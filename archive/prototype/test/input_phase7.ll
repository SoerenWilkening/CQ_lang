; Stage 4 IR for Phase 7 specialization test.
;
; CQ source equivalent:
;   quantum int double_it(quantum int x) { return x + x; }
;
;   int main() {
;       quantum int a = 3;
;       quantum int b = double_it(a);     // this call should be specialized
;       int m = (int) b;
;       return m;
;   }

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_i32(i32)
declare i64         @cq_measure(%qint_mid_t)

; The user-defined function — a candidate for quantum specialization
; whenever it is called with a qint_mid_t-typed argument.
define %qint_mid_t @double_it(%qint_mid_t %x) {
entry:
  %x_val = extractvalue %qint_mid_t %x, 0
  %r_val = add i32 %x_val, %x_val
  %r     = insertvalue %qint_mid_t poison, i32 %r_val, 0
  ret %qint_mid_t %r
}

define i64 @example() {
entry:
  %a = call %qint_mid_t @cq_init_i32(i32 3)
  %b = call %qint_mid_t @double_it(%qint_mid_t %a)
  %m = call i64 @cq_measure(%qint_mid_t %b)
  ret i64 %m
}
