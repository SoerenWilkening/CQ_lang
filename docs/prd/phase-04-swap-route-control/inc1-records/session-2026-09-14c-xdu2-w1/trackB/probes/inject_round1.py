#!/usr/bin/env python3
"""Injection matrix, BINARY mutation — bd xdu2 Track B.

A decline fixture for an ACCEPT-ONLY normaliser is the vacuity trap in its purest
form: when the stage refuses, the module is byte-identical to not having the
stage at all, so the fixture can pass because the clause works OR because the
clause is unreachable.  The only instrument that separates those is to DELETE the
clause from the binary and watch the fixture go red.

Each mutant removes exactly one clause.  A fixture named in `expect_red` that
stays GREEN is a MISSED mutation — the clause it claims to pin is not the reason
it passes.
"""
import subprocess, sys, os, shutil, re
W='/Users/sorenwilkening/Desktop/CQ_xdu2B'
P=f'{W}/ir-pass/src/RailBankPromote.cpp'
S=f'{W}/ir-pass/src/RailBankCarveShim.cpp'
ORIG={P:open('/tmp/cqB/mut/P.orig').read(), S:open('/tmp/cqB/mut/S.orig').read()}

MUTANTS = [
 # (name, file, old, new, [fixtures expected to go RED])
 ("M1-B2-address-equality", P,
  "    if (SE.getSCEV(G) != Addr)\n      return false;",
  "    if (false && SE.getSCEV(G) != Addr)\n      return false;",
  ["railbank_promote_reject_two_cells"]),
 ("M2-B3-single-exiting-block", P,
  "  if (Plan.L->getExitingBlock() != Plan.Latch)\n    return false;",
  "  if (false && Plan.L->getExitingBlock() != Plan.Latch)\n    return false;",
  ["railbank_promote_reject_early_exit"]),
 ("M3-in-loop-observer-fence", P,
  "  for (Instruction *I : NonRewritable)\n    if (Plan.L->contains(I->getParent()))\n      return false;",
  "  for (Instruction *I : NonRewritable)\n    if (false && Plan.L->contains(I->getParent()))\n      return false;",
  ["railbank_promote_reject_inloop_other_read"]),
 ("M4-C3-taint-half", S,
  "  if (!taint.Tainted.count(const_cast<Value *>(SI->getValueOperand())))\n    return RailBankCarve::NotBank;",
  "  if (false)\n    return RailBankCarve::NotBank;",
  ["railbank_promote_reject_classical_store"]),
 ("M5-C1-initializer-proof", P,
  "      if (!isWholeObjectZeroStore(SI, Bank))\n        return false;",
  "      if (!isWholeObjectZeroStore(SI, Bank) && false)\n        return false;",
  ["railbank_promote_reject_nonzero_init"]),
 ("M5b-C1-initializer-proof-carve", S,
  "        if (SawInit || MS->isVolatile() || MS->getRawDest() != A || !V ||\n            !V->isZero() || !Len || Len->getZExtValue() != Bytes) {",
  "        if (false) {",
  ["railbank_promote_reject_nonzero_init"]),
 ("M6-C6-totality", S,
  "  if (Trip != AT->getNumElements())\n    return RailBankCarve::RejectTotality;",
  "  if (false && Trip != AT->getNumElements())\n    return RailBankCarve::RejectTotality;",
  ["railbank_promote_reject_oversized_bank"]),
 ("M7-B4-simple-access", P,
  "      if (auto *L = dyn_cast<LoadInst>(Memop)) {\n        if (!L->isSimple() || L->getType() != Plan.CellTy)\n          return false;",
  "      if (auto *L = dyn_cast<LoadInst>(Memop)) {\n        if (L->getType() != Plan.CellTy)\n          return false;",
  ["railbank_promote_reject_volatile_cell"]),
 ("M8-B5-one-writer", P,
  "      if (isa<StoreInst>(Memop))\n        return false;\n      continue;",
  "      if (false)\n        return false;\n      continue;",
  ["railbank_promote_reject_store_outside_loop"]),
 ("M9-C1-escape", P,
  "    auto *G = dyn_cast<GetElementPtrInst>(UI);\n    if (!G || G->use_empty())\n      return false;",
  "    auto *G = dyn_cast<GetElementPtrInst>(UI);\n    if (!G || G->use_empty())\n      continue;",
  ["railbank_promote_reject_escaping_address"]),
 ("M10-B8-at-least-one-load", P,
  "  if (Plan.Loads.empty())\n    return false;",
  "  if (false && Plan.Loads.empty())\n    return false;",
  ["railbank_promote_reject_already_ssa"]),
 ("M11-C2'-addrec-injectivity", S,
  "  if (!AR || AR->getLoop() != L || !AR->isAffine() || !AR->getStart()->isZero())\n    return RailBankCarve::RejectIndex;",
  "  if (!AR && false)\n    return RailBankCarve::RejectIndex;",
  ["railbank_promote_reject_noninjective_index"]),
]

def restore():
    for f,t in ORIG.items(): open(f,'w').write(t)

def build():
    r=subprocess.run(['cmake','--build','build','-j8'],cwd=W,capture_output=True,text=True)
    return r.returncode==0, r.stdout+r.stderr

def lit():
    r=subprocess.run(['lit','ir-pass/test','--filter','railbank_'],cwd=f'{W}/build',
                     capture_output=True,text=True)
    red=set()
    for m in re.finditer(r'FAIL: CQ IR-pass :: (\S+)\.ll', r.stdout+r.stderr):
        red.add(m.group(1))
    return red, r.stdout+r.stderr

restore()
ok,log=build()
assert ok, log[-3000:]
base_red,_=lit()
print(f"BASELINE: {len(base_red)} red (expected 0): {sorted(base_red)}")
missed=0; na=0; total=0; rows=[]
for name,f,old,new,expect in MUTANTS:
    restore()
    t=ORIG[f]
    if t.count(old)!=1:
        na+=1; rows.append(f"  {name:38s} N/A  anchor count={t.count(old)}  *** HOLE ***"); continue
    open(f,'w').write(t.replace(old,new))
    ok,log=build()
    if not ok:
        na+=1; rows.append(f"  {name:38s} N/A  mutant does not compile  *** HOLE ***"); continue
    red,_=lit()
    total+=1
    caught=[e for e in expect if e in red]
    miss=[e for e in expect if e not in red]
    missed+=len(miss)
    extra=sorted(red-set(expect))
    rows.append(f"  {name:38s} {'CAUGHT' if not miss else 'MISSED'}  by={caught}  missed={miss}  also_red={extra}")
restore()
ok,log=build()
assert ok, log[-3000:]
print("\n".join(rows))
print(f"\nmutants={total} applied, N/A={na} (each N/A is a HOLE, not a pass), MISSED={missed}")
