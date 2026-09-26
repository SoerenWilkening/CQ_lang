import os, sys
sys.dont_write_bytecode = True
ROOT = sys.argv[1]; sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
from concurrent.futures import ThreadPoolExecutor
hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
A = "struct TaintSet {"
def mk(nm):
    # NO extra includes, NO clean decoy of our own: the alias's short name only
    return hdr.replace(A, f"struct R3RawRec2 {{ llvm::Value *P = nullptr; }};\nusing {nm} = R3RawRec2;\n" + A + f"\n  {nm} *R3AP = nullptr;", 1)
names = ["Entry", "Node", "Info", "Record", "Impl", "Key", "Data", "Item", "State", "Result", "Region"]
def run(nm):
    errs, n = G.check(mk(nm), st, G.ALLOWLIST, sc)
    return nm, errs
with ThreadPoolExecutor(4) as ex:
    for nm, errs in ex.map(run, names):
        print(f"{'CAUGHT' if errs else 'MISSED'} alias `{nm}` -> raw-bearing record, held by pointer: " + (errs[0].splitlines()[0][:150] if errs else ""))
