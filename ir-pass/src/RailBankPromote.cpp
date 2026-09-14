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
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/Transforms/Utils/SSAUpdater.h"

#include <cstdlib>
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

}  // namespace cq
