// LoopBoundProbe.cpp — MEASUREMENT TOOLING for the libm loop-bound campaign.
// Originally the bd 8zj2 throwaway; committed at owner direction 2026-08-21 so
// bd 19v3's 120-cell sweep measures with the SAME instrument 8zj2's 8-cell sweep
// did, rather than a re-authored one that can silently diverge.
//
// *** NOT PART OF THE SHIPPED PASS. *** It is deliberately NOT wired into the
// top-level CMake build and NOT registered with ctest: it must never be able to
// affect `cmake --build build` or the suite. Build it standalone (see README).
//
// Two passes:
//
//   cq-spike-scev    : per-loop SCEV trip-count report, straight off the LLVM 19
//                      API (no printer-text transcription), including BOTH the
//                      TRAP-1-compliant unsigned+1 answer and the TRAP-1-UNSOUND
//                      signed formula, side by side, so the trap is MEASURED on
//                      each cell rather than assumed to transfer.
//   cq-spike-excise  : back-edge excision. *** A KNOWN-FALSE-NEGATIVE PROBE —
//                      bd 66rz. *** Retained ONLY so the memo's §3a refutation
//                      stays reproducible. It prints a banner to stderr on every
//                      run; do not silence it, and do not use it to decide
//                      whether anything lies behind a loop.
//
// KNOWN LIMITATION of the scev reporter, recorded because it misled a reviewer:
// `isa<SCEVConstant>` is NOT a soundness test. Its `VERDICT bound-kind =
// CONSTANT` line fires for `fmod.f64`'s vacuous `-2` = 4294967294 bound. A usable
// bound needs FIVE conditions — constant AND non-negative AND small AND
// reachability-total AND `1 <= shift-amount <= width-1`. The reporter measures;
// it does not adjudicate. See SPIKE-8zj2 §1a/§2b.
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

std::string scevStr(const SCEV *S) {
  std::string Out;
  raw_string_ostream OS(Out);
  if (!S)
    OS << "<null>";
  else
    S->print(OS);
  return OS.str();
}

std::string dbgLoc(const Instruction *I) {
  if (!I)
    return "?";
  const DebugLoc &DL = I->getDebugLoc();
  if (!DL)
    return "no-dbg";
  std::string Out;
  raw_string_ostream OS(Out);
  OS << DL->getFilename() << ":" << DL.getLine();
  return OS.str();
}

