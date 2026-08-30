// WireWalk.cpp — Shared forward in-place-gate wire walk. See WireWalk.h for
// the contract and the two consumer modes (ArmClassify position-free;
// OpcodeLowering position-aware). Hoisted from
// ArmClassify::wireGainsNonDiagonalGate (test_C_libtooling-ee5) so the
// straight-line stale-record guard (test_C_libtooling-uzb) reuses the same
// core instead of forking it (Rule 14).

#include "WireWalk.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <cassert>
#include <iterator>

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
    if (isCallToPrefix(CI, "cq_phi_")) {
      V = Arg0;
      continue;
    }
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
//     q = cq_theta(q0,g); z = cq_theta(0,.125); for (…) { if (q>5) … }
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
//            Reachable from C (`for (…) { d = q + 1; cq_theta(q, t); }`), and
//            granting it the barrier would ACCEPT the classic iteration-2 stale
//            read. That is why this predicate exists at all.
//
// The test: for every incoming (`V`, `B`), no `cq_theta` runs between `V` and
// the `B → P` edge. Then `P`'s value at every execution equals the wire, so
// re-executing `P` re-establishes the record — the premise `gateIsHarmless`
// leg 2 needs. A non-instruction incoming (a constant / argument) means the
// value at that edge is not a wire record at all: refuse.
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
bool gateIsHarmless(const Instruction *EmitPoint, const CallInst *T,
                    const Value *Seed, ArrayRef<Value *> Seeds,
                    const DominatorTree &DT) {
  if (!DT.dominates(EmitPoint, T))
    return false;
  if (!isPotentiallyReachable(T, EmitPoint, /*ExclusionSet=*/nullptr, &DT))
    return true;  // leg 1 — the pre-existing straight-line proof, unchanged.
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

}  // namespace

CallInst *findNonDiagonalWireGate(ArrayRef<Value *> Seeds,
                                  bool CrossValueRouting,
                                  const Instruction *EmitPoint,
                                  const DominatorTree *DT) {
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
  // (accept boundary pinned by lowering_stale_record_alias_producer.ll,
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
      if (isCallToPrefix(CI, "cq_theta_") &&
          (isCallToPrefix(Arg0, "cq_theta_") || isCallToPrefix(Arg0, "cq_phi_"))) {
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
        // And when the add IS in place, the read is already fenced by an owner
        // that can see it: straight-line by the M-C fence's G6 ("no data use
        // AFTER the site" — so the stale reader cannot exist), and inside a loop
        // by `LoopLowering::staleRailRecordRead`, which reasons over the RAIL
        // CHAIN rather than over user edges and therefore sees a theta behind an
        // add without needing to walk through it.
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
              gateIsHarmless(EmitPoint, CI, Seed, Seeds, *DT))
            continue;  // provably post-emission on every trace — harmless.
          return CI;
        }
        if (isCallToPrefix(CI, "cq_phi_"))
          Work.push_back(CI);  // diagonal — same wire, keep walking forward.
      }
    }
  }
  return nullptr;
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
