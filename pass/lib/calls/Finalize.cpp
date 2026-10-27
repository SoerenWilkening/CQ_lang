// calls::finalize (cq-by8, owner ruling 2026-10-27 option (a)): CR §1.4 and rule 18, "the
// original (unlifted) body is kept only while a classical call site still uses it; a callee whose
// every call was retargeted is dropped."
//
// Runs once per module after every construct() and before verifyLowered.
//
//   Clones.     A function in the clone namespace (CR §1.4, "__cq_q_") whose symbol abi::parseClone
//               accepts, defined or declared, twins included. A module with none is left untouched:
//               finalize returns before reading anything else.
//   Originals.  The defined, non-clone function a clone was made from: the fn of the clone's §1.4
//               reading. The reading is checked against every defined function of the module, not
//               only the right-to-left parse, so a name that reads as a clone of two in-module
//               functions (CR §1.4: a fn ending in _<binary>_b<N>) is an internal error, not a
//               guess. A clone whose fn has no body here (rule 27 declared clones, libm names of
//               intrinsics with no injected body) has no original.
//   Live.       An original with a use anywhere but inside an original's body (a call or any other
//               use: classical call sites, address-taken function pointers, global initializers,
//               @llvm.used) is live, and so is every original a live original's body uses. The
//               rest have no classical caller left: every call was retargeted to a clone, or comes
//               from another dropped original (mutual recursion, call chains: 33, 119).
//   Dropped.    Every original that is not live. What a dropped body alone referenced and that now
//               has no use is dropped with it when it carries no symbol of its own: declarations
//               and local-linkage functions and variables.
//
// Shapes not lowered here (cq::unimplemented): a "__cq_q_" symbol that is not a canonical clone
// name (a uniquified clone, CR §1.4 ruling 2026-10-27: the clone table belongs to materialize, which
// finalize cannot see through Calls.h); a dead original whose body was rewritten in place (it calls
// an ABI symbol: a tainted entry function that also has clones and no in-module caller).
#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Common.h"

#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <string>

using namespace llvm;

namespace cq::calls {
namespace {

constexpr StringLiteral kClonePrefix = "__cq_q_";

bool isClone(const Function &F) { return F.getName().starts_with(kClonePrefix); }

// True iff the symbol is in one of the ABI namespaces the lowering emits (CR §1.1 to §1.4).
bool isAbiSymbol(StringRef name) {
  bool unc = false;
  return abi::parseCore(name).has_value() || abi::parseTemplate(name, &unc).has_value() ||
         abi::parseClone(name).has_value();
}

// The defined, non-clone function C was made from, or nullptr when its fn has no body here.
Function *originalOf(Module &M, Function &C) {
  StringRef rest = C.getName().drop_front(kClonePrefix.size());
  SmallVector<Function *, 2> cands;
  for (size_t i = rest.find('_'); i != StringRef::npos; i = rest.find('_', i + 1)) {
    Function *G = M.getFunction(rest.take_front(i));
    if (!G || G->isDeclaration() || isClone(*G))
      continue;
    // fn = G iff the rest of the symbol reads as the suffix of a clone of some one-token fn.
    std::optional<abi::CloneSpec> s = abi::parseClone((Twine(kClonePrefix) + "x_" + rest.drop_front(i + 1)).str());
    if (s && s->fn == "x")
      cands.push_back(G);
  }
  if (cands.size() > 1)
    unimplemented("calls: calls::finalize: a clone name that reads as a clone of more than one in-module "
                  "function (@" + cands[0]->getName().str() + ", @" + cands[1]->getName().str() +
                      ") (CR §1.4)",
                  &C);
  return cands.empty() ? nullptr : cands[0];
}

// Every global reachable from the constants in `work`, through constant expressions and aggregates.
void collectGlobals(SmallVector<const Constant *, 8> work, SetVector<GlobalValue *> &out) {
  SmallPtrSet<const Constant *, 16> seen;
  while (!work.empty()) {
    const Constant *c = work.pop_back_val();
    if (!seen.insert(c).second)
      continue;
    if (auto *gv = dyn_cast<GlobalValue>(c)) {
      out.insert(const_cast<GlobalValue *>(gv));
      continue;
    }
    for (const Value *op : c->operands())
      if (auto *oc = dyn_cast<Constant>(op))
        work.push_back(oc);
  }
}

// Every global a function body references.
void collectReferences(Function &F, SetVector<GlobalValue *> &out) {
  SmallVector<const Constant *, 8> work;
  for (Instruction &I : instructions(F))
    for (Value *op : I.operands())
      if (auto *c = dyn_cast<Constant>(op))
        work.push_back(c);
  collectGlobals(std::move(work), out);
}

} // namespace

void finalize(Module &M) {
  SmallVector<Function *, 8> clones;
  for (Function &F : M) {
    if (!isClone(F))
      continue;
    if (!abi::parseClone(F.getName()))
      unimplemented("calls: calls::finalize: a symbol in the clone namespace that is not a canonical "
                    "clone name (a uniquified clone; CR §1.4)",
                    &F);
    clones.push_back(&F);
  }
  if (clones.empty())
    return;

  SetVector<Function *> originals;
  for (Function *C : clones)
    if (Function *G = originalOf(M, *C))
      originals.insert(G);

  // Liveness. Seeds: a use outside every original's body.
  SmallPtrSet<Function *, 16> live;
  SmallVector<Function *, 16> work;
  for (Function *O : originals)
    for (User *U : O->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !originals.count(I->getFunction())) {
        live.insert(O);
        work.push_back(O);
        break;
      }
    }
  while (!work.empty()) {
    Function *L = work.pop_back_val();
    for (Instruction &I : instructions(*L))
      for (Value *op : I.operands())
        if (auto *G = dyn_cast<Function>(op); G && originals.count(G) && live.insert(G).second)
          work.push_back(G);
  }

  SmallVector<Function *, 8> dead;
  for (Function *O : originals)
    if (!live.count(O))
      dead.push_back(O);
  if (dead.empty())
    return;

  SetVector<GlobalValue *> refs;
  for (Function *D : dead) {
    for (Instruction &I : instructions(*D))
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *callee = CB->getCalledFunction(); callee && isAbiSymbol(callee->getName()))
          unimplemented("calls: calls::finalize: an original with no classical caller whose body was "
                        "rewritten in place (a tainted entry function that also has clones)",
                        D);
    collectReferences(*D, refs);
  }

  SmallPtrSet<GlobalValue *, 16> erased;
  for (Function *D : dead)
    D->dropAllReferences();
  for (Function *D : dead) {
    erased.insert(D);
    D->eraseFromParent();
  }

  // What only the dropped bodies referenced, transitively, when it now has no use and no symbol of
  // its own (declarations, local linkage).
  bool changed = true;
  while (changed) {
    changed = false;
    for (size_t i = 0; i < refs.size(); ++i) {
      GlobalValue *G = refs[i];
      if (erased.count(G))
        continue;
      G->removeDeadConstantUsers();
      if (!G->use_empty() || !(G->isDeclaration() || G->hasLocalLinkage()))
        continue;
      if (auto *F = dyn_cast<Function>(G)) {
        collectReferences(*F, refs);
        F->dropAllReferences();
      } else if (auto *V = dyn_cast<GlobalVariable>(G)) {
        if (V->hasInitializer())
          collectGlobals({V->getInitializer()}, refs);
        V->dropAllReferences();
      } else {
        continue;   // aliases and ifuncs are left alone
      }
      erased.insert(G);
      G->eraseFromParent();
      changed = true;
    }
  }
}

} // namespace cq::calls
