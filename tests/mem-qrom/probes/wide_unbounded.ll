; A 64-bit quantum index into memory of unknown extent with no range fact: 2^64 entries do not fit the
; i64 length, but the address p + 4 * x depends only on x modulo 2^62: n = 2^62 at x truncated to 62 bits
; (cq-k65d).
declare i64 @cq_theta_ull(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @wide_unbounded(i64 %x0, double %t, ptr %p) {
  %x = call i64 @cq_theta_ull(i64 %x0, double %t)
  %e = getelementptr inbounds i32, ptr %p, i64 %x
  %v = load i32, ptr %e, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK wide_unbounded: %{{i}} = call i32 @cq_template_trunc_i64_to_i62(i32 %{{x}})
; CHECK wide_unbounded: call i32 @cq_template_qrom_load_i32(ptr %p, i64 4611686018427387904, i32 %{{i}})
