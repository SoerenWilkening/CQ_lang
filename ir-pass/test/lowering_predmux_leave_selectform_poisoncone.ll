; lowering_predmux_leave_selectform_poisoncone.ll — DECLINE probe (bd adia
; Rule-13 board, the inherent-poison note): the select-form canonicalization
; `select(a,b,false)` -> `and(a,b)` observes the SHIELDED operand `b` on
; basis states the original never did, so its cone must be provably DEFINED
; after the flag drop. A shift by a RUNTIME amount has no flag to drop — an
; amount >= the bit width is inherent poison — so `coneDefinedAfterFlagDrop`
; fails, the select-form stays unclaimed, and the region falls to the
; existing loud nested-control decline, char-for-char.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 5
  %sh = shl i32 1, %q                 ; runtime shift amount — inherent poison
  %b = icmp ult i32 %sh, 4096
  %c1 = select i1 %a, i1 %b, i1 false ; shielded cone contains %sh -> fence
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
