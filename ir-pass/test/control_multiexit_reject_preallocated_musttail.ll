; control_multiexit_reject_preallocated_musttail.ll — DECLINE (bd
; test_C_libtooling-dm7f.5): a `musttail` that forwards a `preallocated` argument. A
; `preallocated` call-site operand is legal only on a `musttail` call or with a
; "preallocated" operand bundle a forwarded argument has no token for, so the demoted
; call would be invalid IR — there is no plain-`tail` spelling to be identical to.
; Refused before any mutation, with the same words the clone path's `scanBody` uses
; for the same forward (SpecializeReject.cpp). IR-only (the 32-bit Windows C++ ABI).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: musttail forward of a preallocated argument under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @pk(ptr preallocated(i32), i32)

define i32 @example(ptr preallocated(i32) %p, i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %fwd, label %done
fwd:
  %r = musttail call i32 @pk(ptr preallocated(i32) %p, i32 %u0)
  ret i32 %r
done:
  ret i32 %q
}
