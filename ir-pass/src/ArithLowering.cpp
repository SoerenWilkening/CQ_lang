// ArithLowering.cpp — per-instruction lowering for the two data-arithmetic
// classes (binary + unary `fneg`). See header for the operand-shape rules.
// Generalizes the Phase-2 `add`/`fadd` body to all 16 in-scope stems with
// HH/HL/LH shapes and commutativity-gated BirthOrder; the driver
// (`OpcodeLowering`) owns collection, program order, and erase.

#include "ArithLowering.h"

#include "ChainWalk.h"      // isInPlaceGateOn (the ONE in-place-gate relation)
#include "LoopPlan.h"       // inPlaceValueRailOperand (the dtzb shape predicate)
#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"
#include "WireWalk.h"       // provablyBefore (the shared position-aware proof)

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

namespace {

// Promote `repl` into the taint set as the lowered replacement for `orig`,
// drop `orig` from the set, and give `repl` the next BirthOrder slot. This
// is the exact Phase-2 bookkeeping, shared by the binary and unary paths.
// The driver erases `orig` afterward (we only RAUW + bookkeep here).
//
// Phase 7.1 Increment A: `handleWidth` records the lowered handle's LOGICAL
// ABI width on `repl` (the data result width — Increment A's first reader is
// the Q+Q data-position compare, which recovers it from `HandleWidth`). Empty
// ⇒ no record (the pre-7.1 behavior; a genuinely-missing entry rides the Q+Q
// decline rather than defaulting to i32). R-A scrub: `HandleWidth.erase(orig)`
// mirrors the `Tainted.erase` — with `Value*` pointer reuse a stale entry at
// `orig`'s reused address would otherwise feed a wrong width into a later Q+Q
// compare (a verify-clean miscompile). The erase happens UNCONDITIONALLY (even
// when `handleWidth` is empty) so no stale `orig` record survives.
void promote(Value *repl, Instruction *orig, TaintSet &taint,
             StringRef handleWidth = {}) {
  taint.Tainted.insert(repl);
  taint.Tainted.erase(orig);
  taint.BirthOrder[repl] = taint.NextBirth++;
  taint.HandleWidth.erase(orig);
  if (!handleWidth.empty())
    taint.HandleWidth[repl] = handleWidth;
}

// ── M-C Inc 2b (bd test_C_libtooling-6uqc): NEGATE A CLASSICAL IMMEDIATE ────
//
// `q - c` is emitted as the in-place `cqrt_addc_<W>(q, -c)`. There is NO
// `cqrt_subc_` and there must not be one: the runtime contract is
// `h := (h + imm) mod 2^W` (runtime/cq_runtime.h), and `x - c` and `x + (-c)`
// are the SAME basis permutation at every width, so a new frozen symbol would
// buy a value the compiler already computes at emission time (Rule 15 / the
// Phase-11 freeze surface is untouched by this batch).
//
// THE NEGATION IS CLASSICAL CODE, and that is the whole safety story. It never
// touches the rail, never enters `taint.Tainted` (it is created in Phase 2 of
// `lowerOps`, after the taint set and the M-C fence have both been read), and
// emits no trace line — the golden sees only the negated VALUE in the `addc`
// immediate slot.
//
// TWO SPELLINGS, deliberately not one:
//   * a `ConstantInt` folds HERE, with a WRAPPING `APInt` negation. This is not
//     a micro-optimisation: the source op routinely carries `nsw`, and
//     `-INT_MIN` is not representable in a signed iW, so a signed-overflow-
//     asserting fold would abort the compiler on well-defined input
//     (`lowering_mc_subc_intmin.ll`). `APInt::operator-()` is two's-complement
//     (`flipAllBits(); ++`), so INT_MIN maps to INT_MIN — which is the
//     arithmetically correct answer mod 2^W and the only one the reversible
//     gate can mean. At i1 it collapses to the identity (`-1 == 1 mod 2`), which
//     is why `free_pairing_check.py` carries an explicit `i1 true`/`i1 true`
//     pairing arm.
//   * anything else — the campaign customer's `volatile` load, ordinary
//     classical arithmetic — gets an ORDINARY `sub iW 0, %v` instruction. That
//     is a shape `free_pairing_check.py`'s rule (A1) `provably_not_a_rail` reads
//     as classical on POSITIVE evidence (a plain classical instruction result
//     that is neither a rail, a formal parameter, nor a rail-minting call — its
//     docstring names `sub i32 0, %6` as an already-measured member of that
//     class). NOTE THE LIMIT OF THAT CLAIM (2b Rule-13 round, F1): (A1) clears
//     the IMMEDIATE SLOT only — it does not make the write history reduce.
//     `is_negation` cannot pair two SSA-NAMED immediates (`%v` vs
//     `sub iW 0, %v`), so a DEAD-and-freed rail whose addc immediates are SSA
//     values reports UNPROVEN (loud, safe direction; lowering_mc_subc_ssa_imm's
//     own stream is the measured example, and the 2a `add` analogue behaves
//     identically). No shipped strict slice hits it — all 36 SSA-immediate addc
//     sites live in slices that never free the rail or run --allow-unproven.
//     G4 independently holds out the one shape (A1) could not vouch for, a
//     formal PARAMETER immediate.
//
// A non-`ConstantInt` CONSTANT (a `ptrtoint` constexpr, say) rides the second
// path: `IRBuilder`'s folder either folds it or materialises a real `sub`, both
// of which are classical and neither of which is a rail.
Value *negateClassicalImmediate(Value *Imm, IRBuilder<> &B,
                                const Instruction *At) {
  if (auto *CI = dyn_cast<ConstantInt>(Imm))
    return ConstantInt::get(CI->getContext(), -CI->getValue());
  Value *N = B.CreateNeg(Imm, "cq_negimm");
  if (auto *NI = dyn_cast<Instruction>(N))
    if (DebugLoc DL = At->getDebugLoc())
      NI->setDebugLoc(DL);
  return N;
}

}  // namespace

