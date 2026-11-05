#!/usr/bin/env python3
"""Tests of checker/rt/rt_tape.c and host_fx.c.

1. Differential test against native x86-64 code. A tape format entry is performed at the end of the
   shot by printf on its measured fields (CR §1.3, BACKEND_ABI §1.11). For every case (a format and
   its fields) this generates
     - native.ll: the same printf call as LLVM IR (each field converted to the argument type of its
       conversion by zext/trunc/fpext/fptrunc/inttoptr), compiled by clang-19 -O1 and run on the host;
     - diff_driver.c: the same entry recorded on a tape through rt_tape.c, once with every numeric field
       as a tape rail (cqrt_tape_write_<W>) and once as a literal (cqrt_tape_write_<W>_lit),
   and requires the entry's "text" in the end-of-shot event to equal the native output byte for byte,
   for edge values, fp specials and a seeded random set at every corpus width plus i1, i7, i100.
   The tape family has no CR §2 row (BACKEND_ABI §1.11: "§2. None"), so no totalization row applies.
2. Semantic scenarios (scenarios.c): predicates, abort ordering, one sequence across tapes, controlled
   writes at every width, copy-at-call strings, the host-boundary table of BACKEND_ABI §1.11 (resolved,
   the INPUT rows, deferred) with the stand-in, capture, exit()/_Exit, and one scenario per violation,
   each of which must be reported.
3. The references of 209, 210, 99, 47 and 138 run in the real evaluator through a hand driver (refs.py).

Usage: run_tests.py --clang <clang-19> [--work DIR] [--seed N]
"""
import argparse
import json
import os
import random
import re
import struct
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RT = os.path.join(ROOT, "checker", "rt")
SEP = b"\x1e<<CQ-SEP>>\x1e"

INT_WIDTHS = [1, 7, 8, 16, 32, 64, 80, 100, 128]   # corpus rail widths plus i1, i7, i100
FP_WIDTHS = [16, 32, 64, 80]
FP_FMT = {16: (5, 10), 32: (8, 23), 64: (11, 52), 80: (15, 64)}
FP_IR = {16: "half", 32: "float", 64: "double", 80: "x86_fp80"}

INT_FORMATS = ["%d", "%i", "%u", "%x", "%X", "%o", "%#x", "%#o", "%hhd", "%hhu", "%hd", "%hu",
               "%ld", "%lu", "%lld", "%llx", "%jd", "%zu", "%td", "%c", "%.3d", "%#.5llo",
               "[%8d|%-8d|%08d|%+d|% d]", "<%*d>", "%c%c%c"]
FP_FORMATS = ["%f", "%e", "%g", "%a", "%A", "%.3f", "%10.2e", "%-12g|", "%+.0f", "%#g", "%G", "%E",
              "%.17g", "%F", "%Lg", "%Lf", "%Le", "%La", "%.21Lg", "%Lf %e"]
STR_FORMATS = ["%s", "%10s|", "%-10s|", "%.2s|", "%%%s%%", "no conversions\n", "x=%d s=%s\n"]
STRINGS = ["hello", "", "a\tb", "100%"]


def standin(name, words):
    """cq_standin.h over the argument words."""
    h = 0xcbf29ce484222325
    for c in name.encode():
        h = ((h ^ c) * 0x100000001b3) & (2 ** 64 - 1)
    for w in words:
        h = ((h ^ w) * 0x100000001b3) & (2 ** 64 - 1)
    return h


def line_byte_h(h, j):
    if j + 1 >= 6:
        return 10
    return ord("a") + ((h ^ j) * 0x100000001b3 & (2 ** 64 - 1)) % 26


def line_byte(name, j):
    return line_byte_h(standin(name, []), j)


