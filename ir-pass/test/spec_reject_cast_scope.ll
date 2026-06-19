; spec_reject_cast_scope.ll — Phase 6.4 (WI-1.13 over-accept hardening, completed):
; a tainted body containing an in-WIDTH but out-of-SCOPE arithmetic cast (a signed
; `sitofp` FROM `i1` — excluded because Clang uses `uitofp` for `_Bool`, so there
; is no `cq_template_sitofp_i1_to_f32`) has no reversible template. Before this the
; body whitelist accepted any non-pointer `CastInst` of valid width, so the clone
; was created and the cast only backstopped LATE at lowerOps. The classifier now
; mirrors `castInScope` at DETECTION, declining at the offending cast's `!dbg` with
; the precise "unsupported cast" kind. Recorded in `plan6.Diagnosed`, so the
; carve-out does NOT also emit `kMsgUnknownCallee`; CHECK-NOT confirms no clone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %b = trunc i32 %x to i1
  %f = sitofp i1 %b to float
  %r = fptosi float %f to i32
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported cast)
; CHECK-NOT: cq taint escape
; CHECK-NOT: @__cq_q_helper
