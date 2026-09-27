; spec_accept_phantom_arg_read_byval_slot_kept.ll — ACCEPT, the pointer slot KEPT (bd test_C_libtooling-91k9; bd vsfp Rule-13 r4A
; F-YA-1, probe `bv`; 2 TUs).
;
; The callee is `int h(int a, struct Big s)` (a `byval` struct slot `h` never reads). The clone records that slot dead, and rounds 3–4 NEUTRALISED it with
; `Constant::getNullValue(<param type>)` — for a pointer that is `null`: the call became
; `ptr noundef nonnull byval(%struct.Big) align 8 null` and the linked executable SIGSEGVed (exit
; 139; `pn` got `nonnull null` into a `dereferenceable(16)` parameter — immediate UB), while opt,
; the verifier and stage 2b were all clean. The ORACLE compiles it correctly. Since round 5 the
; one rewrite applies the pre-`specialize()` drop's own eligibility (`dropEligibleSlot`: an int/fp
; scalar, no `byval`/`inalloca`/`preallocated`/`returned`/`swifterror`, allowlisted attributes
; only), so a pointer slot is never rewritten — a classical pointer left in a dead slot costs
; nothing (no rail, no spine). The NONULL prefix pins that no pointer argument is `null`; the
; main CHECKs pin the stream (the ORACLE's, byte-identical; the executable exits 5, measured).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   struct Big { int x[8]; };
;   int h(int a, struct Big s);
;   int main(int c, char **v) {
;     int m = atoi(v[1]);
;     struct Big b = {{m, 1, 2, 3, 4, 5, 6, 7}};
;     int q = cq_theta(m & 7, .5);
;     int r = h(q, b);
;     return cq_measure(r) + b.x[0];
;   }
; Library TU (plain C, no CQ.h):
;   struct Big { int x[8]; };
;   int h(int a, struct Big s) { return a * 3; }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NONULL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr nocapture noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, ptr noundef nonnull byval(%{{[a-zA-Z0-9_.]+}}) align 8 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG
;
; No pointer argument is neutralised to null (bd 91k9):
; NONULL-NOT: align {{[0-9]+}} null
; NONULL-NOT: nonnull null

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.Big = type { [8 x i32] }

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = alloca %struct.Big, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  %5 = load ptr, ptr %4, align 8, !tbaa !6
  %6 = tail call i32 @atoi(ptr nocapture noundef %5)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #5
  store i32 %6, ptr %3, align 8, !tbaa !10
  %7 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 1, ptr %7, align 4, !tbaa !10
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  store i32 2, ptr %8, align 8, !tbaa !10
  %9 = getelementptr inbounds i8, ptr %3, i64 12
  store i32 3, ptr %9, align 4, !tbaa !10
  %10 = getelementptr inbounds i8, ptr %3, i64 16
  store i32 4, ptr %10, align 8, !tbaa !10
  %11 = getelementptr inbounds i8, ptr %3, i64 20
  store i32 5, ptr %11, align 4, !tbaa !10
  %12 = getelementptr inbounds i8, ptr %3, i64 24
  store i32 6, ptr %12, align 8, !tbaa !10
  %13 = getelementptr inbounds i8, ptr %3, i64 28
  store i32 7, ptr %13, align 4, !tbaa !10
  %14 = and i32 %6, 7
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 5.000000e-01) #5
  %16 = tail call i32 @h(i32 noundef %15, ptr noundef nonnull byval(%struct.Big) align 8 %3) #5
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %18 = load i32, ptr %3, align 8, !tbaa !10
  %19 = add nsw i32 %18, %17
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #5
  ret i32 %19
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, ptr nocapture noundef readnone byval(%struct.Big) align 8 %1) local_unnamed_addr #4 {
  %3 = mul nsw i32 %0, 3
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