def parse_fmt(f):
    """Yields, per consumed argument, (conv, length) with conv '*' for a star argument."""
    out, i = [], 0
    while i < len(f):
        if f[i] != "%":
            i += 1
            continue
        i += 1
        if f[i] == "%":
            i += 1
            continue
        while f[i] in "-+ #0'":
            i += 1
        for part in range(2):
            if part == 1:
                if f[i] != ".":
                    break
                i += 1
            if f[i] == "*":
                out.append(("*", ""))
                i += 1
            else:
                while f[i].isdigit():
                    i += 1
        ln = ""
        if f[i] in "hl":
            ln = f[i]
            i += 1
            if f[i] == ln[0]:
                ln += f[i]
                i += 1
        elif f[i] in "jztLq":
            ln = f[i]
            i += 1
        out.append((f[i], ln))
        i += 1
    return out


def arg_type(conv, ln):
    if conv in "*c":
        return "i32"
    if conv in "diuoxX":
        return "i32" if ln in ("", "h", "hh") else "i64"
    if conv in "sp":
        return "ptr"
    return "x86_fp80" if ln == "L" else "double"


def fp_values(w, rng):
    e, m = FP_FMT[w]
    explicit = w == 80
    emax = (1 << e) - 1

    def enc(s, ex, man):
        if explicit:
            man |= (1 << 63) if 0 < ex else 0   # explicit integer bit: set for normals, inf, nan
        return (s << (e + m)) | (ex << m) | man

    top = 1 << (m - 2) if explicit else 1 << (m - 1)   # quiet bit
    vals = [enc(0, 0, 0), enc(1, 0, 0), enc(0, emax, 0), enc(1, emax, 0), enc(0, emax, top),
            enc(1, emax, top), enc(0, emax, 1), enc(0, 0, 1), enc(1, 0, (top << 1) - 1 if not explicit else (1 << 63) - 1),
            enc(0, 1, 0), enc(0, emax - 1, (1 << m) - 1 if not explicit else (1 << 63) - 1),
            enc(0, (emax >> 1), 0), enc(1, (emax >> 1), 1 << (m - 1) if not explicit else 1 << 62)]
    for _ in range(6):
        ex = rng.randrange(0, emax + 1)
        man = rng.getrandbits(m - 1 if explicit else m)
        vals.append(enc(rng.getrandbits(1), ex, man))
    return vals


def int_values(w, rng):
    mask = (1 << w) - 1
    vals = {0, 1 & mask, mask, 1 << (w - 1), (1 << (w - 1)) - 1}
    while len(vals) < 5 + 6 and w > 3:
        vals.add(rng.getrandbits(w))
    return sorted(vals)


def build_cases(seed):
    rng = random.Random(seed)
    cases = []   # (fmt, [fields]) field = ('i', w, v) | ('f', w, bits) | ('s', str)
    for w in INT_WIDTHS:
        for v in int_values(w, rng):
            for f in INT_FORMATS:
                fields = []
                for conv, ln in parse_fmt(f):
                    fields.append(("i", 32, 6) if conv == "*" else ("i", w, v))
                cases.append((f, fields))
            if w == 64:
                cases.append(("%p", [("i", 64, v)]))
    for w in FP_WIDTHS:
        for v in fp_values(w, rng):
            for f in FP_FORMATS:
                cases.append((f, [("f", w, v) for _ in parse_fmt(f)]))
    for s in STRINGS:
        for f in STR_FORMATS:
            fields = []
            for conv, ln in parse_fmt(f):
                fields.append(("s", s) if conv == "s" else ("i", 32, rng.getrandbits(32)))
            cases.append((f, fields))
    return cases


def c_bytes(b):
    return "".join("\\%03o" % c for c in b)


def ir_bytes(b):
    return "".join(chr(c) if 32 <= c < 127 and c not in (34, 92) else "\\%02X" % c for c in b)


