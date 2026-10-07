; spec_accept_clone_main_condtree.ll — bd p3kd.7.8: a lifted clone is lowered by
; MAIN'S stage list (StageList.h), and the Bennett wrap reverses whatever main's
; emitters mint, mechanically (BennettWrap.h; owner rulings 2026-10-07).
;
; `sel(x) = (x < 1000 && x != 0) ? x*3 : x+7` (clang -O1: `and i1` of two compares
; feeding one select), called with a quantum `x`. Inside the clone main's 4.4
; select path runs: CondTreeEmit mints the compare flags and the AND node onto an
; `i1` ancilla (`cqrt_toffoli`), SelectMergeEmit does the X-bracketed two-copy
; merge into a fresh `|0>` rail. Main then strips the network and frees the flags
; INLINE; inside a clone the wrap elides those strips (a strip writes only its own
; rail after that rail's last read, and a lifted body is a basis permutation), so:
;   * FORWARD: network, the two copies, NO `_unc` / `cqrt_free` / trailing `cqrt_x`
;     before the copy-out (the elided strip — main would emit them here);
;   * the copy-out `cqrt_copy_i32(%out, %cqq.out)`;
;   * REVERSE: the exact mirror of the forward that remains, operand-identical, so
;     stage 2b pairs every adjoint with its forward gate;
;   * every `|0>` rail freed only after the reverse; `%cqq.out` returned.
; Before p3kd.7.8 the clone used its own select lowering (`lowerCloneSelect`,
; removed): forward-only network + one or two copies, a second spelling of this.
;
; Unitary (traced by hand): g = (x<1000)∧(x≠0); copy(g, 3x) then copy(¬g, x+7)
; leaves out = g ? 3x : x+7; the reverse replays copy(¬g, x+7), X, copy(g, 3x) and
; zeroes out, the toffoli zeroes g, the compare/arm `_unc`s zero their rails.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define internal i32 @__cq_q_sel_1(
; CHECK:       %[[ADD:[^ ]+]] = call i32 @cq_template_add_i32_hl(i32 %x, i32 7)
; CHECK:       %[[MUL:[^ ]+]] = call i32 @cq_template_mul_i32_hl(i32 %x, i32 3)
; CHECK:       %[[C1:[^ ]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %x, i32 1000)
; CHECK:       %[[C2:[^ ]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %x, i32 0)
; CHECK:       %[[G:[^ ]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_toffoli(i32 %[[C1]], i32 %[[C2]], i32 %[[G]])
; CHECK-NEXT:  %[[OUT:[^ ]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[MUL]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[ADD]], i32 %[[OUT]])
; CHECK-NEXT:  %[[CO:[^ ]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[OUT]], i32 %[[CO]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[ADD]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[MUL]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_toffoli(i32 %[[C1]], i32 %[[C2]], i32 %[[G]])
; CHECK-NEXT:  call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[C2]], i32 %x, i32 0)
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[C1]], i32 %x, i32 1000)
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[MUL]], i32 %x, i32 3)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[ADD]], i32 %x, i32 7)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[ADD]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[MUL]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[C2]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT:  ret i32 %[[CO]]
;
; The clone's forward holds no strip: no `_unc` and no free precede the copy-out.
; RUN: %filecheck --check-prefix=NOSTRIP %s < %t.ll
; NOSTRIP-LABEL: define internal i32 @__cq_q_sel_1(
; NOSTRIP-NOT:   {{_unc\(|cqrt_free}}
; NOSTRIP:       call void @cqrt_copy_i32(

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @sel(i32 noundef %x) {
entry:
  %add = add nsw i32 %x, 7
  %c1 = icmp slt i32 %x, 1000
  %c2 = icmp ne i32 %x, 0
  %and = and i1 %c1, %c2
  %mul = mul nsw i32 %x, 3
  %r = select i1 %and, i32 %mul, i32 %add
  ret i32 %r
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @sel(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
