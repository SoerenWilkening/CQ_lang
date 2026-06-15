; control_swap_reject_select_dualuse.ll — DECLINE: a DUAL-USE fan-out select
; (4.4 WI-1 §3.2 gate 3 + the fan-out rule, PRD §16.2). The whole select declines
; even though it ALSO has a legitimate integer-data use.
;
; `%sel` is an i32-data select: it feeds a `cq_measure` (a genuine DATA use) AND,
; via a `bitcast`+`fpext` carrier chain, a `cq_phi` arg-1 (an ANGLE use). The
; arg-1 angle exclusion is per-operand-USE, not global, so `%sel` is legitimately
; tainted-as-data and angle-bearing at once. Splitting (merge for the data use,
; rotate for the angle use) would double-realize the value — a silent miscompile.
; `selReachesRotationArg1` returns true on the FIRST arg-1 reach and declines the
; ENTIRE select `rotation angle` (never split — the fan-out rule).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd  = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c   = icmp sgt i32 %qd, 5
  %sel = select i1 %c, i32 %qd, i32 7        ; i32-data select
  %md  = call i32 @cq_measure_si32(i32 %sel) ; DATA use (measured as a handle)
  %bc  = bitcast i32 %sel to float           ; value-preserving carrier
  %w   = fpext float %bc to double           ; value-preserving carrier
  %q2  = call i32 @cq_phi_si32(i32 %qd, double %w)  ; ANGLE use (arg-1) — fan-out
  %m   = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %md
}