def gen_native(cases):
    g, body = [], []
    g.append('@sep = private constant [%d x i8] c"%s\\00"' % (len(SEP) + 1, ir_bytes(SEP)))
    n = 0
    for ci, (f, fields) in enumerate(cases):
        fb = f.encode()
        g.append('@fmt%d = private constant [%d x i8] c"%s\\00"' % (ci, len(fb) + 1, ir_bytes(fb)))
        args = []
        for fi, ((conv, ln), fld) in enumerate(zip(parse_fmt(f), fields)):
            t = arg_type(conv, ln)
            if fld[0] == "s":
                sb = fld[1].encode()
                g.append('@s%d_%d = private constant [%d x i8] c"%s\\00"' % (ci, fi, len(sb) + 1, ir_bytes(sb)))
                args.append("ptr @s%d_%d" % (ci, fi))
                continue
            kind, w, v = fld
            n += 1
            x = "%%x%d" % n
            if kind == "i":
                if t == "ptr":
                    body.append("  %s = inttoptr i%d %d to ptr" % (x, w, v))
                else:
                    tw = int(t[1:])
                    op = "zext" if w < tw else "trunc" if w > tw else None
                    if op:
                        body.append("  %s = %s i%d %d to %s" % (x, op, w, v, t))
                    else:
                        x = str(v)
                args.append("%s %s" % (t, x))
            else:
                body.append("  %s = bitcast i%d %d to %s" % (x, w, v, FP_IR[w]))
                tw = 80 if t == "x86_fp80" else 64
                if tw != w:
                    n += 1
                    y = "%%x%d" % n
                    body.append("  %s = %s %s %s to %s" % (y, "fpext" if w < tw else "fptrunc", FP_IR[w], x, t))
                    x = y
                args.append("%s %s" % (t, x))
        body.append("  call i32 (ptr, ...) @printf(ptr @fmt%d%s)" % (ci, "".join(", " + a for a in args)))
        body.append("  call i32 (ptr, ...) @printf(ptr @sep)")
    return ("target triple = \"x86_64-apple-macosx\"\n" + "\n".join(g) +
            "\ndeclare i32 @printf(ptr, ...)\ndefine i32 @main() {\n" + "\n".join(body) +
            "\n  ret i32 0\n}\n")


def gen_driver(cases):
    """A table-driven driver: one tape, every case once with rail fields and once with literals."""
    fl, cl = [], []
    for f, fields in cases:
        cl.append('  {"%s", %d, %d},' % (c_bytes(f.encode()), len(fl), len(fields)))
        for fld in fields:
            if fld[0] == "s":
                fl.append('  {\'s\', 0, 0, 0, "%s"},' % c_bytes(fld[1].encode()))
            else:
                kind, w, v = fld
                fl.append("  {'%s', %d, UINT64_C(%d), UINT64_C(%d), 0}," % (kind, w, v & ((1 << 64) - 1), v >> 64))
    return """#include <stdio.h>
#include "fake_core.h"
typedef struct { char k; unsigned w; uint64_t lo, hi; const char *s; } F;
typedef struct { const char *fmt; int first, n; } C;
static const F fields[] = {
%s
  {0, 0, 0, 0, 0}};
static const C cases[] = {
%s
};
int main(void) {
  int32_t t = fake_call("cqrt_tape_alloc", 0);
  for (int variant = 0; variant < 2; variant++)
    for (unsigned c = 0; c < sizeof cases / sizeof cases[0]; c++) {
      fake_call("cqrt_tape_fmt", 2, fake_h(t), fake_p(cases[c].fmt));
      for (int i = 0; i < cases[c].n; i++) {
        const F *f = &fields[cases[c].first + i];
        if (f->k == 's') {
          if (variant == 0) fake_call("cqrt_tape_write_i64", 2, fake_h(t), fake_h(fake_rail("i64", fake_p(f->s))));
          else fake_call("cqrt_tape_write_i64_lit", 2, fake_h(t), fake_p(f->s));
          continue;
        }
        char wt[8], sym[48];
        snprintf(wt, sizeof wt, "%%c%%u", f->k, f->w);
        snprintf(sym, sizeof sym, "cqrt_tape_write_%%s%%s", wt, variant ? "_lit" : "");
        cqe_val v = f->k == 'f' ? fake_f(f->w, f->lo, f->hi) : fake_i(f->w, f->lo, f->hi);
        if (variant == 0) fake_call(sym, 2, fake_h(t), fake_h(fake_rail(wt, v)));
        else fake_call(sym, 2, fake_h(t), v);
      }
    }
  return 0;
}
""" % ("\n".join(fl), "\n".join(cl))


