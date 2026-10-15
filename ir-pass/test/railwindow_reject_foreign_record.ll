; railwindow_reject_foreign_record.ll — DECLINE (bd 01po.19 S4): the
; `!cq.railwindow` record is COMPILER-OWNED (it makes every load of the object a
; taint seed and every store a kept-carrier sink), so an input that already
; carries it is a loud reserved-name decline, before any array is claimed
; (`declineForeignRailWindowRecords`, the `!cq.railbank.seed` precedent).
; Hand IR: a plain scalar program with the record forged on an unrelated alloca.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq rail window: input carries the compiler-owned !cq.railwindow record

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)

define i32 @main() {
entry:
  %forged = alloca i32, i64 2, align 4, !cq.railwindow !0
  %q = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %m = call zeroext i1 @cq_measure_i1(i1 zeroext %q)
  %r = zext i1 %m to i32
  ret i32 %r
}

!0 = !{i32 1}
