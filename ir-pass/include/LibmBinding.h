// LibmBinding.h — bind a quantum math.h call to the injected library body
// (bd test_C_libtooling-3c6m.72, NORTHSTAR goal 2, CLAUDE R14).
//
// `tools/cqc` links the math.h bundle (`tools/libm_bundle.py`) into every
// program that uses a CQ primitive: every openlibm (or owner-ruled CQ trig) body is present as a function
// `__cq_libm_<name>` (external linkage only so `llvm-link` keeps it; no libm
// symbol is ever redefined). A classical call keeps its callee, so a
// purely classical program reaches the system libm exactly as before (owner
// ruling 2026-10-06). A call with a TAINTED operand to
//   * a declared function `@<name>`, or
//   * an LLVM math intrinsic LangRef defines equal to the libm function
//     (`@llvm.sin.f64` == `sin`, `.f32` == `sinf`, `.f80` == `sinl`)
// is retargeted to `__cq_libm_<name>` when that body exists with the call's
// exact function type. The specializer then lifts the body like any visible
// classical callee; it is never inlined (owner ruling 2026-10-06: a called body
// must lower exactly as an inlined one would, so a decline there is a lifting
// gap, bd p3kd). This binds the call to injected SOURCE; it never lowers a
// function by name.
//
// Only a PUBLIC bundle body binds (the math.h entry points the bundle keeps
// external); openlibm's private helpers never do. A program's own EXTERNAL
// definition of the spelling (or an external alias of one) wins over the bundle
// on the intrinsic route, since under C linkage it is the function the call
// names; an ifunc binds nothing (loud); a private (local-linkage) function of
// that name is some TU's helper and never binds. A curated hardware
// intrinsic (`isCuratedReversibleIntrinsic`: sqrt, floor, fma, …) keeps its
// direct template. A type or calling-convention mismatch (`llvm.frexp` returns
// an aggregate, libm `frexp` writes through a pointer) or a missing body binds
// nothing, and the call still fails loudly as an unknown callee.
//
// Known gaps (loud): a math.h call inside a helper the specializer lifts is not
// bound (bd p3kd.11); taint grown in round 2 is not re-asked (bd 3c6m.75).
// Known silent defect inherited from the lifter: a bound call reads a stale
// rotated argument in `q2 = q; cq_theta(&q2, .3); cbrt(q)` (bd r2j3.6; before
// this binding the call failed loudly, review round 3).

#ifndef CQ_IRPASS_LIBM_BINDING_H_
#define CQ_IRPASS_LIBM_BINDING_H_

namespace llvm {
class Module;
}  // namespace llvm

namespace cq {

struct TaintSet;
class WidthDispatch;

// Retarget every tainted math.h call that has an injected body, re-propagating
// `taint` when anything changed (it is fresh on return).
// Returns true when it changed the module. L1: called after the first
// propagation AND re-asked before `detectSpecializations`, in both entry
// points, because taint can reach a call only after a later pre-pass.
bool bindLibmCalls(llvm::Module &M, TaintSet &taint, WidthDispatch &wd);

// Erase every injected `__cq_libm_*` body and table nothing references, and
// make the survivors (callees of a lowered clone) internal, so the bundle never
// leaves the module. `KeepBindable` (the early call, right after the first
// binding) also keeps every body a program call could still bind to, so the
// pre-passes never walk bundle code the program cannot reach. The final call
// (end of the pass, and the no-quantum early exit) keeps only what is used, so
// a classical program links no bundle code; it first sends any call that was
// bound but ended classical back to the system libm. Returns true when it
// changed M.
bool eraseUnusedLibmBodies(llvm::Module &M, bool KeepBindable);

}  // namespace cq

#endif  // CQ_IRPASS_LIBM_BINDING_H_
