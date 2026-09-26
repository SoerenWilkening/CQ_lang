#!/usr/bin/env python3
"""Rule-13 r3 (8e5r), second batch: POINTERS to non-project types. Same harness as
guard_fool_r3.py (guard imported unmodified, check() called, controls first)."""
import os, sys, time
sys.dont_write_bytecode = True
ROOT = sys.argv[1]; sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
A = "struct TaintSet {"
def ins(m, pre=""):
    return hdr.replace("#include <set>\n", "#include <set>\n" + G.EXTRA_INCLUDES, 1).replace(A, pre + A + "\n  " + m, 1)
def ins_global(m, pre):
    # `pre` placed at GLOBAL scope, before `namespace cq {`
    h = hdr.replace("#include <set>\n", "#include <set>\n" + G.EXTRA_INCLUDES, 1)
    assert h.count("namespace cq {") >= 1
    h = h.replace("namespace cq {", pre + "namespace cq {", 1)
    return h.replace(A, A + "\n  " + m, 1)
P = [
  ("NULL: pristine", hdr, True, False),
  ("POS: std::set<Value*> by value", ins("std::set<llvm::Value *> R3S;"), True, True),
  ("POS: unique_ptr<std::set<Value*>>", ins("std::unique_ptr<std::set<llvm::Value *>> R3U;"), True, True),
  ("C1 raw POINTER to a library container of raw Value*: std::set<llvm::Value *> *",
   ins("std::set<llvm::Value *> *R3SetPtr = nullptr;"), False, True),
  ("C2 raw POINTER to llvm::DenseMap<llvm::Value *, unsigned>",
   ins("llvm::DenseMap<llvm::Value *, unsigned> *R3MapPtr = nullptr;"), False, True),
  ("C3 raw POINTER to llvm::SmallPtrSet<llvm::Instruction *, 4>",
   ins("llvm::SmallPtrSet<llvm::Instruction *, 4> *R3SPSPtr = nullptr;"), False, True),
  ("C4 pointer to a GLOBAL-namespace record holding a raw Value*",
   ins_global("R3G *R3GP = nullptr;", "struct R3G { llvm::Value *P = nullptr; };\n"), False, True),
  ("C4b the same GLOBAL record held BY VALUE (control: closed world refuses)",
   ins_global("R3G R3GV;", "struct R3G { llvm::Value *P = nullptr; };\n"), True, True),
  ("C5 pointer to a record in a NON-cq project namespace holding a raw Value*",
   ins_global("cqx::R3X *R3XP = nullptr;", "namespace cqx { struct R3X { llvm::Value *P = nullptr; }; }\n"), False, True),
  ("C6 SmallVector of POINTERS to a raw library table",
   ins("llvm::SmallVector<llvm::DenseSet<llvm::Value *> *, 2> R3VecOfTblPtr;"), False, True),
]
t0 = time.time(); missed = []; bad = []
for label, h, ctl, expect in P:
    errs, n = G.check(h, st, G.ALLOWLIST, sc)
    c = bool(errs)
    if ctl:
        ok = c == expect; tag = ("ok " if ok else "BAD") + (" control-refused" if c else " control-clean")
        if not ok: bad.append(label)
    else:
        tag = "CAUGHT" if c else "MISSED"
        if not c: missed.append(label)
    print(f"{tag:22s} {label}  [{n} members]")
    for e in errs[:2]: print("        " + e.splitlines()[0][:200])
print(f"\ncontrols bad: {len(bad)}; attacks {sum(1 for p in P if not p[2])}, MISSED {len(missed)}")
print(f"elapsed {time.time()-t0:.1f}s PCH {G._PCH['state']}")
import shutil
if G._PCH["dir"]: shutil.rmtree(G._PCH["dir"], ignore_errors=True)