void reportLoop(Loop *L, ScalarEvolution &SE, unsigned Idx) {
  BasicBlock *H = L->getHeader();
  BasicBlock *Latch = L->getLoopLatch();
  SmallVector<BasicBlock *, 4> Exiting;
  L->getExitingBlocks(Exiting);
  SmallVector<BasicBlock *, 4> Exits;
  L->getExitBlocks(Exits);

  outs() << "LOOP #" << Idx << " depth=" << L->getLoopDepth()
         << " innermost=" << (L->isInnermost() ? "yes" : "no") << "\n";
  outs() << "  header      = %" << H->getName() << "  @ "
         << dbgLoc(H->getFirstNonPHI()) << "\n";
  outs() << "  latch       = " << (Latch ? ("%" + Latch->getName().str()) : "<none>")
         << "\n";
  outs() << "  exiting     =";
  for (BasicBlock *B : Exiting)
    outs() << " %" << B->getName();
  outs() << "   (count " << Exiting.size() << ")\n";
  outs() << "  exit blocks =";
  for (BasicBlock *B : Exits)
    outs() << " %" << B->getName();
  outs() << "   (count " << Exits.size() << ")\n";
  outs() << "  header-is-exiting = " << (L->isLoopExiting(H) ? "yes" : "no")
         << "\n";

  for (BasicBlock *B : Exiting) {
    auto *BI = dyn_cast<BranchInst>(B->getTerminator());
    if (BI && BI->isConditional()) {
      std::string C;
      raw_string_ostream OS(C);
      BI->getCondition()->print(OS);
      outs() << "  exit-cond   @%" << B->getName() << " : " << OS.str() << "\n";
    }
  }

  // ---- SCEV, all four flavours, straight off the API ----
  const SCEV *Exact = SE.getBackedgeTakenCount(L);
  const SCEV *CMax = SE.getConstantMaxBackedgeTakenCount(L);
  const SCEV *SMax = SE.getSymbolicMaxBackedgeTakenCount(L);

  outs() << "  BTC exact              = " << scevStr(Exact) << "\n";
  outs() << "  BTC constant-max       = " << scevStr(CMax) << "\n";
  outs() << "  BTC symbolic-max       = " << scevStr(SMax) << "\n";

  // TRAP-1 COMPLIANT: LLVM's own unsigned max trip count. Internally this is
  // getConstantTripCount(getConstantMaxBackedgeTakenCount(L)) = zext(BTC)+1,
  // and 0 when the constant does not fit in 32 bits — i.e. UNSIGNED, and +1
  // for the trip (not the backedge) count. This is the number a peel needs.
  outs() << "  SOUND trip bound (getSmallConstantMaxTripCount) = "
         << SE.getSmallConstantMaxTripCount(L) << "   (0 = unknown/too-wide)\n";
  outs() << "  exact trip (getSmallConstantTripCount)          = "
         << SE.getSmallConstantTripCount(L) << "   (0 = unknown/non-constant)\n";

  // TRAP-1 UNSOUND, reproduced deliberately: the signed reading of an unsigned
  // quantity, returning a BACKEDGE count where a peel needs a TRIP count.
  if (SMax && !isa<SCEVCouldNotCompute>(SMax)) {
    ConstantRange R = SE.getSignedRange(SMax);
    ConstantRange U = SE.getUnsignedRange(SMax);
    outs() << "  UNSOUND formula getSignedRange(symbolicMax).getSignedMax() = "
           << R.getSignedMax() << "\n";
    outs() << "    signed range   = " << R << "\n";
    outs() << "    unsigned range = " << U << "\n";
    outs() << "    isKnownNonNegative(symbolicMax) = "
           << (SE.isKnownNonNegative(SMax) ? "yes" : "NO") << "\n";
  } else {
    outs() << "  UNSOUND formula: N/A (symbolic max is CouldNotCompute)\n";
  }

  // Is the constant max a LITERAL constant (⇒ a width fact, independent of any
  // runtime/quantum value) or does it name an SSA value (⇒ data-dependent)?
  if (CMax && isa<SCEVConstant>(CMax))
    outs() << "  VERDICT bound-kind = CONSTANT (no SSA operand => "
              "value-independent)\n";
  else if (CMax && isa<SCEVCouldNotCompute>(CMax))
    outs() << "  VERDICT bound-kind = UNPREDICTABLE (SCEV cannot bound it)\n";
  else
    outs() << "  VERDICT bound-kind = NON-CONSTANT SCEV (data-dependent)\n";
  outs() << "\n";
}

struct SpikeScev : PassInfoMixin<SpikeScev> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    auto &SE = FAM.getResult<ScalarEvolutionAnalysis>(F);
    if (LI.empty())
      return PreservedAnalyses::all();
    outs() << "=== function @" << F.getName() << " ===\n";
    unsigned Idx = 0;
    for (Loop *L : LI.getLoopsInPreorder())
      reportLoop(L, SE, Idx++);
    outs() << "TOTAL LOOPS in @" << F.getName() << " = " << Idx << "\n";
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};

// The measurement above uses the PASS MANAGER's ScalarEvolution. The CQ pass does
// NOT: LoopLowering.cpp / LoopUnrollPrepass.cpp hand-construct one, because the
// MODULE plugin has no FAM. If the two disagree, every number measured through
// `opt` is the wrong number for the question "what would the pass see". So measure
// both and diff them.
//
// CORRECTION (bd 19v3 adversarial round, 2026-08-21): an earlier version of this
// comment said the pass builds a "DEFAULT (conservative) TargetLibraryInfo". IT
// DOES NOT — `:` below builds `TargetLibraryInfoImpl(Triple(getTargetTriple()))`,
// triple-derived, the same Impl `TargetLibraryAnalysis` builds, and it is verbatim
// `LoopLowering.cpp:1561-1564`. The ONLY remaining difference is the per-Function
// binding: the analysis gives `TargetLibraryInfo(Impl, &F)`, this gives
// `TargetLibraryInfo(Impl)`. That difference IS live on this corpus (125 of 125
// modules carry `"no-builtins"`, which the Function-bound form honours by
// disabling every libfunc) — but three attempts to turn it into a SCEV difference
// failed, because SCEV's TLI reaches only the one-level `simplifyInstruction` in
// `createSCEV`. So read the measured "zero disagreements" as a NULL RESULT WITH
// UNESTABLISHED FALSIFYING POWER, not as a cleared risk.
struct SpikeScevPassStyle : PassInfoMixin<SpikeScevPassStyle> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      DominatorTree DT(F);
      LoopInfo LI(DT);
      if (LI.empty())
        continue;
      // Verbatim the LoopLowering.cpp:~1240 idiom.
      AssumptionCache AC(F);
      TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
      TargetLibraryInfo TLI(TLII);
      ScalarEvolution SE(F, TLI, AC, DT, LI);
      outs() << "=== [PASS-STYLE SE] function @" << F.getName() << " ===\n";
      unsigned Idx = 0;
      for (Loop *L : LI.getLoopsInPreorder())
        reportLoop(L, SE, Idx++);
      outs() << "TOTAL LOOPS in @" << F.getName() << " = " << Idx << "\n";
    }
    return PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};

