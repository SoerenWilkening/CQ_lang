; cq-2h7xa (BACKEND_ABI §1.15, CR rule 6's in-place update): add, sub, addc forward, at i100 across a word, and
; inverted by a cq_invert region (add <-> sub, addc of the negated literal).
target triple = "x86_64-apple-macosx16.0.0"
define i32 @inplace(i32 %x0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %x0)
  %y = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_add_i32(i32 %y, i32 %x)
  call void @cqrt_sub_i32(i32 %y, i32 %x)
  call void @cqrt_addc_i32(i32 %x, i32 -3)
  call void @cqrt_invert_begin()
  call void @cqrt_add_i32(i32 %y, i32 %x)
  call void @cqrt_addc_i32(i32 %x, i32 10)
  call void @cqrt_invert_end()
  call void @cqrt_free(i32 %y)
  %w = call i32 @cqrt_alloc_i100(i100 18446744073709551615)
  call void @cqrt_addc_i100(i32 %w, i100 1)
  %v = call i32 @cqrt_alloc_i100(i100 5)
  call void @cqrt_sub_i100(i32 %v, i32 %w)
  call void @cqrt_addc_i100(i32 %w, i100 -1)
  call void @cqrt_free(i32 %v)
  %xm = call i32 @cqrt_measure_i32(i32 %x)
  %wm = call i100 @cqrt_measure_i100(i32 %w)
  %wl = trunc i100 %wm to i32
  %r = xor i32 %xm, %wl
  ret i32 %r
}
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i100(i100)
declare void @cqrt_add_i32(i32, i32)
declare void @cqrt_sub_i32(i32, i32)
declare void @cqrt_addc_i32(i32, i32)
declare void @cqrt_addc_i100(i32, i100)
declare void @cqrt_sub_i100(i32, i32)
declare void @cqrt_invert_begin()
declare void @cqrt_invert_end()
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i100 @cqrt_measure_i100(i32)
