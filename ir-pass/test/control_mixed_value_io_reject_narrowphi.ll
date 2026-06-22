; control_mixed_value_io_reject_narrowphi.ll — DECLINE (Phase 7.2 Increment 2,
; Rule-13 must-fix): a mixed value+I/O diamond whose value merge φ is a CONSTANT
; data-mux but of a NON-i32 width (here i8, feeding a `zext i8 → i32`). Every cq
; rail handle is i32 (Rule 15), so the data-mux out-rail is an i32 handle and the
; `RAUW φ→out` would relaunder this narrow φ to i32 — turning `zext i8 %φ to i32`
; into the ill-typed `zext i32 %out to i32` → a BROKEN MODULE (a verifier abort on
; valid -O1 input). The mixed accept is therefore gated to an i32 φ ONLY; a
; narrower/wider constant data-mux beside I/O DECLINES LOUDLY (over-decline is
; always safe). A realistic -O1 source: `char r = (q>5)?3:4;` kept narrow by an
; opaque `char` consumer, with an unrelated i32 `printf("%d", q)` as the sink.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %p = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %sel = phi i8 [ 3, %arm ], [ 4, %entry ]      ; NON-i32 constant data-mux
  %z = zext i8 %sel to i32
  %s = add nsw i32 %q, %z
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}

; CHECK: error{{.*}}cq I/O output sink: conditional output is not a lowerable single-sink if(q) diamond
; CHECK-NOT: cqrt_copy_i8_controlled
; CHECK-NOT: cqrt_tape_write_i32_controlled
