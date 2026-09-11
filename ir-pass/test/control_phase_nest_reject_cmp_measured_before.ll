; control_phase_nest_reject_cmp_measured_before.ll — DECLINE (Track A.1, bd
; test_C_libtooling-r903 item (b)): the 4.3 DEPTH-2 NEST's inner condition
; register is measured before the region.
;
;     int p = cq_theta(u, .2);
;     int b = cq_theta(3, .5);
;     int m = cq_measure(b);              // collapses the INNER condition register
;     if (p > 1) { if (b > 0) cq_phi(.7); }
;
; ACCEPT on `main` 0c7380c (rc 0), DECLINE here.
;
; IT IS THE PIN FOR THE BACKSTOP, and the only fixture in this increment that is.
; `classifyPhaseKickbackNest` has NO compare rung-(ii) clause of its own — the
; two classifier clauses this increment adds are at `classifySelectRegion` and
; `classifyPhaseKickback` — so this program is refused by
; `reverifyCmpCondReads` alone, over the record `lowerCompareToFlag` writes at
; `CondTreeEmit`'s leaf mint. Delete the recording (or make it opt-IN and forget
; a caller) and this goes green while the module emits a conjunction toffoli
; controlled on a collapsed register.
;
; That is exactly why the write half lives inside the shared mint rather than at
; the ten emitters: the rail record's FIRST spelling put `markRailCondRead` at
; four emitter sites and MISSED this very one — the nest's conjunction toffoli,
; which for an inner rail is that rail's only read (bd r9e5, FIX_B1_R2.md).

; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u) {
entry:
  %p = call i32 @cq_theta_si32(i32 %u, double 2.000000e-01)
  %b = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %b)
  %c1 = icmp sgt i32 %p, 1
  br i1 %c1, label %outer, label %done

outer:
  %c2 = icmp sgt i32 %b, 0
  br i1 %c2, label %inner, label %done

inner:
  call void @cq_phi(double 7.000000e-01)
  br label %done

done:
  ret i32 %m
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
