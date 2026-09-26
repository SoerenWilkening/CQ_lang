// scrub_selftest.cpp — deterministic pin of `ScrubOnDelete.h` on EVERY
// pointer-keyed member of `cq::TaintSet` (bd test_C_libtooling-8e5r / -um24 /
// -j8sk). Test-only: built as `cq-scrub-selftest`, linked with the test
// allocator (`cq_debug_alloc.cpp`), never part of `libCQPass.so`.
//
// WHY A SELF-TEST AND NOT ONLY A FIXTURE. A lit fixture can pin the defect only
// through an ALLOCATION COINCIDENCE — a fresh instruction of the right size
// landing on the right freed address at the right time — and any unrelated
// change to the pass's allocation sequence can move that coincidence away while
// the defect stays. This program asks the mechanism directly, per member, with
// the coincidence MANUFACTURED:
//
//   (1) insert a live key X; check it is a member;
//   (2) DELETE X (eraseFromParent / delete), keep only its ADDRESS;
//   (3) the address is not a member — `count`, `find`, `lookup`, `contains`,
//       `size`, `empty` and iteration all agree. Pointer COMPARISON only: the
//       dead address is never dereferenced, so (3) is deterministic under ANY
//       allocator;
//   (4) allocate a fresh object Y of the same kind. Under
//       `CQ_OPT_DEBUG_ALLOC=lifo` it lands at X's address DETERMINISTICALLY
//       (exact-class LIFO reuse), and that is REQUIRED — a run where it did
//       not is reported as a FAILURE, because the aliasing branch would then be
//       vacuous. With Y == X's address: Y is NOT a member (the bd 8e5r property:
//       the unfixed tables answered `true` here), inserting Y is a NEW insertion,
//       a map's value for Y is the DEFAULT and never X's stale value, and a list
//       yields Y exactly ONCE.
//
// A member whose type is reverted to a raw `SmallPtrSet`/`DenseMap`/
// `SmallVector`/`std::set` still COMPILES here (the APIs are compatible) and
// FAILS at (3). `tools/taintset_scrub_guard.py` is the other half: a
// BEST-EFFORT check that catches the common spellings of a NEW raw pointer-keyed
// member this file does not know about (its docstring names the gaps it has —
// bd wop9 / 7gri / jk56).

#include "TaintPropagation.h"

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdlib>
#include <cstring>
#include <iterator>
#include <string>

using namespace llvm;

namespace {

unsigned Checks = 0, Failures = 0, ReuseTried = 0, ReuseHit = 0;
unsigned SkippedBranches = 0, SkippedChecks = 0;
bool StrictReuse = false;

// The aliasing branch of one member did not run because the fresh object did not
// land on the dead address. Under `--require-reuse` that is a FAILURE (the branch
// would be vacuous); otherwise it is COUNTED and reported — never skipped
// silently (Rule-13 r1B F-EB-10).
void skipBranch(unsigned NChecks, const std::string &What);

void expect(bool Ok, const std::string &What) {
  ++Checks;
  if (!Ok) {
    ++Failures;
    errs() << "FAIL: " << What << "\n";
  }
}

void skipBranch(unsigned NChecks, const std::string &What) {
  ++SkippedBranches;
  SkippedChecks += NChecks;
  if (StrictReuse)
    expect(false, What + ": address reuse NOT reproduced under --require-reuse "
                         "(the aliasing branch would be vacuous)");
}

template <typename C> std::size_t iterCount(const C &Cont) {
  return static_cast<std::size_t>(std::distance(Cont.begin(), Cont.end()));
}

struct Fixture {
  LLVMContext Ctx;
  Module M{"scrub_selftest", Ctx};
  Function *G = nullptr;  // declare i32 @g(i32)
  Function *F = nullptr;  // define void @f(i32, ptr)
  BasicBlock *BB = nullptr;
  Argument *A = nullptr, *P = nullptr;

