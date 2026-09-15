; control_phase_kickback_reject_cmp_inplace_xor_measured_parent.ll — DECLINE, and
; it is the fixture that RETIRES round-1 open question Q-3 (Track A.1, Rule-13
; ROUND-2 finding F-A1R2-2; probe `review_a1_r2_probes/f4f.c`).
;
; Q-3 asked whether `railWireNamesBackward`'s crossing of `taint.InPlaceRailOps`
; is untested insurance that should be deleted — FIX_A1_R1 §F-A1-3 could not build
; a program that reaches it, because every spelling it tried was pre-empted ONE
; STAGE EARLIER by `LoopLowering::staleRailRecordRead`. THE ANSWER IS "KEEP IT":
; there is a reachable DECLINE face, from single-TU plain `clang -O1` C.
;
;     int slice(int u) {
;       int q = cq_theta(u, 0.5);  int acc = 0;
;       for (int i = 0; i < 3; ++i) {
;         acc += cq_measure(q);          /* the register COLLAPSES */
;         q = q ^ 9;                     /* IN PLACE: same rail, NEW SSA name */
;         if (q > 5) cq_phi(0.3);        /* the flag is minted from the POST-xor
;                                           name, off a COLLAPSED register */
;       }
;       return acc;
;     }
;
; WHAT THE ORACLE EMITS (`main` 0c7380c, rc 0) — bd `r903` item (b) verbatim,
; through the in-place relabelling:
;     %m     = cqrt_measure_i32(%h)                        ; COLLAPSE
;     cqrt_xorc_i32(%h, 9)                                 ; IN PLACE on %h
;     %h_cmp = cq_template_icmp_sgt_i32_hl(%h, 5)          ; flag off the collapse
;     cqrt_rz_i1(%h_cmp, 0.3), !cq.branchphase
;
; WHY ONLY THE CROSSING CATCHES IT. The compare's DIRECT operand is the POST-`xor`
; SSA name; the `cq_measure` names the PRE-`xor` header phi. Without the
; `InPlaceRailOps` crossing, `railWireNamesBackward(post)` yields the singleton
; `{post}`, which has no `cq_measure` user, and rung (ii) accepts. The crossing is
; the SOLE reason this declines.
;
; WHY THE ROUND-1 PROBES MISSED IT — worth recording, because it is a `-O1` fact
; and not an oversight of imagination: `ip1`/`ip3` used `add`, and `clang -O1`
; rewrites `(q+1) > 5` SIDEWAYS onto the pre-`add` value (`icmp sgt i32 %7, 4`),
; so the measured register lands DIRECTLY in the compare and the crossing is never
; needed. `xor` does not distribute over the compare, so the post-op name
; survives. Same asymmetry straight-line: `q ^ 9` keeps the derived name, `q + 7`
; does not.
;
; ACCEPT CONTROL: `control_phase_kickback_cmp_inplace_xor_other_register.ll`
; (probe `f4h.c`) — the identical loop with a DIFFERENT register measured, GREEN
; on all three binaries. RED-GREEN: the ORACLE returns rc 0 on this module.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %body

exit:                                             ; preds = %latch
  ret i32 %acc.next

body:                                             ; preds = %entry, %latch
  %i    = phi i32 [ 0, %entry ], [ %i.next, %latch ]
  %acc  = phi i32 [ 0, %entry ], [ %acc.next, %latch ]
  %cur  = phi i32 [ %q, %entry ], [ %post, %latch ]
  %m    = call i32 @cq_measure_si32(i32 %cur)
  %acc.next = add nsw i32 %m, %acc
  %post = xor i32 %m, 9
  %c    = icmp sgt i32 %post, 5
  br i1 %c, label %arm, label %latch

arm:                                              ; preds = %body
  call void @cq_phi(double 3.000000e-01)
  br label %latch

latch:                                            ; preds = %body, %arm
  %i.next = add nuw nsw i32 %i, 1
  %done   = icmp eq i32 %i.next, 3
  br i1 %done, label %exit, label %body, !llvm.loop !0
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.mustprogress"}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
