// RailBankPromote.cpp — bd `xdu2` / L-1a clause C5: THE PER-ACTIVATION PROMOTER.
//
// Read `RailBankPromote.h` first: the contract, why the naive element-type
// rewrite is wrong, the slot and its L1 (round-2) argument, the staged landing,
// the B-clauses and the per-activation containment proof. This file carries the
// PLAN and the REWRITE.
//
// ACCEPT-ONLY (the `MergePhiPeel` / `promoteVolatileScalarLocals` precedent):
// this stage NEVER calls `diagnoseUnderControl` and never diagnoses at all. A
// shape that fails any clause is left BYTE-UNTOUCHED and reaches its existing
// loud owner unchanged — which, for every member of this stage's population, is
// `declineTaintEscapes`' `cq taint escape: tainted value stored to memory`.

#include "RailBankPromote.h"

#include "QramLowering.h"   // railBankCarveVerdict / RailBankCarve / RailBankShape
                            // — TRACK A'S REAL CLASSIFIER. ⚠ Until the merge of
                            // 2026-09-14c this was `RailBankCarve.h`, a Track-B
                            // stand-in built so that leaving it in was a
                            // DUPLICATE-SYMBOL link error. The trigger FIRED as
                            // written (measured at the merge gate: `duplicate
                            // symbol 'cq::railBankCarveVerdict(...)'` in BOTH
                            // libCQPass.so and cq-opt), the shim and its header
                            // are deleted, and this line is the whole of the
                            // change it demanded (L8: a retirement trigger that
                            // names its own replacement text works).
                            //
                            // ⚠ AND EXACTLY ONE THIRD OF THAT TRIPWIRE ACTUALLY
                            // FIRED (merge filing F-4). The recipe was defended as
                            // a THREE-part argument — a duplicate-symbol LINK
                            // error, a REDEFINITION compile error "in any TU that
                            // sees both headers", and a hard error on the
                            // duplicated default argument — and the last two are
                            // INERT: measured at the gate, neither fired, because
                            // NO TU includes both headers, which is precisely the
                            // arrangement a stand-in header is built to have. The
                            // fail-loud property was carried ENTIRELY by the link
                            // error. Recorded here, at the recipe's own site, so a
                            // future stand-in built to the same pattern does not
                            // inherit only the inert parts and call itself
                            // impossible to forget: **if you build a shim, the
                            // tripwire must be a DEFINITION collision at LINK
                            // time; a declaration collision proves nothing about
                            // headers nobody includes together.**
#include "OpcodeSupport.h"  // abiWidthFromType (the ABI width the record carries)
#include "TaintPropagation.h"

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"  // getUnderlyingObject (Rule 14: LLVM's own walk)
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"

#include "llvm/ADT/STLExtras.h"  // make_early_inc_range

#include <cstdlib>
#include <optional>
#include <utility>

using namespace llvm;

namespace cq {

namespace {

// A recovered promotion site. Every field is filled by `planBank` BEFORE any
// mutation (Rule 9: detection is pure analysis by SSA-value identity), and
// `applyBank` is then INFALLIBLE — it never bails half-way, because a
// half-normalised module is a reviewer's nightmare and, worse, a module no
// clause in the tree describes.
struct BankPlan {
  AllocaInst *Bank = nullptr;
  Loop *L = nullptr;
  BasicBlock *Header = nullptr;
  BasicBlock *Latch = nullptr;
  Type *CellTy = nullptr;
  // The per-cell seed. `Constant::getNullValue(CellTy)` for BOTH admitted
  // initializer shapes — a proven whole-object constant-zero `llvm.memset`, and
  // (owner ruling D1, composing with bd `z9t1`) NO initializer at all. The
  // disclosure that second case owes is at `railBankCarveVerdictImpl`'s D1
  // block (`QramLowering.cpp`) and in `IMPL_A.md` §6.
  Constant *Seed = nullptr;
  // The gep to CLONE at the latch, and the store to copy `!dbg`/align/`!tbaa`
  // from. Both come from the LAST `Bank` store in program order, so the surviving
  // store keeps the source location of the write the author actually wrote and
  // the `kMsgStore` decline stays where it was.
  GetElementPtrInst *CanonGep = nullptr;
  StoreInst *CanonStore = nullptr;
  uint64_t Count = 0;                  // N, from RailBankShape
  StringRef ElemAbi;                   // the cell ABI width, from RailBankShape
  SmallVector<LoadInst *, 4> Loads;    // in `L`
  SmallVector<StoreInst *, 4> Stores;  // in `L`
  SmallVector<GetElementPtrInst *, 8> Geps;  // in `L`, erased once dead
};

// Is `I` an access to `Plan.Bank`'s cell through a CANONICAL access gep?
bool isCellMemop(const Instruction *I, const AllocaInst *Bank) {
  const Value *P = nullptr;
  if (auto *LI = dyn_cast<LoadInst>(I))
    P = LI->getPointerOperand();
  else if (auto *SI = dyn_cast<StoreInst>(I))
    P = SI->getPointerOperand();
  else
    return false;
  auto *G = dyn_cast<GetElementPtrInst>(P);
  return G && G->getPointerOperand() == Bank;
}

// ── THE BANK-USER VOCABULARY ────────────────────────────────────────────────
//
// Every user of the alloca must fall in one of these, or the bank is refused.
// The partition is what licenses the rewrite: this stage MOVES a write inside
// the activation, so it may only do so when every other observer of the object
// is provably outside the loop or provably a non-writer.
enum class BankUse {
  Rewritable,  // a canonical `gep [N x T], ptr %a, 0, %idx` — the cells this
               // stage forwards. In `L` these ARE the rewrite; outside `L` they
               // are left alone (and must be read-only, B5).
  Read,        // a provable in-bounds constant-offset READ of one cell: a direct
               // `load` off the alloca, or a `gep` with a constant accumulated
               // offset all of whose users are cell-typed simple loads. ⚠ This
               // is `-O1`'s spelling for an UNROLLED read loop (`b[0]`, `b[1]`,
               // `b[2]` become `load ptr %a`, `gep i8 ptr %a, 1`, `gep i8 ptr
               // %a, 2`), which is why the clause exists at all.
  Init,        // the one admitted initializer: a whole-object constant-zero
               // `llvm.memset`, or a whole-object constant-zero `store`.
  Marker,      // `llvm.lifetime.start` / `.end`.
  Unknown,     // anything else — the address escapes or is accessed off-shape.
};

// A whole-object constant-ZERO store (`store i16 0, ptr %a` for `[2 x i8]`).
//
// ⚠ MEASURED CORRECTION TO `SCOPE_L1a.md` §2 C1, which names ONLY "a
// constant-zero `llvm.memset`" (`QramLowering.cpp:1953-1971`). `clang -O1`
// emits a memset for `bool b[3] = {0}` and a plain INTEGER STORE for `bool b[2]
// = {0}` / `bool b[8] = {0}` — the power-of-two sizes it can write in one
// instruction. A memset-only clause therefore refuses TWO OF THE THREE sizes the
// increment's own fixture list names (N=2/3/8), which is an over-decline of the
// program we set out to compile, not a safety margin (owner ruling 2026-09-11).
//
// It is a PROOF, not a manufacture: the object is provably all-zero after it,
// exactly as after the memset. Only the NO-INITIALIZER case (owner ruling D1)
// manufactures a value the source never wrote, and only that case carries the
// bd `z9t1` disclosure.
bool isWholeObjectZeroStore(const StoreInst *SI, const AllocaInst *Bank) {
  if (SI->getPointerOperand() != Bank || !SI->isSimple())
    return false;
  auto *C = dyn_cast<Constant>(SI->getValueOperand());
  if (!C || !C->isNullValue())
    return false;
  const DataLayout &DL = Bank->getModule()->getDataLayout();
  return DL.getTypeStoreSize(SI->getValueOperand()->getType()) ==
         DL.getTypeAllocSize(Bank->getAllocatedType());
}

// A provable in-bounds constant-offset read of one cell.
bool isConstantOffsetCellRead(const User *U, const AllocaInst *Bank,
                              Type *CellTy) {
  const DataLayout &DL = Bank->getModule()->getDataLayout();
  const uint64_t Size = DL.getTypeAllocSize(Bank->getAllocatedType());
  const uint64_t Cell = DL.getTypeStoreSize(CellTy);
  if (auto *LI = dyn_cast<LoadInst>(U))
    return LI->getPointerOperand() == Bank && LI->isSimple() &&
           LI->getType() == CellTy && Cell <= Size;
  auto *G = dyn_cast<GetElementPtrInst>(U);
  if (!G || G->getPointerOperand() != Bank)
    return false;
  APInt Off(DL.getIndexTypeSizeInBits(G->getType()), 0);
  if (!G->accumulateConstantOffset(DL, Off) || Off.isNegative())
    return false;
  if (Off.getActiveBits() > 63 || Off.getZExtValue() + Cell > Size)
    return false;
  if (G->use_empty())
    return false;
  for (const User *Use : G->users()) {
    auto *LI = dyn_cast<LoadInst>(Use);
    if (!LI || LI->getPointerOperand() != G || !LI->isSimple() ||
        LI->getType() != CellTy)
      return false;
  }
  return true;
}

// ── THE PLAN (pure analysis, no mutation — Rule 9) ──────────────────────────
bool planBank(AllocaInst *Bank, const TaintSet &taint, DominatorTree &DT,
              LoopInfo &LI, ScalarEvolution &SE, BankPlan &Plan) {
  auto *AT = dyn_cast<ArrayType>(Bank->getAllocatedType());
  if (!AT || Bank->isArrayAllocation())
    return false;
  Plan.Bank = Bank;
  Plan.CellTy = AT->getElementType();

  // Walk the alloca's users ONCE and collect the rewrite's worklist. This is NOT
  // a second carve (Rule 14): the carve answers "is this store a rail-bank cell
  // write?" and is CALLED below; this walk collects the instructions the rewrite
  // will touch and refuses anything it cannot express. An accept needs BOTH, so
  // a divergence between them can only ever over-DECLINE.
  SmallVector<std::pair<GetElementPtrInst *, Instruction *>, 8> Pairs;
  SmallVector<Instruction *, 4> Inits;
  SmallVector<Instruction *, 8> NonRewritable;  // `Read` / `Init` / `Marker`
  SmallVector<StoreInst *, 4> AllStores;        // every cell store in the object
  for (User *U : Bank->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI)
      return false;  // a `ConstantExpr` on the address: not modelled.
    if (auto *II = dyn_cast<IntrinsicInst>(UI)) {
      Intrinsic::ID ID = II->getIntrinsicID();
      if (ID == Intrinsic::lifetime_start || ID == Intrinsic::lifetime_end) {
        NonRewritable.push_back(II);
        continue;
      }
      if (auto *MS = dyn_cast<MemSetInst>(II)) {
        auto *V = dyn_cast<ConstantInt>(MS->getValue());
        auto *Len = dyn_cast<ConstantInt>(MS->getLength());
        const uint64_t Size = Bank->getModule()->getDataLayout()
                                  .getTypeAllocSize(AT).getFixedValue();
        if (MS->isVolatile() || MS->getRawDest() != Bank || !V || !V->isZero() ||
            !Len || Len->getZExtValue() != Size)
          return false;
        Inits.push_back(MS);
        NonRewritable.push_back(MS);
        continue;
      }
      return false;
    }
    if (auto *SI = dyn_cast<StoreInst>(UI)) {
      // A direct store off the alloca is EITHER the whole-object zero
      // initializer or a write this stage does not model. Never a cell write it
      // could rewrite: a rewritable access goes through a canonical gep.
      if (!isWholeObjectZeroStore(SI, Bank))
        return false;
      Inits.push_back(SI);
      NonRewritable.push_back(SI);
      continue;
    }
    if (isConstantOffsetCellRead(UI, Bank, Plan.CellTy)) {
      NonRewritable.push_back(UI);
      // ⚠ AND ITS LOADS, WHICH ARE A DIFFERENT SET OF BLOCKS (bd
      // `test_C_libtooling-n74d`, P1, Rule-13 round 1 finding F-α2). The
      // "nothing non-rewritable inside `L`" clause below is what LICENSES MOVING
      // THE STORE, and it was keyed on the ADDRESS. `clang -O1` LICM hoists a
      // loop-invariant cell address to the preheader and LEAVES THE LOAD IN THE
      // LOOP, so on the validated floor the gep's block and the load's block are
      // routinely different blocks — MEASURED verbatim in
      // `trackA/probes/c1_readcell1_inloop.c`'s stage-1 IR:
      //     %2 = getelementptr inbounds i8, ptr %1, i64 1   ; ENTRY block
      //   6:                                                ; the loop
      //     %14 = load i8, ptr %2, align 1                  ; IN `L`
      // A `Read` gep is NOT an observation; its LOADS are. Rule 9 verbatim:
      // never assume instruction placement — and this is the class of fence the
      // project keeps losing to (`CLAUDE.md` L5, F2's four lost rounds).
      // ⚠ RETIREMENT TRIGGER: the day `BankUse::Read` admits a user that is not a
      // load (a `memcpy` source, say), enumerate ITS observation points here too —
      // the invariant this clause needs is *every instruction that OBSERVES the
      // object*, and a gep observes nothing.
      if (auto *RG = dyn_cast<GetElementPtrInst>(UI))
        for (User *RU : RG->users())
          if (auto *RI = dyn_cast<Instruction>(RU))
            NonRewritable.push_back(RI);
      continue;
    }
    auto *G = dyn_cast<GetElementPtrInst>(UI);
    if (!G || G->use_empty())
      return false;
    // ⚠ NOT `G->hasOneUse()`. In the customer's `-O1` module the arm's gep has
    // TWO uses — the seed `load` AND the `store` at the same address — which is
    // exactly the shape `SCOPE_L1a.md` §0 H3 exists to describe. A literal
    // `hasOneUse()` (which §2 C4 names) makes this stage fire on nothing;
    // MEASURED, and the same correction is carried at the carve.
    for (User *Use : G->users()) {
      auto *Memop = dyn_cast<Instruction>(Use);
      if (!Memop || !isCellMemop(Memop, Bank))
        return false;
      // B4 — simple, exact-type accesses only.
      if (auto *L = dyn_cast<LoadInst>(Memop)) {
        if (!L->isSimple() || L->getType() != Plan.CellTy)
          return false;
      } else if (auto *S = dyn_cast<StoreInst>(Memop)) {
        if (!S->isSimple() || S->getValueOperand()->getType() != Plan.CellTy)
          return false;
      } else {
        return false;
      }
      Pairs.emplace_back(G, Memop);
      if (auto *SI = dyn_cast<StoreInst>(Memop))
        AllStores.push_back(SI);
    }
  }
  if (AllStores.empty())
    return false;
  if (Inits.size() > 1)
    return false;  // one initializer, or none (owner ruling D1).

