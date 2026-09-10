; x03 — the i32 sanity control: does the const-global QROM read path accept an
; `i1` CELL at all? Same table as x01, a single measure, no rail.
@tbl = internal unnamed_addr constant [8 x i1] [i1 true, i1 false, i1 true, i1 true, i1 false, i1 true, i1 false, i1 true]
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
define i32 @qrom_i1(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i1], ptr @tbl, i64 0, i64 %i
  %x = load i1, ptr %g
  %m = call i1 @cq_measure_i1(i1 %x)
  %z = zext i1 %m to i32
  ret i32 %z
}
