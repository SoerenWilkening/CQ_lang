// The structural verifier (NORTHSTAR principle 4, cq-arch "Verify.h"). Module verify (cq-w0-verify).
//
// verifyLowered runs over a lowered module (our output inside cq-lower, or any .ll through
// -passes=cq-verify) and fails with report_fatal_error listing every violation, each line naming its
// check and the offending instruction. The checks:
//
// Handles are recognised from ABI call results and operand slots (abi::parse*), closed over
// phi/select/freeze. The rail checks are a forward must-analysis: a rail's state is the set of states
// it may be in at a program point (known basis, measured, dirty, rotated, freed); a check fires only
// when every possibility violates it, so an imprecision never rejects a correct module. Rails
// reached only through memory, the push/pop stack or parameters start in "anything"; every other
// alias of a rail written through one name (phi/select class) becomes "anything" at that write.
#include "cq/Verify.h"
#include "cq/Order.h"

#include <algorithm>
#include <cstring>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <tuple>
#include <vector>

#include "Roles.h"
#include "cq/Abi.h"
#include "cq/Common.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/EquivalenceClasses.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq {
namespace {

using verify::Kind;
using verify::Res;
using verify::Role;
using verify::Sig;

// Rail states, as a may-set.
enum : uint8_t { SK = 1, SM = 2, SD = 4, SF = 8, SX = 16, STop = 31 };

struct Violation {
  const char *check;
  std::string text;
};

std::string where(const Instruction &I) {
  std::string s;
  raw_string_ostream os(s);
  os << "in @" << I.getFunction()->getName() << ": " << I;
  return os.str();
}

class FunctionVerifier {
public:
  FunctionVerifier(const Function &F, verify::SigCache &Sigs, std::vector<Violation> &Out, bool Reference)
      : F(F), Sigs(Sigs), Out(Out), Reference(Reference) {}

  void run() {
    if (!Reference)
      measureProvenance();
    collectHandles();
    controlOnTaint();
    handleInClassicalOp();
    railStates();
    uncOperands();
    memoryRails();
  }

private:
  const Function &F;
  verify::SigCache &Sigs;
  std::vector<Violation> &Out;
  const bool Reference;

  // ---- unwritten-measurement, provenance (cq-arch V1): every cqrt_measure_<W> carries !cq.measure, the
  // uniqued empty tuple, and nothing else carries it. Our output only; references have no marker. ----
  void measureProvenance() {
    const unsigned MDKind = F.getContext().getMDKindID("cq.measure");
    for (const Instruction &I : instructions(F)) {
      if (!isa<CallBase>(I) && !I.hasMetadata())
        continue;   // neither a measure call nor a carrier of !cq.measure
      const MDNode *MD = I.hasMetadata() ? I.getMetadata(MDKind) : nullptr;
      const Sig *S = sigOf(I);
      const bool isMeasure = S && S->kind == Kind::Core && S->core && S->core->op == abi::Core::Measure;
      if (isMeasure && !MD)
        report("unwritten-measurement",
               "cqrt_measure without !cq.measure: not the lowering of a user cq_measure", I);
      else if (MD && !isMeasure)
        report("unwritten-measurement", "!cq.measure on an instruction that is not a cqrt_measure_<W> call", I);
      else if (MD && (!isa<MDTuple>(MD) || MD->getNumOperands() != 0 || MD->isDistinct()))
        report("unwritten-measurement", "!cq.measure is not the uniqued empty tuple !{}", I);
    }
  }

  // ---- handles ----
  SmallPtrSet<const Value *, 32> H;
  DenseMap<const Value *, unsigned> Idx;
  std::vector<const Value *> Vals;
  std::vector<int> ClassOf;                     // phi/select/freeze class of each handle, or -1
  std::vector<std::vector<unsigned>> Classes;   // the members of each class of two or more

  void report(const char *check, const Twine &why, const Instruction &I) {
    Out.push_back({check, (why + "\n    " + where(I)).str()});
  }

  const Sig *sigOf(const Instruction &I) {
    if (auto *CB = dyn_cast<CallBase>(&I))
      return &Sigs.get(*CB);
    return nullptr;
  }

  static bool isHandleRole(Role r) {
    return r != Role::Classical && r != Role::Word;
  }

  bool addH(const Value *V) {
    if (!isa<Instruction>(V) && !isa<Argument>(V))
      return false;
    if (!V->getType()->isIntegerTy(32))
      return false;
    return H.insert(V).second;
  }

