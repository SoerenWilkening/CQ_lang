// SelectMergeEmit.cpp — see header. The mutating controlled-XOR copy merge for an
// accepted tainted-condition integer-data `select` (Phase 4.4 / PRD Part IV
// §16.3; IMPLEMENTATION-4.4 §4). NO rail, NO route `cqrt_cswap`, NO
// `RegionFlatten`, NO reverse-play — the single biggest simplification vs. the
// br-diamond emitters. Reuses `lowerCompareToFlag` (mint/strip), `allocFn`/
// `freeFn` (rail + the one free), `copyControlledFn` (the merge primitive), and
// `xFn` (the ¬flag bracket) verbatim (Rule 14); the only original logic is the
// six-step ordering, which IS the §5a contract.
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2):
// with `%out` allocated to |0>, `copy_c(f, a, out)` writes a iff f=1 and the
// X-bracketed `copy_c(f, b, out)` writes b iff f=0, so `%out = f ? a : b` with no
// double-write on either basis branch — provided the `cqrt_x` encloses ONLY the
// second copy (the §16.3 bracket-order hazard, invisible to a count-only CHECK;
// pinned by the §5a ordered FileCheck). The flag is stripped by `icmp_inv` (q is
// untouched — the copies write `out`, never q — so q == q0 and the strip is
// valid) and freed; q, `%out`, and both operands are left allocated (Rule 6/8).

#include "SelectMergeEmit.h"

#include "CompareLowering.h"    // lowerCompareToFlag (mint + _inv strip)
#include "ControlPlan.h"        // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"  // copyControlledFn / xFn
#include "OpcodeSupport.h"      // abiWidthFromType
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"      // allocFn / freeFn / llvmWidthType

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// so a later module walk (`lowerRotations` / `lowerOps` / `uncompute`) never
// dereferences freed memory (§6.1 — the dangling-work-list SIGSEGV). A per-TU
// mirror of `SwapRouteEmit::scrubTaint` (the house style for trivial taint-set
// maintenance, cf. the duplicated `isMeasureSink`). Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
  }
}

}  // namespace

// Shared copy-source materializer (promoted from the former file-local `static
// materialize`; see SelectMergeEmit.h for the contract). Now consumed by the
// select merge below, `SwitchDataMuxEmit`, and `ClassicalCallArmEmit` (Rule 14).
Value *materializeCopySource(Value *V, FunctionCallee Alloc,
                             const TaintSet &taint, IRBuilder<> &B,
                             const DebugLoc &DL, const Twine &Name) {
  if (taint.Tainted.count(V))
    return V;  // already an i32 quantum handle.
  CallInst *H = B.CreateCall(Alloc, {V}, Name);
  if (DL)
    H->setDebugLoc(DL);
  return H;
}

