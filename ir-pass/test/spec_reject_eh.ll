; spec_reject_eh.ll — Phase 6.4 WI-4.1: a callee body that uses EXCEPTION
; HANDLING (an `invoke` + landing pad / `resume`) unwinds via a non-value control
; edge spanning multiple blocks — a construct the straight-line Bennett reverse
; has no story for. It is detected BEFORE the single-block `size() != 1` gate so
; the diagnostic names the actual hazard ("exception handling") rather than the
; generic in-body-control message (PRD §2.11). Recorded in `plan6.Diagnosed`, so
; the carve-out does NOT also emit the generic `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @may_throw()
declare i32 @__gxx_personality_v0(...)

define i32 @helper(i32 %x) personality ptr @__gxx_personality_v0 {
entry:
  invoke void @may_throw() to label %ok unwind label %lpad
ok:
  %y = add i32 %x, 1
  ret i32 %y
lpad:
  %lp = landingpad { ptr, i32 } cleanup
  resume { ptr, i32 } %lp
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (exception handling)
; CHECK-NOT: cq taint escape