  // Handles: ABI results and handle operand slots, closed over phi / select arms / freeze in both
  // directions.
  void collectHandles() {
    for (const Instruction &I : instructions(F)) {
      const Sig *S = sigOf(I);
      if (!S || (S->kind != Kind::Core && S->kind != Kind::Template))
        continue;
      auto *CB = cast<CallBase>(&I);
      if (S->res == Res::Known || S->res == Res::Dirty)
        addH(&I);
      for (unsigned i = 0, e = CB->arg_size(); i < e && i < S->roles.size(); ++i)
        if (isHandleRole(S->roles[i]))
          addH(CB->getArgOperand(i));
    }
    bool changed = true;
    while (changed) {
      changed = false;
      for (const Instruction &I : instructions(F)) {
        SmallVector<const Value *, 4> ops;
        if (auto *P = dyn_cast<PHINode>(&I))
          for (const Value *V : P->incoming_values())
            ops.push_back(V);
        else if (auto *Sel = dyn_cast<SelectInst>(&I))
          ops = {Sel->getTrueValue(), Sel->getFalseValue()};
        else if (auto *Fr = dyn_cast<FreezeInst>(&I))
          ops = {Fr->getOperand(0)};
        else
          continue;
        bool any = H.count(&I);
        for (const Value *V : ops)
          any |= H.count(V) != 0;
        if (!any)
          continue;
        changed |= addH(&I);
        for (const Value *V : ops)
          changed |= addH(V);
      }
    }
    for (const Argument &A : F.args())
      if (H.count(&A))
        index(&A);
    for (const Instruction &I : instructions(F))
      if (H.count(&I))
        index(&I);
    EquivalenceClasses<const Value *> EC;
    for (const Value *V : Vals)
      EC.insert(V);
    for (const Instruction &I : instructions(F)) {
      if (!H.count(&I))
        continue;
      SmallVector<const Value *, 4> ops;
      if (auto *P = dyn_cast<PHINode>(&I))
        for (const Value *V : P->incoming_values())
          ops.push_back(V);
      else if (auto *Sel = dyn_cast<SelectInst>(&I))
        ops = {Sel->getTrueValue(), Sel->getFalseValue()};
      else if (auto *Fr = dyn_cast<FreezeInst>(&I))
        ops = {Fr->getOperand(0)};
      for (const Value *V : ops)
        if (H.count(V))
          EC.unionSets(&I, V);
    }
    ClassOf.assign(Vals.size(), -1);
    for (auto It = EC.begin(); It != EC.end(); ++It) {
      if (!It->isLeader())
        continue;
      std::vector<unsigned> members;
      for (auto M = EC.member_begin(It); M != EC.member_end(); ++M)
        members.push_back(Idx[*M]);
      if (members.size() < 2)
        continue;
      for (unsigned m : members)
        ClassOf[m] = Classes.size();
      Classes.push_back(std::move(members));
    }
  }

  void index(const Value *V) {
    Idx[V] = Vals.size();
    Vals.push_back(V);
  }

  // ---- classical-control-on-taint ----
  // A handle as the program moves it: a handle, a literal, or a phi / select over such values.
  bool handleLike(const Value *V) const {
    SmallPtrSet<const Value *, 8> seen;
    SmallVector<const Value *, 8> w{V};
    while (!w.empty()) {
      const Value *X = w.pop_back_val();
      if (!seen.insert(X).second || isa<ConstantInt>(X) || H.count(X))
        continue;
      if (auto *P = dyn_cast<PHINode>(X)) {
        for (const Value *In : P->incoming_values())
          w.push_back(In);
      } else if (auto *S = dyn_cast<SelectInst>(X)) {
        w.push_back(S->getTrueValue());
        w.push_back(S->getFalseValue());
      } else {
        return false;
      }
    }
    return V->getType()->isIntegerTy(32);
  }
  void controlOnTaint() {
    SmallPtrSet<const Value *, 32> T(H.begin(), H.end());
    bool changed = true;
    while (changed) {
      changed = false;
      for (const Instruction &I : instructions(F)) {
        if (T.count(&I))
          continue;
        // CR §1.1 (ruling 2026-11-02): the lowered program may compare handles (icmp eq/ne of two handles, or
        // a handle and a literal such as 0, "no rail"): a classical decision, not a value computed from one.
        if (auto *Cmp = dyn_cast<ICmpInst>(&I); Cmp && Cmp->isEquality() && handleLike(Cmp->getOperand(0)) &&
                                                handleLike(Cmp->getOperand(1)))
          continue;
        if (!(isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<CmpInst>(I) || isa<CastInst>(I) ||
              isa<PHINode>(I) || isa<SelectInst>(I) || isa<FreezeInst>(I) || isa<GetElementPtrInst>(I) ||
              isa<InsertElementInst>(I) || isa<ExtractElementInst>(I) || isa<ShuffleVectorInst>(I) ||
              isa<InsertValueInst>(I)))
          continue;
        for (const Value *Op : I.operands())
          if (T.count(Op)) {
            T.insert(&I);
            changed = true;
            break;
          }
      }
    }
    for (const Instruction &I : instructions(F)) {
      const Value *C = nullptr;
      if (auto *B = dyn_cast<BranchInst>(&I)) {
        if (B->isConditional())
          C = B->getCondition();
      } else if (auto *Sw = dyn_cast<SwitchInst>(&I)) {
        C = Sw->getCondition();
      } else if (auto *Sel = dyn_cast<SelectInst>(&I)) {
        C = Sel->getCondition();
      } else if (auto *IB = dyn_cast<IndirectBrInst>(&I)) {
        C = IB->getAddress();
      }
      if (C && T.count(C))
        report("classical-control-on-taint", "a classical branch, switch or select on a value computed from a handle", I);
    }
  }

