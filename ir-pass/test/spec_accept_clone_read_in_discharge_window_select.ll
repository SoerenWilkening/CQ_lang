; spec_accept_clone_read_in_discharge_window_select.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-rhk5; family member `f07`). The callee `h(a, k) = k > 3 ? k : 0`
; lifts to a clone whose body is the 5po2 clone-select merge: a compare flag, two
; `cqrt_copy_i32_controlled(%h_cmp, %k, %cqq.sel)` (forward + its self-inverse
; replay), the copy-out, and the compare's adjoint. The formal `%k` is a compare
; operand (B1), a controlled copy's SOURCE (B3') and an adjoint read slot (B2) — never
; a destination — so `cloneCallPreservesArg` admits the call and the caller's chain
; `3q`, `3q ^ q` is discharged before the second Ry.
;
; ORACLE (main 9a230646): the lyyf-(B) warning, the chain left allocated. The
; hand-inlined twin (`s = q > 3 ? q : 0`) DECLINES at the 4.4 select's condition-wire
; fence (`condition predates a non-diagonal gate`), so there is no twin stream to
; compare with; this file pins the discharge and the unchanged clone body, and the
; family battery records the member's 2b/entangle.py result (TRACK_RHK5.md §5.2).
;
; bd p3kd.7.8: main's 4.4 `SelectMergeEmit` now lowers the clone's select (the clone-only
; `lowerCloneSelect` and its one-copy const-zero fast path are gone): the false arm 0 is
; materialized as a |0> rail and ¬flag-copied (XOR of 0, the identity), and the wrap
; mirrors both copies inside the re-played `cqrt_x`. `%k` is still only a compare
; operand, a copy SOURCE and an `_unc` read slot, so the caller's discharge is unchanged.
; Hand trace: SEL = [k>3]·k ⊕ ¬[k>3]·0; the mirror undoes the zero copy, restores the flag,
; undoes the k copy (SEL = 0), the `_unc` zeroes the flag; all three rails free at |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %s = call i32 @h(i32 %m, i32 %q)
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %ms = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %c = icmp sgt i32 %k, 3
  %r = select i1 %c, i32 %k, i32 0
  ret i32 %r
}

; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase
; LOWER-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: %m2 = call i32 @cqrt_measure_i32(i32 %s)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
;
; CLONE-LABEL: define internal i32 @__cq_q_h_10(i32 %a, i32 %k)
; CLONE-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %k, i32 3)
; CLONE-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %k, i32 %[[SEL]])
; CLONE-NEXT: call void @cqrt_x(i32 %[[F]])
; CLONE-NEXT: %[[K0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K0]], i32 %[[SEL]])
; CLONE-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CLONE-NEXT: call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; CLONE-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[K0]], i32 %[[SEL]])
; CLONE-NEXT: call void @cqrt_x(i32 %[[F]])
; CLONE-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %k, i32 %[[SEL]])
; CLONE-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %k, i32 3)
; CLONE-NEXT: call void @cqrt_free(i32 %[[F]])
; CLONE-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CLONE-NEXT: call void @cqrt_free(i32 %[[K0]])
; CLONE-NEXT: ret i32 %[[OUT]]
; CLONE-NEXT: }
