; control_multiexit_musttail_classical_call_arm.ll — ACCEPT (bd test_C_libtooling-dm7f.5):
; the PLAIN-C `musttail` row. `@example` is `clang -O1`'s output (cleaned of target
; attributes) for
;     __attribute__((noinline)) int k(int u, int a) { return a + 100; }
;     __attribute__((noinline)) int f(int u, int a) {
;       int q = u; cq_theta(&q, .5);
;       if (q > 3) __attribute__((musttail)) return k(u, a);
;       return 5;
;     }
; A `musttail` call must be immediately followed by `ret`, so -O1 keeps a `ret` per
; arm (and replaces k's dead first argument with `poison`). On main 7b4e6359 this
; declined `non-reconverging value exit under quantum control` (measured). Now the
; `musttail` is demoted to `tail` — sound: `k` is not recursive into `@example`
; (CallGraph), the caller is not variadic, no `preallocated` operand — so the call,
; its operands and its result are unchanged and only the stack-reuse guarantee goes.
; The `ret`s merge, the empty `ret i32 5` block is folded into `entry`, and the module
; is `@twin` — clang's own output for the same source WITHOUT the attribute (a `tail`
; call and a merge φ): the 6.5 classical-call arm (control_classical_call_arm_accept_
; i32_ret.ll's shape). Both streams are pinned line for line.
;
; HAND TRACE. q = Ry(0.5)|u0>. The classical call `k(poison, a)` (pure, all-classical
; operands) is hoisted into the predecessor and runs once, classically: r = a + 100.
; f = [x > 3]. out = |0>. sel = alloc(r) holds the classical r; copy_controlled(f,
; sel, out) XORs r into out on the x > 3 branch; X f; sel' = alloc(5);
; copy_controlled(f, sel', out) XORs 5 into out on the x <= 3 branch; X f restores
; f. The `_unc` strip returns f to 0 and frees it. out = sum_x a_x |x>|x > 3 ? a+100 :
; 5> — f's value on every branch — and it ESCAPES via `ret` (the caller owns it).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i32 @cq_theta_si32(i32, double)

define i32 @k(i32 %u, i32 %a) #0 {
  %s = add nsw i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %other
arm:
  %r = musttail call i32 @k(i32 poison, i32 %a)
  ret i32 %r
other:
  ret i32 5
}

define i32 @twin(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %m
arm:
  %r = tail call i32 @k(i32 poison, i32 %a)
  br label %m
m:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  ret i32 %y
}

attributes #0 = { noinline nounwind willreturn memory(none) }

; CHECK: define i32 @example(i32 %u0, i32 %a) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call i32 @k(i32 poison, i32 %a)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[OUT]], i32 %[[R]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
; CHECK: define i32 @twin(i32 %u0, i32 %a) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[TH]], double 5.000000e-01)
; CHECK-NEXT: %[[TR:[a-zA-Z0-9_.]+]] = tail call i32 @k(i32 poison, i32 %a)
; CHECK-NEXT: %[[TF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TH]], i32 3)
; CHECK-NEXT: %[[TOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[TF]], i32 %[[TOUT]], i32 %[[TR]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[TF]], i32 %[[TOUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF]], i32 %[[TH]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF]])
; CHECK-NEXT: ret i32 %[[TOUT]]
; CHECK-NEXT: }

; WHOLE-FILE, PURE-NEGATIVE. (`musttail call`, not `musttail`: the ModuleID line
; carries this file's own name.)
; NEG-NOT: musttail call
; NEG-NOT: cq.retmerge
; NEG-NOT: cqrt_cswap
; NEG-NOT: call void @cqrt_free(i32 %out
