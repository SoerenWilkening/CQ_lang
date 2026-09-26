import os, sys
sys.dont_write_bytecode = True
ROOT = sys.argv[1]; sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
A = "struct TaintSet {"
def ins(m, pre=""):
    return hdr.replace("#include <set>\n", "#include <set>\n" + G.EXTRA_INCLUDES, 1).replace(A, pre + A + "\n  " + m, 1)
orig_dump, orig_resolve = G._dump, G._resolve
def dump(d, n):
    rs, e = orig_dump(d, n)
    print("  DUMP", n, "->", [(r.get("kind"), r.get("name"), r.get("loc", {}).get("line")) for r in (rs or [])])
    return rs, e
def resolve(d, items):
    out = orig_resolve(d, items)
    print("  RESOLVE", [(it[0], it[3]) for it in items], "->", out)
    return out
G._dump, G._resolve = dump, resolve
for lbl, h in [("B8", ins("R3Rec *R3AP = nullptr;", "namespace r3other { struct R3Rec { unsigned X = 0; }; }\nstruct R3RawRec2 { llvm::Value *P = nullptr; };\nusing R3Rec = R3RawRec2;\n")),
               ("B1", ins("R3Spec<unsigned> R3S;", "template <typename T> struct R3Spec { T X{}; };\ntemplate <> struct R3Spec<unsigned> { llvm::Value *P = nullptr; };\n")),
               ("B7", ins("std::set<R3Key> R3KS;", "struct R3Key { llvm::WeakVH H; bool operator<(const R3Key &O) const { return static_cast<llvm::Value *>(H) < static_cast<llvm::Value *>(O.H); } };\n"))]:
    print(lbl)
    errs, n = G.check(h, st, G.ALLOWLIST, sc)
    print("  errs:", errs[:2], "members", n)
