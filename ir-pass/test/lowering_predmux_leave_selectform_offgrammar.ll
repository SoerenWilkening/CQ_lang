; lowering_predmux_leave_selectform_offgrammar.ll — DECLINE probe (bd adia):
; only the two POISON-SHIELD select forms are E6-admissible —
; `select(a, b, false)` (&&) and `select(a, true, b)` (||). A general i1
; select COMBINATOR (`select(a, b, c)`, all three non-constant — a genuine
; data mux over booleans) is NOT a short-circuit shield and has no negation
; inside the no-NOT literal grammar; the region is left and the existing loud
; nested-control decline fires, char-for-char.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 5
  %b = icmp slt i32 %q, 100
  %b2 = icmp ne i32 %q, 42
  %c1 = select i1 %a, i1 %b, i1 %b2   ; off-grammar: all-non-constant combinator
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = add i32 %q, 3
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
