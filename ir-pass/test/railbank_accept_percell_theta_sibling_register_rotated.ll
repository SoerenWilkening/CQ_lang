; railbank_accept_percell_theta_sibling_register_rotated.ll — THE CAPABILITY,
; WITH A NON-DIAGONAL GATE IN THE MODULE THAT MUST NOT MATTER.
;
; bd `xdu2` / L-1a W1, Rule-13 review F-1 (session 2026-09-15) + the owner
; constraint relayed the same day.  The capability the rail bank exists for is a
; **DISTINCT THETA PER CELL**, minted INSIDE the walk loop, per trip — the inner
; loop of `example/grover/grover_oracle_uncompute.c`.  It is NOT the shape the
; review's P1 probe has (ONE loop-invariant rail's name parked in N cells), and
; the memory-hop fence must separate them.  This fixture is the POSITIVE CONTROL
; that says so under adversarial conditions:
;
;   * the bank is per-cell (each trip's `cq_theta` mints its own rail, so no
;     register name outlives the trip and no later gate can relabel it), AND
;   * a genuinely NON-DIAGONAL gate — `cqrt_ry_i32(h, 0.7)`, a chained rotation
;     on an unrelated register `q` — sits BETWEEN the write loop and the measure
;     loop, exactly where `p01`'s staling gate sits.
;
; A fence seeded with the WRONG thing (the function's rails, the bank OBJECT, or
; "any theta between the loops") declines this module.  The shipped fence seeds
; at THE CELL'S OWN PARKED RAIL, which `q`'s wire never touches, so it accepts.
; That is why this file is worth more than a second copy of the canonical
; accept: the canonical accept has no non-diagonal gate to be confused by.
;
; ⚠ IT IS ALSO THE DISCRIMINATOR AGAINST THE MEASURED STOPGAP.  The Rule-13
; review offered a cheaper conjunct — *refuse a `Bank` whose stored value is not
; defined inside `L`* — which flips zero registered accepts and closes the P1.
; It was NOT taken, because it over-declines the legitimate invariant-park
; ordering (`railbank_accept_invariant_rail_measured_before_gate.ll`).  This
; module is on the OTHER side of that line: it passes the stopgap too, so it
; cannot tell the two fixes apart, and the reader should not read it as doing so.
;
; MEASURED on the fix binary: ACCEPT, 13 trace lines, STRICT stage 2b
; `2 rail mint(s) of which 2 left allocated, 0 cqrt_free site(s): 0 verified,
; 0 violation(s), 0 unproven`.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/session-2026-09-15-orchestrator/bfix/probes/o04_percell_theta_other_reg_rotated.c`:
;   int slice(void) {
;       int b0[3]; int s = 0;
;       for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
;       int q = cq_theta(0, 0.3);
;       q = cq_theta(q, 0.7);
;       for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
;       return s + cq_measure(q);
;   }
;   int main(void) { (void) slice(); return 0; }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR     --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CRY    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS   --input-file=%t.ll %s

; The bank is claimed and retyped; the per-trip mint is INSIDE the rolled loop.
; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: call i32 @cqrt_alloc_i32(i32 0)
; IR: call void @cqrt_ry_i32(i32 %{{.*}}, double 5.000000e-01)
; IR: store i32 %{{.*}}, ptr %{{.*}}, align 4

; ONE WHOLE-FILE PREFIX PER COUNTED SYMBOL (Rule 12 hygiene defect (a)).  ROLLED,
; so ONE mint site for the bank plus ONE for `q`; THREE `ry` (the rolled per-cell
; prep, `q`'s source and `q`'s chained 0.7); TWO measure sites (the rolled bank
; loop and `q`).
; CALLOC-COUNT-2: call i32 @cqrt_alloc_i32(
; CRY-COUNT-3: call void @cqrt_ry_i32(
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(

; PURE NEGATIVES.
; NOTS-NOT: cqrt_free
; NOTS-NOT: cq_template
; NOTS-NOT: cq_theta_
; NOTS-NOT: cq_measure_
;
; ⚠ ONE OF THESE NEGATIVES WAS **VACUOUS** AND WAS REPLACED, RECORDED HERE
; RATHER THAN QUIETLY FIXED (Rule 12 hygiene defect (c); CLAUDE.md L10 — an
; instrument's failure mode is to report a pass).  The first draft carried
; `NOTS-NOT: 3 x i8`, copied from the `_Bool`-bank fixtures where it pins the
; type rewrite.  THIS bank has `int` cells: `3 x i8` does not occur in this
; module's IR at ALL, before or after lowering, so the check could never have
; fired.  MEASURED (comments stripped): 0 occurrences in the input body, 0 in
; the lowered output.  The replacements are non-vacuous by the same
; measurement — `cq_theta_` / `cq_measure_` occur on 10 and 7 body lines of
; the INPUT respectively and on ZERO lines of the output, so they pin the
; pass's postcondition (`declineSurvivingIntrinsicCalls`: no
; `@cq_{theta,phi,measure}_<sfx>` may remain) on a module where a failure to
; lower the bank read is exactly how that postcondition would break.

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #3
  br label %5

2:                                                ; preds = %5
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #3
  br label %15

5:                                                ; preds = %0, %5
  %6 = phi i64 [ 0, %0 ], [ %10, %5 ]
  %7 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %6
  %8 = load i32, ptr %7, align 4, !tbaa !6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #3
  store i32 %9, ptr %7, align 4, !tbaa !6
  %10 = add nuw nsw i64 %6, 1
  %11 = icmp eq i64 %10, 3
  br i1 %11, label %2, label %5, !llvm.loop !10

12:                                               ; preds = %15
  %13 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %14 = add nsw i32 %13, %21
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #3
  ret i32 %14

15:                                               ; preds = %2, %15
  %16 = phi i64 [ 0, %2 ], [ %22, %15 ]
  %17 = phi i32 [ 0, %2 ], [ %21, %15 ]
  %18 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %16
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %21 = add nsw i32 %20, %17
  %22 = add nuw nsw i64 %16, 1
  %23 = icmp eq i64 %22, 3
  br i1 %23, label %12, label %15, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