bool rewriteBinary(BinaryOperator *bo, WidthDispatch &wd, TaintSet &taint) {
  // Stem + width gating. An out-of-scope opcode (`binaryStem` empty) or an
  // unsupported width (`abiWidthFromType` empty) hits the loud diagnostic
  // and is left un-lowered — the driver must not erase it.
  StringRef Stem = binaryStem(bo->getOpcode());
  if (Stem.empty()) {
    diagnoseNoTemplate(bo);
    return false;
  }
  StringRef AbiWidth = abiWidthFromType(bo->getType());
  if (AbiWidth.empty()) {
    diagnoseNoTemplate(bo);
    return false;
  }
  // i80 binary fence (bd 3c6m.51): i80 is an INTERMEDIATE x86_fp80 bit-pattern
  // width shipping ONLY four bitwise ops — `and` (mask) + `lshr` (word offset
  // shift), the Inc-1 EXTRACTION (read) ops, plus `or` (combine) + `shl` (position
  // shift), the Inc-2 field-insert (write) ops the promoteFp80Union RMW pack emits.
  // Every OTHER binary op at i80 (add/sub/mul/xor/ashr/div/rem) has NO generated
  // template; without this gate `dataTemplateFn` would `getOrInsertFunction` a
  // phantom `cq_template_<op>_i80` extern (verify-clean, exit 0, LINK-FAILS at
  // Stage 3) — the n0ui i128 phantom-mint lesson at a narrower surface. Decline
  // LOUDLY and leave `bo` standing (well-typed, verify-clean); over-decline is safe
  // (Prime Directive). and/lshr/or/shl are the shipped i80 rows (opcode_table.yaml).
  if (AbiWidth == "i80" && !i80BinaryInScope(Stem)) {
    diagnoseNoTemplate(bo);
    return false;
  }
  // Domain sanity: integer stems must land on an integer width and fp
  // stems on an fp width. `binaryStem` already partitions the opcodes; this
  // guards against malformed IR picking a mismatched template.
  const bool FpStem = bo->getType()->isFloatingPointTy();
  const bool IntStem = bo->getType()->isIntegerTy();
  const bool WantsFp = Stem.starts_with("f");  // fadd/fsub/fmul/fdiv/frem
  if ((WantsFp && !FpStem) || (!WantsFp && !IntStem)) {
    diagnoseNoTemplate(bo);
    return false;
  }

  IRBuilder<> Builder(bo);
  Value *A = bo->getOperand(0);
  Value *B = bo->getOperand(1);

  // Operand classification by taint membership (authoritative — covers
  // tainted args/loads as handles and untainted args/literals/globals as
  // classical; `isa<Constant>` would misclassify both, which the
  // `lowering_q_plus_arg` fixture pins).
  const bool ATainted = taint.Tainted.count(A) != 0;
  const bool BTainted = taint.Tainted.count(B) != 0;
  const bool Commutative = isCommutative(bo->getOpcode());

  Value *Lhs = nullptr;
  Value *Rhs = nullptr;
  Shape ShapeSel;
  if (ATainted && BTainted) {
    // HH → symmetric QQ template. Commutative: order by BirthOrder (lower
    // → LHS) for stable traces. Non-commutative: preserve source order
    // (the BirthOrder swap is gated OFF — operand order is semantic).
    Lhs = A;
    Rhs = B;
    if (Commutative) {
      const unsigned BA = taint.BirthOrder.lookup(A);
      const unsigned BB = taint.BirthOrder.lookup(B);
      // 0 means "unassigned"; only swap when both are known and B is
      // lower-birth. Falls back to source order otherwise (harmless).
      if (BA != 0 && BB != 0 && BB < BA) {
        Lhs = B;
        Rhs = A;
      }
    }
    ShapeSel = Shape::QQ;
  } else if (Commutative) {
    // One tainted, commutative → always handle-on-left, literal-on-right
    // `_hl(handle, classical)` regardless of which source side held the
    // classical (the BirthOrder/canonicalization swap is ON).
    Lhs = ATainted ? A : B;
    Rhs = ATainted ? B : A;
    ShapeSel = Shape::HL;
  } else if (ATainted) {
    // Non-commutative, handle on the left, classical on the right → `_hl`
    // with source order preserved.
    Lhs = A;
    Rhs = B;
    ShapeSel = Shape::HL;
  } else {
    // Non-commutative, classical on the left, handle on the right (e.g.
    // `100 - x`, `3 << x`) → `_lh(classical, handle)`, order preserved.
    Lhs = A;
    Rhs = B;
    ShapeSel = Shape::LH;
  }

  FunctionCallee Callee = wd.dataTemplateFn(Stem, AbiWidth, ShapeSel);
  if (!Callee) {
    diagnoseNoTemplate(bo);
    return false;
  }
  CallInst *T = Builder.CreateCall(Callee, {Lhs, Rhs}, "h_op");
  if (DebugLoc DL = bo->getDebugLoc())
    T->setDebugLoc(DL);
  bo->replaceAllUsesWith(T);
  // Record the result handle's LOGICAL width (the binary op's own ABI width,
  // already validated non-empty at :45) so a downstream Q+Q data compare can
  // recover it (Increment A). The i32-laundered handle type loses this width.
  promote(T, bo, taint, AbiWidth);
  return true;
}

