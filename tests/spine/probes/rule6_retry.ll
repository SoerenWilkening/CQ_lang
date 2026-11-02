; cq-2ql9: CR rule 6 Dead is asked at the clean-up point; an old y held back only because an earlier
; update of it (y + 1, still garbage then) is read later is retried once that update settles (measured,
; rotated, or every reader lowered), against the image of the update that waited (a * 5, the odd mul).
; @retry_mul (unc-h2 p32): y + 1 and y * 5 both measured: y cleaned from y * 5 (t = 5^-1 * a5).
; @retry_gate (p34): y + 1 rotated after the measurement of y * 5: y cleaned, before the gate.
; @retry_first (qram-h2 p12b): r = y * 7 first, then y + 3: y cleaned from y + 3.
; @retry_xor (p30): y ^ z.  @retry_garbage: the earlier update y * 5 stays garbage (read by a + 2, which
; is measured): y is cleaned after it; a is cleaned from a + 2.
; CHECK-COUNT retry_mul: call void @cqrt_copy_i32( 1
; CHECK retry_mul: call i32 @cq_template_mul_i32_hl(i32 %{{t}}, i32 -858993459)
; CHECK-COUNT retry_gate: call void @cqrt_copy_i32( 1
; CHECK-COUNT retry_first: call void @cqrt_copy_i32( 1
; CHECK retry_first: call i32 @cq_template_sub_i32_hl(i32 %{{t}}, i32 3)
; CHECK-COUNT retry_xor: call void @cqrt_copy_i32( 1
; CHECK-COUNT retry_garbage: call void @cqrt_copy_i32( 2
;
; C: int retry_mul(int y0, double th) {
; C:     int y = y0;
; C:     cq_theta(&y, th);
; C:     int a = y;
; C:     y = y + 1;
; C:     return cq_measure(a * 5) ^ cq_measure(y);
; C: }
; C: int retry_gate(int y0, double th) {
; C:     int y = y0;
; C:     cq_theta(&y, th);
; C:     int a = y;
; C:     y = y + 1;
; C:     int r = cq_measure(a * 5);
; C:     cq_theta(&y, th);
; C:     return r ^ cq_measure(y);
; C: }
; C: int retry_first(int a, double th) {
; C:     int y = a;
; C:     cq_theta(&y, th);
; C:     int r = y * 7;
; C:     y = y + 3;
; C:     return cq_measure(r) + cq_measure(y);
; C: }
; C: int retry_xor(int y0, int z0, double th) {
; C:     int y = y0, z = z0;
; C:     cq_theta(&y, th);
; C:     cq_theta(&z, th);
; C:     int a = y;
; C:     y = y ^ z;
; C:     return cq_measure(a * 5) ^ cq_measure(y) ^ cq_measure(z);
; C: }
; C: int retry_garbage(int y0, double th) {
; C:     int y = y0;
; C:     cq_theta(&y, th);
; C:     int a = y * 5;
; C:     y = y + 1;
; C:     int s = a + 2;
; C:     return cq_measure(s) ^ cq_measure(y);
; C: }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @retry_mul(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = add nsw i32 %3, 1
  %5 = mul nsw i32 %3, 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %8 = xor i32 %7, %6
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: nounwind ssp uwtable
define i32 @retry_gate(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = add nsw i32 %3, 1
  %5 = mul nsw i32 %3, 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = xor i32 %8, %6
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @retry_first(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = mul nsw i32 %3, 7
  %5 = add nsw i32 %3, 3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @retry_xor(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2)
  %6 = xor i32 %5, %4
  %7 = mul nsw i32 %4, 5
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %10 = xor i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %12 = xor i32 %10, %11
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @retry_garbage(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = mul nsw i32 %3, 5
  %5 = add nsw i32 %3, 1
  %6 = add nsw i32 %4, 2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %9 = xor i32 %8, %7
  ret i32 %9
}



