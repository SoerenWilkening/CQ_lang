; control_predmux_reject_rail_phi_cond.ll — DECLINE (bd test_C_libtooling-fn1q
; increment 2). THE RAIL PHI IS THE **NEXT** INCREMENT, AND THIS FILE IS THE
; RECORD THAT IT WAS LEFT OUT ON PURPOSE.
;
; The condition is a 2-incoming `i1` phi — a preceding controlled state-prep
; region's merge phi, which after `RailBankPromote` is exactly what the owner's
; `bool b0[n]` array becomes (`%cq.bank1 = phi i1 [ %31, %30 ], [ false, %23 ]`).
; `isCondRailPhiShape` (SelectClassify.h) recognizes the SHAPE, and this increment
; deliberately does NOT call it at E6.
;
; ⚠ WHY NOT, and it is not timidity. `isCondRailPhiShape` is WEAK BY DESIGN — any
; 2-incoming `i1` phi passes it — and its consumers do not rely on it alone: the
; 4.4 select path gates it behind `AllowRailPhi` and PROVES it by asking
; `preppedRailPhiRegionIdx` whether a claimed state-prep region actually owns that
; phi (bd 3qps / 4aiu, and Track M's `AllowRailPhi` ROOT-ONLY scoping before it).
; None of that machinery is asked here. Admitting the shape at E6 on the weak test
; alone would claim and flatten regions whose phi no region owns, and the decline
; would then land downstream instead of pre-claim — the bd 3c6m.67 self-operand
; lesson. Widening two axes at once is what `MergePhiPeel`'s P9 refuses in writing
; and the same refusal applies here.
;
; ⚠ RETIREMENT TRIGGER (L8) — AND THIS ONE IS DUE SOON, WHICH IS WHY IT IS WRITTEN
; PRECISELY. The rail-phi increment of bd `fn1q` lands exactly this shape. When it
; does, this file becomes an ACCEPT whose stream is
; control_predmux_accept_rail_leaf_cond.ll's with the rail read off the phi, and
; the fixture must be RE-DERIVED here, not deleted — a decline fixture that goes
; green because its subject no longer exists pins nothing (Rule 12 hygiene (c)).
;
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %c = icmp sgt i32 %u, 0
  br i1 %c, label %prep, label %join
prep:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %join
join:
  %rp = phi i1 [ %b, %prep ], [ false, %entry ]
  br i1 %b, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %join ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %join ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}

; CHECK: error:
; CHECK-SAME: cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy_i32_controlled
