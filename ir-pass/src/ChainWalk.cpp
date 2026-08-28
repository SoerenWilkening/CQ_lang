// ChainWalk.cpp — see header. Terminal-handle detection + the shared per-gate
// predicates. The whole-DAG recovery itself lives in `DagTraversal` (WI-4); this
// module is the vocabulary both it and the uncompute driver consult.

#include "ChainWalk.h"

#include "TaintPropagation.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

bool isAbiQramStore(const CallInst *G) {
  const Function *Callee = G ? G->getCalledFunction() : nullptr;
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  if (!N.starts_with("cqrt_qram_store_"))
    return false;
  // The `_unc` adjoint twins (`..._unc`, `..._controlled_unc`) are never a FORWARD
  // store — they are what the spine EMITS, not what it recognizes.
  if (N.ends_with("_unc"))
    return false;
  // VOID IS THE LOAD-BEARING TEST, NOT THE ARITY (bd 1fim Rule-13 round, 2026-08-11).
  // "A store MINTS NO RAIL" is the semantic property this whole predicate stands on:
  // it is the ONLY reason `emitInverseCall` may adjoint a store with a SAME-ARGS
  // `_unc` instead of the out-first form every rail-minting producer gets. Arity is
  // merely a proxy for it, and an INCOMPLETE one — the first draft of this fix checked
  // arity alone, and three reviewers independently reproduced the ORIGINAL defect at
  // the FROZEN arity by flipping only the return type:
  //     %s = call i32 @cqrt_qram_store_i32(i32 %h, i32 3, i32 4)  ; arity 3, NON-void
  //     call void @cqrt_qram_store_i32_unc(i32 %h, i32 3, i32 4)  ; cannot name %s
  //     call void @cqrt_free(i32 %h)                              ; freed anyway
  // `opt` rc=0, verify-clean, and `free_pairing_check.py` reports "2 verified, 0
  // violation(s)". Test the property itself; do not proxy it again.
  if (!G->getType()->isVoidTy())
    return false;
  // EVERY OPERAND IS AN `i32` HANDLE, at every width — Rule 15 ("a runtime handle is
  // always `i32` regardless of width"), and the header is uniform on it:
  // `void cqrt_qram_store_<W>(int32_t arr, int32_t idx, int32_t val)` for all nine
  // widths (runtime/cq_runtime.h:541-549), plus a leading `int32_t pred` on the
  // guarded twin. THE THIRD AXIS, added after a Rule-13 verifier built
  // `declare void @cqrt_qram_store_i32(i32, i32, double)` — VOID and arity 3, so the
  // void+arity draft ACCEPTED it — and the pass then minted an `_unc` whose signature
  // does not match the frozen body. That is not caught at link: C symbols carry no
  // signature, so the name resolves to the real 3×i32 body and the call runs with a
  // reinterpreted operand. With this test the predicate matches the frozen PROTOTYPE,
  // not a proxy for it.
  for (const Use &A : G->args())
    if (!A.get()->getType()->isIntegerTy(32))
      return false;
  // The two frozen forward shapes, and their EXACT arities:
  //   plain      `cqrt_qram_store_<W>(arr, idx, val)`              — 3
  //   guarded    `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` — 4
  if (N.ends_with("_controlled"))
    return G->arg_size() == 4;
  // A name that CONTAINS `_controlled` without ending in it is an off-pattern
  // spelling of neither frozen form — decline rather than fall through to the
  // plain-arity test (the Prime Directive; over-declining is the safe direction).
  if (N.contains("_controlled"))
    return false;
  return G->arg_size() == 3;
}

