; control_swap_reject_nested_cond_datause_dead.ll — DECLINE probe (ziov.3,
; Unowned arm): a depth-2 phase nest whose OUTER condition is reused as data, but
; the data lineage is DEAD WITHIN THE FUNCTION — neither measured nor escaped.
;
; `%c1 = icmp sgt q, 5` feeds the `br` AND `%d = zext %c1`, but `%d`'s lineage
; (`%dead = add %d, 7`) is never measured, returned, nor inverted — a quantum bit
; computed then orphaned. This is the SAME dirty-entangled-rail hazard the flat
; path declines (Rule 6/8): sharing would leave the flag allocated AND entangled
; with q with no downstream owner. The nested disposition declines it with the
; SAME string as the flat path ("condition data use neither escaped nor
; measured") — char-for-char, so detection and the negative fixture cannot drift.
; The flat-path deferred-strip accept (ziov.2) was reviewed and CLOSED won't-fix
; as a silent miscompile (see control_swap_reject_cond_datause_dead.ll); this
; nested decline stands regardless and is the permanent disposition here too.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use neither escaped nor measured under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  %d  = zext i1 %c1 to i32          ; DATA use of the OUTER condition
  %dead = add i32 %d, 7             ; DEAD: never measured, returned, or inverted
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
