; control_classical_call_arm_twin_reject_round2_arg.ll — DECLINE (bd dm7f.33, still
; open after batch 053). Hand IR (C hits the pre-existing two-sequential-6.5-arms
; decline first, bd dm7f.22 / 35t0, because clang merges the first arm's merge block
; into the second arm's predecessor):
;   int g(int v){ return v ^ 5; }   int f(int v){ return v * 3; }
;   int h(int x){ return g(x + 1); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int p = 0; cq_theta(&p, 0.5);
;                  int y = 5; if (q > 3) y = f(k);   /* 6.5 arm 1: %out1 */
;                  int z = p; if (p > 2) z = h(y);   /* 6.5 arm 2: reads y */
;                  return cq_measure(z); }
; Arm 2 is claimed while `y` (a merge of `f(k)` and 5) is still classical. Arm 1's
; emitter then replaces `y` by its quantum `%out1`, arm 2's emitter freezes that
; argument and hoists `@h`'s speculation-safe twin on it, and the round-2
; propagation (`repropagateControlMerges`) taints the twin call: it becomes a
; quantum call, and the lift refuses the twin's `freeze` (a classical artefact).
; WHY IT STAYS LOUD (R1): lifting it needs more than this lane's files. The call
; must be lifted as the ORIGINAL `@h`, the emitter's root `freeze` of a now-quantum
; argument must fold (TaintPropagation `isLocalIntegerIdentityFreeze` refuses a
; freeze feeding a user callee), and the emitter's `cqrt_alloc_i32(%result)`
; materialization of a classical result must become the identity on a quantum one
; (ClassicalCallArmEmit.cpp; left as is it would allocate a register holding a
; handle's tag). The same shape without a twin declines too
; (`cq taint escape: tainted value reaches an unsupported instruction`, the root
; freeze). Retire this row when dm7f.33 lands.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: note: {{.*}}in function ex i32 (i32): cq specialization: the error below is inside the quantum call to '__cq_specsafe_h' lifted from here
; CHECK: error: {{.*}}in function __cq_specsafe_h i32 (i32): cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal noundef i32 @g(i32 noundef %v) #0 {
  %r = xor i32 %v, 5
  ret i32 %r
}
define internal i32 @f(i32 noundef %v) #0 {
  %r = mul i32 %v, 3
  ret i32 %r
}
define internal i32 @h(i32 noundef %x) #0 {
  %a = add nsw i32 %x, 1
  %r = call i32 @g(i32 noundef %a)
  ret i32 %r
}

define i32 @ex(i32 noundef %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 0.000000e+00)
  %p = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 3
  br i1 %c1, label %arm1, label %m1
arm1:
  %fy = call i32 @f(i32 noundef %k)
  br label %m1
m1:
  %y = phi i32 [ %fy, %arm1 ], [ 5, %entry ]
  br label %mid
mid:
  %c2 = icmp sgt i32 %p, 2
  br i1 %c2, label %arm2, label %m2
arm2:
  %hz = call i32 @h(i32 noundef %y)
  br label %m2
m2:
  %z = phi i32 [ %hz, %arm2 ], [ %p, %mid ]
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
