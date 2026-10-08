; lowering_runtime_narrow_abi_ext.ll — bd test_C_libtooling-r2j3.20 (etj3).
; The runtime's C ABI takes `bool`, `int8_t` and `int16_t` parameters (and returns them
; from `cqrt_measure_i1/i8/i16`). clang passes those `zeroext i1` / `signext i8` /
; `signext i16`, and clang-built callees rely on it. The pass declared them with bare
; `i1`/`i8`/`i16`, so a negative literal reached the C template unextended: etj3 measured
; `cq_template_sub_i16_lh(i16 -9, …)` printing 65527 and the i8 one 247. Every runtime
; declaration now carries the extension its C prototype implies (one sweep at the end
; of the pass, `annotateRuntimeNarrowABI`), so codegen extends at each call.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-DAG: declare i32 @cq_template_sub_i16_lh(i16 signext, i32)
; CHECK-DAG: declare i32 @cq_template_sub_i8_lh(i8 signext, i32)
; CHECK-DAG: declare i32 @cqrt_alloc_i16(i16 signext)
; CHECK-DAG: declare i32 @cqrt_alloc_i8(i8 signext)
; CHECK-DAG: declare i32 @cqrt_alloc_i1(i1 zeroext)
; CHECK-DAG: declare signext i16 @cqrt_measure_i16(i32)
; CHECK-DAG: declare signext i8 @cqrt_measure_i8(i32)
; CHECK-DAG: declare zeroext i1 @cqrt_measure_i1(i32)
declare i16 @cq_theta_si16(i16, double)
declare i8 @cq_theta_si8(i8, double)
declare i1 @cq_theta_i1(i1, double)
declare i16 @cq_measure_si16(i16)
declare i8 @cq_measure_si8(i8)
declare i1 @cq_measure_i1(i1)

define i16 @example(i16 %a, i8 %b, i1 %c) {
  %q = call i16 @cq_theta_si16(i16 %a, double 5.000000e-01)
  %d = sub i16 -9, %q
  %m = call i16 @cq_measure_si16(i16 %d)
  %p = call i8 @cq_theta_si8(i8 %b, double 5.000000e-01)
  %e = sub i8 -9, %p
  %n = call i8 @cq_measure_si8(i8 %e)
  %r = call i1 @cq_theta_i1(i1 %c, double 5.000000e-01)
  %o = call i1 @cq_measure_i1(i1 %r)
  %ne = sext i8 %n to i16
  %oe = zext i1 %o to i16
  %s1 = add i16 %m, %ne
  %s2 = add i16 %s1, %oe
  ret i16 %s2
}
