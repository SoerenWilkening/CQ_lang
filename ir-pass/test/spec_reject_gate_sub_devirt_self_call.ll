; spec_reject_gate_sub_devirt_self_call.ll — DECLINE, and above all TERMINATION (bd
; test_C_libtooling-p3kd.21, R11 r1 item 1; reviewer probe revS1/p1_devirt_rec.c).
;
;   typedef void (*fp_t)(void *, int, bool *);
;   __attribute__((noinline)) static void g(void *f, int n, bool *p) {
;     cq_theta(p, 0.1);
;     if (n > 0) ((fp_t)f)(f, n - 1, p);
;   }
;   int main(int argc, char **argv) { bool q = 0; g((void *)g, argc, &q); return cq_measure(q); }
;
; `g` is no member of a call cycle (its self-call is indirect), so the call in
; `main` is compiled at its site; the -O1 re-run then DEVIRTUALIZES the inlined
; indirect call into a direct `g(g, n - 1, p)` with the same trigger, and before
; the inline history every round inlined it again: the pass never ended. The
; history (SpecializeGateInline.h, LLVM's InlineHistory rule) refuses to inline
; `g` at a site produced by inlining `g`; that site keeps its loud owner. A
; classically bounded recursion through a function pointer is a goal-1 gap
; (follow-up filed from bd p3kd.21), not a physics decline. Mirrors the
; diagnostic character-for-character. `clang -O1 -include CQ.h` output verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function main i32 (i32, ptr): cq taint escape: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca i8, align 1
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %3) #4
  store i8 0, ptr %3, align 1, !tbaa !6
  call void @g(ptr noundef nonnull @g, i32 noundef %0, ptr noundef nonnull %3)
  %4 = load i8, ptr %3, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #4
  %7 = zext i1 %6 to i32
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %3) #4
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: noinline nounwind ssp uwtable
define internal void @g(ptr noundef %0, i32 noundef %1, ptr noundef %2) #2 {
  %4 = load i8, ptr %2, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef 1.000000e-01) #5
  %7 = zext i1 %6 to i8
  store i8 %7, ptr %2, align 1, !tbaa !6
  %8 = icmp sgt i32 %1, 0
  br i1 %8, label %9, label %11

9:                                                ; preds = %3
  %10 = add nsw i32 %1, -1
  tail call void %0(ptr noundef %0, i32 noundef %10, ptr noundef nonnull %2) #4
  br label %11

11:                                               ; preds = %9, %3
  ret void
}

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