def sh(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, **kw)
    if r.returncode != 0:
        sys.stderr.write("command failed: %s\n%s%s" % (" ".join(cmd), r.stdout.decode(errors="replace"),
                                                      r.stderr.decode(errors="replace")))
        sys.exit(1)
    return r


def build(clang, work, name, srcs):
    exe = os.path.join(work, name)
    sh([clang, "-std=c17", "-O1", "-Wall", "-Wextra", "-Werror", "-I", RT, "-I", HERE, "-o", exe,
        os.path.join(RT, "rt_tape.c"), os.path.join(RT, "host_fx.c"), os.path.join(HERE, "fake_core.c")] + srcs)
    return exe


def run_trace(exe, args, work, tag):
    path = os.path.join(work, tag + ".jsonl")
    env = dict(os.environ, CQE_TRACE=path)
    r = subprocess.run([exe] + args, env=env, capture_output=True)
    if r.returncode != 0:
        sys.stderr.write("%s exited %d: %s\n" % (tag, r.returncode, r.stderr.decode(errors="replace")))
        sys.exit(1)
    with open(path, encoding="utf-8") as fh:
        return [json.loads(l) for l in fh if l.strip()]


def shot_of(trace):
    shots = [e for e in trace if e.get("ev") == "tape" and e.get("op") == "shot"]
    return shots[0] if len(shots) == 1 else None


def text_bytes(s):
    return s.encode("latin-1")


def differential(clang, work, seed):
    cases = build_cases(seed)
    ll = os.path.join(work, "native.ll")
    with open(ll, "w") as fh:
        fh.write(gen_native(cases))
    native = os.path.join(work, "native")
    sh([clang, "-O1", "-o", native, ll])
    out = sh([native]).stdout.split(SEP)
    assert out[-1] == b"" and len(out) == len(cases) + 1, (len(out), len(cases))
    drv = os.path.join(work, "diff_driver.c")
    with open(drv, "w") as fh:
        fh.write(gen_driver(cases))
    exe = build(clang, work, "diff_driver", [drv])
    trace = run_trace(exe, [], work, "diff")
    viol = [e for e in trace if e.get("ev") == "violation"]
    shot = shot_of(trace)
    fails = []
    if viol:
        fails.append("violations: %s" % viol[:3])
    if not shot:
        fails.append("no single shot event")
        return len(cases), fails
    ents = shot["events"]
    if len(ents) != 2 * len(cases):
        fails.append("%d entries for %d cases x 2" % (len(ents), len(cases)))
        return len(cases), fails
    for k, e in enumerate(ents):
        ci = k % len(cases)
        want = out[ci]
        got = text_bytes(e["text"])
        if got != want or not e["performed"]:
            fails.append("case %d (%s) %s: fmt %r fields %r: native %r, tape %r" % (
                ci, "rail" if k < len(cases) else "lit", "performed" if e["performed"] else "NOT performed",
                cases[ci][0], cases[ci][1], want[:120], got[:120]))
    want_stdout = b"".join(out[:-1]) * 2
    if text_bytes(shot["stdout"]) != want_stdout:
        fails.append("shot stdout differs from the concatenated native output")
    return len(cases), fails


def performed(shot):
    return [(e.get("fmt") or e.get("name"), e["performed"]) for e in shot["events"] if e["kind"] != "abort"]


