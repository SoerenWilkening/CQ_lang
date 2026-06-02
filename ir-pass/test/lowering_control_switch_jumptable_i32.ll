; lowering_control_switch_jumptable_i32.ll — Phase 4.x (test_C_libtooling-5zu),
; NEGATIVE safety lock (adversarial review 2026-06-03). A constant jump table of
; NON-angle `i32` DATA (clang's lowering of `int a = (idx<N)?t[idx]:base;`). This
; is NOT a rotation-angle dispatch — normalizeJumpTableAngle only handles `double`
; angle tables (the CQ rotation surface is double-only). Rewriting an i32 table
; would turn the safe memory-escape diagnostic into an out-of-scope value-mux (a
; silent semantic change). The recognizer DECLINES (element type not double), so
; the tainted-memory-escape guard diagnoses the handle-indexed load.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}memory addressing under quantum control
; CHECK-NOT: cq_template_add_i32
@itbl = private unnamed_addr constant [3 x i32] [i32 10, i32 20, i32 30], align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %idx = add i32 %q, -1
  %bound = icmp ult i32 %idx, 3
  br i1 %bound, label %lookup, label %merge
lookup:
  %zext = zext i32 %idx to i64
  %gep = getelementptr inbounds [3 x i32], ptr @itbl, i64 0, i64 %zext
  %val = load i32, ptr %gep, align 4
  br label %merge
merge:
  %a = phi i32 [ %val, %lookup ], [ 99, %entry ]
  %r = call i32 @cq_phi_si32(i32 %a, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