bool isInPlaceGateOn(const CallInst *G, const Value *H) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // iw81.7 / Phase 7.5 Inc 2: a QRAM store is a VOID in-place mutation on its ARRAY
  // handle — arg 1 for the GUARDED form `cqrt_qram_store_<W>_controlled(flag, arr,
  // idx, val)` (arg 0 is the path-predicate flag), arg 0 for the plain
  // `cqrt_qram_store_<W>(arr, idx, val)`. Recognized BEFORE the generic
  // `_controlled` bail below (a controlled gate is normally NOT an in-place gate,
  // but this store IS on its array). The borrowed tainted operands (flag / idx /
  // val) are enqueued as DAG parents by `DagTraversal`; the flag-mint compare
  // reverses AFTER this gate's `_unc` (the strip).
  //
  // The ABI-shape test is `isAbiQramStore` — the ONE definition, shared with
  // `EmitInverse::isInverseEmittable` (bd test_C_libtooling-1fim). That predicate
  // used to re-spell the match as a bare PREFIX test with no arity check, so an
  // off-ABI-arity store was invertible over there and not an in-place gate over
  // here: two predicates, one gate, different answers — the same defect shape as
  // the `railOf` mis-attribution below (bd uow0). Driving both from one definition
  // makes them agree BY CONSTRUCTION rather than by two spellings being kept in
  // sync (Rule 14).
  if (isAbiQramStore(G))
    return N.ends_with("_controlled") ? G->getArgOperand(1) == H
                                      : G->getArgOperand(0) == H;
  if (N.contains("_controlled"))
    return false;
  // Uncontrolled rotation `cqrt_ry/rz_<W>(H, θ)` — arg_size 2, arg 0 is the
  // handle. Mints no new value (void), so it belongs to `H`'s DAG link.
  if ((N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) &&
      G->arg_size() == 2 && G->getArgOperand(0) == H)
    return true;
  // Issue dtzb / bd test_C_libtooling-6uqc (M-C): the IN-PLACE VALUE gates
  // `cqrt_addc_<W>(H, imm)` / `cqrt_xorc_<W>(H, imm)` — VOID, arg_size 2, arg 0
  // is the handle, arg 1 the CLASSICAL immediate (Rule 15: the handle is i32 at
  // every width; the immediate carries the logical width). Like a rotation they
  // MUTATE the one rail and mint nothing, so they belong to `H`'s DAG link.
  //
  // WHY THIS ENTRY EXISTS ONLY NOW, and why it is REQUIRED rather than tidy.
  // Before M-C these gates were minted ONLY by the 7.3/7.4 loop path, where the
  // rail is loop-carried and the whole-DAG spine leaks it anyway — so the
  // omission was inert. M-C emits them on STRAIGHT-LINE rails the spine must
  // reverse and free, and every consumer of this predicate then needs them:
  //   * `isTerminalHandle` — an addc user is benign (it mints no handle), so the
  //     rail stays its own chain's terminal. Without this the chain has NO
  //     terminal at all and is never recovered.
  //   * `DagTraversal` step 1 — the addc joins `D.Calls`, so `emitDagReversal`
  //     emits its adjoint (`cqrt_addc_<W>(H, -imm)`; `EmitInverse` already knows
  //     the recipe) and the rail actually returns to |0> before `cqrt_free`.
  //   * `DagTraversal` step 3 closure — an addc user no longer reads as an
  //     unowned consumer that marks the whole DAG `NotClosed`.
  //   * `railOf` — DERIVED from this predicate (bd uow0), so the gate is
  //     attributed to the register it writes rather than to itself.
  //   * clause (d) (`Uncomputation.cpp`'s moved-anchor scan, and reverse program
  //     order generally) — an in-place basis-relabelling gate this predicate
  //     cannot see is precisely the "invisible write between forward and
  //     adjoint" that clause (d) exists to forbid.
  // VOID IS THE LOAD-BEARING TEST, NOT THE ARITY (the `isAbiQramStore` lesson,
  // bd 1fim, restated here because the first draft of this row proxied it with
  // arity alone and the Rule-13 round demonstrated the regression: a hand-written
  // NON-void same-named fake at the frozen arity closed the DAG, got a same-args
  // "adjoint" emitted for a rail-MINTING call, and a `cqrt_free` of a chain with
  // an unaccounted mint — verify-clean, free-pairing-clean, wrong). A non-void
  // fake must stay an unrecognized consumer (`NotClosed` => Rule-6 safe leak).
  if ((N.starts_with("cqrt_addc_") || N.starts_with("cqrt_xorc_")) &&
      G->getType()->isVoidTy() && G->arg_size() == 2 &&
      G->getArgOperand(0) == H)
    return true;
  // (The plain QRAM store is handled by the `isAbiQramStore` arm above, together
  // with its guarded twin — one definition for both frozen shapes.)
  return false;
}

bool isAllocMint(const Value *V) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // A qubit-register mint, OR (Phase 7.5 Inc 2) a QRAM array-handle mint: the
  // alloca-backed mutable array is an in-place-mutated register ROOT — its
  // stores are reversed (LIFO) but the array handle itself is a CLASSICAL
  // resource token, never freed (§2.9; Inc 1 "array-handle-never-freed"). Both
  // bottom out the DAG (no tainted parents to hop to — alloc takes a classical
  // count).
  return N.starts_with("cqrt_alloc_") || N.starts_with("cqrt_qram_alloc_");
}

bool isMeasureSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_measure_");
}

bool isOutputSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cqrt_tape_write_");
}

