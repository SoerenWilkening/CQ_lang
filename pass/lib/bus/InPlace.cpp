// Rule 5 In-place form: the shape is recognized here; its construction is not built yet and stops loudly.
#include "BusInternal.h"

#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;
using namespace llvm::PatternMatch;

namespace cq::bus {

namespace {

bool isTheta(const Value *v) {
  auto *c = dyn_cast<CallInst>(v);
  const Function *G = c ? c->getCalledFunction() : nullptr;
  return G && G->isDeclaration() && G->getName().starts_with("cq_theta_");
}

// Is a memory version change on a path of the original function from `from` to `to`?
bool changeBetween(LoweringContext &ctx, const Instruction &from, const Instruction &to) {
  const BasicBlock *FB = from.getParent(), *TB = to.getParent();
  auto scan = [&](BasicBlock::const_iterator a, BasicBlock::const_iterator b) {
    for (; a != b; ++a)
      if (&*a != &to && versionChange(ctx, *a))
        return true;
    return false;
  };
  if (FB == TB && from.comesBefore(&to))
    return scan(std::next(from.getIterator()), to.getIterator());
  if (scan(std::next(from.getIterator()), FB->end()) || scan(TB->begin(), to.getIterator()))
    return true;
  SmallPtrSet<const BasicBlock *, 16> fwd, back;
  SmallVector<const BasicBlock *, 16> w{FB};
  while (!w.empty())
    for (const BasicBlock *s : successors(w.pop_back_val()))
      if (s != FB && s != TB && fwd.insert(s).second)
        w.push_back(s);
  w.push_back(TB);
  while (!w.empty())
    for (const BasicBlock *p : predecessors(w.pop_back_val()))
      if (p != FB && p != TB && back.insert(p).second)
        w.push_back(p);
  for (const BasicBlock *b : fwd)
    if (back.count(b) && scan(b->begin(), b->end()))
      return true;
  return false;
}

// The steps of rule 5's form, back from the stored value: a cq_theta of the previous value, a rule-6 bijection in it,
// a width cast, a select whose arms are such updates. The load of `ptr` the chain starts from, or (Readers) the
// instruction that stored the value it starts from through `ptr`.
const Instruction *chainStart(const Value *v, const Value *ptr, const StoreInst &S, unsigned depth) {
  if (depth > 32)
    return nullptr;
  if (auto *L = dyn_cast<LoadInst>(v))
    return L->getPointerOperand() == ptr ? L : nullptr;
  if (isTheta(v)) {
    const Value *y = cast<CallInst>(v)->getArgOperand(0);
    // Readers: a cq_theta on the value -O1 forwarded from a store to the cell it is stored back through.
    for (const User *u : y->users())
      if (auto *Prev = dyn_cast<StoreInst>(u); Prev && Prev != &S && Prev->getValueOperand() == y &&
                                               Prev->getPointerOperand() == ptr && Prev->getParent() == S.getParent() &&
                                               Prev->comesBefore(&S))
        return Prev;
    return chainStart(y, ptr, S, depth + 1);
  }
  auto *I = dyn_cast<Instruction>(v);
  if (!I)
    return nullptr;
  const Value *a = nullptr, *b = nullptr;
  if (match(I, m_Add(m_Value(a), m_Value(b))) || match(I, m_Sub(m_Value(a), m_Value(b))) ||
      match(I, m_Xor(m_Value(a), m_Value(b)))) {
    if (const Instruction *r = chainStart(a, ptr, S, depth + 1))
      return r;
    return chainStart(b, ptr, S, depth + 1);
  }
  if (auto *Mul = dyn_cast<BinaryOperator>(I); Mul && Mul->getOpcode() == Instruction::Mul) {
    auto *k = dyn_cast<ConstantInt>(Mul->getOperand(1));
    return k && k->getValue()[0] ? chainStart(Mul->getOperand(0), ptr, S, depth + 1) : nullptr;
  }
  if (isa<ZExtInst>(I) || isa<TruncInst>(I) || isa<FreezeInst>(I) || isa<UnaryOperator>(I))
    return chainStart(I->getOperand(0), ptr, S, depth + 1);
  if (auto *Sel = dyn_cast<SelectInst>(I)) {
    if (const Instruction *r = chainStart(Sel->getTrueValue(), ptr, S, depth + 1))
      return r;
    return chainStart(Sel->getFalseValue(), ptr, S, depth + 1);
  }
  if (auto *II = dyn_cast<IntrinsicInst>(I))
    switch (II->getIntrinsicID()) {
    case Intrinsic::bswap:
    case Intrinsic::bitreverse:
      return chainStart(II->getArgOperand(0), ptr, S, depth + 1);
    case Intrinsic::fshl:
    case Intrinsic::fshr:
      return II->getArgOperand(0) == II->getArgOperand(1) ? chainStart(II->getArgOperand(0), ptr, S, depth + 1)
                                                          : nullptr;
    default:
      return nullptr;
    }
  return nullptr;
}

} // namespace

bool isInPlaceForm(LoweringContext &ctx, const StoreInst &S) {
  const Instruction *start = chainStart(S.getValueOperand(), S.getPointerOperand(), S, 0);
  return start && !changeBetween(ctx, *start, S);
}

void lowerInPlace(LoweringContext &, StoreInst &S) {
  std::string s;
  raw_string_ostream os(s);
  os << "cq: unimplemented: bus: the in-place form (rule 5): " << S;
  report_fatal_error(Twine(os.str()), /*gen_crash_diag=*/false);
}

} // namespace cq::bus
