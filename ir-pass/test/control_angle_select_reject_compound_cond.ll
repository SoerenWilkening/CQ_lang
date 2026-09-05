; control_angle_select_reject_compound_cond.ll — DECLINE (S4): a COMPOUND
; `and i1` condition tree (bd drbq Inc 2b).
;
; S4 requires a BARE `CmpInst` (`Tree.Nodes` empty, ONE leaf). A real and/or tree
; needs the 3c6m.12 flag NETWORK — a fresh `|0>` ancilla per node, a toffoli, and
; a reverse strip in LIFO order — which the 4.4 select emitter has and this
; emitter does not.
;
; HAND-WRITTEN, DELIBERATELY, and the reason is worth recording: `clang -O1` does
; NOT produce this shape from `if (q > 5 && q < 100)`. It folds the whole
; conjunction to ONE compare on a derived value (`add q,-6; icmp ult ..., 94`),
; which this increment ACCEPTS — see
; `control_angle_select_ry_derived_cond.ll`. So the tree form is reachable only
; from hand IR or a spelling `-O1` does not canonicalize, and this fixture is the
; fence for it rather than a shape the C surface hits.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  %c2 = icmp slt i32 %q, 100
  %c = and i1 %c1, %c2
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
