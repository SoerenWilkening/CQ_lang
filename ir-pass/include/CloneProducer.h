// CloneProducer.h — a Phase-6 clone RESULT as an uncompute-spine PRODUCER (bd
// test_C_libtooling-p3kd.13; the lift bd ln16 named for region conditions and that
// was never built).
//
// THE GAP. `%r = @__cq_q_<callee>_<mask>(h, …)` is a Bennett-wrapped reversible
// call, |x⟩|0⟩_r → |x⟩|f(x)⟩_r, whose scratch the clone body already uncomputed. Its
// result rail is a basis record of its handle arguments, exactly what a
// `cq_template_*` result is. The spine knew only templates as producers, so a clone
// result consumed by another tainted op was never uncomputed: `sin(pow(c, e))`
// lowered to `%3 = pow_01(h, e); sin_f64(%3); measure`, and `%3` stood allocated and
// entangled with `c` for the rest of the program (stage 2b: "1 template rail
// mint(s) of which 1 left dirty"). A later non-diagonal gate on `c` then dephased
// it beyond what the program's own live record implies, with only the M-A warning.
//
// THE ADJOINT is the clone's void twin `@<clone>_unc(out, args…)`, which runs
// `out ^= f(args)` and leaves the borrowed arguments as it found them. It is the
// SAME function the 6.3 inner-call drain synthesizes (`ensureTwin`, one recipe:
// `synthesizeCloneUncTwin`), minted by `EmitInverse`'s existing clone recipe. Ground
// truth, Bennett.jl 824458d1: `src/lowering/call.jl:169-203` (`lower_call!`
// non-compact) inlines a callee's forward gates and leaves the cleanup to the
// CALLER's reverse, `src/bennett_transform.jl:365-377` (`_bennett_default`), which
// replays every gate, the callee's included, in reverse; `call.jl:130-168` (compact)
// wraps the callee as forward + copy + reverse, a self-inverse block whose replay
// zeroes the copy wires — `out ^= f(x)`. Either way the callee's output is an
// intermediate the caller's reverse discharges, in LIFO order with the rest.
//
// WHAT THIS FILE DECIDES, AND NOTHING ELSE. "May the spine OWN this clone result
// as a producer?" Everything positional — consumers executed before the discharge
// point, the borrowed parents unmoved across the window, multiplicity, fan-out as a
// DAG adjointed once per gate (R7) — stays with the drivers that already prove it
// for a template rail (`Uncomputation`, `DagTraversal`, `FreePoint`). A clone
// producer enters those drivers at exactly the points a template producer does.
//
// OWNERSHIP IS THE SPECIALIZER'S RECORD, NEVER A NAME (bd ln16's own condition):
//   (P1) the called OPERAND is a `Function` the specializer recorded building
//        (`taint.SpecHandleArgMask`, bd l3oi), with an EXACT, non-varargs body
//        (`calleeBodyTrusted`), called at its own type, with no operand bundle;
//   (P2) the result is a tainted `i32` handle (a ReturnTainted clone; a twin is
//        void and never qualifies);
//   (P3) the twin is AVAILABLE: either a `<clone>_unc` DEFINITION the specializer
//        recorded (synthesized or adopted by `ensureTwin` for an inner call — the
//        bd 9oob caveat about an adopted reserved-name twin applies to it exactly as
//        it already does to that inner call, so no program newly enters 9oob's
//        population), or NO symbol of that name at all and a body the bd xy9n
//        duplication fence clears (`findUndefOperandInBody`). Any other symbol of
//        that name — a declaration, an alias, an unrecorded definition — is not
//        trusted;
//   (P4) no ARGUMENT carries undef/poison (`slotCarriesUndef`): the twin call re-reads
//        every argument, so the literal would gain a second materialisation and the
//        adjoint could compute a different f.
//
// THE FREEZE. A clone body may carry a `freeze` the speculation fence inserted on
// a classical value it could not prove defined (`stabilizeSpeculatedValues`); the
// twin re-executes it, so the forward and the twin need not pick the same value
// for a POISON operand. That is the premise every inner-call twin already rests
// on, and it holds for a UB-free source program: the flattened body evaluates a
// speculated value on every basis state, but a frozen value only reaches the
// copied-out result on states where the source evaluates it too, where it is
// defined and the freeze is the identity; elsewhere the mux discards it, and the
// twin's own mirror undoes its scratch with its own choice. So `out ^= f(x)` holds
// for each x. A literal `undef` is NOT covered by that argument (the source reads
// it on the taken path) and stays refused by (P3)/(P4). The argument RESTS ON FOUR
// PREMISES (R11 round 1, F2); a change to any of them reopens it:
//   * only UNTAINTED values are ever frozen — `stabilize` returns a tainted value
//     unchanged (SpeculationSafety.cpp, `stabilize`), PredMux freezes a leaf only
//     under an untainted condition (PredMuxFlatten.cpp, `convertPhis`), the rail
//     select freezes its CLASSICAL condition (CloneRailSelect.cpp), a hoisted
//     classical call under quantum control freezes its classical ARGUMENTS
//     (ClassicalCallArmEmit.cpp, `NeedFreeze`), and a guarded classical read
//     freezes its classical INDEX and EXTENT (GuardedClassicalRead.cpp) — so a
//     freeze's poison-ness depends on classical inputs alone, never on the basis
//     state, and the twin sees the same classical inputs as the forward (R11 r2
//     F2-r2 completed this list; a NEW freeze minter must be added here);
//   * `scanBody` refuses a SOURCE `freeze` in a lifted callee (SpecializeReject.cpp,
//     "unsupported instruction"), so every freeze in a clone is one of the above;
//   * a `literal.stable` freeze of an undef CONSTANT has an undef operand, which
//     `findUndefOperandInBody` refuses ((P3)), so no twin duplicates one;
//   * a CALLER-side freeze is one shared SSA value, never re-executed by a twin,
//     and the post-uncompute `stabilize` rewrites every use of a stabilized value,
//     the twin call's included.
//
// THE POLICY WHEN (P3) OR (P4) FAILS, made explicit: the result is NOT owned, so it
// is left allocated — today's accepted leak (R5: never freed dirty), unchanged —
// and a later non-diagonal gate on a register it records is reported by the M-A
// guard (`warnLiveRecordRotations`, the owner's lyyf ruling), exactly as before this
// change. Building the twin for those shapes is filed as a follow-up.
//
// RETIREMENT TRIGGER (L7): if `scanBody` ever admits a phase or rotation primitive
// in a lifted callee, a clone is no longer a basis permutation of its arguments and
// `cloneGatePreservesBasis` below becomes false for it.

