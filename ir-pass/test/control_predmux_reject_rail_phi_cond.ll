; control_predmux_reject_rail_phi_cond.ll — DECLINE. ⚠ ITS RETIREMENT TRIGGER HAS
; FIRED (bd fn1q increment 5a), AND THE TRIGGER WAS RIGHT.
;
; This file was written at increment 2 to record that the rail φ was left out of E6
; ON PURPOSE. Its corrected trigger said: a rail φ whose prep sits under a TAINTED
; condition will ACCEPT when the rail-φ increment lands, while THIS module — prep
; under a CLASSICAL condition — will STILL DECLINE, because the downstream proves a
; rail φ through `preppedRailPhiRegionIdx`, which needs a CLAIMED state-prep region,
; and a classical-condition prep is not a region at all.
;
; MEASURED at increment 5a on the landed binary: exactly that. The tainted-prep
; sibling is now `control_predmux_accept_rail_phi_cond.ll`; this module declines
; with the SAME string it declined with before. ⚠ L8 works — a retirement trigger
; written with its measurement was character-for-character correct about a binary
; that did not exist yet. Write them.
;
; ⚠ WHAT CHANGED UNDER THIS FILE, AND IT IS A REAL COST, NOT A NO-OP. E6 now ADMITS
; this shape (`isStructuralRailPhi`: every incoming is a rail call or an `i1`
; constant — the strongest thing provable before `detectControlRegions` exists).
; So the region is CLAIMED AND FLATTENED and the decline lands DOWNSTREAM, at the
; 4.4 select, instead of pre-claim at E6. The VERDICT is unchanged — a decline
; cannot become silence — but DETECT-BEFORE-MUTATE is lost for this one shape.
;
; ⚠ THE **STRING** IS NOT GUARANTEED, and an earlier draft of this header said it
; was (Rule-13 round 1 F2). Measured: put a SECOND independent tainted region in
; the same function and the decline moves from `nested control flow under quantum
; control` to `control flow under quantum control`, because the flatten mutates the
; first region and the decline lands with a different owner. THIS module's string
; is unchanged; the class's is not. That is the cost bd `cfmv`'s
; Rule-13 round 2 filed as R4R2-1, and it is taken KNOWINGLY here.
;
; ⚠ AND IT IS TAKEN BECAUSE THIS DECLINE IS NOT A PHYSICS DECLINE. Owner ruling:
; a construct with no physics reason to decline must compile. `%c` here is
; CLASSICAL, so this program is a classical branch choosing between two circuits —
; rail-controlled on one path, constants on the other. There is no superposed
; condition, no no-cloning problem and no dirty rail; it is realizable. Making it
; compile is bd fn1q increment 5b, and the shape of that work is already visible:
; promote the constant incoming to a `|0>` rail handle so the φ becomes a HANDLE
; mux under a classical condition — the `RailBankPromote` idiom bd `zujr` already
; uses for the loop-carried case, where a `|0>` control correctly means "this arm
; never fires".
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
