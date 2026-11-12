#!/usr/bin/env python3
"""The references of 209, 210, 99, 47 and 138 in the real evaluator (core.c, dispatch.c, the templates, rt_tape.c,
host_fx.c, rt_bus.c, the bundle's cq_host.c) through a hand driver: their event sequences per BACKEND_ABI §1.11, with no violation.
Usage: refs.py --clang C --work D --spec S"""
import argparse
import glob
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RT = os.path.join(os.path.dirname(os.path.dirname(HERE)), "checker", "rt")
ROOT = os.path.dirname(os.path.dirname(HERE))
SPEC = next(p for p in (os.path.join(ROOT, "..", "CQ_spec"), os.path.join(ROOT, "..", "..", "CQ_spec")) if os.path.isdir(p))
sys.path.insert(0, HERE)
from run_tests import STREAM  # noqa: E402


def sh(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, **kw)
    if r.returncode != 0:
        sys.stderr.write("command failed: %s\n%s%s" % (" ".join(cmd)[:400], r.stdout.decode(errors="replace"), r.stderr.decode(errors="replace")))
        sys.exit(1)
    return r


def runtime(clang, work):
    objs = []
    srcs = glob.glob(os.path.join(RT, "*.c"))
    srcs.append(os.path.join(ROOT, "bundle", "host", "cq_host.c"))
    for s in srcs:
        o = os.path.join(work, os.path.basename(s) + ".o")
        sh([clang, "-std=c17", "-O1", "-w", "-I", RT, "-c", s, "-o", o])
        objs.append(o)
    return objs


def prog(clang, work, objs, spec, ex, decls, call):
    d = os.path.join(work, ex)
    os.makedirs(d, exist_ok=True)
    name = ex.split("_", 1)[1]
    ll = os.path.join(spec, "examples", ex, name + ".lowered.ll")
    drv = os.path.join(d, "driver.c")
    with open(drv, "w") as f:
        f.write("#include <stdio.h>\n%s\nint main(void) { %s; return 0; }\n" % (decls, call))
    drvll = os.path.join(d, "driver.ll")
    sh([clang, "-S", "-emit-llvm", "-O0", "-w", drv, "-o", drvll])
    stubs = os.path.join(d, "stubs.ll")
    sh([sys.executable, os.path.join(RT, "stubgen.py"), ll, drvll, "-o", stubs])
    exe = os.path.join(d, "prog")
    sh([clang, "-O0", "-w", *objs, ll, drvll, stubs, "-lm", "-o", exe])
    return exe


def run(exe, tag):
    path = exe + "." + tag + ".jsonl"
    r = subprocess.run([exe], env=dict(os.environ, CQE_TRACE=path), capture_output=True, stdin=subprocess.DEVNULL)
    if r.returncode != 0:
        raise RuntimeError("%s exited %d: %s" % (exe, r.returncode, r.stderr[:400]))
    with open(path, encoding="utf-8") as f:
        return [json.loads(x) for x in f if x.strip()]


def summary(trace):
    shots = [e for e in trace if e.get("ev") == "tape" and e.get("op") == "shot"]
    shot = shots[0]
    return shot, [(e.get("fmt") or e.get("name") or e.get("kind"), e.get("class"), e.get("performed")) for e in shot["events"]]


