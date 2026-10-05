; control_angle_select_forward_rail_cycle_frozen.ll — ACCEPT. A phase angle
; select in `entry`, then an empty classical counting loop on `%n`.
;
;     int r = u1; cq_theta(&r,.25);            // r never read again
;     cq_phi(q == 5 ? .9 : .3);
;
; WHAT IT PINS: the select lowers by kickback on the flag in `entry` (mint,
; `cqrt_x`-bracketed `cqrt_rz_i1(f, .3)`, `cqrt_rz_i1(f, .9)`, strip, free), the
; loop carries no gate, and the dead `r` is reverse-played and kept allocated
; (the bd 5c5b note in the CHECK block).
;
; ⚠ THE ORIGINAL SUBJECT IS GONE. The file was written (bd drbq Inc 2b, round-2
; Rule-13 review, lens R1 item 2) to pin a GAP: S7's prongs do not ask about the
; rotated register's rail FORWARD of the consumer, so a later gate on the SAME
; rail inside a loop (pre-3qlq register form `t = cq_phi(r, 0.9)`) lowered, and
; `ChainWalk::railCarriesControlledRotation` FROZE that rail (never
; reverse-played, never freed). The 3qlq migration deleted the in-loop gate (an
; uncontrolled phase) and the select no longer rotates `r`, so neither the gap
; nor the freeze is exercised here; "frozen" in the file name is history.
;
; ⚠ RE-SPELL BLOCKED (bd jttf, 2026-10-05). The register-free spelling of the
; subject rotates `r` with the 2b select and keeps an in-place gate on the same
; rail inside a classical cycle:
;
;     int q = u0; cq_theta(&q, .5);  int r = u1; cq_theta(&r, .25);
;     cq_theta(&r, q == 5 ? .9 : .3);              // the 2b gate on r
;     for (int i = 0; i <= n; i++) cq_theta(&r, .1); // FORWARD gate, in a cycle
;     return cq_measure(q) + cq_measure(r);
;
; Measured through `clang -O1` and `cq-opt` on 2ab46c39: it DECLINES `cq
; controlled lowering: control flow inside a loop body under quantum control`
; (also with `r` left unmeasured), while the same program with an UNCONTROLLED
; `cq_theta(&r, .3)` in place of the select lowers (Case A, the loop rolled on
; one handle). The loop's bound is classical, so this is an over-decline (R1),
; reported to the coordinator for a bd bug. The non-loop-carried spelling
; (`int g = r; cq_theta(&g, .1);` in the body) declines `rotation/measure operand
; predates a non-diagonal gate`, the stale-copy fence. So the S7 gap this file
; was written for is unreachable today, by declines. RE-SPELL TRIGGER: when the
; C above accepts, replace the IR with its `clang -O1` output and re-derive the
; CHECKs (the select's controlled Ry on `r`, then the rolled in-place Ry on the
; same rail inside the cycle, and no reverse-play and no free of that rail).
;
; ORACLE DISPOSITION: RED on the pre-2b binary (`rotation angle under quantum
; control`) — it declines every angle select.
;
; Reproducers from the round-2 review, lens R1
; (`review2b_r2/R1/probes/s7/{fwd,nat}_sel_{ry,rz}.ll`), re-derived without the
; scaffolding block in `fix2b_r2/probes/fwdcycle_{sel,twin,plain}.ll`.
;
;
; 3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED from this
; fixture's own output under the Inc-1 (register-free `void @cq_phi(double)`)
; binary.  The pre-Inc-1 pin — a `cqrt_rz_<W>` or `cqrt_rz_<W>_controlled` on
; the user's REGISTER — asserted the gate PRD §1 shows is the identity on the
; marked branch (`cqrt_rz_<W>` is TENSORED, so a routed W-bit Rz applies
; `(-1)^popcount(target)` and can never mark |0..0>).  The stream now pinned is
; the KICKBACK: the flag is minted into a |0> ancilla, the phase lands on the
; FLAG with an UNCONTROLLED `cqrt_rz_i1`, the ordinary compare `_unc` returns
; the flag to |0> on every branch, and the flag is freed.  The fixture's
; PURPOSE (its header above) is unchanged.
;
; ORIGINAL negatives REMOVED.  Each was MEASURED to fire on this fixture's
; own Inc-1 output, so keeping it would assert something false.  A `-NOT`
; that used to sit AFTER a positive of its prefix was WINDOWED to the text
; past that positive; re-measuring it whole-file is a strictly stronger
; question, and where the pattern is one of the counted ones the
; `-COUNT-n` + `-NOT` pair below pins `exactly n` — stronger than the
; window it replaces, not weaker.
;   * call void @cqrt_rz_i1(   [superseded by the ACNT count]
;   * call void @cqrt_free(   [superseded by the FCNT count]
;   * call void @cqrt_x(   [superseded by the XCNT count]
;   * !cq.branchphase
;
; 30 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  br label %L

L:
  %i = phi i32 [ 0, %entry ], [ %inext, %L ]
  ; pre-3qlq, the FORWARD gate on the SAME rail sat here; the migration deleted it
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %L

exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output
; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at
; its DEFINITION and referenced afterwards, so the chain asserts operand
; IDENTITY — the strip and the free name the SAME flag the mint produced
; (bd 8txa: the golden itself must witness the pairing).  Handle names are
; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass
; never emits).  Trailing `!cq.branchphase` metadata is stripped here because
; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.
; CHECK: define i32 @example(i32 %u0, i32 %u1, i32 %n) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H1]], double -2.500000e-01)
; bd 5c5b (libcqops vmz9): the dead `%r` root is reverse-played back to its
; runtime seed |u1>, not |0>, so it is kept allocated: no free follows its Ry-dagger.
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: br label %L
; CHECK: L:                                                ; preds = %L, %entry
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %entry ], [ %inext, %L ]
; CHECK-NEXT: %[[INEXT:[a-zA-Z0-9_.]+]] = add i32 %[[I]], 1
; CHECK-NEXT: %[[DONE:[a-zA-Z0-9_.]+]] = icmp sgt i32 %[[INEXT]], %n
; CHECK-NEXT: br i1 %[[DONE]], label %exit, label %L
; CHECK: exit:                                             ; preds = %L
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M2]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: cqrt_copy
;   ^ method-B copy on a phase arm dephases the answer (Rule 7)
; NOROUTE-NOT: _controlled
;   ^ the kickback gate is UNCONTROLLED, on the flag ancilla
; NOROUTE-NOT: call void @cqrt_rz_{{[a-z0-9]+}}_controlled(
;   ^ ⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the blanket one is DROPPED from any fixture that legitimately emits a controlled Ry or a controlled copy — and dropping it took the only catch for a controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate this increment removes — until this line was added. The width complement above cannot cover it either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(` has `_controlled` in between.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: double -3.000000e-01
; NOROUTE-NOT: double 0xBFD3333333333333
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
