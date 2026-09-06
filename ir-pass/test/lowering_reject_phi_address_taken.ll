; lowering_reject_phi_address_taken.ll — DECLINE. Rule-13 round-1 finding F-L3-4
; (bd test_C_libtooling-3qlq Inc 1 part A, lens L3): a NON-CALL user of the
; register-free `@cq_phi` — its address taken into a function pointer.
;
;     void (*volatile pf)(double) = cq_phi;
;     int slice(void){ int q = cq_theta_si32(0, 0.3); pf(0.5); return cq_measure_si32(q); }
;
; `clang -O1` emits `@pf = global ptr @cq_phi` and an indirect call.
;
; WHAT WENT WRONG. `deleteGlobalPhases` derived its survivor list with
; `for (User *U : PhaseFn->users()) if (auto *CI = dyn_cast<CallInst>(U))` — a
; FILTER, so a non-call user simply fell out of the walk. The pass lowered
; nothing for it, `@cq_phi` SURVIVED into the lowered module, and `opt` exited 0
; on a module it had not lowered. MEASURED: stage 2 exit 0, stage 2b exit 0,
; stage 3 fails with `Undefined symbols … "_cq_phi", referenced from: _pf`.
;
; Loud at the LINKER is not loud at the COMPILER. Rule 1 says there is no third
; path, and an `opt` that exits 0 on an unlowered quantum construct IS one — so
; any user of `@cq_phi` that is not a direct call to it now declines here.
;
; NOTE WHICH SPELLING TAKES WHICH MESSAGE, because three of them are distinct and
; all three are pinned somewhere: an `invoke` is caught at COLLECTION
; (`front-end intrinsic cq_phi reached via invoke; only a direct call is
; supported`, `lowering_reject_intrinsic_invoke_phi.ll`); an indirect call UNDER a
; tainted branch declines `control flow under quantum control` at
; `detectControlRegions`, before this stage; and the address-take itself lands
; here. The diagnostic is attributed to `@cq_phi` itself when the user is a global
; initializer rather than an instruction — there is no containing function to name.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq taint propagation: front-end intrinsic cq_phi has its address taken; only a direct call is supported

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@pf = global ptr @cq_phi, align 8

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #1
  %2 = load volatile ptr, ptr @pf, align 8
  tail call void %2(double noundef 5.000000e-01) #1
  %3 = tail call i32 @cq_measure_si32(i32 noundef %1) #1
  ret i32 %3
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
