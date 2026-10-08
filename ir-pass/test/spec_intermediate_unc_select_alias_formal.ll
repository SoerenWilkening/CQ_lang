; spec_intermediate_unc_select_alias_formal.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-p3kd.13): the clone's own borrowed-parent proof through a
; `select` ALIAS of its formal.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int g(int x, int k) { return k > 0 ? x : x * 3 + 1; }
;     int alias_consumer(int m, int k) { int q = m & 7; cq_theta(&q, .5);
;                                        int s = g(q, k) * 5; return cq_measure(s); }
; `k` is a RUNTIME classical operand, so the clone keeps a classical-condition RAIL
; SELECT (CloneRailSelect.h): `%cqq.rsel = select i1 %c, i32 %x, i32 %h_op1`, and
; the copy-out reads the select. The formal `%x` therefore has a non-call user.
;
; WHY IT MATTERS. Discharging the clone rail `%r` after the `mul` reads `q` (the
; borrowed parent) through the twin, so the M-B clause-(d) scan must prove the
; clone CALL itself leaves `q`'s label alone (`cloneCallPreservesArg`, bd rhk5,
; row (3) of `preservesBorrowedParent`). The rhk5 proof refused every non-call
; use of the formal, so a body with a rail select — openlibm `pow` has one — kept
; its result allocated. bd p3kd.13 walks a `select` alias's uses with the same
; (B1)–(B4) table (ClonePreserves.cpp `aliasLabelPreserved`): here the only use is
; the copy-out's READ slot, so `%x` is never written.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @alias_consumer(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_g_01(i32 noundef %[[H]], i32 noundef %1)
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 5)
; CHECK-NEXT: call fastcc void @__cq_q_g_01_unc(i32 %[[R]], i32 %[[H]], i32 %1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])
; The clone body really carries the alias:
; CHECK-LABEL: define internal fastcc i32 @__cq_q_g_01(
; CHECK:      select i1 %{{[0-9]+}}, i32 %0, i32 %{{[a-zA-Z0-9_.]+}}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @alias_consumer(i32 noundef %0, i32 noundef %1) {
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #1
  %5 = tail call fastcc i32 @g(i32 noundef %4, i32 noundef %1)
  %6 = mul nsw i32 %5, 5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %7
}

define internal fastcc i32 @g(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  %4 = mul nsw i32 %0, 3
  %5 = add nsw i32 %4, 1
  %6 = select i1 %3, i32 %0, i32 %5
  ret i32 %6
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nomerge nounwind }
