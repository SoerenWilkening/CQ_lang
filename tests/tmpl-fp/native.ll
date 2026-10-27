; Native reference for the tmpl-fp differential test (cq-w0-tmpl-fp).
; Each function is the plain LLVM IR operation the template stands for, on bit patterns passed as
; integers (no half/float ABI questions). Compiled by clang-19 -O1 for x86_64-apple-macosx and run
; on the host; tests/tmpl-fp/test_tmpl_fp.c compares checker/rt/tmpl_fp.c against it.

define i16 @native_fadd_f16(i16 %a, i16 %b) {
  %x = bitcast i16 %a to half
  %y = bitcast i16 %b to half
  %r = fadd half %x, %y
  %o = bitcast half %r to i16
  ret i16 %o
}

define i16 @native_fsub_f16(i16 %a, i16 %b) {
  %x = bitcast i16 %a to half
  %y = bitcast i16 %b to half
  %r = fsub half %x, %y
  %o = bitcast half %r to i16
  ret i16 %o
}

define i16 @native_fmul_f16(i16 %a, i16 %b) {
  %x = bitcast i16 %a to half
  %y = bitcast i16 %b to half
  %r = fmul half %x, %y
  %o = bitcast half %r to i16
  ret i16 %o
}

define i16 @native_fdiv_f16(i16 %a, i16 %b) {
  %x = bitcast i16 %a to half
  %y = bitcast i16 %b to half
  %r = fdiv half %x, %y
  %o = bitcast half %r to i16
  ret i16 %o
}

define i16 @native_frem_f16(i16 %a, i16 %b) {
  %x = bitcast i16 %a to half
  %y = bitcast i16 %b to half
  %r = frem half %x, %y
  %o = bitcast half %r to i16
  ret i16 %o
}

define i16 @native_fneg_f16(i16 %a) {
  %x = bitcast i16 %a to half
  %r = fneg half %x
  %o = bitcast half %r to i16
  ret i16 %o
}

define i16 @native_sqrt_f16(i16 %a) {
  %x = bitcast i16 %a to half
  %r = call half @llvm.sqrt.f16(half %x)
  %o = bitcast half %r to i16
  ret i16 %o
}

define i16 @native_fma_f16(i16 %a, i16 %b, i16 %c) {
  %x = bitcast i16 %a to half
  %y = bitcast i16 %b to half
  %z = bitcast i16 %c to half
  %r = call half @llvm.fma.f16(half %x, half %y, half %z)
  %o = bitcast half %r to i16
  ret i16 %o
}

declare half @llvm.sqrt.f16(half)
declare half @llvm.fma.f16(half, half, half)

define i32 @native_fadd_f32(i32 %a, i32 %b) {
  %x = bitcast i32 %a to float
  %y = bitcast i32 %b to float
  %r = fadd float %x, %y
  %o = bitcast float %r to i32
  ret i32 %o
}

define i32 @native_fsub_f32(i32 %a, i32 %b) {
  %x = bitcast i32 %a to float
  %y = bitcast i32 %b to float
  %r = fsub float %x, %y
  %o = bitcast float %r to i32
  ret i32 %o
}

define i32 @native_fmul_f32(i32 %a, i32 %b) {
  %x = bitcast i32 %a to float
  %y = bitcast i32 %b to float
  %r = fmul float %x, %y
  %o = bitcast float %r to i32
  ret i32 %o
}

define i32 @native_fdiv_f32(i32 %a, i32 %b) {
  %x = bitcast i32 %a to float
  %y = bitcast i32 %b to float
  %r = fdiv float %x, %y
  %o = bitcast float %r to i32
  ret i32 %o
}

define i32 @native_frem_f32(i32 %a, i32 %b) {
  %x = bitcast i32 %a to float
  %y = bitcast i32 %b to float
  %r = frem float %x, %y
  %o = bitcast float %r to i32
  ret i32 %o
}

define i32 @native_fneg_f32(i32 %a) {
  %x = bitcast i32 %a to float
  %r = fneg float %x
  %o = bitcast float %r to i32
  ret i32 %o
}

define i32 @native_sqrt_f32(i32 %a) {
  %x = bitcast i32 %a to float
  %r = call float @llvm.sqrt.f32(float %x)
  %o = bitcast float %r to i32
  ret i32 %o
}

define i32 @native_fma_f32(i32 %a, i32 %b, i32 %c) {
  %x = bitcast i32 %a to float
  %y = bitcast i32 %b to float
  %z = bitcast i32 %c to float
  %r = call float @llvm.fma.f32(float %x, float %y, float %z)
  %o = bitcast float %r to i32
  ret i32 %o
}

declare float @llvm.sqrt.f32(float)
declare float @llvm.fma.f32(float, float, float)

define i64 @native_fadd_f64(i64 %a, i64 %b) {
  %x = bitcast i64 %a to double
  %y = bitcast i64 %b to double
  %r = fadd double %x, %y
  %o = bitcast double %r to i64
  ret i64 %o
}

define i64 @native_fsub_f64(i64 %a, i64 %b) {
  %x = bitcast i64 %a to double
  %y = bitcast i64 %b to double
  %r = fsub double %x, %y
  %o = bitcast double %r to i64
  ret i64 %o
}

define i64 @native_fmul_f64(i64 %a, i64 %b) {
  %x = bitcast i64 %a to double
  %y = bitcast i64 %b to double
  %r = fmul double %x, %y
  %o = bitcast double %r to i64
  ret i64 %o
}

define i64 @native_fdiv_f64(i64 %a, i64 %b) {
  %x = bitcast i64 %a to double
  %y = bitcast i64 %b to double
  %r = fdiv double %x, %y
  %o = bitcast double %r to i64
  ret i64 %o
}

define i64 @native_frem_f64(i64 %a, i64 %b) {
  %x = bitcast i64 %a to double
  %y = bitcast i64 %b to double
  %r = frem double %x, %y
  %o = bitcast double %r to i64
  ret i64 %o
}

define i64 @native_fneg_f64(i64 %a) {
  %x = bitcast i64 %a to double
  %r = fneg double %x
  %o = bitcast double %r to i64
  ret i64 %o
}

define i64 @native_sqrt_f64(i64 %a) {
  %x = bitcast i64 %a to double
  %r = call double @llvm.sqrt.f64(double %x)
  %o = bitcast double %r to i64
  ret i64 %o
}

define i64 @native_fma_f64(i64 %a, i64 %b, i64 %c) {
  %x = bitcast i64 %a to double
  %y = bitcast i64 %b to double
  %z = bitcast i64 %c to double
  %r = call double @llvm.fma.f64(double %x, double %y, double %z)
  %o = bitcast double %r to i64
  ret i64 %o
}

declare double @llvm.sqrt.f64(double)
declare double @llvm.fma.f64(double, double, double)
