; control_multiexit_reject_variadic_musttail.ll — DECLINE (bd test_C_libtooling-dm7f.5):
; a `musttail` in a VARIADIC caller. LangRef: such a call forwards the caller's
; unprototyped variadic arguments to the callee (the trailing `...` in the argument
; list, which the IR parser accepts ONLY on a `musttail` call); a plain call forwards
; nothing, so the demotion the `ret` merge needs would change what `@vk` receives —
; there is not even a plain spelling of it. Refused before any mutation. IR-only; a
; compiler gap (reported with dm7f.5), not physics.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: variadic musttail forward under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @vk(i32, ...)

define i32 @example(i32 %u0, ...) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %fwd, label %done
fwd:
  %r = musttail call i32 (i32, ...) @vk(i32 %u0, ...)
  ret i32 %r
done:
  ret i32 %q
}
