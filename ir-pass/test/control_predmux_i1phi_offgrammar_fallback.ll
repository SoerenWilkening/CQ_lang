; control_predmux_i1phi_offgrammar_fallback.ll — FALLBACK PIN (3c6m.14 L6
; Inc 2): an i1 phi with an OFF-GRAMMAR incoming (a `trunc`, not a compare/
; and-or tree) keeps the Inc-1 select-chain conversion, so the consuming
; select's condition is an i1 SELECT — off the 3c6m.12 flag-mint grammar —
; and declines loudly, byte-for-byte today's posture. The boolean-algebra
; path (control_predmux_accept_i1phi_cond.ll) must NOT widen to incomings it
; cannot prove are compare trees: a trunc'd bit has no flag-mint shape.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %sideb
inner:
  %c2 = icmp eq i32 %q, 7
  br i1 %c2, label %ia, label %ib
ia:
  %t  = trunc i32 %q to i1
  br label %ijoin
ib:
  %cb = icmp sgt i32 %q, 8
  br label %ijoin
ijoin:
  %flag = phi i1 [ %t, %ia ], [ %cb, %ib ]
  %v  = select i1 %flag, i32 3, i32 9
  %vv = add i32 %q, %v
  br label %merge
sideb:
  %u = mul i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %vv, %ijoin ], [ %u, %sideb ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK: control flow under quantum control