  // B6 — every store into the bank is a `Bank` store by TRACK A'S CARVE, and
  // there is at least one. ⚠ THE ONE CALL SITE. `QramLowering.h` explains why
  // it is one and why every way its signature can change is a compile or link
  // error rather than a silent second spelling.
  //
  // ⚠ AND IT IS WHERE THE PROMOTER'S FACTS COME FROM (Rule 14). `RailBankShape`
  // hands back the alloca, the loop, the raw index, the cell type, the ABI
  // string, `N` and the proven trip count, and NONE of them is re-derived here —
  // Track A added the out-parameter for exactly this reason, because the
  // alternative is a second spelling of the origin walk (the drbq Inc-3 (b')
  // defect, filed by name).  It runs FIRST, before any clause below, because
  // `Plan.L` is the carve's answer and every B-clause is stated in terms of it.
  //
  // ⚠ Two facts about the shipped ACCEPT SURFACE that the promoter depends on and
  // does NOT re-ask — the walk loop is OUTERMOST, and C4 admits the
  // read-modify-write cell address — are recorded in `QramLowering.h` (C2′'s
  // `getParentLoop()` half and C4's deviation). The first
  // is load-bearing for THIS stage's soundness and the B-clauses do NOT cover it
  // (B1 refuses an access in a SUB-loop, never an ENCLOSING loop);
  // `railbank_promote_reject_nested_outer_loop.ll` pins it.
  //
  // ⚠ THE VERDICT THIS CLAUSE REQUIRES IS `BankRaw`, NOT `Bank` (bd
  // `test_C_libtooling-de8n`, 2026-09-15). The carve's clause C7 splits the
  // accept-shaped verdict in two, and the split IS this stage's contract:
  //   *the promoter's INPUT is `BankRaw`; the promoter's OUTPUT is `Bank`.*
  // `Bank` means "no read of the bank survives inside `L`, and the store is total
  // per trip" — which is precisely what `applyBank` produces and what the deferred
  // type rewrite is allowed to see. Requiring `BankRaw` here is not a narrowing of
  // the fire set: B8 below refuses a bank with no in-`L` load, and a `Bank` bank
  // has none by definition, so every module this stage has ever fired on is
  // `BankRaw`. What it buys is that the contract is CHECKED at both ends rather
  // than argued — and a SECOND, independent guarantee that the caller's fixpoint
  // terminates (after a promotion the same bank classifies `Bank` and is refused
  // here, one clause before B8 can be reached).
  // ⚠ RETIREMENT TRIGGER: if C7 is ever widened so that a shape this stage still
  // wants to normalise classifies `Bank`, this line silently stops promoting it
  // with NO diagnostic anywhere. Re-derive C7 and this clause in the same change.
  for (StoreInst *SI : AllStores) {
    const char *Msg = nullptr;
    RailBankShape Shape;
    if (railBankCarveVerdict(SI, taint, DT, LI, SE, Msg, &Shape) !=
        RailBankCarve::BankRaw)
      return false;
    if (Shape.Alloca != Bank || Shape.CellTy != Plan.CellTy || !Shape.L)
      return false;  // two stores that resolve to different banks or cell types.
    if (!Plan.L)
      Plan.L = Shape.L;
    else if (Plan.L != Shape.L)
      return false;
    Plan.Count = Shape.Count;
    Plan.ElemAbi = Shape.ElemAbi;
  }

  // ⚠ NOTHING NON-REWRITABLE MAY LIVE INSIDE `L`, AND THIS CLAUSE IS THE ONE
  // THAT LICENSES MOVING THE STORE. This stage relocates the activation's write
  // to the activation's END, so any OTHER observer of the object inside the loop
  // body would see the write at a different point in the trip:
  //     for (i…) { if (c) b[i] = θ(b[i]); x = b[0]; }
  // reads `b[0]` AFTER the store on trip 0 in the source and BEFORE it after the
  // move. That is a silent miscompile of a CLASSICAL value, and `opt -verify`
  // cannot see it. A `Read`, an `Init` or a lifetime marker inside `L` is
  // therefore refused outright rather than reasoned about.
  for (Instruction *I : NonRewritable)
    if (Plan.L->contains(I->getParent()))
      return false;

