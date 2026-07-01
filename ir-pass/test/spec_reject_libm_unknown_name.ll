; spec_reject_libm_unknown_name.ll — bd 3c6m.3 DECLINE PROBE (Rule 12, mirrors
; the accept `spec_accept_libm_body.ll`). A declaration-only extern in a would-be
; clone that is NOT in the curated libm name-set (`@frobnicate`, arbitrary) must
; STILL loud-decline "(nested call)", NEVER over-accept. The `isLibmCall`
; whitelist added to `SpecializeReject::scanBody` is EXACT-NAME over a
; declaration-only libc extern (the curated `libm_table.yaml` set) — it is NOT a
; blanket accept of every declaration-only nested call, and NOT a
; `starts_with`/prefix match (the cq_theta_evil hazard, C7). `@frobnicate` fails
; the name lookup, so it falls through to the existing declaration-only "nested
; call" decline. The body is OTHERWISE perfectly liftable (i32 arg + i32 return,
; the in-clone `sitofp`/`fptosi` casts are in scope), so the ONLY reason for the
; decline is the unknown extern — pinning that the whitelist did not widen to an
; arbitrary declaration-only call.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @frobnicate(double)

define i32 @frob_helper(i32 %n) {
entry:
  %d = sitofp i32 %n to double
  %e = call double @frobnicate(double %d)
  %ri = fptosi double %e to i32
  ret i32 %ri
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @frob_helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (nested call)
; CHECK-NOT: @__cq_q_frob_helper
; CHECK-NOT: cq_template_frobnicate
