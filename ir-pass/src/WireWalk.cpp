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

// Any `cq_theta_*` call — SOURCE or CHAINED. Deliberately coarser than the
// tainted-arg-0 test the rest of the pass uses: this predicate only ever
// WITHHOLDS a new accept (it gates the barrier below), never grants one, so
// over-matching costs a decline and nothing else — and it keeps this TU free of
// a `TaintSet` dependency it has never had.
bool isAnyThetaCall(const Instruction *I) {
  return isCallToPrefix(I, "cq_theta_");
}

// Does some execution path from `V` (exclusive) to `Target` (a terminator that
// `V` dominates) run a `cq_theta`? Paths that re-execute `V` are CUT — going
// around a back edge re-binds `V`, so what happens on the far side belongs to
// the next activation, not to this one.
//
// Exact block walk, each block scanned at most once. Blocks are entered only at
// the TOP, so re-entering `V`'s own block always re-executes `V` before
// anything after it (`V` dominates `Target`, hence precedes it in that block) —
// which is why that case is a plain cut and not a re-scan.
bool thetaOnPathTo(const Instruction *V, const Instruction *Target) {
  const BasicBlock *VB = V->getParent();
  for (auto I = std::next(V->getIterator()), E = VB->end(); I != E; ++I) {
    if (&*I == Target)
      return false;  // reached the edge with the wire quiet.
    if (isAnyThetaCall(&*I))
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
      if (isAnyThetaCall(&I))
        return true;
    }
    if (Reached)
      continue;  // this path ended at the edge; do not walk past it.
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
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
  SmallPtrSet<const Instruction *, 2> Barriers;
  Barriers.insert(Barrier);
  return !reachesWithoutBarrier(B, A, Barriers);
}

}  // namespace cq