  // Partition: the accesses INSIDE the write loop are the rewrite's worklist;
  // everything else is left byte-untouched.
  SmallPtrSet<GetElementPtrInst *, 8> SeenGeps;
  for (auto &P : Pairs) {
    GetElementPtrInst *G = P.first;
    Instruction *Memop = P.second;
    if (!Plan.L->contains(Memop->getParent())) {
      // B5 — ONE WRITER. A store outside the write loop makes the
      // per-activation seed something other than the initializer. A LOAD outside
      // it is fine and is exactly the customer's measure loop: it reads cells
      // written by a DIFFERENT activation of a DIFFERENT loop, which no
      // per-activation forwarding can reach (`SCOPE_L1a.md` §3c) — so it keeps
      // its `load`, and that load is what the DEFERRED taint rule will claim.
      if (isa<StoreInst>(Memop))
        return false;
      continue;
    }
    // B1 — DIRECTLY in `L`. An access in a SUB-loop of `L` would need a φ inside
    // that sub-loop's own back edge; sound in principle, unmeasured here, and
    // refused rather than widened (Prime Directive).
    if (LI.getLoopFor(Memop->getParent()) != Plan.L)
      return false;
    SeenGeps.insert(G);
    if (auto *L = dyn_cast<LoadInst>(Memop))
      Plan.Loads.push_back(L);
    else
      Plan.Stores.push_back(cast<StoreInst>(Memop));
  }
  // One gep may carry SEVERAL memops (the customer's arm gep carries the seed
  // load AND the store), so the erase list is DEDUPED — erasing the same
  // instruction twice is a use-after-free that `opt -verify` never sees.
  for (GetElementPtrInst *G : SeenGeps)
    Plan.Geps.push_back(G);
  // B9 — EXACTLY ONE WRITE PER ACTIVATION, AND THIS STAGE OWNS THE CLAUSE (merge
  // filing F-2, 2026-09-14c). The carve's C4 second half already refuses a bank
  // with more than one store site, so this is unreachable today — which is exactly
  // why it is written here rather than relied upon from there. `MERGE_FILINGS.md`
  // F-1's lesson, in one line: *the promoter's soundness must not rest on a
  // conjunct that lives in another file and was cleared for a different purpose.*
  // Its second job is to make `applyBank` SIMPLE: with one store the rewrite has
  // one available value to register and one store to relocate, so the
  // several-stores-per-activation `SSAUpdater` merge that used to sit there — dead
  // on the merged binary, untested, and one widening away from becoming live — is
  // gone rather than dormant.
  // ⚠ RETIREMENT TRIGGER, and it names what is OWED rather than what is allowed:
  // the day C4 (or this clause) admits a two-writer bank, `applyBank` needs the
  // several-stores merge BACK — register the last cell store of every block, take
  // the canonical store by dominance among them, and land it together with a
  // red-green pair whose accept has two stores in one activation and whose
  // adversarial probe puts them in sibling arms. Do not widen one without the
  // other; the `git` history at this commit carries the deleted spelling.
  if (Plan.Stores.size() != 1)
    return false;
  // B8 — nothing to forward means nothing to do; leave the module byte-untouched.
  if (Plan.Loads.empty())
    return false;

  // B1/B3 — the loop shape the single trailing store needs.
  Plan.Header = Plan.L->getHeader();
  Plan.Latch = Plan.L->getLoopLatch();
  if (!Plan.Header || !Plan.Latch || !Plan.L->getLoopPreheader())
    return false;
  // B3 — NO EARLY EXIT. The activation's write is placed at the latch, so a path
  // that leaves the loop without reaching the latch would DROP a write the source
  // performed — and the measure loop that follows makes that write observable.
  if (Plan.L->getExitingBlock() != Plan.Latch)
    return false;
  // The initializer must be PROVEN to be in effect when the loop starts. Asked
  // with dominance rather than assumed from "it is in the entry block".
  for (Instruction *I : Inits)
    if (!DT.dominates(I, Plan.L->getLoopPreheader()->getTerminator()))
      return false;

  // B2 — ONE CELL PER ACTIVATION. `b[i]` beside `b[i+1]` is refused: `b[i+1]`'s
  // write would be trip `i+1`'s SEED, and "the cell starts at the initializer"
  // is the premise this entire stage rests on. SCEV equality is the right
  // question (SCEVs are uniqued, so pointer comparison IS semantic equality
  // here) and it is strictly stronger than comparing gep operands, which would
  // miss `b[i]` written as `b[i+1-1]`.
  const SCEV *Addr = SE.getSCEV(Plan.Geps.front());
  for (GetElementPtrInst *G : Plan.Geps)
    if (SE.getSCEV(G) != Addr)
      return false;

  // The canonical gep/store — the activation's single write (B9), whose `!dbg`,
  // alignment and `!tbaa` the relocated store inherits so `kMsgStore` keeps firing
  // at the source line the author wrote. ⚠ This used to pick the dominance-last of
  // several; that selection is gone with the several-stores merge (B9's retirement
  // trigger says what to restore and what test is then owed).
  Plan.CanonStore = Plan.Stores.front();
  Plan.CanonGep = cast<GetElementPtrInst>(Plan.CanonStore->getPointerOperand());

  // B7 — MATERIALISABLE AT THE LATCH. Asked explicitly rather than argued:
  // "obviously dominates" is how a use-before-def gets into a Release build
  // (`MergePhiPeel::condRemintableAt`'s own note).
  Instruction *Term = Plan.Latch->getTerminator();
  for (Value *Op : Plan.CanonGep->operands())
    if (auto *OI = dyn_cast<Instruction>(Op))
      if (!DT.dominates(OI, Term))
        return false;

