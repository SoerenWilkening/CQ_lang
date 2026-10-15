; spec_accept_select_derived_true.ll — ACCEPT (bd p3kd.7.1; was
; spec_reject_select_derived_true.ll, a 5po2 slice-1 accept-shape boundary): a
; lifted `select` whose TRUE arm is the DERIVED value `b + 1` and whose false arm
; is constant zero. The retired `isLiftableSelect` required a param-direct true
; arm next to a zero false arm, so this declined `InBodyControl`, although
; `lowerCloneSelect`'s one-copy fast path lowers it: the derived arm is a data
; template captured into the forward stream, controlled-copied into the |0> select
; rail, and reversed and freed by the Bennett wrap.
;
; Trace check, |b>: flag = [b < 5]; sel = flag·(b+1); out = sel. Reverse: the
; copy, then the compare `_unc`, then the add `_unc`, so every scratch rail is |0>
; before its free.
;
; bd p3kd.7.8: the clone's select is now lowered by MAIN's 4.4 SelectMergeEmit
; (the clone-only `lowerCloneSelect` and its one-copy fast path for a zero false
; arm are gone). The constant-zero false arm is materialized as its own
; `cqrt_alloc_i32(0)` rail and copied under ¬flag like any arm; main's inline
; strip is elided by the Bennett wrap, whose reverse is the EXACT mirror. Trace on
; |b>: f = [b<5]; out gets b+1 under f, then (f flipped) 0 under ¬f (out
; unchanged), so out = f·(b+1), the source's select; the mirror un-copies 0,
; re-flips f, un-copies b+1 (out -> |0>), then the compare and add `_unc`s zero f
; and d. The zero rail is only read, so it is |0> and freed with d, f and out.
; The property pinned is unchanged: a DERIVED true arm next to a zero false arm
; lifts and computes f·(b+1).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %d = add i32 %b, 1
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %d, i32 0   ; derived (non-param) true arm
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-NEXT:  %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[D]], i32 %[[SEL]])
; (bd dm7f.81: the FALSE arm is the constant 0: no write and no ¬flag bracket; its former %Z rail and free are gone.)
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[D]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F]], i32 %b, i32 5)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %b, i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
