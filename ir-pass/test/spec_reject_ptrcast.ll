; spec_reject_ptrcast.ll — Phase 6.4 (WI-1.13 over-accept hardening): a tainted
; body containing a pointer / bit-reinterpret cast (`inttoptr`/`ptrtoint`/
; `bitcast`/`addrspacecast`) crosses the pointer domain or reinterprets bits and
; has no reversible template. Before 6.4 the body whitelist accepted any
; `CastInst`, so the clone `__cq_q_helper_1` was created and the cast only
; backstopped LATE at lowerOps (naming the CLONE). 6.4 rejects it at DETECTION,
; at the offending cast's `!dbg`, with the precise "pointer cast" kind. Recorded
; in `plan6.Diagnosed`, so the carve-out does NOT also emit `kMsgUnknownCallee`;
; CHECK-NOT confirms no clone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %p = inttoptr i32 %x to ptr
  %i = ptrtoint ptr %p to i32
  ret i32 %i
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (pointer cast)
; CHECK-NOT: cq taint escape
; CHECK-NOT: @__cq_q_helper
