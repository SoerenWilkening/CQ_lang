; spec_accept_int_abi_i64_return.ll — ACCEPT (bd p3kd.9, the lround/llround shape).
;
; A tainted `long` (i64) RETURN copies out of the lifted clone to an i32 handle
; through `cqrt_copy_i64`, exactly as a tainted fp return copies out through
; `cqrt_copy_f<W>` (bd 3c6m.54). The clone's i64 return is retyped to the i32
; handle when `predictReturnTainted`, the call is rebuilt to the i32 type
; (`retargetSite`), and the caller records the result's logical width "i64" in
; `HandleWidth`, so a caller cast off the result (`(int)widen3(q)`) lowers to
; `cq_template_trunc_i64_to_i32` rather than reading the laundered i32. Before
; p3kd.9 `scanBody` admitted only an i32 or reversible-fp return, so this
; declined `floating-point quantum argument or return has no reversible copy`
; (openlibm lround/lroundf/lroundl/llround/llroundf/llroundl, mixture Q).
;
; C source (clang -O1, then the IR below trimmed of attributes and metadata):
;   __attribute__((noinline)) long widen3(int a) { return (long)a * 3 + 1; }
;   long ret_example(int u0) {
;     int q = u0;
;     cq_theta(&q, 0.5);
;     return cq_measure(widen3(q));
;   }
;   int ret_cast_example(int u0) {
;     int q = u0;
;     cq_theta(&q, 0.5);
;     return cq_measure((int)widen3(q));
;   }
;
; Semantics: the clone computes |a>|0> -> |a>|3*(long)a+1> on an i64 out rail
; (forward, `cqrt_copy_i64` into a fresh |0> i64 rail, reverse, free the scratch);
; both call sites share the one `(widen3, 1)` clone.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_measure_sl(i64)
declare i32 @cq_measure_si32(i32)

define range(i64 -6442450943, 6442450943) i64 @widen3(i32 noundef %0) {
  %2 = sext i32 %0 to i64
  %3 = mul nsw i64 %2, 3
  %4 = add nsw i64 %3, 1
  ret i64 %4
}

define i64 @ret_example(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = tail call i64 @widen3(i32 noundef %2)
  %4 = tail call i64 @cq_measure_sl(i64 noundef %3)
  ret i64 %4
}

define i32 @ret_cast_example(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = tail call i64 @widen3(i32 noundef %2)
  %4 = trunc i64 %3 to i32
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %5
}

; The i64 measure reads the clone's i32 handle directly.
; CHECK-LABEL: define i64 @ret_example(
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_widen3_1(i32 %[[H]])
; CHECK:     call i64 @cqrt_measure_i64(i32 %[[R]])
;
; The caller cast off the result reads the recorded logical width i64.
; CHECK-LABEL: define i32 @ret_cast_example(
; CHECK:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_widen3_1(i32 %[[H2]])
; CHECK:     %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[R2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[T2]])
;
; Clone: i64 arithmetic, an i64 out rail, the i64 copy-out, then the reverse.
; CHECK-LABEL: define internal i32 @__cq_q_widen3_1(i32
; CHECK-SAME:  %[[P:[a-zA-Z0-9_.]+]])
; CHECK:     %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i32_to_i64(i32 %[[P]])
; CHECK:     %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i64_hl(i32 %[[S]], i64 3)
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i64_hl(i32 %[[M]], i64 1)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:     call void @cqrt_copy_i64(i32 %[[A]], i32 %[[OUT]])
; CHECK:     call void @cq_template_add_i64_hl_unc(i32 %[[A]], i32 %[[M]], i64 1)
; CHECK:     call void @cq_template_mul_i64_hl_unc(i32 %[[M]], i32 %[[S]], i64 3)
; CHECK:     call void @cq_template_sext_i32_to_i64_unc(i32 %[[S]], i32 %[[P]])
; CHECK:     ret i32 %[[OUT]]