bool recordsIntoKeptCarrier(const CallInst *S, const Value *H) {
  // THE COPY-OUT SURFACE (bd test_C_libtooling-5pio, owner ruling 2026-08-11). A
  // method-B `cqrt_copy_<W>(src, dst)` records `src`'s basis label onto `dst`, and
  // `dst` is a KEPT carrier the whole-DAG reversal never touches — structurally the
  // same relation to the reversal as a tape write, so it seeds the same freeze.
  //
  // SLOT-AWARE here, unlike the tape arm below: `isCopyOutSink` matches only when
  // `H` is arg 0, the SOURCE.
  //
  // STATE THE REASON CORRECTLY, because the tempting one is FALSE. A draft of this
  // comment said a blind scan "would seed the destination and freeze the very
  // register the copy exists to produce". That harm CANNOT occur, and a Rule-13
  // reviewer measured it three ways: a freeze suppresses only a `cqrt_free`, never
  // an adjoint, and a copy DESTINATION is never freeable in the first place — in the
  // destination role it is not a benign closure user, so it falls through to
  // `D.NotClosed = true` and the whole DAG is left allocated, and it fails
  // `isTerminalHandle` for the same reason. Seeding it would change nothing; if it
  // ever did, it would be a leak — the safe direction, exactly as the tape arm's own
  // slot-BLINDNESS argues four lines below.
  //
  // So the asymmetry is sound, but it is sound because of that `NotClosed`
  // compensation, not because of any harm avoided. Written down here because the
  // compensation is what a future over-decline-reduction would remove: make the
  // destination slot benign for closure and this arm silently needs to become
  // slot-blind. (bd 5pio Rule-13 round; CLAUDE.md's warning about agent-authored
  // justifications hardening by repetition is exactly what this replaces.)
  //
  // WHY THIS AND NOT A PREDICATE ON THE DESTINATION. bd 5pio asked whether to admit
  // the copy sink only when `dst` is provably measured. Bennett.jl — the project's
  // standing ground truth for the compute/copy-out/uncompute model — requires
  // NOTHING of a copy destination: not measured (it has no measurement concept), not
  // kept, not even fresh or zero, and it ships three kernels that copy out and then
  // uncompute-and-free the SOURCE into a live register, an accumulator and a scratch
  // checkpoint respectively. A dst-measured rule would break all three. Bennett puts
  // the entire reclamation license on the SOURCE's own chain, which is what this
  // seed hands to `preservesBasisUnderRecord`. Note also what a dst-measured guard
  // could not have caught: it says nothing about the source's correlation with its
  // own ANCESTORS, which is exactly what the backward walk over `AncEdges` models.
  // (bd memory [bennett-copyout-destination-2026-08-11].)
  //
  // CAUTION, because Bennett's own discipline does NOT discriminate CQ's hazard:
  // `ry(%h); copy(%h,%dst); ry(-%h); free(%h)` SATISFIES it completely — exact whole
  // -chain adjoint, copy strictly between — and the unitary is still wrong. The
  // discrimination is `preservesBasisUnderRecord`'s rotation test, which is CQ's own
  // and has no Bennett counterpart (Bennett's gate universe is closed at three basis
  // permutations, so the invariant is vacuous there).
  if (isCopyOutSink(S, H))
    return true;
  // Tape-only and SLOT-BLIND — see the header for why both are load-bearing (the
  // controlled twin records its ctrl at arg 0 and its src at arg 2, and the tape
  // token is never a DAG rail so a blind scan cannot over-match).
  if (!isOutputSink(S))
    return false;
  for (const Use &A : S->args())
    if (A.get() == H)
      return true;
  return false;
}

