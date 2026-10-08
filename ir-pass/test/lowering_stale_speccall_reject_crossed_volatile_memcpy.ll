; lowering_stale_speccall_reject_crossed_volatile_memcpy.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 4 R4-1; OWNER RULING 2026-10-08, bd memory
; owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08).
;
;   struct S { int a[8]; };
;   volatile struct S src;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     struct S dst = src;              // a VOLATILE struct copy: memcpy(..., i1 true)
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + dst.a[argc & 7];
;   }
;
; Clang lowers the volatile struct copy to `llvm.memcpy` with its volatile flag set,
; a volatile access (`Instruction::isVolatile` asks `MemIntrinsic::isVolatile`), so
; the moved gates may not cross it, while the non-volatile `llvm.lifetime.start` in
; front of it is crossable. The stale fence declines. The non-volatile twin (a local
; initializer's memcpy) is placed: review probe r2_crossed_lifetime.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

%struct.S = type { [8 x i32] }

@src = global %struct.S zeroinitializer, align 4

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = alloca %struct.S, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #4
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %3, ptr align 4 @src, i64 32, i1 true)
  %6 = tail call i32 @f(i32 noundef %4)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5) #4
  %9 = add nsw i32 %8, %7
  %10 = and i32 %0, 7
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = add nsw i32 %9, %13
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #4
  ret i32 %14
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #5

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
