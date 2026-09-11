#!/usr/bin/env python3
"""Three-way corpus sweep (parallel) for the l4x4.b round-1 FIX.
Frozen binary pairs only — never the live build tree (IMPL_f2 §5b)."""
import subprocess, sys, os, glob, re
from concurrent.futures import ProcessPoolExecutor
S = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4_fix"
PAIRS = {
  "f2":     ("/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/cq-opt",
             "/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/libCQPass.so"),
  "oracle": ("/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt",
             "/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so"),
  "chk":    (f"{S}/bin/cq-opt.267937d", f"{S}/bin/libCQPass.so.267937d"),
  "fix":    (f"{S}/bin/cq-opt.fix",     f"{S}/bin/libCQPass.so.fix"),
}
TEST = "/Users/sorenwilkening/Desktop/CQ_l4x4/ir-pass/test"
DIAG = re.compile(r"lowering: (.*?) under quantum control")
def run(key, f):
    opt, plug = PAIRS[key]
    p = subprocess.run([opt, "-load-pass-plugin", plug, "-passes=cq-lowering",
                        "-S", f, "-o", "-"], capture_output=True, text=True)
    m = DIAG.search(p.stderr)
    return p.returncode, (m.group(1) if m else ""), p.stdout
def one(args):
    a, b, f = args
    r1, d1, o1 = run(a, f); r2, d2, o2 = run(b, f)
    n = os.path.basename(f)
    if r1 != r2:  return ("RCDIFF", f"RCDIFF   {n}: {a} rc={r1} [{d1}] -> {b} rc={r2} [{d2}]")
    if d1 != d2:  return ("DIAGDIFF", f"DIAGDIFF {n}: [{d1}] -> [{d2}]")
    if o1 != o2:  return ("OUTDIFF", f"OUTDIFF  {n}")
    return (None, None)
if __name__ == "__main__":
    a, b = sys.argv[1], sys.argv[2]
    files = sorted(glob.glob(os.path.join(TEST, "*.ll")))
    c = {"RCDIFF":0, "DIAGDIFF":0, "OUTDIFF":0}
    with ProcessPoolExecutor(max_workers=6) as ex:
        for kind, msg in ex.map(one, [(a,b,f) for f in files], chunksize=8):
            if kind: c[kind]+=1; print(msg, flush=True)
    print(f"[{a} -> {b}] files={len(files)} RCDIFF={c['RCDIFF']} DIAGDIFF={c['DIAGDIFF']} OUTDIFF={c['OUTDIFF']}")