  // The SEED. `Constant::getNullValue` for BOTH admitted initializer shapes —
  // the carve has already proven which (a whole-object constant-zero memset, or
  // none at all: owner ruling D1, composing with bd `z9t1`).
  Plan.Seed = Constant::getNullValue(Plan.CellTy);
  return true;
}

// ── THE REWRITE (infallible; every precondition is proven above) ────────────
void applyBank(BankPlan &Plan) {
  Function *F = Plan.Bank->getFunction();
  LLVMContext &Ctx = F->getContext();

  SSAUpdater SSA;
  SSA.Initialize(Plan.CellTy, "cq.bank");

  // PASS A — the available values. The HEADER is registered UNCONDITIONALLY (the
  // activation's store value if the store IS in the header, else the seed), and
  // that is the whole per-activation containment proof: `SSAUpdater` stops its
  // predecessor walk at a block with an available value, and the header is the
  // only block of a natural loop whose predecessors leave `L` or cross the back
  // edge. See `RailBankPromote.h`.
  //
  // ⚠ TWO REGISTRATIONS, NOT A WALK OVER `L->blocks()`, BECAUSE B9 PROVES THERE IS
  // EXACTLY ONE STORE (merge filing F-2). The per-block form carried an
  // `SSAUpdater` merge of several stores per activation that nothing in the tree
  // could reach — unreachable rather than merely untested, since the carve's C4
  // refuses a multi-store bank before B6 even returns — and dead code that becomes
  // live under a widening, with no test behind it, is the thing F-2 asks not to be
  // left lying around. B9's retirement trigger carries what to restore.
  StoreInst *TheStore = Plan.Stores.front();
  SSA.AddAvailableValue(TheStore->getParent(), TheStore->getValueOperand());
  if (TheStore->getParent() != Plan.Header)
    SSA.AddAvailableValue(Plan.Header, Plan.Seed);

  // PASS B — every intra-activation load becomes the dominating definition. The
  // in-block ordering is hand-rolled (the part `LoadAndStorePromoter` hand-rolls
  // too); φ PLACEMENT is `SSAUpdater`'s and is not hand-rolled.
  //
  // ⚠ The `Parent == Header` arm is NOT an optimisation. `GetValueInMiddleOfBlock`
  // on the header would walk the header's predecessors — preheader AND LATCH —
  // and build a φ carrying the PREVIOUS ACTIVATION's value: the naive
  // element-type rewrite's defect in another spelling. That query is never made.
  SmallVector<Instruction *, 16> FoldSeeds;
  for (LoadInst *L : Plan.Loads) {
    Value *Def = nullptr;
    for (Instruction *P = L->getPrevNode(); P; P = P->getPrevNode())
      if (auto *SI = dyn_cast<StoreInst>(P))
        if (isCellMemop(SI, Plan.Bank)) {
          Def = SI->getValueOperand();
          break;
        }
    if (!Def)
      Def = (L->getParent() == Plan.Header)
                ? static_cast<Value *>(Plan.Seed)
                : SSA.GetValueInMiddleOfBlock(L->getParent());
    // Collect the users BEFORE the RAUW: PASS F re-asks the constant folder of
    // exactly the instructions whose operands this stage turned into constants,
    // which is the only reason any folding happens here at all.
    if (isa<Constant>(Def))
      for (User *U : L->users())
        if (auto *UI = dyn_cast<Instruction>(U))
          FoldSeeds.push_back(UI);
    L->replaceAllUsesWith(Def);
  }

  // PASS C — the activation's final value.
  //
  // `GetValueAtEndOfBlock` and not `…InMiddleOf…`: if the latch itself holds a
  // store, PASS A registered that store's value as the latch's available value
  // and this must read it, not the live-in.
  Value *Final = SSA.GetValueAtEndOfBlock(Plan.Latch);

  // PASS D — exactly ONE store per activation, at the activation's end.
  //
  // The gep is CLONED rather than reused, which is both the `-O1` target shape
  // (`L1_promoted_store.c` emits a fresh `getelementptr` immediately above its
  // store) and the only spelling with ONE code path: an existing access gep may
  // sit in any block of `L`, and one that does not dominate the latch cannot be
  // reused at all. `Instruction::clone` copies the indices, the `inbounds` flag
  // and the `!dbg`.
  Instruction *Term = Plan.Latch->getTerminator();
  auto *Addr = cast<GetElementPtrInst>(Plan.CanonGep->clone());
  Addr->setName("cq.bank.addr");
  Addr->insertBefore(Term);
  auto *NewStore =
      new StoreInst(Final, Addr, /*isVolatile=*/false, Plan.CanonStore->getAlign(),
                    Term);
  // ⚠ The `!dbg` is the ORIGINAL store's, deliberately. This stage moves a write
  // it does not own the source location of, and the surviving store is still the
  // write the author wrote — so `declineTaintEscapes`' `kMsgStore` keeps firing
  // at the same source line and column. A LOST `!dbg` is invisible to every
  // other gate in the tree and is a regression on its own terms.
  NewStore->setDebugLoc(Plan.CanonStore->getDebugLoc());
  if (MDNode *TB = Plan.CanonStore->getMetadata(LLVMContext::MD_tbaa))
    NewStore->setMetadata(LLVMContext::MD_tbaa, TB);

  // PASS E — erase, COLLECT-THEN-MUTATE.
  //
  // ⚠ bd memory `DCE-under-block-iterator-loopphi-uaf`: an inline
  // `RecursivelyDeleteTriviallyDeadInstructions` under `make_early_inc_range`
  // crashes across a loop-φ back edge, because the deleted operand is not
  // dominated by the deleting iterator's position. This stage operates INSIDE A
  // LOOP BODY, which is that hazard's exact home, so there is no recursive
  // deletion here at all: the worklist is closed and bounded (loads, then their
  // stores, then the geps that are dead BECAUSE of those two), it was collected
  // before any mutation, and every entry is held through a `WeakTrackingVH` so a
  // pointer that somehow died earlier is skipped rather than dereferenced.
  SmallVector<WeakTrackingVH, 16> Dead;
  for (LoadInst *L : Plan.Loads)
    Dead.push_back(L);
  for (StoreInst *S : Plan.Stores)
    Dead.push_back(S);
  for (WeakTrackingVH &V : Dead)
    if (auto *I = dyn_cast_or_null<Instruction>(static_cast<Value *>(V))) {
      I->replaceAllUsesWith(PoisonValue::get(I->getType()));
      I->eraseFromParent();
    }
  for (GetElementPtrInst *G : Plan.Geps)
    if (G->use_empty())
      G->eraseFromParent();

  // PASS F — CONSTANT-FOLD the users this stage turned constant, and nothing
  // else.
  //
  // WHY IT IS HERE AND NOT LEFT TO SOMEONE ELSE: the seed load's `-O1` consumer
  // is a `trunc nuw i8 %seed to i1`, and after the forwarding that is `trunc nuw
  // i8 0 to i1`. Folding it is what makes the arm's theta read a LITERAL
  // (`@cq_theta_i1(i1 false, …)`) — byte-for-byte the `-O1` target shape, which
  // is this stage's stated contract. It also keeps the promoted module free of
  // untainted residue that would otherwise have to be adjudicated by stages that
  // have no reason to see it.
  //
  // WHY IT IS THE WEAKEST POSSIBLE FOLDER: `ConstantFoldInstruction` only ever
  // replaces an instruction ALL of whose operands are already constants. It is
  // not InstCombine, it is seeded ONLY from the users of a load this stage
  // replaced with a Constant, and it propagates no further than constants reach.
  //
  // ⚠ PHI NODES ARE DELIBERATELY EXCLUDED. `ConstantFoldInstruction` does fold a
  // φ all of whose incomings are one constant — legally — but a φ here is a
  // LOOP-CARRIED φ, and erasing one from inside a worklist seeded by a loop-body
  // rewrite is the `DCE-under-block-iterator-loopphi-uaf` hazard a second time.
  // Refusing it can only leave an un-folded constant φ standing, which is the
  // safe direction and costs nothing this stage's contract asks for.
  SmallPtrSet<Instruction *, 16> Seen;
  const DataLayout &DL = F->getParent()->getDataLayout();
  while (!FoldSeeds.empty()) {
    Instruction *I = FoldSeeds.pop_back_val();
    if (!Seen.insert(I).second || isa<PHINode>(I))
      continue;
    Constant *C = ConstantFoldInstruction(I, DL);
    if (!C)
      continue;
    for (User *U : I->users())
      if (auto *UI = dyn_cast<Instruction>(U))
        FoldSeeds.push_back(UI);
    I->replaceAllUsesWith(C);
    I->eraseFromParent();
  }

  // ⚠ NO `!cq.railbank` METADATA IS MINTED HERE, AND THAT IS TRACK A'S SHIPPED
  // DECISION, NOT AN OMISSION. `SCOPE_L1a.md` §4.3 designs the record as the
  // FREEZE's membership proof, and the freeze (the D1/D6 doors) is in the
  // deferred half together with the taint rule and the type rewrite. Minted now
  // it would have NO READER — Rule 12 hygiene defect (c) in its purest form, a
  // subject that does not exist yet — so it is the TYPE REWRITER's to mint next
  // session, being the only stage that both proves the bank and mutates it
  // (`trackA/SIGNATURE.md`, deviation (2)).
  //
  // ⚠ CLAUSE B8 IS THEREFORE LOAD-BEARING FOR TERMINATION, not only for "is it
  // worth doing". The caller drives this stage to a fixpoint and the stage ADDS a
  // store, so something must stop it re-promoting its own output. That something
  // is B8: `applyBank` replaces EVERY in-`L` load, so after a promotion the write
  // loop contains none, and `planBank` refuses on the next turn. RETIREMENT
  // TRIGGER: weaken B8 (for instance to admit a bank with no load, which is a
  // no-op today) and the fixpoint DOES NOT TERMINATE — reinstate a membership
  // record in the same change.
  // PASS G — SINK THE STORAGE CAST OUT OF THE ARM (bd `xdu2` W1 piece 2, the
  // `i8`/`i1` RESIDUAL).
  //
  // THE PROBLEM, MEASURED. A `_Bool` cell's C storage type is `i8` while the
  // rail is `i1`, so `clang -O1` puts a `zext i1 %theta to i8` INSIDE THE ARM
  // and PASS A builds the merge phi at the CELL type. That cast is a tainted
  // value-producing op in a region arm, so `classifyArms` reads the region as a
  // VALUE ARM and the module declines `cq controlled lowering: value-arm
  // swap-route under quantum control`, ANCHORED AT THE `zext` ITSELF (probe
  // `derived/B2_nostore.ll`). With the phi at the RAIL type and no cast in the
  // arm the same module gets past it (`derived/B3_i1cell_nostore.ll`).
  //
  // WHY THE CAST CANNOT SIMPLY BE DELETED. `store i1` into an `i8` cell makes
  // the carve answer `NotBank` at the PUN FENCE (`QramLowering.cpp`,
  // `StoreVal->getType() != CellTy`), whose header carries a RETIREMENT TRIGGER
  // IN BOTH DIRECTIONS: it and `matchQramAccess`'s twin are one fence with two
  // spellings and neither moves without the other. So the cast is SUNK to the
  // activation-end store instead — measured `Bank`, `cells=3 abi=i8 trips=3`
  // (`derived/B7_i1phi_zextsunk_store.ll`) — and the fence is untouched.
  //
  // ⚠ IT FIRES ONLY WHEN THE STORE'S VALUE IS A `phi`, i.e. ONLY ON THE
  // CONDITIONAL-ARM SHAPE, WHICH IS ENTIRELY THE DECLINING POPULATION TODAY.
  // An unconditional per-trip prep has no phi and its cast already sits
  // directly in front of the store; nothing is narrowed and the module is
  // byte-unchanged. That is why this rewrite cannot move any accept: it can
  // only move a decline STRING (wall 2 → wall 3).
  //
  // ⚠ CORRECTION (Rule-13 review item I-2, 2026-09-15): THE `phi` TEST IS NOT
  // WHAT CARRIES "cannot move an accept". The load-bearing premise is that
  // BOTH condition classes for a conditional bank store decline today, and
  // both were measured separately: a CLASSICAL condition dies at
  // `cq taint escape: tainted value muxed by a classical-condition phi`
  // (probes `b01`/`b02`), a TAINTED one at `cq controlled lowering: condition
  // predates a non-diagonal gate` (probes `c01`/`c02`). Neither is a property
  // of this sink, and either could move — bd `wx8g` already landed the in-loop
  // rolled bool-controlled prep, and the 2c fence is on CLAUDE.md §5's
  // over-decline list. RETIREMENT TRIGGER: **the day a conditional bank store
  // accepts, re-derive this claim from scratch; the `phi` test alone does not
  // carry it.** That landing also owes the two obligations below.
  //
  // ⚠ AND IT MANUFACTURES THE VALUE PASS 3 REFUSES TO WRITE — a LATENT P1,
  // gated by exactly that trigger (review item I-3). The `addIncoming` below
  // builds `Constant::getNullValue(RailTy)` for every non-`zext` incoming, so
  // after the type rewrite the ¬arm parks HANDLE `0` IN A CELL. PASS 3 of the
  // rewrite deletes the zero initializer rather than rescaling it for precisely
  // this reason, in its own words: *"a RESCALED memset would write handle `0`
  // into every cell, and handle `0` IS A LIVE RAIL in this runtime
  // (`cqrt_alloc_i1(0) -> h0`)"*. The same live rail, arriving by a different
  // door, protected by nothing that knows about it. When a conditional bank
  // store accepts, the ¬arm owes a REAL `|0>` rail (a fresh `cqrt_alloc`), not
  // the literal 0 — and PASS 3's comment and this one must be read together.
  //
  // ⚠ THIRD OBLIGATION OF THE SAME LANDING (review F-1's fix): with a `phi`
  // store value, `railBankParkedRails` seeds the stale fence AT THE `phi` and
  // walks only its forward users, and `recordBarrierCutsPath`'s barrier stops
  // being the store. Both are stated at the call site in `OpcodeLowering.cpp`.
  //
  // ⚠ THE EQUIVALENCE IS `trunc(zext(x)) == x` AND `trunc(0) == 0`, and it is
  // exact only because every incoming is a ZERO-extension from ONE common rail
  // type or the zero constant, and every other user is the matching truncation.
  // `sext` would be equally exact and is deliberately NOT admitted: `-O1` does
  // not emit it for a `_Bool` cell, so admitting it would widen the population
  // past the one this was measured on.
  //
  // RETIREMENT TRIGGER: the sink exists so the arm classifies as a state prep
  // AND so the pun fence stays untouched. If `RailBankShape::ElemAbi` ever
  // carries the RAIL width, or the pun fence learns a cast, RE-DERIVE THIS FROM
  // SCRATCH — the sink is then doing nothing and the cast is free to reach
  // `lowerOps` and mint a second, entangled rail per cell (measured:
  // `probes/b09_bool_zext_to_int.c` → `cq_template_zext_i1_to_i32(h0) -> h1`).
  if (auto *P = dyn_cast<PHINode>(Final)) {
    Type *RailTy = nullptr;
    bool Narrowable = true;
    for (unsigned i = 0, e = P->getNumIncomingValues(); i != e && Narrowable; ++i) {
      Value *In = P->getIncomingValue(i);
      if (auto *Z = dyn_cast<ZExtInst>(In)) {
        Type *T = Z->getOperand(0)->getType();
        if (RailTy && RailTy != T)
          Narrowable = false;
        else
          RailTy = T;
        continue;
      }
      auto *C = dyn_cast<ConstantInt>(In);
      if (!C || !C->isZero())
        Narrowable = false;
    }
    if (!RailTy || RailTy == P->getType())
      Narrowable = false;
    SmallVector<TruncInst *, 4> Truncs;
    if (Narrowable)
      for (User *U : P->users()) {
        if (U == NewStore)
          continue;
        auto *TR = dyn_cast<TruncInst>(U);
        if (!TR || TR->getType() != RailTy) {
          Narrowable = false;
          break;
        }
        Truncs.push_back(TR);
      }
    if (Narrowable) {
      auto *NP = PHINode::Create(RailTy, P->getNumIncomingValues(), "cq.bank", P);
      NP->setDebugLoc(P->getDebugLoc());
      SmallVector<Instruction *, 4> DeadZexts;
      for (unsigned i = 0, e = P->getNumIncomingValues(); i != e; ++i) {
        Value *In = P->getIncomingValue(i);
        if (auto *Z = dyn_cast<ZExtInst>(In)) {
          NP->addIncoming(Z->getOperand(0), P->getIncomingBlock(i));
          DeadZexts.push_back(Z);
        } else {
          NP->addIncoming(Constant::getNullValue(RailTy),
                          P->getIncomingBlock(i));
        }
      }
      for (TruncInst *TR : Truncs) {
        TR->replaceAllUsesWith(NP);
        TR->eraseFromParent();
      }
      auto *Sunk = new ZExtInst(NP, P->getType(), "cq.bank.stg", NewStore);
      Sunk->setDebugLoc(NewStore->getDebugLoc());
      NewStore->setOperand(0, Sunk);
      P->eraseFromParent();
      for (Instruction *Z : DeadZexts)
        if (Z->use_empty())
          Z->eraseFromParent();
    }
  }

  (void)Ctx;
  if (::getenv("CQ_RAILBANK_DBG"))
    errs() << "CQ_RAILBANK_DBG: promote bank %" << Plan.Bank->getName() << " in @"
           << F->getName() << " header %" << Plan.Header->getName()
           << " cells=" << Plan.Count
           << " cell=" << Plan.ElemAbi << " seed=zero loads=" << Plan.Loads.size()
           << " stores=" << Plan.Stores.size() << "\n";
}

}  // namespace

