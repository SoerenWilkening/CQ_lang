; control_multiexit_reject_mutual_recursive_musttail.ll — DECLINE (bd
; test_C_libtooling-dm7f.5): the MUTUAL-recursion half of the recursion refusal.
; `@example`'s tainted arm `musttail`-calls `@g`, and `@g` calls `@example` back, so
; `@g` reaches the caller in LLVM's `CallGraph` and the demotion would turn a
; constant-stack mutual recursion into a growing one. Refused before any mutation.
; (`@g`'s own two `ret`s sit under a CLASSICAL branch and are never touched.)
; Retirement trigger: bd wrwo's programmer-supplied bound.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: recursive musttail call under quantum control

declare i32 @cq_theta_si32(i32, double)

define i32 @g(i32 %u, i32 %n) {
entry:
  %z = icmp eq i32 %n, 0
  br i1 %z, label %stop, label %again
stop:
  ret i32 0
again:
  %n1 = sub i32 %n, 1
  %v = call i32 @example(i32 %u, i32 %n1)
  ret i32 %v
}

define i32 @example(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %rec, label %done
rec:
  %r = musttail call i32 @g(i32 %u0, i32 %n)
  ret i32 %r
done:
  ret i32 %q
}
