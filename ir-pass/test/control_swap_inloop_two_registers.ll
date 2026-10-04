; control_swap_inloop_two_registers.ll — ACCEPT (bd test_C_libtooling-8h7d.5,
; Rule-13 round 1, finding OD1). TWO INDEPENDENT QUANTUM REGISTERS, each with its
; own tainted `if`, in ONE classically-bounded loop.
;
;     cq_theta(&a, .5);  cq_theta(&b, .25);
;     for (…) { if (a == 5) a = cq_phi(a, PI);
;               if (b == 3) b = cq_phi(b, PI);
;               cq_theta(&a, -.5);  cq_theta(&b, -.25);
;               cq_theta(&a,  .5);  cq_theta(&b,  .25); }
;     return cq_measure(a) + cq_measure(b);
;
; `clang -O1` verbatim (two loop-carried register phis in one header, two
; sequential diamonds, the arms value-propagated to `cq_phi(5, …)` / `cq_phi(3,
; …)`). It DECLINED at ba35c1f — "condition predates a non-diagonal gate under
; quantum control" — because `WireWalk::phiTracksWire` asked whether ANY
; `cq_theta` sat between an incoming and its edge, so each register's rotations
; refused the OTHER register's barrier and neither could ever be claimed. Nothing
; about that decline was about either register's own wire; the shape was simply
; unreachable.
;
; THE FIXTURE PINS BOTH HALVES OF THE GROUPING RULE, and they pull in opposite
; directions, which is why it is worth a file:
;   * the STALENESS test is per WIRE — `%b`'s Ry may not stale `%a`'s record
;     (finding OD1), else this program never lowers;
;   * the RECORD-LIVENESS fence groups rail chains by their ROOT MINT — two
;     chains rooted at ONE mint are one physical register and MUST interfere
;     (lowering_reject_inloop_rail_alias_shared_mint.ll, which is red for exactly
;     that reason). Two mints, two registers, no interference. Coarsen the fence
;     to one group per loop and this file goes red; drop the root grouping and its
;     twin goes green with a miscompile.
;
; The emitted stream is the two per-register streams in SOURCE order on two
; handles, and gates on distinct wires commute, so the rolled body is the same
; circuit the hand-unrolled form would emit.
;
; SINCE bd test_C_libtooling-drbq Increment 2a the flat phase arm lowers
; CONTROL-IN-PLACE (§6a): the arm's `Rz` is ONE
; `cqrt_rz_i32_controlled(flag, register, theta)` and the swap route (work-rail
; alloc, both `cqrt_cswap`s, the rail free) is gone. Nothing else moves — the flag
; mint, the strip, the flag free and every downstream gate are unchanged.
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
;   * !cq.branchphase
;
; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,
; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:
; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass
; emitted here.  Read it as history; the stream this file now ASSERTS is
; the derived one below, and the two are meant to differ.
;
; 30 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  br label %7

3:                                                ; preds = %19
  %4 = tail call i32 @cq_measure_si32(i32 noundef %23)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %24)
  %6 = add nsw i32 %5, %4
  ret i32 %6

7:                                                ; preds = %0, %19
  %8 = phi i32 [ 0, %0 ], [ %25, %19 ]
  %9 = phi i32 [ %2, %0 ], [ %24, %19 ]
  %10 = phi i32 [ %1, %0 ], [ %23, %19 ]
  %11 = icmp eq i32 %10, 5
  br i1 %11, label %12, label %14

12:                                               ; preds = %7
  call void @cq_phi(double 0x400921FB54442D18)
  br label %14

14:                                               ; preds = %12, %7
  %16 = icmp eq i32 %9, 3
  br i1 %16, label %17, label %19

17:                                               ; preds = %14
  call void @cq_phi(double 0x400921FB54442D18)
  br label %19

19:                                               ; preds = %17, %14
  %21 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef -5.000000e-01)
  %22 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef -2.500000e-01)
  %23 = tail call i32 @cq_theta_si32(i32 noundef %21, double noundef 5.000000e-01)
  %24 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef 2.500000e-01)
  %25 = add nuw nsw i32 %8, 1
  %26 = icmp eq i32 %8, 0
  br i1 %26, label %7, label %3, !llvm.loop !6
}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output
; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at
; its DEFINITION and referenced afterwards, so the chain asserts operand
; IDENTITY — the strip and the free name the SAME flag the mint produced
; (bd 8txa: the golden itself must witness the pairing).  Handle names are
; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass
; never emits).  Trailing `!cq.branchphase` metadata is stripped here because
; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.
; CHECK: define i32 @slice() {
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 2.500000e-01)
; CHECK-NEXT: br label %3
; CHECK: 1:                                                ; preds = %3
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M3]], %[[M]]
; CHECK-NEXT: ret i32 %[[V2]]
; CHECK: 3:                                                ; preds = %3, %0
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = phi i32 [ 0, %0 ], [ %5, %3 ]
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H2]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H2]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 2.500000e-01)
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = add nuw nsw i32 %[[V4]], 1
; CHECK-NEXT: %[[V6:[a-zA-Z0-9_.]+]] = icmp eq i32 %[[V4]], 0
; CHECK-NEXT: br i1 %[[V6]], label %3, label %1
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
; NOROUTE-NOT: condition predates a non-diagonal gate
; NOROUTE-NOT: rail record read past an in-place gate
; NOROUTE-NOT: call void @cqrt_cswap

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
