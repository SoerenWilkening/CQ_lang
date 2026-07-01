; lowering_reject_byref_inline_body_load.ll — bd g7ip MISS-SAFETY probe. A visible
; by-ref producer whose store value READS MEMORY (`*out = v + g`, a load from a
; global). The loaded value's provenance is not modeled by the pure-cone proof, so
; inlining it could read the wrong value — ByRefInline SKIPS it (the body proof
; rejects any instruction that `mayReadFromMemory`), and it falls through to the
; EXISTING loud specializer decline. Only a body that is a PURE expression over
; the params + constants is inlined.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (memory access)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

@g = internal global i32 0

define i32 @demo() {
  %cell = alloca i32, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  call void @mysplit(i32 %q, ptr %cell)
  %r = load i32, ptr %cell, align 4
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

define internal void @mysplit(i32 %v, ptr %out) {
  %l = load i32, ptr @g, align 4
  %r = add nsw i32 %v, %l
  store i32 %r, ptr %out, align 4
  ret void
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