bool promoteRailBankCells(Module &M, const TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Cheap pre-filter before any analysis is built: no candidate alloca, no
    // work. `DominatorTree`/`LoopInfo`/`ScalarEvolution` are built LAZILY for
    // exactly the same measured reason `detectControlRegions` and
    // `MergePhiPeel` build theirs lazily — an unconditional tree costs ~60ms per
    // invocation on a libm slice whose functions mostly have nothing to claim,
    // and the census corpus is full of such modules.
    bool AnyCandidate = false;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (!A->isArrayAllocation() && isa<ArrayType>(A->getAllocatedType())) {
          AnyCandidate = true;
          break;
        }
    if (!AnyCandidate)
      continue;

    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;  // every clause needs an enclosing loop (C2' is an add-rec).
    // The `LoopUnrollPrepass.cpp:238-242` direct-construction idiom (itself
    // copied from `LoopLowering.cpp:4160-4165`): a default `TargetLibraryInfoImpl`
    // is a conservative TLI, sufficient for SCEV's trip-count reasoning.
    //
    // ⚠ `TaintPropagation.cpp:1861-1863` warns that "a `LoopInfo` built
    // mid-fixpoint would describe a loop the next iteration reshapes", and this
    // stage is inside a fixpoint — so the answer is stated rather than inherited:
    // this slot is the FIRST normaliser in the pass, above `foldIdentityBitcasts`
    // and far above `unrollConstTripLoops` / `recognizeCtlzIdiomLoops` / the
    // PredMux flattener, so the loops SE describes here are the SOURCE loops and
    // no earlier stage in either entry point reshapes control flow. Within this
    // stage's own fixpoint the analyses are rebuilt per call, and the rewrite
    // changes NO edge — it inserts and erases instructions only — so even a
    // cached tree would stay valid.
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);

    for (Instruction &I : F.getEntryBlock()) {
      auto *A = dyn_cast<AllocaInst>(&I);
      if (!A)
        continue;
      BankPlan Plan;
      if (!planBank(A, taint, DT, LI, SE, Plan))
        continue;
      applyBank(Plan);
      // ONE BANK PER CALL (the `flattenPredMuxRegions` precedent): return so the
      // caller re-`propagate`s and the next claim sees fresh taint, fresh
      // dominance and a fresh SCEV — no cached identity crosses an erasure
      // (Rule 9).
      return true;
    }
  }
  return false;
}

// ═══════════════════════════════════════════════════════════════════════════
// bd `xdu2` / L-1a Increment W1 — THE SECOND HALF. See `RailBankPromote.h` for
// the three-piece contract and for why they land as ONE commit.
// ═══════════════════════════════════════════════════════════════════════════

namespace {

// The record's name. ONE spelling, in one place.
constexpr char kRailBankMD[] = "cq.railbank";

// The two diagnostics this half owns. Mirrored CHARACTER-FOR-CHARACTER by the
// negative fixtures (Rule 12):
//   * railbank_reject_load_as_branch_cond.ll  → kMsgBankReader
//   * railbank_reject_load_as_gate_control.ll → kMsgBankReader
//   * railbank_reject_load_into_arith.ll      → kMsgBankReader
//   * railbank_reject_rewrite_unexpected_user.ll → kMsgBankRewrite
constexpr char kMsgBankReader[] =
    "cq rail bank: unsupported reader of a rail-bank cell";
constexpr char kMsgBankRewrite[] =
    "cq rail bank: cell type rewrite failed on a proven bank";

void diagnoseBank(Instruction *I, const char *Msg) {
  I->getFunction()->getContext().diagnose(
      DiagnosticInfoUnsupported(*I->getFunction(), Msg, I->getDebugLoc()));
}

// Drop an erased instruction from every taint work-list that might still hold
// it, so a later module walk never dereferences freed memory. The house
// `scrubTaint` (AngleSelectEmit / SelectMergeEmit / ClassicalCallArmEmit), in
// its rail-bank spelling: the erased classes here are a STORAGE CAST (a
// `CastInst`) and nothing else, so the CallInst arms of the sibling scrubs are
// deliberately absent rather than copied.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  taint.HandleWidth.erase(I);
}

}  // namespace

bool isRailBankAlloca(const AllocaInst *AI) {
  return AI && AI->getMetadata(kRailBankMD) != nullptr;
}

Type *railBankRailType(const AllocaInst *AI) {
  MDNode *N = AI ? AI->getMetadata(kRailBankMD) : nullptr;
  if (!N || N->getNumOperands() != 1)
    return nullptr;
  auto *CM = dyn_cast<ConstantAsMetadata>(N->getOperand(0));
  auto *CI = CM ? dyn_cast<ConstantInt>(CM->getValue()) : nullptr;
  if (!CI)
    return nullptr;
  return IntegerType::get(AI->getContext(),
                          static_cast<unsigned>(CI->getZExtValue()));
}

AllocaInst *railBankOfPointer(Value *P) {
  if (!P)
    return nullptr;
  auto *AI = dyn_cast<AllocaInst>(getUnderlyingObject(P));
  return isRailBankAlloca(AI) ? AI : nullptr;
}

Value *bankStoreRailValue(StoreInst *SI, Type *CellT) {
  Value *SV = SI->getValueOperand();
  if (auto *C = dyn_cast<CastInst>(SV))
    if (CellT && C->getDestTy() == CellT && C->getSrcTy()->isIntegerTy())
      return C->getOperand(0);
  return SV;
}