  // Rule 19 (162, 193): a function whose C return type is an integer wider than i32 returns an
  // escaped handle zero-extended to it. Only a zext whose every user is a return of it qualifies.
  bool isReturnedHandleZExt(const Instruction &I) const {
    auto *Z = dyn_cast<ZExtInst>(&I);
    if (!Z || Z->getType() != F.getReturnType() || Z->use_empty())
      return false;
    for (const User *U : Z->users())
      if (!isa<ReturnInst>(U))
        return false;
    return true;
  }

  // ---- handle-in-classical-op ----
  void handleInClassicalOp() {
    for (const Instruction &I : instructions(F)) {
      for (const Use &U : I.operands()) {
        const Value *V = U.get();
        if (!H.count(V))
          continue;
        unsigned n = U.getOperandNo();
        if (isa<PHINode>(I) || isa<FreezeInst>(I) || isa<ReturnInst>(I))
          continue;
        if (isa<SelectInst>(I) && n != 0)
          continue;
        if (isa<StoreInst>(I) && n == 0)
          continue;
        if (isa<InsertValueInst>(I) && n == 1)
          continue;
        if (isReturnedHandleZExt(I))
          continue;
        // CR §1.1 (ruling 2026-11-02): handles may be compared (icmp eq/ne against a handle or a literal).
        if (auto *Cmp = dyn_cast<ICmpInst>(&I); Cmp && Cmp->isEquality() && handleLike(Cmp->getOperand(0)) &&
                                                handleLike(Cmp->getOperand(1)))
          continue;
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (CB->isArgOperand(&U)) {
            const Sig &S = Sigs.get(*CB);
            unsigned a = CB->getArgOperandNo(&U);
            if (S.kind == Kind::Core || S.kind == Kind::Template || !S.roles.empty()) {
              if (a < S.roles.size() && S.roles[a] != Role::Classical)
                continue;
              report("handle-in-classical-op",
                     "handle in classical operand " + Twine(a) + " of @" + S.callee, I);
              continue;
            }
            if (S.kind == Kind::Clone)
              continue;
            const Function *Callee = CB->getCalledFunction();
            if (!Callee || !hostCallee(*Callee))
              continue;  // an in-module function, or a dispatch through a pointer
            report("handle-in-classical-op", "handle passed to the external function @" + Callee->getName(), I);
            continue;
          }
        }
        report("handle-in-classical-op", "a handle used by a classical instruction", I);
      }
    }
  }

  // ---- rail states: free-without-unc, use-after-free, inplace-on-frozen, unwritten-measurement ----
  // cq-4tkb4: a state is a vector of fixed-size chunks shared between blocks, copied on the first write (a block's
  // state differs from its predecessor's in a few handles; one dense vector per block took 2.3 GB on a function of
  // 76k blocks and 30k handles). The values are those of one dense vector per block.
  static constexpr unsigned kChunk = 256;
  struct ChunkArena {
    std::vector<std::unique_ptr<uint8_t[]>> pool;
    uint8_t *make(const uint8_t *from) {
      pool.push_back(std::make_unique<uint8_t[]>(kChunk));
      std::memcpy(pool.back().get(), from, kChunk);
      return pool.back().get();
    }
  };
  struct State {
    std::vector<const uint8_t *> c;
    std::vector<char> mine;    // a chunk this state made and may write in place
    ChunkArena *arena = nullptr;
    uint8_t operator[](size_t i) const { return c[i / kChunk][i % kChunk]; }
    void put(size_t i, uint8_t v) {
      size_t k = i / kChunk;
      if (c[k][i % kChunk] == v)
        return;
      if (!mine[k]) {
        c[k] = arena->make(c[k]);
        mine[k] = 1;
      }
      const_cast<uint8_t *>(c[k])[i % kChunk] = v;
    }
  };

  uint8_t get(const State &S, const Value *V) const {
    auto It = Idx.find(V);
    if (It == Idx.end())
      return STop;
    return S[It->second];
  }

  void set(State &S, const Value *V, uint8_t bits) {
    auto It = Idx.find(V);
    if (It == Idx.end())
      return;
    unsigned i = It->second;
    if (ClassOf[i] >= 0)
      for (unsigned p : Classes[ClassOf[i]])
        S.put(p, STop);
    S.put(i, bits);
  }

