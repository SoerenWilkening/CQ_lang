; control_predmux_accept_rail_phi_cond.ll — ACCEPT (bd fn1q increment 5a). THE
; RAIL PHI at PredMux's E6, and ⚠ THE LAST WALL IN FRONT OF THE OWNER'S OWN
; example/grover/grover_oracle_uncompute.c.
;
; THE SHAPE. `if (b0[i])` over a `_Bool` ARRAY. `promoteRailBankCells` runs at
; CQLoweringPass.cpp:196, long before PredMux at :374, so by the time E6 looks the
; bank cell is register-resident and the branch reads a φ:
;     %rp = phi i1 [ %b, %prep ], [ false, %entry ]
; one incoming a `cq_theta_i1` result, the other the constant `false`.
;
; ⚠ WHY `isStructuralRailPhi` AND NOT `isCondRailPhiShape`. The latter is ANY
; 2-incoming `i1` φ and is weak BY DESIGN — its other consumers finish the proof
; with `preppedRailPhiRegionIdx`, which asks whether a CLAIMED state-prep region
; owns the φ. E6 CANNOT ASK THAT: PredMux runs before `detectControlRegions`, so no
; plan exists. And the obvious fallback, "is the φ's defining branch TAINTED?", is
; REFUTED BY MEASUREMENT — the owner's own prep branch is untainted at that slot, so
; a taint test would refuse the program this bead exists for. What IS provable with
; no plan and no taint is that every incoming is a rail CALL or an `i1` CONSTANT.
;
; ⚠ NECESSARY, NOT SUFFICIENT, AND THE SIBLING PROVES IT: a prep under a CLASSICAL
; condition is admitted here and still refused downstream, with the SAME string
; (…_reject_rail_phi_cond.ll). That is bd fn1q increment 5b, not a wall — see that
; file's header for why it is a compiler-structure decline and not a physics one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; ⚠ EVERY GATE FAMILY IS COUNTED, AND THE LIST IS THIS LONG BECAUSE A MEASUREMENT
; SAID SO. Rule-13 round 1 (F3) ran the injection matrix against this file and
; found it **7 of 8 VACUOUS**: an injected `cqrt_measure` (Rule 5 — the compiler
; never inserts a measurement the user did not write), an injected `cqrt_free`
; (Rule 6), an injected `cqrt_x` and an injected `cqrt_ry` (Rule 7 — the rail must
; be read ONLY as a control) all passed, while the header asserted exactly those
; properties. Two count lines and a short negative list are not a pin.
;
; A NEGATIVE CANNOT CLOSE THESE: this shape legitimately emits `cqrt_x`,
; `cqrt_free`, `cqrt_measure` and `cqrt_cnot`. An EXACT COUNT can — `count N` fails
; on N+1 as loudly as on N-1.
; RUN: grep "call void @cqrt_ry_i1_controlled(" %t.cqd0.ll | count 1
; RUN: grep "@cqrt_ry" %t.cqd0.ll | count 5
; RUN: grep "call i32 @cqrt_alloc_i1(" %t.cqd0.ll | count 3
; RUN: grep "call i32 @cqrt_alloc_i32(" %t.cqd0.ll | count 7
; RUN: grep "call void @cqrt_free(" %t.cqd0.ll | count 3
; RUN: grep "@cqrt_measure" %t.cqd0.ll | count 6
; RUN: grep "call void @cqrt_x(" %t.cqd0.ll | count 4
; RUN: grep "call void @cqrt_cnot(" %t.cqd0.ll | count 4
; RUN: grep "call void @cqrt_copy_i32_controlled(" %t.cqd0.ll | count 4
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; ⚠ THE WHOLE-FAMILY `@cqrt_ry` COUNT IS THE RULE-7 PIN, and it is spelled that way
; after two corrections. A `count 0` on `cqrt_ry_i1` cannot be used at all — `grep`
; exits 1 with no match and lit fails the pipeline before `count` runs. And an
; `i1`-SPECIFIC count is not a pin either: the injection matrix MISSED an injected
; `cqrt_ry_i32` straight through it. The family count (5 = 1 declare + 1 controlled
; mint + 3 uses) moves for an injected rotation at ANY width, which is the Rule-7
; class §4i records a round catching one increment ago.
;
; The prep is a CONTROLLED Ry on a fresh rail — the shipped state-prep idiom.
; CHECK: cqrt_ry_i1_controlled
;
; NEG-NOT: cqrt_rz
; NEG-NOT: cqrt_cswap
; NEG-NOT: cqrt_qram

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
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
  %mq = call i32 @cq_measure_si32(i32 %q)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  %s3 = add i32 %s2, %mq
  ret i32 %s3
}
