; lowering_reject_taint_escape_return_value_diamond.ll — DECLINE: a value-arm
; (method-B) diamond whose merge result is RETURNED at NON-i32 width
; (test_C_libtooling-udw, member 3/3).
;
; `if (q > 5) { p = p*5 + 15; } return p;` — the i32-width twin is an ACCEPT case
; (Phase 4.2 value-arm swap-route: `cqrt_copy_i32` produces the merged handle `%out`,
; ALWAYS i32). Returning that always-i32 `%out` from a function declared to return
; i64 leaves `ret i64 <i32 handle>` — so a shape PRD Part II §8.5 sanctions (ret is
; a legitimate consumer of `out`) crashes the verifier on ACCEPT-class input rather
; than declining. declineTaintEscapes catches the tainted non-i32 ret pre-RAUW.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)

define i64 @example(i64 %u0, i64 %v0) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %p = call i64 @cq_theta_sll(i64 %v0, double 2.500000e-01)
  %c = icmp sgt i64 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i64 %p, 5
  %v2 = add i64 %v1, 15
  br label %merge
merge:
  %pm = phi i64 [ %v2, %arm ], [ %p, %entry ]
  ret i64 %pm                                      ; non-i32 escape — cannot launder
}

; CHECK: error{{.*}}cq taint escape: tainted value returned at non-i32 width
