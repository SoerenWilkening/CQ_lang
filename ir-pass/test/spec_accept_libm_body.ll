; spec_accept_libm_body.ll — bd 3c6m.3 (Rule-13 finding on bd 3c6m.2) × Phase 6:
; a classical helper whose body contains a curated DIRECT-libm math.h call now
; SPECIALIZES instead of loud-declining. Pre-fix, `SpecializeReject::scanBody`
; saw `@ilogb` (a declaration-only libc extern, NOT an `@llvm.*` intrinsic) as a
; nested declaration-only call and rejected the whole candidate
; ("non-reversibilizable … (nested call)") — a SAFE over-decline, not a
; miscompile; the EXACT same class as the Phase-7.1-E intrinsic-in-clone
; over-decline. Accepting it (`isLibmCall` whitelist in scanBody, symmetric with
; the `isCuratedReversibleIntrinsic` whitelist, the top-level `declineTaintEscapes`
; carve, and OpcodeLowering's enqueue) — PLUS the mirrored skip in the transitive
; worklist (`Specialization.cpp`, else the fp libm operand mis-declines FpAbi
; naming the clone) — lets the SAME machinery the intrinsic case rides take over.
;
; A libm call needs an fp operand, but a tainted clone arg is an i32 HANDLE, so
; the fp domain is reached by an in-clone `sitofp` (i32→f64). `ilogb` (f64→i32,
; the CrossUnary shape) then returns an i32 directly, satisfying the i32-return
; ABI gate with no output cast. `seedClone` taints `sitofp`→`ilogb`, `lowerOps`
; lowers them to the FROZEN `cq_template_sitofp_i32_to_f64` / `cq_template_ilogb_
; f64_to_i32` additive producers (3c6m.2 ABI, NO new symbol), the Bennett wrap
; captures both in the forward stream, copies out ONLY the i32 result, and
; `emitInverseChain` reverses each via its `_unc` twin. ilogb is Class-2 (no
; `_inv`): its `_unc` recomputes from the LIVE fp source `%h_cast`, whose own
; `_unc` recomputes from the LIVE borrowed input `%n` — held because every scratch
; rail is freed only AFTER the complete reverse (BennettWrap step e). The libm
; producer is computed-then-uncomputed, never measured, never escaped.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ilogb(double)

define i32 @ilogb_helper(i32 %n) {
entry:
  %d = sitofp i32 %n to double
  %e = call i32 @ilogb(double %d)
  ret i32 %e
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @ilogb_helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; Caller retargets to the mangled clone.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_ilogb_helper_1(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; Clone: internal linkage; the in-clone `sitofp` feeds the libm producer; out copy
; is the i32 RESULT.
; CHECK:     define internal i32 @__cq_q_ilogb_helper_1(i32 %n)
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK:     %[[LIBM:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ilogb_f64_to_i32(i32 %[[CAST]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[LIBM]], i32 %[[OUT]])
; LIFO uncompute of the whole clone via the `_unc` twins; the ilogb `_unc` reads
; the still-live fp source `%[[CAST]]`, whose `_unc` reads the still-live `%n`;
; every rail freed once, AFTER the complete reverse.
; CHECK:     call void @cq_template_ilogb_f64_to_i32_unc(i32 %[[LIBM]], i32 %[[CAST]])
; CHECK:     call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[CAST]], i32 %n)
; CHECK:     call void @cqrt_free(i32 %[[CAST]])
; CHECK:     call void @cqrt_free(i32 %[[LIBM]])
; CHECK:     ret i32 %[[OUT]]
;
; The raw libm call is gone from the clone; the keep-live `_unc` is used, never a
; dirty-freeing `_inv`; the borrowed input was never copied out.
; CHECK-NOT: call {{.*}}@ilogb(
; CHECK-NOT: cq_template_ilogb_f64_to_i32_inv
; CHECK-NOT: cq taint escape
