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
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: rotation angle under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 7        ; i32-data select
  %md  = call i32 @cq_measure_si32(i32 %sel) ; DATA use (measured as a handle)
  %bc  = bitcast i32 %sel to float           ; value-preserving carrier
  %w   = fpext float %bc to double           ; value-preserving carrier
  call void @cq_phi(double %w)  ; ANGLE use (arg-1) — fan-out
  %m   = call i32 @cq_measure_si32(i32 %q)
  ret i32 %md
}
