; lowering_predmux_leave_speccall_recursive.ll — DECLINE probe (bd adia): the
; pending-spec pure-callee proof breaks CALL-GRAPH cycles via its OnStack set
; (a recursive callee has no termination bound), so E4 leaves the region; the
; site then rides the spec path's own loud recursion decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: recursive callee has no static depth bound
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @purefn(i32 %a) {
entry:
  %c = icmp sgt i32 %a, 0
  br i1 %c, label %rec, label %done
rec:
  %a1 = add i32 %a, -1
  %r = call i32 @purefn(i32 %a1)
  br label %done
done:
  %p = phi i32 [ %r, %rec ], [ 0, %entry ]
  ret i32 %p
}
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
