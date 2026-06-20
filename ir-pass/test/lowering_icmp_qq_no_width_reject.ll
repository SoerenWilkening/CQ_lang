; lowering_icmp_qq_no_width_reject.ll — Phase 7.1 Increment A over-accept guard
; (the ABSENT-width arm of the QQ agreement-or-decline guard; never fall back to
; i32). LOAD-BEARING for `rewriteCompare`'s `WA.empty()` decline.
;
; CONSTRUCTABLE absent-width shape (verified by hand, 2026-06-20): two tainted
; i1 compare-result flags fed DIRECTLY into an outer `icmp eq i1 %f1, %f2`. The
; two inner Q+Q compares (`%f1`, `%f2`) lower cleanly to i32 flag handles — their
; theta operands carry HandleWidth=i32, so the inner QQ width is recovered. But a
; compare result is an i1 FLAG handle, and `CompareLowering::promote` records NO
; HandleWidth for a flag (only arith/cast/theta results record a data width). So
; when the OUTER `icmp eq i1 %f1, %f2` is rewritten in program order, BOTH its
; operands are tainted i32 handles with an ABSENT HandleWidth entry. That is the
; `WA.empty()` arm: `rewriteCompare` leaves `QqWidth` empty and the existing Q+Q
; loud bail (`diagnoseNoTemplate`) fires FROM THE OUTER COMPARE ITSELF — the
; diagnostic is `no template for opcode 'icmp i1'` (the i1 result type), NOT a
; `trunc`/upstream producer. Confirmed: `cq-opt` exits 1 on this module.
;
; LOAD-BEARING ARGUMENT (Rule 12 substitution test): if the new agreement-or-
; decline guard were loosened to default an absent/empty recovered width to
; "i32" (the laundered handle type), the outer compare would enter the QQ branch
; with AbiWidth="i32", `compareInScope("icmp","eq")` is true, and the resolver
; would MINT `cq_template_icmp_eq_i32(...)` — a QQ compare over two FLAG handles
; whose real logical relation was lost. The `CHECK-NOT: cq_template_icmp` below
; would then FAIL. The inner compares (`_slt_i32`/`_sgt_i32`) are NOT minted on
; the decline path (the whole module bails), so no `cq_template_icmp` may appear.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; The decline must come from the OUTER `icmp i1` compare (its i1 result type),
; pinning that it is the COMPARE — not an upstream producer — that declines.
; CHECK: error{{.*}}no template for opcode 'icmp i1'{{.*}}
;
; The QQ compare must NOT be lowered to ANY compare template (no i32 fallback);
; and the whole module bails, so the inner compares are not minted either.
; CHECK-NOT: cq_template_icmp
; CHECK-NOT: cq_template_fcmp

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  ; Two inner Q+Q compares: each lowers to an i32 FLAG handle (HandleWidth empty
  ; on the flag), recovering i32 only for the inner compare itself.
  %f1 = icmp slt i32 %a, %b
  %f2 = icmp sgt i32 %a, %b
  ; Outer Q+Q compare: both operands are tainted i1-flag handles with ABSENT
  ; HandleWidth → `WA.empty()` → loud decline from this `icmp i1`.
  %outer = icmp eq i1 %f1, %f2
  %m = call i1 @cq_measure_i1(i1 %outer)
  ret i1 %m
}
