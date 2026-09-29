; spec_accept_musttail_in_clone_demoted.ll — ACCEPT — a `musttail` call inside a CLONE is demoted (bd
; test_C_libtooling-m5pn, found by the bd nlfd/ev3m cell table, 2026-09-28; 2 TUs, plain C).
;
; `int h(int a, int k){ __attribute__((musttail)) return h2(a, k); }` with `h2` READING `a`
; (`return k + a;`), called with a quantum `p`. `h2`'s clone returns a quantum rail, so `h`'s
; clone's Bennett wrap copies it out AFTER the inner call — and on `main` 9a230646 the
; `musttail` marker cloned from `h` was then no longer followed by `ret`: the verifier ABORTED
; the whole run (exit 134, `musttail call must precede a ret`). `musttail` promises only the
; tail-call lowering (for every argument kind reachable from C; a `preallocated` forward is
; declined earlier, `spec_reject_musttail_forward_preallocated.ll`), so `stripStaleClassicalAttrs`
; now demotes it in every clone body (the CLONE lines; the ORIGINAL `h`, a non-clone, keeps its
; `musttail` — the CHECK-NEXT line). ⚠ The one cause is code emitted after the call; round 1's
; second reason ("the fp→i32 rewrite changes prototypes") was false on the reachable surface
; (Rule-13 r1B F-r1B-4). The trace is byte-identical to the plain-`tail` spelling's. ⚠ Until
; bd rhk5 landed (9ad22639) that trace was rhk5's warned wrong unitary (the clone call sits
; between `p = q * 3` and its phase consumer) and `main`'s stream was deliberately NOT pinned
; (bd jlf8); on the merged binary it is clean (0 warnings, 0 dirty, 2b STRICT) and the
; hand-inlined twin's circuit, so it is pinned now (r1B F-r1B-5 — whose note that round 1's
; "1 warning" comment would go stale was the retirement trigger). Remove the demotion and this
; file ABORTS again (mutant D1).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) {
;     int m = atoi(v[1]);
;     int q = cq_theta(m & 7, .5); int p = q * 3; int r = h(p, m); int u = p ^ q;
;     if (u == 10) cq_phi(3.14159);
;     q = cq_theta(q, .7);
;     return cq_measure(q) + cq_measure(r);
;   }
; Library TU (plain C, no CQ.h):
;   __attribute__((noinline)) int h2(int a, int k) { return k + a; }
;   int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }
;
; Regenerate (tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19): clang -O1
; -emit-llvm -S the caller with -I<repo>/include -include CQ.h, the library without it,
; then llvm-link -S caller.ll lib.ll.
;
; Twin (trace-compared, tools/pairs.py): its plain-`tail` spelling `mtlN` (byte-identical traces) and the hand-inlined twin `mtlT` (TRACE-EQUIV, tools/trace_twin_equiv.py) — both measured on the binary merged with bd rhk5 9ad22639; the e2e pair `e2e-spec-musttail-clone-live-arg-twin-equivalent` links it.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of each function (derived from the lowered module; SSA
; names wildcarded, constants — every dropped `0` and every angle — kept). Between
; consecutive matches NO other runtime/clone call may appear, so the stream is pinned
; EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr nocapture noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_01(i32 noundef %{{[a-zA-Z0-9_.]+}}, i32 noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_xor_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 10)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_rz_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 3.141590e+00), !cq.branchphase !10
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 10)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_xor_i32_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_mul_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret 
; CHECK-LABEL: define {{.*}}@h(
; CHECK-NEXT: musttail call i32 @h2(
; CLONE-LABEL: define internal i32 @__cq_q_h_01(
; CLONE-NOT: musttail
; CLONE: call i32 @__cq_q_h2_01(
; CLONE-NOT: musttail
; CLONE: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #5
  %8 = mul nsw i32 %7, 3
  %9 = tail call i32 @h(i32 noundef %8, i32 noundef %5) #5
  %10 = xor i32 %8, %7
  %11 = icmp eq i32 %10, 10
  br i1 %11, label %12, label %13

12:                                               ; preds = %2
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %13

13:                                               ; preds = %12, %2
  %14 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 0x3FE6666666666666) #5
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %9) #5
  %17 = add nsw i32 %16, %15
  ret i32 %17
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = musttail call i32 @h2(i32 noundef %0, i32 noundef %1)
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