bool rewriteUnary(UnaryOperator *uo, WidthDispatch &wd, TaintSet &taint) {
  // `fneg` is the only in-scope unary data op. Anything else is out of
  // scope → loud diagnostic, left un-lowered.
  if (uo->getOpcode() != Instruction::FNeg) {
    diagnoseNoTemplate(uo);
    return false;
  }
  StringRef AbiWidth = abiWidthFromType(uo->getType());
  if (AbiWidth.empty() || !uo->getType()->isFloatingPointTy()) {
    diagnoseNoTemplate(uo);
    return false;
  }

  FunctionCallee Callee = wd.dataTemplateFn("fneg", AbiWidth, Shape::Unary);
  if (!Callee) {
    diagnoseNoTemplate(uo);
    return false;
  }
  IRBuilder<> Builder(uo);
  // The operand is the tainted handle (taint reached this fneg through it);
  // the (i32)->i32 unary template consumes it directly.
  CallInst *T = Builder.CreateCall(Callee, {uo->getOperand(0)}, "h_fneg");
  if (DebugLoc DL = uo->getDebugLoc())
    T->setDebugLoc(DL);
  uo->replaceAllUsesWith(T);
  // Record the fneg result handle's LOGICAL fp width (validated non-empty at
  // :134) for a downstream Q+Q fp data compare (Increment A).
  promote(T, uo, taint, AbiWidth);
  return true;
}

