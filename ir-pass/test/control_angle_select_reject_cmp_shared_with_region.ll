; control_angle_select_reject_cmp_shared_with_region.ll — DECLINE: ONE compare
; used as BOTH a `br` region's control AND an angle select's condition (bd drbq
; Inc 2b).
;
;     if (q == 5) s = cq_phi(s, .7);                  // a swap-route region
;     r = cq_theta(r, q == 5 ? .9 : .3);              // an angle select
;
; `clang -O1` CSEs the two `q == 5` tests into ONE `icmp` with two users, so this
; is a plain-C-reachable composition, not a hand-built curiosity.
;
; WHICH GUARD FIRES, AND WHY IT IS NOT THE ONE THIS INCREMENT WROTE. The ziov
; condition-data-use disposition runs first (the terminator dispatch precedes the
; block's select scan): the compare has a non-branch user whose forward lineage is
; neither escaped nor measured, so the REGION declines
; `condition data use neither escaped nor measured`. Since a `DS_Error`
; diagnostic terminates the run, that is the only message emitted.
;
; S4's `Cond->hasOneUse()` would have refused the select independently — measured
; by deleting the region from this IR, which leaves a single-user compare that
; ACCEPTS. The two fences overlap; neither is redundant. Sharing one flag between
; a region and an angle select is a recorded follow-on (the region's flag is
; stripped and freed inside ITS stream, so the select would have to mint a second
; one or the two would have to agree on a single lifetime).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use neither escaped nor measured under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %s = call i32 @cq_theta_si32(i32 %u2, double 2.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %sd = call i32 @cq_phi_si32(i32 %s, double 7.000000e-01)
  br label %merge
merge:
  %sm = phi i32 [ %sd, %arm ], [ %s, %entry ]
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %ms = call i32 @cq_measure_si32(i32 %sm)
  %x = add i32 %mt, %ms
  ret i32 %x
}
