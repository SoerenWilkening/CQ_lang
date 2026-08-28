; lowering_live_record_sibling_read_taped_accept.ll — ACCEPT: the OBSERVING SINK
; is a 7.6 OUTPUT TAPE write, not a measurement (M-A, bd test_C_libtooling-6uqc;
; the F1 ruling, 2026-08-28).
;
; SOURCE:
;     a = cq_theta(a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * 3;                     // a SIBLING of the wire
;     w = cq_theta(w, 0.5);              // T — chained, in-place Ry on the wire
;     int z = c * 7;                     // a post-gate READ of the sibling
;     int y = a * 5;                     // a post-gate READ of the ancestor
;     printf("%d %d %d", w, z, y);       // all three land on the output tape
;
; WHY IT LOWERS — and note the sink family is the point. The ruling enumerates
; "measure / ret / tape / a template read that itself flows to one", and this
; module has NO measurement at all (Rule 5: the compiler never inserts one).
; Every exemption here is carried by `cqrt_tape_write_i32`, whose `out_handle` is
; a KEPT output rail (`taint.OutputRails`) — never uncomputed, never freed:
;   * `%h_op1` (`c`) — post-gate template read `z = c * 7`, whose result is taped.
;     A template read is a HOP; the tape write on its result is the SINK.
;   * `%h` (the alloc parent) — the same shape one level up, via `y = a * 5`.
;     This is the ROOT-READ trick lowering_io_tape_chained_theta.ll depends on,
;     reused here so the sibling really is what this fixture discriminates.
;   * `%h_op2` (`z`) and `%h_op3` (`y`) are minted AFTER the gate, so the F2
;     existence test skips them: a rail that is not allocated when the `Ry` fires
;     cannot dephase it.
;
; Only the WRITTEN slot of a tape write is treated as a sink (`…(tape, src)` /
; `…(ctrl, tape, src)`), never the tape token, which is a classical resource
; handle and not a rail at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [9 x i8] c"%d %d %d\00"

define void @slice(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w   = mul i32 %q, 2                                          ; THE WIRE
  %c   = mul i32 %q, 3                                          ; the SIBLING
  %q2  = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %z   = mul i32 %c, 7                                          ; post-gate read of `c`
  %y   = mul i32 %q, 5                                          ; post-gate read of `a`
  %r   = call i32 (ptr, ...) @printf(ptr @.str, i32 %q2, i32 %z, i32 %y)
  ret void
}

; The gate fires, then both post-gate reads are TAPED — the observations that
; exempt the sibling and the ancestor:
; CHECK:      %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 2)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:      call void @cqrt_ry_i32(i32 %[[W]], double 5.000000e-01)
; CHECK:      %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[C]], i32 7)
; CHECK:      %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK:      call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[Z]])
; CHECK:      call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[Y]])
; CHECK-NOT:  cq rotation lowering
; CHECK-NOT:  cqrt_measure