bool rewriteInPlaceValueRail(BinaryOperator *bo, WidthDispatch &wd,
                             TaintSet &taint) {
  // `bo` is a `lowerLoops`-proven rail self-update (issue dtzb) or an M-C
  // straight-line reassignment (`classifyInPlaceReassignment`). Pick the
  // in-place symbol by opcode; the logical width is the op's OWN result type
  // (the rail operand was RAUW'd to the i32 handle by rotation lowering, but
  // `bo`'s result type still carries the width — the cross-type-laundered
  // operand never changes `bo`'s type).
  //
  // `sub` (M-C Inc 2b) shares `add`'s symbol: it is `cqrt_addc_<W>` with the
  // immediate NEGATED (see `negateClassicalImmediate`). It can only arrive here
  // through the M-C route — `inPlaceValueRailOperand`, which is what
  // `lowerLoops` proves its `InPlaceRailOps` with, admits add/xor ONLY, so the
  // dtzb loop path cannot mint a `sub` and this batch does not widen it.
  const Instruction::BinaryOps Op = bo->getOpcode();
  StringRef AbiWidth = abiWidthFromType(bo->getType());
  FunctionCallee Callee =
      Op == Instruction::Xor ? wd.xorcFn(AbiWidth) : wd.addcFn(AbiWidth);
  if (!Callee) {
    // Unsupported width — `inPlaceValueRailOperand` applies the SAME ≤64-integer
    // fence, so this is unreachable; never mint a phantom symbol or leave an
    // ill-typed op (Rule 1). Loud decline.
    diagnoseNoTemplate(bo);
    return false;
  }
  // Exactly one operand is tainted (the rail handle, i32 by now — handles join
  // `Tainted` at the theta mint); the other is the classical immediate at the
  // rail's logical width. The recognizer proved this (one tainted operand), so
  // the selection is unambiguous.
  Value *L = bo->getOperand(0), *R = bo->getOperand(1);
  bool TL = taint.Tainted.count(L) != 0;
  Value *Handle = TL ? L : R;
  Value *Imm = TL ? R : L;
  // `sub` IS NOT COMMUTATIVE, and getting this backwards is the one way this
  // emission could be a silent miscompile: `c - q` is negate-the-RAIL then add
  // — a rewrite of the whole register, which `cqrt_addc_<W>` cannot express —
  // whereas the emission below computes `q + (-c)`. The recognizer
  // (`inPlaceReassignRailOperand`) admits HANDLE-LHS ONLY, so a tainted RHS
  // cannot reach here; the check is defense in depth, and it fails LOUD rather
  // than emitting the wrong permutation (Prime Directive). Unreachable through
  // the shipped surface — `lowering_mc_sub_fence_fallback.ll`'s
  // `@classical_lhs` pins that `c - q` never even reaches the fence's accept.
  if (Op == Instruction::Sub && !TL) {
    diagnoseNoTemplate(bo);
    return false;
  }
  IRBuilder<> Builder(bo);
  if (Op == Instruction::Sub)
    Imm = negateClassicalImmediate(Imm, Builder, bo);
  CallInst *C = Builder.CreateCall(Callee, {Handle, Imm});
  if (DebugLoc DL = bo->getDebugLoc())
    C->setDebugLoc(DL);
  // In-place: the result IS the rail handle (same register, mutated state). RAUW
  // to the handle — a no-op when the Case-A phi collapse already left `bo`
  // use-empty (the single-op value accumulator), and the correct rewire for a
  // chained self-update (`q1 = q ^ 9; q2 = q1 ^ 3` — `q1`'s RAUW feeds `q2`). The
  // void in-place gate is not itself a tainted producer; the handle stays
  // tainted. The driver erases `bo`.
  bo->replaceAllUsesWith(Handle);
  return true;
}

