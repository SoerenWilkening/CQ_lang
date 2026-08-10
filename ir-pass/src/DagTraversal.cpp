// DagTraversal.cpp — see header. Whole-DAG recovery (WI-4) via a visited-set
// worklist: backward from the terminals through every tainted operand (QQ = two
// parents), collecting in-place rotations + reassigning template producers, then
// the closure / measure / escape analysis over every recovered rail.

#include "DagTraversal.h"

#include "ChainWalk.h"          // isInPlaceGateOn / isAllocMint / isMeasureSink
#include "TaintPropagation.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"

using namespace llvm;

namespace cq {

namespace {

// A `cq_invert_*` region call — Phase-7 manual inversion owns the handle (PRD
// §2.6); mirrors `FreePoint::isRecognizedEscapeUser`.
bool isInvertEscape(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cq_invert_");
}

// A reassigning template producer (`cq_template_<op>_<W>…`) — its result is a
// fresh rail the DAG must zero and free. (Rotations are in-place; allocs are
// roots; controlled forms / `_inv`/`_unc` twins are not forward data producers.)
bool isTemplateProducer(const CallInst *G) {
  const Function *Callee = G->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  // Phase 7.5: a QRAM load result is also a fresh rail the DAG must zero (via its
  // `_unc`) and free — and, crucially, must be CLOSURE-CHECKED here so a load whose
  // value fans out to a consumer OUTSIDE the recovered DAG marks the DAG NotClosed
  // (a Rule-8 safe-leak), never a use-after-free of a freed cell-copy.
  if (N.starts_with("cqrt_qram_load_") && !N.ends_with("_unc"))
    return true;
  return N.starts_with("cq_template_") && !N.contains("_controlled") &&
         !N.ends_with("_inv") && !N.ends_with("_unc");
}

// bd 261j(a) — does gate `G` keep its rail a BASIS PERMUTATION OF LIVE CONDITIONS,
// so that re-emitting the adjoint still returns the rail to |0⟩ even though the
// rail was RECORDED into a carrier the reversal never touches?
//
// THE INVARIANT (owner ruling 2026-08-10). Let R be a rail, W its forward chain,
// cond(W) the non-R SSA operands W reads, and C a record of R taken by a kept
// carrier. Freeing R is Rule-6-legal iff (a) R starts at |0⟩; (b) on the reachable
// subspace W(|0⟩_R ⊗ |c⟩_cond) = |g(c)⟩_R ⊗ |c⟩_cond — W is a basis permutation of
// cond(W) up to a label-diagonal phase; (c) the emitted reversal is W†; and (d)
// every register in cond(W) still holds its forward value when W† fires. Then
// W† C W (|0⟩_R ⊗ |ψ⟩) = |0⟩_R ⊗ (D ^= g(cond)) for ARBITRARILY many kept records.
//
// (d) IS DELICATE — it is the clause that made the first implementation of this
// ruling a silent miscompile, so read it precisely. "Still holds its forward
// value" means the value the register held WHEN THE FORWARD GATE RAN, not its
// value at the end of the forward stream. Those differ whenever a later
// non-diagonal gate writes the same register. Reverse program order delivers (d)
// for free — but ONLY because `emitDagReversal` adjoints EVERY recovered gate,
// including the gates of frozen rails; the freeze suppresses `cqrt_free`, never
// an adjoint. Any future change that skips an adjoint breaks (d) for every
// surviving reader of that register (MEASURED: see the Uncomputation.cpp note).
//
// DECISIVE COROLLARY: cond(W) = ∅ ⇒ R is freeable only if W is trivial on |0⟩.
// `cqrt_ry_<W>(H, θ)` has cond = ∅ (its only other operand is a CLASSICAL angle,
// Rule 3) and is NOT trivial on |0⟩ — it is the gate that mints the superposition.
// That, not any "redundancy" argument, is why the shipped slice_io free was a
// hidden measurement: `Ry† (CNOT-onto-kept-tape) Ry |0⟩` is not |0⟩.
//
// FAILS CLOSED: anything not named here — including anything a future increment
// adds to the recovered gate set — is treated as NOT basis-preserving, which
// freezes the rail (a leak, the safe direction). `cqrt_x` is deliberately ABSENT:
// `isInPlaceGateOn` never recovers it today, so an entry would be an inert
// unverified claim; if it is ever recovered it must fail closed here.
//
// APPLIED PER GATE, NEVER TO THE COMPOSED CHAIN — deliberate, and it over-freezes.
// A rail whose gate sequence happens to COMPOSE to a basis permutation (the
// textbook case is `ry(θ)` then `ry(-θ)`, i.e. the identity) still freezes, because
// each factor is judged alone. Recognizing cancellation would mean reasoning about
// products of rotations, which is exactly the kind of "it must cancel" argument
// this ticket's history says not to trust; the cost is a leaked rail on a shape no
// emitter produces, and the alternative risks an under-freeze.
bool preservesBasisUnderRecord(const CallInst *G) {
  // A reassigning producer — `cq_template_*` (out = f(parents), the embedded
  // permutation) and `cqrt_qram_load_<W>` (a cell copy conditioned on arr/idx).
  // Both are permutations of their PARENTS, so (b) holds. (d) holds because
  // `emitDagReversal` adjoints every recovered gate in reverse program order,
  // which restores each parent to its producer-time value before this gate's
  // `_unc` fires. Say it that way and not "the DAG keeps the parents live": LIVE
  // is not enough, they must be at the RIGHT value, and an earlier draft of this
  // freeze falsified exactly that by skipping frozen rails' adjoints.
  // NOTE the spelling matters: `railOf` returns the gate ITSELF for a producer,
  // so writing this whitelist as {rz, qram_store} with producers closed would
  // freeze every template rail and collapse into the blunt DAG-global rule.
  if (isTemplateProducer(G))
    return true;
  const Function *Callee = G->getCalledFunction();
  StringRef N = Callee ? Callee->getName() : StringRef();
  // Rz is DIAGONAL: trivial on |0⟩ (condition (b) with g = identity), and the
  // label-diagonal phase it applies commutes with, and cancels against, a
  // basis-label record.
  if (N.starts_with("cqrt_rz_"))
    return true;
  // A QRAM store is a permutation of its array conditioned on idx/val (and, in
  // the guarded form, a flag) — all borrowed parents, restored to their
  // producer-time values by the same every-gate reverse-play as above (NOT merely
  // "kept live"; a rotated index reaching `cqrt_qram_store_<W>_unc` pops the wrong
  // cell, which is what the skip-the-adjoint draft actually did).
  if (N.starts_with("cqrt_qram_store_") && !N.ends_with("_unc"))
    return true;
  return false;  // `cqrt_ry_<W>` lands here — and so does anything new.
}

}  // namespace

DataDag recoverDataDag(ArrayRef<Value *> Terminals, const TaintSet &taint,
                       DominatorTree &DT) {
  DataDag D;

  // 1. Backward worklist DAG recovery. Each handle contributes its in-place
  //    rotations as gates; a template-produced handle is itself a gate and hops
  //    to ALL its tainted operands (QQ ⇒ two parents); an alloc/non-call handle
  //    is a root. A visited-set dedups shared prefixes (fan-out reconvergence).
  SmallVector<Value *, 16> Work(Terminals.begin(), Terminals.end());
  SmallPtrSet<Value *, 16> VisitedHandles;
  SmallPtrSet<CallInst *, 16> SeenGates;
  // The DAG's ANCESTOR edges as (child, parent) pairs. The walk below already
  // computes them — it just did not retain them. Step 3b closes the "recorded
  // into a kept carrier" seed BACKWARD over these edges (bd 261j(a)).
  SmallVector<std::pair<Value *, Value *>, 32> AncEdges;
  while (!Work.empty()) {
    Value *H = Work.pop_back_val();
    if (!VisitedHandles.insert(H).second)
      continue;
    for (User *U : H->users())
      if (auto *G = dyn_cast<CallInst>(U))
        if (isInPlaceGateOn(G, H) && SeenGates.insert(G).second) {
          D.Calls.push_back(G);
          // A multi-input in-place gate — a Phase 7.5 QRAM store
          // `cqrt_qram_store_<W>(arr=H, idx, val)` — carries additional TAINTED
          // borrowed operands (idx, val) that are its parents in the DAG. Enqueue
          // them so their producers (the index rotation; a tainted store value's
          // chain) are recovered and reverse AFTER this gate's `_unc` (SSA
          // dominance: the gate `_unc` reads them, so it is emitted before their
          // own adjoints/frees). A rotation's only non-handle operand is a
          // classical angle (untainted), so this loop is a no-op for rotations.
          for (Value *Op : G->args())
            if (Op != H && taint.Tainted.count(Op)) {
              Work.push_back(Op);
              AncEdges.emplace_back(H, Op);  // Op is a parent of H's rail
            }
        }
    auto *CI = dyn_cast<CallInst>(H);
    if (CI && !isAllocMint(CI)) {
      if (SeenGates.insert(CI).second)
        D.Calls.push_back(CI);
      for (Value *Op : CI->args())
        if (taint.Tainted.count(Op)) {
          Work.push_back(Op);
          AncEdges.emplace_back(CI, Op);  // Op is a parent of the produced rail
        }
    } else {
      D.Roots.push_back(H);
    }
  }

  // 2. Program order (same block ⇒ position, else dominance, BirthOrder tie-break
  //    only — FileCheck-stable). Because every gate dominates the single
  //    insertion point (the driver's dominance check), dominance is a TOTAL order
  //    here, so reverse program order is an unambiguous reverse-topological order.
  llvm::stable_sort(D.Calls, [&](CallInst *A, CallInst *B) {
    if (A == B)
      return false;
    if (A->getParent() == B->getParent())
      return A->comesBefore(B);
    if (DT.dominates(A, B))
      return true;
    if (DT.dominates(B, A))
      return false;
    return taint.BirthOrder.lookup(A) < taint.BirthOrder.lookup(B);
  });

  // 3. Closure / measure / escape analysis over every RAIL (a root or a template
  //    producer's result — the values the DAG zeroes and frees; rotations mint no
  //    rail). Every forward consumer of a rail must itself be a recovered gate;
  //    anything else means the rail is owned outside the DAG.
  //    EXPORTED as `D.Rails` (bd uow0 Rule-13 round 2): the driver frees by
  //    `railOf(G)` over `D.Calls`, which is NOT the same set, and a value in the
  //    difference would be freed carrying none of the verdicts this scan sets.
  SmallPtrSet<Value *, 16> &Rails = D.Rails;
  for (Value *R : D.Roots)
    Rails.insert(R);
  for (CallInst *G : D.Calls)
    if (isTemplateProducer(G))
      Rails.insert(G);

  for (Value *R : Rails) {
    // A Phase-4-owned control rail reached as a DAG ancestor (e.g. `x = merged +
    // 1` off a merge OUT-rail) is owned by Phase 4 (DD-4) — never reverse/free it.
    // Explicit, not incidental: the closure scan below would also catch it via the
    // rail's controlled-copy users, but ControlOwnedRails is the load-bearing
    // image (PRD §2.2) so the protection does not rest on that coincidence.
    if (taint.ControlOwnedRails.count(R)) {
      D.NotClosed = true;
      continue;
    }
    // A kept I/O output rail (7.6, PRD-7.6 §2.5) — never reverse/free it. The
    // `out_handle` of a `cqrt_tape_write_<W>` is not a data producer, so it is
    // never a DAG root or template-producer rail here, but the explicit
    // OutputRails subtraction is the SAME load-bearing discipline as
    // ControlOwnedRails above (do NOT rest on that incidental exclusion).
    if (taint.OutputRails.count(R)) {
      D.NotClosed = true;
      continue;
    }
    // A parked abort/exit graveyard rail (7.2 Inc 3, plan §2-A) reached as a DAG
    // ancestor — kept frozen + entangled, never reverse-played/freed (Rule 6).
    // Missing THIS site (subtracting only at terminal selection) would let a
    // graveyard rail reached as an upstream operand be reversed/freed = a hidden
    // collapse of the parked superposition; the explicit image is load-bearing
    // (the SAME discipline as ControlOwnedRails / OutputRails above — do NOT rest
    // on the closure scan's incidental controlled-cswap-user exclusion).
    if (taint.GraveyardRails.count(R)) {
      D.NotClosed = true;
      continue;
    }
    for (User *U : R->users()) {
      if (auto *CU = dyn_cast<CallInst>(U)) {
        if (isInPlaceGateOn(CU, R))
          continue;  // R's own in-place rotation — part of R's chain
        if (isMeasureSink(CU)) {
          D.MeasuredUpstream = true;
          if (!D.UpstreamMeasure)
            D.UpstreamMeasure = CU;
          continue;
        }
        if (isOutputSink(CU)) {
          // bd 8gi5(3)/e4zs: a preserving READ is still a use. Record it so the
          // driver can place the reversal after it — `computeFreePoint` only sees
          // the TERMINAL's users, so when R is an upstream rail this is the ONLY
          // place the sink is visible to the ordering decision.
          D.PreservingSinks.push_back(CU);
          continue;  // 7.6: a `cqrt_tape_write_<W>` SINK on R — it READS R (a
                     // CNOT-class copy; the kept out_handle is an OutputRails
                     // member, subtracted above), so it is NOT a forward data
                     // consumer and does NOT mark the DAG NotClosed, and unlike a
                     // measure it is NOT a collapse (no MeasuredUpstream).
                     //
                     // It DOES, however, correlate R with a register the reversal
                     // never touches. "R's lineage then uncomputes normally
                     // (Bennett)" — what this comment used to claim — is FALSE
                     // whenever R's own chain is not a basis permutation of live
                     // conditions (bd 261j(a), owner ruling 2026-08-10: an Ry rail
                     // recorded onto a kept tape and then freed is a hidden
                     // measurement). Step 3b below decides that per rail; the
                     // `continue` here only settles CLOSURE, never freeability.
        }
        if (isCopyOutSink(CU, R)) {
          D.PreservingSinks.push_back(CU);  // bd 8gi5(3): as above, the ordering
                                            // half — a preserving read is a use.
          continue;  // sxuk: a method-B copy-out READS R as src (a CNOT-class copy)
                     // — like a tape write a benign source-preserving sink, NOT a
                     // forward data consumer, so it does NOT mark the DAG
                     // NotClosed; the copy DESTINATION is the kept escaped/measured
                     // carrier and is never recovered as a gate.
                     //
                     // Same narrowing as the tape sink above: this settles CLOSURE
                     // only. It is NOT a `recordsIntoKeptCarrier` for step 3b — bd
                     // 8gi5 censused this surface and found no live instance (the
                     // only copy src the spine reverses is a `cqrt_qram_load_<W>`
                     // result, a permutation of live arr/idx; the sxuk index roots
                     // are measurement-immune by QramLowering.cpp:1749-1757), and
                     // extending the freeze here is that ticket's call, not this
                     // one's.
        }
        if (isInvertEscape(CU)) {
          D.Escaped = true;
          continue;
        }
        if (SeenGates.count(CU))
          continue;  // a covered DAG gate — the legit fan-out / QQ consumer
        D.NotClosed = true;  // controlled copy/cswap, free, or out-of-DAG gate
        continue;
      }
      if (isa<ReturnInst>(U)) {
        D.Escaped = true;  // a returned rail — the caller owns its reversal
        continue;
      }
      if (auto *Phi = dyn_cast<PHINode>(U))
        if (Phi->use_empty())
          continue;  // a benign both-arm live-range merge (dead result)
      D.NotClosed = true;  // any other user we cannot prove reversible
    }
  }

  // 3b. RECORD FREEZE (bd 261j(a), owner ruling 2026-08-10). A rail RECORDED into
  //     a carrier the reversal never touches (a kept output tape) stays CORRELATED
  //     with it, so re-emitting its adjoint returns it to |0⟩ only if its forward
  //     chain is a basis permutation of conditions that are still live —
  //     `preservesBasisUnderRecord` above carries the algebra. A rail that fails
  //     that is ENTANGLED at the free point, and `cqrt_free` is a hardware reset =
  //     a projective measurement (Rules 5/6/8). Freeze it: NO `cqrt_free`, LEFT
  //     ALLOCATED (a Rule-6 safe leak), decided here and executed in
  //     `Uncomputation::emitDagReversal`. A frozen rail IS still fully
  //     reverse-played — the freeze suppresses the free, never an adjoint, and
  //     that distinction is the whole soundness argument (see the note at the
  //     suppression site; dropping the adjoint breaks clause (d) above for every
  //     surviving rail that READS the frozen one).
  //
  //     The correlation propagates BACKWARD only. A DESCENDANT of a recorded rail
  //     A reverses cleanly even carrying its own Ry: the record C is diagonal on A
  //     and W_D acts on D conditioned on A, so C commutes with W_D and
  //     W_D† C W_D = C. (On the tape surface descendants are structurally
  //     impossible anyway — `tapedLineageClosed`, IOSinkLowering.cpp:144, declines
  //     taping a value with continued lineage.) An ANCESTOR is not so lucky: the
  //     record reads the descendant's label, which is a function of the ancestor's,
  //     so the ancestor is correlated too and its own chain must be re-proved.
  {
    SmallPtrSet<Value *, 8> Correlated;
    SmallVector<Value *, 8> CWork;
    // Seed: Rails ∪ {railOf(G)}. Those sets are NOT the same — a tainted non-alloc
    // CallInst enters `D.Calls` above but only a `cq_template_*`/`cqrt_qram_load_*`
    // enters `Rails`, while `emitDagReversal` frees by railOf. Seeding from `Rails`
    // alone would be incomplete on its own terms.
    //
    // THIS USED TO SAY the gap is "empty today only because a DOWNSTREAM guard —
    // `isInverseEmittable` — removes it". THAT IS FALSE and was corrected here (bd
    // uow0 Rule-13 round 2): `isInverseEmittable` explicitly ACCEPTS the one
    // emitter-mintable member, a `@__cq_q_<callee>_<mask>` specialization-clone
    // call. What actually keeps the gap empty is that no accepted input reaches such
    // a rail (both routes decline loudly), and the driver no longer rests on that:
    // it intersects its freeable set with `D.Rails`. Seeding WIDELY here is still
    // right — the freeze is a subtraction, so over-seeding can only over-freeze,
    // which is a leak.
    auto seedIfRecorded = [&](Value *R) {
      if (!R || Correlated.count(R))
        return;
      for (User *U : R->users())
        if (auto *S = dyn_cast<CallInst>(U))
          if (recordsIntoKeptCarrier(S, R)) {
            Correlated.insert(R);
            CWork.push_back(R);
            return;
          }
    };
    for (Value *R : Rails)
      seedIfRecorded(R);
    for (CallInst *G : D.Calls)
      seedIfRecorded(railOf(G));

    while (!CWork.empty()) {
      Value *C = CWork.pop_back_val();
      for (const auto &E : AncEdges)
        if (E.first == C && Correlated.insert(E.second).second)
          CWork.push_back(E.second);
    }

    for (CallInst *G : D.Calls) {
      Value *R = railOf(G);
      if (Correlated.count(R) && !preservesBasisUnderRecord(G))
        D.FrozenRails.insert(R);
    }

    // `railOf` NAMES WHAT THE GATE WRITES (bd test_C_libtooling-uow0, fixed). It
    // used to return the arg-0 FLAG of `cqrt_qram_store_<W>_controlled(flag, arr,
    // idx, val)` rather than its arg-1 array; it is now derived from
    // `isInPlaceGateOn`, so the two agree by construction. Two earlier drafts
    // reasoned around that gap and both are recorded here so neither rationale is
    // re-derived: a fail-closed `isGuardedQramStore` backstop (needed only while
    // the freeze SKIPPED a frozen rail's gates — skipping a gate whose `railOf`
    // does not name what it writes leaves a different register dirty), and then
    // the argument that the mis-attribution was inert because this decision and
    // the `emitDagReversal` suppression consult the SAME `railOf`. That second
    // argument was sound for the FREEZE and false for `Earliest` keying, which is
    // the half uow0 fixed.
  }
  return D;
}

}  // namespace cq