CASES = [
    # 209: the printf with a rail field is deferred; the putchar behind it is too, and stays behind it
    ("209_host_call_behind_printf", "int host_call_behind_printf(int,double,int);", "host_call_behind_printf(3,.5,10)",
     [("%d", "deferred", True), ("putchar", "deferred", True)], "3", lambda t, s: s["events"][1]["fields"] == [{"k": "lit", "w": "i32", "v": "0xa"}]),
    # 210: the printf is deferred, the fgets behind it is performed at the call (quantum length: bus stores)
    ("210_input_behind_output", "int input_behind_output(unsigned,double,int,double,FILE*);",
     "input_behind_output(3,.5,4,.25,stdin)", [("%d\n", "deferred", True), ("fgets", "input", True)], "4\n",
     lambda t, s: [e["name"] if e["kind"] == "effect" else e["fmt"] for e in t if e.get("ev") == "effect"] == ["fgets", "%d\n"]
     # buf[0], loaded and measured, is the stream's first byte, which fgets stored under n & 7 = 3 (ruling Q5)
     and [int(e["v"], 16) for e in t if e.get("ev") == "measure"] == [STREAM[0]]),
    # 99: both output entries deferred; the buffer captured at the entry (two QUANTUM cells, one HOST); x > k is 0
    ("99_byte_tape", "int byte_tape(unsigned char,double,int);", "byte_tape(0,.5,1)",
     [("fwrite", "deferred", True), ("fputs", "deferred", False)], "",
     lambda t, s: s["events"][0]["fields"][0]["cap"] == "\x00\x01z" and "cap" in s["events"][1]["fields"][0]),
    # 99 with x > k reading 1: the fputs string captured under a quantum predicate and performed
    ("99_byte_tape", "int byte_tape(unsigned char,double,int);", "byte_tape(0,.5,-1)",
     [("fwrite", "deferred", True), ("fputs", "deferred", True)], "",
     lambda t, s: s["events"][1]["fields"][0]["cap"] == "hi\n"),
    # 47: format entries with rail fields and a controlled entry; the predicate read at the call
    ("47_printf_tape", "int printf_quantum(int,double);int printf_under_quantum_if(int,double,int);int printf_mixed(int,double,int);",
     "printf_quantum(0,.5); printf_under_quantum_if(0,.5,1); printf_under_quantum_if(5,.5,1); printf_mixed(0,.5,3)", None, None, None),
    # 138: an f64 field, compound and nested predicates
    ("138_tape_variants", "int printf_double(double,double);int printf_compound_cond(int,int,double,double,int,int);int printf_nested_cond(int,int,double,double,int,int);",
     "printf_double(0,.5); printf_compound_cond(0,0,.5,.25,1,2); printf_compound_cond(5,5,.5,.25,1,2); printf_nested_cond(0,0,.5,.25,1,2); printf_nested_cond(5,5,.5,.25,1,2)", None, None, None),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clang", default="/usr/local/opt/llvm@19/bin/clang")
    ap.add_argument("--work", required=True)
    ap.add_argument("--spec", default=os.path.normpath(SPEC))
    ap.add_argument("--show", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.work, exist_ok=True)
    objs = runtime(a.clang, a.work)
    bad = 0
    for i, (ex, decls, call, want, stdout, extra) in enumerate(CASES):
        exe = prog(a.clang, os.path.join(a.work, str(i)), objs, a.spec, ex, decls, call)
        tr = run(exe, "t")
        viol = [e for e in tr if e.get("ev") == "violation"]
        shot, seq = summary(tr)
        if a.show:
            print(ex, call, "\n ", seq, "\n  stdout", repr(shot["stdout"]))
            print("  roles", [(e.get("role")) for e in tr if e.get("ev") == "exit"][:1])
        msgs = []
        if viol:
            msgs.append("violations %s" % viol[:3])
        if want is not None and seq != want:
            msgs.append("sequence %s, want %s" % (seq, want))
        if stdout is not None and shot["stdout"] != stdout:
            msgs.append("stdout %r, want %r" % (shot["stdout"], stdout))
        if extra and not extra(tr, shot):
            msgs.append("extra check failed: %s" % shot)
        if want is None:
            msgs += check_expected(ex, shot)
        for m in msgs:
            print("FAIL %s %s: %s" % (ex, call, m))
        bad += bool(msgs)
    print("references: %d runs, %d failed" % (len(CASES), bad))
    sys.exit(1 if bad else 0)


def check_expected(ex, shot):
    """47 and 138: the entries in order, by the C program's own predicates and values at these inputs."""
    want = {
        "47_printf_tape": EXPECT_47,
        "138_tape_variants": EXPECT_138,
    }[ex]
    got = [(e.get("fmt"), e.get("performed"), e.get("text")) for e in shot["events"]]
    return [] if got == want else ["entries %s, want %s" % (got, want)]


EXPECT_47 = [("%d\n", True, "0\n"), ("big %d\n", False, "big 0\n"), ("big %d\n", True, "big 5\n"),
             ("%d %d %d\n", True, "0 3 3\n")]
EXPECT_138 = [("%f\n", True, "0.000000\n"), ("both %d %d\n", False, "both 0 0\n"), ("both %d %d\n", True, "both 5 5\n"),
              ("inner %d\n", False, "inner 0\n"), ("outer %d\n", False, "outer 0\n"), ("inner %d\n", True, "inner 5\n"),
              ("outer %d\n", True, "outer 5\n")]

if __name__ == "__main__":
    main()
