; lowering_stale_speccall_reject_crossed_callsite_attrs.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 2 R2-5). Hand IR.
;
; The stale lifted call's classical operand `load @G` would be carried above `@w`,
; whose CALL SITE claims `memory(none)` (as `bindLibmCalls` keeps the libc
; declaration's attributes on a call bound to an injected body) while its
; DEFINITION writes `@G` (the `lgamma`/`signgam` shape). The placement asks a call's
; memory effects of its definition on BOTH sides, moved and crossed
; (StaleReadPlacement.cpp `memoryEffectsOf`), so the load may not cross the store
; inside `@w`, and the stale fence declines. The round-1 snapshot 8c517ac4 asked the
; crossed side of the call site, carried the load, and `f` received the pre-`@w`
; value of `@G` (measured: exit 0, `load @G` above `ry(h, .3)` and above `@w`).
; RETIREMENT TRIGGER (L7): a placement that carries the conflicting call too, or
; 57ch (B).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32): cq opcode lowering: operand predates a non-diagonal gate

@G = global i32 0, align 4

define i32 @w(i32 noundef %v) local_unnamed_addr #4 {
  store i32 %v, ptr @G, align 4
  ret i32 %v
}

define i32 @f(i32 noundef %x, i32 noundef %k) local_unnamed_addr #0 {
  %m = mul nsw i32 %x, 3
  %r = add nsw i32 %m, %k
  ret i32 %r
}

define i32 @main(i32 noundef %a) local_unnamed_addr #1 {
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %q, double noundef 3.000000e-01) #2
  %z = tail call i32 @w(i32 noundef %a) #5
  %g = load i32, ptr @G, align 4
  %r = tail call i32 @f(i32 noundef %q, i32 noundef %g)
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %r) #3
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %q2) #3
  %s = add nsw i32 %m2, %m1
  %t = add nsw i32 %s, %z
  ret i32 %t
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
attributes #4 = { noinline nounwind willreturn }
attributes #5 = { nounwind willreturn memory(none) }
