; lowering_uncompute_measured_intermediate_qq.ll — Phase 5 WI-5 DECLINE / WI-4
; both-parent-scan lock (PRD §2.5 / §2.11 / §2.12; IMPLEMENTATION §4 WI-5). A DEAD
; two-quantum-operand product `prod = q1 * q2` whose SECOND parent `q2` is later
; measured through the upstream handle. The whole-DAG recovery hops BOTH tainted
; parents (`dataInputHandle` returns all tainted operands), so the closure scan
; reaches `q2` and finds its `cqrt_measure_` sink.
;
; Reversing the dead `%prod` DAG would un-rotate and `cqrt_free` `q2` BEFORE the
; user measurement reads it — a hidden projective collapse (Rule 5/6): the measure
; would see |0>, not the prepared state, a verify-clean wrong unitary. A
; one-parent measured-upstream scan (the pre-WI-4 bug) would follow only `q1` and
; MISS `q2`'s measure; this fixture pins that the scan covers the SECOND parent
; and that the existing loud `kMsgLineageMeasured` decline takes precedence over
; the WI-5 placement/invertibility flips (the QQ product itself IS invertible and
; placeable — only the measured intermediate makes it unsafe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x, i32 %y) {
entry:
  %q1   = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2   = call i32 @cq_theta_si32(i32 %y, double 3.500000e-01)
  %prod = mul i32 %q1, %q2                        ; DEAD QQ terminal
  %m    = call i32 @cq_measure_si32(i32 %q2)      ; measures the SECOND parent's register
  ret i32 %m
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
