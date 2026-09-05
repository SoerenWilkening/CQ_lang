; control_inplace_ry_reject_stateprep_unrecognized_suffix.ll — DECLINE (F1, the
; THIRD sub-clause: the seed's LLVM type vs the NAME-DERIVED ABI width).
;
; ⚠ THIS FIXTURE EXISTS BECAUSE THE SHIPPED RECORD SAID IT COULD NOT
; (round-1 Rule-13 review, lens L1 finding F-L1-1, probe `p/c03_unrec_suffix.ll`).
; Notes §8 F-3 and PRD §14.4 both said the clause was "structurally unreachable …
; no fixture can be written, and none was". They were reasoning about a
; PROTOTYPE mismatch, which is genuinely blocked. THE REACHABLE ROUTE IS AN
; UNRECOGNIZED SUFFIX:
;
;   * `isThetaCall` is a bare NAME-PREFIX test (`starts_with("cq_theta_")`), so
;     `@cq_theta_si32x` IS a theta to the classifier;
;   * `resolveSources` loops `wd.allSuffixes()` — the 16 canonical names — so
;     `declMatchesPrototype` is NEVER ASKED of this declaration, and its own
;     comment says an unrecognized suffix "stays out of collection — and
;     validation — entirely";
;   * `abiWidthFor("si32x")` is therefore `""`, `llvmWidthType("")` is null, and
;     F1's third clause fires on its `!SeedTy` half.
;
; A sibling predicate spelled differently from its siblings IS the hole, and here
; the two spellings are `starts_with("cq_theta_")` and `allSuffixes()`.
;
; IT IS LOAD-BEARING, NOT DEFENCE IN DEPTH, AND THE COUNTERFACTUAL IS MEASURED
; RATHER THAN ARGUED. `taint.ThetaCalls` is populated only from `ThetaFns`, so an
; unrecognized-suffix theta is NEVER LOWERED. Without this clause the state-prep
; classifier ACCEPTS: R3 passes by uniqued-constant identity, the re-scoped
; `!StatePrep && !Tainted(RotBase)` check is skipped, R4 and R6 are skipped, and
; the detection width gate at `ArmClassify` asks a DIFFERENT derivation
; (`abiWidthFromType(T->getType())` = `i32`, which DOES have a controlled
; rotation). The emitter hoists `T`, records `ControlledRotations[T]`, RAUWs the
; merge to it and flattens the diamond.
;
; MEASURED 2026-09-05 by disabling exactly this clause and rebuilding BOTH
; targets, on two modules:
;
;   * THIS module (which MEASURES the prepped rail) -> exit 1, but with a
;     DIFFERENT and much later string:
;     `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` —
;     the merge value is the un-lowered theta's result, not a handle, so the
;     failure lands in `lowerMeasures` rather than in detection;
;   * the SAME module with the prepped rail NOT measured -> **exit 0**, and the
;     emitted module carries
;     `%rt = call i32 @cq_theta_si32x(i32 0, double 9.000000e-01)` — A STANDING
;     `@cq_theta_*` — bracketed by `cq_template_icmp_eq_i32_hl`, its `_unc` strip
;     and `cqrt_free`, i.e. A FLAG MINTED, STRIPPED AND FREED AROUND NOTHING.
;
; That second module is what "load-bearing" means here: without the clause the
; pass emits a region whose gate does not exist.
;
; THE MECHANISM THE RECORD NAMED IS ALSO WRONG, and it is corrected at both
; sites: "the LLVM verifier forces a call's argument to match its callee's
; parameter type" is false — LLVM 19 PARSES AND VERIFIES a call whose
; `FunctionType` differs from its callee's. What blocks that other route is
; `CallBase::getCalledFunction()`, which returns NULL in exactly that case, so
; `isThetaCall` is false and the pass never sees a theta at all.
;
; ONE-TOKEN CONTROL: `control_inplace_ry_stateprep_suffix_control.ll` is this
; module with `si32x` → `si32` and NOTHING else changed. It ACCEPTS.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed does not match the merge incoming under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32x(i32, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32x(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mr
}
