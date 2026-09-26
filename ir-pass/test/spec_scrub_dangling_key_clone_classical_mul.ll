; bd test_C_libtooling-8e5r (P1 SILENT MISCOMPILE, pre-existing) — a DANGLING
; `taint.Tainted` KEY aliased by a Phase-6 clone's CLASSICAL instruction.
;
; THE DEFECT. `lowerShadowMemory` / `lowerQramReads` erased the tainted
; store/load/GEP of the shadow array (`arr[q2&7]=7; arr[q&7]=9; r1=arr[...]`)
; WITHOUT removing them from `taint.Tainted`, so the freed pointers stayed KEYS.
; `specialize()` then built the clone `@__cq_q_k1_*` of `k1(a,b) = a*7 + b` with
; `a` classical and `b` quantum; the clone's classical `mul nsw i32 %0, 7` is a
; 128-byte `User` allocation, the size class of a freed `StoreInst`, and landed
; on one. The module-level `lowerOps` walks clone bodies, asked
; `taint.Tainted.count(mul)`, got TRUE, and emitted
;     %h_op1 = call i32 @cq_template_mul_i32_hl(i32 7, i32 %0)   ; 7 as a HANDLE
;     %h_op  = call i32 @cq_template_add_i32_hl(i32 %1, i32 %h_op1)
; — the constant 7 passed as a qubit handle, the classical `m` as the literal,
; and a handle id as the add's literal. `opt` exit 0, verify-clean, stage 2b
; `3 verified, 0 violation(s)`. At run time: `cq_template_mul_i32_hl(h7, 5)` on
; the ALREADY-FREED rail h7 and `cq_template_add_i32_hl(h1, 10)` where the right
; gate is `add_hl(h1, 35)` (see the e2e twin `e2e-spec-scrub-dangling-key`).
;
; THE FIX IS TOTAL, NOT A SITE: every pointer-keyed `TaintSet` table is a
; self-cleaning container (`include/ScrubOnDelete.h`) — LLVM's own `~Value()`
; callback drops a deleted key, so no erase site has to remember to.
;
; WHY THREE ALLOCATOR MODES. Whether the stale key is ALIASED is decided by the
; allocator, so under the system allocator this module is a LOTTERY on the
; unfixed binary (THIS file, 20 runs each, oracle `def1b088`: the frozen `cq-opt`
; wrong 16/20; the same sources + the test allocator, unset, wrong 15/20).
; `CQ_OPT_DEBUG_ALLOC` (`ir-pass/tools/cq_debug_alloc.cpp`, linked only into
; `%debugalloc-cq-opt` = `cq-opt-debugalloc`, never into `%cq-opt` or the plugin)
; makes it deterministic:
;   lifo   — exact-class LIFO address reuse for the blocks the test allocator
;            manages (non-aligned new/delete: IR objects, hooks, std nodes —
;            see cq_debug_alloc.cpp's SCOPE): the unfixed binary is WRONG
;            20/20; the fixed one is right 20/20;
;   nofree — no reuse at all: the no-aliasing REFERENCE stream (the unfixed
;            binary is right 20/20 here, and it is byte-identical to the fixed
;            binary's output in all three modes).
; The pin is BOTH that the `lifo` stream is the correct one (FileCheck) AND that
; the three modes emit byte-identical modules (`diff`): a lowering whose output
; depends on where the allocator puts things is the defect, whatever it emits.
; ⚠ An allocation-coincidence pin is only as durable as the coincidence: an
; unrelated change to the pass's allocation sequence can move it. The per-member
; deterministic pin that does NOT depend on a coincidence is `cq-scrub-selftest`
; (ctest `ir-pass-scrub-on-delete-selftest-lifo`); this fixture is the
; end-to-end one.
;
; Source (two TUs, `llvm-link`ed as `run_slice_multi.sh` does):
;   int k1(int a, int b) { return (a * 7) + b; }            // lib.c, no CQ.h
;   volatile int M = 5, N = 3;
;   int main(void) { int m = M, n = N; int acc = 0;
;     int q = cq_theta(m, .5); int q2 = cq_theta(n, .25);
;     int arr[8] = {0}; arr[q2 & 7] = 7; arr[q & 7] = 9;
;     int r1 = arr[(q2 + 1) & 7]; acc += cq_measure(r1);
;     int u = k1(m, q); int v = k1(n, q2);
;     return (acc + cq_measure(u) + cq_measure(v) + cq_measure(q2) + cq_measure(q)) & 0; }
;
; RUN: env CQ_OPT_DEBUG_ALLOC=lifo %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.lifo.ll
; RUN: env CQ_OPT_DEBUG_ALLOC=nofree %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.nofree.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.sys.ll
; RUN: %filecheck %s --implicit-check-not=cq_template_mul < %t.lifo.ll
; RUN: diff %t.lifo.ll %t.nofree.ll
; RUN: diff %t.lifo.ll %t.sys.ll

; The QRAM shadow array whose store/load/GEP erasure left the dangling keys.
; CHECK-LABEL: define noundef i32 @main()
; CHECK:         call void @cqrt_qram_store_i32(
; CHECK:         call void @cqrt_qram_store_i32(
; CHECK:         call i32 @cqrt_qram_load_i32(
; Both call sites retargeted to the ONE clone (arg 0 classical, arg 1 quantum).
; CHECK:         call i32 @__cq_q_k1_[[N:[0-9]+]](i32 noundef %{{[0-9]+}}, i32 noundef %h)
; CHECK:         call i32 @__cq_q_k1_[[N]](i32 noundef %{{[0-9]+}}, i32 noundef %h2)
; The clone: the classical product stays a CLASSICAL `mul`, and is the add's
; LITERAL; the quantum argument %1 is the only handle.
; CHECK:       define internal i32 @__cq_q_k1_[[N]](i32 noundef %0, i32 noundef %1)
; CHECK-NEXT:    %[[P:[0-9]+]] = mul nsw i32 %0, 7
; CHECK-NEXT:    %h_op = call i32 @cq_template_add_i32_hl(i32 %1, i32 %[[P]])
; CHECK-NEXT:    %cqq.out = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:    call void @cqrt_copy_i32(i32 %h_op, i32 %cqq.out)
; CHECK-NEXT:    call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %1, i32 %[[P]])
; CHECK-NEXT:    call void @cqrt_free(i32 %h_op)
; CHECK-NEXT:    ret i32 %cqq.out

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@M = global i32 5, align 4
@N = global i32 3, align 4

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = alloca [8 x i32], align 16
  %2 = load volatile i32, ptr @M, align 4, !tbaa !6
  %3 = load volatile i32, ptr @N, align 4, !tbaa !6
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #5
  %5 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.500000e-01) #5
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %1) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %1, i8 0, i64 32, i1 false)
  %6 = and i32 %5, 7
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %7
  store i32 7, ptr %8, align 4, !tbaa !6
  %9 = and i32 %4, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %10
  store i32 9, ptr %11, align 4, !tbaa !6
  %12 = add nsw i32 %5, 1
  %13 = and i32 %12, 7
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %18 = tail call i32 @k1(i32 noundef %2, i32 noundef %4) #5
  %19 = tail call i32 @k1(i32 noundef %3, i32 noundef %5) #5
  %20 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  %21 = tail call i32 @cq_measure_si32(i32 noundef %19) #5
  %22 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  %23 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %1) #5
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @k1(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = mul nsw i32 %0, 7
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.module.flags = !{!1, !2, !3, !4, !5}

!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
