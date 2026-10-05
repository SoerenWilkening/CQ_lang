// CalleeBody.h — bd `test_C_libtooling-p3kd.2`: THE ONE answer to "may the pass
// trust the module-local BODY of a callee?". Every site asks it with the use it
// makes of the body, so the question is stated where it is asked (Rule 12: one
// predicate; a site never re-derives it from linkage accessors).
//
// LLVM 19 splits a definition's linkage along two axes (GlobalValue.h):
//   * INTERPOSABLE (`isInterposable()`): `weak`, `linkonce`, `common`,
//     `extern_weak`, and any definition that is not `dso_local` under the
//     `SemanticInterposition` module flag. The linker or loader may bind an
//     ARBITRARY, non-equivalent body. There is no implementation to lift.
//   * DEREFINABLE (`mayBeDerefined()`, private): additionally `weak_odr`,
//     `linkonce_odr`, `available_externally`, and a `nobuiltin` function
//     definition. The body that links is the same SOURCE function (ODR), but it
//     may be a different REFINEMENT of it: each TU's optimizer may have exploited
//     UB, or resolved an `undef`, differently. LLVM's own example is
//     `void foo(int *v) { int t = 5 / v[0]; }` refined here to `void foo(int *v) {}`
//     while the linker binds the unrefined copy: `readnone` read off this copy
//     must not license DSE of a store to `v[0]` before a call to `foo`.
// `hasExactDefinition()` is `!isDeclaration() && !mayBeDerefined()`.
//
// THE TWO QUESTIONS.
//   * `Execute`: the module-local body RUNS in place of the call. The site is
//     retargeted to a clone of it (a Phase-6 specialization: the top callee of a
//     candidate), which is inlining in LLVM's terms. Sound for an exact definition
//     and for one derefinable ONLY through an ODR linkage: "inlining is okay across
//     non-exact linkage types as long as they're not interposable, since in such
//     cases the currently visible variant is *a* correct implementation of the
//     original source function" (GlobalValue::isDefinitionExact). A fact read off
//     the body (its shape, its return taint) is then a fact about the body that
//     runs at that site. `available_externally` is decided the same way: its body
//     is an inlining copy guaranteed equivalent to the external definition, and a
//     clone with internal linkage is emitted although the original never is.
//     A `nobuiltin` definition is NOT admitted (call sites may assume builtin
//     semantics of it; no C spelling reaches it, so nothing is lost).
//   * `AssumeOfLinkedCall`: a fact read off the module-local body is ASSUMED of a
//     call that still runs whatever body the linker binds: a dead parameter
//     rewritten to a constant (the dead-argument drop), a purity/termination proof
//     that licenses a speculated hoist, deletion-by-liveness that licenses dropping
//     an outer argument, a label-preservation proof, or a nested classical call a
//     clone keeps and the uncompute twin re-executes. Needs the EXACT definition: a
//     derefined variant may read the dropped slot, trap on the speculated input, or
//     return a different value the second time.
// A declaration or null is trusted for neither. Varargs, `naked` and the other
// shape conjuncts are different questions and stay at their sites.
//
// C REACHABILITY (measured 2026-10-05, clang 19.1.7 -O1): C99 `inline` and
// `extern inline __attribute__((gnu_inline))` are `available_externally` in the
// frontend's IR, but the -O1 pipeline inlines them or turns them into
// declarations (EliminateAvailableExternally); with `noinline` clang emits only
// the declaration. `__attribute__((weak))` is `weak` (interposable). No plain-C
// spelling was found that reaches `weak_odr`/`linkonce_odr` (C++ inline functions
// and template instantiations do). The widening is reached from hand IR and from
// llvm-linked modules of other front ends.

#ifndef CQ_IRPASS_CALLEE_BODY_H_
#define CQ_IRPASS_CALLEE_BODY_H_

#include "llvm/IR/Attributes.h"
#include "llvm/IR/Function.h"

namespace cq {

enum class CalleeBodyUse {
  Execute,             // the body runs in place of the call (cloned, retargeted)
  AssumeOfLinkedCall,  // a property of the body is assumed of the linked call
};

inline bool calleeBodyTrusted(const llvm::Function *F, CalleeBodyUse Use) {
  if (!F || F->isDeclaration())
    return false;
  if (F->hasExactDefinition())
    return true;
  if (Use == CalleeBodyUse::AssumeOfLinkedCall)
    return false;
  // Execute: derefinable ONLY through an ODR linkage, never interposable.
  const bool ODR = F->hasWeakODRLinkage() || F->hasLinkOnceODRLinkage() ||
                   F->hasAvailableExternallyLinkage();
  return ODR && !F->isInterposable() &&
         !F->hasFnAttribute(llvm::Attribute::NoBuiltin);
}

}  // namespace cq

#endif  // CQ_IRPASS_CALLEE_BODY_H_