  Fixture() {
    Type *I32 = Type::getInt32Ty(Ctx);
    G = Function::Create(FunctionType::get(I32, {I32}, false),
                         Function::ExternalLinkage, "g", M);
    F = Function::Create(
        FunctionType::get(Type::getVoidTy(Ctx), {I32, PointerType::get(Ctx, 0)}, false),
        Function::ExternalLinkage, "f", M);
    A = F->getArg(0);
    P = F->getArg(1);
    BB = BasicBlock::Create(Ctx, "", F);
    ReturnInst::Create(Ctx, BB);
  }
  Instruction *term() { return BB->getTerminator(); }
  BinaryOperator *mkAdd() { return BinaryOperator::CreateAdd(A, A, "", term()); }
  CallInst *mkCall() { return CallInst::Create(G, {A}, "", term()); }
  PHINode *mkPhi() { return PHINode::Create(A->getType(), 0, "", BB->getFirstNonPHI()); }
  StoreInst *mkStore() { return new StoreInst(A, P, term()); }
  BasicBlock *mkBlock() {
    BasicBlock *B = BasicBlock::Create(Ctx, "", F);
    new UnreachableInst(Ctx, B);
    return B;
  }
  Function *mkFunction() {
    return Function::Create(G->getFunctionType(), Function::ExternalLinkage, "", M);
  }
};

template <typename T> void kill(T *V) { V->eraseFromParent(); }

// One set member. `Mk` returns a fresh key of the member's pointee kind.
template <typename SetT, typename MkT>
void checkSet(const char *Name, SetT &S, MkT Mk) {
  std::string N = Name;
  auto *X = Mk();
  expect(S.insert(X).second, N + ": first insert is new");
  expect(S.count(X) == 1 && S.size() == 1 && !S.empty() && iterCount(S) == 1,
         N + ": live key is a member");
  const void *Addr = X;
  kill(X);
  auto *D = static_cast<decltype(X)>(const_cast<void *>(Addr));  // never dereferenced
  expect(S.count(D) == 0, N + ": deleted key is not counted");
  expect(!S.contains(D), N + ": deleted key is not contained");
  expect(S.find(D) == S.end(), N + ": deleted key is not found");
  expect(S.size() == 0 && S.empty(), N + ": size/empty ignore the deleted key");
  expect(iterCount(S) == 0, N + ": iteration skips the deleted key");
  auto *Y = Mk();
  ++ReuseTried;
  if (static_cast<const void *>(Y) == Addr) {
    ++ReuseHit;
    expect(S.count(Y) == 0, N + ": a FRESH object at the dead address is NOT a member (8e5r)");
    expect(S.insert(Y).second, N + ": inserting the fresh object is a NEW insertion");
    expect(S.count(Y) == 1 && S.size() == 1 && iterCount(S) == 1,
           N + ": the revived address is a member exactly once");
  } else {
    skipBranch(3, N);
  }
  S.erase(Y);
  expect(S.empty(), N + ": explicit erase empties the set");
  kill(Y);
}

template <typename MapT, typename MkT, typename ValT>
void checkMap(const char *Name, MapT &Mp, MkT Mk, ValT V1) {
  std::string N = Name;
  auto *X = Mk();
  Mp[X] = V1;
  expect(Mp.count(X) == 1 && Mp.size() == 1 && iterCount(Mp) == 1 &&
             Mp.lookup(X) == V1,
         N + ": live key maps");
  const void *Addr = X;
  kill(X);
  auto *D = static_cast<decltype(X)>(const_cast<void *>(Addr));
  expect(Mp.count(D) == 0 && !Mp.contains(D), N + ": deleted key is not counted");
  expect(Mp.find(D) == Mp.end(), N + ": deleted key is not found");
  expect(Mp.lookup(D) == ValT(), N + ": deleted key looks up the default");
  expect(Mp.size() == 0 && Mp.empty() && iterCount(Mp) == 0,
         N + ": size/empty/iteration ignore the deleted key");
  auto *Y = Mk();
  ++ReuseTried;
  if (static_cast<const void *>(Y) == Addr) {
    ++ReuseHit;
    expect(Mp.count(Y) == 0 && Mp.lookup(Y) == ValT(),
           N + ": a FRESH object at the dead address has NO mapping (8e5r)");
    expect(Mp[Y] == ValT(), N + ": operator[] on the fresh object yields the DEFAULT, not the stale value");
    expect(Mp.count(Y) == 1 && Mp.size() == 1, N + ": the revived key is a member once");
  } else {
    skipBranch(3, N);
  }
  Mp.erase(Y);
  expect(Mp.empty(), N + ": explicit erase empties the map");
  kill(Y);
}

template <typename ListT, typename MkT>
void checkList(const char *Name, ListT &L, MkT Mk) {
  std::string N = Name;
  auto *X = Mk();
  L.push_back(X);
  expect(!L.empty() && iterCount(L) == 1 && L.contains(X), N + ": live call is listed");
  const void *Addr = X;
  kill(X);
  auto *D = static_cast<decltype(X)>(const_cast<void *>(Addr));
  expect(L.empty() && iterCount(L) == 0 && !L.contains(D),
         N + ": deleted call is not listed");
  auto *Y = Mk();
  ++ReuseTried;
  if (static_cast<const void *>(Y) == Addr) {
    ++ReuseHit;
    expect(!L.contains(Y), N + ": a FRESH call at the dead address is NOT listed (8e5r)");
    L.push_back(Y);
    expect(iterCount(L) == 1, N + ": the fresh call is listed exactly ONCE, not twice");
  } else {
    skipBranch(2, N);
  }
  L.erase_value(Y);
  expect(L.empty(), N + ": erase_value empties the list");
  kill(Y);
}

}  // namespace

