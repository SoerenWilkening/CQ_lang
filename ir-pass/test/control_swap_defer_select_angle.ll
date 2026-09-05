; control_swap_defer_select_angle.ll — ***THIS FIXTURE NOW ACCEPTS.*** It pinned
; the 4.4 WI-1 angle-select DEFER (`rotation angle under quantum control`) for
; over a year; bd `test_C_libtooling-drbq` Increment 2b implements the lowering,
; so the shape it describes LOWERS. The file keeps its name for git continuity
; and because several documents cite it by name — read the name as historical.
;
; THE SHAPE, unchanged from the original fixture:
;     q = rz(q, 0.9); if (q > 5) { rz(q, a); } else { rz(q, b); }
; `clang -O1` SimplifyCFG folds that to ONE hoisted `cq_phi` whose ANGLE is a
; tainted-condition select (`select i1 %c, double a, double b`) — the branch CFG
; is gone before the pass runs (Rule 9). The original header called this "a
; rotation angle under quantum control, NOT a data mux", and that half is still
; exactly right: it is a rotation angle, the select is never lowered as a data
; merge, and no angle-position taint ever reaches a handle.
;
; WHAT CHANGED IS THE DISPOSITION, NOT THE CLASSIFICATION. The angle select is
; lowered BY DIFFERENCE (control-in-place-PRD §12.3):
;     rz(q, b)                            ; unconditional, the FALSE-arm angle
;     f = icmp_sgt_i32_hl(q, 5)           ; the ordinary flag mint
;     rz_controlled(f, q, a - b)          ; the drbq Inc-2a in-place gate
;     icmp_sgt_i32_hl_unc(f, q, 5)        ; the ordinary strip
;     free(f)
; Exact IN REAL ARITHMETIC by angle additivity on one axis: under
; `Rz = diag(1, e^{i.theta})` the two diagonals multiply entrywise, so
; `Rz(b).Rz(a-b) = Rz(a)` with no global-phase residue. In IEEE double the
; realized true-arm angle is `b + fl(a-b)`, error `|delta| <= 1/2 ulp(a-b)` — AND
; FOR THIS FIXTURE THAT ERROR IS EXACTLY ZERO: the arms are the CONSTANTS 0.25 and
; 0.75, a Sterbenz pair, so `fl(0.25 - 0.75) = -0.5` is exact, and the
; constant-arm fence (S1 clauses 2a/2b/3, round-1 Rule-13 review lens L7-F1)
; applies to this file and passes.
;
; *** ROUND-2 CORRECTION (lens R2 N5 = lens R1 item 4b). *** The round-1 edit put
; the RUNTIME-ARM sentence here — "the arms here are RUNTIME `double` arguments,
; so no compile-time fence is possible and the bound is what stands" — which is
; false of this fixture (its arms are constants, two lines below in the body) and
; contradicted its own next sentence. The runtime-arm caveat then lived on the two
; files that actually had runtime arms, `control_swap_reject_switch_datamux_angle.ll`
; and `control_angle_select_ry_arg_angles.ll`, and stated BOTH halves of the
; residual rather than only "the bound".
;
; *** CLEARANCE CORRECTION (Rule-13 clearance review, finding F-11 / blocker B1;
; *** orchestrator decision: owner option (2)). RUN-TIME ARMS NOW DECLINE — the
; *** accept class is CONSTANT arms only, so this fixture's Sterbenz constants are
; *** no longer merely "fenced and passing", they are the whole admitted class.
; *** The two files named above changed with it: the datamux one was given the
; *** constants 0.9/0.3 and `control_angle_select_ry_arg_angles.ll` was REPLACED by
; *** `control_angle_select_reject_runtime_arms.ll`, which carries the full
; *** argument. Nothing about THIS fixture's stream, arms or assertions moved.
;
; NOTHING QUANTUM ENTERS THE ANGLE SLOT — every angle emitted is a classical
; constant (here `0.75`, `0.9` and the folded difference `-0.5`), which is what
; the f64/angle prohibition (Rule 3) actually forbids.
;
; NOTE the rotated register IS the condition register (`%qd` and `%q` are one
; rail after the RAUW). That is legal for the `cq_phi` stem and ONLY for it —
; PRD §3c: a diagonal gate moves no computational-basis label, so the strip still
; recomputes the predicate the mint read. The `cq_theta` twin of this shape
; declines; see `control_angle_select_rz_cond_register.ll` and
; `control_angle_select_reject_cond_register.ll`, which are that pair stated
; minimally.
;
; ORACLE DISPOSITION: RED on the pre-2b binary (it declines `rotation angle`),
; GREEN here — Rule 12 red-green, and the reason this file is a rewrite rather
; than an edit.
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
;   * call void @cqrt_rz_
;   * call void @cqrt_ry_
;   * select
;   * call void @cqrt_x   [superseded by the XCNT count]
;   * call i32 @cqrt_alloc_i32(
;   * call void @cqrt_free(   [superseded by the FCNT count]
;
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 27 line(s) of prose that annotated the OLD CHECK block were removed with
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

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %ang = select i1 %c, double 2.500000e-01, double 7.500000e-01
  call void @cq_phi(double %ang)
  %m   = call i32 @cq_measure_si32(i32 %q)
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
; CHECK: define i32 @example(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 7.500000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M1]]
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
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; Original negatives PRESERVED (re-measured on the Inc-1 output):
; NOROUTE-NOT: call void @cqrt_copy
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: cqrt_ry_i32_controlled
; NOROUTE-NOT: double -7.500000e-01
; NOROUTE-NOT: double -9.000000e-01

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