bool railBankParkedRails(Value *V, SmallVectorImpl<Value *> &Out) {
  auto *LD = dyn_cast<LoadInst>(V);
  if (!LD)
    // D5 entry (2): on a `_Bool` bank the C storage type is `i8` and the rail
    // `i1`, so the value the reader actually names is the storage TRUNCATION,
    // not the load. Recognised by the SAME shape entry (2) admits, and nothing
    // wider: a `zext`/`sext`/`bitcast` reader is not on the allow-list and the
    // module declines before this question is ever asked.
    if (auto *TR = dyn_cast<TruncInst>(V))
      LD = dyn_cast<LoadInst>(TR->getOperand(0));
  if (!LD)
    return false;
  AllocaInst *Bank = railBankOfPointer(LD->getPointerOperand());
  if (!Bank)
    return false;
  Type *CellT = nullptr;
  if (auto *AT = dyn_cast<ArrayType>(Bank->getAllocatedType()))
    CellT = AT->getElementType();
  // The OBJECT'S ADDRESS TREE, not a scan of the function. A `Bank` alloca's
  // every user is a canonical cell access, a lifetime marker or the initializer
  // (carve clause C1), so the stores are reachable from the alloca through gep
  // and cast hops alone — and C1 is what makes that enumeration complete rather
  // than merely plausible.
  SmallVector<Value *, 8> WL{Bank};
  SmallPtrSet<Value *, 8> Seen;
  while (!WL.empty()) {
    Value *P = WL.pop_back_val();
    if (!Seen.insert(P).second)
      continue;
    for (User *U : P->users()) {
      if (isa<GetElementPtrInst>(U) || isa<BitCastInst>(U) ||
          isa<AddrSpaceCastInst>(U)) {
        WL.push_back(cast<Value>(U));
        continue;
      }
      auto *SI = dyn_cast<StoreInst>(U);
      if (!SI || SI->getPointerOperand() != P)
        continue;
      Value *R = bankStoreRailValue(SI, CellT);
      // ⚠ A CONSTANT IS NEVER A SEED, AND THE REASON IS LLVM'S, NOT OURS.
      // Constants are UNIQUED MODULE-WIDE, so handing `i8 0` — the whole-object
      // zero initializer C1 admits, or a `false` arm incoming PASS G builds —
      // to a walker that follows USER edges enumerates every unrelated use of
      // that literal in the module and can return a `cq_theta` on a wire this
      // bank never touched. That would be an OVER-DECLINE MANUFACTURED BY THE
      // SEED rather than found in the program. A constant also parks no rail:
      // it has no wire, so there is nothing for a later gate to stale.
      if (!isa<Constant>(R))
        Out.push_back(R);
    }
  }
  return true;
}

bool railStoredToRailBank(const Value *H) {
  if (!H)
    return false;
  for (const User *U : H->users())
    if (const auto *SI = dyn_cast<StoreInst>(U))
      if (SI->getValueOperand() == H &&
          railBankOfPointer(const_cast<Value *>(SI->getPointerOperand())))
        return true;
  return false;
}

bool markRailBankAllocas(Module &M, const TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // The same cheap pre-filter `promoteRailBankCells` uses, for the same
    // measured reason: an unconditional DominatorTree costs ~60ms per
    // invocation on a census slice with nothing to claim.
    bool AnyCandidate = false;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (!A->isArrayAllocation() && isa<ArrayType>(A->getAllocatedType())) {
          AnyCandidate = true;
          break;
        }
    if (!AnyCandidate)
      continue;
    DominatorTree DT(F);
    LoopInfo LI(DT);
    if (LI.empty())
      continue;  // a bank store is ALWAYS in a loop (the carve's own conjunct).
    AssumptionCache AC(F);
    TargetLibraryInfoImpl TLII(Triple(M.getTargetTriple()));
    TargetLibraryInfo TLI(TLII);
    ScalarEvolution SE(F, TLI, AC, DT, LI);
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI)
          continue;
        const char *Msg = nullptr;
        RailBankShape Shape;
        // ⚠ `Bank` AND NOTHING ELSE. `BankRaw` is the promoter's input and must
        // keep declining (`trackA/SIGNATURE.md` §3/§4); a `Reject*` keeps its
        // own per-clause diagnostic at `declineTaintEscapes`, which is the ONE
        // site that diagnoses — this stage NEVER diagnoses, so a bank it cannot
        // claim is left byte-untouched for its existing loud owner (the
        // accept-only normaliser discipline).
        // ── THE A×B COMPOSITION, ANSWERED HERE (2026-09-14c `MERGE_FILINGS.md`
        //    F-1, re-derived by the Rule-13 review of 2026-09-15).
        //
        // F-1 asked that C2′, C4 and C6 be re-derived as PRECONDITIONS OF
        // `applyBank` rather than inherited as clauses of a classifier. The
        // structural answer is stronger than F-1 feared and it is THIS LOOP:
        // the full carve runs AGAIN, on the module AFTER the promoter's fixpoint
        // has settled, and mints only on `RailBankCarve::Bank`. So every
        // precondition the type rewrite and the D5 allow-list rest on is
        // RE-PROVEN ON `applyBank`'s OUTPUT — Rule 11 applied to a sibling stage
        // instead of trust.
        //   * C2′ (non-self-wrapping affine `{0,+,1}`, constant trips ≤ N) —
        //     re-proven here, on the promoter's own cloned latch gep. It is what
        //     makes "each cell written once" true for PASS 2's index-preserving
        //     retype.
        //   * C4 (exactly one store site) — re-proven here. ⚠ `applyBank` ADDS a
        //     store, so the input's C4 and the output's C4 are different facts
        //     about different modules; both are checked, in that order.
        // ⚠ C6 IS THE SEAM AND IT IS NOT FULLY RE-PROVEN. Its COUNTING half
        // (`Trips == N`) does re-prove here, and that is the half PASS 3 leans
        // on when it DELETES the initializer. Its IN-LOOP-READ half is VACUOUS
        // on this module, because `applyBank` PASS B has already erased every
        // in-`L` load: the forwarding PASS B performed is licensed by the INPUT
        // carve alone, and this mint cannot re-check it — THE EVIDENCE WAS
        // CONSUMED. That is not a defect (B6's `BankRaw` requirement is exactly
        // that proof, taken while the loads still existed), but it is the one
        // precondition established ONCE and thereafter UNFALSIFIABLE, and it is
        // where T1/T3's "widen the promoter and C7 in the same change"
        // obligation actually bites. RETIREMENT TRIGGER: any widening of the
        // promoter's read handling must re-establish the in-loop-read half at
        // its own site, because nothing downstream of `applyBank` can.
        if (railBankCarveVerdict(SI, taint, DT, LI, SE, Msg, &Shape) !=
            RailBankCarve::Bank)
          continue;
        if (!Shape.Alloca || isRailBankAlloca(Shape.Alloca))
          continue;
        // ⚠ THE RECORD CARRIES THE **RAIL** WIDTH, NOT THE CELL WIDTH, AND
        // THE TWO DIFFER FOR EXACTLY THE OWNER'S SPELLING. A `_Bool` cell's C
        // storage type is `i8` while the rail is `i1`, and `clang -O1` bridges
        // them with a storage EXTENSION cast on the store side and a storage
        // TRUNCATION cast on the read side. Both casts are erased by the type
        // rewrite, so BOTH the D5 allow-list and the rewrite must be able to
        // tell a STORAGE cast from a cast the user wrote — and after
        // `lowerRotations`' cross-type RAUW the extension cast reads
        // `zext i32 %h to i8` and its original source type is UNRECOVERABLE.
        // So the width is captured HERE, pre-lowering, where the store's value
        // operand still names it.
        //
        // ⚠ THE OVER-ACCEPT THIS CLOSES WAS MEASURED, NOT ANTICIPATED
        // (`probes/d5g_width_pun_measure.c`). `int b0[3]` with
        // `cq_measure((short) b0[i])` gave a rail minted `cqrt_alloc_i32` and
        // MEASURED `cqrt_measure_i16` — the truncation GATE dropped entirely.
        // The scalar twin (`probes/d5h_scalar_width_pun.c`, no array anywhere)
        // emits `cq_template_trunc_i32_to_i16(h0) -> h1` and measures the NEW
        // rail, on this binary AND on the ORACLE. A bank must not lose a gate
        // the register spelling emits.
        // ⚠ ASKED BY CALLING `bankStoreRailValue`, WHICH IS ALSO WHAT THE STALE
        // FENCE'S MEMORY HOP SEEDS FROM (Rule 14, and the Rule-13 review's I-4
        // is this file's own cautionary instance of the alternative). The record
        // carries that value's WIDTH; `railBankParkedRails` carries the VALUE.
        // One relation, one implementation — a width that disagreed with the
        // seed would let the fence walk a wire the record does not describe.
        Type *CellT = Shape.CellTy;
        Type *RailT = bankStoreRailValue(SI, CellT)->getType();
        Shape.Alloca->setMetadata(
            kRailBankMD,
            MDNode::get(F.getContext(),
                        {ConstantAsMetadata::get(ConstantInt::get(
                            Type::getInt32Ty(F.getContext()),
                            RailT->getIntegerBitWidth()))}));
        Changed = true;
        if (::getenv("CQ_RAILBANK_DBG"))
          errs() << "CQ_RAILBANK_DBG: mark bank %" << Shape.Alloca->getName()
                 << " in @" << F.getName() << " cells=" << Shape.Count
                 << " cell=" << Shape.ElemAbi
                 << " rail=i" << RailT->getIntegerBitWidth() << "\n";
      }
  }
  return Changed;
}