def scenarios(clang, work):
    exe = build(clang, work, "scenarios", [os.path.join(HERE, "scenarios.c")])
    checks = []

    def check(name, fn):
        trace = run_trace(exe, [name], work, "sc_" + name)
        viol = [e["what"] for e in trace if e.get("ev") == "violation"]
        try:
            msg = fn(trace, shot_of(trace), viol)
        except Exception as ex:  # a malformed trace is a failure of the scenario
            msg = "exception %r" % ex
        checks.append((name, msg))

    def violation_of(pattern):
        def fn(trace, shot, viol):
            return None if any(re.search(pattern, v) for v in viol) else "no violation /%s/ in %s" % (pattern, viol)
        return fn

    def ok_shot(expect_perf, stdout, aborted=None):
        def fn(trace, shot, viol):
            if viol:
                return "violations %s" % viol
            if not shot:
                return "no single shot event"
            if performed(shot) != expect_perf:
                return "performed %s, want %s" % (performed(shot), expect_perf)
            if text_bytes(shot["stdout"]) != stdout:
                return "stdout %r, want %r" % (shot["stdout"], stdout)
            if aborted is not None and shot["aborted"] != aborted:
                return "aborted %s" % shot["aborted"]
            return None
        return fn

    check("pred", ok_shot([("zero %d\n", False), ("one %d\n", True), ("plain\n", False + True)],
                          b"one 6\nplain\n"))
    check("abort", ok_shot([("a\n", True), ("b\n", True), ("c\n", False), ("d\n", False)], b"a\nb\n", True))
    check("abort_first", ok_shot([("never\n", False)], b"", True))
    check("two_tapes", ok_shot([("A%d ", True), ("B%d ", True), ("late\n", False)], b"A1 B2 ", True))

    def write_ctl(trace, shot, viol):
        if viol:
            return "violations %s" % viol
        writes = [e for e in trace if e.get("ev") == "tape" and e.get("op") == "write"]
        allocs = {e["h"]: e for e in trace if e.get("ev") == "alloc"}
        if len(writes) != 13 * 3:
            return "%d writes" % len(writes)
        for i in range(0, len(writes), 3):
            a, b, c = writes[i:i + 3]
            if not (a["v"] == b["v"] and c["v"] == "0x0" and a["v"] != "0x0" and a["cv"] == 1 and b["cv"] == 1
                    and c["cv"] == 0 and a["w"] == b["w"] == c["w"]):
                return "bad controlled write %s" % [a, b, c]
            for x in (a, b, c):
                if x["h"] == x["src"] or allocs[x["h"]]["known"] != 1:
                    return "tape rail of classical-valued operands not fresh and classical-valued: %s" % x
        f = shot["events"][0]["fields"]
        if [x["v"] for x in f] != [w["v"] for w in writes]:
            return "end-of-shot values differ from the writes"
        return None
    check("write_ctl", write_ctl)
    check("copy_at_call", ok_shot([("%s!\n", True)], b"orig!\n"))

    def clean(fn):
        def wrapped(trace, shot, viol):
            if viol:
                return "violations %s" % viol
            return fn(trace, shot)
        return wrapped

    def classes(shot):
        return [(e.get("fmt") or e.get("name"), e["class"], e["performed"]) for e in shot["events"] if e["kind"] != "abort"]

    def lines(trace):
        return [(e.get("fmt") or e.get("name"), e["when"]) for e in trace if e.get("ev") == "effect"]

    def tap(trace, name, *ev):
        return [e for e in trace if e.get("ev") == name]

    def qstores(trace):
        return [(e["off"] - min(x["off"] for x in tap(trace, "qstore")), e["write"]) for e in tap(trace, "qstore")]

    def effect(trace, shot):
        if os.path.exists("/tmp/cq_rt_tape_must_not_exist"):
            return "effect executed"
        if classes(shot) != [("remove", "resolved", True), ("raise", "resolved", False)] or shot["stdout"] != "":
            return "classes %s" % classes(shot)
        if lines(trace) != [("remove", "call")]:
            return "lines %s" % lines(trace)
        f = [e["fields"] for e in shot["events"]]
        if f[0][0].get("cap") != "/tmp/cq_rt_tape_must_not_exist" or f[1] != [{"k": "lit", "w": "i32", "v": "0x1e"}]:
            return "fields %s" % f
        return None
    check("effect", clean(effect))

    def res_result(trace, shot):
        allocs = [e for e in trace if e.get("ev") == "alloc"]
        r = [e for e in shot["events"]]
        want = standin("raise", [30]) & 0xffffffff
        if int(r[0]["r"]["v"], 16) != want or int(r[1]["r"]["v"], 16) != 0 or int(r[2]["r"]["v"], 16) != 0:
            return "results %s, want %x" % ([x["r"] for x in r], want)
        known = {e["h"]: e["known"] for e in allocs}
        if not all(known[x["r"]["h"]] == 1 for x in r):
            return "a result rail is not classical-valued"
        return None
    check("res_result", clean(res_result))

    def addr_not_mixed(trace, shot):
        r = [int(e["r"]["v"], 16) for e in shot["events"]]
        want = standin("unknown_fn", [7]) & 0xffffffff
        if r[0] != want or r[1] != want or r[2] != standin("", [7]) & 0xffffffff:
            return "results %s" % r
        if shot["events"][2]["name"] is not None:
            return "null name %r" % shot["events"][2]["name"]
        return None
    check("addr_not_mixed", clean(addr_not_mixed))

    def defer_field(trace, shot):
        if classes(shot) != [("x=%d\n", "deferred", True), ("putchar", "deferred", True), ("end\n", "deferred", True)]:
            return "classes %s" % classes(shot)
        if lines(trace) != [("x=%d\n", "end"), ("putchar", "end"), ("end\n", "end")]:
            return "lines %s" % lines(trace)
        if int(shot["events"][1]["r"]["v"], 16) != 0 or not shot["deviation"]:
            return "deferred result %s deviation %s" % (shot["events"][1]["r"], shot["deviation"])
        return None if shot["stdout"] == "x=3\nend\n" else "stdout %r" % shot["stdout"]
    check("defer_field", clean(defer_field))
    check("resolved_then_deferred", clean(lambda tr, sh: None if (
        classes(sh) == [("first\n", "resolved", True), ("putchar", "resolved", True), ("%d\n", "deferred", True)]
        and lines(tr) == [("first\n", "call"), ("putchar", "call"), ("%d\n", "end")] and not sh["deviation"])
        else "classes %s lines %s" % (classes(sh), lines(tr))))
    check("pred_copy", ok_shot([("one\n", True), ("zero\n", False)], b"one\n"))
    check("pred_copy_changed", violation_of("predicate rail .* changed"))
    check("pred_seed_freed", clean(lambda tr, sh: None if (
        classes(sh) == [("putchar", "resolved", True), ("%d", "deferred", True), ("putchar", "deferred", True)])
        else "classes %s" % classes(sh)))
    check("abort_input", clean(lambda tr, sh: None if (
        classes(sh) == [("putchar", "deferred", False), ("fgets", "input", True)] and lines(tr) == [] and sh["aborted"])
        else "classes %s lines %s" % (classes(sh), lines(tr))))
    check("abort_q", clean(lambda tr, sh: None if (classes(sh) == [("putchar", "deferred", True)])
                           else "classes %s" % classes(sh)))

    def input_classical(trace, shot):
        if classes(shot) != [("%d\n", "deferred", True), ("fgets", "input", True)]:
            return "classes %s" % classes(shot)
        if lines(trace) != [("fgets", "call"), ("%d\n", "end")]:
            return "lines %s" % lines(trace)
        p = tap(trace, "probe")[0]
        return None if p["b0"] == line_byte("fgets", 0) and p["b1"] == line_byte("fgets", 1) else "bytes %s" % p
    check("input_classical", clean(input_classical))
    check("input_skip", clean(lambda tr, sh: None if classes(sh) == [("fgets", "input", False)] and not lines(tr)
                              else "classes %s lines %s" % (classes(sh), lines(tr))))

    def input_len_q(trace, shot):
        if classes(shot) != [("fgets", "input", True)]:
            return "classes %s" % classes(shot)
        q = tap(trace, "qstore")
        if [(e["write"]) for e in q] != [1, 1, 1, 0, 0, 0, 0]:     # v = 3: 2 bytes and the NUL of 7 cells reached
            return "qstores %s" % q
        want = [line_byte("fgets", 0), line_byte("fgets", 1), 0, 0, 0, 0, 0]
        return None if [e["b"] for e in q] == want else "bytes %s want %s" % ([e["b"] for e in q], want)
    check("input_len_q", clean(input_len_q))

    def input_addr_q(trace, shot):
        q = tap(trace, "qstore")
        if [(e["write"], e["b"]) for e in q] != [(1, line_byte("fgets", 0)), (1, 0)]:
            return "qstores %s" % q
        # an INPUT call with a quantum address is performed and not resolved: a later output stays behind it
        return None if classes(shot) == [("fgets", "input", True), ("after\n", "deferred", True)] else "classes %s" % classes(shot)
    check("input_addr_q", clean(input_addr_q))

    def input_pred_q(trace, shot):
        q = tap(trace, "qstore")
        if [e["write"] for e in q] != [0, 0, 1, 1]:
            return "qstores %s" % q
        # c = 0: the C program does not reach the call, so no effect line; the input is consumed all the same
        if classes(shot) != [("fgets", "input", True), ("fgets", "input", True)]:
            return "classes %s" % classes(shot)
        return None if lines(trace) == [("fgets", "call")] else "lines %s" % lines(trace)
    check("input_pred_q", clean(input_pred_q))
    check("input_ident_q", clean(lambda tr, sh: None if (classes(sh) == [("fgets", "deferred", True)] and not tap(tr, "qstore")
                                                         and sh["deviation"]) else "classes %s" % classes(sh)))

    def read_fread_getc(trace, shot):
        p = tap(trace, "probe")[0]
        want = {"r": 6, "f": 3, "g": line_byte("getc", 0), "gc": line_byte("getchar", 0), "a6": ord("Z"), "b6": ord("Z"),
                "a0": line_byte_h(standin("read", [3]), 0)}
        return None if all(p[k] == v for k, v in want.items()) else "probe %s want %s" % (p, want)
    check("read_fread_getc", clean(read_fread_getc))

    def capture(trace, shot):
        e = shot["events"]
        if classes(shot) != [("fwrite", "deferred", True), ("fputs", "deferred", False)]:
            return "classes %s" % classes(shot)
        if e[0]["fields"][0].get("cap") != "ABz":
            return "cap %r" % e[0]["fields"][0].get("cap")
        if "cap" in e[1]["fields"][0]:
            return "a capture under classical c = 0"
        n = [x for x in trace if x.get("ev") == "alloc" and x["w"] == "i8" and x["known"] == 0]
        return None if len(n) == 2 else "%d capture rails" % len(n)
    check("capture", clean(capture))
    check("capture_ql", clean(lambda tr, sh: None if (sh["events"][0]["class"] == "deferred" and
                                                      sh["events"][0]["fields"][0]["cap"] == "abcd")
                              else "%s" % sh["events"][0]))
    check("string_rail", ok_shot([("[%s]", True), ("<%s>\n", True)], b"[cl]<qu>\n"))
    check("string_quantum_cell", clean(lambda tr, sh: None if (
        classes(sh) == [("%s\n", "deferred", True)] and sh["stdout"] == "aXc\n") else "%s" % sh["events"]))
    check("fprintf_format", clean(lambda tr, sh: None if (
        [f.get("cap") for f in sh["events"][0]["fields"]] == [None, "%s-%d", "str", None]) else "%s" % sh["events"]))
    check("percent_n", ok_shot([("ab%nc\n", True)], b"abc\n"))
    check("excess", clean(lambda tr, sh: None if (
        [len(e["fields"]) for e in sh["events"]] == [1, 0] and sh["stdout"] == "x\ny\n") else "%s" % sh["events"]))
    def excess(fields, marks):
        def go(trace, sh):
            got = [[int(f["v"], 16) for f in e["fields"]] for e in sh["events"]]
            if got != fields or sh["stdout"] != "x\n":
                return "fields %s stdout %r" % (got, sh["stdout"])
            if [bool(e.get("split_open")) for e in sh["events"]] != marks:
                return "marks %s" % sh["events"]
            return None
        return go
    check("excess_effect", clean(excess([[1, 2], [3]], [False, False])))
    check("excess_none", clean(excess([[], [3]], [False, False])))
    check("excess_unknown", clean(excess([[], [1, 2], [5]], [False, True, False])))
    check("excess_variadic", clean(lambda tr, sh: None if (
        [len(e["fields"]) for e in sh["events"]] == [0, 2] and sh["events"][1].get("split_open")) else "%s" % sh["events"]))
    check("retired", ok_shot([], b""))

    def host_fx(trace, shot):
        p = tap(trace, "probe")[0]
        e = tap(trace, "effect")
        if p["r"] != standin("remove", []) & 0xffffffff or p["s"] != standin("raise", [9]) & 0xffffffff:
            return "results %s" % p
        if [x["name"] for x in e] != ["remove", "raise"] or e[0]["fields"][0]["cap"] != "/tmp/cq_rt_tape_host_fx":
            return "lines %s" % e
        return None
    check("host_fx", clean(host_fx))
    # the literal is the number of h7, the first rail fake_core hands out (100): read as a literal, not a rail
    check("spellings", ok_shot([("%d %d %d %s\n", True)], b"7 8 100 s\n", False))
    check("not_mine", ok_shot([], b""))
    check("exit_call", ok_shot([("bye\n", True)], b"bye\n"))
    check("underscore_exit", lambda tr, shot, v: None if shot is None and not v else "tape survived _Exit")

    def violation(pattern):
        def fn(trace, shot, viol):
            return None if any(re.search(pattern, v) for v in viol) else "no violation /%s/ in %s" % (pattern, viol)
        return fn
    check("v_field_no_entry", violation("no open entry"))
    check("v_bad_tape", violation("not returned by cqrt_tape_alloc"))
    check("v_free_tape_rail", violation("free_forbidden: rail .* has role tape"))
    check("v_tape_rail_gone", violation("tape rail .* is gone"))
    check("v_tape_rail_changed", violation("tape rail .* changed after its write"))
    check("v_abort_changed", violation("abort flag .* changed after cqrt_abort_i1"))
    check("v_free_abort", violation("free_forbidden: rail .* has role abort"))
    check("v_abort_not_i1", violation("abort flag .* is not an i1 rail"))
    check("v_pred_not_i1", violation("predicate .* is not an i1 rail"))
    check("v_pred_dead", violation("predicate .* is not a live rail"))
    check("v_unc", violation("no _unc"))
    check("v_missing_field", violation("needs more fields"))
    check("v_bad_conv", violation("has no defined meaning"))
    check("v_effect_arity", violation("fgets has 1 fields"))
    check("v_null_name_empty", violation("null name with no host address"))
    check("v_effect_open_format", violation("still lacks fields"))
    check("v_width_mismatch", violation("width i32 but rail .* is i8"))
    check("v_effect_uncontrolled", violation("cqrt_tape_effect: no such form"))
    check("v_hl", violation("no _hl form"))
    check("v_ctl_arity", violation("2 arguments, expected 3"))
    check("v_lit_ctl", violation("no such form"))
    return checks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clang", default="/usr/local/opt/llvm@19/bin/clang")
    ap.add_argument("--work")
    ap.add_argument("--seed", type=int, default=20261027)
    a = ap.parse_args()
    work = a.work or tempfile.mkdtemp(prefix="rt-tape-")
    os.makedirs(work, exist_ok=True)
    ncases, dfails = differential(a.clang, work, a.seed)
    print("differential: %d cases x 2 variants (rail, literal), %d mismatches" % (ncases, len(dfails)))
    for f in dfails[:20]:
        print("  FAIL", f)
    checks = scenarios(a.clang, work)
    bad = [(n, m) for n, m in checks if m]
    print("scenarios: %d run, %d failed" % (len(checks), len(bad)))
    for n, m in bad:
        print("  FAIL %s: %s" % (n, m))
    refs = subprocess.run([sys.executable, os.path.join(HERE, "refs.py"), "--clang", a.clang, "--work", os.path.join(work, "refs")])
    sys.exit(1 if dfails or bad or refs.returncode else 0)


if __name__ == "__main__":
    main()
