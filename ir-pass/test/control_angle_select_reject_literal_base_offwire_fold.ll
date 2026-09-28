; control_angle_select_reject_literal_base_offwire_fold.ll — DECLINE (S3, a LITERAL
; untainted base; bd test_C_libtooling-drbq.13). THE COUNTER-EXAMPLE that keeps the
; literal base out of bd z0re's widening, which admits only a RUNTIME base.
;
;     int t = q / 4; int r;
;     if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .3);   // probe a1, from C
;     return cq_measure(r) + cq_measure(t);
;
; MEASURED at clang -O1 (this body is its stage-1 IR, minimised): IPSCCP pins `t`
; to 5 on the true edge and rewrites the true arm's `cq_theta(t, .9)` to
; `cq_theta(5, .9)`; SimplifyCFG then sinks the two now-arg-0-identical thetas into
; ONE theta reading an angle select; InstCombine rewrites the compare SIDEWAYS off
; `t` (`(q & -4) == 20`). `t = sdiv q, 4` is STILL LIVE and measured. The source
; rotated `t` IN PLACE on the `t == 5` branch; the module is an angle select on the
; LITERAL base 5. Admitting a literal base would prepare a FRESH |5⟩ and leave `t`
; unrotated — the F-R1-1 class of F2's header, OFF the condition's wire (the
; compare reads `and q, -4`, a sibling of `t`), so NOT the owner-ruled α trade.
;
; The DIAMOND prep refuses the identical hazard at F2 (probe `a8`: `int r = 5; if
; (t == 5) r = cq_theta(t, .9);` declines `state prep seed is proven equal to the
; condition register`). F2 is an EDGE analysis (`LazyValueInfo::
; getConstantRangeOnEdge`), a select has no edge, and LLVM 19 exposes LVI's
; condition analysis only through a branch edge or a select-OPERAND use — so the
; literal angle-select base stays declined, with the string it has always had,
; until an owner decision on how to ask F2 of a select condition (bd drbq.13).
;
; A RUNTIME base cannot be the image of this fold (IPSCCP substitutes only
; constants, and SimplifyCFG sinks a call only when at most ONE operand needs a φ,
; so arg-0 must already agree in both arms — probes a3/a4 keep the if/else unsunk),
; which is why `control_angle_select_ry_runtime_base.ll` ACCEPTS.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %m) {
entry:
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %a = and i32 %q, -4
  %c = icmp eq i32 %a, 20
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %r = call i32 @cq_theta_si32(i32 5, double %ang)
  %t = sdiv i32 %q, 4
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s = add nsw i32 %mt, %mr
  ret i32 %s
}
