; The general window (two quantum terms, a byte stride) into memory of unknown extent at 64-bit indices:
; 2^64 cells, n = 0 (CR 1.3, rule 20, cq-k65d 2026-11-02), the flattened index at i64 (wraps as the address).
declare i64 @cq_theta_ull(i64, double)
declare i16 @cq_measure_ui16(i16)

define i16 @wide_general(i64 %x0, i64 %y0, double %t, ptr %p) {
  %x = call i64 @cq_theta_ull(i64 %x0, double %t)
  %y = call i64 @cq_theta_ull(i64 %y0, double %t)
  %e = getelementptr inbounds i8, ptr %p, i64 %x
  %f = getelementptr inbounds [3 x i8], ptr %e, i64 %y
  %v = load i16, ptr %f, align 1
  %m = call i16 @cq_measure_ui16(i16 %v)
  ret i16 %m
}
; CHECK wide_general: @cq_template_qrom_load_i16_s(ptr %p, i64 0, i64 1, i32 %{{l}})