  // Result of an in-place XOR-type write (not/and/or/xor target, copy/xorc target), per concrete pair
  // of (target state, source state), unioned: monotone by construction.
  // No handle source (not_i1, xorc) acts as a known one.
  static uint8_t writeResult(uint8_t t, uint8_t src, bool hasSources) {
    uint8_t srcSet = !hasSources ? SK : src ? src : STop;
    uint8_t out = 0;
    for (uint8_t tb = 1; tb <= SX; tb <<= 1) {
      if (!(t & tb))
        continue;
      if (tb == SX) {
        out |= tb;
        continue;
      }
      for (uint8_t sb = 1; sb <= SX; sb <<= 1) {
        if (!(srcSet & sb))
          continue;
        bool srcKnown = sb == SK || sb == SM;
        if (tb == SK || tb == SM)
          out |= srcKnown ? SK : SD;
        else  // a dirty or rotated target: a dirty source may clean it (rule 6), a known one cannot
          out |= srcKnown ? tb : (SK | tb);
      }
    }
    return out;
  }

  // A forward call of the clone a twin undoes. Twins recompute through the _pure clone (CR §1.4), so
  // the forward call may be the _pure spelling or not.
  bool isForwardOf(const CallBase &CB, const abi::CloneSpec &Twin) {
    // Rule 18 with rule 19: the forward of the all-zero mask's twin is the call of the function's in-place lowering.
    if (const Function *G = CB.getCalledFunction(); G && G->getName() == Twin.fn && !Twin.ctl && Twin.bounds.empty() &&
                                                    !StringRef(Twin.mask).contains('1'))
      return true;
    const Sig &S = Sigs.get(CB);
    if (S.kind != Kind::Clone || S.unc)
      return false;
    const abi::CloneSpec &C = *S.clone;
    return C.fn == Twin.fn && C.mask == Twin.mask && C.bounds == Twin.bounds && C.ctl == Twin.ctl;
  }

  bool isForwardCloneResult(const Value *V, const abi::CloneSpec &Twin) {
    if (auto *EV = dyn_cast<ExtractValueInst>(V))
      V = EV->getAggregateOperand();
    if (auto *CB = dyn_cast<CallBase>(V))
      return isForwardOf(*CB, Twin);
    return false;
  }

  void transfer(const Instruction &I, State &S, bool rep) {
    // A use of a rail freed on every path.
    if (!isa<PHINode>(I))
      for (const Value *Op : I.operands())
        if (H.count(Op) && get(S, Op) == SX) {
          if (rep)
            report("use-after-free", "a handle used after its rail was freed on every path", I);
          break;
        }
    const Sig *Sg = sigOf(I);
    auto *CB = dyn_cast<CallBase>(&I);
    if (Sg && (Sg->kind == Kind::Core || Sg->kind == Kind::Template)) {
      uint8_t src = 0;
      bool hasSources = false;
      for (unsigned i = 0, e = std::min<unsigned>(CB->arg_size(), Sg->roles.size()); i < e; ++i)
        if (Sg->roles[i] == Role::Read && H.count(CB->getArgOperand(i))) {
          src |= get(S, CB->getArgOperand(i));
          hasSources = true;
        }
      for (unsigned i = 0, e = std::min<unsigned>(CB->arg_size(), Sg->roles.size()); i < e; ++i) {
        const Value *V = CB->getArgOperand(i);
        if (!H.count(V))
          continue;
        uint8_t st = get(S, V);
        switch (Sg->roles[i]) {
        case Role::Free:
          if (rep && st != 0 && st != SX && !(st & SK))
            report("free-without-unc",
                   "cqrt_free of a rail in no known basis state (not after its _unc, not a seed)", I);
          set(S, V, SX);
          break;
        case Role::BusFree:
          set(S, V, SX);
          break;
        case Role::UncOut:
          if (rep && st == SF)
            report("inplace-on-frozen", "_unc on a rotated rail", I);
          set(S, V, (st & SX) | ((st & ~SX) ? SK : 0));
          break;
        case Role::Write:
          // Not a frozen violation: CR writes rotated rails by copy (rule 6 clean-up), xorc (rule 10
          // reset before a prep) and not_i1 (rule 8 bracket on a bare i1 flag).
          set(S, V, writeResult(st, src, hasSources));
          break;
        case Role::Swap:
          // After a swap the rail holds what the cells held: nothing this analysis tracks, nothing it may reject.
          set(S, V, (st & SX) | ((st & ~SX) ? uint8_t(SK | SM | SD | SF) : 0));
          break;
        case Role::Rotate:
          if (rep && st == SM)
            report("inplace-on-frozen", "rotation of a measured rail", I);
          set(S, V, (st & SX) | ((st & ~SX) ? SF : 0));
          break;
        case Role::Measure:
          if (rep && st == SM)
            report("unwritten-measurement",
                   "a second measurement of a rail measured on every path (a re-measurement is a classical re-read)", I);
          set(S, V, (st & SX) | ((st & ~SX) ? SM : 0));
          break;
        default:
          break;
        }
      }
      if (H.count(&I))
        set(S, &I, Sg->res == Res::Known ? SK : Sg->res == Res::Dirty ? SD : STop);
      return;
    }
    if (Sg && Sg->kind == Kind::Clone) {
      if (Sg->unc)
        for (const Value *V : CB->args())
          if (H.count(V) && originsAny(V, [&](const Value *R) { return isForwardCloneResult(R, *Sg->clone); }))
            set(S, V, SK);
      if (H.count(&I))
        set(S, &I, SD);
      return;
    }
    if (!H.count(&I))
      return;
    if (auto *EV = dyn_cast<ExtractValueInst>(&I)) {
      const Sig *AS = nullptr;
      if (auto *ACB = dyn_cast<CallBase>(EV->getAggregateOperand()))
        AS = &Sigs.get(*ACB);
      set(S, &I, AS && AS->kind == Kind::Clone && !AS->unc ? SD : STop);
    } else if (auto *Sel = dyn_cast<SelectInst>(&I)) {
      set(S, &I, get(S, Sel->getTrueValue()) | get(S, Sel->getFalseValue()));
    } else if (auto *Fr = dyn_cast<FreezeInst>(&I)) {
      set(S, &I, get(S, Fr->getOperand(0)));
    } else {
      set(S, &I, STop);
    }
  }

