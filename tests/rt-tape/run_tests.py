#!/usr/bin/env python3
"""Tests of checker/rt/rt_tape.c (cq-w0-rt-tape).

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
   writes at every width, copy-at-call strings, effect entries, exit()/_Exit, and one scenario per
   violation, each of which must be reported.

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
        if (f->k == 's') { fake_call("cqrt_tape_write_str_lit", 2, fake_h(t), fake_p(f->s)); continue; }
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
        os.path.join(RT, "rt_tape.c"), os.path.join(HERE, "fake_core.c")] + srcs)
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
                if x["h"] == x["src"] or allocs[x["h"]]["known"] != 0:
                    return "tape rail not fresh/unknown: %s" % x
        f = shot["events"][0]["fields"]
        if [x["v"] for x in f] != [w["v"] for w in writes]:
            return "end-of-shot values differ from the writes"
        return None
    check("write_ctl", write_ctl)
    check("copy_at_call", ok_shot([("%s!\n", True)], b"orig!\n"))

    def effect(trace, shot, viol):
        if viol:
            return "violations %s" % viol
        if os.path.exists("/tmp/cq_rt_tape_must_not_exist"):
            return "effect executed"
        if performed(shot) != [("remove", True), ("raise", False)] or shot["stdout"] != "":
            return "performed %s" % performed(shot)
        f = [e["fields"] for e in shot["events"]]
        if f != [[{"k": "str", "s": "/tmp/cq_rt_tape_must_not_exist"}], [{"k": "lit", "w": "i32", "v": "0x1e"}]]:
            return "fields %s" % f
        return None
    check("effect", effect)
    def str_group(trace, shot, viol):
        if viol:
            return "violations %s" % viol
        if text_bytes(shot["stdout"]) != b"[hi!] 7 <>\n":
            return "stdout %r" % shot["stdout"]
        f = shot["events"][0]["fields"]
        if [x.get("k") for x in f] != ["str", "rail", "str"] or f[0]["s"] != "hi!" or f[2]["s"] != "":
            return "fields %s" % f
        return None
    check("str_group", str_group)

    def str_group_effect(trace, shot, viol):
        if viol:
            return "violations %s" % viol
        if os.path.exists("/tmp/cq_rt_tape_str_group"):
            return "effect executed"
        f = [e["fields"] for e in shot["events"]]
        if performed(shot) != [("remove", True)] or f != [[{"k": "str", "s": "/tmp/cq_rt_tape_str_group"}]]:
            return "performed %s fields %s" % (performed(shot), f)
        return None
    check("str_group_effect", str_group_effect)
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
    check("v_percent_n", violation("%n on a tape entry"))
    check("v_width_mismatch", violation("width i32 but rail .* is i8"))
    check("v_effect_uncontrolled", violation("cqrt_tape_effect: no such form"))
    check("v_hl", violation("no _hl form"))
    check("v_ctl_arity", violation("2 arguments, expected 3"))
    check("v_lit_ctl", violation("no such form"))
    check("v_quantum_string", violation("%s on a quantum field"))
    check("v_str_nested", violation("already has an open tape_str_begin group"))
    check("v_str_end_alone", violation("has no open tape_str_begin group"))
    check("v_str_open_at_end", violation("still open at the end of the shot"))
    check("v_str_wide_field", violation("a i32 field inside a tape_str_begin group"))
    check("v_str_no_entry", violation("has no open entry"))
    check("v_str_entry_inside", violation("new entry on tape .* inside an open tape_str_begin group"))
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
    sys.exit(1 if dfails or bad else 0)


if __name__ == "__main__":
    main()
