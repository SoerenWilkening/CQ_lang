; spec_reject_clone_switch.ll — Phase 6 / issue 5po2 I2 (over-accept probe): a
; tainted-scrutinee SWITCH in a lifted callee stays DECLINED at detection. I2 lifts
; tainted `br` diamonds / controlled-returns; an in-clone `switch` is a distinct
; N-way routing shape (a later increment), and `scanBody`'s terminator whitelist
; admits only `ret`/`br` — a `switch` terminator is `InBodyControl`, declined
; source-located at the ORIGINAL callee during detection (before any clone is
; wrapped). Over-declining is safe (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  switch i32 %b, label %def [ i32 0, label %z
                              i32 1, label %o ]
z:
  ret i32 10
o:
  ret i32 20
def:
  %d = add i32 %b, 3
  ret i32 %d
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains tainted control flow under quantum lift
