// LiftCoverage.h — the per-use lift coverage of the post-lift stale re-sweep.
// Moved verbatim out of OpcodeLowering.cpp (bd test_C_libtooling-r2j3.6, to keep
// that file from growing); its one client is still the stale-record sweep there.
//
// ── THE PER-USE LIFT COVERAGE (bd test_C_libtooling-r2j3.11 + -dm7f.1) ──────────
//
// After `liftOneRegisterMergePhi` RAUWs a phi onto its wire base, a read of the
// phi and a read of the base are the same operand, so the re-sweep seeded at the
// base sees the phi's OWN incoming gates as siblings (dm7f.1: `if (c)
// cq_theta(&q,.125); v = q + 3;` declined) — and a union of every lift's gates
// would accept a stale read of a SECOND phi over the same base (`int r = q; if (c)
// { cq_theta(&q,.125); r = q; cq_theta(&q,.25); } v = r + 3;`, measured: the
// `add` read the post-`.25` wire). The lift therefore records its USES
// (`TaintSet::LiftedMergePhi`), and a read is exempted from exactly the gates on
// the record it read:
//   * the read's own slot is a recorded use of lift L — L's `RecordGates`;
//   * the operand is an in-place gate chain whose ancestry passes a recorded use
//     (`%t = cq_theta(phi, ·)`, then `v = %t + 3`) — the same, since `%t`'s record
//     extends the phi's. The hop is the walker's own backward closure: a
//     `cq_theta_` call whose arg 0 is tainted (the relation `lowerRotations`
//     builds the rail from), or a `cq_phi_` call.
// A use only counts while its slot still holds the lift's base: a later rebuild
// that renumbered or re-pointed it drops out, which can only decline.
//
// A lifted (Phase-6) call's argument slot is a use like any other (bd r2j3.6): the
// lift records the `call @g(%phi)` operand, `retargetSite` keeps the CallInst (or
// RAUWs it to its rebuild, which the tracking handle follows, same slot numbers).

#ifndef CQ_IRPASS_LIFT_COVERAGE_H_
#define CQ_IRPASS_LIFT_COVERAGE_H_

#include "TaintPropagation.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <utility>

namespace cq {

struct LiftCoverage {
  const TaintSet *Taint = nullptr;
  llvm::DenseMap<std::pair<const llvm::Value *, unsigned>,
                 llvm::SmallVector<unsigned, 1>>
      UseToLift;

  explicit LiftCoverage(TaintSet &T) : Taint(&T) {
    for (unsigned L = 0, E = T.LiftedMergePhis.size(); L != E; ++L) {
      const TaintSet::LiftedMergePhi &Rec = T.LiftedMergePhis[L];
      const llvm::Value *Base = Rec.Base;
      if (!Base)
        continue;
      for (const TaintSet::LiftedUse &U : Rec.Uses) {
        auto *UI =
            llvm::dyn_cast_or_null<llvm::User>(static_cast<llvm::Value *>(U.User));
        if (!UI || U.OpNo >= UI->getNumOperands() ||
            UI->getOperand(U.OpNo) != Base)
          continue;
        UseToLift[{UI, U.OpNo}].push_back(L);
      }
    }
  }

  // The lifts whose record the read in slot `OpNo` of `I` denotes; false when the
  // read is not a lifted read at all.
  bool liftsOf(const llvm::Instruction &I, unsigned OpNo,
               llvm::SmallVectorImpl<unsigned> &Lifts) const {
    auto Add = [&](const llvm::Value *U, unsigned Slot) {
      auto It = UseToLift.find({U, Slot});
      if (It != UseToLift.end())
        Lifts.append(It->second.begin(), It->second.end());
    };
    Add(&I, OpNo);
    llvm::SmallPtrSet<const llvm::Value *, 8> Seen;
    for (const llvm::Value *V = I.getOperand(OpNo); V && Seen.insert(V).second;) {
      const auto *CI = llvm::dyn_cast<llvm::CallInst>(V);
      const llvm::Function *F = CI ? CI->getCalledFunction() : nullptr;
      if (!F || CI->arg_size() < 1)
        break;
      const llvm::Value *A0 = CI->getArgOperand(0);
      const bool Hop = F->getName().starts_with("cq_phi_") ||
                       (F->getName().starts_with("cq_theta_") &&
                        Taint->Tainted.count(const_cast<llvm::Value *>(A0)));
      if (!Hop)
        break;
      Add(CI, 0);
      V = A0;
    }
    return !Lifts.empty();
  }

  // The gates the read in slot `OpNo` of `I` is exempt from (see above).
  bool coveredFor(const llvm::Instruction &I, unsigned OpNo,
                  llvm::SmallPtrSetImpl<const llvm::CallInst *> &Cov) const {
    llvm::SmallVector<unsigned, 2> Lifts;
    if (!liftsOf(I, OpNo, Lifts))
      return false;
    for (unsigned L : Lifts)
      for (const llvm::WeakVH &G : Taint->LiftedMergePhis[L].RecordGates)
        if (auto *GC = llvm::dyn_cast_or_null<llvm::CallInst>(
                static_cast<llvm::Value *>(G)))
          Cov.insert(GC);
    return true;
  }

  // Every slot of `I` that holds `Op` must be a lifted read, and a gate is exempt
  // only if EVERY such slot's record contains it: `add %p, %q` after the RAUW is
  // `add %q, %q`, and the base slot's record is not the phi's.
  bool coveredForValue(const llvm::Instruction &I, const llvm::Value *Op,
                       llvm::SmallPtrSetImpl<const llvm::CallInst *> &Cov) const {
    bool First = true;
    for (unsigned S = 0, E = I.getNumOperands(); S != E; ++S) {
      if (I.getOperand(S) != Op)
        continue;
      llvm::SmallPtrSet<const llvm::CallInst *, 8> Mine;
      if (!coveredFor(I, S, Mine)) {
        Cov.clear();
        return false;
      }
      if (First) {
        Cov.insert(Mine.begin(), Mine.end());
        First = false;
        continue;
      }
      llvm::SmallVector<const llvm::CallInst *, 8> Drop;
      for (const llvm::CallInst *G : Cov)
        if (!Mine.count(G))
          Drop.push_back(G);
      for (const llvm::CallInst *G : Drop)
        Cov.erase(G);
    }
    return !First;
  }

  // Record `I` as a covered reader of every lift its slots read, for the late
  // live-record warning (`TaintSet::LiftedMergePhi::Readers`).
  void noteReader(llvm::Instruction &I, TaintSet &T) const {
    llvm::SmallVector<unsigned, 2> Lifts;
    for (unsigned S = 0, E = I.getNumOperands(); S != E; ++S)
      liftsOf(I, S, Lifts);
    for (unsigned L : Lifts)
      T.LiftedMergePhis[L].Readers.emplace_back(&I);
  }
};

}  // namespace cq

#endif  // CQ_IRPASS_LIFT_COVERAGE_H_
