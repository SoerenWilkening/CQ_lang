; lowering_icmp_qq_mixed_width_reject.ll — Phase 7.1 Increment A over-accept
; guard (the AGREEMENT-OR-DECLINE arm, reached on the QQ path).
;
; DIVISION OF LABOR across the two QQ over-accept arms (reconciled 2026-06-20):
;   * the ABSENT-width arm (`WA.empty()`) is pinned by a CONSTRUCTABLE decline in
;     `lowering_icmp_qq_no_width_reject.ll` (two tainted i1-flag operands carry no
;     recorded width → loud `no template for opcode 'icmp i1'` from the compare).
;   * the DISAGREEMENT arm (`WA != WB`, both non-empty) is UNCONSTRUCTABLE from any
;     valid input .ll: every tainted value records `HandleWidth ==
;     abiWidthFromType(its own SSA result type)` (theta from the operand type,
;     arith from the result type, cast from the DEST type), and an `icmp`/`fcmp`
;     forces both operands to share ONE SSA type — so two BOTH-PRESENT recovered
;     widths ALWAYS agree on clean IR. The disagreement arm is correct
;     defense-in-depth against a stale/corrupted side-table, not an input-
;     reachable path, so it cannot carry its own decline fixture.
;
; This fixture therefore guards the CONSTRUCTABLE over-accept that is reachable
; ON the SAME QQ branch once width agreement HAS passed: two same-width (f64)
; thetas WITH AGREEMENT (`QqWidth`="f64" → QQ branch entered), but an OUT-OF-SCOPE
; fcmp predicate (`ord`). The QQ-branch `compareInScope` predicate gate then
; declines LOUDLY — proving the QQ path mints NO `cq_template_fcmp_ord_f64` for an
; unsupported predicate (a verify-clean link-fail otherwise). LOAD-BEARING for the
; predicate gate: removing `compareInScope` would `getOrInsertFunction` the
; non-existent `cq_template_fcmp_ord_f64` symbol and emit it, flipping the
; `CHECK-NOT: cq_template_fcmp` below. The diagnostic is `fcmp i1` (the compare's
; i1 result type), pinning that it is the COMPARE — not an upstream producer —
; that declines. (Note: this fixture does not by itself distinguish the QQ-path
; predicate decline from the empty-width QQ bail — both print `fcmp i1`; the
; ABSENT-width arm is pinned separately by `lowering_icmp_qq_no_width_reject.ll`.)
; The loud diagnostic makes `cq-opt` exit non-zero, so `not` is required.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; The decline must come from the `fcmp i1` compare AFTER the QQ branch was entered
; (width agreement passed), pinning the on-QQ-path predicate gate.
; CHECK: error{{.*}}no template for opcode 'fcmp i1'{{.*}}
;
; No compare template may be minted for the out-of-scope predicate on the QQ
; path (neither the in-scope agreed-width symbol nor an out-of-scope one).
; CHECK-NOT: cq_template_fcmp
; CHECK-NOT: cq_template_icmp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call double @cq_theta_f64(double 2.0, double 5.000000e-01)
  %b = call double @cq_theta_f64(double 3.0, double 2.500000e-01)
  ; Both tainted, widths AGREE (f64) → QQ branch entered; `ord` is out of the
  ; {oeq,une,olt,ogt,ole,oge} scope → `compareInScope` declines loudly.
  %c = fcmp ord double %a, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