namespace {

// Is `U` an admitted reader of the rail-bank cell load `LD`? THE POSITIVE
// ALLOW-LIST — see `RailBankPromote.h`. Everything this returns false for is a
// loud decline; there is no third answer.
bool isAdmittedRailBankReader(const Instruction *U, const LoadInst *LD,
                              Type *RailTy,
                              const SmallPtrSetImpl<const CallInst *> &Measures) {
  // (1) the measurement sink itself. EXACT MEMBERSHIP of the collected
  //     `@cq_measure_<sfx>` call sites, never a `starts_with("cq_measure_")`
  //     prefix — prefix-on-accept is spoofable and an opaque `cq_measure_evil`
  //     would confer ownership of a live rail (the `ArmClassify` G10 / `soleMeasure`
  //     discipline, copied deliberately).
  //     ⚠ AND ITS OPERAND TYPE MUST BE THE **RAIL** TYPE. A direct measure of
  //     the load is admissible only when the cell type IS the rail type (an
  //     `int` bank). On a `_Bool` bank the cell is `i8` and the rail `i1`, so a
  //     measure reading the `i8` load directly is `cq_measure((char) b0[i])` —
  //     whose register spelling emits a real `cq_template_zext_i1_to_i8` GATE
  //     and measures the NEW rail. Admitting it here would DROP that gate.
  if (const auto *CI = dyn_cast<CallInst>(U))
    return Measures.count(CI) != 0 && LD->getType() == RailTy;
  // (2) the storage-TRUNCATION cast `-O1` emits because the C storage type of a
  //     `_Bool` cell is `i8` while the rail is `i1`. Single-use, and its one
  //     user must itself be an admitted measure. Piece 2 erases it; at D5 time
  //     it is still standing, which is why this entry exists at all.
  //     ⚠ AND ITS DESTINATION MUST BE THE **RAIL** TYPE, WHICH IS THE WHOLE
  //     FENCE. A `trunc` to any OTHER width is a truncation the user wrote, and
  //     the register spelling of that program emits
  //     `cq_template_trunc_<from>_to_<to>` — a real reversible gate minting a
  //     NEW rail, which is then what gets measured. MEASURED both ways
  //     (`probes/d5g` vs `probes/d5h`): without this conjunct `int b0[3]` with
  //     `cq_measure((short) b0[i])` minted `cqrt_alloc_i32` and measured
  //     `cqrt_measure_i16`, dropping the gate. A bank must never lose a gate
  //     the register spelling emits.
  if (const auto *TR = dyn_cast<TruncInst>(U)) {
    if (TR->getOperand(0) != LD || !TR->hasOneUse() || TR->getType() != RailTy)
      return false;
    const auto *One = dyn_cast<CallInst>(*TR->user_begin());
    return One && Measures.count(One) != 0;
  }
  // ⚠ THERE IS NO ENTRY (3), AND ITS ABSENCE IS A MEASUREMENT RATHER THAN AN
  //   OVERSIGHT.  `SCOPE_B.md` §5.1 designed a third entry — *a further store
  //   into a `!cq.railbank` cell* (a bank-to-bank copy of the rail NAME: no
  //   gate, no clone).  It was implemented, and then it was measured to have NO
  //   REACHABLE SUBJECT AT THE `-O1` FLOOR: on
  //   `trackB/probes/d5d_bank_to_bank_copy.c` (`for (i<3) b1[i] = b0[i];`
  //   between the write loop and the measure loop) `clang -O1` FORWARDS the
  //   copy and DELETES the second array outright, so the module that reaches
  //   this pass has exactly ONE bank and the entry never fires.  Pinned by
  //   `railbank_accept_bank_copy_folded.ll`.
  //
  //   An allow-list entry with no customer is Rule 12 hygiene defect (c) in its
  //   purest form — an ACCEPT DOOR in a Prime-Directive fence that no fixture
  //   can hold open — so it was REMOVED rather than shipped unpinned.  Removing
  //   it narrows the accept, which is the safe direction: a module that somehow
  //   did carry a surviving bank-to-bank store now declines loudly.
  //
  //   ⚠ AND THE REMOVAL TOOK A CUSTOMER OFF AN OPEN P1 WITH IT.  A surviving
  //   copy makes TWO names denote ONE rail, so measuring both banks emits
  //   `cqrt_measure_i1(h0)` twice on one qubit — bd `yiid`'s shape.  MEASURED
  //   also WITHOUT any bank (`trackB/probes/d5f_scalar_double_measure.c`:
  //   `cq_measure(q) + cq_measure(q)`, no array anywhere, compiles identically
  //   on this binary and on the pre-second-half one), so the boundary is bd
  //   `yiid`'s and not this increment's — but this increment does not add to it
  //   either.
  //
  //   RETIREMENT TRIGGER: the day a `-O1` spelling is found in which a
  //   bank-to-bank store SURVIVES — or the floor stops folding it — re-derive
  //   entry (3) WITH the bd `yiid` question answered, not before.
  return false;
}

}  // namespace

void declineUnallowedRailBankReaders(Module &M, const TaintSet &taint) {
  SmallPtrSet<const CallInst *, 16> Measures;
  Measures.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *LD = dyn_cast<LoadInst>(&I);
        if (!LD)
          continue;
        AllocaInst *Bank = railBankOfPointer(LD->getPointerOperand());
        if (!Bank)
          continue;
        Type *RailTy = railBankRailType(Bank);
        // ⚠ ENUMERATE, NEVER STOP AT THE FIRST MATCH (L4: *a wire question must
        // be a gate SET, not a BOOLEAN over a return-first walker*). The answer
        // is "every user is admitted", so the whole user list is walked and the
        // OFFENDING user is what carries the `!dbg` — putting an admitted
        // consumer in front of an unadmitted one cannot hide the second.
        for (User *U : LD->users()) {
          auto *UI = dyn_cast<Instruction>(U);
          if (!UI) {
            diagnoseBank(LD, kMsgBankReader);  // a ConstantExpr view of the value.
            continue;
          }
          if (RailTy && isAdmittedRailBankReader(UI, LD, RailTy, Measures))
            continue;
          diagnoseBank(UI, kMsgBankReader);
        }
      }
  }
}

namespace {

// Retype ONE proven bank in place. `Fail` is set (and a loud diagnostic fired)
// on anything the rewrite did not expect — NEVER a silent `continue`
// (`SCOPE_B.md` §10 item 2: the rewrite enumerates from the SAME user shapes
// C1's scan proves, and an omission here is silent because the verifier cannot
// see a 4-byte write into a 3-byte object).
//
// ⚠ IN-PLACE MUTATION, NOT REBUILD-AND-RAUW, AND THAT IS DELIBERATE. Every
// `Value *` in `taint` and in the control plan stays valid because no load, gep
// or alloca is replaced — only the STORAGE CASTS are erased, and those are
// scrubbed. Rebuilding the loads would leave freed pointers in tables this
// stage cannot enumerate.
void rewriteOneBank(AllocaInst *AI, TaintSet &taint, bool &Fail) {
  Module &M = *AI->getModule();
  LLVMContext &Ctx = AI->getContext();
  const DataLayout &DL = M.getDataLayout();
  Type *I32 = Type::getInt32Ty(Ctx);
  auto *OldArr = dyn_cast<ArrayType>(AI->getAllocatedType());
  if (!OldArr) {
    diagnoseBank(AI, kMsgBankRewrite);
    Fail = true;
    return;
  }
  auto *NewArr = ArrayType::get(I32, OldArr->getNumElements());

  // Collect first, mutate after: the walks below read `AI->users()` and
  // `GEP->users()`, and PASS 3 erases.
  SmallVector<GetElementPtrInst *, 8> Geps;
  SmallVector<LoadInst *, 8> Loads;
  SmallVector<StoreInst *, 4> Stores;
  SmallVector<Instruction *, 4> Lifetimes;
  SmallVector<Instruction *, 4> Inits;

  auto takeCellUser = [&](User *GU, Value *Ptr) -> bool {
    if (auto *LD = dyn_cast<LoadInst>(GU)) {
      if (LD->getPointerOperand() == Ptr) {
        Loads.push_back(LD);
        return true;
      }
    } else if (auto *ST = dyn_cast<StoreInst>(GU)) {
      if (ST->getPointerOperand() == Ptr) {
        Stores.push_back(ST);
        return true;
      }
    }
    return false;
  };

  for (User *U : AI->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI) {
      diagnoseBank(AI, kMsgBankRewrite);
      Fail = true;
      return;
    }
    if (auto *G = dyn_cast<GetElementPtrInst>(UI)) {
      Geps.push_back(G);
      for (User *GU : G->users())
        if (!takeCellUser(GU, G)) {
          diagnoseBank(cast<Instruction>(GU), kMsgBankRewrite);
          Fail = true;
          return;
        }
      continue;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(UI)) {
      Intrinsic::ID Id = II->getIntrinsicID();
      if (Id == Intrinsic::lifetime_start || Id == Intrinsic::lifetime_end) {
        Lifetimes.push_back(II);
        continue;
      }
      if (Id == Intrinsic::memset || Id == Intrinsic::memset_inline) {
        Inits.push_back(II);
        continue;
      }
      diagnoseBank(II, kMsgBankRewrite);
      Fail = true;
      return;
    }
    if (auto *ST = dyn_cast<StoreInst>(UI)) {
      // The whole-object constant-zero initializer `-O1` spells as
      // `store i64 0, ptr %b` — C1 admits it, and it is DELETED rather than
      // rescaled (see PASS 3).
      //
      // ⚠ ASKED BY CALLING `isWholeObjectZeroStore`, and the first spelling
      // here was a type INEQUALITY (`value type != cell type`) which DIVERGES
      // from the carve on a one-cell bank: for `[1 x i8]` the whole-object zero
      // IS a `store i8 0`, so the carve files it as an Init while the
      // inequality filed it as a CELL STORE — and PASS 4 then hit its loud
      // `kMsgBankRewrite` on a shape the carve had proven. A divergence between
      // a rewrite and the carve that licensed it is the drbq Inc-3 (b') defect
      // in miniature: two spellings of one question.
      //
      // ⚠ CORRECTION (Rule-13 review item I-4, 2026-09-15): THIS IS NOT "THE
      // SAME PREDICATE C1 ASKS", AND THE EARLIER WORDING SAID IT WAS — a
      // Rule-14 property asserted in a Rule-13 core stage four lines above a
      // warning about exactly that. It IS two spellings. C1
      // (`QramLowering.cpp`) asks `wholeArrayConstantZero(DL, value, AT)`:
      // `getTypeStoreSize(valueTy) == getTypeStoreSize(ArrTy)`. This asks
      // `isWholeObjectZeroStore(ST, AI)`: pointer identity AND `isSimple()` AND
      // `getTypeStoreSize(valueTy) == getTypeAllocSize(allocatedTy)`. They agree
      // on every reachable module (for an integer-element array `StoreSize ==
      // AllocSize`), so this is a DOCUMENTATION defect and not a correctness
      // one — but the honest statement is "a STRICTLY STRONGER predicate that
      // agrees with C1 on the reachable population", never "the same predicate".
      // L7-with-a-twist: the correction is landed in the SOURCE, because a
      // correction that lives only in a record gets re-derived next round.
      // RETIREMENT TRIGGER: the day a bank's cells are not an integer type — a
      // pointer, a struct, an `i1` array with a non-byte store size — the two
      // size questions can part company; consolidate them then, in one place.
      if (isWholeObjectZeroStore(ST, AI)) {
        Inits.push_back(ST);
        continue;
      }
    }
    if (!takeCellUser(UI, AI)) {  // the direct zero-offset cell-0 access.
      diagnoseBank(UI, kMsgBankRewrite);
      Fail = true;
      return;
    }
  }

