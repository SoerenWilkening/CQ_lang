// round1_snapshot_asym.cpp — REVIEW-ONLY (r1A on bd 8e5r), F-EA-1.
// Reproduces, at container level, the interaction between the self-cleaning
// `TaintSet::InLoopFlattenedPreds` (ScrubMap, whose operator[] RESETS a recycled
// key) and the RAW `DenseMap` snapshot `repropagateControlMerges` takes of it
// (`Round1FlattenedPreds`, TaintPropagation.cpp:2079), read by
// `collapseFlattenedLoopRails`' onward test `It->second <= Before` (LoopLowering.cpp
// ~4725). Sequence: round 1 records Pred P1 (count 1); the snapshot is taken; P1 is
// DELETED; a NEW block P2 lands at P1's address (forced with CQ_OPT_DEBUG_ALLOC=lifo);
// round 2 records P2 (++map[P2]); the onward test is asked for P2.
//   pre-8e5r  (raw live map + raw snapshot):       2 > 1  -> re-offered
//   8e5r      (ScrubMap live + RAW snapshot):       1 <= 1 -> SKIPPED  (the asymmetry)
//   8e5r + self-cleaning snapshot (ScrubMap copy):  1 > 0  -> re-offered
#include "llvm/IR/Instructions.h"  // ScrubOnDelete.h is not self-contained (needs CallInst)
#include "ScrubOnDelete.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include <cstdio>
using namespace llvm;
int main() {
  LLVMContext Ctx;
  Module M("m", Ctx);
  Function *F = Function::Create(FunctionType::get(Type::getVoidTy(Ctx), false),
                                 Function::ExternalLinkage, "f", M);
  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", F);
  IRBuilder<>(Entry).CreateRetVoid();
  auto run = [&](int Variant) {
    BasicBlock *P1 = BasicBlock::Create(Ctx, "p1", F);
    const void *A1 = P1;
    unsigned Seen = 0, Before = 0;
    bool Reoffered = false;
    if (Variant == 0) {  // pre-8e5r: both raw
      DenseMap<const BasicBlock *, unsigned> Live;
      ++Live[P1];
      DenseMap<const BasicBlock *, unsigned> Snap(Live.begin(), Live.end());
      P1->eraseFromParent();
      BasicBlock *P2 = BasicBlock::Create(Ctx, "p2", F);
      if ((const void *)P2 != A1) { std::printf("variant %d: NO REUSE (run under lifo)\n", Variant); return; }
      ++Live[P2];
      Seen = Live.find(P2)->second;
      auto PIt = Snap.find(P2); Before = PIt == Snap.end() ? 0 : PIt->second;
      P2->eraseFromParent();
    } else {
      cq::ScrubMap<const BasicBlock *, unsigned> Live;
      ++Live[P1];
      if (Variant == 1) {
        DenseMap<const BasicBlock *, unsigned> Snap(Live.begin(), Live.end());  // shipped spelling
        P1->eraseFromParent();
        BasicBlock *P2 = BasicBlock::Create(Ctx, "p2", F);
        if ((const void *)P2 != A1) { std::printf("variant %d: NO REUSE (run under lifo)\n", Variant); return; }
        ++Live[P2];
        Seen = Live.find(P2)->second;
        auto PIt = Snap.find(P2); Before = PIt == Snap.end() ? 0 : PIt->second;
        P2->eraseFromParent();
      } else {
        cq::ScrubMap<const BasicBlock *, unsigned> Snap(Live);  // self-cleaning snapshot
        P1->eraseFromParent();
        BasicBlock *P2 = BasicBlock::Create(Ctx, "p2", F);
        if ((const void *)P2 != A1) { std::printf("variant %d: NO REUSE (run under lifo)\n", Variant); return; }
        ++Live[P2];
        Seen = Live.find(P2)->second;
        auto PIt = Snap.find(P2); Before = PIt == Snap.end() ? 0 : PIt->second;
        P2->eraseFromParent();
      }
    }
    Reoffered = !(Seen <= Before);
    static const char *N[] = {"pre-8e5r (raw live, raw snapshot)", "8e5r    (ScrubMap live, RAW snapshot)",
                              "8e5r+fix (ScrubMap live, ScrubMap snapshot)"};
    std::printf("%-46s count(P2)=%u snapshot=%u -> %s\n", N[Variant], Seen, Before,
                Reoffered ? "re-offered" : "SKIPPED (round-2 loop never re-offered)");
  };
  run(0); run(1); run(2);
  return 0;
}
