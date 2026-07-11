; control_swap_reject_select_i1sel_combinator.ll — DECLINE PIN (3c6m.12 L4
; probe): a `select`-of-i1 COMBINATOR condition (`select %c1, true, %c2` — the
; short-circuit form InstCombine normally folds to `or` for pure compares).
; The condition tree grammar is and/or over CmpInst leaves ONLY; an i1-select
; node is out. The inner i1 select is itself discovered as a (legitimate) i1
; DATA region and may emit, but the OUTER select's condition is then a non-tree
; value → gate 2 declines LOUDLY at detection and `opt` exits non-zero, writing
; no output — the pre-existing loud outcome, pinned here so the compound accept
; can never silently swallow the combinator shape (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %c   = select i1 %c1, i1 true, i1 %c2      ; i1 combinator select
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
