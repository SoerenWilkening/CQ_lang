; lowering_stale_speccall_reject_crossed_fake_intrinsic.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 5 R5-2). Hand IR (the review's probe
; s4_fake_intrinsic_nosync).
;
; `@llvm.cq.port.write` is an EXTERNAL declaration whose name merely starts with
; `llvm.` (LLVM 19 accepts it; its intrinsic ID is `not_intrinsic`; a C asm label
; reaches the same name). `nosync` is truthful for a body that does a monotonic store
; to a device word, which the ruling counts. The crossing test asks
; `getIntrinsicID() != not_intrinsic`, never `Function::isIntrinsic()`'s name prefix,
; so this is an opaque declaration that may touch memory: refused, like the same
; declaration under any other name (review probe s5_renamed_decl_control). The
; snapshot 823b12c5 admitted it on `nosync`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

define i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #2 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #3
  tail call void @llvm.cq.port.write(i32 1)
  %3 = tail call i32 @f(i32 noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %6 = add nsw i32 %5, %4
  ret i32 %6
}

declare void @llvm.cq.port.write(i32) #0
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { nosync nounwind willreturn }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