  void blockEntry(const BasicBlock &BB, State &S, const DenseMap<const BasicBlock *, std::vector<const uint8_t *>> &OutS,
                  bool rep) {
    for (const PHINode &P : BB.phis()) {
      if (!H.count(&P))
        continue;
      uint8_t st = 0;
      for (unsigned i = 0, e = P.getNumIncomingValues(); i < e; ++i) {
        auto It = OutS.find(P.getIncomingBlock(i));
        uint8_t in = 0;
        if (It != OutS.end()) {
          auto Ix = Idx.find(P.getIncomingValue(i));
          in = Ix == Idx.end() ? STop : It->second[Ix->second / kChunk][Ix->second % kChunk];
        }
        if (!H.count(P.getIncomingValue(i)))
          in = STop;
        if (rep && in == SX)
          report("use-after-free", "a phi incoming freed on every path to its edge", P);
        st |= in;
      }
      set(S, &P, st);
    }
  }

  void railStates() {
    if (Vals.empty() || F.isDeclaration())
      return;
    ReversePostOrderTraversal<const Function *> RPO(&F);
    using Chunks = std::vector<const uint8_t *>;
    DenseMap<const BasicBlock *, Chunks> OutS;
    ChunkArena arena;
    const size_t nc = (Vals.size() + kChunk - 1) / kChunk;
    std::vector<uint8_t> zeros(kChunk, 0);
    const uint8_t *zero = zeros.data();
    auto entryState = [&](const BasicBlock *BB) {
      State S;
      S.arena = &arena;
      S.c.assign(nc, zero);
      S.mine.assign(nc, 0);
      SmallVector<const Chunks *, 4> in;
      for (const BasicBlock *P : predecessors(BB))
        if (auto It = OutS.find(P); It != OutS.end())
          in.push_back(&It->second);
      for (size_t k = 0; k < nc && !in.empty(); ++k) {
        const uint8_t *first = (*in[0])[k];
        bool same = all_of(in, [&](const Chunks *o) { return (*o)[k] == first; });
        if (same) {
          S.c[k] = first;
          continue;
        }
        uint8_t buf[kChunk];
        std::memcpy(buf, first, kChunk);
        for (size_t j = 1; j < in.size(); ++j)
          for (unsigned x = 0; x < kChunk; ++x)
            buf[x] |= (*in[j])[k][x];
        S.c[k] = arena.make(buf);
        S.mine[k] = 1;
      }
      if (BB == &F.getEntryBlock())
        for (const Argument &A : F.args())
          if (H.count(&A))
            S.put(Idx[&A], uint8_t(S[Idx[&A]] | STop));
      return S;
    };
    // The chunks of S equal to o's in content take o's (a state that did not change keeps its chunks).
    auto sameAs = [&](State &S, const Chunks &o) {
      bool eq = true;
      for (size_t k = 0; k < nc; ++k) {
        if (S.c[k] == o[k])
          continue;
        if (std::memcmp(S.c[k], o[k], kChunk) == 0)
          S.c[k] = o[k];
        else
          eq = false;
      }
      return eq;
    };
    // With no back edge (every reachable predecessor earlier in RPO), one pass in RPO is the fixed point: report
    // during it. rep only gates the reports, never the states.
    DenseMap<const BasicBlock *, unsigned> pos;
    for (const BasicBlock *BB : RPO)
      pos[BB] = pos.size();
    bool acyclic = all_of(RPO, [&](const BasicBlock *BB) {
      return all_of(predecessors(BB), [&](const BasicBlock *P) {
        auto It = pos.find(P);
        return It == pos.end() || It->second < pos.lookup(BB);
      });
    });
    if (acyclic) {
      for (const BasicBlock *BB : RPO) {
        State S = entryState(BB);
        blockEntry(*BB, S, OutS, true);
        for (const Instruction &I : *BB)
          if (!isa<PHINode>(I))
            transfer(I, S, true);
        OutS[BB] = std::move(S.c);
      }
      return;
    }
    bool changed = true;
    while (changed) {
      changed = false;
      for (const BasicBlock *BB : RPO) {
        State S = entryState(BB);
        blockEntry(*BB, S, OutS, false);
        for (const Instruction &I : *BB)
          if (!isa<PHINode>(I))
            transfer(I, S, false);
        auto It = OutS.find(BB);
        if (It == OutS.end() || !sameAs(S, It->second)) {
          OutS[BB] = std::move(S.c);
          changed = true;
        }
      }
    }
    for (const BasicBlock *BB : RPO) {
      State S = entryState(BB);
      blockEntry(*BB, S, OutS, true);
      for (const Instruction &I : *BB)
        if (!isa<PHINode>(I))
          transfer(I, S, true);
    }
  }