#ifndef CQ_IRPASS_CLONE_PRODUCER_H_
#define CQ_IRPASS_CLONE_PRODUCER_H_

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallPtrSet.h"

namespace llvm {
class CallInst;
class Value;
}  // namespace llvm

namespace cq {

struct DataDag;
struct TaintSet;

// (P1)–(P4) above. Pure analysis, no IR.
bool isCloneProducer(const llvm::CallInst *G, const TaintSet &taint);

// A call `EmitInverse` would invert through the clone-twin recipe (a non-void
// `__cq_q_*` that is not itself a twin) but that `isCloneProducer` refuses. A DAG
// that reaches one cannot be reversed: its adjoint would name a twin nobody built.
// `recoverDataDag` marks such a DAG not closed (a leak, never a dangling symbol).
bool isUnownableCloneCall(const llvm::CallInst *G, const TaintSet &taint);

// `preservesBasisUnderRecord` (ChainWalk.h) for a recovered gate that may be a clone
// producer. A clone is a basis permutation of its handle arguments: `scanBody`
// refuses every `cq_theta`/`cq_phi` in a lifted callee (spec_clone_theta_free.ll),
// so its body is a classical reversible circuit and its scratch is freed inside it.
bool cloneGatePreservesBasis(const llvm::CallInst *G, const TaintSet &taint);

// A group holding clone-result TERMINALS is planned per TerminalGroups.h (R11
// rounds 1-5): the union of its template and clone terminals is PROBED first and
// emitted only if it plans out without reverse-playing or freeing less than the
// template terminals alone (`neverWorse`); otherwise the template terminals plan exactly as main and the clone
// terminals SILENTLY afterwards — every refusal of the dead-terminal spine leaves a
// clone rail allocated (its pre-p3kd.13 disposition; a later non-diagonal gate still
// gets the M-A warning) instead of adding a decline. This is the last check before a
// non-Loud plan emits: the reversal must touch no gate or rail an earlier group
// reversed, read no rail it freed, and write no rail an already-emitted adjoint
// (`taint.SpineOps`) still reads. False ⇒ the plan is refused.
bool cloneTerminalReversalDisjoint(
    const DataDag &D, const llvm::SmallPtrSetImpl<const llvm::CallInst *> &RG,
    const llvm::SmallPtrSetImpl<llvm::Value *> &RR, const TaintSet &taint);

// Before the spine emits the adjoints of `Gates`: synthesize the twin of every clone
// producer among them that has none yet, and record its handle mask
// (`(mask << 1) | 1`, the inner drain's record). A no-op for every other gate.
void materializeCloneTwins(llvm::ArrayRef<llvm::CallInst *> Gates,
                           TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CLONE_PRODUCER_H_
