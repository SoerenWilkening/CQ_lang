; control_swap_reject_select_cmp_measured_sidepath.ll — DECLINE (Track A.1, bd
; test_C_libtooling-r10v): the measurement sits on a CLASSICALLY GUARDED SIDE
; PATH that reaches the select.
;
;     int q = 0; cq_theta(&q, .5);
;     if (ext(1)) s = cq_measure(q);      // neither dominates nor is dominated
;     int a = (q == 1) ? 2 : 5;
;
; VERBATIM `clang -O1` (probe `d2_sel_cmp_measured_sidepath.c`), ACCEPT on `main`
; 0c7380c. THIS IS WHY THE RUNG ASKS REACHABILITY AND NOT DOMINANCE (round-1
; finding F-1b-2, inherited here): the measure's block does not dominate the
; select's, so a dominance test would accept — yet on the `ext(1) != 0` path the
; register is collapsed before the flag is minted. `isPotentiallyReachable` asks
; the one question that is correct for every placement: can the read point
; execute after this measurement on SOME path?
;
; The rail twin is `control_swap_reject_select_rail_measured_sidepath.ll`.

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ext(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %g = call i32 @ext(i32 1)
  %gz = icmp eq i32 %g, 0
  br i1 %gz, label %join, label %side

side:
  %m = call i32 @cq_measure_si32(i32 %q)
  br label %join

join:
  %s = phi i32 [ %m, %side ], [ 0, %entry ]
  %c = icmp eq i32 %q, 1
  %a = select i1 %c, i32 2, i32 5
  %r = add nsw i32 %s, %a
  ret i32 %r
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