  // ---- origins (through phi / select arms / freeze) ----
  template <typename Pred> bool originsAny(const Value *V, Pred P) const {
    SmallVector<const Value *, 16> Work{V};
    SmallPtrSet<const Value *, 16> Seen;
    while (!Work.empty()) {
      const Value *X = Work.pop_back_val();
      if (!Seen.insert(X).second)
        continue;
      if (auto *Ph = dyn_cast<PHINode>(X)) {
        for (const Value *In : Ph->incoming_values())
          Work.push_back(In);
      } else if (auto *Sel = dyn_cast<SelectInst>(X)) {
        Work.push_back(Sel->getTrueValue());
        Work.push_back(Sel->getFalseValue());
      } else if (auto *Fr = dyn_cast<FreezeInst>(X)) {
        Work.push_back(Fr->getOperand(0));
      } else if (P(X)) {
        return true;
      }
    }
    return false;
  }

  SmallVector<const Value *, 8> origins(const Value *V) const {
    SmallVector<const Value *, 8> R;
    originsAny(V, [&](const Value *X) {
      R.push_back(X);
      return false;
    });
    return R;
  }

  // A root whose identity as a rail is known: the result of a handle-producing ABI call.
  bool traceable(const Value *R) {
    auto *CB = dyn_cast<CallBase>(R);
    if (!CB)
      return false;
    const Sig &S = Sigs.get(*CB);
    return (S.kind == Kind::Core || S.kind == Kind::Template) && (S.res == Res::Known || S.res == Res::Dirty);
  }

  // What a root of origins() can be as a rail. A fresh rail (an ABI result, a clone result field: CR
  // §1.3 "every handle a call returns names a newly allocated object", rule 18 copy-out) is only
  // itself. A parameter may be any parameter's rail (a clone may get one rail twice), never a rail
  // this activation allocated. Anything else (a load, a pop, another call) may be any rail.
  enum class RootKind { Fresh, Param, Wild };
  struct RootKey {
    RootKind kind;
    const Value *v;
    unsigned field;
  };

  RootKey rootKey(const Value *R) {
    if (traceable(R))
      return {RootKind::Fresh, R, 0};
    if (isa<Argument>(R))
      return {RootKind::Param, R, 0};
    const Value *Agg = R;
    unsigned field = ~0u;
    if (auto *EV = dyn_cast<ExtractValueInst>(R)) {
      Agg = EV->getAggregateOperand();
      field = EV->getNumIndices() == 1 ? EV->getIndices()[0] : ~0u - 1;
    }
    if (auto *CB = dyn_cast<CallBase>(Agg)) {
      const Sig &S = Sigs.get(*CB);
      if (S.kind == Kind::Clone && !S.unc)
        return {RootKind::Fresh, CB, field};
    }
    return {RootKind::Wild, R, 0};
  }

  static bool mayAlias(const RootKey &A, const RootKey &B) {
    if (A.kind == RootKind::Wild || B.kind == RootKind::Wild)
      return true;
    if (A.kind != B.kind)
      return false;
    if (A.kind == RootKind::Param)
      return true;
    return A.v == B.v && A.field == B.field;
  }

  bool sameHandle(const Value *A, const Value *B) {
    if (A == B)
      return true;
    auto OA = origins(A), OB = origins(B);
    for (const Value *RA : OA)
      for (const Value *RB : OB)
        if (mayAlias(rootKey(RA), rootKey(RB)))
          return true;
    return false;
  }

  static bool fixedClassical(const Value *V) { return isa<Constant>(V) || isa<Argument>(V); }

  static bool sameClassical(const Value *A, const Value *B) {
    if (A == B)
      return true;
    return !(fixedClassical(A) && fixedClassical(B));
  }

  bool sameOperand(const Value *A, const Value *B, Role r) {
    if (r == Role::Classical || r == Role::Word)
      return (H.count(A) || H.count(B)) ? sameHandle(A, B) : sameClassical(A, B);
    return sameHandle(A, B);
  }