bool isCopyOutSink(const CallInst *G, const Value *H) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // The UNCONTROLLED 2-arg basis copy `cqrt_copy_<W>(src, dst)` reading `H` as its
  // SOURCE (arg 0). Like a measure / tape-write sink it READS H without consuming
  // it, so the spine treats it as a benign terminal user; the copy DESTINATION
  // (dst) is the kept carrier. The 3-arg `_controlled` data-mux copy (4.4/6.5) and
  // any `_inv`/`_unc` twin fail.
  //
  // IT IS ALSO A `recordsIntoKeptCarrier` (bd 5pio, owner ruling 2026-08-11), so
  // this predicate is now load-bearing for the 261j record FREEZE and not only for
  // closure. This comment used to read "NOT a `recordsIntoKeptCarrier` — bd 8gi5
  // owns whether this surface needs the 261j freeze"; that ticket ruled.
  //
  // SRC AND DST MUST BE DISTINCT. `cqrt_copy_<W>(%x, %x)` is rejected, and the
  // reason is that BOTH readers of this predicate — the closure scan
  // (`DagTraversal`) and `isTerminalHandle` — `continue` on the FIRST match, so a
  // value passed in both slots would be read purely as a preserved SOURCE and its
  // WRITE role would vanish: the spine then frees a rail a CNOT wrote, with that
  // write never adjointed (`opt` rc=0, verify-clean; stage 2b does catch it, as
  // `VIOLATION B1-input-aliases-written-rail`). `railOf` already reasons explicitly
  // about the same-value-in-two-slots case for in-place gates; this predicate never
  // got that treatment until bd 5pio's Rule-13 round found it. Declining the aliased
  // form is the over-declining direction and no emitter mints it.
  return N.starts_with("cqrt_copy_") && !N.contains("_controlled") &&
         !N.ends_with("_inv") && !N.ends_with("_unc") && G->arg_size() == 2 &&
         G->getArgOperand(0) == H && G->getArgOperand(0) != G->getArgOperand(1);
}

Value *railOf(CallInst *G) {
  // An in-place gate's rail is the operand it MUTATES, so ASK `isInPlaceGateOn`
  // — the single definition of that relation — instead of re-spelling its
  // arity/suffix tests here. Re-spelling them is exactly how the guarded QRAM
  // store came to be mis-attributed (bd test_C_libtooling-uow0): this function
  // returned the arg-0 FLAG of `cqrt_qram_store_<W>_controlled(flag, arr, idx,
  // val)` while `isInPlaceGateOn` correctly matched the arg-1 ARRAY of the very
  // same gate, so the two predicates disagreed about which register the gate
  // writes. Driving one from the other makes them agree BY CONSTRUCTION rather
  // than by two spellings being kept in sync (Rule 14).
  //
  // First match wins. That is unambiguous, not a tie-break: `isInPlaceGateOn`
  // matches exactly ONE argument position per callee shape, and when the same
  // SSA value is passed in two slots of one gate the answer is that value either
  // way.
  for (Value *Op : G->args())
    if (isInPlaceGateOn(G, Op))
      return Op;
  const Function *Callee = G->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  // `cqrt_x` is self-inverse and acts on its arg-0 handle. `isInPlaceGateOn`
  // deliberately does not recognize it (the same reason it is absent from
  // `preservesBasisUnderRecord`), so the loop above never returns for it.
  //
  // REACHABILITY, stated exactly — an earlier draft of this comment said
  // "UNREACHABLE, a void call can never be a DAG handle" and that was WRONG
  // (measured in the bd uow0 Rule-13 round). The premise holds for the real
  // ABI symbol, which IS void; but `declineTaintEscapes` carves out `cqrt_*` by
  // NAME with no signature check, so a user-declared NON-void `@cqrt_x` is
  // recovered by the DAG walk's tainted-CallInst path and this arm does fire.
  // Behaviour there is identical to the pre-uow0 spelling (arg 0) and is the safe
  // direction (the fictional result is leaked, not freed). Kept because it AGREES
  // with the loop above — were `isInPlaceGateOn` ever taught `cqrt_x` it would
  // match this same arg-0 handle — so unlike the pre-uow0 spelling for the QRAM
  // store, this arm cannot contradict it.
  if (N == "cqrt_x" && G->arg_size() >= 1)
    return G->getArgOperand(0);
  // A reassigning producer (`cq_template_*`, `cqrt_qram_load_<W>`): the fresh
  // result IS the rail (PRD §2.11).
  return G;
}

bool isTerminalHandle(Value *Handle, const TaintSet &taint) {
  if (!taint.Tainted.count(Handle))
    return false;
  // Terminal iff EVERY user is benign: an in-place rotation on `Handle` (mints
  // no new value), a measurement sink, or a non-quantum read. ANY other gate
  // that takes `Handle` as an operand — a data/compare/cast template, a
  // controlled gate, a `_controlled`/teardown `_inv` — consumes the register
  // forward or keeps it live as control input, so `Handle` is NOT the terminal.
  for (User *U : Handle->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      continue;  // a classical/non-call read does not extend the quantum chain
    if (isInPlaceGateOn(CI, Handle) || isMeasureSink(CI) || isOutputSink(CI) ||
        isCopyOutSink(CI, Handle))
      continue;  // in-place rotation, measurement/output sink (7.6), or a method-B
                 // copy-out reading Handle as src (sxuk — preserves it)
    return false;  // any other gate consumes `Handle` ⇒ not the chain terminal
  }
  return true;
}

}  // namespace cq
