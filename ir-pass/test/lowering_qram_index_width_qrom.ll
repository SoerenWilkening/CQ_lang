; lowering_qram_index_width_qrom.ll — ACCEPT (libcqops handoff b6a): every
; const-global QROM read passes an index rail of LOGICAL width 32 to
; `cqrt_qram_load_<W>`. The index handle was always an i32 token; its WIDTH is
; now fixed too (`runtime/cq_runtime.h`, QRAM section preamble), because the
; symbol names only the cell width and a backend needs one agreed index width.
; `lowerQramReads` decides the cast from the index's LOGICAL width and
; `bracketQramIndexCasts` wraps the call in `cast; call; cast_unc; free`:
;   * a native i64 index           -> `trunc` (exact on every in-bounds index:
;                                      N is an i32 count, OOB is source UB);
;   * an already-laundered i64 rail -> the same trunc (its `HandleWidth` record,
;                                      not its i32 SSA type, gives the width);
;   * a stripped narrow widening    -> re-extended to i32 with the STRIPPED
;                                      cast's own kind (sext/zext), never left
;                                      at i8/i1;
;   * a laundered narrow rail       -> the same.
; The bracket is four consecutive calls (CHECK-NEXT): the cast rail is never
; live across any other gate (see lowering_qram_index_width_shadow.ll's F1).
; Before the fix each of these passed a 64/8/1-bit rail as the index (the i64
; ones abort libcqops: "the index rail is not i32").
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@t4 = internal constant [4 x i32] [i32 7, i32 9, i32 11, i32 13]
@t64 = internal constant [4 x i64] [i64 0, i64 1, i64 2, i64 3]
@t8 = internal constant [4 x i8] [i8 0, i8 1, i8 2, i8 3]
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i8 @cq_theta_si8(i8, double)
declare i32 @cq_measure_si32(i32)

; (1) A native i64 index (a `long` subscript): IR trunc, lowered by lowerOps.
define i32 @native_i64(i64 %u) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %q
  %v = load i32, ptr %g, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK-LABEL: define i32 @native_i64(
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[A]], i32 %[[T]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NOT: call i32 @cqrt_qram_load_i32(i32 %[[A]], i32 %[[Q]])
; CHECK:     ret i32

; (2) A laundered i64 rail: the nested read `t4[t64[q]]` — the inner load is an
; i32-typed handle whose LOGICAL width is the i64 cell, so the trunc is minted
; directly.
define i32 @nested_i64_cell(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %sq = sext i32 %q to i64
  %g1 = getelementptr inbounds [4 x i64], ptr @t64, i64 0, i64 %sq
  %i1 = load i64, ptr %g1, align 8
  %g2 = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %i1
  %v = load i32, ptr %g2, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK-LABEL: define i32 @nested_i64_cell(
; CHECK-DAG: %[[A4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK-DAG: %[[A64:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i64(i32 4)
; CHECK:     %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:     %[[I1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i64(i32 %[[A64]], i32 %[[Q2]])
; CHECK:     %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[I1]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[A4]], i32 %[[T2]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T2]], i32 %[[I1]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK:     ret i32

; (3) A stripped narrow widening `sext i8 -> i64`: re-extended to i32 as SEXT.
define i32 @narrow_i8(i8 %u) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u, double 5.000000e-01)
  %s = sext i8 %q to i64
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %s
  %v = load i32, ptr %g, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK-LABEL: define i32 @narrow_i8(
; CHECK:     %[[A3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:     %[[Q3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u)
; CHECK:     %[[T3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i8_to_i32(i32 %[[Q3]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[A3]], i32 %[[T3]])
; CHECK-NEXT: call void @cq_template_sext_i8_to_i32_unc(i32 %[[T3]], i32 %[[Q3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T3]])
; CHECK:     ret i32

; (4) A `_Bool` subscript `zext i1 -> i64` over a tainted compare: re-extended to
; i32 as ZEXT (an i1 rail is not an index).
define i32 @narrow_i1(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp ult i32 %q, 2
  %z = zext i1 %c to i64
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %z
  %v = load i32, ptr %g, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK-LABEL: define i32 @narrow_i1(
; CHECK:     %[[C4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(
; CHECK:     %[[T4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[C4]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T4]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[T4]], i32 %[[C4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T4]])
; CHECK:     ret i32

; (5) A laundered narrow rail: `t4[t8[q]]` — the inner i8 load handle under a
; `zext i8 -> i64`: re-extended directly as ZEXT.
define i32 @nested_i8_cell(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %sq = sext i32 %q to i64
  %g1 = getelementptr inbounds [4 x i8], ptr @t8, i64 0, i64 %sq
  %i1 = load i8, ptr %g1, align 1
  %z = zext i8 %i1 to i64
  %g2 = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %z
  %v = load i32, ptr %g2, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}
; CHECK-LABEL: define i32 @nested_i8_cell(
; CHECK:     %[[I5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i8(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[T5:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i8_to_i32(i32 %[[I5]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T5]])
; CHECK-NEXT: call void @cq_template_zext_i8_to_i32_unc(i32 %[[T5]], i32 %[[I5]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T5]])
; CHECK:     ret i32
