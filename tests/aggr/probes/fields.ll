; tests/aggr probes (cq-w1-aggr), written by hand: rule 26 field-wise aggregates that clang -O1 does not keep
; inside one function (SROA splits them). Nested struct/array fields mixing rails and classical values, a
; constant aggregate operand, a classical field read back as a literal, and an aggregate field replaced.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%T = type { i32, [2 x i32], i32 }

define i32 @p_fields(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %a = insertvalue %T poison, i32 %x, 0
  %b = insertvalue %T %a, i32 %2, 1, 0
  %y = add i32 %x, %2
  %d = insertvalue %T %b, i32 %y, 1, 1
  %e = insertvalue %T %d, i32 7, 2
  %arr = extractvalue %T %e, 1
  %p = extractvalue [2 x i32] %arr, 1
  %c0 = extractvalue [2 x i32] %arr, 0
  %q = extractvalue %T %e, 0
  %r = extractvalue %T %e, 2
  %s = mul i32 %p, %q
  %t = add i32 %s, %r
  %u = xor i32 %t, %c0
  %m = tail call i32 @cq_measure_ui32(i32 noundef %u)
  ret i32 %m
}

define i32 @p_constagg(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %a = insertvalue { i32, { i32, i32 } } { i32 3, { i32, i32 } { i32 5, i32 11 } }, i32 %x, 1, 0
  %in = extractvalue { i32, { i32, i32 } } %a, 1
  %k = extractvalue { i32, { i32, i32 } } %a, 0
  %hi = extractvalue { i32, i32 } %in, 1
  %lo = extractvalue { i32, i32 } %in, 0
  %b = insertvalue { i32, { i32, i32 } } %a, { i32, i32 } { i32 13, i32 17 }, 1
  %z = extractvalue { i32, { i32, i32 } } %b, 1, 1
  %s = mul i32 %lo, %hi
  %t = add i32 %s, %k
  %u = sub i32 %t, %z
  %v = xor i32 %u, %2
  %m = tail call i32 @cq_measure_ui32(i32 noundef %v)
  ret i32 %m
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef)
declare i32 @cq_measure_ui32(i32 noundef)
