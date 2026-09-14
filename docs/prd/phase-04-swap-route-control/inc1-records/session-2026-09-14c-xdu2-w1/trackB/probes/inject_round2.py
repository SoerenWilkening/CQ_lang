#!/usr/bin/env python3
"""Injection matrix ROUND 2 — bd xdu2 Track B.

Round 1 ran ONE mutant per clause and reported MISSED=7 of 12.  Every one of the
seven was the same thing: a SECOND clause in the conjunction also refuses the
shape, so deleting one left the fixture green.  That is defence in depth and not
vacuity — but a fixture that passes for a reason other than the one its header
claims still pins the wrong thing, and "the clause is unreachable" and "another
clause got there first" look identical from the outside.

Round 2 removes EVERY clause that refuses each shape, in one mutant.  A fixture
that is still green after that is genuinely vacuous.  `M12` is the reverse
direction: it removes a clause the PROMOTER does not own (Track A's outermost
conjunct) to measure that the promoter really would fire without it.
"""
import subprocess, re
W='/Users/sorenwilkening/Desktop/CQ_xdu2B'
P=f'{W}/ir-pass/src/RailBankPromote.cpp'
S=f'{W}/ir-pass/src/RailBankCarveShim.cpp'
ORIG={P:open('/tmp/cqB/mut/P.orig').read(), S:open('/tmp/cqB/mut/S.orig').read()}

# (name, [(file, old, new), …], [fixtures expected to go RED])
MUTANTS = [
 ("M1'-B2-address-equality (isolated fixture)", [
   (P, "    if (SE.getSCEV(G) != Addr)\n      return false;",
       "    if (false && SE.getSCEV(G) != Addr)\n      return false;")],
  ["railbank_promote_reject_two_cells"]),

 ("M2'-B3 + carve single-exiting-block", [
   (P, "  if (Plan.L->getExitingBlock() != Plan.Latch)\n    return false;",
       "  if (false && Plan.L->getExitingBlock() != Plan.Latch)\n    return false;"),
   (S, "  const BasicBlock *Exiting = L->getExitingBlock();\n  if (!Exiting)\n    return RailBankCarve::RejectTotality;",
       "  const BasicBlock *Exiting = L->getExitingBlock();\n  if (false)\n    return RailBankCarve::RejectTotality;")],
  ["railbank_promote_reject_early_exit"]),

 ("M5'-initializer proof, BOTH halves", [
   (P, "        if (MS->isVolatile() || MS->getRawDest() != Bank || !V || !V->isZero() ||\n            !Len || Len->getZExtValue() != Size)\n          return false;",
       "        if (false)\n          return false;"),
   (S, "        if (SawInit || MS->isVolatile() || MS->getRawDest() != A || !V ||\n            !V->isZero() || !Len || Len->getZExtValue() != Bytes) {",
       "        if (false) {")],
  ["railbank_promote_reject_nonzero_init"]),

 ("M7'-B4 simple access, BOTH halves", [
   (P, "      if (auto *L = dyn_cast<LoadInst>(Memop)) {\n        if (!L->isSimple() || L->getType() != Plan.CellTy)\n          return false;",
       "      if (auto *L = dyn_cast<LoadInst>(Memop)) {\n        if (L->getType() != Plan.CellTy)\n          return false;"),
   (S, "      if (auto *LI = dyn_cast<LoadInst>(Use)) {\n        if (LI->getPointerOperand() == G && LI->isSimple() &&\n            LI->getType() == CellTy)\n          continue;",
       "      if (auto *LI = dyn_cast<LoadInst>(Use)) {\n        if (LI->getPointerOperand() == G &&\n            LI->getType() == CellTy)\n          continue;")],
  ["railbank_promote_reject_volatile_cell"]),

 ("M8'-B5 one writer + carve in-loop store", [
   (P, "      if (isa<StoreInst>(Memop))\n        return false;\n      continue;",
       "      if (false)\n        return false;\n      continue;"),
   (S, "  Loop *L = LI.getLoopFor(SI->getParent());\n  outMsg = \"cq rail bank: cell index is not an injective per-activation add-recurrence\";\n  if (!L)\n    return RailBankCarve::RejectIndex;",
       "  Loop *L = LI.getLoopFor(SI->getParent());\n  outMsg = \"cq rail bank: cell index is not an injective per-activation add-recurrence\";\n  if (!L)\n    return RailBankCarve::Bank;")],
  ["railbank_promote_reject_store_outside_loop"]),

 ("M9'-C1 escape, BOTH halves", [
   (P, "    auto *G = dyn_cast<GetElementPtrInst>(UI);\n    if (!G || G->use_empty())\n      return false;",
       "    auto *G = dyn_cast<GetElementPtrInst>(UI);\n    if (!G || G->use_empty())\n      continue;"),
   (S, "    auto *G = dyn_cast<GetElementPtrInst>(U);\n    if (!G) {\n      // A call argument, an `inttoptr`/`ptrtoint`, a pointer phi/select: the\n      // address escapes, or the object is accessed at a shape not modelled here.\n      outMsg = \"cq rail bank: array address escapes or is accessed off-shape\";\n      return RailBankCarve::RejectShape;\n    }",
       "    auto *G = dyn_cast<GetElementPtrInst>(U);\n    if (!G) {\n      continue;\n    }")],
  ["railbank_promote_reject_escaping_address"]),

 ("M12-carve OUTERMOST-loop conjunct (Track A's, not mine)", [
   (S, "  if (L->getParentLoop())\n    return RailBankCarve::RejectIndex;",
       "  if (false && L->getParentLoop())\n    return RailBankCarve::RejectIndex;")],
  ["railbank_promote_reject_nested_outer_loop"]),
]

def restore():
    for f,t in ORIG.items(): open(f,'w').write(t)
def build():
    r=subprocess.run(['cmake','--build','build','-j8'],cwd=W,capture_output=True,text=True)
    return r.returncode==0, r.stdout+r.stderr
def lit():
    r=subprocess.run(['lit','ir-pass/test','--filter','railbank_'],cwd=f'{W}/build',capture_output=True,text=True)
    return {m.group(1) for m in re.finditer(r'FAIL: CQ IR-pass :: (\S+)\.ll', r.stdout+r.stderr)}

restore(); ok,log=build(); assert ok, log[-3000:]
base=lit(); print(f"BASELINE: {len(base)} red (expected 0): {sorted(base)}")
missed=0; na=0; total=0; rows=[]
for name,edits,expect in MUTANTS:
    restore()
    bad=False
    for f,old,new in edits:
        t=open(f).read()
        if t.count(old)!=1:
            rows.append(f"  {name:46s} N/A  anchor count={t.count(old)}  *** HOLE ***"); na+=1; bad=True; break
        open(f,'w').write(t.replace(old,new))
    if bad: continue
    ok,log=build()
    if not ok:
        rows.append(f"  {name:46s} N/A  mutant does not compile  *** HOLE ***"); na+=1; continue
    red=lit(); total+=1
    miss=[e for e in expect if e not in red]; missed+=len(miss)
    rows.append(f"  {name:46s} {'CAUGHT' if not miss else 'MISSED'}  missed={miss}  also_red={sorted(red-set(expect))}")
restore(); ok,log=build(); assert ok, log[-3000:]
print("\n".join(rows))
print(f"\nround-2 mutants={total} applied, N/A={na} (each N/A is a HOLE, not a pass), MISSED={missed}")
