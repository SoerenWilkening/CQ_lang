; spec_twin_parity_ordering.ll — Phase 6.1 WI-1.12: the decline-by-default
; ordering boundary. One module, two tainted-arg sites at the same taint-escape
; seam: `@good` (a 1-arg pure-classical visible body — a PROVEN-Accept candidate
; the pre-pass enters into `plan6.Pending`) and `@ext` (a declaration-only opaque
; callee — never a candidate). The carve-out SUPPRESSES `kMsgUnknownCallee` for
; the proven `@good` site yet STILL fires it for the unproven `@ext` site:
; EXACTLY ONE escape error, proving detection runs as a pre-pass BEFORE the
; carve-out and that suppression is the proven exception, not the default.
;
; (Part (b) of WI-1.12 — run() vs runOnFunction parity — is a structural
; invariant: both entry points wire the SAME two slots, the pre-pass before the
; carve-out and the driver before lowerRotations. Only `cq-lowering` (the module
; pass = run()) is registered, so the twin shim is not opt-invokable; the mirror
; is asserted by code and the Rule-13 review.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ext(i32)

define i32 @good(i32 %x) {
entry:
  %y = add i32 %x, 1
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r1 = call i32 @good(i32 %q)              ; proven candidate → suppressed
  %r2 = call i32 @ext(i32 %q)               ; opaque extern → still declines
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  ret void
}

; EXACTLY ONE escape error — for `@ext`; `@good` is suppressed (had detection
; failed to prove `@good`, a SECOND identical error would fire here).
; CHECK-COUNT-1: cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT:     cq taint escape
