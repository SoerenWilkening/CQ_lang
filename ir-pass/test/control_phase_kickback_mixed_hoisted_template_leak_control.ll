; control_phase_kickback_mixed_hoisted_template_leak_control.ll — ACCEPT, AND IT
; LEAKS. bd test_C_libtooling-3qlq Inc 1, the Rule-13 CLEARANCE finding C-1. This
; is the DISCRIMINATING CONTROL for that fix: the shape one operator away from the
; one C-1 repaired, whose disposition the fix must NOT change.
;
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
;       for(int i=0;i<3;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
;       q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
;
; `clang -O1` on that source with `@main` dropped; `!llvm.loop` verbatim.
;
; WHAT IT PINS. The kickback's condition register is `p = q * 3` — a HOISTED
; LOOP-INVARIANT **TEMPLATE** rail (`cq_template_mul_i32_hl`), not a root mint. The
; loop is otherwise the C-1 shape exactly: `r` is loop-CARRIED, so
; `collapseRailPhisIn` returns `Collapsed`, and the `Collapsed` branch now also
; asks `invariantRegisterRoots`. Clause (ii) REFUSES `p` — a `cq_template_*` call
; is precisely what `ChainWalk::isInteriorTerminalHandle` clause (I1) ADMITS to the
; M-B interior partition, so it is precisely what may NOT be handed to
; `markIfRailLocal` as a Root: a recovered forward gate in the PREHEADER paired
; with an adjoint `At` in the K-times body is the multiplicity hazard that
; function's own comment names, and only the (I1) exclusion rules it out.
;
; SO THE BODY'S PER-BIT `and` RAILS ARE STILL NOT DISCHARGED, and that is the
; PRIME-DIRECTIVE disposition, not an oversight: the leak is the safe direction
; (Rule 6 — a rail not provably |0> is left allocated, never freed dirty), and
; widening clause (ii) to admit a template rail is **owner question Q-R1-1**, not
; this fix's to decide. MEASURED, rolled/unrolled `and_i32_hl` vs `_unc`:
; **3/0 rolled and 3/3 unrolled on BOTH 542d588 (the pre-fix subject) and on the
; C-1 fix** — byte-identical rolled traces, `diff` empty. That equality IS the
; assertion: it says the widening did not reach here.
;
; Two sibling spellings measure the same wall and are recorded in
; `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3: a `sext` rail (`long long p = q;`) and a
; Q+Q rail (`p = q + r`). Q-R1-1's disclosure therefore covers ANY loop-invariant
; TEMPLATE rail — a cast, a Q+Q op, an onward `mul` — not only `q*3`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The hoisted template rail is minted ONCE, in the preheader.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK: %[[P:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)

; The rolled body: the bit rail is minted off `%[[P]]`, the flag is minted,
; bracketed, kicked, stripped and freed — and then NOTHING. No `and` discharge,
; no free of the bit rail.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[P]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %{{.*}}, double 1.000000e-01)

; ⭐ THE CONTROL'S OWN ASSERTION. **ZERO** `and` discharges — the leak, pinned.
; If a future widening of clause (ii) reaches the hoisted template rail this goes
; RED, which is the point: Q-R1-1 must be RULED, not drifted into.
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; ONE kickback gate, and it is the only Rz.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; EXACTLY ONE free in the whole module — the flag's. The bit rail and the `mul`
; rail are LEFT ALLOCATED, never freed dirty (Rule 6, the safe direction).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg
; NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #2
  %4 = mul nsw i32 %2, 3
  br label %10

5:                                                ; preds = %17
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %18) #2
  %9 = add nsw i32 %8, %7
  ret i32 %9

10:                                               ; preds = %1, %17
  %11 = phi i32 [ 0, %1 ], [ %19, %17 ]
  %12 = phi i32 [ %3, %1 ], [ %18, %17 ]
  %13 = shl nuw nsw i32 1, %11
  %14 = and i32 %13, %4
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %17, label %16

16:                                               ; preds = %10
  tail call void @cq_phi(double noundef 2.000000e-01) #2
  br label %17

17:                                               ; preds = %16, %10
  %18 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 1.000000e-01) #2
  %19 = add nuw nsw i32 %11, 1
  %20 = icmp eq i32 %19, 3
  br i1 %20, label %5, label %10, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
