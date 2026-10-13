; spec_accept_int_abi_i64_arg.ll — ACCEPT (bd p3kd.9, the scalbln CQ/QQ shape).
;
; A tainted `long` (i64) ARGUMENT crosses a lifted call as an i32 runtime handle,
; exactly as a tainted fp argument does (bd 3c6m.54): the clone's i64 parameter is
; retyped to the i32 handle AFTER main's stage list ran on the well-typed body
; (owner ruling owner-ruling-clone-pipeline-q1q2-2026-10-07, Q2), and its logical
; width "i64" is recorded in `HandleWidth`, so the `trunc` that reads it lowers to
; `cq_template_trunc_i64_to_i32` (not the laundered i32). Before p3kd.9 the per-site
; ABI admitted only i32 and the reversible fp widths, so this declined
; `floating-point quantum argument or return has no reversible copy` (openlibm
; scalbln/scalblnf/scalblnl, mixtures CQ and QQ, whose `long n` is quantum).
;
; C source (clang -O1, then the IR below trimmed of attributes and metadata):
;   __attribute__((noinline)) int narrow3(long n) { return (int)n * 3 + 1; }
;   int arg_example(long u0) {
;     long q = u0;
;     cq_theta(&q, 0.5);
;     return cq_measure(narrow3(q));
;   }
;
; Semantics: the clone computes |n>|0> -> |n>|3*(int)n+1> (Bennett: forward, copy
; out with `cqrt_copy_i32`, reverse); the borrowed i64 handle is only read.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i64 @cq_theta_sl(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @narrow3(i64 noundef %0) {
  %2 = trunc i64 %0 to i32
  %3 = mul nsw i32 %2, 3
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

define i32 @arg_example(i64 noundef %0) {
  %2 = tail call i64 @cq_theta_sl(i64 noundef %0, double noundef 5.000000e-01)
  %3 = tail call i32 @narrow3(i64 noundef %2)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 %4
}

; Caller: an i64 rail, passed as its i32 handle.
; CHECK-LABEL: define i32 @arg_example(
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %0)
; CHECK:     call void @cqrt_ry_i64(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = {{(tail )?}}call i32 @__cq_q_narrow3_1(i32 {{(noundef )?}}%[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; Clone: the i64 slot is an i32 handle; the trunc reads its LOGICAL width.
; CHECK-LABEL: define internal i32 @__cq_q_narrow3_1(i32
; CHECK-SAME:  %[[P:[a-zA-Z0-9_.]+]])
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[P]])
; CHECK:     call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(
; CHECK:     call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T]], i32 %[[P]])
; CHECK:     ret i32