  // Compare the forward argument list of Fwd with Unc's operands from position off on.
  bool argsMatch(const CallBase &Fwd, const CallBase &Unc, unsigned off, const Sig *FS) {
    if (Unc.arg_size() < off + Fwd.arg_size())
      return false;
    for (unsigned j = 0, e = Fwd.arg_size(); j < e; ++j) {
      Role r = (FS && j < FS->roles.size()) ? FS->roles[j] : Role::Word;
      if (!sameOperand(Fwd.getArgOperand(j), Unc.getArgOperand(off + j), r))
        return false;
    }
    return true;
  }

  const CallBase *asCallTo(const Value *V, StringRef name) {
    auto *CB = dyn_cast<CallBase>(V);
    if (!CB || !CB->getCalledFunction() || CB->getCalledFunction()->getName() != name)
      return nullptr;
    return CB;
  }

  // ---- freed-overtaken-copy, kept-rail-released (rule 5 Memory; rulings "Every _unc must leave 0") ----
  // A bus access this module's IR shows as a memory version change (a call of another function may be one too, read
  // as no change: a check fires only when the violation is certain).
  bool isVersionChange(const Instruction &I) {
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB)
      return false;
    if (const Function *G = CB->getCalledFunction(); G && G->getName() == "__cq_alloc")
      return true;
    const Sig &S = Sigs.get(*CB);
    return S.kind == Kind::Core && S.core &&
           (S.core->op == abi::Core::QramStore || S.core->op == abi::Core::QramSwap ||
            S.core->op == abi::Core::TapeEffect || S.core->op == abi::Core::TapeEffectW);
  }

  // A change on EVERY path from A to B within A's block (the one reading a must-check needs).
  bool changeBetween(const Instruction &A, const Instruction &B) {
    if (A.getParent() != B.getParent() || !cq::comesBefore(&A, &B))
      return false;
    for (const Instruction *X = A.getNextNode(); X && X != &B; X = X->getNextNode())
      if (isVersionChange(*X))
        return true;
    return false;
  }

  void memoryRails() {
    for (const Instruction &I : instructions(F)) {
      auto *CB = dyn_cast<CallBase>(&I);
      const Sig *Sg = CB ? &Sigs.get(*CB) : nullptr;
      if (!Sg || Sg->kind != Kind::Core || !Sg->core)
        continue;
      if (Sg->core->op == abi::Core::Free && CB->arg_size() == 1) {
        const CallBase *Load = dyn_cast<CallBase>(CB->getArgOperand(0));
        const Sig *LS = Load ? &Sigs.get(*Load) : nullptr;
        if (LS && LS->kind == Kind::Core && LS->core && LS->core->op == abi::Core::QramLoad && !LS->unc &&
            changeBetween(*Load, I))
          report("freed-overtaken-copy", "cqrt_free of a load copy a memory version change overtook (rule 5)", I);
        continue;
      }
      if (Sg->core->op != abi::Core::QramStore)
        continue;
      SmallVector<const Value *, 2> kept{CB->getArgOperand(CB->arg_size() - 1)};
      if (Sg->core->ctl)
        kept.push_back(CB->getArgOperand(0));
      for (const Value *V : kept)
        for (const User *U : V->users()) {
          auto *UC = dyn_cast<CallBase>(U);
          const Sig *US = UC ? &Sigs.get(*UC) : nullptr;
          if (!US || !UC->getParent() || UC->getParent() != I.getParent() || !cq::comesBefore(&I, UC))
            continue;
          bool freed = US->kind == Kind::Core && US->core && US->core->op == abi::Core::Free;
          bool unc = (US->kind == Kind::Template || US->kind == Kind::Core) && US->unc && UC->getArgOperand(0) == V;
          if (freed || unc)
            report("kept-rail-released", "the value or control rail of a kept store released after it (rule 5)", *UC);
        }
    }
  }

  // ---- unc-operand-mismatch ----
  void uncOperands() {
    StringMap<std::vector<const CallBase *>> callsTo;   // read by find only
    // cq-i61ms: the forward clone calls by (fn, mask, bounds, ctl), in program order, read once: the twins below
    // looked them up by a scan of the whole function each (isForwardOf; sqlite3VdbeExec: minutes).
    std::map<std::tuple<std::string, Mask, std::vector<uint64_t>, bool>, std::vector<const CallBase *>> fwdClones;
    DenseMap<const CallBase *, unsigned> callIdx;
    for (const Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        unsigned n = callIdx.size();
        callIdx[CB] = n;
        if (const Function *Callee = CB->getCalledFunction())
          callsTo[Callee->getName()].push_back(CB);
        if (const Sig &S = Sigs.get(*CB); S.kind == Kind::Clone && !S.unc)
          fwdClones[{S.clone->fn, S.clone->mask, S.clone->bounds, S.clone->ctl}].push_back(CB);
      }

    for (const Instruction &I : instructions(F)) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      const Sig &S = Sigs.get(*CB);
      if (!S.unc)
        continue;
      if (S.kind == Kind::Template || (S.kind == Kind::Core && S.core->op == abi::Core::QramLoad)) {
        // _unc(out, forward args...): out is the forward call's result.
        const Value *OutV = CB->getArgOperand(0);
        auto roots = origins(OutV);
        bool opaque = false, matched = false, anyFwd = false;
        for (const Value *R : roots) {
          const CallBase *Fwd = asCallTo(R, S.fwd);
          if (!Fwd) {
            opaque |= !traceable(R);
            continue;
          }
          anyFwd = true;
          if (Fwd->arg_size() + 1 == CB->arg_size() && argsMatch(*Fwd, *CB, 1, &Sigs.get(*Fwd)))
            matched = true;
        }
        if (!matched && !opaque)
          report("unc-operand-mismatch",
                 anyFwd ? Twine("operands differ from the forward call of @") + S.fwd
                        : Twine("result operand is not produced by @") + S.fwd,
                 I);
        continue;
      }
      if (S.kind == Kind::Clone) {
        // Twin: (outs..., forward args..., old slot handles / snapshots...).
        bool matched = false;
        // The calls isForwardOf accepts, in program order.
        const abi::CloneSpec &Tw = *S.clone;
        std::vector<const CallBase *> Fwds;
        if (auto it = fwdClones.find({Tw.fn, Tw.mask, Tw.bounds, Tw.ctl}); it != fwdClones.end())
          Fwds = it->second;
        if (!Tw.ctl && Tw.bounds.empty() && !StringRef(Tw.mask).contains('1'))
          if (auto it = callsTo.find(Tw.fn); it != callsTo.end()) {
            Fwds.insert(Fwds.end(), it->second.begin(), it->second.end());
            llvm::sort(Fwds, [&](const CallBase *a, const CallBase *b) { return callIdx[a] < callIdx[b]; });
            Fwds.erase(std::unique(Fwds.begin(), Fwds.end()), Fwds.end());
          }
        for (const CallBase *Fwd : Fwds) {
          for (unsigned k = 0; k + Fwd->arg_size() <= CB->arg_size() && !matched; ++k) {
            bool outsOk = true;
            for (unsigned o = 0; o < k && outsOk; ++o)
              outsOk = originsAny(CB->getArgOperand(o), [&](const Value *R) {
                const Value *X = R;
                if (auto *EV = dyn_cast<ExtractValueInst>(X))
                  X = EV->getAggregateOperand();
                return X == Fwd || !traceable(R);
              });
            if (outsOk && argsMatch(*Fwd, *CB, k, nullptr))
              matched = true;
          }
          // CR §1.4: a _ctl twin may take the predicate first, then outs, then the other arguments (205, 98).
          for (unsigned k = 0; S.clone->ctl && Fwd->arg_size() && k + Fwd->arg_size() <= CB->arg_size() && !matched; ++k) {
            bool same = sameOperand(Fwd->getArgOperand(0), CB->getArgOperand(0), Role::Word);
            for (unsigned j = 1, e = Fwd->arg_size(); j < e && same; ++j)
              same = sameOperand(Fwd->getArgOperand(j), CB->getArgOperand(k + j), Role::Word);
            matched = same;
          }
          if (matched)
            break;
        }
        // Rule 19: a twin recomputes a callee that rotates through the callee's twin (Finalize replayRegisterCall): no forward.
        std::optional<abi::CloneSpec> self = abi::parseClone(CB->getFunction()->getName());
        if (Fwds.empty() && self && self->unc)
          continue;
        if (!matched)
          report("unc-operand-mismatch",
                 Fwds.empty() ? Twine("twin with no forward call of @") + S.fwd + " in this function"
                              : Twine("operands differ from every forward call of @") + S.fwd,
                 I);
        continue;
      }
    }
  }
};

} // namespace

