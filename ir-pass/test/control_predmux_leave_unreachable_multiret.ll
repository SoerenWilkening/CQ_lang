; control_predmux_leave_unreachable_multiret.ll — LEAVE→DECLINE (bd 20xt.5 (d)
; adversarial probe): the (d) unreachable-tolerance must NOT be mistaken for
; general multi-exit tolerance. This region reaches BOTH an `unreachable` sink
; (the exhaustive-switch default — genuinely dead) AND a real `ret` arm (a
; SECOND function exit that IS live). (d)'s merge recompute ignores ONLY the
; unreachable exit; the live `ret` still makes the region non-reconverging, so
; `mergeIgnoringUnreachable` finds no single merge and PredMux LEAVES — the
; region falls through to the existing loud decline. Pins that tolerating
; `unreachable` never widened E3 to admit a real `ret`/multi-exit.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %sp = icmp sgt i32 %q, 100
  br i1 %sp, label %retarm, label %quad      ; one arm RETURNS — a live 2nd exit
retarm:
  ret i32 7
quad:
  %m = and i32 %q, 3
  switch i32 %m, label %dead [
    i32 0, label %c0
    i32 1, label %c1
    i32 2, label %c2
    i32 3, label %c3
  ]
c0:
  %a0 = add i32 %q, 10
  br label %merge
c1:
  %a1 = mul i32 %q, 5
  br label %merge
c2:
  %a2 = xor i32 %q, 7
  br label %merge
c3:
  %a3 = sub i32 %q, 4
  br label %merge
dead:
  unreachable
merge:
  %rm = phi i32 [ %a0, %c0 ], [ %a1, %c1 ], [ %a2, %c2 ], [ %a3, %c3 ]
  %r  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %r
}
; CHECK: error{{.*}}lowering: control flow under quantum control