int main(int argc, char **argv) {
  // Rule-13 r1B F-EB-10: the mode is VALIDATED, and "reuse required" is an
  // ARGUMENT, not a re-read of the env string — a typo (`LIFO`) or a lost ctest
  // ENVIRONMENT used to downgrade silently to "(not required)".
  const char *Mode = std::getenv("CQ_OPT_DEBUG_ALLOC");
  std::string M = Mode ? Mode : "";
  if (!M.empty() && M != "lifo" && M != "nofree") {
    errs() << "cq-scrub-selftest: unknown CQ_OPT_DEBUG_ALLOC='" << M
           << "' (expected unset, 'lifo' or 'nofree') — refusing to run\n";
    return 2;
  }
  for (int I = 1; I < argc; ++I) {
    if (!std::strcmp(argv[I], "--require-reuse")) {
      StrictReuse = true;
    } else {
      errs() << "cq-scrub-selftest: unknown argument '" << argv[I] << "'\n";
      return 2;
    }
  }
  if (StrictReuse && M != "lifo") {
    errs() << "cq-scrub-selftest: --require-reuse needs CQ_OPT_DEBUG_ALLOC=lifo (got '" << M
           << "') — refusing to run\n";
    return 2;
  }

  Fixture Fx;
  cq::TaintSet T;
  auto Add = [&] { return Fx.mkAdd(); };
  auto Call = [&] { return Fx.mkCall(); };
  auto Phi = [&] { return Fx.mkPhi(); };
  auto Store = [&] { return Fx.mkStore(); };
  auto Block = [&] { return Fx.mkBlock(); };
  auto Fn = [&] { return Fx.mkFunction(); };

  // ---- lists -------------------------------------------------------------
  checkList("ThetaCalls", T.ThetaCalls, Call);
  checkList("PhiCalls", T.PhiCalls, Call);
  checkList("MeasureCalls", T.MeasureCalls, Call);
  checkList("PhaseCalls", T.PhaseCalls, Call);
  // ---- sets --------------------------------------------------------------
  checkSet("Tainted", T.Tainted, Add);
  checkSet("IntrinsicInvokes", T.IntrinsicInvokes, Call);
  checkSet("StaleDeclined", T.StaleDeclined, Add);
  checkSet("ValueArmConeOps", T.ValueArmConeOps, Add);
  checkSet("ControlOwnedRails", T.ControlOwnedRails, Add);
  checkSet("PromotedCarriedHandlePhis", T.PromotedCarriedHandlePhis, Phi);
  checkSet("DischargedFlagGates", T.DischargedFlagGates, Call);
  checkSet("OutputRails", T.OutputRails, Add);
  checkSet("GraveyardRails", T.GraveyardRails, Add);
  checkSet("IterationLocalBlocks", T.IterationLocalBlocks, Block);
  checkSet("InPlaceRailOps", T.InPlaceRailOps, Add);
  checkSet("PreLoopCommittedInPlaceOps", T.PreLoopCommittedInPlaceOps, Add);
  checkSet("UntaintedMergeRails", T.UntaintedMergeRails, Add);
  checkSet("UserSourceRotations", T.UserSourceRotations, Call);
  checkSet("UserChainedRotations", T.UserChainedRotations, Call);
  checkSet("UserPhaseRotations", T.UserPhaseRotations, Call);
  checkSet("SpineOps", T.SpineOps, Call);
  // ---- maps --------------------------------------------------------------
  checkMap("BirthOrder", T.BirthOrder, Add, 7u);
  checkMap("HandleWidth", T.HandleWidth, Add, StringRef("i16"));
  checkMap("InPlaceRailIdx", T.InPlaceRailIdx, Add, 1u);
  checkMap("InLoopFlattenedPreds", T.InLoopFlattenedPreds, Block, 3u);
  checkMap("SpecHandleArgMask", T.SpecHandleArgMask, Fn, uint64_t(5));
  {
    // Maps whose MAPPED value is a Value handle: the key half as above, with a
    // live mapped value, then the mapped half — a deleted flag/tape/store value
    // reads back as null, never as a dangling pointer.
    Instruction *Flag = Fx.mkAdd();
    auto Probe = [&](auto &Mp, auto MkKey, const char *Name) {
      std::string N = Name;
      auto *K = MkKey();
      Mp[K] = Flag;
      expect(static_cast<Value *>(Mp.lookup(K)) == Flag, N + ": mapped value is live");
      const void *Addr = K;
      kill(K);
      auto *D = static_cast<decltype(K)>(const_cast<void *>(Addr));
      expect(Mp.count(D) == 0 && Mp.empty() && iterCount(Mp) == 0,
             N + ": deleted key is not a member");
      auto *K2 = MkKey();
      ++ReuseTried;
      if (static_cast<const void *>(K2) == Addr) {
        ++ReuseHit;
        expect(Mp.count(K2) == 0 && static_cast<Value *>(Mp.lookup(K2)) == nullptr,
               N + ": a FRESH key at the dead address has NO mapping (8e5r)");
      } else {
        skipBranch(1, N);
      }
      Mp[K2] = Flag;
      return K2;
    };
    Value *K1 = Probe(T.SharedCondFlags, Add, "SharedCondFlags");
    Function *K2 = Probe(T.IOTapeForFn, Fn, "IOTapeForFn");
    StoreInst *K3 = Probe(T.GuardedStores, Store, "GuardedStores");
    kill(Flag);  // the MAPPED value dies; every entry must now read null
    expect(static_cast<Value *>(T.SharedCondFlags.lookup(K1)) == nullptr,
           "SharedCondFlags: a deleted mapped flag reads back null");
    expect(static_cast<Value *>(T.IOTapeForFn.lookup(K2)) == nullptr,
           "IOTapeForFn: a deleted mapped tape reads back null");
    expect(static_cast<Value *>(T.GuardedStores.lookup(K3)) == nullptr,
           "GuardedStores: a deleted mapped value reads back null");
    T.SharedCondFlags.clear();
    T.IOTapeForFn.clear();
    T.GuardedStores.clear();
    cast<Instruction>(K1)->eraseFromParent();
    K2->eraseFromParent();
    K3->eraseFromParent();
  }
  {
    // ControlledRotations: `const CallInst *` → WeakTrackingVH.
    CallInst *X = Fx.mkCall();
    T.ControlledRotations[X] = Fx.A;
    const void *Addr = X;
    kill(X);
    auto *D = static_cast<const CallInst *>(Addr);
    expect(T.ControlledRotations.count(D) == 0 && T.ControlledRotations.empty(),
           "ControlledRotations: deleted theta is not a member");
    CallInst *Y = Fx.mkCall();
    ++ReuseTried;
    if (static_cast<const void *>(Y) == Addr) {
      ++ReuseHit;
      expect(T.ControlledRotations.count(Y) == 0 &&
                 static_cast<Value *>(T.ControlledRotations.lookup(Y)) == nullptr,
             "ControlledRotations: a FRESH call at the dead address has NO flag (8e5r)");
    } else {
      skipBranch(1, "ControlledRotations");
    }
    kill(Y);
  }
  // ---- the pair set --------------------------------------------------------
  {
    Instruction *V = Fx.mkAdd();
    BasicBlock *B = Fx.mkBlock();
    T.ClaimedRailRoots.insert({V, B});
    expect(T.ClaimedRailRoots.count({V, B}) == 1, "ClaimedRailRoots: live pair is a member");
    const void *AddrV = V;
    kill(V);
    expect(T.ClaimedRailRoots.count({static_cast<const Value *>(AddrV), B}) == 0 &&
               T.ClaimedRailRoots.empty(),
           "ClaimedRailRoots: a pair whose VALUE died is gone");
    Instruction *V2 = Fx.mkAdd();
    T.ClaimedRailRoots.insert({V2, B});
    const void *AddrB = B;
    kill(B);
    expect(T.ClaimedRailRoots.count({V2, static_cast<const BasicBlock *>(AddrB)}) == 0 &&
               T.ClaimedRailRoots.empty(),
           "ClaimedRailRoots: a pair whose BLOCK died is gone");
    kill(V2);
  }
  // ---- copy / move / iterate-while-erasing -----------------------------------
  {
    Instruction *X = Fx.mkAdd(), *Y = Fx.mkAdd(), *Z = Fx.mkAdd();
    T.Tainted.insert(X);
    T.Tainted.insert(Y);
    T.Tainted.insert(Z);
    cq::TaintedValueSet Snapshot = T.Tainted;  // the `beforeTaint` idiom
    const void *AY = Y;
    // Erase EVERY member from INSIDE an iteration of the set that holds it (the
    // `lowerMeasures`-over-`MeasureCalls` shape): the iterator must survive.
    unsigned Visited = 0;
    for (Value *V : T.Tainted) {
      ++Visited;
      cast<Instruction>(V)->eraseFromParent();
    }
    expect(Visited == 3, "Tainted: erasing the CURRENT member mid-iteration visits all three");
    expect(T.Tainted.empty() && Snapshot.empty(),
           "Tainted + its COPY both drop keys deleted after the copy");
    expect(Snapshot.count(static_cast<const Value *>(AY)) == 0, "snapshot: deleted key absent");
    // A MOVED set keeps listening (the hook's owner pointer survives the move).
    Instruction *W = Fx.mkAdd();
    T.Tainted.insert(W);
    cq::TaintSet Moved = std::move(T);
    expect(Moved.Tainted.count(W) == 1, "move: the key moved with the set");
    const void *AW = W;
    kill(W);
    expect(Moved.Tainted.count(static_cast<const Value *>(AW)) == 0 && Moved.Tainted.empty(),
           "move: the moved-to set drops a key deleted after the move");
    // And the moved-from TaintSet is an EMPTY, usable, still-listening set.
    Instruction *U = Fx.mkAdd();
    T.Tainted.insert(U);
    const void *AU = U;
    kill(U);
    expect(T.Tainted.count(static_cast<const Value *>(AU)) == 0 && T.Tainted.empty(),
           "move: the moved-from set is usable and self-cleaning");
    (void)X;
    (void)Z;
  }
  {
    // A list erased from INSIDE its own iteration (`lowerMeasures`).
    CallInst *C1 = Fx.mkCall(), *C2 = Fx.mkCall(), *C3 = Fx.mkCall();
    T.MeasureCalls.push_back(C1);
    T.MeasureCalls.push_back(C2);
    T.MeasureCalls.push_back(C3);
    unsigned Visited = 0;
    for (CallInst *CI : T.MeasureCalls) {
      ++Visited;
      CI->eraseFromParent();
    }
    expect(Visited == 3 && T.MeasureCalls.empty(),
           "MeasureCalls: erasing the CURRENT call mid-iteration visits all three");
  }

  outs() << "scrub-on-delete selftest [CQ_OPT_DEBUG_ALLOC=" << (M.empty() ? "<unset>" : M)
         << "]: " << Checks << " checks, " << Failures << " failures; address reuse reproduced "
         << ReuseHit << "/" << ReuseTried
         << (StrictReuse ? " (REQUIRED)" : " (not required)") << "; aliasing branches SKIPPED "
         << SkippedBranches << "/" << ReuseTried << " (" << SkippedChecks << " checks)\n";
  return Failures ? 1 : 0;
}
