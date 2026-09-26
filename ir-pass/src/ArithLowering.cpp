// ArithLowering.cpp — per-instruction lowering for the two data-arithmetic
// classes (binary + unary `fneg`). See header for the operand-shape rules.
// Generalizes the Phase-2 `add`/`fadd` body to all 16 in-scope stems with
// HH/HL/LH shapes and commutativity-gated BirthOrder; the driver
// (`OpcodeLowering`) owns collection, program order, and erase.

#include "ArithLowering.h"

#include "ChainWalk.h"      // isInPlaceGateOn (the ONE in-place-gate relation)
#include "FreePoint.h"      // blockCanRepeat (the ONE "can this block run twice")
#include "LoopPlan.h"       // inPlaceValueRailOperand (the dtzb shape predicate)
#include "OpcodeSupport.h"
#include "TaintPropagation.h"
#include "TemplateName.h"   // dataName — the ONE builder of the template symbol
#include "Uncomputation.h"  // InteriorDischargePlan (the M-B discharge PLAN)
#include "WidthDispatch.h"
#include "WireWalk.h"       // provablyBefore (the shared position-aware proof)

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

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
// when `handleWidth` is empty) so no stale `orig` record survives. (Now
// belt-and-braces since bd 8e5r: every TaintSet table drops a deleted key by itself, `ScrubOnDelete.h` — so this erase is no longer the only thing between a
// reused address and a wrong width.)
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

