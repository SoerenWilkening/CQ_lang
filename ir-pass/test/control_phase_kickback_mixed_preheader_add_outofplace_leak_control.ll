; control_phase_kickback_mixed_preheader_add_outofplace_leak_control.ll —
; ACCEPT **AND LEAKS**, deliberately. bd test_C_libtooling-3qlq Inc 1, the SECOND
; C-1 review round, finding F-C1-1's DISCRIMINATING CONTROL: the same mixed loop
; whose preheader `add` M-C lowers OUT OF PLACE, because the PRE-op value is read
; after it.
;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int keep = q;                                  /* the pre-op value */
;       q = q + 7;
;       for(int i=0;i<3;i++){ if((q>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       return cq_measure(keep)+cq_measure(r); }
;
; WHAT THIS PINS, AND WHY IT IS AN ACCEPT RATHER THAN A DECLINE. M-C's G6/G7 pair
; refuses an in-place reassignment whose parent has a LATER read, so the `add`
; mints a FRESH `cq_template_add_i32_hl` rail — a loop-invariant TEMPLATE rail
; read by the body's condition, i.e. owner question **Q-R1-1** exactly. The
; extension MUST refuse it (a template rail is what `isInteriorTerminalHandle`
; clause (I1) ADMITS, so the multiplicity argument that licenses a root mint does
; not carry), and refusing means the per-trip bit rails are NOT discharged. That
; leak is the Prime-Directive disposition until Q-R1-1 is ruled: a rail left
; allocated is never a wrong free (Rule 6), and this file's job is to prove the
; F-C1-1 widening did NOT reach it.
;
; MEASURED IDENTICAL on 542d588, on the round-1 C-1 fix and on this HEAD: rolled
; `cq_template_and_i32_hl` 3 / `_unc` **0** against a hand-unrolled twin at 3/3,
; and the rolled trace is BYTE-UNCHANGED across all three binaries.
;
; It is ALSO the fixture that pins the STABILITY conjunct of the fix. The commit
; predicate is `classifyInPlaceReassignment` AND `P->hasOneUse()`; here BOTH fail
; (M-C itself refuses, and `%q` has two uses), so the file discriminates the
; widening from the leak without depending on which conjunct fires.
;
;
; ⚠⚠ RE-DERIVED 2026-09-21 — bd `test_C_libtooling-4jok`, WHEN bd `tu9q` P0+P3
; LANDED.  The PER-TRIP `and` rail now gains an IN-BODY `_unc` + `cqrt_free`,
; because the body is MARKED and `planInteriorComponent` §2.9 will place an
; in-body `At` for it.  Three directives moved and each moved for that ONE
; reason: the `CHECK-NEXT` chain (two lines now sit between the flag's
; `icmp_eq_unc` and its `cqrt_free`), the pure-negative on
; `@cq_template_and_i32_hl_unc` (which is now PRESENT and is the POINT), and the
; `cqrt_free` census, 2 -> 3.
;
; ⚠ THE NEGATIVE IS NOT DELETED, IT IS INVERTED, AND THAT DISTINCTION IS THE
; WHOLE RE-DERIVATION.  The old line asserted the per-trip chain does NOT
; discharge — `CLAUDE.md` §5 calls that stream *"the ACCEPT was the defect"* and
; says *"do not restore their old `CHECK` prefixes, which pinned the leaking
; stream."*  Read literally that forbids the old prefix; it does not forbid a
; POSITIVE prefix over the DISCHARGING stream, which is the opposite property.
; Getting that backwards — deleting the line, or keeping it — is the single
; easiest mistake at this landing and Rule-13 round 5 (F-5) says so in writing.
;
; ⚠ THE FREE CENSUS IS NOW 3 AND EACH ONE IS NAMED, because an EXTRA free is a
; hidden measurement (Rule 6) and a census whose members are not named stops
; being a census: (1) the per-trip condition FLAG `%h_cmp`, `cqrt_x`-bracketed
; and returned by its `icmp_eq_unc`; (2) the per-trip `and` RAIL, returned by the
; `and_i32_hl_unc` immediately above it — THE NEW ONE; (3) the HOISTED rail at
; the loop EXIT, whose `EXITD` prefix pins it positionally.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=EXITD < %t.cqd0.ll
;
; bd `tu9q` P2 — the HOISTED rail's discharge, pinned POSITIONALLY and not only
; counted: it sits in the loop-EXIT block, immediately before the post-loop
; measures, which no in-body placement could produce.
; EXITD: call void @cq_template_add_i32_hl_unc(i32 %h_op, i32 %h, i32 7)
; EXITD-NEXT: call void @cqrt_free(i32 %h_op)
; EXITD-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h)

; The two root mints, then ⭐ the preheader op as a FRESH OUT-OF-PLACE RAIL.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[P:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[Q]], i32 7)

