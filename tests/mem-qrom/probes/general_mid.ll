; cq-k65d: a signed index into the middle of a static object (p = &T[1][4], p[x % 8]): the window is the
; object's cells, from 12 cells before p. (cqcheck user cannot run it yet: its probe builder rejects the
; constant GEP operand of the C program, bead filed.)
; | #include <stdlib.h>
; | static const int T[4][8] = {{1,2,3,4,5,6,7,8},{11,12,13,14,15,16,17,18},{21,22,23,24,25,26,27,28},{31,32,33,34,35,36,37,38}};
; | static const unsigned char B[16] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
; | 
; | /* a signed index into the middle of a known object: the cells before the base are in reach */
; | int qrom_mid(int x, double th) {
; |     cq_theta(&x, th);
; |     const int *p = &T[1][4];
; |     return cq_measure(p[x % 8]);
; | }

@T = internal unnamed_addr constant [4 x [8 x i32]] [[8 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8], [8 x i32] [i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17, i32 18], [8 x i32] [i32 21, i32 22, i32 23, i32 24, i32 25, i32 26, i32 27, i32 28], [8 x i32] [i32 31, i32 32, i32 33, i32 34, i32 35, i32 36, i32 37, i32 38]], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @qrom_mid(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = srem i32 %3, 8
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds i32, ptr getelementptr inbounds (i8, ptr @T, i64 48), i64 %5
  %7 = load i32, ptr %6, align 4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr



; CHECK qrom_mid: %{{i}} = call i32 @cq_template_add_i32_hl(i32 %{{r}}, i32 12)
; CHECK qrom_mid: call i32 @cq_template_qrom_load_i32(ptr @T, i64 32, i32 %{{i}})