// ---- provenance opacification (bd 19v3) -----------------------------------
//
// THE (A)-vs-(B) DISCRIMINATOR. 19v3's bucket (B) — "derivable BUT
// GUARD-CONDITIONAL" — is the dangerous one: PredMux measurably removes every
// guard (`br i1` 5->0, 4->0, `switch` 1->0), so a bound resting on an enclosing
// guard is the R1-class silent miscompile QramLowering.cpp:703-708 exists to
// prevent. 8zj2 discriminated by hand on 4 cells ("delete loop 1's entry guard
// AND replace both preheader incomings with a fresh @opaque_i32, destroying all
// provenance — SCEV's answer is unchanged at i32 32"). This automates exactly
// that leg so it can be run on every cell.
//
// It replaces EVERY value defined outside L and used inside L with a call to an
// opaque `declare` of the same type — strictly stronger than 8zj2's header-phi-
// only version, since a bound may rest on a loop-invariant mask or limit as
// easily as on a phi incoming. Literal constants are left alone: they are part
// of the loop's own text, not provenance (the in-loop `shl 1` must survive, or
// the test would destroy the very recurrence it is measuring).
//
// *** ONE-SIDED, BY CONSTRUCTION. *** SURVIVES => the bound does not depend on the
// outside INTEGER/FP values it replaced: partial positive evidence for bucket (A).
// DOES NOT SURVIVE => NOT a proof of guard-conditionality — SCEV may simply have
// lost a fact it could have kept. Read a lost bound as "needs the semantic leg",
// never as "(B), proven". Never invert this test.
//
// *** AND SURVIVES IS NOT A CLEAN BILL OF HEALTH — THREE MEASURED HOLES. *** Found
// by an adversarial round against this very file (bd 19v3, 2026-08-21), the same
// way bd 8zj2 found two over-accepts in its own instrument:
//
//   1. IT ONLY REPLACES INTEGER AND FP VALUES. A bound carried by a POINTER, by an
//      allocated object's SIZE, or by `!range` metadata on an in-loop load is never
//      touched. Measured counterexamples: `@ptr_small` (8-byte alloca, pointer
//      compare exit) and `@global_range_bound` (in-loop load with `!range`) each
//      hold a small non-negative constant bound that passes C1+C2+C3 and report
//      SURVIVES after replacing ZERO values. That is why the NULL-MUTATION banner
//      below exists: a survival over an empty mutation is not a measurement.
//   2. SURVIVAL IS VACUOUS WHEN THE BASELINE WAS `CouldNotCompute`. CNC in => CNC
//      out is what ANY mutation produces, including none. On the bd 19v3
//      population, 43 of 76 loops "survive" but only 16 had a real baseline bound;
//      the other 27 are CNC->CNC and carry zero information. Never quote a bare
//      survival count.
//   3. IT DOES NOT DELETE THE ENTRY GUARD, which bd 8zj2's hand test did. It is
//      strictly STRONGER on the value leg and strictly WEAKER on the guard leg, so
//      it is not the same test and must not be described as reproducing it.
//
// Poison flags are also untouched — strip `nuw`/`nsw`/`exact` separately if the
// bound might rest on them (measured on the 19v3 bucket-A set: it does not).
//
// It deliberately REUSES `reportLoop` verbatim so the SCEV measurement is the
// identical instrument, per the bd 19v3 direction not to re-author it.
struct SpikeOpaque : PassInfoMixin<SpikeOpaque> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    if (LI.empty())
      return PreservedAnalyses::all();
    SmallVector<Loop *, 8> All(LI.getLoopsInPreorder());
    Module *M = F.getParent();
    unsigned Nth = 0;
    for (Loop *L : All) {
      // Collect (use, outside-value) pairs first: mutating while walking uses
      // invalidates the iteration (Rule 9's never-cache-across-mutation, and the
      // loop-phi UAF this project has already paid for once).
      SmallVector<std::pair<Use *, Value *>, 32> Work;
      for (BasicBlock *BB : L->blocks())
        for (Instruction &I : *BB)
          for (Use &U : I.operands()) {
            Value *V = U.get();
            if (isa<Constant>(V) || isa<BasicBlock>(V) || isa<MetadataAsValue>(V))
              continue;
            if (!V->getType()->isIntegerTy() && !V->getType()->isFloatingPointTy())
              continue;
            if (auto *DI = dyn_cast<Instruction>(V)) {
              if (L->contains(DI->getParent()))
                continue;  // defined inside — part of the recurrence.
            } else if (!isa<Argument>(V)) {
              continue;
            }
            Work.push_back({&U, V});
          }
      unsigned Done = 0;
      for (auto &P : Work) {
        Use *U = P.first;
        Type *Ty = P.second->getType();
        std::string Nm;
        raw_string_ostream NS(Nm);
        NS << "cq_spike_opaque_" << Nth << "_";
        Ty->print(NS);
        FunctionCallee FC = M->getOrInsertFunction(NS.str(), Ty);
        // Insert in the USER's block, immediately before the user, so it
        // dominates trivially even for a phi-free shape. For a PHI operand the
        // call must sit in the INCOMING block instead (a phi's operand must
        // dominate the end of its incoming edge, not the phi).
        auto *UserI = cast<Instruction>(U->getUser());
        Instruction *IP = UserI;
        if (auto *PN = dyn_cast<PHINode>(UserI))
          IP = PN->getIncomingBlock(*U)->getTerminator();
        CallInst *C = CallInst::Create(FC, {}, "", IP->getIterator());
        U->set(C);
        ++Done;
      }
      errs() << "OPAQUIFIED loop #" << Nth << " in @" << F.getName() << ": "
             << Done << " outside-value use(s)\n";
      // A survival over an EMPTY mutation is not a measurement — the loop was
      // re-analysed unchanged, so of course the bound is unchanged. Say so
      // unmissably rather than letting the caller read the ordinary SURVIVES.
      // (Hole 1 above: the collector skips pointers, aggregates and metadata, so a
      // bound resting on those produces exactly this.)
      if (Done == 0)
        errs() << "*** cq-spike-opaque NULL MUTATION on loop #" << Nth << " in @"
               << F.getName() << " — 0 values replaced, so any SURVIVES verdict "
                  "for it is VOID. Its bound may rest on a pointer, an object "
                  "size, or !range metadata, none of which this probe touches. ***\n";
      ++Nth;
    }
    if (verifyFunction(F, &errs())) {
      errs() << "*** cq-spike-opaque: VERIFIER FAILED after opacification in @"
             << F.getName() << " — DISCARD this cell's result ***\n";
      return PreservedAnalyses::none();
    }
    // Re-analyse from scratch: the mutation invalidated everything.
    DominatorTree DT(F);
    LoopInfo LI2(DT);
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M->getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI2);
    outs() << "=== [OPAQUE] function @" << F.getName() << " ===\n";
    unsigned Idx = 0;
    for (Loop *L : LI2.getLoopsInPreorder())
      reportLoop(L, SE, Idx++);
    outs() << "TOTAL LOOPS in @" << F.getName() << " = " << Idx << "\n";
    return PreservedAnalyses::none();
  }
  static bool isRequired() { return true; }
};

