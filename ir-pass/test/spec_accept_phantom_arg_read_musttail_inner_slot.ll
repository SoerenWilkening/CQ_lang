; spec_accept_phantom_arg_read_musttail_inner_slot.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-w7nm; bd vsfp Rule-13 r5 F-Z-1, probe `mt1`; 2 TUs llvm-linked, stage 1 as the
; reviewer recorded it — ⚠ RE-SPELLED by bd ev3m, see below).
;
; r2B's `k19` main (`p = q * 3` feeds `h`'s dead slot and the oracle `(p ^ q) == 10`) with
; `int h(int a, int k) { __attribute__((musttail)) return h2(a, k); }`. `h2`'s clone records slot
; 0 dead; inside `h`'s clone that slot is on a `musttail` call. Round 5 asked the drop's WHOLE
; eligibility (`dropEligibleSlot`, whose `musttail` refusal was then a POLICY conservatism) in the
; liveness call-slot rule, so the inner slot counted as a READ, `h`'s parameter became live, the
; outer phantom slot was never neutralised, and the spine left `p`'s template rail dirty across
; `Ry(0.7)` — bd tzfa's wrong unitary, exit 0, the ORACLE's stream byte-for-byte. Round 6 asks
; `nullSafeSlot` there (slot type + attributes only). The CLONE prefix pins that `h`'s clone passes
; `0` into the inner call and holds no template; the main CHECKs pin the twin's stream (the
; `mul_i32_hl_unc` + `cqrt_free` of `p` before the second Ry).
;
; ⚠ bd ev3m (2026-09-28) RE-SPELLED THIS FILE, because it would otherwise have stopped pinning
; anything (CLAUDE.md Rule 12(c)). `h2` originally read `a` in a volatile-fold diamond, which is
; dead once the fenv stages run; ev3m made a `musttail` site drop-eligible, so the pre-specialize
; drop removed the whole chain (`h2` slot → `h`'s parameter → `main`'s slot) and no clone was ever
; built — this file went RED on its NODROP and CLONE lines while its C spelling (the e2e pair
; `e2e-spec-dropped-arg-musttail-inner-twin-identical`) stayed green for the TWIN's reason. `h2`
; now reads `a` in a BRANCH-ONLY empty diamond (IR-only: `-O1` folds one away), which the drop
; sees as a live read and only the CLONE's flatten kills. ⚠ CORRECTED in round 2 (Rule-13 r1B
; F-r1B-3): round 1 wrote here that "the in-clone `musttail` slot is still the subject" — FALSE.
; The same track's commit C demotes a clone's `musttail` in `cloneFor` (`stripStaleClassicalAttrs`,
; the first statement of `buildClone`), BEFORE any record or liveness question is asked, so from
; commit C on NO slot question is ever asked of a `musttail` call inside a clone: the w7nm
; mechanism is retired twice (commit B removed the drop's refusal, commit C the marker). What this
; file still pins is the GENERIC inner-slot neutralisation (`h2`'s clone records slot 0 dead, `h`'s
; clone passes `0` into its now-PLAIN inner call, `main` passes `0`) — worth keeping, but not the
; subject it was written for. The demotion itself is pinned by
; `spec_accept_musttail_in_clone_demoted.ll` (an `inalloca` forward is DECLINED since the
; owner's 2026-10-05 ruling: spec_reject_musttail_forward_inalloca.ll) and the e2e slices
; `e2e-slice-spec-musttail-{clone-live-arg,clone-partial-drop}` (linked, twin-equivalent).;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
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
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %{{[a-zA-Z0-9_.]+}})
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
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG
;
; The clone body reads nothing the caller did not pass: no template call (bd sqjq):
; CLONE-LABEL: define {{.*}}@__cq_q_h_
; CLONE-NOT: cq_template_
; CLONE: call i32 @__cq_q_{{g|h2}}_{{[0-9]+}}(i32 noundef 0,
; CLONE-NOT: cq_template_
; CLONE: ret 

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@K = internal global i32 7, align 4

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
  %16 = add nsw i32 %15, %9
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = icmp sgt i32 %0, 3   ; bd ev3m re-spell: a BRANCH-ONLY read (IR-only) — live before
  br i1 %3, label %nlfd.arm, label %nlfd.join   ; specialize, killed by the CLONE's flatten

nlfd.arm:
  br label %nlfd.join

nlfd.join:
  %4 = add nsw i32 %1, 1
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nounwind ssp willreturn uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = musttail call i32 @h2(i32 noundef %0, i32 noundef %1)
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nounwind ssp willreturn uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
