; lowering_stale_reader_chain_accept.ll — ACCEPT, and it is THE DISCRIMINATING
; ACCEPT for bd test_C_libtooling-3d8q: the reader fence must widen a DECLINE
; without touching one well-formed chain.
;
;   int q=0; cq_theta(&q,0.3); int a=q; cq_theta(&a,0.5); int c=a; cq_theta(&c,0.9);
;   return cq_measure(c)+cq_measure(c);
;
; Every rotation consumes the previous name, and the ONLY name read afterwards is
; the chain TIP — read TWICE, which is legal and ordinary: the linear rule is
; about POSITION, not COUNT (`docs/frontend.md` §3.2, "Strict single-use is
; deliberately not the rule").
;
; ⚠ IT IS THE BYTE-IDENTICAL TWIN of the miscompile
; `lowering_reject_stale_reader_sibling_theta.ll` emitted on the pre-fix
; compiler — same four gates, same two measures, same handle. That is the whole
; evidence that the old accept was wrong: one circuit cannot be the compilation
; of both programs. Keep the two files in sync; if this one's stream ever stops
; being what the other used to emit, re-derive both.
;
; TWO exemptions carry this accept and each has its own way of failing silently:
;   * `%c` is ITS OWN GATE on `%a`'s rail — exempted via `Covered`, which skips it
;     as EVIDENCE while still walking THROUGH it. Drop that and EVERY chained
;     rotation in the tree declines against itself;
;   * for `cq_measure(%c)`, `%a` and `%q` are on `%c`'s backward ANCESTRY — the
;     producers of the record — and the walker's per-seed `Exempt` set holds them.
;     Widen the exempt set to a shared/unioned one and a genuine sibling hides.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %a = call i32 @cq_theta_si32(i32 %q, double 5.000000e-01)
  %c = call i32 @cq_theta_si32(i32 %a, double 9.000000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %c)
  %m2 = call i32 @cq_measure_si32(i32 %c)
  %s = add i32 %m1, %m2
  ret i32 %s
}

; ONE rail, three in-place rotations on it, both measurements on the same handle.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 9.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

; Counts live in their own WHOLE-FILE prefix — a positive line inside a negative
; prefix WINDOWS every negative after it (Rule 12 fixture-hygiene defect (a)).
; ACNT-COUNT-1: call i32 @cqrt_alloc_i32(
; ACNT-NOT: call i32 @cqrt_alloc_i32(

; TWO measurements, of the tip, on the one handle — the "position, not count"
; half of the linear rule. (Added by the injection matrix: `dup_measure` was
; caught by NO block.)
; MCNT-COUNT-2: call i32 @cqrt_measure_i32(
; MCNT-NOT: call i32 @cqrt_measure_i32(

; Pure negatives only.
; NOQ-NOT: cq_theta_si32
; NOQ-NOT: cq_measure_si32
; NOQ-NOT: cqrt_free
