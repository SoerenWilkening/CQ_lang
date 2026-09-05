; control_swap_accept_post_region_theta.ll — ACCEPT (bd test_C_libtooling-lom0
; Increment 4): a chained `cq_theta` that runs strictly AFTER a phase region's
; whole emitted stream no longer declines it.
;
; THE CUSTOMER, and it is one line of C: state preparation is S = `Ry(0.5)`
; THEN `+ off`, so re-preparing after the reflection about |0> means
;     ... R0; a = cq_theta(a, 0.5); a += off;
; and until this increment that spelling declined with
;     cq controlled lowering: condition predates a non-diagonal gate
; because `wireGainsNonDiagonalGate` was schedule-INDEPENDENT: ANY theta
; anywhere on the condition's wire declined the region, including one that runs
; after the flag was minted, routed, Rz'd, routed back, `_unc`-stripped and
; freed. It was the single wall between CQ and a full Grover iteration, and it
; was NOT workaroundable from source — reordering S to `+off` then `Ry` gets
; past the guard but computes a DIFFERENT unitary (Ry does not commute with the
; `+3` permutation), which is the one thing this compiler exists to prevent.
;
; THE SOURCE THIS IR IS `clang -O1` OF (example/grover/grover_iteration.c):
;     volatile int cq_off = 3;
;     int a = 0;
;     a = cq_theta(a, 0.5);   a += cq_off;          /* S  */
;     if (a == 5) a = cq_phi(a, PI);                /* O  */
;     a -= cq_off; a = cq_theta(a, -0.5);           /* S† */
;     if (a == 0) a = cq_phi(a, PI);                /* R0 */
;     a = cq_theta(a, 0.5);   a += cq_off;          /* S  — THE FRONTIER LINE */
;     return cq_measure(a);
; The `volatile` offset is load-bearing (Rule 9): a literal `+3/-3` pair is
; reassociated by -O1, cancelled on the straight-through edge and SUNK into the
; oracle arm, which then declines `arm rewrites a condition operand`.
;
; WHICH REGION THE ACCEPT IS ABOUT. Region 1 (the oracle) never saw a wire gate
; at all — MEASURED, not assumed: replace its arm gate with a value op and it
; declines `arm rewrites a condition operand`, the value-arm string, rather than
; the deferred wire-gate one. Its condition reads `%3 = add %2, %1`; the walk
; crosses the merge phi `%8` but an ordinary `sub`/`add` result is a distinct SSA
; value it does not cross, so `%10 = sub %8, %9` ends the wire and the S-dagger
; theta `%11` behind it is never reached.
; Region 2 (the reflection) is the one that declined: its condition reads the
; CHAINED theta `%11`, whose forward wire runs through the merge phi `%16` into
; `%17 = cq_theta(%16, 0.5)` — the re-prep Ry. `%17` is in block `%15`, which
; `%7`'s terminator dominates, and nothing reaches back from `%15` to `%7`, so
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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
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

; ONE register for the whole program (M-C in-place reassignment).
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[0-9]+}})
;
; region 1 — the oracle, on %[[H]].
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
;
; S-dagger, IN PLACE on the same register.
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %cq_negimm)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
;
; region 2 — the reflection about |0>. THIS is the region the Inc-4 accept is
; about; its condition's wire gains the re-prep Ry below.
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 0)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[H]], double 0x400921FB54442D18)
;
; THE ORDERING THIS FIXTURE EXISTS FOR: strip THEN free THEN the re-prep Ry.
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 %{{[0-9]+}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
;
; Both diamonds flattened; no residual quantum control.
; CHECK-NOT: phi
; CHECK-NOT: br i1
;
; Exactly ONE allocation — the wire. Since drbq Inc 2a a phase region mints no
; work rail at all (the two per-region ancillas went with the route), so the whole
; program is one data register, and nothing is left entangled with the wire when
; the re-prep Ry fires.
; CNT-COUNT-1: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(

; No swap route survives on either region — window is `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
