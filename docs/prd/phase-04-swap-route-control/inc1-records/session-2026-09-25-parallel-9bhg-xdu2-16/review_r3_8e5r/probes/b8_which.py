import os, sys
sys.dont_write_bytecode = True
ROOT = sys.argv[1]; sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
A = "struct TaintSet {"
orig = G._dump
def dump(d, n):
    rs, e = orig(d, n)
    if n != "TaintSet":
        for r in rs or []:
            loc = r.get("loc", {}); rng = r.get("range", {}).get("begin", {})
            print(f"  DUMP {n}: kind={r.get('kind')} file={(loc.get('file') or rng.get('file') or loc.get('includedFrom',{}).get('file') or '?')} line={loc.get('line')} fields={[c.get('name') for c in r.get('inner',[]) if c.get('kind')=='FieldDecl'][:6]}")
    return rs, e
G._dump = dump
for nm in ("Result", "Impl"):
    h = hdr.replace(A, f"struct R3RawRec2 {{ llvm::Value *P = nullptr; }};\nusing {nm} = R3RawRec2;\n" + A + f"\n  {nm} *R3AP = nullptr;", 1)
    print(nm); errs, n = G.check(h, st, G.ALLOWLIST, sc); print("  errs", len(errs))
