; lowering_stale_speccall_reject_crossed_maynot_return_builtin_setjmp.ll — DECLINE (bd
; test_C_libtooling-57ch.4; OWNER RULING 2026-10-13, bd memory
; owner-ruling-57ch4-maynot-return-2026-10-13; batch 053 narrow review): the module
; holds a `__builtin_setjmp`, so a call that may not return is not crossed.
;
;   void *env[5];
;   int g;
;   __attribute__((noinline)) void h(int i) { g = g * 3 + i; }
;   __attribute__((noinline)) void spin(int n) { for (int i = 0; i < n; i++) h(i); }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int landing(void) { return __builtin_setjmp(env); }   // llvm.eh.sjlj.setjmp: no returns_twice attribute
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     spin(argc);                      // CROSSED: may not return
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + g;
;   }
;
; clang -O1 emits `__builtin_setjmp` as `call i32 @llvm.eh.sjlj.setjmp(ptr)`, declared
; with only `nounwind`: no `returns_twice` attribute anywhere. A scan for that
; attribute alone found "no setjmp" and the placement crossed `spin` (rc 0 on the
; reviewed snapshot). The ruling's "no setjmp" covers the builtin, so the module scan
; also counts `Intrinsic::eh_sjlj_setjmp` call sites (`callTerminationCrossable`,
; StaleReadRegion.h) and the stale fence declines. Siblings: the libc `setjmp`
; spelling lowering_stale_speccall_reject_crossed_maynot_return_setjmp.ll; the accept
; without a landing point lowering_stale_speccall_reject_crossed_maynot_return_callee.ll.
; RETIREMENT TRIGGER (L7): 57ch (B), or a proof that no `longjmp` reaches the
; landing point from the crossed call.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32, ptr): cq opcode lowering: operand predates a non-diagonal gate

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4
@env = global [5 x ptr] zeroinitializer, align 16

define void @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = load i32, ptr @g, align 4
  %3 = mul nsw i32 %2, 3
  %4 = add nsw i32 %3, %0
  store i32 %4, ptr @g, align 4
  ret void
}

define void @spin(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %4, label %3

3:                                                ; preds = %4, %1
  ret void

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %6, %4 ], [ 0, %1 ]
  tail call void @h(i32 noundef %5)
  %6 = add nuw nsw i32 %5, 1
  %7 = icmp eq i32 %6, %0
  br i1 %7, label %3, label %4
}

define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @landing() local_unnamed_addr #3 {
  %1 = tail call ptr @llvm.frameaddress.p0(i32 0)
  store ptr %1, ptr @env, align 16
  %2 = tail call ptr @llvm.stacksave.p0()
  store ptr %2, ptr getelementptr inbounds (i8, ptr @env, i64 16), align 16
  %3 = tail call i32 @llvm.eh.sjlj.setjmp(ptr nonnull @env)
  ret i32 %3
}

declare ptr @llvm.frameaddress.p0(i32 immarg) #4

declare ptr @llvm.stacksave.p0() #5

declare i32 @llvm.eh.sjlj.setjmp(ptr) #6

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #8
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #8
  tail call void @spin(i32 noundef %0)
  %5 = tail call i32 @f(i32 noundef %3)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #6
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4) #6
  %8 = add nsw i32 %7, %6
  %9 = load i32, ptr @g, align 4
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) }
attributes #1 = { nofree noinline norecurse nosync nounwind memory(readwrite, inaccessiblemem: none) }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #3 = { nounwind }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn memory(none) }
attributes #5 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #6 = { nounwind }
attributes #8 = { nomerge nounwind }
