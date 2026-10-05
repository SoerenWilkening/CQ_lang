; control_swap_accept_post_region_theta.ll — ACCEPT (bd test_C_libtooling-lom0
; Increment 4): a chained `cq_theta` that runs strictly AFTER a phase region's
; whole emitted stream no longer declines it.
;
; THE CUSTOMER, and it is one line of C: state preparation is S = `Ry(0.5)`
; THEN `+ off`, so re-preparing after the reflection about |0> means
;     ... R0; cq_theta(&a, 0.5); a += off;
; and until this increment that spelling declined with
;     cq controlled lowering: condition predates a non-diagonal gate
; because `wireGainsNonDiagonalGate` was schedule-INDEPENDENT: ANY theta
; anywhere on the condition's wire declined the region, including one that runs
; after the flag was minted, used, `_unc`-stripped and freed. It was the single
; wall between CQ and a full Grover iteration, and it was NOT workaroundable
; from source — reordering S to `+off` then `Ry` gets
; past the guard but computes a DIFFERENT unitary (Ry does not commute with the
; `+3` permutation), which is the one thing this compiler exists to prevent.
;
; THE SOURCE THIS IR IS `clang -O1` OF (example/grover/grover_iteration.c):
;     volatile int cq_off = 3;
;     int a = 0;
;     cq_theta(&a, 0.5);   a += cq_off;          /* S  */
;     if (a == 5) cq_phi(PI);                       /* O  */
;     a -= cq_off; cq_theta(&a, -0.5);           /* S† */
;     if (a == 0) cq_phi(PI);                       /* R0 */
;     cq_theta(&a, 0.5);   a += cq_off;          /* S  — THE FRONTIER LINE */
;     return cq_measure(a);
; The `volatile` offset is load-bearing (Rule 9): a literal `+3/-3` pair is
; reassociated by -O1, cancelled on the straight-through edge and SUNK into the
; oracle arm, which then declines `arm rewrites a condition operand`.
;
; WHICH REGION THE ACCEPT IS ABOUT. Region 1 (the oracle) never saw a wire gate
; at all — MEASURED, not assumed: replace its arm gate with a value op and it
; declines `arm rewrites a condition operand`, the value-arm string, rather than
; the deferred wire-gate one. Its condition reads `%3 = add %2, %1`; an ordinary
; `sub`/`add` result is a distinct SSA value the walk does not cross, so
; `%10 = sub %3, %9` ends the wire and the S-dagger theta `%11` is never reached.
; Region 2 (the reflection) is the one that declined: its condition reads the
; CHAINED theta `%11`, whose forward wire runs into `%17 = cq_theta(%11, 0.5)`
; — the re-prep Ry. `%17` is in block `%15`, which `%7`'s terminator
; dominates, and nothing reaches back from `%15` to `%7`, so
; `provablyBefore(BI, %17)` holds and the region is accepted as a PHASE arm.
;
; WHAT THE CHECKS BELOW ASSERT, and it is the whole soundness claim: region 2's
; flag is minted, used, STRIPPED and FREED before the re-prep `cqrt_ry_i32`
; fires, and the `cqrt_addc_i32` that completes S comes after it. If a future
; change let the Ry slide before the strip, the `_unc` would read a post-Ry
; basis and the flag would not return to |0> — a verify-clean wrong unitary that
; only this ordering catches.
;
; AND NOTE THE RAIL, because the obvious argument for this accept is FALSE.
; Since M-C (bd 6uqc Inc 2) every `q += off` / `q -= off` lowers IN PLACE to
; `cqrt_addc_i32`, so the ENTIRE program runs on one physical register `%h`: the
; re-prep Ry acts on the very rail region 2's condition read. The proof is over
; IR POSITIONS (dominance + non-reachability), never over rail identity — "a
; different SSA value means a different rail" has not been true here since 2b.
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
; 30 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

@cq_off = global i32 3, align 4

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %2 = load volatile i32, ptr @cq_off, align 4
  %3 = add nsw i32 %2, %1
  %4 = icmp eq i32 %3, 5
  br i1 %4, label %5, label %7

5:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %7

7:
  %9 = load volatile i32, ptr @cq_off, align 4
  %10 = sub nsw i32 %3, %9
  %11 = call i32 @cq_theta_si32(i32 %10, double -5.000000e-01)
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %15

13:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %15

15:
  %17 = call i32 @cq_theta_si32(i32 %11, double 5.000000e-01)
  %18 = load volatile i32, ptr @cq_off, align 4
  %19 = add nsw i32 %18, %17
  %20 = call i32 @cq_measure_si32(i32 %19)
  ret i32 %20
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
; CHECK: define i32 @main() {
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[V1:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V1]])
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_off, align 4
; CHECK-NEXT: %[[CQ_NEGIMM:[a-zA-Z0-9_.]+]] = sub i32 0, %[[V2]]
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[CQ_NEGIMM]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = load volatile i32, ptr @cq_off, align 4
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 %[[V3]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
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
; NOROUTE-NOT: {{= phi }}
;   ^ NO `phi` INSTRUCTION survives: the region was flattened and its merge
;     phi dissolved. ⚠ THE ANCHOR `= phi ` IS LOAD-BEARING, not style. This
;     line used to read `NOROUTE-NOT: phi`, which ALSO matched the substring
;     "phi" in the MODULE PATH that `cq-opt` prints in its `ModuleID` /
;     `source_filename` preamble — so the fixture passed or failed on where
;     the checkout happened to live, and reddened for everyone working in a
;     worktree named `*phi*` (measured: 7 fixtures, bd Track M 2026-09-13).
;     A negative that can match the harness's own preamble is not a negative
;     about the program. Keep every `-NOT` anchored to IR the pass emits.
; NOROUTE-NOT: br i1

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
