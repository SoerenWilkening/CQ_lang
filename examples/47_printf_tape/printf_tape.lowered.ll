; HAND-WRITTEN. Rules: 16, 8, 4, 5, 2.
; Checked: printf_quantum: x (%4, measured as %6); printf_under_quantum_if: x (%5, measured as %8); printf_mixed:
; y = x + c (%6, measured as %9).
; Clean: printf_under_quantum_if's flag x > k (%6), uncomputed after the controlled tape entry and freed.
; Kept: each function's tape (%3 / %4 / %4) and its write-only tape rails (%5; %7; %7 and %8), which stay entangled with
; the register they copy and are never freed; the registers x (and y in printf_mixed, the source of the measured value).
; Rotations: (Ry, x, th, 1) in each function.
; Each printf opens one tape ENTRY with its format string (cqrt_tape_fmt); quantum fields are appended as fresh
; write-only rails (CNOT copies, never freed or uncomputed), classical fields as literals (rule 16: a side-effecting
; host call is a tape entry with its predicate). Under a quantum condition the entry and every field are controlled by
; the predicate; the entry is always appended, so the tape length is classical. No measurement is inserted: the backend
; reads the tape after the program's last own measurement and prints the entries whose predicate measured 1. Printing a
; quantum value is an observation written by the user: the tape rail stays entangled with the register. printf's return
; value is unused and dropped.
source_filename = "printf_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@.str.1 = private unnamed_addr constant [8 x i8] c"big %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [10 x i8] c"%d %d %d\0A\00", align 1

define i32 @printf_quantum(i32 noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_tape_alloc()    ; IR: the function's output tape
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %3 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %3 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_tape_fmt(i32 %3, ptr @.str)    ; IR: %4 = printf(@.str, %3): open the entry with its format string
  %5 = call i32 @cqrt_tape_write_i32(i32 %3, i32 %4)    ; IR: %4 = printf(..., %3): field 0, a quantum value copied onto a fresh tape rail
  %6 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%3)
  ret i32 %6    ; IR: ret i32 %5
}

define i32 @printf_under_quantum_if(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's output tape
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [path predicate of block %6]
  call void @cqrt_tape_fmt_controlled(i32 %6, i32 %4, ptr @.str.1)    ; IR: block %6: %7 = printf(@.str.1, %4): entry opened under the predicate (printed iff it measures 1)
  %7 = call i32 @cqrt_tape_write_i32_controlled(i32 %6, i32 %4, i32 %5)    ; IR: %7 = printf(..., %4): field 0 copied under the predicate
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  %8 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %9 = cq_measure_si32(%4)
  ret i32 %8    ; IR: ret i32 %9
}

define i32 @printf_mixed(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's output tape
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %2)    ; IR: %5 = add nsw i32 %4, %2
  call void @cqrt_tape_fmt(i32 %4, ptr @.str.2)    ; IR: %6 = printf(@.str.2, %4, %2, %5): open the entry
  %7 = call i32 @cqrt_tape_write_i32(i32 %4, i32 %5)    ; IR: field 0: %4 (quantum)
  call void @cqrt_tape_write_i32_lit(i32 %4, i32 %2)    ; IR: field 1: %2 (classical literal)
  %8 = call i32 @cqrt_tape_write_i32(i32 %4, i32 %6)    ; IR: field 2: %5 (quantum)
  %9 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%5)
  ret i32 %9    ; IR: ret i32 %7
}

declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_fmt(i32, ptr)
declare void @cqrt_tape_fmt_controlled(i32, i32, ptr)
declare i32 @cqrt_tape_write_i32(i32, i32)
declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)
declare void @cqrt_tape_write_i32_lit(i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