// ---- back-edge excision (the L3 memo's peel test) -------------------------
//
// *** THIS IS A KNOWN-FALSE-NEGATIVE PROBE. bd 66rz. ***
// Excision deletes the loop's exit branch, which makes the whole tainted
// loop-body recurrence dead; cq-lowering's own DCE then removes it. So the
// "rest" that gets lowered CONTAINS NO INSTRUCTION FROM THE LOOP. Measured:
// inject a real blocker (`trunc i32 -> i7`) into ilogb.f64's loop body and this
// still reports LOWERS CLEAN, while the identical blocker under a genuine
// static-K peel declines. It reported CLEAN on 6 of 6 looping cells, including
// two the project has ruled permanently out. Use a genuine static-K peel (body
// live, exit branches preserved) to ask what is behind a loop.
struct SpikeExcise : PassInfoMixin<SpikeExcise> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    // Unsilenceable, once per run: this tool must not be usable without its
    // status being visible in the transcript.
    static bool Warned = false;
    if (!Warned) {
      Warned = true;
      errs() << "*** cq-spike-excise: KNOWN-FALSE-NEGATIVE deeper-layer probe "
                "(bd 66rz). It deletes the loop body it claims to test. Use a "
                "genuine static-K peel instead. ***\n";
    }
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    SmallVector<Loop *, 8> All(LI.getLoopsInPreorder());
    unsigned Done = 0, Bailed = 0;
    // innermost-first so an outer loop's structure is still intact when read
    for (Loop *L : reverse(All)) {
      BasicBlock *H = L->getHeader();
      BasicBlock *Latch = L->getLoopLatch();
      if (!Latch) {
        errs() << "EXCISE-BAIL: no unique latch in @" << F.getName() << "\n";
        ++Bailed;
        continue;
      }
      auto *BI = dyn_cast<BranchInst>(Latch->getTerminator());
      if (!BI) {
        errs() << "EXCISE-BAIL: latch terminator is not a br\n";
        ++Bailed;
        continue;
      }
      // Target: the latch's non-header successor when the latch exits; else the
      // loop's unique exit block. Anything else is an unproven shape — bail
      // LOUDLY rather than invent an edge (the whole point of the test is that
      // the REST of the body is untouched).
      BasicBlock *Target = nullptr;
      if (BI->isConditional()) {
        for (BasicBlock *S : BI->successors())
          if (S != H)
            Target = S;
      }
      if (!Target)
        Target = L->getUniqueExitBlock();
      if (!Target) {
        errs() << "EXCISE-BAIL: cannot determine an exit target for loop with "
                  "header %" << H->getName() << "\n";
        ++Bailed;
        continue;
      }
      // If Target's phis do not already list Latch as a predecessor we would
      // have to invent an incoming value — refuse (LiteralIntegrity discipline:
      // never mint a value that denotes nothing).
      bool NeedsInvented = false;
      for (PHINode &P : Target->phis())
        if (P.getBasicBlockIndex(Latch) < 0)
          NeedsInvented = true;
      if (NeedsInvented) {
        errs() << "EXCISE-BAIL: target %" << Target->getName()
               << " phis lack a Latch incoming (would require an invented "
                  "value)\n";
        ++Bailed;
        continue;
      }
      // Excise: latch -> exit unconditionally, then drop the header phis'
      // latch incomings.
      BranchInst::Create(Target, BI->getIterator());
      BI->eraseFromParent();
      for (PHINode &P : make_early_inc_range(H->phis())) {
        int Idx = P.getBasicBlockIndex(Latch);
        if (Idx >= 0)
          P.removeIncomingValue((unsigned)Idx, /*DeletePHIIfEmpty=*/false);
      }
      ++Done;
    }
    if (Done)
      errs() << "EXCISED " << Done << " back edge(s) in @" << F.getName()
             << " (bailed " << Bailed << ")\n";
    else if (Bailed)
      errs() << "EXCISED 0, bailed " << Bailed << " in @" << F.getName() << "\n";
    return Done ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
  static bool isRequired() { return true; }
};

}  // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "cq-spike-8zj2", "0.1",
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "cq-spike-scev") {
                    FPM.addPass(SpikeScev());
                    return true;
                  }
                  if (Name == "cq-spike-excise") {
                    FPM.addPass(SpikeExcise());
                    return true;
                  }
                  if (Name == "cq-spike-opaque") {
                    FPM.addPass(SpikeOpaque());
                    return true;
                  }
                  return false;
                });
            PB.registerPipelineParsingCallback(
                [](StringRef Name, ModulePassManager &MPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "cq-spike-scev-passstyle") {
                    MPM.addPass(SpikeScevPassStyle());
                    return true;
                  }
                  return false;
                });
          }};
}
