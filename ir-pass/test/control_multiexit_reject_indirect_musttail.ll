; control_multiexit_reject_indirect_musttail.ll — DECLINE (bd test_C_libtooling-dm7f.5):
; a `musttail` through a function POINTER in a multi-exit function under tainted
; control. The demotion's soundness rests on the callee not reaching the caller again
; (the recursion refusal); an indirect callee has no body to ask, so the function is
; refused before any mutation. (A pointer call under quantum control is also opaque
; code with no implementation to lift — NORTHSTAR goal 1's closed list.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: indirect musttail call under quantum control

declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0, ptr %fp) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %call, label %done
call:
  %r = musttail call i32 %fp(i32 %u0, ptr %fp)
  ret i32 %r
done:
  ret i32 %q
}
