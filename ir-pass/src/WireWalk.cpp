// WireWalk.cpp — Shared forward in-place-gate wire walk. See WireWalk.h for
// the contract and the two consumer modes (ArmClassify position-free;
// OpcodeLowering position-aware). Hoisted from
// ArmClassify::wireGainsNonDiagonalGate (test_C_libtooling-ee5) so the
// straight-line stale-record guard (test_C_libtooling-uzb) reuses the same
// core instead of forking it (Rule 14).

#include "WireWalk.h"

#include "TaintPropagation.h"  // TaintSet (the chained-theta ancestry crossing, F-1b-1)

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/LoopInfo.h"          // leg 1b (bd 3d8q F-D2-2)
#include "llvm/Analysis/ScalarEvolution.h"   // leg 1b (bd 3d8q F-D2-2)
#include "llvm/IR/Dominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"               // leg 1b (bd 3d8q F-D2-2)
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <cassert>
#include <iterator>
#include <optional>

using namespace llvm;

namespace cq {

namespace {

bool isCallToPrefix(const Value *V, StringRef Prefix) {
  const auto *CI = dyn_cast<CallInst>(V);
  if (!CI)
    return false;
  const Function *F = CI->getCalledFunction();
  return F && F->getName().starts_with(Prefix);
}

// ── bd test_C_libtooling-8h7d.5 — the RECORD-REFRESH cut (7.3 Increment 3) ──
//
// THE WHOLE INCREMENT IN ONE SENTENCE: a record that is RE-ESTABLISHED on every
// path from a wire gate back to the read cannot be staled by that gate. Inside a
// classically-bounded loop that is the difference between "the body's Ry is next
// iteration's PRODUCER" (fine) and "the body's Ry relabelled a register this
// read still denotes" (the stale-record miscompile). Everything below is the
// machinery for deciding which one you are looking at, and it is deliberately
// EXACT — a heuristic here is a silent miscompile in one direction and an
// uncompilable `for` loop in the other.

// The WIRE of `Seed`: every SSA name that denotes the same physical register.
// EXTRACTED from `findNonDiagonalWireGate`'s own per-seed closure rather than
// re-spelt (Rule 14) — the backward ancestry (diagonal `cq_phi` and chained
// `cq_theta` arg-0 hops to the wire origin) followed by the forward walk over
// every in-place gate on arg-0, plus, when `CrossValueRouting`, the phi/select
// routing edges that carry the same physical handle.
//
// IT ALSO CROSSES AN IN-PLACE VALUE SELF-UPDATE (`q += c` / `q ^= c`, issue
// dtzb), which the gate-FINDING walk does not, and the asymmetry is deliberate
// and directional. Here a bigger wire can only make `phiTracksWire` REFUSE a
// barrier — the safe direction — whereas in the finding walk crossing that edge
// would flag thetas on a rail the op MINTED (an out-of-place `add` produces a
// fresh handle whose later rotations touch nothing of the parent's wire) and
// over-decline straight-line programs the M-C fence already proves sound. Shape
// test only, no `TaintSet`: over-inclusion is free in this direction.
void collectWireValues(Value *Seed, bool CrossValueRouting,
                       SmallPtrSetImpl<Value *> &Out) {
  SmallVector<Value *, 16> Work;
  for (Value *V = Seed;;) {
    Work.push_back(V);
    Out.insert(V);
    auto *CI = dyn_cast<CallInst>(V);
    if (!CI || CI->arg_size() < 1)
      break;
    Value *Arg0 = CI->getArgOperand(0);
    // ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 — the `@cq_phi_<sfx>` family is
    // RETIRED and `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE, so the
    // register-free `void @cq_phi(double)` never reaches here. Kept, not deleted
    // (PRD §6.2 row P6); see the note at `ArmClassify.cpp`'s `isPhiCall` for why
    // widening it would read the wrong operand.
    if (isCallToPrefix(CI, "cq_phi_")) {
      V = Arg0;
      continue;
    }
    // ⚠ THE NARROW ANCESTRY, ON PURPOSE (bd 3qlq.4 round 2, F-1b2-3). This is
    // `thetaOnPathTo`'s closure, whose ONLY consumer is `phiTracksWire`, where
    // the polarity is INVERTED (ArmClassify.cpp: a PRECONDITION that GRANTS) —
    // so widening it as `findNonDiagonalWireGate` was widened for F-1b-1 (cross
    // the arg-0 edge of ANY tainted parent) would move an ACCEPT-direction
    // predicate and needs its own Rule-13 round. The parity gap (a template
    // parent stops this closure at the chained theta) is recorded with bd
    // test_C_libtooling-r903; no caller supplies a taint set here today, and a
    // defaulted parameter that nothing supplies was deleted rather than left to
    // read as a fix (round 2's F-1b2-3).
    if (isCallToPrefix(CI, "cq_theta_") &&
        (isCallToPrefix(Arg0, "cq_theta_") || isCallToPrefix(Arg0, "cq_phi_"))) {
      V = Arg0;
      continue;
    }
    break;  // wire origin (source theta / template result / argument).
  }
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    for (User *U : V->users()) {
      if (CrossValueRouting) {
        if (auto *P = dyn_cast<PHINode>(U)) {
          if (Out.insert(P).second)
            Work.push_back(P);
          continue;
        }
        if (auto *Sel = dyn_cast<SelectInst>(U)) {
          if (V != Sel->getCondition() && Out.insert(Sel).second)
            Work.push_back(Sel);
          continue;
        }
      }
      if (auto *BO = dyn_cast<BinaryOperator>(U)) {
        if ((BO->getOpcode() == Instruction::Add ||
             BO->getOpcode() == Instruction::Xor) &&
            Out.insert(BO).second)
          Work.push_back(BO);
        continue;
      }
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || CI->arg_size() < 1 || CI->getArgOperand(0) != V)
        continue;  // not an in-place gate on this wire (angle/data uses, br).
      if ((isCallToPrefix(CI, "cq_theta_") || isCallToPrefix(CI, "cq_phi_")) &&
          Out.insert(CI).second)
        Work.push_back(CI);
    }
  }
}

