; lowering_inplace_qq_decline_prior_record.ll — DECLINE (owner ruling
; owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1; bd test_C_libtooling-r2j3.33,
; dm7f.51 step 1): the old `t` is DEAD after `t ^= a` and the result survives,
; but the in-place fence REFUSES, so the pass fails loudly instead of lowering
; out of place (which leaves the old `t` rail recording `a` beside `t'`).
;
; Source (clang -O1 -include CQ.h):
;   int a = 0, t = 0; cq_theta(&a, .5); cq_theta(&t, .4);
;   int u = t * 3; t ^= a; cq_theta(&a, .7);
;   cq_measure(a); cq_measure(t); cq_measure(u);
; WHY THE FENCE REFUSES: `u = t * 3` is a PRIOR reader of `t` whose rail is never
; discharged before the xor (it is measured last), so G7 cannot prove that no
; later `_unc` re-reads `t` (`priorUseIsSettled` arm (d)). Before r2j3.33 this
; lowered rc 0 to `cq_template_xor_i32(h_a, h_t)` with the old `t` rail kept.
; RETIREMENT TRIGGER: the design's D2(b) clause ("a prior reader that is observed
; counts settled", with a post-`uncompute` re-check; bd test_C_libtooling-dm7f.76)
; flips this to an accept.
;
; ⚠ FLIPPED TO AN ACCEPT by bd test_C_libtooling-dm7f.77 (dm7f.51 step 2): the
; retirement trigger above (design D2(b), bd dm7f.76) is built for the OBSERVED
; case — a prior producer whose rail the program MEASURES is never reversed by the
; spine, so overwriting `t` after it stales nothing (`priorUseIsSettled` arm (d3),
; quantum source only; dicke.c needs it for `q4 = !q2 ... q2 ^= q1`). `u = 3t`
; is minted from the old `t`, measured last, and `t ^= a` goes in place:
; `mul_hl(t, 3)`, `cqrt_xor_i32(a, t)`, Ry on `a`. The source circuit exactly
; (register `u` a kept record of the old `t`, register `t` overwritten in place).
; The step-1 postcondition still re-asks every later adjoint after `uncompute`.
; The "returned" half of D2(b) is not built (dm7f.76 stays open for it).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define noundef i32 @main()
; CHECK:       %[[U:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[T:[a-zA-Z0-9_.]+]], i32 3)
; CHECK-NEXT:  call void @cqrt_xor_i32(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[T]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[U]])
; CHECK-NOT:   cq_template_xor

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define noundef i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = mul nsw i32 %2, 3
  %4 = xor i32 %2, %1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

