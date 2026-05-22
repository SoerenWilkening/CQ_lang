; Stage 4 LLVM IR — hand-written, mimicking what the rewriter + Clang -O1 would produce
; for the CQ source:
;
;   quantum int a = 3;
;   quantum int b = 5;
;   quantum int c = a + b;
;   int m = (int) c;          // measurement-as-cast
;   return m;

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; The mid-level struct type carrying the quantum signal at function boundaries.
%qint_mid_t = type { i32 }

; Front-end intrinsic declarations — survive Clang's -O1 cleanup as opaque externs.
declare %qint_mid_t @cq_init_i32(i32)
declare i64         @cq_measure(%qint_mid_t)

define i64 @example() {
entry:
  ; quantum int a = 3
  %a_struct = call %qint_mid_t @cq_init_i32(i32 3)
  %a        = extractvalue %qint_mid_t %a_struct, 0

  ; quantum int b = 5
  %b_struct = call %qint_mid_t @cq_init_i32(i32 5)
  %b        = extractvalue %qint_mid_t %b_struct, 0

  ; quantum int c = a + b   — tainted add, both operands quantum
  %c        = add i32 %a, %b

  ; (int) c   — measurement
  %c_struct = insertvalue %qint_mid_t poison, i32 %c, 0
  %m        = call i64 @cq_measure(%qint_mid_t %c_struct)

  ret i64 %m
}
