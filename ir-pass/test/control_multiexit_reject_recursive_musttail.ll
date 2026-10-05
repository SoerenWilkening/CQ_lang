; control_multiexit_reject_recursive_musttail.ll — DECLINE (bd test_C_libtooling-dm7f.5):
; the decline twin of control_multiexit_musttail_classical_call_arm.ll. Merging the
; `ret`s of a multi-exit function under tainted control requires demoting each
; `musttail` before them to `tail`, which drops only the stack-reuse guarantee — and
; that guarantee is LOAD-BEARING when the callee is the caller itself: `musttail` is
; what keeps a self-recursion in constant stack, and a quantum-controlled recursion
; needs a finite bound (NORTHSTAR goal 1) that nothing here supplies. So the function
; is refused BEFORE any mutation (`mustTailDemotionRefusal`, ReturnMerge.cpp), with
; the call's location. Retirement trigger: a programmer-supplied bound (bd wrwo,
; `cq_bound`) lets this lower; re-derive the expectation then.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: recursive musttail call under quantum control

declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %rec, label %done
rec:
  %n1 = sub i32 %n, 1
  %r = musttail call i32 @example(i32 %u0, i32 %n1)
  ret i32 %r
done:
  ret i32 %q
}
