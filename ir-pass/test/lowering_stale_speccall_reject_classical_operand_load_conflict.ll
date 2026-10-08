; lowering_stale_speccall_reject_classical_operand_load_conflict.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 1 F2): the decline twin of
; lowering_stale_speccall_classical_operand_placed_accept.ll. Hand IR.
;
; The stale lifted call's classical operand is `load @G * 3`, and a STORE to `@G`
; sits between the gate and the load. Carrying the load to the placement slot would
; move it above the store and change the value `f` receives, so the placement
; refuses (StaleReadPlacement.h clause (e), asked of every carried instruction, not
; only of the call) and the stale fence declines with its one string.
; An OVER-DECLINE kept loud: the store's value is classical and available before the
; gate, so carrying the store as well would be legal here; the placement carries
; only operands, never an instruction it would have to reorder memory around.
; RETIREMENT TRIGGER (L7): a placement that also carries the conflicting memory
; chain, or 57ch (B), flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32): cq opcode lowering: operand predates a non-diagonal gate

@G = global i32 0, align 4

define i32 @f(i32 noundef %x, i32 noundef %k) local_unnamed_addr #0 {
  %m = mul nsw i32 %x, 3
  %r = add nsw i32 %m, %k
  ret i32 %r
}

define i32 @main(i32 noundef %a) local_unnamed_addr #1 {
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %q, double noundef 3.000000e-01) #2
  store i32 %a, ptr @G, align 4
  %g = load i32, ptr @G, align 4
  %k = mul nsw i32 %g, 3
  %r = tail call i32 @f(i32 noundef %q, i32 noundef %k)
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %r) #3
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %q2) #3
  %s = add nsw i32 %m2, %m1
  ret i32 %s
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
