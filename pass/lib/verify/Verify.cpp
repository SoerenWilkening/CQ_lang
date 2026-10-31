// The structural verifier (NORTHSTAR principle 4, cq-arch "Verify.h"). Module verify (cq-w0-verify).
//
// verifyLowered runs over a lowered module (our output inside cq-lower, or any .ll through
// -passes=cq-verify) and fails with report_fatal_error listing every violation, each line naming its
// check and the offending instruction. The checks:
//
//   free-without-unc            a cqrt_free whose rail is in no known basis state: neither returned to
//                               |0> by its producer's _unc (or a clone twin) nor a seed (CR §0, rules 5, 7)
//   use-after-free              a use of a handle after its cqrt_free / cqrt_qram_free
//   inplace-on-frozen           a rotated rail reverse-played: the result rail of an _unc was rotated
//                               (rule 10: frozen, never reverse-played); or a rotation of a measured rail
//                               (CR §1.3). copy, xorc and not_i1 on a rotated rail are CR's own (rules 6,
//                               10, 8) and are not violations.
//   unc-operand-mismatch        an _unc (template, QRAM core, clone twin) whose operands differ from its
//                               forward call (CR §1.2, §1.3, §1.4)
//   handle-in-classical-op      a handle reaching a classical instruction or a classical operand slot
//                               (a zext feeding only the return is rule 19's wide return, 193)
//   classical-control-on-taint  a br / switch / select condition computed from a handle
//   unwritten-measurement       a cqrt_measure the source did not write: a second measurement of a rail
//                               already measured on every path (rule 2: a re-measurement is a classical
//                               re-read, never a second call); and, outside reference mode, the
//                               provenance marker (cq-arch V1): a cqrt_measure_<W> without !cq.measure, a
//                               !cq.measure that is not the uniqued empty tuple, or one on any other
//                               instruction. Reference mode (cq-verify<reference>) ignores the marker.
//
// Handles are recognised from ABI call results and operand slots (abi::parse*), closed over
// phi/select/freeze. The rail checks are a forward must-analysis: a rail's state is the set of states
// it may be in at a program point (known basis, measured, dirty, rotated, freed); a check fires only
// when every possibility violates it, so an imprecision never rejects a correct module. Rails
// reached only through memory, the push/pop stack or parameters start in "anything"; every other
// alias of a rail written through one name (phi/select class) becomes "anything" at that write.
#include "cq/Verify.h"

#include <map>
#include <optional>
#include <string>
#include <vector>

