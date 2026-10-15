// ClonePreserves.cpp — `cloneCallPreservesArg` (ChainWalk.h, bd
// test_C_libtooling-rhk5), moved VERBATIM out of ChainWalk.cpp by bd p3kd.13 to keep
// that file from growing, plus the one widening that bd needed: a `select` ALIAS of
// the formal is followed rather than refused (see `aliasLabelPreserved`).

#include "ChainWalk.h"
#include "CalleeBody.h"        // calleeBodyTrusted (bd p3kd.2)
#include "ControlledSymbols.h" // isControlledXorc (bd dm7f.81)
#include "RotationLowering.h"  // isCopyGate — the ONE copy-write-slot owner (bd rhk5 r2)
#include "TaintPropagation.h"
#include "TemplateName.h"      // isUncHandleSlot — the ONE slot table

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"  // is_contained
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

// ── bd test_C_libtooling-rhk5 — see the header for the whole argument ────────
namespace {

// A (function, formal-slot) pair. While it is being proved it sits on the proof
// STACK; re-entering one is a CYCLE, which refuses (fail closed): the specializer
// declines recursive callees, so no accepted module reaches it, and "assume the
// formal is preserved while proving it" is exactly the kind of co-inductive
// argument this spine does not make.
using FormalKey = std::pair<const Function *, unsigned>;
constexpr unsigned kMaxCloneNesting = 16;

// The three answers. `NoProvisional` is a refusal that depends on the PATH that
// reached the question — a cycle hit, or the nesting cap — and it is the one
// answer the memo must not store (bd `tcpq`): cached, it would answer a later
// question that reaches the same (function, slot) along a SHORTER, acyclic path.
// A `Yes` can never be provisional: the walk is a conjunction that stops at the
// first refusal, so any refusal anywhere below a node makes the node a refusal.
enum class Proof { Yes, No, NoProvisional };

struct ProofCtx {
  SmallVector<FormalKey, 8> Stack;          // the path being proved (cycle test)
  DenseMap<FormalKey, bool> Memo;           // path-INDEPENDENT verdicts only
  DenseMap<const Value *, bool> AliasMemo;  // bd p3kd.13: a select alias, the same
};

Proof formalLabelPreserved(const Function &F, unsigned ArgNo,
                           const TaintSet &taint, ProofCtx &Ctx);
Proof aliasLabelPreserved(const Value *A, const TaintSet &taint, ProofCtx &Ctx);

// (C1)/(C2) and the per-slot recursion.
Proof clonePassPreserves(const CallInst *C, const Value *V, const TaintSet &taint,
                         ProofCtx &Ctx) {
  // (C1) the callee, resolved from the called OPERAND — never
  // `getCalledFunction()`'s name, never a prefix — with an EXACT definition: a
  // `weak`/`linkonce`/`available_externally` body can be replaced at link time
  // by one this walk never saw (bd `fb5y`, r1A F-r1A-2: a `weak` read-only twin
  // interposed by a strong writing one). `hasExactDefinition()` also excludes a
  // declaration.
  const auto *F = dyn_cast<Function>(C->getCalledOperand());
  if (!calleeBodyTrusted(F, CalleeBodyUse::AssumeOfLinkedCall) || F->isVarArg())
    return Proof::No;
  auto It = taint.SpecHandleArgMask.find(F);
  if (It == taint.SpecHandleArgMask.end())
    return Proof::No;  // not something the specializer recorded building.
  const uint64_t HandleSlots = It->second;
  // (C2) `V` reaches the body only through ARGUMENT slots: inside an operand
  // bundle it would be read by something this proof does not walk. (As the called
  // operand it cannot appear at all: `V` is an `i32` handle and the callee a
  // pointer — the first spelling tested that too, and r1A F-r1A-5 measured the
  // conjunct DEAD in typed IR, so it is gone.)
  for (unsigned B = 0, E = C->getNumOperandBundles(); B != E; ++B)
    for (const Use &U : C->getOperandBundleAt(B).Inputs)
      if (U.get() == V)
        return Proof::No;
  bool Passed = false;
  for (unsigned K = 0, E = C->arg_size(); K != E; ++K) {
    if (C->getArgOperand(K) != V)
      continue;
    Passed = true;
    // `K >= F->arg_size()` is unreachable once varargs are refused (a call with
    // more arguments than a non-varargs callee has parameters does not verify);
    // it is kept only because `F.getArg(K)` below would otherwise be UB.
    if (K >= F->arg_size() || K >= 64 || !((HandleSlots >> K) & 1))
      return Proof::No;  // not a slot the specializer recorded as a quantum HANDLE.
    Proof P = formalLabelPreserved(*F, K, taint, Ctx);
    if (P != Proof::Yes)
      return P;
  }
  return Passed ? Proof::Yes : Proof::No;
}

Proof formalLabelPreserved(const Function &F, unsigned ArgNo,
                           const TaintSet &taint, ProofCtx &Ctx) {
  const FormalKey Key{&F, ArgNo};
  auto M = Ctx.Memo.find(Key);
  if (M != Ctx.Memo.end())
    return M->second ? Proof::Yes : Proof::No;
  if (is_contained(Ctx.Stack, Key) || Ctx.Stack.size() >= kMaxCloneNesting)
    return Proof::NoProvisional;  // a cycle, or the nesting cap — path-dependent.
  Ctx.Stack.push_back(Key);
  const Proof Res = aliasLabelPreserved(F.getArg(ArgNo), taint, Ctx);
  Ctx.Stack.pop_back();
  if (Res != Proof::NoProvisional)
    Ctx.Memo[Key] = (Res == Proof::Yes);
  return Res;
}

// Every use of `A` — the formal itself, or (bd p3kd.13) a `select` ALIAS of it —
// leaves the label alone.
Proof aliasLabelPreserved(const Value *A, const TaintSet &taint, ProofCtx &Ctx) {
  Proof Res = Proof::Yes;
  for (const Use &U : A->uses()) {
    const auto *UC = dyn_cast<CallInst>(U.getUser());
    // bd p3kd.13: a `select` taking `A` as a VALUE operand (never the condition,
    // operand 0: an `i1`) is an alias that may BE `A` — the clone's classical-
    // condition rail select (CloneRailSelect.h), e.g. openlibm pow's
    // `select %c, %h_op, %x`. It writes nothing; it is label-preserving iff
    // every use of it is, so walk its uses with this same table rather than
    // refuse it. A select is never its own operand (SSA, one block), so the walk
    // ends; `AliasMemo` keeps a select reached twice from costing twice.
    if (const auto *S = dyn_cast<SelectInst>(U.getUser());
        S && U.getOperandNo() != 0) {
      auto It = Ctx.AliasMemo.find(S);
      Proof Sub = It != Ctx.AliasMemo.end()
                      ? (It->second ? Proof::Yes : Proof::No)
                      : aliasLabelPreserved(S, taint, Ctx);
      if (Sub != Proof::NoProvisional)
        Ctx.AliasMemo[S] = (Sub == Proof::Yes);
      if (Sub == Proof::Yes)
        continue;
      Res = Sub;
      break;
    }
    // Any other non-call user — `ret`, a φ, a store, a cast, a classical op — lets
    // the handle escape this walk (an ALIAS whose later uses nothing here reads)
    // or treats it as a number. Refuse.
    if (!UC || !UC->isArgOperand(&U)) {
      Res = Proof::No;
      break;
    }
    const unsigned Slot = UC->getArgOperandNo(&U);
    const auto *UCallee = dyn_cast<Function>(UC->getCalledOperand());
    // (B1)–(B3) classify the use by its callee's NAME, and are therefore asked
    // ONLY of a callee this module merely DECLARES — an external runtime-ABI
    // symbol, the frozen semantics every emitter relies on. A DEFINED callee
    // whose name looks like the runtime's is NOT the runtime: bd `fb5y` (r1A
    // F-r1A-1, a P1) is a module-defined `cq_template_evil_i32(k){cqrt_x(k)}`
    // admitted by name as a read. A defined callee must go through (B4) — recorded
    // and walked — or it refuses.
    if (UCallee && UCallee->isDeclaration()) {
      const StringRef N = UCallee->getName();
      // (B1) a forward reassigning producer: reads every operand, mints fresh.
      if (isTemplateProducer(UC))
        continue;
      // (B2) an out-first adjoint reading the formal in a HANDLE slot >= 1.
      if (isUncHandleSlot(N, Slot))
        continue;
      // (B3) a basis copy reading the formal in a READ slot: `isCopyGate` is the
      //      ONE statement of "a `cqrt_copy_<W>[_controlled]` writes its LAST
      //      operand and reads the others" (Rule 14 — the first spelling
      //      re-derived it inline, r1A F-r1A-6 / r1B F-6). The formal must not be
      //      the destination, in this slot or any other.
      if (isCopyGate(UC)) {
        const unsigned Last = UC->arg_size() - 1;
        if (Slot != Last && UC->getArgOperand(Last) != A)
          continue;
      }
      // (B3′) bd dm7f.81 — the classical-arm write `cqrt_xorc_<W>_controlled(
      //      ctrl, dst, imm)` reads only its CONTROL (slot 0); dst is written.
      if (isControlledXorc(UC) && Slot == 0 && UC->getArgOperand(1) != A)
        continue;
      Res = Proof::No;
      break;
    }
    // (B4) an inner clone / `_unc` twin call, proved the same way.
    Proof Sub = clonePassPreserves(UC, A, taint, Ctx);
    if (Sub == Proof::Yes)
      continue;
    Res = Sub;
    break;
  }
  return Res;
}

}  // namespace

bool cloneCallPreservesArg(const CallInst *C, const Value *V,
                           const TaintSet &taint) {
  // The memo lives for ONE query. A module-scoped cache would also be sound
  // (bodies are final when the spine asks) but it would be keyed on `Function *`
  // across stages that erase functions — the stale-key class bd 8e5r pins — for
  // no measured gain: within a query the memo already makes the cost linear in
  // the clone DAG, which is what F-r1A-3's exponential walk needed.
  ProofCtx Ctx;
  return clonePassPreserves(C, V, taint, Ctx) == Proof::Yes;
}

}  // namespace cq