// Does some execution path from `V` (exclusive) to `Target` (a terminator that
// `V` dominates) run a `cq_theta` ON `V`'S OWN WIRE? Paths that re-execute `V`
// are CUT — going around a back edge re-binds `V`, so what happens on the far
// side belongs to the next activation, not to this one.
//
// PER WIRE, not per program (bd test_C_libtooling-8h7d.5 Rule-13 round 1,
// finding OD1). This asked `isAnyThetaCall` — ANY `cq_theta` anywhere on the
// path — until 2026-08-30, and the justification given was that over-matching
// "only ever WITHHOLDS a new accept". That is true of soundness and false of
// usefulness: it made the barrier depend on SOURCE ORDER. Measured —
//     q = q0; cq_theta(&q,g); z = 0; cq_theta(&z,.125); for (…) { if (q>5) … }
// declined, and the SAME program with the two mints swapped compiled, because
// `%z` happened to sit between `%q` and the loop entry. It also made two
// independent registers, each with its own tainted `if` in one loop, permanently
// unlowerable — a whole shape class lost to a register the walk was not even
// reasoning about. A theta rotates the wire its ARG-0 names; if that name is not
// in this seed's wire closure it cannot stale this record.
//
// Exact block walk, each block scanned at most once. Blocks are entered only at
// the TOP, so re-entering `V`'s own block always re-executes `V` before
// anything after it (`V` dominates `Target`, hence precedes it in that block) —
// which is why that case is a plain cut and not a re-scan.
//
// `Wire == nullptr` runs the OLD wire-blind test (any theta at all). That mode is
// kept for one reason and used for exactly one purpose — see `thetaOnPathTo`
// below, which uses it as a cheap NECESSARY condition so the expensive closure is
// only ever built for a path that has a theta on it at all. It is never the
// answer.
bool thetaOnPathToImpl(const Instruction *V, const Instruction *Target,
                       const SmallPtrSetImpl<Value *> *Wire) {
  auto Stales = [&](const Instruction &I) {
    const auto *CI = dyn_cast<CallInst>(&I);
    if (!CI || !isCallToPrefix(CI, "cq_theta_") || CI->arg_size() < 1)
      return false;
    return !Wire || Wire->count(CI->getArgOperand(0)) != 0;
  };
  const BasicBlock *VB = V->getParent();
  for (auto I = std::next(V->getIterator()), E = VB->end(); I != E; ++I) {
    if (&*I == Target)
      return false;  // reached the edge with the wire quiet.
    if (Stales(*I))
      return true;
  }
  SmallPtrSet<const BasicBlock *, 32> Seen;
  SmallVector<const BasicBlock *, 32> Work(succ_begin(VB), succ_end(VB));
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (B == VB)
      continue;  // re-executes `V` — a different activation. Cut.
    if (!Seen.insert(B).second)
      continue;
    bool Reached = false;
    for (const Instruction &I : *B) {
      if (&I == Target) {
        Reached = true;
        break;
      }
      if (Stales(I))
        return true;
    }
    if (Reached)
      continue;  // this path ended at the edge; do not walk past it.
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

bool thetaOnPathTo(const Instruction *V, const Instruction *Target) {
  // The wire-blind answer is a NECESSARY condition for the per-wire one (a theta
  // on `V`'s wire is a theta), so run the cheap block walk first and build the
  // user-graph closure only when it says there is something to classify.
  // `phiTracksWire` is called once per candidate gate per barrier-closure round,
  // so the closure would otherwise be rebuilt many times per function. The result
  // is identical either way.
  //
  // NOT a fix for a measured regression — say so, because the first draft of this
  // comment claimed one. The apparent 0.36s -> 1.23s on the tree's biggest fixture
  // was COLD-START noise on a freshly relinked plugin; re-measured warm, the
  // per-wire build is 0.25s against 0.24-0.25s for the base plugin, i.e. inside
  // the noise. This is a structural short-circuit, not a rescue.
  if (!thetaOnPathToImpl(V, Target, /*Wire=*/nullptr))
    return false;
  SmallPtrSet<Value *, 16> Wire;
  collectWireValues(const_cast<Instruction *>(V), /*CrossValueRouting=*/true,
                    Wire);
  return thetaOnPathToImpl(V, Target, &Wire);
}

// Does PHINode `P` faithfully DENOTE the wire at the moment it executes?
//
// THIS IS THE LOAD-BEARING DISTINCTION, and the naive version of it is a silent
// miscompile. "A phi just re-reads the wire" is FALSE in general: a phi's value
// is its taken INCOMING, not the register's current contents. Two shapes make
// the point, and only the first may be admitted:
//
//   TRACKS   `%q = phi [%q0, %pre], [%qn, %latch]` where `%qn` is the last wire
//            write of the body. On iteration 2 `%q` denotes exactly the state
//            the previous iteration left, which IS the wire. (The `for` loop
//            this increment exists for.)
//   DOES NOT `%p = phi [%q, %pre], [%p, %latch]` with a body `cq_theta` whose
//            result is discarded (or kept in another name). `%p` is provably
//            `%q` — the PRE-LOOP record — while the wire has moved under it.
//            Reachable from C (`for (…) { d = q + 1; int g = q; cq_theta(&g, t); }`), and
//            granting it the barrier would ACCEPT the classic iteration-2 stale
//            read. That is why this predicate exists at all.
//
// The test: for every incoming (`V`, `B`), no `cq_theta` runs between `V` and
// the `B → P` edge. Then `P`'s value at every execution equals the wire, so
// re-executing `P` re-establishes the record — the premise `gateIsHarmless`
// leg 2 needs. A non-instruction incoming (a constant / argument) means the
// value at that edge is not a wire record at all: refuse.
// DEFINED BELOW, OUTSIDE THE ANONYMOUS NAMESPACE (bd test_C_libtooling-drbq
// Inc 3): `ArmClassify`'s R6 per-activation refresh fence asks the identical
// question of a rail record's own definition, so the predicate is EXPORTED
// rather than re-spelled (Rule 14 — bd [[identity-carry-phi-does-not-refresh]]
// is precisely a case where two spellings of "does re-executing this def
// re-read the wire" would have disagreed). The declaration in WireWalk.h is what
// the two call sites above resolve to.

// "Can `From` reach `To` on some execution path WITHOUT executing any of
// `Barriers`?" An EXACT forward CFG walk (each block scanned at most once, so it
// terminates), deliberately NOT `llvm::isPotentiallyReachable`: that helper's
// exclusion set is per-BLOCK, and it bails `true` past a 32-block scan limit —
// the same two reasons `regionEntryInLoop` (ControlDetect.cpp) hand-rolls its
// walk. Here the barrier is an INSTRUCTION, and it routinely lives in the very
// block the walk is trying to reach.
//
// `From`'s own block is entered MID-WAY (at `From`), so its tail is scanned
// separately and the block is NOT pre-marked visited — a back edge that
// re-enters it from the top is a genuinely different traversal.
bool reachesWithoutBarrier(const Instruction *From, const Instruction *To,
                           const SmallPtrSetImpl<const Instruction *> &Barriers) {
  const BasicBlock *FB = From->getParent();
  for (auto I = std::next(From->getIterator()), E = FB->end(); I != E; ++I) {
    if (Barriers.count(&*I))
      return false;  // cut — and this tail is the block's only continuation.
    if (&*I == To)
      return true;
  }
  SmallPtrSet<const BasicBlock *, 32> Seen;
  SmallVector<const BasicBlock *, 32> Work(succ_begin(FB), succ_end(FB));
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (!Seen.insert(B).second)
      continue;
    bool Cut = false;
    for (const Instruction &I : *B) {
      if (Barriers.count(&I)) {
        Cut = true;  // the record is re-established on this path.
        break;
      }
      if (&I == To)
        return true;  // reached the read with the record un-refreshed.
    }
    if (Cut)
      continue;
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

// The position-aware harmlessness test for ONE candidate staling gate `T`
// against the emission point `A`, given the RECORD the emission reads (`Seed`)
// and the full defended seed set.
//
// Leg 1 is `provablyBefore` verbatim — unchanged, and it alone decides every
// straight-line shape. Leg 2 is strictly ADDITIVE: it is consulted only when
// leg 1 already failed, i.e. only when `T` can reach `A` at all, which (given
// `A` dominates `T`) means a CFG cycle carries `T` back around. So NO shape
// that was accepted before this increment can be declined by it, and no shape
// it accepts was accepted before.
//
// WHY LEG 2 IS SOUND. Take any execution of `A` at trace time t_A; let t_S be
// the LAST execution of a barrier before it (the seed's own definition, or a
// phi that supersedes it — see below). Suppose some instance of `T` ran at
// t_S < t_T < t_A: that is exactly what "stale" means. The trace segment from
// t_T to t_A is a CFG path from `T` to `A`, so by `!reachesWithoutBarrier` it
// executes a barrier at some t' with t_T < t' < t_A — and t' > t_T > t_S
// contradicts t_S being the LAST one. So no `T` instance lies between the
// record's establishment and its read. ∎ The premise the proof rests on is
// "executing a barrier re-establishes the record", which is exactly what
// `phiTracksWire` checks for the phi barriers and what a gate/producer
// definition gives for free.
//
// THE SUPERSEDING PHI, and why the seed's own definition is not enough. The
// condition-provenance seed set (`ArmClassify::condProvenance`) walks BACKWARD
// through phis, so a loop-header phi's incomings — the PRE-LOOP mint and the
// body's last gate — are themselves seeds. Neither is re-executed on the back
// edge in the way the read needs; the PHI is. A phi `P` in the same seed set
// that lists `Seed` among its incomings, that dominates `A`, and that TRACKS
// THE WIRE therefore supersedes `Seed` on the path and joins the barrier set.
// Membership in `Seeds` is what ties `P` to the record being defended (an
// unrelated phi user of `Seed` proves nothing about `A`'s read), and the
// closure is iterated so a chain of routing phis resolves.
//
// A seed that is ITSELF a non-tracking phi gets NO barrier at all — not even
// its own definition — because the premise fails for it too.
//
// `RequireEmitDominance` (bd test_C_libtooling-3d8q) — see `WireWalk.h`. The
// dominance test below is a CONSERVATIVE PRECONDITION, not the proof: legs 1 and
// 2 each establish "no instance of `T` runs between the record's last
// establishment and this execution of `EmitPoint`" without it. Leg 2's proof, as
// written above, never cites `DT.dominates(EmitPoint, T)`; what it needs is that
// a barrier executes before `t_A`, which SSA gives for free (`Seed` is
// `EmitPoint`'s own operand, and every superseding phi is separately required to
// dominate `EmitPoint`). Every shipped caller passes `true` and is byte-unchanged.
// LEG 2 ALONE, split out for bd test_C_libtooling-3d8q's Rule-13 round-1 finding
// F-D1-1 so the ONE caller that must skip leg 1 can ask it without re-spelling it
// (Rule 14). `gateIsHarmless` below is byte-identical in behaviour to what it was
// before the split, and remains the only entry point every pre-existing caller
// reaches. Nothing else changed: the barrier set, the superseding-phi closure and
// the walk are moved verbatim.
bool recordBarrierCutsPath(const Instruction *EmitPoint, const CallInst *T,
                           const Value *Seed, ArrayRef<Value *> Seeds,
                           const DominatorTree &DT) {
  const auto *SeedDef = dyn_cast<Instruction>(Seed);
  if (!SeedDef)
    return false;  // no re-establishing definition — loop-invariant, decline.
  if (const auto *SeedPhi = dyn_cast<PHINode>(SeedDef))
    if (!phiTracksWire(SeedPhi))
      return false;  // the seed does not denote the live wire — decline.

  SmallPtrSet<const Instruction *, 4> Barriers;
  Barriers.insert(SeedDef);
  for (bool Grew = true; Grew;) {
    Grew = false;
    for (Value *S : Seeds) {
      auto *P = dyn_cast<PHINode>(S);
      if (!P || Barriers.count(P) || !DT.dominates(P, EmitPoint))
        continue;
      bool Supersedes = false;
      for (Value *In : P->incoming_values())
        if (auto *InI = dyn_cast<Instruction>(In))
          if (Barriers.count(InI))
            Supersedes = true;
      if (!Supersedes || !phiTracksWire(P))
        continue;
      Barriers.insert(P);
      Grew = true;
    }
  }
  return !reachesWithoutBarrier(T, EmitPoint, Barriers);
}

bool gateIsHarmless(const Instruction *EmitPoint, const CallInst *T,
                    const Value *Seed, ArrayRef<Value *> Seeds,
                    const DominatorTree &DT, bool RequireEmitDominance,
                    bool SeedIsCellRead = false) {
  if (RequireEmitDominance && !DT.dominates(EmitPoint, T))
    return false;
  // ⚠ LEG 1 IS MEANINGLESS WHEN `T == EmitPoint`, AND THAT IS AN LLVM FACT, NOT A
  // STYLE POINT (bd 3d8q, Rule-13 round-1 F-D1-1; owner ruling 2026-09-14).
  // LLVM 19's `isPotentiallyReachable(A, B)` opens
  //     if (A == B || A->comesBefore(B)) return true;
  // so with the two coinciding it answers TRUE **BY IDENTITY** — never because a
  // path exists — leg 1 never short-circuits, and leg 2 then refuses any seed
  // that is a non-wire-tracking φ or not an Instruction. MEASURED on binary
  // `33af6130`: calling THIS function as the stale-reader fence's self-gate test
  // declines 12 shipped Rule-13-cleared ACCEPT fixtures, ten of which hold a
  // reader that cannot execute twice at all. The self-gate question has its own
  // owner, `readerStalesItself` below, which asks leg 1 non-degenerately from
  // `std::next(R)` and then calls `recordBarrierCutsPath` — the SAME leg 2.
  // DO NOT "simplify" that back into a `gateIsHarmless(R, R, …)` call.
  if (!isPotentiallyReachable(T, EmitPoint, /*ExclusionSet=*/nullptr, &DT))
    return true;  // leg 1 — the pre-existing straight-line proof, unchanged.
  // A CELL read gets leg 1 only — re-running the seed's def does not
  // re-establish a record held in memory (`WireWalk.h`, `SeedIsCellRead`).
  if (SeedIsCellRead)
    return false;
  return recordBarrierCutsPath(EmitPoint, T, Seed, Seeds, DT);
}

// ─────────────────────────────────────────────────────────────────────────────
// LEG 1b OF `readerStalesItself` — "the CFG says `R` is in a cycle, but does `R`
// ITSELF run more than once?" (bd test_C_libtooling-3d8q, Rule-13 round-2
// finding F-D2-2.)
//
// WHY IT EXISTS. Leg 1 is a pure CFG question — `reachesWithoutBarrier(R, R, {})`
// — and a CFG cycle through `R`'s block is not the same fact as `R` executing
// twice. MEASURED, two well-formed programs the ORACLE compiled to the CORRECT
// one-rotation circuit and the round-2 binary declined:
//
//   for (i<3) { if (i == 0) { b = q; cq_theta(&b,.1); s += cq_measure(b); } else … }
//   first = 1; for (i<3) { if (first) { b = q; cq_theta(&b,.1); …; first = 0; } … }
//
// `q` is loop-INVARIANT, so leg 2 (`recordBarrierCutsPath`) correctly refuses —
// there is no per-trip barrier that re-establishes the record. But the reader
// runs EXACTLY ONCE, so there is no second instance to stale it and the chain
// reading and the re-preparation reading COINCIDE. The owner's 2026-09-14 ruling
// declined the in-loop invariant re-read because *"the source admits TWO
// realizable circuits and names neither"*; a once-executing reader admits
// exactly ONE, so the ruling's own rationale is absent and the decline is an
// over-decline this fence created (an over-decline is a DEFECT — owner ruling
// 2026-09-11, quoted in CLAUDE.md's Prime Directive).
//
// ⚠ THIS IS AN ACCEPT-DIRECTION WIDENING — the unforgivable direction if it is
// wrong — so every clause below is a REQUIREMENT and every unprovable answer is
// `false` (keep declining). It is reachable from EXACTLY ONE predicate
// (`readerStalesItself`, itself one caller: `recordStaleQuantumReaders`), and it
// is inert when the caller passes no `LoopInfo`/`ScalarEvolution`, so it cannot
// move `gateIsHarmless` or any of the walker's pre-existing callers.

// "What is the guard `C` worth when control arrives at header `H` from the LATCH
// `Lat`?" `std::nullopt` = NOT PROVABLE, which is always the decline direction.
//
// Two evaluators, because the two idioms `-O1` produces are not the same shape:
//   (i) a ONE-SHOT FLAG (`int first = 1; … first = 0;`) survives `-O1` as an
//       `i1` header φ with CONSTANT incomings (`[false, %pre], [true, %latch]`).
//       SCEV models no `i1` φ, so this is read off the φ directly.
//   (ii) a COMPARE ON THE INDUCTION VARIABLE (`if (i == 0)`) survives as
//       `icmp eq %iv, 0` on a header φ. Each operand is rewritten to the value
//       it takes ON THE LATCH EDGE (an `H`-φ becomes its latch incoming; a
//       loop-invariant operand is already that value) and the rewritten
//       predicate is put to ScalarEvolution, whose answer is UNIVERSAL over the
//       add-recurrence's iterations — exactly the quantifier this needs
//       ("false on EVERY arrival from the latch", not just on the second trip).
// Anything else — a non-`H` φ, a loop-variant non-φ operand, an `fcmp`, a
// non-integer operand, a `select`/`and`/`or` tree — is `nullopt` (L5: when you
// cannot bound something, say what is skipped rather than enumerating folds).
std::optional<bool> guardValueOnLatchEdge(const Value *C, const BasicBlock *H,
                                          const BasicBlock *Lat, const Loop *L,
                                          ScalarEvolution &SE) {
  if (const auto *K = dyn_cast<ConstantInt>(C))
    return K->isOne();
  if (const auto *P = dyn_cast<PHINode>(C)) {
    if (P->getParent() != H)
      return std::nullopt;
    if (const auto *K = dyn_cast<ConstantInt>(P->getIncomingValueForBlock(Lat)))
      return K->isOne();  // (i) the one-shot flag.
    return std::nullopt;
  }
  const auto *Cmp = dyn_cast<ICmpInst>(C);
  if (!Cmp)
    return std::nullopt;
  Value *Op[2];
  for (unsigned I = 0; I != 2; ++I) {
    Value *O = Cmp->getOperand(I);
    if (auto *P = dyn_cast<PHINode>(O)) {
      if (P->getParent() != H)
        return std::nullopt;  // a φ we cannot evaluate on the latch edge.
      O = P->getIncomingValueForBlock(Lat);
    } else if (!L->isLoopInvariant(O)) {
      return std::nullopt;  // loop-variant and not a header φ — unevaluable.
    }
    if (!O->getType()->isIntegerTy())
      return std::nullopt;  // SCEV is asked about integers only.
    Op[I] = O;
  }
  const SCEV *A = SE.getSCEV(Op[0]), *B = SE.getSCEV(Op[1]);
  ICmpInst::Predicate P = Cmp->getPredicate();
  if (SE.isKnownPredicate(P, A, B))
    return true;
  if (SE.isKnownPredicate(ICmpInst::getInversePredicate(P), A, B))
    return false;
  return std::nullopt;  // SCEV cannot decide — the `i < argc` control lands here.
}

// "Does `R` execute AT MOST ONCE per activation of its function?" — the SEMANTIC
// reading of leg 1, for a reader that sits in a guarded block inside a loop.
//
// THE PROOF, and every clause is load-bearing. Let `L` be `R`'s innermost loop,
// `H` its header, `PH` its preheader, `Lat` its latch, `B` the reader's block:
//
//   (C2) `L` is TOP-LEVEL. In a nest, "once per activation of the inner loop"
//        is once per trip of the outer one — not once.
//   (C3) `L` is in loop-simplify-ish form (a preheader and a single latch) and
//        `B != H` (the header runs every trip by construction).
//   (C4) `H` is entered on EXACTLY TWO EDGES, and they are `PH` and `Lat`. Both
//        the edge COUNT (`pred_size`, so a duplicated latch edge cannot pass as
//        one) and the edge SET are checked, because (C7) reads ONE incoming of a
//        φ and a second latch edge would carry a value it never saw.
//   (C5) `B`'s ONLY predecessor is `H` — so every execution of `R` is an `H`→`B`
//        edge, and there is no second door into the reader.
//   (C6) `H`'s terminator is a conditional `br` whose successors are DISTINCT
//        and exactly one of them is `B`. `Want` is the polarity that reaches `R`.
//   (C1) the guard is CLASSICAL (untainted). Under a tainted condition "how many
//        times does this block execute" has no classical answer at all.
//   (C7) THE SEMANTIC STEP: the guard provably evaluates to `!Want` on EVERY
//        arrival from `Lat`.
//   (C8a) `PH` is NOT REACHABLE FROM `R` — the loop cannot be re-entered after
//        the reader has run. Without this the loop could be exited and entered
//        again, and the second entry arrives at `H` from `PH`, where (C7) says
//        nothing. `isPotentiallyReachable` is conservative-TRUE (it bails true
//        past its scan limit), and TRUE here means DECLINE.
//
// Then: an execution of `R` needs an `H`→`B` edge (C5), which needs an arrival
// at `H` with the guard `== Want`; arrivals at `H` come from `PH` or `Lat` (C4);
// from `Lat` the guard is `!Want` (C7); so only a `PH` arrival can run `R`, and
// after one has, `PH` never executes again (C8a). Hence at most one `R`. ∎
//
//   (C8b) a STRUCTURAL BACKSTOP, deliberately kept although the proof above is
//         complete without it: every CFG cycle through `R` must cross `H`'s
//         terminator. The argument above leans on LoopInfo's contracts (a
//         preheader is outside the loop and is the loop's only non-latch entry);
//         this clause leans on nothing but the CFG, and it costs one bounded
//         walk. If the two ever disagree, the conjunction declines — which is
//         the direction this file is allowed to be wrong in.
bool readerRunsAtMostOncePerActivation(const Instruction *R, const LoopInfo &LI,
                                       ScalarEvolution &SE,
                                       const DominatorTree &DT,
                                       const TaintSet &Taint) {
  const BasicBlock *B = R->getParent();
  const Loop *L = LI.getLoopFor(B);
  if (!L || L->getParentLoop())
    return false;  // (C2) no loop (leg 1 owns it) / nested.
  const BasicBlock *H = L->getHeader();
  BasicBlock *PH = L->getLoopPreheader();
  BasicBlock *Lat = L->getLoopLatch();
  if (!PH || !Lat || B == H)
    return false;  // (C3)
  if (pred_size(H) != 2)
    return false;  // (C4) edge COUNT — a duplicated latch edge is refused here.
  {
    SmallPtrSet<const BasicBlock *, 4> P(pred_begin(H), pred_end(H));
    if (!P.count(PH) || !P.count(Lat))
      return false;  // (C4) edge SET.
  }
  if (B->getUniquePredecessor() != H)
    return false;  // (C5)
  const auto *Br = dyn_cast<BranchInst>(H->getTerminator());
  if (!Br || !Br->isConditional())
    return false;  // (C6)
  bool Want;
  if (Br->getSuccessor(0) == B && Br->getSuccessor(1) != B)
    Want = true;
  else if (Br->getSuccessor(1) == B && Br->getSuccessor(0) != B)
    Want = false;
  else
    return false;  // (C6) `B` is both successors, or neither.
  // (C1) THE GUARD MUST BE CLASSICAL. "How many times does this block execute?"
  // is a CLASSICAL question, and under a TAINTED condition it does not even have
  // a classical answer — the region is a control region, the arm runs in
  // superposition, and `detectControlRegions` (or the loop layer) owns it. Asking
  // ScalarEvolution about a quantum handle would be a Rule-3 wire crossing of the
  // exact family this project keeps hitting.
  //
  // ⚠ THE L1 RESIDUAL, STATED RATHER THAN LEFT AS AN INFERENCE. This runs at
  // ROUND-1 taint, and a condition can become tainted only at the round-2
  // fixpoint (derived from a 6.5/4.5 merge `%out`); the `Delta` re-ask is scoped
  // to readers whose RECORD operand grew, so such a reader is not re-asked. That
  // window CANNOT turn a decline into an accept, and the reason is independent of
  // this leg: a round-2-tainted condition on a LOOP HEADER's branch is a tainted
  // branch in a loop, which the loop layer refuses on its own (`control flow
  // inside a loop body under quantum control`, or the Q1 quantum-bounded-exit
  // decline for an exiting one). Granting here removes ONE reader from
  // `taint.StaleQuantumReaders`; it disarms no other fence. RETIREMENT TRIGGER:
  // the day a tainted loop-header branch LOWERS, re-derive this paragraph — the
  // argument is that it does not, not that the taint set is settled.
  if (Taint.Tainted.count(Br->getCondition()))
    return false;
  std::optional<bool> OnLatch =
      guardValueOnLatchEdge(Br->getCondition(), H, Lat, L, SE);
  if (!OnLatch || *OnLatch == Want)
    return false;  // (C7)
  if (isPotentiallyReachable(R, PH->getTerminator(), /*ExclusionSet=*/nullptr,
                             &DT, &LI))
    return false;  // (C8a) — conservative TRUE is the decline direction.
  SmallPtrSet<const Instruction *, 1> Cut;
  Cut.insert(Br);
  if (reachesWithoutBarrier(R, R, Cut))
    return false;  // (C8b)
  return true;
}

}  // namespace

// (bd test_C_libtooling-3d8q, Rule-13 round-1 finding F-D1-1) "Can `R`'s OWN
// PREVIOUS DYNAMIC INSTANCE stale the record `Seed` that `R` reads?"
//
// THE QUESTION EXISTS BECAUSE OF A MEASURED SILENT MISCOMPILE.
// `recordStaleQuantumReaders` grants the reader the `Covered` self-exemption —
// `c = a; cq_theta(&c,θ)` is an in-place Ry on the very rail it reads, so without it
// every well-formed chained rotation would decline against itself — and that
// exemption was UNCONDITIONAL. A loop body holding exactly ONE `cq_theta` on a
// loop-INVARIANT quantum name therefore compiled, emitting a stream
// BYTE-IDENTICAL to the self-assigned chain, which is a DIFFERENT, well-formed
// program.
//
// ⚠ IT CANNOT BE SPELLED AS `gateIsHarmless(R, R, …)`, AND THAT IS MEASURED, NOT
// ARGUED. Leg 1 asks `llvm::isPotentiallyReachable(T, EmitPoint)`, whose LLVM-19
// implementation opens with `if (A == B || A->comesBefore(B)) return true;` — so
// with `T == EmitPoint` it answers TRUE **BY IDENTITY**, never short-circuits,
// and every self-gate falls into leg 2. Leg 2 then refuses any seed that is a
// non-wire-tracking φ or is not an Instruction — correct when the gate really can
// reach the read, vacuous when the "path" was the identity. MEASURED on binary
// `33af6130`: that spelling turned **12 shipped Rule-13-cleared ACCEPT fixtures
// into declines** (`control_inplace_ry_inloop_two_exits`, the three
// `control_inplace_ry_stateprep_*`, both `control_*_lifted_phi_base`, the two
// `control_phase_kickback_mixed_*_leak_control`,
// `control_swap_accept_select_mergephi_rail_sdagger` and the three
// `lowering_*_live_record_*router_phi*`) plus two decline fixtures whose message
// moved. Every one of them has a reader that CANNOT EXECUTE TWICE.
//
// So the two legs are asked in the only order that is meaningful for the identity
// case, with the SHARED implementations (Rule 14 — no third spelling of either):
//   (1) `reachesWithoutBarrier(R, R, {})` — the exact, non-degenerate "is there a
//       CFG path from just after `R` back to `R`". It starts at `std::next(R)`,
//       so unlike `isPotentiallyReachable` it cannot match by identity. NO path
//       ⇒ `R` runs at most once ⇒ it cannot stale itself, whatever the seed is.
//   (1b) `readerRunsAtMostOncePerActivation` — the SEMANTIC reading of the very
//       same question, for the case leg 1's CFG test cannot see (bd 3d8q,
//       Rule-13 round-2 finding F-D2-2): a reader in a GUARDED block inside a
//       loop, where the guard is provably false on every arrival from the latch
//       (`if (i == 0) …`, and the `first`-flag idiom). The cycle is real, the
//       second EXECUTION is not. Skipped when the caller supplies no
//       `LoopInfo`/`ScalarEvolution`, so it is strictly additive. See the
//       definition in this file for the eight clauses and the proof.
//   (2) otherwise leg 2 verbatim (`recordBarrierCutsPath`): every back-edge path
//       from `R` to `R` must cross a barrier that RE-ESTABLISHES the record —
//       the seed's own definition, or a superseding wire-tracking φ. The
//       φ-carried in-loop chain (`cq_theta(&q,θ)`) passes here; the
//       loop-INVARIANT seed does not, which is the defect.
// `Seeds` is the one-element `{Seed}`, exactly what the walk this fence runs is
// seeded with, so the self-gate is asked the same question as every other gate.
bool readerStalesItself(const CallInst *R, Value *Seed,
                        const DominatorTree &DT, const LoopInfo *LI,
                        ScalarEvolution *SE, const TaintSet *Taint) {
  SmallPtrSet<const Instruction *, 1> NoBarrier;
  if (!reachesWithoutBarrier(R, R, NoBarrier))
    return false;  // (1) `R` cannot execute a second time at all — CFG.
  if (LI && SE && Taint &&
      readerRunsAtMostOncePerActivation(R, *LI, *SE, DT, *Taint))
    return false;  // (1b) — nor semantically, through a one-shot guard.
  return !recordBarrierCutsPath(R, R, Seed, ArrayRef<Value *>(Seed), DT);
}

bool phiTracksWire(const PHINode *P) {
  for (unsigned I = 0, E = P->getNumIncomingValues(); I != E; ++I) {
    const auto *V = dyn_cast<Instruction>(P->getIncomingValue(I));
    if (!V)
      return false;
    const Instruction *Term = P->getIncomingBlock(I)->getTerminator();
    if (V == Term)
      continue;  // degenerate; nothing can run between.
    if (thetaOnPathTo(V, Term))
      return false;
  }
  return true;
}

// THE ONE IMPLEMENTATION of the forward wire walk; its two public faces below
// differ only in whether they stop at the first staling gate or enumerate them
// all (Track A.1 — Rule 14: a second walk spelled separately is how two
// spellings of one relation eventually disagree). `Out != nullptr` is the
// enumerating mode: a staling gate is APPENDED and the walk continues, the gate
// itself pushed forward so the enumeration is transitive; `Covered` is the
// caller's already-ruled-on set, whose members are skipped as evidence with
// their forward wire still walked (see `WireWalk.h`).
static CallInst *walkNonDiagonalWireGates(
    ArrayRef<Value *> Seeds, bool CrossValueRouting,
    const Instruction *EmitPoint, const DominatorTree *DT,
    const TaintSet *Taint,
    const SmallPtrSetImpl<const CallInst *> *Covered,
    SmallVectorImpl<CallInst *> *Out, bool RequireEmitDominance,
    bool SeedIsCellRead = false) {
  // Seed closure + forward wire walk, PER SEED (test_C_libtooling-6j1, extended
  // for test_C_libtooling-6vk). A seed names a basis RECORD; the physical wire
  // carrying it is shared with the seed's whole ANCESTRY — rotation lowering
  // RAUWs a `cq_phi` (Rz, diagonal) AND a CHAINED `cq_theta` (Ry whose arg-0 is
  // itself a live quantum wire) and their arg-0 to the SAME i32 handle. So a
  // non-diagonal gate consuming a SIBLING SSA name of that ancestry
  // (`%q2 = cq_theta(%q, ·)` while the seed reads `%q` or a `cq_phi`/chained
  // theta over `%q`) is an in-place Ry on the seed's own wire that a forward-
  // only walk from the seed can never reach (it follows USER edges only).
  //
  // Close every seed BACKWARD through `cq_phi` arg-0 hops AND chained-`cq_theta`
  // arg-0 hops to the wire origin, recording the ON-ANCESTRY gates (the seed and
  // every gate that BUILT its record). That backward chain is exactly the gates
  // that PRODUCE the seed's record — they precede it on every trace and can
  // never stale it — so they are EXEMPT from the forward staling-gate frontier;
  // only an OFF-ancestry sibling theta (a second user of a shared parent handle,
  // NOT on the seed's own arg-0 chain) is stale evidence. This is the 6vk fix
  // sketch: the over-decline the previous never-cross-theta stop avoided came
  // ONLY from flagging the producing theta, which the exemption now prevents
  // (accept boundary pinned by lowering_stale_record_add_after_phi.ll,
  // lowering_stale_record_add_before_theta.ll,
  // lowering_stale_record_chained_theta_onancestry.ll). A SOURCE theta's arg-0
  // is the classical init (not a quantum wire), so the closure stops there and
  // never reaches into classical scaffolding.
  //
  // The exempt set is per the ORIGINAL seed's own ancestry, so each seed is
  // walked INDEPENDENTLY: a theta off-ancestry of one seed but on-ancestry of
  // another must still be flagged for the first (it stales that seed's record),
  // which a shared/unioned exempt set would unsoundly hide. Termination needs no
  // visited set on the backward closure: arg-0 def edges strictly ascend the
  // dominance order for reachable (tainted) code, so the chain cannot cycle —
  // the same argument the pre-hoist ArmClassify manual closure relied on, now
  // also covering the chained-theta arg-0 edge.
  for (Value *Seed : Seeds) {
    SmallVector<Value *, 16> Work;
    SmallPtrSet<Value *, 16> Exempt;  // on-ancestry producers — never stale the record
    for (Value *V = Seed;;) {
      Work.push_back(V);
      Exempt.insert(V);
      auto *CI = dyn_cast<CallInst>(V);
      if (!CI || CI->arg_size() < 1)
        break;  // a non-call ancestor — the wire origin / record boundary.
      Value *Arg0 = CI->getArgOperand(0);
      if (isCallToPrefix(CI, "cq_phi_")) {
        V = Arg0;  // diagonal Rz hop — same wire, same basis record.
        continue;
      }
      // A CHAINED theta (arg-0 is itself a `cq_theta`/`cq_phi` quantum wire) is
      // an in-place Ry whose arg-0 shares the wire; cross it to reach the parent
      // record. A SOURCE theta (arg-0 is the classical init) is the wire origin.
      // F-1b-1 (bd 3qlq.4): with `Taint`, cross the arg-0 edge of ANY chained
      // theta — the relation `lowerRotations` builds the rail from — so a
      // SIBLING in-place Ry on a template/compare/phi parent is on the closure.
      if (isCallToPrefix(CI, "cq_theta_") &&
          (isCallToPrefix(Arg0, "cq_theta_") || isCallToPrefix(Arg0, "cq_phi_") ||
           (Taint && Taint->Tainted.count(Arg0)))) {
        V = Arg0;
        continue;
      }
      break;  // wire origin (source theta / template result / argument).
    }
    SmallPtrSet<Value *, 16> Seen;
    while (!Work.empty()) {
      Value *V = Work.pop_back_val();
      if (!Seen.insert(V).second)
        continue;
      for (User *U : V->users()) {
        if (CrossValueRouting) {
          // PHINodes and select VALUE operands route the same physical handle
          // onward (after rotation lowering's RAUW they are i32-handle muxes),
          // so a theta behind them is still an in-place gate on a wire the
          // seed may denote. A select's CONDITION use is not a routing edge.
          if (auto *P = dyn_cast<PHINode>(U)) {
            Work.push_back(P);
            continue;
          }
          if (auto *Sel = dyn_cast<SelectInst>(U)) {
            if (V != Sel->getCondition())
              Work.push_back(Sel);
            continue;
          }
        }
        // AN IN-PLACE VALUE SELF-UPDATE (`q += c`, issue dtzb) IS NOT CROSSED
        // HERE, and that is a MEASURED decision, not an oversight (bd 8h7d.5
        // Rule-13 round 1 raised it as a contributing gap; the measurement
        // answered it the other way). Crossing it would put every theta behind
        // an `add` back on this seed's wire. That is WRONG whenever the add
        // lowers OUT of place — the overwhelmingly common case here, because
        // `declineStaleRecordOps` runs BEFORE `lowerLoops`, so `InPlaceRailOps`
        // is empty and the M-C fence has not classified anything yet: an
        // out-of-place `cq_template_add_<W>_hl` MINTS a fresh rail, and a later
        // rotation of THAT handle touches nothing of the parent's wire.
        //
        // And when the add IS in place, the read is fenced by an owner that can
        // see it: straight-line by the M-C fence's G6 ("no data use AFTER the
        // site" — so the stale reader cannot exist), and on a loop's rail by
        // `LoopLowering::staleRailRecordRead`, which counts every in-place op on
        // the RAIL (chain and forward extension) as a gate, so it sees a theta
        // behind an add without walking through it. ⚠ CORRECTED (bd
        // test_C_libtooling-r2j3.13): that fence ALSO has to ask the add as a
        // READ. Until r2j3.13 round 1 skipped every op its fixpoint absorbed, so
        // a post-loop `add %root, 5` on a pre-loop alias (an add-only loop, no Ry
        // on this wire for `declineStaleRecordOps` to find) was marked in place
        // and read the moved register unasked: a silent miscompile on main.
        // Round 1 now skips only its peeled chains, as round 2 always did.
        //
        // MEASURED 2026-08-30 with the crossing spliced in: ZERO new declines
        // across the 53-program Rule-13 probe corpus (the two programs it
        // touched, x3_stale_c and x4_round1_stale, already decline — only the
        // message changed), and ONE regression —
        // control_swap_inloop_railop_inplace.ll, i.e. the shipped customer slice
        // slice_control_grover_loop_offset, whose PRE-HEADER `q += cq_off` puts
        // the loop's own S-dagger Ry behind an add and would be read as a
        // condition staler. Pure cost. Do not re-add it without a probe that
        // shows a program it catches and nothing else does.
        auto *CI = dyn_cast<CallInst>(U);
        if (!CI || CI->arg_size() < 1 || CI->getArgOperand(0) != V)
          continue;  // not an in-place gate on this wire (angle/data uses, br).
        if (isCallToPrefix(CI, "cq_theta_")) {
          // An ON-ancestry producing theta builds the seed's record (it is on
          // the seed's own backward arg-0 chain); it never stales the record,
          // and it is already on `Work`, so its own forward wire is walked from
          // there. Skip it as a staling candidate.
          if (Exempt.count(CI))
            continue;
          // (Track A.1, F-A1-1) A gate the CALLER has already ruled on is not
          // this walk's evidence — but it is still a wire, so keep walking
          // FORWARD from it: the exemption is of the named gate, never of what
          // lies behind it. Deliberately tested BEFORE the harmlessness proof:
          // `Covered` is an identity question and needs neither positions nor a
          // tree, and answering it first keeps the two walks that form the set
          // difference comparable.
          if (Covered && Covered->count(CI)) {
            Work.push_back(CI);
            continue;
          }
          // An OFF-ancestry sibling Ry on a shared wire IS stale evidence.
          // Position-free mode (`EmitPoint` null): decline unconditionally.
          // Position-aware mode: harmless iff PROVABLY after every execution of
          // `EmitPoint` —
          //   * `DT->dominates(EmitPoint, T)`: every path reaching T already
          //     executed the template (first-execution order), and
          //   * `!isPotentiallyReachable(T, EmitPoint)`: once T fired, the
          //     template never re-executes (a loop back-edge would otherwise
          //     replay the template against the post-Ry wire on iteration 2
          //     while its SSA operand still denotes the pre-Ry record).
          // Both proven ⇒ every template instance precedes every Ry instance on
          // every trace — harmless. Unproven ⇒ return T (decline; over-decline
          // is safe, Prime Directive).
          // Both halves are `provablyBefore(EmitPoint, T)` — the shared
          // spelling this header exports (Rule 14); it was inlined here and
          // re-derived in RotationLowering until bd 6uqc Inc 2a needed a third
          // caller.
          // The RECORD this walk defends is `Seed` — the emission's own
          // operand — so `Seed` is the barrier whose re-execution refreshes it
          // (bd test_C_libtooling-8h7d.5). Per-seed, never per-closure: an
          // ancestry member is a PRODUCER of the record, not the record.
          if (EmitPoint && DT &&
              gateIsHarmless(EmitPoint, CI, Seed, Seeds, *DT,
                             RequireEmitDominance, SeedIsCellRead))
            continue;  // provably post-emission on every trace — harmless.
          if (Out) {
            // ENUMERATING MODE: record it and keep going, walking THROUGH it so
            // a gate reachable only behind another one is enumerated too (the
            // two sets of the difference must be built by the same rule).
            Out->push_back(CI);
            Work.push_back(CI);
            continue;
          }
          return CI;
        }
        if (isCallToPrefix(CI, "cq_phi_"))
          Work.push_back(CI);  // diagonal — same wire, keep walking forward.
      }
    }
  }
  return nullptr;
}

CallInst *findNonDiagonalWireGate(
    ArrayRef<Value *> Seeds, bool CrossValueRouting,
    const Instruction *EmitPoint, const DominatorTree *DT,
    const TaintSet *Taint,
    const SmallPtrSetImpl<const CallInst *> *Covered,
    bool RequireEmitDominance, bool SeedIsCellRead) {
  return walkNonDiagonalWireGates(Seeds, CrossValueRouting, EmitPoint, DT,
                                  Taint, Covered, /*Out=*/nullptr,
                                  RequireEmitDominance, SeedIsCellRead);
}

void collectNonDiagonalWireGates(ArrayRef<Value *> Seeds,
                                 bool CrossValueRouting,
                                 const Instruction *EmitPoint,
                                 const DominatorTree *DT, const TaintSet *Taint,
                                 SmallVectorImpl<CallInst *> &Out,
                                 bool RequireEmitDominance) {
  walkNonDiagonalWireGates(Seeds, CrossValueRouting, EmitPoint, DT, Taint,
                           /*Covered=*/nullptr, &Out, RequireEmitDominance);
}

bool provablyBefore(const Instruction *A, const Instruction *B,
                    const DominatorTree &DT) {
  return DT.dominates(A, B) &&
         !isPotentiallyReachable(B, A, /*ExclusionSet=*/nullptr, &DT);
}

bool provablyBeforePerActivation(const Instruction *A, const Instruction *B,
                                 const Instruction *Barrier,
                                 const DominatorTree &DT) {
  if (!DT.dominates(A, B))
    return false;
  if (!isPotentiallyReachable(B, A, /*ExclusionSet=*/nullptr, &DT))
    return true;  // the plain proof — unchanged.
  if (!Barrier)
    return false;
  // `Barrier == A` IS A VACUOUS PROOF, and it silently DELETED half of one (bd
  // test_C_libtooling-8h7d.5, Rule-13 round 1, finding P1). `reachesWithoutBarrier`
  // tests `Barriers.count(&I)` BEFORE `&I == To`, so with `To == A == Barrier` the
  // walk CUTS at the very instruction it is trying to reach and can never return
  // true — the whole call degenerates to `DT.dominates(A, B)`, i.e. the
  // reachability half of `provablyBefore` is thrown away with no diagnostic and
  // no test.
  //
  // And fixing the endpoint order would not rescue it: every path from `B` back
  // to `A` ends AT `A`, so "re-executes `A` on the way" is trivially satisfiable
  // and the disjunct proves nothing about this activation. The header's contract
  // is the rule — the barrier must be the instruction whose EXECUTION
  // re-establishes the premise — and `A`, the premise's own subject, never is.
  // Refuse it outright rather than return an answer that reads like a proof.
  // (`Barrier == B` is a DIFFERENT and sound configuration and is deliberately
  // NOT refused: `Uncomputation.cpp`'s LEFT disjunct asks
  // `provablyBeforePerActivation(M, First, First)`, where the walk runs from
  // `First` forward looking for `M` and cuts only on RE-entering `First` — the
  // genuine "M belongs to a later activation" question.)
  assert(Barrier != A && "per-activation barrier must not be the subject A");
  if (Barrier == A)
    return false;
  SmallPtrSet<const Instruction *, 2> Barriers;
  Barriers.insert(Barrier);
  return !reachesWithoutBarrier(B, A, Barriers);
}

bool everyPathReExecutes(const Instruction *From, const Instruction *To,
                         const Instruction *Barrier) {
  SmallPtrSet<const Instruction *, 2> Barriers;
  Barriers.insert(Barrier);
  return !reachesWithoutBarrier(From, To, Barriers);
}

bool intervalAlternates(const Instruction *Open, const Instruction *Close) {
  // The SAME walk `provablyBeforePerActivation` uses, with both endpoints set to
  // `Close` — asked here rather than re-spelt (Rule 14). `reachesWithoutBarrier`
  // starts at `std::next(Close)`, so this is a genuine "can `Close` come round
  // again" question and not a degenerate self-match.
  return everyPathReExecutes(Close, Close, Open);
}

}  // namespace cq