namespace {

// ── M-C fence helpers (bd test_C_libtooling-6uqc Inc 2a) ────────────────────
//
// G2's OPERAND PICKER, widened for `sub` (Inc 2b). For `add`/`xor` this IS the
// dtzb predicate `inPlaceValueRailOperand`, asked and not re-spelt (Rule 14):
// exactly one tainted operand (the parent rail `P`), one classical immediate,
// an integer width the in-place ABI can serve.
//
// `sub` IS DELIBERATELY NOT ADDED TO THAT SHARED PREDICATE. `inPlaceValueRail
// Operand` is `lowerLoops`' own shape test — it drives `peelInPlaceBase`,
// `loopHasInPlaceRailStructure` and the `InPlaceRailOps` proof — so widening it
// would silently widen the 7.3/7.4 LOOP recognizer's accepted rail vocabulary
// in the same edit, which is a different Rule-13 surface with a different
// customer and no fixture in this batch. The `sub` rule therefore lives here,
// in the M-C fence, and the loop path is byte-for-byte untouched.
//
// AND IT IS DIRECTIONAL, which the add/xor rule never had to be. Those two are
// commutative, so "exactly one tainted operand" already determines the emission.
// `sub` is not: only HANDLE-LHS (`q - c`) is an in-place tweak of the immediate.
// `c - q` is negate-the-RAIL then add — a rewrite of the register's whole value,
// which `cqrt_addc_<W>` cannot express at any width — so it is refused in EVERY
// batch, not deferred to a later one. It is also the NUMEROUS shape (census 0.2:
// 84 `cq_template_sub_<W>_lh` calls corpus-wide against 7 `_hl`), which is
// exactly why the direction is tested here rather than assumed downstream.
llvm::Value *inPlaceReassignRailOperand(BinaryOperator *bo,
                                        const TaintSet &taint) {
  if (bo->getOpcode() != Instruction::Sub)
    return inPlaceValueRailOperand(bo, taint);
  Type *Ty = bo->getType();
  if (!Ty->isIntegerTy() || Ty->getIntegerBitWidth() > 64)
    return nullptr;  // the same <=64-integer bound the add/xor rule applies.
  Value *L = bo->getOperand(0), *R = bo->getOperand(1);
  // HANDLE-LHS ONLY: `q - c`. A tainted RHS (`c - q`, and `q - q'`) is refused.
  if (!taint.Tainted.count(L) || taint.Tainted.count(R))
    return nullptr;
  return L;
}
//
// G7 — is this ALREADY-EXECUTED user of the parent handle `P` SETTLED, i.e. can
// nothing emitted AFTER `bo` still need `P` at its pre-`bo` value?
//
// THE HAZARD, stated exactly, because "no use after the op" alone does NOT cover
// it. The Phase-5 spine emits its adjoints at a POST-DOMINATING point, which is
// after `bo` in program order even though the forward gates it adjoints are
// before it. So a rail `X = f(P, …)` minted BEFORE `bo` and reversed by the
// spine yields `..._unc(X, P, …)` AFTER `bo` — reading a `P` we have just
// relabelled. `X` is then not zeroed and its `cqrt_free` is a hidden measurement
// (Rules 6/8). That is the census's (T2) failure and it is invisible to
// `opt -verify`, to the golden byte-diff, and to `free_pairing_check.py`'s
// structural pairing. So each prior user must be shown harmless.
//
// (a) AN IN-PLACE GATE ON `P` ITSELF is harmless BY THE SPINE'S OWN ORDERING.
//     `emitDagReversal` walks one DAG in REVERSE PROGRAM ORDER, and the
//     `cqrt_addc` this fence is about is itself an in-place gate on `P`
//     (ChainWalk learned that in this same increment), so the moment the DAG
//     walks `P` it collects our gate too — later in program order than this
//     prior gate, hence adjointed EARLIER. `P` is back at its prior-gate value
//     before that gate's adjoint reads it. Clause (d) holds by construction, not
//     by luck; there is exactly ONE regular terminal group per function, so the
//     two gates cannot land in differently-ordered DAGs.
//
// (b) ADJOINT TRAFFIC ALREADY IN THE IR (`_unc`/`_inv`) is harmless: it has
//     already fired. This is the Phase-4 flag strip, emitted inline by
//     `SwapRouteEmit` long before `lowerOps` runs — and it is precisely what
//     makes seq-grover's region compares "prior, COMPLETED readers" in the
//     ruling's sense. An `_unc` whose OUT slot IS `P` is refused: that would say
//     `P`'s own rail was discharged before we mutate it.
//
// (c) A VOID `cqrt_*` GATE THAT MINTS NO RAIL FROM `P` (`cqrt_cswap` route
//     pairs, `cqrt_x` brackets, `cqrt_cnot`/`cqrt_toffoli` networks,
//     `cqrt_copy_*`, `cqrt_tape_write_*`) is harmless: a void call is never a
//     DAG *handle*, and `isInPlaceGateOn` does not match it, so it can never be
//     a member of `D.Calls` — the spine never re-emits it. `cqrt_qram_store_*`
//     is the ONE void exception and is refused here: it IS an in-place gate on
//     its ARRAY, so the spine DOES adjoint it, and its `_unc` re-reads its
//     idx/val operands — which is where `P` would be sitting. (When `P` is the
//     array itself, arm (a) already claimed it.)
//
// (d) A RAIL-MINTING PRODUCER READING `P` (`cq_template_*`, `cqrt_qram_load_*`,
//     a `__cq_q_*` clone call) is the hazard itself — UNLESS its rail is already
//     FULLY DISCHARGED before `bo`: its `_unc` fired and its rail was freed,
//     both provably before. A freed rail cannot be reversed again — its
//     `cqrt_free` user makes `recoverDataDag`'s closure scan mark the whole DAG
//     `NotClosed`, and `reverseTerminalGroup` then emits nothing at all — so no
//     future adjoint of it exists to re-read `P`. This arm is what admits
//     seq-grover's two region compares (SPIKE §9.8) without admitting the
//     general "earlier consumer" the SC reading refused.
//
// (e) EVERYTHING ELSE — a plain-IR use (`ret`/`store`/`phi`), a STILL-UNLOWERED
//     tainted opcode (it is not a `CallInst` yet, and the spine will adjoint
//     whatever `lowerOps` turns it into), a measurement, an unknown callee —
//     is refused. Out-of-place is the fallback, so refusing costs nothing but a
//     kept ancestor rail, which is exactly today's behavior.
bool priorUseIsSettled(const Instruction *UI, const Value *P,
                       const BinaryOperator *bo, const DominatorTree &DT) {
  const auto *CI = dyn_cast<CallInst>(UI);
  if (!CI)
    return false;  // (e) plain-IR use / still-unlowered tainted opcode.
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;  // (e) indirect call — nothing to reason about.
  StringRef N = Callee->getName();

  if (isInPlaceGateOn(CI, P))
    return true;  // (a)

  if (N.ends_with("_unc") || N.ends_with("_inv"))  // (b)
    return CI->arg_size() >= 1 && CI->getArgOperand(0) != P;

  if (CI->getType()->isVoidTy() && N.starts_with("cqrt_") &&
      !N.starts_with("cqrt_qram_store_"))
    return true;  // (c)

  // (d) — a producer whose own rail is provably zeroed AND released before `bo`.
  // Both halves are required: the `_unc` witnesses that the rail was RETURNED TO
  // |0>, the `cqrt_free` witnesses that the register was RELEASED (and is what
  // makes the spine's closure scan refuse to touch it again). Demanding only one
  // would rest the argument on the other being implied, which it is not.
  if (CI->getType()->isVoidTy())
    return false;  // a void non-`cqrt_` callee — unknown, refuse.
  bool Zeroed = false, Released = false;
  for (const User *DU : CI->users()) {
    const auto *D = dyn_cast<CallInst>(DU);
    if (!D || !D->getCalledFunction())
      continue;
    const Instruction *DI = D;
    if (!provablyBefore(DI, bo, DT))
      continue;
    StringRef DN = D->getCalledFunction()->getName();
    if (DN == "cqrt_free" && D->arg_size() == 1 && D->getArgOperand(0) == CI)
      Released = true;
    // The out-first `_unc` convention (DD-3): the rail being zeroed is arg 0.
    // A QRAM store `_unc` takes its forward's args and zeroes nothing, so it is
    // excluded exactly as `RotationLowering::isDischargeOf` excludes it.
    else if (DN.ends_with("_unc") && !DN.starts_with("cqrt_qram_store_") &&
             D->arg_size() >= 1 && D->getArgOperand(0) == CI)
      Zeroed = true;
  }
  return Zeroed && Released;
}

}  // namespace

