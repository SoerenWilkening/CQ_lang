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
; ⚠ RETIREMENT TRIGGER (L8) — AND THE FIRST VERSION OF IT WAS WRONG, WHICH IS WHY
; IT IS NOW WRITTEN WITH ITS MEASUREMENT. It said: "the rail-phi increment lands
; exactly this shape; when it does, this file becomes an ACCEPT." **FALSE.**
; Measured on an E6-bypassed build: a rail phi whose prep sits under a TAINTED
; condition ACCEPTS, while THIS module — whose prep sits under a CLASSICAL
; condition — STILL DECLINES, because the downstream 4.4 select path proves a rail
; phi through `preppedRailPhiRegionIdx`, which needs a CLAIMED state-prep region to
; own it, and a prep under a classical condition is not a region at all.
;
; So this file pins TWO independent refusals, and the rail-phi increment retires
; only the first. Its correct trigger is: when E6 admits `isCondRailPhiShape`,
; RE-MEASURE this module — it is expected to keep declining, and if it starts
; ACCEPTING then something has ALSO widened the prep-region proof and that is a
; separate thing to go and read. The shape increment 3 actually has to take is the
; TAINTED-prep spelling, kept beside this session's probes as
; `probes/inc2/railphi_tainted_prep.ll`.
;
; Either way: RE-DERIVE, DO NOT DELETE — a decline fixture that goes green because
; its subject no longer exists pins nothing (Rule 12 hygiene (c)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
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
  br i1 %rp, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %join ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %join ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %mb = call i1 @cq_measure_i1(i1 %rp)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}

; CHECK: error:
; CHECK-SAME: cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy_i32_controlled
