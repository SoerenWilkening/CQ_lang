; control_phase_nest_reject_cmp_round2_sibling_theta.ll — DECLINE (Track A.1, bd
; test_C_libtooling-9pum): the ROUND-2 TAINT WINDOW at the 4.3 DEPTH-2 NEST, with
; a COMPARE leaf on the INNER level. The compare twin of
; `control_phase_nest_reject_rail_round2_inner_sibling_theta.ll`.
;
; The inner condition `b > 0` reads a register that a round-2 rail merge puts
; under `b3`'s rotation too, so the conjunction toffoli's control is minted from
; the post-`.9` register. ACCEPT on `main` 0c7380c (exit 0, verify-clean). The
; nest reaches the record through the SAME `lowerCompareToFlag` call
; `CondTreeEmit`'s leaf mint makes for every other tree consumer — which is why
; no per-emitter recording call was needed here (the `markRailCondRead` lesson:
; the rail record's FIRST spelling missed exactly this emitter).

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %p = call i32 @cq_theta_si32(i32 %u, double 2.000000e-01)
  br label %second

second:
  %b = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %b3 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %c1 = icmp sgt i32 %p, 1
  br i1 %c1, label %outer, label %done

outer:
  %c2 = icmp sgt i32 %b, 0
  br i1 %c2, label %inner, label %done

inner:
  call void @cq_phi(double 7.000000e-01)
  br label %done

done:
  %mm = call i32 @cq_measure_si32(i32 %b3)
  ret i32 %mm
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