bool classifyInPlaceReassignment(BinaryOperator *bo, WidthDispatch &wd,
                                 const TaintSet &taint, const DominatorTree &DT,
                                 const LoopInfo &LI) {
  // G1 — BATCHES 2a+2b ADMIT `add` AND `sub`. The mechanism below is
  // opcode-general (`inPlaceReassignRailOperand` knows add, sub AND xor, and
  // `rewriteInPlaceValueRail` emits all three); the ADMISSION is not. `xor` is
  // batch 2c and lands with its own goldens and its own adversarial round.
  //
  // 2b is the batch that CLOSES bd test_C_libtooling-nepx: the campaign's
  // customer (`slice_control_seq_grover`) has exactly one `sub` site, sitting
  // between the oracle region and the S† rotation, and it was the last
  // out-of-place ancestor that dephased the reflection. After this widening the
  // whole slice is a ONE-RAIL program.
  const Instruction::BinaryOps Op = bo->getOpcode();
  if (Op != Instruction::Add && Op != Instruction::Sub)
    return false;

  // G2 — the SHAPE predicate (Rule 14: the dtzb one for add/xor, plus the
  // directional `sub` rule): exactly one tainted operand (the parent rail `P`),
  // one classical immediate, an integer width the in-place ABI can serve, and
  // for `sub` the handle on the LEFT. Its exclusion partition (information-
  // losing opcodes, two-quantum operands, fp, `c - q`) is the one this fence
  // wants.
  Value *P = inPlaceReassignRailOperand(bo, taint);
  if (!P)
    return false;

  // G4 — THE IMMEDIATE MUST BE ONE STAGE 2b CAN PROVE CLASSICAL. `cqrt_addc_<W>`
  // declares its second parameter classical, but at W=i32 both parameters are
  // `int32_t`, so a rail handle in that slot is verify-clean AND prints as a bare
  // decimal in the trace — both shipped gates blind on the same axis. Rule (A1)
  // of `free_pairing_check.py` therefore CHECKS the slot, and its
  // `provably_not_a_rail` answers on positive evidence only: a formal PARAMETER
  // "arrives from outside; nothing here can vouch" and is refused UNPROVEN.
  // Census 0.5 measured the rest of the surface and cleared it — a volatile load
  // (`slice_control_seq_grover`'s own `off`) and ordinary classical arithmetic
  // both pass. So the ONE shape we must keep out-of-place is a formal-argument
  // immediate: converting it would turn a green slice into a stage-2b UNPROVEN.
  Value *Imm = bo->getOperand(0) == P ? bo->getOperand(1) : bo->getOperand(0);
  if (isa<Argument>(Imm))
    return false;

  // G5 — the LOOP-OWNED population is untouched, from both sides.
  //   * `InPlaceRailOps` is `lowerLoops`' own proven set; the driver already
  //     routes it to the same emitter. Claiming one here would be a second
  //     recognizer adjudicating a shape that already has an owner.
  //   * A `bo` inside ANY natural loop is out of scope for this batch. The
  //     rolled-in-place (799w) and whole-loop reverse-play (y05j/dtzb) machinery
  //     owns in-place value gates in loop bodies, with its own capture set and
  //     its own reverse-play ordering; a second, independently-fenced minter in
  //     the same blocks is exactly the interaction this increment is not scoped
  //     to prove. Straight-line only. Over-declining costs a kept ancestor.
  if (taint.InPlaceRailOps.count(bo))
    return false;
  if (LI.getLoopFor(bo->getParent()))
    return false;

  // G6/G7 — POSITION-AWARE DEADNESS + PRIOR-OBLIGATION DISCHARGE.
  for (const User *U : P->users()) {
    const auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      return false;  // a constant-expression use — no position, no proof.
    if (UI == bo)
      continue;  // the op itself: its result IS this same physical rail.
    if (UI->getFunction() != bo->getFunction())
      return false;
    // An UNREACHABLE use never executes, so it is not a read of `P` in any
    // emitted trace — and both halves of `provablyBefore` are VACUOUSLY true for
    // it (LLVM's dominator tree treats an unreachable block as dominated by
    // everything, and nothing is reachable from it), so it would otherwise be
    // silently classified as "prior" and then have to pass G7. Skipping it is
    // the same reading the M-A guard's F3 finding settled.
    if (!DT.isReachableFromEntry(UI->getParent()))
      continue;
    // G6 — no data use AFTER the op. `provablyBefore` is the shared spelling
    // (WireWalk.h): dominance for first-execution order, plus the reachability
    // half so a back edge cannot replay the use against the mutated rail.
    // Unproven ⇒ out-of-place (Prime Directive direction).
    if (!provablyBefore(UI, bo, DT))
      return false;
    // G7 — the prior use must be settled (see `priorUseIsSettled`).
    if (!priorUseIsSettled(UI, P, bo, DT))
      return false;
  }

  // G3 — the width must be in the FROZEN `cqrt_addc_<W>` grid. BOTH admitted
  // opcodes emit that one symbol: `sub` is `addc` with the immediate negated
  // (Inc 2b), so there is no second grid to ask about and no `cqrt_subc_` to
  // mint. (Batch 2c's `xor` will need `wd.xorcFn` here — same five widths, a
  // different symbol.) `wd.addcFn`
  // returns null off-grid; ASKING IT (rather than repeating {i1,i8,i16,i32,i64}
  // here) means the fence tracks the ABI instead of a comment about the ABI, and
  // it must never mint a phantom symbol (the n0ui lesson). G2's own <=64-integer
  // bound already implies this, so it is defense in depth.
  //
  // IT IS DELIBERATELY LAST, and that is not cosmetic. `addcFn` resolves through
  // `Module::getOrInsertFunction`, which CREATES `declare void
  // @cqrt_addc_<W>(i32, iW)` as a SIDE EFFECT — so asking it before the fence
  // has decided planted a dangling declaration in every module containing any
  // tainted integer `add`, including the ones that then stayed out of place.
  // (Measured: `lowering_add_qc_i32.ll` grew a `declare void @cqrt_addc_i32` it
  // never calls.) Harmless at link, but it is a symbol appearing in a module
  // that emits none — exactly the kind of phantom this project refuses to ship.
  // Asked HERE, it is only ever asked for a site that is about to emit.
  return wd.addcFn(abiWidthFromType(bo->getType())) ? true : false;
}

}  // namespace cq