// ONE EMISSION of the in-place gate (bd test_C_libtooling-x67f, Increment 7a).
// `Site` is replaced (RAUW'd to the handle; the CALLER erases it), `HandleIsLhs`
// records whether the handle was the op's LEFT operand — the `sub` direction
// test, kept here so the two callers cannot answer it differently.
//
// The step ORDER is the shipped one and is load-bearing for the fixtures that
// pin it: resolve the width callee FIRST (a `nullptr` there is the loud
// `diagnoseNoTemplate` of `lowering_mc_{sub,xor}_fence_fallback.ll`), THEN the
// `c - q` direction refusal, THEN negate, THEN emit.
bool emitInPlaceReassign(Instruction *Site, Instruction::BinaryOps Op,
                         Value *Handle, Value *Imm, bool HandleIsLhs,
                         StringRef W, WidthDispatch &wd) {
  FunctionCallee Callee =
      Op == Instruction::Xor ? wd.xorcFn(W) : wd.addcFn(W);
  if (!Callee) {
    // Unsupported width — the shape predicate applies the SAME ≤64-integer
    // fence, so this is unreachable; never mint a phantom symbol or leave an
    // ill-typed op (Rule 1). Loud decline.
    diagnoseNoTemplate(Site);
    return false;
  }
  // `sub` IS NOT COMMUTATIVE, and getting this backwards is the one way this
  // emission could be a silent miscompile: `c - q` is negate-the-RAIL then add
  // — a rewrite of the whole register, which `cqrt_addc_<W>` cannot express —
  // whereas the emission below computes `q + (-c)`. Both recognizers admit
  // HANDLE-LHS ONLY, so a tainted RHS cannot reach here; the check is defense in
  // depth, and it fails LOUD rather than emitting the wrong permutation (Prime
  // Directive). Unreachable through the shipped surface —
  // `lowering_mc_sub_fence_fallback.ll`'s `@classical_lhs` pins that `c - q`
  // never even reaches the fence's accept.
  if (Op == Instruction::Sub && !HandleIsLhs) {
    diagnoseNoTemplate(Site);
    return false;
  }
  IRBuilder<> Builder(Site);
  if (Op == Instruction::Sub)
    Imm = negateClassicalImmediate(Imm, Builder, Site);
  CallInst *C = Builder.CreateCall(Callee, {Handle, Imm});
  if (DebugLoc DL = Site->getDebugLoc())
    C->setDebugLoc(DL);
  // In-place: the result IS the rail handle (same register, mutated state). RAUW
  // to the handle — a no-op when the Case-A phi collapse already left `Site`
  // use-empty (the single-op value accumulator), and the correct rewire for a
  // chained self-update (`q1 = q ^ 9; q2 = q1 ^ 3` — `q1`'s RAUW feeds `q2`). The
  // void in-place gate is not itself a tainted producer; the handle stays
  // tainted.
  Site->replaceAllUsesWith(Handle);
  return true;
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
  // Exactly one operand is tainted (the rail handle, i32 by now — handles join
  // `Tainted` at the theta mint); the other is the classical immediate at the
  // rail's logical width. The recognizer proved this (one tainted operand), so
  // the selection is unambiguous. The driver erases `bo`.
  Value *L = bo->getOperand(0), *R = bo->getOperand(1);
  // bd test_C_libtooling-eqpx — CONSUME the writer's recorded operand index for a
  // `lowerLoops`-marked rail op; do not re-derive it. Until eqpx this line re-ran
  // G2's pick a SECOND time here, from a `Tainted` that `promote()` (`:49-57`) is
  // mutating as Phase 2 runs, and that second answer is what put a quantum rail
  // in the classical-immediate slot — and, with the operands commuted, mutated
  // the WRONG REGISTER. `lowerOps` Phase 1 has already re-verified this index
  // against a fresh `inPlaceValueRailOperand` under FINAL taint and declined
  // loudly on a disagreement, so by here it is a checked fact, not a prediction.
  //
  // WHY THE INDEX AND `TL` CANNOT DISAGREE (the round-1 lens's adjudication (A),
  // written down here because the sentence above asserted "a checked fact" without
  // saying WHY the check cannot go stale in the window between Phase 1 and this
  // line). Three facts, each MEASURED by command:
  //   (1) THIS FUNCTION HAS EXACTLY ONE CALL SITE — `OpcodeLowering.cpp:557`
  //       (`grep -rn 'rewriteInPlaceValueRail' ir-pass/src ir-pass/include`: one
  //       definition, one declaration, one call, the rest comments) — and it is
  //       reached only from `Work`, every member of which passed the Phase-1
  //       tripwire. There is no second route into the emitter.
  //   (2) EVERY Phase-2 MUTATION OF `taint.Tainted` IS `promote(repl, orig)`
  //       (`:49` here, mirrored at `CastLowering.cpp:38`, `CompareLowering.cpp:44`,
  //       `IntrinsicLowering.cpp:204`; the body is `Tainted.insert(repl);
  //       Tainted.erase(orig);`). It INSERTS a freshly created instruction and
  //       ERASES a value that was ALREADY tainted and has just been RAUW'd to it.
  //       So an operand that was UNTAINTED at Phase 1 is neither RAUW'd (RAUW only
  //       replaces uses of the tainted `orig`) nor inserted — it cannot JOIN
  //       `Tainted`; and an operand that was TAINTED at Phase 1 is only ever
  //       replaced by another tainted value. Neither direction can move WHICH of
  //       the two operands is the rail.
  //   (3) THE ONE NON-`promote` PHASE-2 RAUW is `emitInPlaceReassign`'s
  //       `Site->replaceAllUsesWith(Handle)` (`:162`), and the value it
  //       substitutes IS the rail handle G2 proved tainted.
  //
  // STATUS, STATED HONESTLY: this index AGREES with `TL` on every program in the
  // corpus — mutant M2+M3 (the Phase-1 index re-verify AND this consume both
  // disabled) moves ZERO of 1707 fixtures — so it is ARGUED DEFENCE-IN-DEPTH, not
  // a fence with a red-green of its own. It is NOT decoration: mutant M-E (the
  // recorded index FLIPPED with the re-verify off) reddens 23 fixtures, so the
  // plumbing is live and observable when WRONG. It is kept because (1)-(3) are a
  // CHAIN a future stage can break silently, and because retiring the third
  // independent computation of one predicate is literally the bd 8h7d.5 F-1/F-3
  // lesson. A reviewer who wants to delete it should first break (2) with a
  // program, not with an argument.
  //
  // The M-C straight-line route (`InPlaceReassign`) records NO index and keeps
  // the `TL` pick: its `sub` widening selects the rail with a DIFFERENT predicate
  // (`inPlaceReassignRailOperand`, handle-LHS only), so M-C's emitted stream is
  // byte-for-byte what it was.
  bool TL = taint.Tainted.count(L) != 0;
  if (auto It = taint.InPlaceRailIdx.find(bo); It != taint.InPlaceRailIdx.end())
    TL = It->second == 0;
  return emitInPlaceReassign(bo, Op, TL ? L : R, TL ? R : L, /*HandleIsLhs=*/TL,
                             AbiWidth, wd);
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
//     a member of `D.Calls` — the spine never re-emits it.
//
//     ⚠ THAT SECOND CLAUSE IS NOT TRUE OF EVERY VOID `cqrt_*`, AND WHICH ARM
//     OWNS A CONTROLLED ROTATION IS **PER STEM** (bd drbq round-2 review lens A
//     §3, restated for the Inc-2a stem split; round-1 review of Inc 2a, L1 F-1).
//     `cqrt_{ry,rz}_<W>_controlled(f, P, θ)` is void, is a `cqrt_*`, and is not a
//     `cqrt_qram_store_`. Read the table, not the prose:
//
//       * `cqrt_ry_<W>_controlled` → **arm (a)**. `isInPlaceGateOn` still matches
//         it at arg 1 (the Inc-0 row, narrowed to this stem by Inc 2a), so it IS
//         a member of `D.Calls` and arm (a) claims it before control reaches
//         here. Its safety is NOT arm (a)'s usual argument ("the DAG collects our
//         gate too, later in program order, hence adjointed EARLIER"): a rail
//         carrying a controlled **Ry** is FROZEN
//         (`ChainWalk::railCarriesControlledRotation`, still `ry`-only), the DAG
//         is `NotClosed`, and the spine emits NOTHING AT ALL. For THIS stem, "can
//         never be a member of `D.Calls`" is false — do not cite it.
//
//       * `cqrt_rz_<W>_controlled` → **arm (c), THIS ONE**, since Inc 2a. The
//         stem split narrowed `isInPlaceGateOn` to `ry`, so the controlled Rz is
//         an UNRECOGNIZED consumer: not a link, never in `D.Calls`, never
//         re-emitted by the spine — i.e. this bullet's own ground is RESTORED for
//         it, and it is what carries the verdict. The freeze the `ry` bullet
//         leans on was REMOVED for this stem by the same increment
//         (`railCarriesControlledRotation` is `ry`-only), so do not reach for it
//         here.
//
//     The VERDICT is `true` on both paths and was `true` under the pre-2a route
//     as well (a `cqrt_cswap` reached arm (c)), so nothing moved behaviourally —
//     measured, `lowering_mc_late_*` and the M-C probes fire in place before and
//     after. What moved is WHICH ARGUMENT IS LOAD-BEARING. If anyone ever
//     re-admits the `rz` stem to `isInPlaceGateOn` (the `ChainWalk.h` note
//     contemplates it), ownership silently changes back to arm (a) and the
//     freeze must come back with it — re-read both bullets before doing that.
//     `cqrt_qram_store_*`
//     is the ONE void exception and is refused here: it IS an in-place gate on
//     its ARRAY, so the spine DOES adjoint it, and its `_unc` re-reads its
//     idx/val operands — which is where `P` would be sitting. (When `P` is the
//     array itself, arm (a) already claimed it.)
//
// (d0 — bd test_C_libtooling-vsfp / bd hgwx) A CALL THAT DOES NOT READ `P` AT ALL:
//     a call to a DEFINED, non-vararg function that passes `P` ONLY in argument
//     slots whose parameter the callee's body has NO USES of. Such a call can
//     neither observe `P` nor mint a rail from it, and neither can any adjoint of
//     it: the only one the pipeline builds is a Phase-6 clone's `_unc` twin, a
//     verbatim copy of the same body, whose parameter in that slot is unused too.
//     So it is settled by construction. This is the question bd hgwx asked for —
//     answered from the CALLEE'S PARAMETER, never from the `__cq_q_` name (r1B's
//     diagnostic mutant) and never from the clone's verdict alone: a clone that
//     DOES read the slot — a spec-QUANTUM clone, or a classical-verdict one whose
//     body computes from `P` and Bennett-reverses it — still counts as a use and
//     falls through to (d) exactly as before (and a clone never measures or rotates
//     its argument: `scanBody` refuses a `cq_*` body). WHO REACHES IT: after bd
//     vsfp's `dropDeadCallArguments` a callee parameter with no uses no longer
//     receives a non-constant operand, so the only customer is a slot whose use
//     the CLONE PIPELINE removed (e.g. `volatile int z = a;` in the callee, which
//     the clone's lowering erases), with a `cq_theta` result as the operand — the
//     one operand `declinePhantomCloneArgReads` exempts; any other tainted operand
//     in such a slot has already been declined. Measured: `u = t + q` after
//     `t = h(q, m)` with that callee lowers IN PLACE like its hand-inlined twin
//     (spec_accept_phantom_arg_read_theta_source_inplace_mc.ll); without (d0) it
//     lowers out of place and dephases the following Ry (warned, lyyf-(B)).
//
// (d) A RAIL-MINTING PRODUCER READING `P` (`cq_template_*`, `cqrt_qram_load_*`,
//     a `__cq_q_*` clone call) is the hazard itself — UNLESS its rail is already
//     FULLY DISCHARGED before `bo`: its `_unc` fired and its rail was freed,
//     ⚠ THIS WAS FALSE AS WRITTEN FOR ONE MEMBER (bd test_C_libtooling-hgwx; bd
//     d88e Rule-13 r1B F-DB-1): a `__cq_q_*` clone that never READS the slot `P`
//     sits in (e.g. `h(a, k) = k + 1`) mints no rail from `P`, and there is no
//     adjoint of it that could ever re-read `P` — yet this arm refused it by the
//     call's SHAPE, so `P` lowered OUT of place where its hand-inlined twin lowers
//     IN place (`j02C`; see (e) for what that cost). bd vsfp closes it twice: the
//     dead-argument drop removes that read before any stage sees it, and arm (d0)
//     above settles the residual by the callee's PARAMETER. r1B's diagnostic
//     mutant (every `__cq_q_*` callee settled, by NAME) stays UNSOUND and
//     unlicensed: a clone that reads `P` keeps an out rail whose `_unc` re-reads
//     `P`. What reaches this arm now is a producer that genuinely READS `P`.
//     Otherwise:
//     both provably before. A freed rail cannot be reversed again — its
//     `cqrt_free` user makes `recoverDataDag`'s closure scan mark the whole DAG
//     `NotClosed`, and `reverseTerminalGroup` then emits nothing at all — so no
//     future adjoint of it exists to re-read `P`. This arm is what admits
//     seq-grover's two region compares (SPIKE §9.8) without admitting the
//     general "earlier consumer" the SC reading refused.
//
// (d2 — bd test_C_libtooling-x67f, Increment 7a) A PRODUCER THE M-B INTERIOR
//     PARTITION HAS PLANNED TO DISCHARGE at a point provably before `bo`. This
//     is arm (d)'s own argument moved one stage earlier in the pipeline, and it
//     exists because arm (d) as written could only ever see a discharge some
//     EARLIER emitter had already inlined — in practice exactly the Phase-4 flag
//     strip. The M-B spine runs LAST, so on a DERIVED-condition region
//     (`if (f(a)==k) …; a -= off;`) the oracle chain's forward template looked
//     like an undischarged prior reader, the sub minted a fresh rail, and the
//     old register stood as a dead ancestor at the next `cq_theta` — a decline
//     whose message named the wrong cause (bd memory
//     [mc-cannot-see-mb-discharge-2026-08-29]).
//
//     WHAT IS TRUSTED, AND WHY IT IS NOT "PREDICT A LATER STAGE" IN THE SENSE
//     THE 2026-08-27 RULING REJECTED. That ruling rejected an early M-A slot
//     which would have had to predict Phase-4 and Phase-5 from an IR where
//     neither had run. Here nothing is predicted from absence: the module is
//     fully lowered (this arm is reachable only from the LATE round below,
//     after `lowerOps`/`lowerMeasures`/`lowerBreakReversePlay`), and the plan is
//     produced by RUNNING THE REAL PLANNER — `planInteriorDischarges` calls the
//     same `collectInteriorPlans` that `uncompute` calls, over the same
//     predicates, on the same IR.
//
//     AND THE PREDICTION IS RE-PROVED WHERE IT MATTERS. The planner runs AGAIN
//     inside `uncompute`, on the post-conversion module, and it is that run
//     which emits. If the conversion moved the plan, the in-place gate we
//     emitted is a MUTATION of a borrowed parent sitting inside the component's
//     clause-(d) interval, which clause (d) refuses — the component LEAKS and no
//     adjoint is emitted at all. So a stale prediction costs a kept rail, never
//     an `_unc` reading a relabelled register. The one partition that would NOT
//     degrade that way is the dead-terminal spine (no clause-(d) scan), and the
//     plan subtracts a superset of everything it could reach precisely so no
//     gate of its can ever appear here (see `planInteriorDischarges`).
//
//     ZEROED IS ASKED, RELEASED IS NOT — deliberately, and the asymmetry is not
//     a relaxation. Arm (d)'s `Released` half is about IR THAT ALREADY EXISTS: a
//     `cqrt_free` in the module makes `recoverDataDag`'s closure scan mark the
//     DAG `NotClosed`, which is what guarantees no SECOND adjoint of that rail
//     will be minted. Here that guarantee comes from single ownership instead —
//     the rail belongs to exactly one planned component, and the plan already
//     excluded every rail the terminal spine could claim. What arm (d2) needs is
//     only the placement fact: every adjoint of the component is inserted BEFORE
//     `At`, and `At` is provably before `bo`.
//
// (e) EVERYTHING ELSE — a plain-IR use (`ret`/`store`/`phi`), a STILL-UNLOWERED
//     tainted opcode (it is not a `CallInst` yet, and the spine will adjoint
//     whatever `lowerOps` turns it into), a measurement, an unknown callee —
//     is refused. Out-of-place is the fallback. ⚠ "Refusing costs nothing but a
//     kept ancestor rail" was this comment's claim and it is FALSE whenever a
//     NON-DIAGONAL gate later acts on the out-of-place result (bd hgwx; bd d88e
//     Rule-13 r1B F-DB-1): the kept ancestor stays entangled with the copy and
//     DEPHASES it. `j02C` (`u = t + q; … Ry(.2) on u`, then a clone call that
//     never read `q` as the refused prior use) measured bit 0 as 0 with
//     probability ≈0.070 where the coherent in-place twin gives ≈0.118 (analytic,
//     r1B §2), reported only as `non-diagonal gate over a live derived record`
//     (the owner's lyyf-(B) warning). So what refusal costs is a KEPT ANCESTOR
//     RAIL PLUS, under a later non-diagonal gate, COHERENCE — a reason to refuse
//     only what must be refused. (`j02C` itself no longer reaches here: arm (d0)
//     and bd vsfp's drop, above.)
bool priorUseIsSettled(const Instruction *UI, const Value *P,
                       const Instruction *bo, const DominatorTree &DT,
                       const InteriorDischargePlan *Plan) {
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

  // (d0) — a call that passes `P` only in slots its callee's body never reads
  // (bd vsfp / bd hgwx; see above). Asked of the PARAMETER: a slot the body reads
  // — a spec-quantum clone's, or any real read — falls through to (d) unchanged.
  if (!Callee->isDeclaration() && !Callee->isVarArg()) {
    bool PassesP = false, ReadsP = false;
    for (unsigned A = 0, E = CI->arg_size(); A < E; ++A) {
      if (CI->getArgOperand(A) != P)
        continue;
      PassesP = true;
      if (A >= Callee->arg_size() || !Callee->getArg(A)->use_empty()) {
        ReadsP = true;
        break;
      }
    }
    if (PassesP && !ReadsP)
      return true;
  }

  // (d) — a producer whose own rail is provably zeroed AND released before `bo`.
  // Both halves are required: the `_unc` witnesses that the rail was RETURNED TO
  // |0>, the `cqrt_free` witnesses that the register was RELEASED (and is what
  // makes the spine's closure scan refuse to touch it again). Demanding only one
  // would rest the argument on the other being implied, which it is not.
  if (CI->getType()->isVoidTy())
    return false;  // a void non-`cqrt_` callee — unknown, refuse.

  // (d2) — the PLANNED discharge (see above). Asked before the already-emitted
  // scan because the two are independent witnesses of the same property and the
  // map lookup is the cheaper one; either alone settles the user.
  if (Plan) {
    auto It = Plan->GateAt.find(CI);
    // `provablyBefore`, and NOTHING WEAKER — in particular `At == bo` is NOT
    // admitted even though the adjoints would in fact land immediately before
    // the site (`emitDagReversal` inserts BEFORE its point). That widening was
    // measured, has no customer among the shapes this increment ships, and
    // could not be pinned by a fixture that does not ALSO exercise a second
    // fence — so it is left out rather than shipped unpinned (Rule 12).
    if (It != Plan->GateAt.end() && provablyBefore(It->second, bo, DT))
      return true;
  }

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

// G3–G7, THE POSITION-AWARE HALF OF THE M-C FENCE, SPELT ONCE (bd
// test_C_libtooling-x67f, Increment 7a). `Site` is the instruction the in-place
// gate will replace, `P` its parent rail, `Imm` the classical immediate, `Op`
// the arithmetic stem and `W` the logical ABI width.
//
// TWO ENTRY POINTS, ONE FENCE. `classifyInPlaceReassignment` reaches it from
// `lowerOps` Phase 1 with a `BinaryOperator` and no plan;
// `classifyLateInPlaceReassignment` reaches it from the LATE round with the
// already-lowered `cq_template_<stem>_<W>_hl` call and the M-B discharge plan.
// The two differ ONLY in how they recover `(Op, P, Imm, W)` — G1/G2, the shape
// half — so everything positional lives here and cannot drift between them
// (Rule 14; the `railOf`/`isAbiQramStore` lesson).
bool inPlaceFenceHolds(const Instruction *Site, const Value *P, const Value *Imm,
                       Instruction::BinaryOps Op, StringRef W,
                       WidthDispatch &wd, const TaintSet &taint,
                       const DominatorTree &DT, const LoopInfo &LI,
                       const InteriorDischargePlan *Plan,
                       bool IgnoreSelfMarking = false) {
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
  if (isa<Argument>(Imm))
    return false;

  // G5 — the LOOP-OWNED population is untouched, from both sides.
  //   * `InPlaceRailOps` is `lowerLoops`' own proven set; the driver already
  //     routes it to the same emitter. Claiming one here would be a second
  //     recognizer adjudicating a shape that already has an owner.
  //   * A `Site` inside ANY natural loop is out of scope for this batch. The
  //     rolled-in-place (799w) and whole-loop reverse-play (y05j/dtzb) machinery
  //     owns in-place value gates in loop bodies, with its own capture set and
  //     its own reverse-play ordering; a second, independently-fenced minter in
  //     the same blocks is exactly the interaction this increment is not scoped
  //     to prove. Straight-line only. Over-declining costs a kept ancestor.
  //
  // AND "IN A LOOP" IS `LoopInfo` **OR** `blockCanRepeat` — the second disjunct
  // is the whole point (Inc 7 Rule-13 round, finding F1; bd
  // test_C_libtooling-x67f). `LoopInfo::getLoopFor` recognizes NATURAL loops
  // only, so an IRREDUCIBLE cycle (two entries, no dominating header) returned
  // null here while executing its blocks K times — and this fence is what makes
  // an in-place gate an at-most-once WRITE. With the site inside such a cycle
  // the register was mutated ONCE PER TRIP: for
  //     entry: br i1 %c0, A, B     A: br B     B: %s = sub %q, %off; ... br %cb, A, exit
  // the source recomputes `q - off` from the loop-invariant `q` on every trip and
  // measures `q - off`, while the emitted stream is `addc(h,-off); addc(h,-off);
  // measure(h)` = `q - 2*off`. A WRONG VALUE, `opt` rc=0, verify-clean, and
  // free-pairing-clean (the rail is never freed) — the definition of a
  // verify-clean silent miscompile. It PRE-DATES the late round (Inc 2's Phase-1
  // fence had it; measured byte-identical on `2afd9a7`), which is exactly why the
  // fix belongs HERE, in the ONE shared fence both rounds ask.
  //
  // `blockCanRepeat` (FreePoint.h, the reachable-from-itself successor DFS) is
  // the SAME predicate bd test_C_libtooling-4p7j put behind the uncompute
  // spine's three reversal backstops and `FreePoint`'s `kMsgLoopBackedge`
  // loudness guard; this is its FIFTH consumer, and the lesson that memory
  // records is precisely this one — when you fix a blind predicate, grep for
  // every consumer. `LoopInfo` stays in FRONT as the O(1) answer for the common
  // case. It is a strict SUPERSET of "in a natural loop", so no acyclic CFG
  // changes disposition: only irreducible ones move, and they move from an
  // in-place mutation to the out-of-place fallback (a fresh rail per trip),
  // which is the same disposition the natural-loop spelling already had.
  // `IgnoreSelfMarking` — see `classifyInPlaceReassignment`'s header. The ONLY
  // caller that passes true is `lowerOps`' (1b) tripwire, re-asking this fence
  // about an op `commitOutOfLoopInPlaceOps` itself put in the set; suppressing
  // this disjunct there is what makes the re-ask a question about the SHAPE and
  // the POSITION rather than about the marking (bd 3qlq Inc 1, C-1 round 3).
  if (!IgnoreSelfMarking &&
      taint.InPlaceRailOps.count(const_cast<Instruction *>(Site)))
    return false;
  if (LI.getLoopFor(const_cast<BasicBlock *>(Site->getParent())) ||
      blockCanRepeat(const_cast<BasicBlock *>(Site->getParent())))
    return false;

  // G6/G7 — POSITION-AWARE DEADNESS + PRIOR-OBLIGATION DISCHARGE.
  for (const User *U : P->users()) {
    const auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      return false;  // a constant-expression use — no position, no proof.
    if (UI == Site)
      continue;  // the op itself: its result IS this same physical rail.
    if (UI->getFunction() != Site->getFunction())
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
    //
    // TWO OUT-OF-FILE CONSUMERS DEPEND ON THIS G6/G7 PAIR.
    //
    // CONSUMER 1 (bd 8h7d.5 Rule-13 ROUND 3, bookkeeping item 4).
    // `LoopLowering::collectRailGates` extends a
    // loop rail FORWARD to decide which gates can stale a rail record, and it
    // deliberately does NOT follow an OFF-CHAIN in-place `add`/`xor` — on the
    // ground that such an op either lands on a fresh rail or, when it does fire in
    // place here, cannot be followed by a read of the pre-op register. That second
    // half is THIS loop: a later data use of `P` is refused, so the two
    // dispositions are mutually exclusive (measured — probes r3h/b4 fires in
    // place, r3h/b5 falls back out of place; pinned by
    // control_swap_inloop_postloop_railop_mc.ll).
    //
    // CONSUMER 2 — THE VALUE-ARM CONTROLLED-COPY MERGE (bd
    // test_C_libtooling-3qlq Inc 2, round-1 review finding F-V1-5). Since that
    // increment `SwapRouteEmit::emitValueRegion` HOISTS the arm chain onto the
    // ORIGINAL routed register `Q` and merges with two controlled copies whose
    // sources must denote DISTINCT physical registers. If M-C ever fired on a
    // chain HEAD (whose parent is `Q`), a DIAMOND's second copy
    // `copy_controlled(f, Q, out)` would read a RELABELLED `Q` — `out =
    // f?R(p):R(p)`, the arm silently lost — and an IF/ELSE with both heads
    // converted would collapse its two copy sources onto one register. Neither
    // is visible to `opt -verify`, to the golden byte-diff, or to
    // `free_pairing_check.py` (nothing is freed dirty). Today the pair always
    // refuses: every chain head reads `Q`, and `Q` always has a SECOND user —
    // the second controlled copy (diamond) or the sibling arm's head (if/else)
    // — so the earlier head is refused by G6 and the later by G7. The
    // equivalent property is `SelectClassify`'s gate 6, which the `br`-value
    // path does not run, so the ONLY thing standing behind it here is this
    // pair. Pinned by `control_swap_value_ifelse_head_out_of_place.ll`, which
    // carries BOTH shapes as two functions on ONE-LINK chains (with a longer
    // chain the head's result feeds a fresh rail and the collision would not
    // show): the diamond needs ONE conversion to break, the if/else two. The
    // `At == bo` widening contemplated in `priorUseIsSettled` would move the
    // if/else case, so re-derive that fixture before taking it.
    // ⚠ AND THIS PAIR IS NOW THE SOLE NET ON THE COMMIT PATH TOO (bd 3qlq, the
    // FOURTH C-1 round, lens finding F-C1D-2): `LoopLowering`'s
    // `commitOutOfLoopInPlaceOps` used to carry `P->hasOneUse()`, a second and
    // independent refusal of anything whose parent has two users, and that round
    // retired it. Read the argument at that function for why the commit still
    // cannot reach a chain head — its peel runs BACKWARD and stops at the merge's
    // own `cqrt_alloc`.
    // ⚠ AND CITE THE RIGHT FIXTURE FOR THE RIGHT CLAIM. The first version of this
    // sentence named `control_phase_kickback_mixed_value_merge_preadd_inloop.ll`
    // as the pin, and the lens on the rebased tree measured otherwise
    // (finding **F-C1E-1**): in THAT module `clang -O1` reassociates `(p+3)*5`
    // into `p*5 + 15`, so `p`'s only chain user is a `mul`, and G2's SHAPE half
    // (`inPlaceValueRailOperand`, add/xor only) refuses the head WHATEVER this
    // pair answers — the fixture is GREEN on a G6/G7-disabled binary and its
    // emitted copies are byte-unchanged. It pins the head-out-of-place PROPERTY
    // on the shape that made the commit fire; it does not pin THIS NET.
    // The net is pinned, as this comment already says three paragraphs up, by
    // `control_swap_value_ifelse_head_out_of_place.ll` (RED on that mutant), and
    // on the COMMIT path by
    // `control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll`,
    // whose chain head IS a dtzb-shaped `add` and whose `CSRC` prefix pins the two
    // controlled copies reading DISTINCT rails.
    //
    // SAY "PAIR", NOT "G6", AND SAY WHY IT IS A WEAK TRIPWIRE. Measured by
    // mutation on that fixture: disabling G6 ALONE leaves it green (G7 refuses the
    // same use), disabling G7 alone leaves it green (G6 refuses it), and only
    // disabling BOTH flips `@mc_then_theta` to an in-place `cqrt_addc_i32`. So the
    // fixture cannot catch a single-clause relaxation, and the loop fence's
    // exclusion rests on the pair rather than on either clause. If you relax
    // EITHER of these to admit a site with a later read, re-derive
    // `collectRailGates`' off-chain-BO rule BEFORE relaxing anything here — the
    // test suite will not do it for you.
    if (!provablyBefore(UI, Site, DT))
      return false;
    // G7 — the prior use must be settled (see `priorUseIsSettled`).
    if (!priorUseIsSettled(UI, P, Site, DT, Plan))
      return false;
  }

  // G3 — the width must be in the FROZEN in-place grid, and THE GRID ASKED MUST
  // BE THE ONE THE EMITTER WILL USE. `add` and `sub` both emit `cqrt_addc_<W>`
  // (`sub` is `addc` with the immediate negated, Inc 2b — there is no
  // `cqrt_subc_`); `xor` emits the SEPARATE `cqrt_xorc_<W>` (Inc 2c). The two
  // resolvers apply the same <=64-integer fence today, but they are distinct
  // functions minting distinct symbols, so this mirrors `rewriteInPlaceValue
  // Rail`'s own `Op == Xor ? xorcFn : addcFn` selection rather than asking one
  // and emitting the other. ASKING the resolver (rather than repeating
  // {i1,i8,i16,i32,i64} here) means the fence tracks the ABI instead of a
  // comment about the ABI, and it must never mint a phantom symbol (the n0ui
  // lesson). G2's own <=64-integer bound already implies this, so it is defense
  // in depth — and `lowering_mc_xor_fence_fallback.ll`'s `@wide_i128` is the one
  // probe in the family that reaches an off-grid width from a POSITIVE (`xor` is
  // a shipped i128 template row; the `add` analogue dies on an earlier cast
  // decline).
  //
  // IT IS DELIBERATELY LAST, and that is not cosmetic. Both resolvers go through
  // `Module::getOrInsertFunction`, which CREATES `declare void
  // @cqrt_{addc,xorc}_<W>(i32, iW)` as a SIDE EFFECT — so asking before the
  // fence has decided planted a dangling declaration in every module containing
  // any tainted integer `add`/`xor`, including the ones that then stayed out of
  // place. (Measured: `lowering_add_qc_i32.ll` grew a `declare void
  // @cqrt_addc_i32` it never calls.) Harmless at link, but it is a symbol
  // appearing in a module that emits none — exactly the kind of phantom this
  // project refuses to ship. Asked HERE, it is only ever asked for a site that
  // is about to emit.
  return (Op == Instruction::Xor ? wd.xorcFn(W) : wd.addcFn(W)) ? true : false;
}

}  // namespace

bool classifyInPlaceReassignment(BinaryOperator *bo, WidthDispatch &wd,
                                 const TaintSet &taint, const DominatorTree &DT,
                                 const LoopInfo &LI, bool IgnoreSelfMarking) {
  // G1 — BATCHES 2a+2b+2c ADMIT `add`, `sub` AND `xor`. This is the FULL
  // admission the mechanism was always written for: `inPlaceReassignRailOperand`
  // has known all three since 2a and `rewriteInPlaceValueRail` has emitted all
  // three since dtzb, so 2c is the removal of a batch gate, not a new lowering.
  // The family is closed here — `mul`/`and`/`or`/shifts are information-LOSING
  // and have no in-place reversible form at any width, and `sdiv`/`srem`/fp are
  // excluded for the same reason, all by G2's shared shape predicate.
  //
  // 2b was the batch that CLOSED bd test_C_libtooling-nepx (the campaign's
  // customer `slice_control_seq_grover` became a ONE-RAIL program). 2c has NO
  // such single customer: its population is openlibm's float-word NORMALIZE
  // idiom (`SET_HIGH_WORD(x, ix ^ 0x3ff00000)` and its f32 twin — 28 of the 31
  // converted corpus sites), so its payoff is 29 fewer never-discharged
  // ancestor rails spread across 14 goldens, not one golden turning coherent.
  const Instruction::BinaryOps Op = bo->getOpcode();
  if (Op != Instruction::Add && Op != Instruction::Sub &&
      Op != Instruction::Xor)
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
  Value *Imm = bo->getOperand(0) == P ? bo->getOperand(1) : bo->getOperand(0);

  // G3–G7 — the shared positional fence. NO PLAN AT THIS SLOT, and that is a
  // statement about the pipeline rather than a caution: `lowerOps` runs before
  // `uncompute`, so the M-B interior partition has neither planned nor emitted
  // anything a fence here could read, and the chain ops this site's parent feeds
  // are not even `CallInst`s yet (arm (e) refuses them on sight). The LATE round
  // is where a plan exists; see `lowerLateReassignments`.
  return inPlaceFenceHolds(bo, P, Imm, Op, abiWidthFromType(bo->getType()), wd,
                           taint, DT, LI, /*Plan=*/nullptr, IgnoreSelfMarking);
}

// ── M-C LATE ROUND (bd test_C_libtooling-x67f, Increment 7a) ─────────────────

namespace {

// G1+G2 for an ALREADY-LOWERED site: is `C` one of the out-of-place
// `cq_template_{add,sub,xor}_<W>_hl(P, imm)` calls THIS PASS minted in
// `rewriteBinary`? Fills `Op`/`P`/`Imm`/`W` on success.
//
// THE SYMBOL IS RE-BUILT, NEVER PARSED. `dataName` is the one builder that
// minted it, so asking that builder the question back is the only spelling that
// cannot drift from the grammar (Rule 14, the `isHandleSlot`-is-the-inverse-of-
// `shapeSuffix` precedent). A hand-rolled `starts_with("cq_template_add_") &&
// ends_with("_hl")` would also match `_hl_controlled` and `_hl_inv` — a
// controlled gate and an adjoint twin, neither of which is a forward
// reassignment — and would silently accept any future shape token.
//
// THE WIDTH COMES FROM `HandleWidth`, AND THAT IS TWO FENCES IN ONE.
//   * A lowered handle is `i32` at EVERY logical width (Rule 15), so nothing in
//     the call's TYPES distinguishes an i8 site from an i64 one. `rewriteBinary`
//     recorded the logical width on the result via `promote`; this reads it back.
//   * Only a site this pass lowered HAS such a record. A hand-written
//     `cq_template_add_i32_hl` in an already-lowered lit fixture is therefore
//     left alone — deliberately: the late round exists to RE-DECIDE a decision
//     `lowerOps` made minutes earlier on IR whose shape it proved, not to adopt
//     IR whose provenance it cannot see (Prime Directive direction).
bool lateReassignShape(const CallInst *C, const TaintSet &taint,
                       Instruction::BinaryOps &Op, Value *&P, Value *&Imm,
                       StringRef &W) {
  const Function *Callee = C->getCalledFunction();
  if (!Callee || C->arg_size() != 2)
    return false;
  StringRef N = Callee->getName();
  // Cheap pre-filter so the exact rebuild below is asked only of plausible
  // symbols; the rebuild, not this, is the authoritative test.
  if (!N.starts_with("cq_template_") || !N.ends_with("_hl"))
    return false;
  StringRef Wl = taint.HandleWidth.lookup(const_cast<CallInst *>(C));
  if (Wl.empty())
    return false;
  static const struct {
    const char *Stem;
    Instruction::BinaryOps Op;
  } Rows[] = {{"add", Instruction::Add},
              {"sub", Instruction::Sub},
              {"xor", Instruction::Xor}};
  for (const auto &Row : Rows) {
    if (N != StringRef(dataName(Row.Stem, Wl, Shape::HL)))
      continue;
    Value *A0 = C->getArgOperand(0), *A1 = C->getArgOperand(1);
    // `_hl` means handle-left by construction, so this re-asserts rather than
    // decides — but a mislabelled symbol must fall back to out-of-place, never
    // put a rail in the classical immediate slot (G4's whole subject).
    if (!taint.Tainted.count(A0) || taint.Tainted.count(A1))
      return false;
    Op = Row.Op;
    P = A0;
    Imm = A1;
    W = Wl;
    return true;
  }
  return false;
}

}  // namespace

bool lowerLateReassignments(Module &M, WidthDispatch &wd, TaintSet &taint) {
  bool Changed = false;
  // Every out-of-place template symbol a conversion orphaned. A converted site
  // may have been the module's ONLY `cq_template_sub_i32_hl` call, and leaving
  // its `declare` behind is precisely the phantom-symbol shape this project
  // refuses to ship (the n0ui lesson, restated at G3's "asked LAST" note). The
  // erase is deferred to AFTER the function walk: `Function::eraseFromParent`
  // mutates `M`'s function list, which this loop is iterating.
  SmallPtrSet<Function *, 4> Orphaned;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    // 1. SHAPE-ONLY PRE-SCAN. Nothing here builds a dominator tree, recovers a
    //    DAG or resolves a runtime symbol, so a function with no leftover M-C
    //    site pays one name test per call and nothing else.
    SmallVector<CallInst *, 4> Sites;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *C = dyn_cast<CallInst>(&I);
        if (!C)
          continue;
        Instruction::BinaryOps Op;
        Value *P = nullptr, *Imm = nullptr;
        StringRef W;
        if (!lateReassignShape(C, taint, Op, P, Imm, W))
          continue;
        // A rail ANOTHER emitter owns is never re-lowered here. Phase-4 control
        // rails, 7.6 output rails, 7.2 graveyard rails and untainted merge rails
        // each have an owner that decides their teardown; converting one would
        // erase a value that owner still names. The SAME explicit-image
        // discipline the uncompute driver applies at terminal selection — and
        // for the same reason (do not rest on the incidental exclusion).
        //
        // ⚠ A **RAIL-BANK** RAIL IS DELIBERATELY NOT ON THIS LIST, AND THE
        // CLAIM THAT IT COULD NOT REACH HERE WAS FALSE (bd `xdu2` W1, Rule-13
        // review item I-1, 2026-09-15). `IMPL_B2.md` §12 round 4 and
        // `SCOPE_B.md` §5.2 said D6's subtraction sites *"were measured
        // unreachable for a bank rail"* because `isTerminalHandle` stops the
        // nomination at source. That is true of the other three families —
        // `collectTerminalCandidates` (explicit), `isInteriorTerminalHandle`
        // (structural: a `store` is not a `CallInst`), `DagTraversal`'s closure
        // scan (incidental, via `D.NotClosed`) — and FALSE of this one, which
        // refuses a bank rail by NOTHING. The correction is recorded HERE, at
        // the site, and not only in a track record: the review's own I-4 and
        // CLAUDE.md's L7-with-a-twist are both about a correction that never
        // reached the source and was re-derived three rounds running.
        //
        // IT IS LEFT ABSENT ON PURPOSE, AND THE GROUND IS MEASUREMENT, NOT
        // ARGUMENT. A bank cell parking `t = q + 7` DOES reach this site and IS
        // converted in place — `cqrt_addc_i32(h0, 7)` — and that stream is
        // BYTE-IDENTICAL to its array-free register twin, which the ORACLE
        // accepts (review probes `h01` vs `h04`). Where a later reader exists
        // the conversion's own `provablyBefore` discipline refuses it and the
        // out-of-place `cq_template_add_i32_hl` stands, again byte-identically
        // to the register twins (`h02`/`h03`, `h05`/`h06`). Adding
        // `railStoredToRailBank` here would therefore REMOVE an accept whose
        // circuit is right — an over-decline, which the owner's 2026-09-11
        // ruling calls a defect rather than a margin.
        //
        // ⚠ RETIREMENT TRIGGER, because the measurement is one shape and not a
        // proof: the in-place conversion RELABELS the parked rail, and the
        // stale-reader fence's memory hop (`railBankParkedRails`, review F-1)
        // walks for `cq_theta_` gates and NOT for a dtzb in-place `add`/`xor` —
        // the documented `WireWalk.h` vocabulary gap, bd `a3z7`. So the day a
        // bank rail's in-place reassignment can sit BETWEEN the store and a
        // later cell read, this absence and that gap compose into a stale read
        // the fence cannot see.
        // ⚠ CORRECTED 2026-09-24 (bd `xdu2.1`, Track B — L7, fixed at the source):
        // this sentence used to say that "today it cannot" because "D5 admits
        // only a measurement … so there is no reader after the conversion to be
        // staled". FALSE: a bank `cq_measure` IS such a reader, and it sits after
        // the site in plain `-O1` C (`int b[3]; for(..) b[i]=q; int t=q+3;
        // cq_measure(t); for(..) cq_measure(b[i]);` —
        // `railbank_stale_accept_parked_parent_add_stays_out_of_place.ll`,
        // twin rows `p10`/`p11`). What refuses the conversion there, MEASURED
        // by mutation, is `inPlaceFenceHolds`' G6/G7 pair: the PARKING `store`
        // is a plain-IR user of `P`, so it is either not provably before the
        // site (G6) or, when it is, `priorUseIsSettled` clause (e) refuses any
        // non-call user (G7). That is a STRUCTURAL refusal — every parked
        // value has a NON-CALL user on the bank's store path: the `store`
        // itself on an `int` bank, or the storage `CastInst` (the `zext` of a
        // `_Bool` into its `i8` cell, a widening `sext`/`zext` into a wider
        // cell) that feeds the store — but it is G7(e)'s, not this list's.
        // RETIREMENT TRIGGER, restated: the day G7(e) admits a `StoreInst` OR a
        // storage `CastInst` (or the bank stops being fed through a non-call
        // user of the parked value), this absence and the vocabulary gap
        // compose. Re-derive BOTH in the same change.
        // ⚠ THIS IS RIGHT FOR THIS SITE AND IS NOT THE ONLY IN-PLACE MINTER
        // (bd `xdu2.1`, Rule-13 round 2 finding F-1, 2026-09-24). The rolled
        // in-loop collapse (`LoopLowering::collapseRailPhisIn`) converts an
        // in-loop `q ^= 3` on a parked `q` through `markInPlaceRailOp`, and no
        // G7(e) stands in front of it; that path accepted a stale bank read
        // until `staleReadOfValue` learned the bank-load hop
        // (`railBankCellReadsOf`). Every in-place minter and what refuses each
        // for a parked rail is enumerated in `TRACK_B.md` §6b.
        if (taint.ControlOwnedRails.count(C) || taint.OutputRails.count(C) ||
            taint.GraveyardRails.count(C) || taint.UntaintedMergeRails.count(C))
          continue;
        Sites.push_back(C);
      }
    if (Sites.empty())
      continue;

    // 2. THE PLAN, ONCE PER FUNCTION, ON THE PRE-CONVERSION IR.
    DominatorTree DT(F);
    LoopInfo LI(DT);
    InteriorDischargePlan Plan = planInteriorDischarges(F, taint);

    // 3. DECIDE EVERYTHING, THEN CONVERT EVERYTHING — the same plan-all-then-
    //    emit-all discipline the interior partition itself runs on, and here it
    //    is also a LIFETIME requirement: a conversion ERASES its template call,
    //    and that call may be the very `Instruction *` a plan entry points at
    //    (or the node a later site's `provablyBefore` walks). Deciding first
    //    means no decision ever reads a plan that a sibling conversion has
    //    already invalidated.
    //
    //    THE BATCH CANNOT WIDEN ITSELF, and that is worth stating because two
    //    M-C sites on one register are the campaign's own `+= off … -= off`
    //    shape. Each decision is taken with every sibling still OUT of place, so
    //    a site whose parent is read by an undischarged sibling rail is refused
    //    (arm (d)/(d2)) exactly as it would be alone. Converting a sibling only
    //    ever turns a template producer into an in-place gate, which arm (a)
    //    settles — strictly more permissive, and never consulted after the fact.
    SmallVector<CallInst *, 4> Accepted;
    for (CallInst *C : Sites) {
      Instruction::BinaryOps Op;
      Value *P = nullptr, *Imm = nullptr;
      StringRef W;
      if (!lateReassignShape(C, taint, Op, P, Imm, W))
        continue;  // unreachable — the pre-scan proved it; re-asked for `Op`/…
      if (inPlaceFenceHolds(C, P, Imm, Op, W, wd, taint, DT, LI, &Plan))
        Accepted.push_back(C);
    }

    for (CallInst *C : Accepted) {
      Instruction::BinaryOps Op;
      Value *P = nullptr, *Imm = nullptr;
      StringRef W;
      if (!lateReassignShape(C, taint, Op, P, Imm, W))
        continue;
      // `_hl` is handle-LEFT, so the `sub` direction test is satisfied by
      // construction; it is passed explicitly rather than hard-coded `true` so
      // the emitter keeps its own loud fallback (see `emitInPlaceReassign`).
      if (!emitInPlaceReassign(C, Op, P, Imm, /*HandleIsLhs=*/true, W, wd))
        continue;  // diagnosed + left standing; never erase an un-lowered site.
      // The out-of-place rail is GONE: scrub every side table keyed on it before
      // the erase, or a `Value *`-keyed lookup at the reused address answers for
      // a register that no longer exists (the R-A stale-`HandleWidth` lesson in
      // `promote` above, which is the same hazard from the other end).
      taint.Tainted.erase(C);
      taint.HandleWidth.erase(C);
      taint.BirthOrder.erase(C);
      Function *Sym = C->getCalledFunction();
      C->eraseFromParent();
      if (Sym)
        Orphaned.insert(Sym);
      Changed = true;
    }
  }
  for (Function *Sym : Orphaned)
    if (Sym->isDeclaration() && Sym->use_empty())
      Sym->eraseFromParent();
  return Changed;
}

}  // namespace cq
