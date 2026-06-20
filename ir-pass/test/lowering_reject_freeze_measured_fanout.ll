; lowering_reject_freeze_measured_fanout.ll — DECLINE (R-B blocker): a tainted
; INTEGER `freeze` whose OPERAND is INDEPENDENTLY measured (a fan-out handle)
; must NOT fold, or the whole-DAG uncompute would mis-/double-free the rail
; (Phase-7.1 Increment B; Rule 8 no-cloning / linear lineage).
;
; `%q` here has TWO forward sinks: `cq_measure(%f)` THROUGH the freeze AND a
; SECOND, independent `cq_measure(%q)`. The operand's per-shot record is no longer
; linear-lineage — folding the freeze and treating `%q` as a single owned terminal
; would let the uncompute free a register another sink already measured (a hidden
; collapse, Rule 6/8). `freezeOperandIndependentlyEscapes` detects the second
; measure of the operand and the freeze falls through to the generic escape
; decline (`kMsgOther`). Decline on fan-out (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %f  = freeze i32 %q                             ; one consumer
  %m1 = call i32 @cq_measure_si32(i32 %f)         ; sink via the freeze
  %m2 = call i32 @cq_measure_si32(i32 %q)         ; INDEPENDENT second sink (fan-out)
  %r  = add i32 %m1, %m2
  ret i32 %r
}

; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
; CHECK-NOT: cqrt_free
