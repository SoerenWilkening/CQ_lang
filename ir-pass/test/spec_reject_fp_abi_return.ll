; spec_reject_fp_abi_return.ll — bd 3c6m.54: after the fp-ABI lift, a REVERSIBLE-fp
; return {f16,f32,f64,f80} is ADMITTED (copied out to an i32 handle via
; `cqrt_copy_f<W>`); the residual FpAbi return decline is an fp width with NO
; reversible copy. Here fp128 — `abiWidthFromType(fp128)` is empty and it is not in
; `abiWidthHasReversibleFpCopy`, so the return-ABI gate (scanBody §2) declines it.
; Reached BEFORE the body whitelist. Recorded in `plan6.Diagnosed`, so the carve-out
; does NOT also emit `kMsgUnknownCallee`.
;
; ⚠ bd vsfp round 2: `%r` is now USED. The helper's body is side-effect-free and
; terminating, so an UNUSED call to it is dead under the pass's liveness predicate and
; the dead-argument drop deletes it (the hand-inlined twin's `-O1` would too) — which
; removed this file's subject (no spec site, no decline). Using the result keeps the
; call a Phase-6 site; the fence below fires before the use is ever lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define fp128 @helper(i32 %x) {
entry:
  %f = sitofp i32 %x to fp128
  ret fp128 %f
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call fp128 @helper(i32 %q)
  %z = call i32 @cq_measure_si32(i32 %q)
  %ri = fptosi fp128 %r to i32
  %s = add i32 %z, %ri
  ret i32 %s
}

; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: cq taint escape
