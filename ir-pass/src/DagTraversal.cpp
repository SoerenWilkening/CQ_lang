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

// `isTemplateProducer` and `preservesBasisUnderRecord` USED to live here, in
// this anonymous namespace. They are now exported from `ChainWalk` (bd
// test_C_libtooling-6uqc Inc 5a) because the M-B INTERIOR partition is a third
// consumer of both, and this project's history says two spellings of one gate
// relation eventually disagree (bd uow0 `railOf`, bd 1fim `isAbiQramStore`).
// The bodies and their arguments moved VERBATIM; nothing about the freeze
// changed. Rule 14 — ask ChainWalk, do not re-spell them.

}  // namespace

DataDag recoverDataDag(ArrayRef<Value *> Terminals, const TaintSet &taint,
                       DominatorTree &DT, const InteriorPlan *IP) {
  DataDag D;

  // The M-B BORROWED-PARENT FRONTIER (bd 6uqc Inc 5a). A value in `IP->Borrowed`
  // is read-only for this DAG: the walk must not enqueue it, so it never becomes
  // a `Root`, its in-place gates are never collected into `Calls`, and nothing
  // downstream can adjoint or free it. `IP == nullptr` ⇒ always false ⇒ the two
  // existing partitions behave exactly as before.
  auto isFrontier = [&](Value *V) { return IP && IP->Borrowed.count(V); };

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
    // bd drbq round-2 review (lens A §1) — THE CONTROL-IN-PLACE FREEZE, ASKED OF
    // EVERY WALKED HANDLE, not only of the step-3 `Rails` set below.
    //
    // The step-3 copy (the `Rails` scan further down this function) is asked
    // over `D.Rails` = roots ∪ template producers, while the thing it must
    // suppress — `emitDagReversal`'s
    // `emitInverseCall` — iterates `D.Calls`, and those two sets are NOT equal
    // (the header note at `Uncomputation.cpp`'s `emitDagReversal` names the
    // difference explicitly and closes the `cqrt_free` half of it with an
    // `D.Rails` intersection, bd uow0). A `@__cq_q_<callee>_<mask>`
    // specialization-clone RESULT is in the difference: `isTemplateProducer`
    // stops at `cq_template_*`/`cqrt_qram_load_*`, so a clone result is never a
    // rail — yet a `cqrt_ry_<W>_controlled` on it IS in `D.Calls` (it enters at
    // the `isInPlaceGateOn` line just below), and Inc 0 made that gate
    // `isInverseEmittable`. So the ADJOINT half of the uow0 gap acquired a
    // customer this increment, and asking the freeze only at step 3 would never
    // see it: the spine would emit `cqrt_ry_<W>_controlled(f, h, -θ)` naming a
    // flag the region already `cqrt_free`d (finding-A's use-after-free, verbatim).
    //
    // It does not fire at HEAD — measured on three C reproducers (a `noinline`
    // callee whose clone result is the rotated base): all three accept and the
    // caller's spine reverses nothing, and so do the uncontrolled and
    // no-rotation twins, so the suppression today lives in whatever already
    // stops a clone-call chain being reversed, NOT here. That is precisely why
    // this is asked structurally rather than left to the coincidence: "the other
    // subsystem happens to stop it" was the prior justification for the free
    // half too, and it was recorded WRONGLY (see the `emitDagReversal` header).
    //
    // NO `continue` — deliberately, and it is not tidiness. `NotClosed` already
    // aborts both reversal drivers (`reverseTerminalGroup` and the M-B interior
    // partition bail on it before emitting anything), so truncating the walk
    // buys nothing; and `planInteriorDischarges` calls `recoverDataDag` for its
    // `TermGates` WITHHOLD set with NO regard for the bails, where a smaller
    // `D.Calls` is the UNSAFE direction (it would let the interior planner claim
    // a gate the terminal spine might reach). Set the flag, keep the superset.
    if (railCarriesControlledRotation(H))
      D.NotClosed = true;
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
          // own adjoints/frees).
          //
          // ⚠ THIS LOOP IS A NO-OP FOR ROTATIONS, BUT NOT FOR THE REASON IT USED
          // TO GIVE (bd drbq round-2 review, lens A §2). The old text said "a
          // rotation's only non-handle operand is a classical angle (untainted)",
          // which was true until Inc 0 added `cqrt_{ry,rz}_<W>_controlled(flag,
          // H, θ)` to `isInPlaceGateOn`: arg 0 of THAT spelling is an i32 CONTROL
          // FLAG handle, not an angle. The loop is still a no-op only because the
          // flag is deliberately NOT in `taint.Tainted` — the in-place
          // rotation-arm emitter mints it through `lowerCompareToFlag` and records
          // it in `ControlledRotations`/`DischargedFlagGates`, never in `Tainted`
          // (all 30 `Tainted.insert` sites enumerated, round-2 lens A).
          //
          // THE TRAP FOR INC 2/3, stated because the contrast is already in the
          // tree: `GuardedStoreArmEmit.cpp`'s guarded-store arm DOES
          // `taint.Tainted.insert(FlagI)` (~:297), precisely so its flag stays
          // live for a `_controlled_unc`. The moment a controlled ROTATION wants
          // the same, its flag becomes a DAG parent of the rotated rail here, the
          // flag's own `cq_template_icmp_*_hl` mint joins `D.Calls`, and the spine
          // emits a SECOND strip plus a free of an already-freed flag. If that
          // day comes, skip the control slot structurally (arg 0 when
          // `isInPlaceGateOn` matched at arg 1) rather than relying on this.
          for (Value *Op : G->args())
            if (Op != H && taint.Tainted.count(Op)) {
              if (!isFrontier(Op))
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
          if (!isFrontier(Op))
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
    // bd drbq Inc 1: a register a `cqrt_{ry,rz}_<W>_controlled` fired on, reached
    // as a DAG ANCESTOR (`s = r + 1` off the rotated register). Its adjoint needs
    // the control flag, which the in-place rotation-arm emitter stripped and
    // freed inside the region — so reversing it HERE would name a freed rail and
    // then free a still-dirty, condition-entangled register (Rules 6/8). This is
    // the site the measured defect actually went through: subtracting only at
    // terminal selection is not enough, because the rotated register is reached
    // through the M-C in-place `addc` on it.
    //
    // Asked STRUCTURALLY of the emitted gate, never of a recorded `Value *`
    // snapshot — see `railCarriesControlledRotation`, whose header records the
    // silent miscompile the snapshot form shipped with (a derived base's rail is
    // erased by `lowerOps` between the record and this query).
    if (railCarriesControlledRotation(R)) {
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
                     // only, never freeability.
                     //
                     // IT IS NOW ALSO A `recordsIntoKeptCarrier` (bd 5pio, owner
                     // ruling 2026-08-11) — the copy DESTINATION is a kept carrier
                     // the reversal never touches, exactly like the tape, so step 3b
                     // re-proves the SOURCE's own chain. This comment used to say
                     // the extension was "that ticket's call, not this one's"; that
                     // ticket ruled, and the ground is Bennett's: it puts the entire
                     // reclamation license on the source's chain and requires
                     // nothing whatever of a copy destination (see
                     // `recordsIntoKeptCarrier` for why the proposed dst-measured
                     // guard was refuted rather than merely unsupported).
                     //
                     // WHAT IT COSTS, measured rather than predicted: the sxuk QRAM
                     // index-root frees are SUPPRESSED (they become Rule-6 leaks).
                     // Those frees were justified by MEASUREMENT IMMUNITY — a valid
                     // argument, but a different one from "the rail is |0>" — so this
                     // freeze SUPERSEDES that carve-out rather than coexisting with
                     // it. On slice_qram_local_uncompute stage 2b goes from "2 left
                     // allocated, 3 free sites" to "4 left allocated, 1 free site",
                     // 0 violations either way.
                     //
                     // TWO DIFFERENT NUMBERS, AND THEY MEASURE DIFFERENT PREDICATES —
                     // do not quote the first as if it bounded the change. The
                     // DIRECT hazard (`src` IS a rotated rail, then freed) is
                     // prophylactic: across 1241 lowered modules there are 150
                     // uncontrolled 2-arg copy sites, 11 whose source is a
                     // directly-rotated rail, and ZERO of those also freed (their
                     // cswap users already force `NotClosed`). But the seed
                     // propagates BACKWARD, so what actually changes is the
                     // ANCESTORS of a copy source — which that census never counted.
                     // MEASURED separately: 9 lit fixtures and 6 e2e goldens move,
                     // 30 `cqrt_free`s removed, and every single changed line in all
                     // 15 modules is a removed `cqrt_free` (no adjoint dropped, no
                     // ordering change, no rc change). A Rule-13 reviewer caught the
                     // author quoting the first number for the second claim.
                     //
                     // What the change buys is durability in a NAME-shaped predicate:
                     // a future emitter minting a copy on a rotation-bearing rail
                     // would otherwise inherit a free with nothing checking.
        }
        if (isInvertEscape(CU)) {
          D.Escaped = true;
          continue;
        }
        if (SeenGates.count(CU))
          continue;  // a covered DAG gate — the legit fan-out / QQ consumer
        // M-B INTERIOR (bd 6uqc Inc 5a). An OWNED interior rail's forward
        // consumer is BY DEFINITION outside the recovered set — that is what
        // "interior" means, and it is why the whole condition-provenance chain
        // of `sqrt(a+3.0) <= 5.0` has no dead terminal and was never recovered
        // at all. Such a consumer is benign for CLOSURE when
        // `ChainWalk::isInteriorConsumer` admits it (the SAME per-user test
        // `isInteriorTerminalHandle` already ran — one definition, Rule 14).
        //
        // CLOSURE IS NOT THE WHOLE PROOF, and this is the one place that could
        // be misread as if it were. What this `continue` says is only "the rail
        // is not owned by some other emitter". That the consumer has ALREADY
        // EXECUTED, and never reads the rail again, is a POSITIONAL fact the
        // driver proves separately with `provablyBefore` before it ever builds
        // an `InteriorPlan` — never here, where there is no insertion point to
        // reason about.
        if (IP && IP->Owned.count(R) && isInteriorConsumer(CU, R, taint))
          continue;
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
  //     `ChainWalk::preservesBasisUnderRecord` carries the algebra. A rail that fails
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
