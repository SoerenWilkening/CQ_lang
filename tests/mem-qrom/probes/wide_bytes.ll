; A byte table at an unbounded 64-bit quantum index into memory of unknown extent: 2^64 cells, spelled
; n = 0 (CR 1.3, rule 20, cq-k65d 2026-11-02); the index is the logical rail itself.
declare i64 @cq_theta_ull(i64, double)
declare i8 @cq_measure_ui8(i8)

define i8 @wide_bytes(i64 %x0, double %t, ptr %p) {
  %x = call i64 @cq_theta_ull(i64 %x0, double %t)
  %e = getelementptr inbounds i8, ptr %p, i64 %x
  %v = load i8, ptr %e, align 1
  %m = call i8 @cq_measure_ui8(i8 %v)
  ret i8 %m
}
; CHECK wide_bytes: call i32 @cq_template_qrom_load_i8(ptr %p, i64 0, i32 %{{x}})