void verifyLowered(const Module &M, const VerifyOptions &Opts) {
  std::vector<Violation> Out;
  verify::SigCache Sigs;
  for (const Function &F : M) {
    if (F.isDeclaration())
      continue;
    FunctionVerifier(F, Sigs, Out, Opts.reference).run();
    // CR §1.4: "A clone called by name and a lowered own symbol keep the original's linkage, calling convention and
    // unnamed_addr (`internal fastcc` stays, and its calls stay `fastcc`)". A direct call whose convention differs from
    // its defined callee's is undefined behaviour in LLVM, and LLVM's own verifier accepts it (cq-5yuk9).
    for (const Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (const Function *G = CB->getCalledFunction())
          if (!G->isDeclaration() && CB->getCallingConv() != G->getCallingConv())
            Out.push_back({"cc-mismatch", ("a call's calling convention differs from its defined callee's, @" +
                                           G->getName() + "\n    " + where(I)).str()});
  }
  if (Out.empty())
    return;
  std::string msg;
  raw_string_ostream os(msg);
  os << "cq: verify: " << Out.size() << " violation" << (Out.size() == 1 ? "" : "s");
  for (const Violation &V : Out)
    os << "\n  " << V.check << ": " << V.text;
  report_fatal_error(Twine(os.str()), /*gen_crash_diag=*/false);
}

} // namespace cq
