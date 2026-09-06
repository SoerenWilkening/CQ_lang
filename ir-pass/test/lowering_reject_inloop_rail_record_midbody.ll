; lowering_reject_inloop_rail_record_midbody.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 round 1, finding F1). The IN-BODY half of the
; rail-record fence, and the reason the fence is POSITIONAL rather than a blanket
; "no rail member escapes the loop".
;
;     for (...) { if (q == 5) q = cq_phi(q, b); q += 3; acc = q_before_the_add * 7; }
;
; Nothing leaves the loop here — `%acc` is minted and consumed inside one
; iteration, which is the sound Case-B pattern and must NOT be over-declined in
; general (control_swap_inloop_rail_record_live.ll is exactly that shape and
; ACCEPTS). What is wrong is the POSITION: `%qm` names the pre-`addc` register and
; the `mul` reads the wire AFTER the `cqrt_addc_i32` relabelled it, so the emitted
; template computes `(q+3)*7` where the source says `q*7`.
;
; A blanket in-loop/out-of-loop test cannot see this, and a blanket escape test
; would refuse `slice_control_grover_loop`'s own `cq_measure(q)`. The fence asks
; the only question that separates them: does a rail-relabelling gate execute
; between the record's definition and the read, without the definition
; re-executing in between?
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cq_template_mul_i32_hl
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = add i32 %q, 3                                 ; in-place rail self-update
  %acc = mul i32 %q, 7                                ; STALE — reads the pre-add record
  %mm = call i32 @cq_measure_si32(i32 %acc)            ; consumed in-body
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m1 = call i32 @cq_measure_si32(i32 %qn)
  ret i32 %m1
}
