; spec_accept_gate_sub_branch_phase.ll (formerly lowering_reject_spec_branch_phase.ll)
; — ACCEPT since bd test_C_libtooling-p3kd.21; was a DECLINE. Rule-13 round-1 finding F-L3-3
; (bd test_C_libtooling-3qlq Inc 1 part A, lens L3): a register-free branch phase
; inside a Phase-6 SPECIALIZATION CANDIDATE must decline as a QUANTUM PRIMITIVE.
;
;     __attribute__((noinline)) static int h(int x){ if (x == 5) cq_phi(PI); return x + 1; }
;     int slice(void){ int q = cq_theta_si32(0,0.3); return cq_measure_si32(h(q)); }
;
; `clang -O1` output verbatim.
;
; WHAT WENT WRONG. `SpecializeReject::buildIntrinsicSets` and
; `SpecializeDetect::intrinsicSites` both unioned `taint.ThetaCalls`,
; `taint.PhiCalls` and `taint.MeasureCalls`. After D1/D2 `PhiCalls` is the RETIRED
; register-form `@cq_phi_<sfx>` family and is PERMANENTLY EMPTY, so neither
; recognizer could see a branch phase at all.
;
; The reject stayed LOUD — which is why this is a truth finding and not a
; miscompile — but on the WRONG GROUND: this program declined
; `callee contains a non-reversibilizable construct under quantum lift (nested
; call)`, the unrelated DECLARATION-ONLY-CALLEE fallback, where the pre-3qlq
; oracle said `callee contains a quantum primitive (cq_*)`. MEASURED on both
; binaries. Safety had silently moved off the recognizer that was written for it
; and onto an accident: if `@cq_phi` ever acquires a body in the module the scan
; would recurse into it, find nothing, and clone a Bennett-wrapped body containing
; an unlowered branch phase.
;
; It matters more since the P7 re-ordering of F-L3-1: `deleteGlobalPhases` now
; runs AFTER `repropagateControlMerges`, so the ROUND-2 `detectSpecializations`
; sees surviving `cq_phi` calls too, and one with a tainted angle satisfies
; `readsTainted` — it would be a tainted-arg CANDIDATE rather than a skipped
; intrinsic site.
;
; bd p3kd.21 (2026-10-14): THE DECLINE IS RETIRED, the reason above is not. `h`
; is a GATE SUBROUTINE, compiled at its call site (SpecializeGateInline.h), never
; cloned: a Bennett-wrapped clone holding the phase would still be the hazard
; this fixture recorded, and `scanBody` still refuses it (pinned by
; spec_reject_gate_sub_devirt_primitive.ll, the one reachable lift of a gate
; callee, and backstopping every other non-inlinable
; site). Inlined, `slice` is `if (q == 5) cq_phi(PI); return measure(q + 1)`:
; the phase kicks back onto the compare flag, which is uncomputed and freed, and
; `q + 1` is the in-place `cqrt_addc_i32` on the measured register. The
; 2026-09-30 decline audit (docs/audits-2026-09-30, row SP-qprim) named exactly
; this remedy: inline callees containing cq_* primitives instead of Bennett-lifting
; them.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @slice(
; CHECK-NEXT: [[Q:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 3.000000e-01)
; CHECK-NEXT: [[F:%[0-9a-z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 [[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 [[F]], double 0x400921FB54442D18), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 [[F]], i32 [[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 [[F]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[Q]], i32 1)
; CHECK-NEXT: [[M:%[0-9a-z.]+]] = call i32 @cqrt_measure_i32(i32 [[Q]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NOT: @h(

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #1
  %2 = tail call fastcc i32 @h(i32 noundef %1)
  %3 = tail call i32 @cq_measure_si32(i32 noundef %2) #1
  ret i32 %3
}

define internal fastcc i32 @h(i32 noundef %0) unnamed_addr #0 {
  %2 = icmp eq i32 %0, 5
  br i1 %2, label %3, label %4

3:                                                ; preds = %1
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #1
  br label %4

4:                                                ; preds = %3, %1
  %5 = add nsw i32 %0, 1
  ret i32 %5
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
