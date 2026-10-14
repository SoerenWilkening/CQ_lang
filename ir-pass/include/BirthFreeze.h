// BirthFreeze.h — clause (a) of the record-freeze invariant, "R starts at |0⟩",
// asked of every rail of a recovered DAG (bd test_C_libtooling-5c5b, libcqops
// bead vmz9). Pure analysis over one recovered DAG; it only ever ADDS to
// `DataDag::FrozenRails`, i.e. it can only remove `cqrt_free`s, never an adjoint.
//
// THE GAP IT CLOSES. The whole-DAG reversal returns every rail to the state it
// held BEFORE its first recovered gate — its BIRTH state — not to |0⟩. The two
// are the same for a template producer (`cq_template_*`, `cqrt_qram_load_*`),
// which mints a fresh |0⟩ rail and computes into it. They are NOT the same for a
// `cqrt_alloc_<W>(seed)` root, which is born holding the classical basis state
// |seed⟩:
//
//     %h = cqrt_alloc_i32(%m)      ; |m⟩
//     cqrt_ry_i32(%h, 0.5)         ; the user's `int q = m; cq_theta(&q, 0.5)`, q dead
//     cqrt_ry_i32(%h, -0.5)        ; spine adjoint: back to |m⟩, NOT |0⟩
//     cqrt_free(%h)                ; reset of |m⟩ — a dirty free for m ≠ 0
//
// `cqrt_free` is a hardware reset, emitted only after the compiler proves the
// rail is |0⟩ (runtime/cq_runtime.h). The earlier licence for this free —
// "the root is disentangled and in a known classical state" (measurement
// immunity) — is a different argument from "the rail is |0⟩", the same
// distinction bd 5pio drew for the sxuk QRAM index roots. libcqops' free
// certificate convicts it and strands the rail (its
// tests/test_shim_cert_rules.inc pins `alloc_i8(5); Ry; Ry⁻¹; free` DIRTY
// against a zero-seed CLEAN sibling). Measured customers: e2e
// slice_z0re_runtime_seed_{f64,prep,prep_literal,prep_spec}.
//
// THE RULE. A rail is born |0⟩ iff it is a template producer, a clone producer
// (bd p3kd.13, CloneProducer.h: the Bennett wrap's `cqrt_alloc_<W>(0)` out rail),
// or a `cqrt_alloc_<W>` whose one seed operand is a constant with an all-zero bit
// pattern (`Constant::isNullValue`: +0.0 qualifies, -0.0 does not; a whole-value
// undef seed was already rewritten to that null by
// `normalizeUndefRotationSeed`). Everything else — a runtime seed (one
// activation's zero is not a proof for the next), a nonzero literal, a
// phi/select/argument root (its birth is some other rail's state at the merge)
// — is frozen: LEFT ALLOCATED, every adjoint still emitted (the Rule-6 fallback;
// see the suppression note in `Uncomputation::emitDagReversal`).
//
// A QRAM ARRAY HANDLE IS NOT FROZEN HERE (bd test_C_libtooling-r2j3.21). It is
// never freed whatever this says (`emitDagReversal` skips it by kind), so the
// freeze bought it nothing but a WRONG ANSWER to the other question `FrozenRails`
// answers: "is this rail KEPT entangled after the reversal?"
// (`keptRailAdjointReadsBorrowed`, bd eqti). A walked array has every store on it
// in `D.Calls` (an array is walked whole: its in-place gates are its stores) and
// every load of it in the DAG (closure), so reverse-play returns it to its BIRTH
// state — `cqrt_qram_alloc_<W>`'s fresh classical cells (QramLowering's bd r2j3.15
// initializer proof) — a product state, whatever registers its stores read. So it
// is kept ENTANGLED only when step 3b/3c froze it (a record into a kept carrier),
// and `FrozenRails ∋ arr` now means exactly that. `railBornZero` still answers
// false for it (its cells are not a freeable |0⟩ register).
//
// ⚠ RETIREMENT TRIGGER: a reversal that UN-SEEDS a root (an in-place
// `cqrt_xorc_<W>`/`cqrt_addc_<W>` of the classical seed after the adjoints, the
// way `BreakReversePlay` returns its `i+1` materialiser to |0⟩) would make such a
// root provably |0⟩ again. That emitter must then teach `railBornZero` the
// un-seeded root rather than bypass this freeze.

#ifndef CQ_IRPASS_BIRTH_FREEZE_H_
#define CQ_IRPASS_BIRTH_FREEZE_H_

namespace llvm {
class Value;
}  // namespace llvm

namespace cq {

struct DataDag;
struct TaintSet;

// Clause (a): does rail `R` hold |0⟩ at birth? Fail-closed — false for any rail
// kind not named above.
bool railBornZero(const llvm::Value *R, const TaintSet &taint);

// Freeze every rail of `D` that `railBornZero` cannot prove.
void freezeUnprovenBirths(DataDag &D, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_BIRTH_FREEZE_H_
