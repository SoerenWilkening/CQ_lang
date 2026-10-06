; spec_reject_clone_switch_classical_scrutinee.ll — DECLINE, a goal-1 GAP (bd
; p3kd.7.1 decline fixture for the widened terminator gate): a switch on a
; CLASSICAL parameter (`%c`, untainted at this call site) whose arms compute from
; the tainted `%b`. Since bd p3kd.7.1 `scanBody` admits `switch`, so the candidate
; is cloned; inside the clone the switch is classical control over quantum data,
; which no clone emitter lowers yet (PredMux claims tainted terminators only), so
; the clone keeps more than one block and the `lowerCloneControl` backstop declines
; it loudly, naming the CLONE. Classical control inside a lifted body is bd
; p3kd.7.2 (the CQ/QC math.h mixtures); this fixture flips when it lands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function __cq_q_helper_01 i32 (i32, i32): cq specialization: callee contains tainted control flow under quantum lift
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  switch i32 %c, label %def [ i32 0, label %z
                              i32 1, label %o ]
z:
  %zb = add i32 %b, 1
  br label %m
o:
  %ob = mul i32 %b, 2
  br label %m
def:
  %db = sub i32 %b, 3
  br label %m
m:
  %r = phi i32 [ %zb, %z ], [ %ob, %o ], [ %db, %def ]
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q, i32 %u1)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