  // PASS 1 — the object. ⚠ SEMANTICALLY LOAD-BEARING AND INVISIBLE TO
  // `opt -verify` (header): an `i32` handle stored into a `[3 x i8]` alloca is
  // a 4-byte write into a 3-byte object and verifies clean under opaque
  // pointers. The alignment must move with the type or every cell access is
  // under-aligned.
  AI->setAllocatedType(NewArr);
  if (AI->getAlign() < DL.getABITypeAlign(I32))
    AI->setAlignment(DL.getABITypeAlign(I32));

  // PASS 2 — the addresses. Both `matchAddressGep` spellings are covered: the
  // array-decay form `[N x cell], base, 0, idx` (source element type is the
  // ARRAY) and the flat element form `cell, base, idx` (source element type is
  // the CELL).
  for (GetElementPtrInst *G : Geps) {
    if (G->getSourceElementType() == OldArr)
      G->setSourceElementType(NewArr);
    else if (G->getSourceElementType() == OldArr->getElementType())
      G->setSourceElementType(I32);
    else {
      diagnoseBank(G, kMsgBankRewrite);
      Fail = true;
      return;
    }
    G->setResultElementType(I32);
  }

  // PASS 3 — the initializer. DELETED, not rescaled, and C6 TOTALITY is what
  // licenses it: every cell is stored before any cell is loaded, so the fill is
  // never observed.
  //
  // ⚠ THE REASON TO PREFER DELETION IS COUNTERFACTUAL, AND SAYING SO IS THE
  // POINT. A RESCALED memset would write handle `0` into every cell, and handle
  // `0` IS A LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`) — so the day
  // C6 is widened to admit a never-written cell, the rescale hands a MEASURE a
  // live rail's handle while the deletion hands it an uninitialised one. WHILE
  // C6 HOLDS the two are indistinguishable, and that was MEASURED rather than
  // argued: injection mutant M8b (rescale instead of delete) was MISSED by every
  // railbank fixture, every railbank e2e slice and stage 2b — the emitted trace
  // is byte-identical either way and `free_pairing_check.py` does not model
  // memory. The ONE instrument in the tree that separates them is the
  // `NOTS-NOT: call void @llvm.memset` negative in
  // `railbank_accept_zeroinit_memset.ll`, written BECAUSE the mutant was missed.
  // RETIREMENT TRIGGER: widen C6's totality and this choice becomes observable —
  // re-derive it then, and do not read "it never fired" as "it does not matter".
  for (Instruction *Init : Inits) {
    Init->eraseFromParent();
  }

  // PASS 3b — the lifetime markers. The object's size changed; a stale constant
  // size would describe a shorter object than the one being written.
  //
  // ⚠ THE `isa<ConstantInt>` TEST HAS NO `else`, WHICH READS LIKE THE SILENT
  // `continue` THIS STAGE'S HEADER FORBIDS. It is not one, and the reason is
  // LLVM'S RATHER THAN THIS STAGE'S (Rule-13 review item I-5, 2026-09-15):
  // `llvm.lifetime.{start,end}.p0`'s size operand is `immarg`, so a
  // non-constant size fails `opt -passes=verify` with *"immarg operand has
  // non-immediate parameter"* and cannot occur in a well-formed module. The
  // VERIFIER OWNS THIS CASE; the test is a `cast`-safety guard, not a policy
  // choice, and the header's "NEVER a silent `continue`" contract is about
  // shapes this stage could meet and chose not to handle. C1 admits these
  // markers unconditionally with no size check, so the two enumerations agree
  // on every module LLVM will build. Saying so at the site is cheaper than a
  // `Fail` arm with no reachable subject (Rule 12 hygiene defect (c)).
  const uint64_t NewSize = DL.getTypeAllocSize(NewArr).getFixedValue();
  for (Instruction *LM : Lifetimes) {
    auto *CI = cast<CallInst>(LM);
    if (isa<ConstantInt>(CI->getArgOperand(0)))
      CI->setArgOperand(0, ConstantInt::get(Type::getInt64Ty(Ctx), NewSize));
  }

  // PASS 4 — the writes. After `lowerRotations` the stored value is either the
  // `i32` handle itself (a cell whose C storage type IS the rail type: `int`
  // cells) or the STORAGE EXTENSION cast standing one hop in front of it (a
  // `_Bool` cell: `zext i1 %theta to i8`, whose operand the cross-type RAUW has
  // already turned into the handle). The cast is erased, NOT lowered: reaching
  // `lowerOps` it becomes `cq_template_zext_i1_to_i8` — a second, entangled
  // rail per cell with the original left allocated.
  SmallVector<Instruction *, 4> DeadCasts;
  for (StoreInst *ST : Stores) {
    Value *V = ST->getValueOperand();
    if (V->getType() != I32) {
      auto *C = dyn_cast<CastInst>(V);
      if (!C || C->getOperand(0)->getType() != I32) {
        diagnoseBank(ST, kMsgBankRewrite);
        Fail = true;
        return;
      }
      ST->setOperand(0, C->getOperand(0));
      DeadCasts.push_back(C);
    }
    ST->setAlignment(DL.getABITypeAlign(I32));
    ST->setMetadata(LLVMContext::MD_tbaa, nullptr);
  }

  // PASS 5 — the reads. The load is MUTATED in place (see the note above), its
  // `!range`/`!tbaa` dropped (a `!range` whose type no longer matches the
  // instruction is a VERIFIER error, not a cosmetic staleness), and its storage
  // TRUNCATION cast folded away — the same cast D5 admits as allow-list entry
  // (2), which is why D5 runs BEFORE this stage and this stage after it.
  Type *RailTy = railBankRailType(AI);
  if (!RailTy) {
    diagnoseBank(AI, kMsgBankRewrite);
    Fail = true;
    return;
  }
  for (LoadInst *LD : Loads) {
    // ⚠ ONLY THE STORAGE TRUNCATION — a `trunc` TO THE RAIL TYPE. A `trunc` to
    // any other width is a truncation the USER wrote, and erasing it would drop
    // the `cq_template_trunc_*` gate the register spelling of the same program
    // emits (measured: `probes/d5g` vs `probes/d5h`). D5 already refuses such a
    // reader, so this is the second of two spellings of one fence — kept
    // because the alternative failure is a DROPPED GATE and is silent.
    for (User *U : llvm::make_early_inc_range(LD->users()))
      if (auto *TR = dyn_cast<TruncInst>(U))
        if (TR->getType() == RailTy) {
          TR->replaceAllUsesWith(LD);
          DeadCasts.push_back(TR);
        }
    LD->mutateType(I32);
    LD->setAlignment(DL.getABITypeAlign(I32));
    LD->setMetadata(LLVMContext::MD_range, nullptr);
    LD->setMetadata(LLVMContext::MD_tbaa, nullptr);
    // The load IS a rail name now (piece 1 tainted it); `lowerMeasures` refuses
    // a tainted operand that is not an `i32` handle, which is exactly what the
    // mutation above supplies.
    taint.HandleWidth.erase(LD);
  }

  // ⚠ ONLY A CAST THAT IS ACTUALLY DEAD. The store side swaps the store's
  // operand and the read side RAUWs the trunc to the load, so both are normally
  // use-free by here — but the STORED VALUE's cast is not constrained to have
  // one user by any clause of the carve, and a cast with a surviving consumer
  // that we erased would leave that consumer reading POISON: verify-clean, and
  // a wrong value at run time. A cast with another user is LEFT STANDING and
  // `lowerOps` lowers it into the `cq_template_*` gate that consumer genuinely
  // wants — the bank stores the raw handle either way, so the two do not fight.
  for (Instruction *C : DeadCasts) {
    if (!C->use_empty())
      continue;
    scrubTaint(C, taint);
    C->eraseFromParent();
  }
}

}  // namespace

void rewriteRailBankCellTypes(Module &M, TaintSet &taint) {
  SmallVector<AllocaInst *, 4> Banks;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (isRailBankAlloca(A))
          Banks.push_back(A);
  }
  bool Fail = false;
  for (AllocaInst *A : Banks) {
    rewriteOneBank(A, taint, Fail);
    if (Fail)
      return;  // `LLVMContext::diagnose` exits on the first DS_Error anyway.
  }
}

}  // namespace cq