void emitSelectRegion(const ControlRegion &R, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint) {
  auto *Sel = dyn_cast_or_null<SelectInst>(R.Merge);
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  if (!Sel || !Cond) {
    // Detection guarantees the shape (SelectClassify pushes only a SelectInst
    // Merge + CmpInst Condition); if it ever fails to hold, bail LOUDLY — a
    // silently skipped accepted region leaves the tainted select to the backend
    // as classical control over quantum state (the unforgivable outcome, Rule 1).
    if (R.Merge)
      diagnoseUnderControl(R.Merge, "control flow");
    return;
  }

  Value *Tru = Sel->getTrueValue();
  Value *Fls = Sel->getFalseValue();

  // Result-width (Wd) source (§4, the resolved gotcha): read at emit time, which
  // runs BEFORE `lowerRotations` launders handles to i32 — so the select still
  // carries its real logical type. NEVER a post-RAUW i32 read. Detection's gate 4
  // already proved a scalar ABI width with a reversible/controlled copy (integer
  // {i1..i64} or, since the §16.4 un-staging, scalar fp {f16..f80} —
  // fp-data-select-PRD §4.4), so a null here is a malformed plan — decline
  // LOUDLY, lower nothing (Rule 1). The copy minter is selected by result type:
  // integer → the shared `copyControlledFn` (whose integer-only null is the 6.5
  // classical-call arm's live classifier and must not be relaxed — DD-7), scalar
  // fp → the select-local `copyControlledFpFn` (§4.2). The fp rail alloc
  // `Constant::getNullValue(RailTy)` yields `double 0.0`/`half 0xH0000`/…,
  // matching the fp `cqrt_alloc_f<W>` signatures.
  StringRef Abi = abiWidthFromType(Sel->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  FunctionCallee Copy = Abi.empty() ? FunctionCallee()
                        : Sel->getType()->isFloatingPointTy()
                            ? csyms.copyControlledFpFn(Abi)
                            : csyms.copyControlledFn(Abi);
  if (!RailTy || !Alloc || !Copy) {
    diagnoseUnderControl(Sel, "control flow");
    return;
  }

  const DebugLoc DL = Sel->getDebugLoc();
  IRBuilder<> B(Sel);  // every stream call lands immediately before the select.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. MINT the flag — cq_template_icmp_<pred>_<Wc>_hl(q, k). Wc is the condition
  //    operand width, resolved internally by lowerCompareToFlag.
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/Sel);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported width / Q+Q).

  // 2. ALLOC the |0> result rail (Wd). It joins `taint.Tainted` (+BirthOrder) so
  //    downstream consumers of the RAUW'd select keep classifying it as a quantum
  //    handle; its only users are cqrt_*/template calls, so `uncompute` never
  //    selects it as a terminal (isTerminalHandle is false — §16.5) and it is
  //    never freed (the live result, owned by the user's measure / ret).
  CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
  stamp(Out);
  taint.Tainted.insert(Out);
  taint.ControlOwnedRails.insert(Out);  // DD-4: Phase-4 owns this merge out-rail
  taint.BirthOrder[Out] = taint.NextBirth++;

  // 3. COPY the TRUE value on the flag (materialize if classical) — fires on f=1.
  Value *TrueSrc = materializeCopySource(Tru, Alloc, taint, B, DL);
  stamp(B.CreateCall(Copy, {Flag, TrueSrc, Out}));

  // 4. COPY the FALSE value on ¬flag, X-bracketed (the 4.1 self-inverse cqrt_x
  //    convention). The bracket encloses ONLY this second copy: a mis-bracket
  //    (x before BOTH copies) yields the identical symbol multiset yet writes a
  //    then b on one basis branch = wrong %out (§16.3, the load-bearing hazard).
  stamp(B.CreateCall(csyms.xFn(), {Flag}));
  Value *FalseSrc = materializeCopySource(Fls, Alloc, taint, B, DL);
  stamp(B.CreateCall(Copy, {Flag, FalseSrc, Out}));
  stamp(B.CreateCall(csyms.xFn(), {Flag}));

  // 5. STRIP the flag + the SINGLE free. Structurally valid outright: the merge
  //    never wrote Cond's lineage (the copies write `%out`, never q), so q == q0
  //    and the `_inv` un-computes the flag to |0> (provably free-able). Reads
  //    Cond's operands — MUST precede any erase of Cond (step 6).
  lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                     /*before=*/Sel);
  stamp(B.CreateCall(wd.freeFn(), {Flag}));

  // 6. REWIRE — RAUW %sel -> %out, scrub, erase. NO flatten (there is no CFG).
  //    The user's measure/ret on the select becomes one on %out (no measurement
  //    is added — Rule 5).
  Sel->replaceAllUsesWith(Out);
  scrubTaint(Sel, taint);
  Sel->eraseFromParent();

  // The select's condition compare is now (in the canonical single-use case)
  // dead: the mint/strip built FRESH `cq_template_icmp` templates from Cond's
  // operands (lowerCompareToFlag does not consume Cond), so the original stock
  // `icmp` has lost its only user. Scrub + erase it so `lowerOps` (L111) does not
  // lower a spurious dead compare into the trace. A SHARED compare (also read as
  // data — clang -O1 CSEs `int f=(q>5)` with the select condition) keeps its
  // other users; leave it for `lowerOps` to lower for that independent data use.
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
}

}  // namespace cq
