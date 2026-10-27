; Rails wider than one word: i100, i128 and f80 alloc, copy and measure.
target triple = "x86_64-apple-macosx16.0.0"
define i128 @wide(i128 %v, x86_fp80 %e) {
  %a = call i32 @cqrt_alloc_i128(i128 %v)
  %b = call i32 @cqrt_alloc_i128(i128 0)
  call void @cqrt_copy_i128(i32 %a, i32 %b)
  %c = call i32 @cqrt_alloc_i100(i100 -1)
  %d = call i32 @cqrt_alloc_f80(x86_fp80 %e)
  %bm = call i128 @cqrt_measure_i128(i32 %b)
  %cm = call i100 @cqrt_measure_i100(i32 %c)
  %dm = call x86_fp80 @cqrt_measure_f80(i32 %d)
  %ce = zext i100 %cm to i128
  %db = bitcast x86_fp80 %dm to i80
  %de = zext i80 %db to i128
  %s0 = xor i128 %bm, %ce
  %s = xor i128 %s0, %de
  ret i128 %s
}
declare i32 @cqrt_alloc_i128(i128)
declare i32 @cqrt_alloc_i100(i100)
declare i32 @cqrt_alloc_f80(x86_fp80)
declare void @cqrt_copy_i128(i32, i32)
declare i128 @cqrt_measure_i128(i32)
declare i100 @cqrt_measure_i100(i32)
declare x86_fp80 @cqrt_measure_f80(i32)
