; lowering_qram_index_width_foreign_tag.ll — ACCEPT (libcqops handoff b6a; the
; round-3 review's H1). `!cq.qram.idxcast` is compiler-owned: the QRAM emitters
; mint it and `bracketQramIndexCasts` consumes it. An INPUT that already carries
; one (here forged onto a classical call) used to be trusted, so `@ext` got a
; `cq_template_trunc_i64_to_i32` "handle" of the classical `%k` as its argument
; (opt rc 0). `stripForeignQramIndexTags` drops input tags at pass entry; the
; program is otherwise unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ext(i32)

define i32 @main(i32 %u, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  %e = call i32 @ext(i32 %k), !cq.qram.idxcast !0
  %r = add i32 %m, %e
  ret i32 %r
}
!0 = !{!"trunc", !"i64", i32 0, i32 1}

; CHECK-LABEL: define i32 @main(
; CHECK-NOT:   cq_template_trunc
; CHECK:       %e = call i32 @ext(i32 %k)
; CHECK-NOT:   cq_template_trunc
; CHECK-NOT:   cqrt_free
; CHECK:       ret i32
; CHECK-NOT:   cq.qram.idxcast
