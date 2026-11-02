; cq-3o3v: each firing Ry logs its target's value before the gate ("pre"); an unmatched firing Ry with
; the negated angle of the last Ry on an untouched rail (CR rule 10's un-prep) puts the value back.
; %r: Ry(0.5) takes a reach, Ry(-0.5) undoes it (r reads 3 again). %s: Ry(0.25) takes a reach, a write,
; then Ry(-0.25): no un-prep (s keeps 0x10 ^ 1). %u: Ry(0.75) takes a reach, Ry(0.75) again: not the
; adjoint (u keeps the reach's value).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @tu(i32 %x0, double %th) {
  %r = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %r, double 0.5)
  call void @cqrt_ry_i32(i32 %r, double -0.5)
  %s = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %s, double 0.25)
  call void @cqrt_xorc_i32(i32 %s, i32 1)
  call void @cqrt_ry_i32(i32 %s, double -0.25)
  %u = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %u, double 0.75)
  call void @cqrt_ry_i32(i32 %u, double 0.75)
  %mr = call i32 @cqrt_measure_i32(i32 %r)
  %ms = call i32 @cqrt_measure_i32(i32 %s)
  %mu = call i32 @cqrt_measure_i32(i32 %u)
  %a = add i32 %mr, %ms
  %b = add i32 %a, %mu
  ret i32 %b
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_xorc_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
