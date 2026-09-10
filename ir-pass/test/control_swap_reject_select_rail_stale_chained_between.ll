; control_swap_reject_select_rail_stale_chained_between.ll — DECLINE (bd
; test_C_libtooling-r9e5, Inc 1b-B.1): the STALE-NAME spelling — `%b = θ(u0,.5);
; %c = θ(%b,.25); select i1 %b, …`. The chained theta is an IN-PLACE Ry on the
; same physical rail (rotation lowering RAUWs the whole chain to ONE handle), so
; the copy the merge takes at the select would read the POST-Ry basis while the
; SSA condition denotes the pre-Ry record: `%out` routed on the wrong predicate,
; verify-clean.
;
; THE DISCRIMINATOR IS `control_swap_select_rail_post_ry.ll`: move the SAME
; chained theta BELOW the select and it accepts, because the DT prong then
; proves it runs after every execution of the select (`ProvenPostRegion`). Here
; it precedes the select, so the re-ask returns it and the rung declines. Green
; on both binaries — the widening did not reach it.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %b, double 2.500000e-01)
  %a = select i1 %b, i32 2, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %m = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %m to i32
  %r = add i32 %n, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
