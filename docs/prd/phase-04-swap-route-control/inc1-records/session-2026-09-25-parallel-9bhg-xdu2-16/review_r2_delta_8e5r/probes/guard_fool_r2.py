#!/usr/bin/env python3
"""Rule-13 r2-delta (8e5r): try to fool the AST taintset_scrub_guard (c150d983).
Imports the guard UNMODIFIED from the subject tree and calls its check() with
mutated TaintPropagation.h texts. Controls first: the pristine header must be
clean (null), a plain raw `llvm::Value *` member must be refused (positive).
Each probe prints CAUGHT (with the first diagnostic) or MISSED.
usage: guard_fool_r2.py <subject-worktree>"""
import os, sys, time
ROOT = sys.argv[1]
sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G

hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
ANCH = "struct TaintSet {"
assert hdr.count(ANCH) == 1

INC = """#include <memory>
#include <set>
#include <functional>
#include <cstdint>
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/PointerIntPair.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Use.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Analysis/LoopInfo.h"
"""
def ins(member, pre=""):
    h = hdr.replace("#include <set>\n", "#include <set>\n" + INC, 1)
    assert h != hdr
    return h.replace(ANCH, pre + ANCH + "\n  " + member, 1)

RAWREC = "struct R2RawRec { llvm::Value *P = nullptr; };\n"
RAWTMPL = "template <typename T> struct R2RawHolder { llvm::Value *P = nullptr; T X{}; };\n"
P = [
  # (label, header, selftest, expect_caught)
  ("NULL: pristine header", hdr, st, False),
  ("NULL: pristine + probe includes", ins(""), st, False),
  ("POS: raw llvm::Value * member", ins("llvm::Value *R2Stray = nullptr;"), st, True),
  ("POS: std::function<void()>", ins("std::function<void()> R2Fn;"), st, True),
  ("POS: PointerIntPair<Value*,1>", ins("llvm::PointerIntPair<llvm::Value *, 1> R2PIP;"), st, True),
  ("POS: BasicBlock::iterator", ins("llvm::BasicBlock::iterator R2It;"), st, True),
  ("POS: unique_ptr<Instruction>", ins("std::unique_ptr<llvm::Instruction> R2UP;"), st, True),
  ("POS: nested record by value holding raw ptr", ins("llvm::SmallVector<R2RawRec, 2> R2Recs;", RAWREC), st, True),
  # --- attacks
  ("A1 project CLASS TEMPLATE holding a raw Value*, instantiated <int>",
   ins("R2RawHolder<int> R2H;", RAWTMPL), st, True),
  ("A2 SmallVector of a project class template spec",
   ins("llvm::SmallVector<R2RawHolder<unsigned>, 2> R2HV;", RAWTMPL), st, True),
  ("A3 type-erased identity set SmallPtrSet<const void *>",
   ins("llvm::SmallPtrSet<const void *, 8> R2Seen;"), st, True),
  ("A4 uintptr_t-keyed DenseMap",
   ins("llvm::DenseMap<std::uintptr_t, unsigned> R2ByAddr;"), st, True),
  ("A5 #ifdef NDEBUG raw member (Release build defines NDEBUG; the guard does not)",
   ins("#ifdef NDEBUG\n  llvm::Value *R2RelOnly = nullptr;\n#endif"), st, True),
  ("A6 vector of POINTERS to a project record holding raw Value*",
   ins("llvm::SmallVector<R2RawRec *, 2> R2RecPtrs;", RAWREC), st, True),
  ("A7 ScrubMap MAPPED pointer to a project record holding raw Value*",
   ins("ScrubMap<llvm::Value *, R2RawRec *> R2MapRec;", RAWREC),
   st + "\nstatic void r2a7(cq::TaintSet &T) { (void)T.R2MapRec; }\n", True),
  ("A8 std::shared_ptr<void>", ins("std::shared_ptr<void> R2Opaque;"), st, True),
  ("A9 DenseMap<llvm::Loop *, unsigned> (non-Value, freed with LoopInfo)",
   ins("llvm::DenseMap<llvm::Loop *, unsigned> R2LoopKey;"), st, True),
  ("A10 SmallVector<llvm::Use *> (Use holds Value*)",
   ins("llvm::SmallVector<llvm::Use *, 4> R2Uses;"), st, True),
  ("A11 std::set<llvm::WeakVH> (handle as an ORDERED key: nulls in place)",
   ins("std::set<llvm::WeakVH> R2WSet;"), st, True),
  ("A12 raw ptr behind `using` in ANOTHER header (LoopPlan.h-style), by value",
   ins("R2Alias R2AliasMember;", "using R2Alias = llvm::SmallPtrSet<llvm::Instruction *, 4>;\n"), st, True),
]
t0 = time.time(); missed = []; bad_ctl = []
for label, h, s, expect in P:
    errs, n = G.check(h, s, G.ALLOWLIST, sc)
    caught = bool(errs)
    if label.startswith(("NULL", "POS")):
        ok = (caught == expect)
        tag = ("ok " if ok else "BAD") + (" control-refused" if caught else " control-clean")
        if not ok: bad_ctl.append(label)
    else:
        tag = "CAUGHT" if caught else "MISSED"
        if not caught: missed.append(label)
    print(f"{tag:22s} {label}  [{n} members]" + (f"\n      -> {errs[0].splitlines()[0][:180]}" if errs else ""))
print(f"\n{len(P)} probes ({sum(1 for p in P if p[0].startswith(('NULL','POS')))} controls), "
      f"controls bad: {len(bad_ctl)}, attacks MISSED: {len(missed)} of "
      f"{sum(1 for p in P if not p[0].startswith(('NULL','POS')))}; {time.time()-t0:.0f}s")
for m in missed: print("  MISSED:", m)
