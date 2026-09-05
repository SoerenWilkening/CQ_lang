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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Whole-input scan: the skipped gate-free arm leaves NO ¬flag bracket anywhere.
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; single controlled gate, NO cqrt_x bracket anywhere (the gate-free else is
; skipped — it contributed nothing under the route and contributes nothing now)
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: call void @cqrt_x
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag; no work rail since drbq Inc 2a), no second.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
; No swap route survives: no |0> work rail, no CSWAP — window is `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)

; NOT-only prefix — guards the ENTIRE lowered module, not just the CHECK tail.
; (Matches CALLS only: ControlledSymbols mints the `declare void @cqrt_x` up
; front whether or not any arm needs the bracket — the declaration is inert.)
; NOX-NOT: call void @cqrt_x
