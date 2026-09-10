; f04 — the rail's parent is a LOOP-CARRIED PHI (the walk collects it and stops);
; the phi name is measured in the body before the select.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_theta_si64(i64, double)
declare i64 @cq_measure_si64(i64)
define i32 @main() {
entry:
  br label %hdr
hdr:
  %i = phi i32 [ 0, %entry ], [ %in, %hdr ]
  %ph = phi i1 [ false, %entry ], [ %b, %hdr ]
  %mm = call i1 @cq_measure_i1(i1 %ph)
  %b = call i1 @cq_theta_i1(i1 %ph, double 5.000000e-01)
  %a = select i1 %b, i32 7, i32 9
  %m = call i32 @cq_measure_si32(i32 %a)
  %in = add i32 %i, 1
  %c = icmp eq i32 %in, 3
  br i1 %c, label %out, label %hdr
out:
  ret i32 %m
}