#include "Roles.h"
#include "cq/Abi.h"
#include "cq/Common.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/EquivalenceClasses.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
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
      const MDNode *MD = I.getMetadata(MDKind);
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
  void controlOnTaint() {
    SmallPtrSet<const Value *, 32> T(H.begin(), H.end());
    bool changed = true;
    while (changed) {
      changed = false;
      for (const Instruction &I : instructions(F)) {
        if (T.count(&I))
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
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (CB->isArgOperand(&U)) {
            const Sig &S = Sigs.get(*CB);
            unsigned a = CB->getArgOperandNo(&U);
            if (S.kind == Kind::Core || S.kind == Kind::Template) {
              if (a < S.roles.size() && S.roles[a] != Role::Classical)
                continue;
              report("handle-in-classical-op",
                     "handle in classical operand " + Twine(a) + " of @" + S.callee, I);
              continue;
            }
            if (S.kind == Kind::Clone)
              continue;
            const Function *Callee = CB->getCalledFunction();
            if (!Callee || !Callee->isDeclaration())
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
  using State = std::vector<uint8_t>;

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
        S[p] = STop;
    S[i] = bits;
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
    const Sig &S = Sigs.get(CB);
    if (S.kind != Kind::Clone || S.unc)
      return false;
    const abi::CloneSpec &C = *S.clone;
    return C.fn == Twin.fn && C.mask == Twin.mask && C.bounds == Twin.bounds && C.ctl == Twin.ctl &&
           C.adj == Twin.adj && C.depth == Twin.depth;
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

  void blockEntry(const BasicBlock &BB, State &S, const DenseMap<const BasicBlock *, State> &OutS, bool rep) {
    for (const PHINode &P : BB.phis()) {
      if (!H.count(&P))
        continue;
      uint8_t st = 0;
      for (unsigned i = 0, e = P.getNumIncomingValues(); i < e; ++i) {
        auto It = OutS.find(P.getIncomingBlock(i));
        uint8_t in = It == OutS.end() ? 0 : get(It->second, P.getIncomingValue(i));
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
    DenseMap<const BasicBlock *, State> OutS;
    auto entryState = [&](const BasicBlock *BB) {
      State S(Vals.size(), 0);
      if (BB == &F.getEntryBlock())
        for (const Argument &A : F.args())
          if (H.count(&A))
            S[Idx[&A]] = STop;
      for (const BasicBlock *P : predecessors(BB)) {
        auto It = OutS.find(P);
        if (It == OutS.end())
          continue;
        for (size_t i = 0; i < S.size(); ++i)
          S[i] |= It->second[i];
      }
      return S;
    };
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
        if (It == OutS.end() || It->second != S) {
          OutS[BB] = std::move(S);
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

  // ---- unc-operand-mismatch ----
  void uncOperands() {
    std::map<std::string, std::vector<const CallBase *>> callsTo;
    for (const Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (const Function *Callee = CB->getCalledFunction())
          callsTo[Callee->getName().str()].push_back(CB);

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
      if (S.kind == Kind::Core && S.core->op == abi::Core::QramStore) {
        bool matched = false;
        for (const CallBase *Fwd : callsTo[S.fwd])
          if (Fwd->arg_size() == CB->arg_size() && argsMatch(*Fwd, *CB, 0, &Sigs.get(*Fwd)))
            matched = true;
        bool opaque = false;
        for (unsigned i = 0; i < CB->arg_size(); ++i)
          if (H.count(CB->getArgOperand(i)))
            for (const Value *R : origins(CB->getArgOperand(i)))
              opaque |= !traceable(R);
        if (!matched && !opaque)
          report("unc-operand-mismatch", Twine("no forward @") + S.fwd + " with these operands", I);
        continue;
      }
      if (S.kind == Kind::Core && S.core->op == abi::Core::QramRealloc) {
        // _unc(a', n_old): a' is a realloc result and n_old the size its input object had.
        bool matched = false, opaque = false, anyFwd = false;
        for (const Value *R : origins(CB->getArgOperand(0))) {
          const CallBase *Fwd = asCallTo(R, S.fwd);
          if (!Fwd) {
            opaque |= !traceable(R);
            continue;
          }
          anyFwd = true;
          for (const Value *R2 : origins(Fwd->getArgOperand(0))) {
            auto *Prev = dyn_cast<CallBase>(R2);
            const Sig *PS = Prev ? &Sigs.get(*Prev) : nullptr;
            if (!PS || PS->kind != Kind::Core ||
                (PS->core->op != abi::Core::QramAlloc && PS->core->op != abi::Core::QramRealloc)) {
              matched = true;  // the old size is not visible here
              continue;
            }
            const Value *N = Prev->getArgOperand(PS->core->op == abi::Core::QramAlloc ? 0 : 1);
            if (sameClassical(N, CB->getArgOperand(1)))
              matched = true;
          }
        }
        if (!matched && !opaque)
          report("unc-operand-mismatch",
                 anyFwd ? Twine("old size differs from the size of the object @") + S.fwd + " resized"
                        : Twine("bus operand is not produced by @") + S.fwd,
                 I);
        continue;
      }
      if (S.kind == Kind::Clone) {
        // Twin: (outs..., forward args..., old slot handles / snapshots...).
        bool matched = false;
        std::vector<const CallBase *> Fwds;
        for (const Instruction &J : instructions(F))
          if (auto *JC = dyn_cast<CallBase>(&J))
            if (isForwardOf(*JC, *S.clone))
              Fwds.push_back(JC);
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
          if (matched)
            break;
        }
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
