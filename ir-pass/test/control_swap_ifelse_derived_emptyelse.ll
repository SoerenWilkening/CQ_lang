; control_swap_ifelse_derived_emptyelse.ll — ACCEPT: derived base, one GATE-FREE arm.
;
; An if/else whose then-arm rotates the pre-region-derived %qd and whose else-arm
; is EMPTY (contributes %qd to the merge unchanged through a real, instruction-
; free else block). The gate-free arm is a no-op route (cswap in + cswap out of
; an untouched |0> rail), so the emitter SKIPS it — no else rail, no ¬flag
; bracket — and the stream degenerates to the single-rail diamond stream over
; the derived base. (clang -O1 normally folds an empty else into the diamond
; form; this raw-IR shape pins the emitter's gate-free-arm skip against the
; derived base regardless of which frontend produced it.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
; Whole-input scan: the skipped gate-free arm leaves NO ¬flag bracket anywhere.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=NOX
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
else:
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qd, %else ]   ; gate-free arm: %qd unchanged
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; single-rail stream, NO cqrt_x bracket anywhere (the gate-free else is skipped)
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: call void @cqrt_x
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; NOT-only prefix — guards the ENTIRE lowered module, not just the CHECK tail.
; (Matches CALLS only: ControlledSymbols mints the `declare void @cqrt_x` up
; front whether or not any arm needs the bracket — the declaration is inert.)
; NOX-NOT: call void @cqrt_x