; The body reads the TEMPLATE rail, and its bit rail is minted, flag-stripped and
; freed — but the `and` itself is NEVER discharged. That missing line is the leak
; this file exists to pin.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[P]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[P]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; ⭐ ZERO `and` discharges — the Q-R1-1 leak, unchanged by the F-C1-1 widening.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ⭐ The preheader op is OUT of place: no `cqrt_addc` anywhere, exactly one
; out-of-place template rail. This is the mirror of
; `..._preheader_addc_inloop.ll`'s `PCNT` block.
; PCNT-NOT: call void @cqrt_addc_i32(
; PCNT-COUNT-1: call i32 @cq_template_add_i32_hl(
; PCNT-NOT: call i32 @cq_template_add_i32_hl(

; ── CONVERTED IN PLACE, 2026-09-18 (bd `test_C_libtooling-tu9q`, piece P2) ────
; ⚠ **THIS CENSUS SAID "ONE free in the body: the flag alone (the bit rail is the
; leak)" AND THE COUNT IS NOW 2.** The second free is NOT in the body: it is the
; HOISTED `add` rail `%h_op`, minted once in the preheader and now discharged ONCE
; at the LOOP EXIT by `Uncomputation::anchorForConsumer`. The bit (`and`) rail is
; still the leak, and `UCNT-NOT` above still pins that — the two halves of the old
; sentence came apart and only one moved.
;
; CORRECTNESS, on the operands: `%h_op = %h + 7` has exactly one in-loop user and
; it READS (`cq_template_and_i32_hl`); the only non-diagonal gate in the body is
; `cqrt_ry_i32(%h1, 0.1)` on the OTHER register, so nothing writes `%h` between the
; mint and the exit and the exit `_unc` reads the basis the forward `add` read
; (clause (d)'s LEFT disjunct). One mint, one adjoint: `multiplicityAgrees` keys
; both endpoints to `nullptr` (neither the preheader nor the exit is marked).
;
; ⚠ L8 RETIREMENT TRIGGER: when P0/P3 lands, the per-trip `and` gains its own
; in-body pair, `UCNT-NOT` fires and this count goes to 3. Re-derive then against
; the hand-unrolled twin's MULTISET; do not relax the census into a range.
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; XCNT-COUNT-2: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg

; ModuleID = 'p/x2_preadd_keep.c'
source_filename = "p/x2_preadd_keep.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = add nsw i32 %2, 7
  br label %9

5:                                                ; preds = %16
  %6 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %8 = add nsw i32 %7, %6
  ret i32 %8

9:                                                ; preds = %1, %16
  %10 = phi i32 [ 0, %1 ], [ %18, %16 ]
  %11 = phi i32 [ %3, %1 ], [ %17, %16 ]
  %12 = shl nuw nsw i32 1, %10
  %13 = and i32 %12, %4
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %16, label %15

15:                                               ; preds = %9
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %16

16:                                               ; preds = %15, %9
  %17 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 1.000000e-01) #2
  %18 = add nuw nsw i32 %10, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %5, label %9, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1


attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
