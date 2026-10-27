; HAND-WRITTEN. Rules: 16, 20, 8, 4, 5, 2.
; Checked: x (measured).
; Clean: the zext of x, the rail x + 1 (cell 1), and the predicate flag x > k.
; Kept: the user register x (cell 0); the tape rails (never freed: they are the observation the user wrote).
; Rotations: Ry(th) on x.
; Expected tape: the three bytes x, x + 1, 'z', then "hi\n" iff x > k.
; BYTE OUTPUT of quantum data (rule 16): buf is a slot array of handles (31, rule 20: cell 0 holds the register x,
; cell 1 the rail x + 1, cell 2 the classical 'z'), and fwrite of n bytes from it is ONE tape entry (47) whose format
; is n raw %c conversions, each byte a field: a quantum cell becomes a fresh write-only tape rail (cqrt_tape_write_i8,
; the i8 width of 47's writes), a classical cell a literal. The stream argument (stdout, loaded from @__stdoutp)
; selects the tape; stdout is the function's tape. fputs of a classical string under a quantum condition is an entry
; opened under the predicate with no fields (printed iff the predicate measures 1); fwrite's and fputs's return values
; are unused and dropped. The predicate and the x + 1 rail are uncomputed after the tape copies; the tape rails stay.
source_filename = "byte_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdoutp = external local_unnamed_addr global ptr, align 8    ; IR: @__stdoutp
@.str = private unnamed_addr constant [4 x i8] c"hi\0A\00", align 1    ; IR: @.str
@.cqfmt.fwrite3 = private unnamed_addr constant [7 x i8] c"%c%c%c\00", align 1    ; IR: fwrite(buf, 1, 3, ...): three raw bytes

define i32 @byte_tape(i8 noundef zeroext %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's output tape (stdout)
  %5 = alloca [3 x i8], align 1    ; IR: %4 = alloca [3 x i8]  (buf: a slot array of handles)
  %6 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %5 = cq_theta_ui8(%0, %1)  [register x; store i8 %5, ptr %4: cell 0 holds this handle]
  call void @cqrt_ry_i8(i32 %6, double %1)    ; IR: %5 = cq_theta_ui8(%0, %1)  [Ry]
  %7 = call i32 @cq_template_zext_i8_to_i32(i32 %6)    ; IR: %7 = zext i8 %5 to i32
  %8 = call i32 @cq_template_add_i8_hl(i32 %6, i8 1)    ; IR: %8 = add i8 %5, 1  [store i8 %8, ptr %6: cell 1 holds this handle]
  %9 = getelementptr inbounds i8, ptr %5, i64 2    ; IR: %9 = getelementptr i8, ptr %4, i64 2
  store i8 122, ptr %9, align 1    ; IR: store i8 122, ptr %9  (classical: cell 2 = 'z')
  %10 = load ptr, ptr @__stdoutp, align 8    ; IR: %10 = load ptr, ptr @__stdoutp  (the stream: stdout, this tape)
  call void @cqrt_tape_fmt(i32 %4, ptr @.cqfmt.fwrite3)    ; IR: %11 = fwrite(%4, 1, 3, %10): one entry, three raw bytes
  %11 = call i32 @cqrt_tape_write_i8(i32 %4, i32 %6)    ; IR: byte 0: cell 0 (the register x) copied onto a fresh tape rail
  %12 = call i32 @cqrt_tape_write_i8(i32 %4, i32 %8)    ; IR: byte 1: cell 1 (%8) copied onto a fresh tape rail
  call void @cqrt_tape_write_i8_lit(i32 %4, i8 122)    ; IR: byte 2: cell 2, the classical 'z'
  %13 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %12 = icmp sgt i32 %7, %2  [path predicate of block %13]
  %14 = load ptr, ptr @__stdoutp, align 8    ; IR: %14 = load ptr, ptr @__stdoutp  (the stream: stdout, this tape)
  call void @cqrt_tape_fmt_controlled(i32 %13, i32 %4, ptr @.str)    ; IR: block %13: %15 = fputs(@.str, %14): entry opened under the predicate, no fields
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %13, i32 %7, i32 %2)    ; IR: uncompute %12
  call void @cqrt_free(i32 %13)    ; IR: release the %12 rail (|0>)
  call void @cq_template_add_i8_hl_unc(i32 %8, i32 %6, i8 1)    ; IR: uncompute %8 (cell 1; its tape copy stays)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %7, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %15 = call i8 @cqrt_measure_i8(i32 %6)    ; IR: %17 = cq_measure_ui8(%5)
  %16 = zext i8 %15 to i32    ; IR: %18 = zext i8 %17 to i32  (classical)
  ret i32 %16    ; IR: ret i32 %18
}

declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_fmt(i32, ptr)
declare void @cqrt_tape_fmt_controlled(i32, i32, ptr)
declare i32 @cqrt_tape_write_i8(i32, i32)
declare void @cqrt_tape_write_i8_lit(i32, i8)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i8(i32, double)
declare i8 @cqrt_measure_i8(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare void @cq_template_add_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
