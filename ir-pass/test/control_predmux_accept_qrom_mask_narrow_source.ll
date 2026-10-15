; control_predmux_accept_qrom_mask_narrow_source.ll — ACCEPT (bd 01po.2): the
; PredMux NeedsMask `and idx, N-1` of a speculated const-table read is built on
; the NARROW source of the gep's -O1 widening `sext`/`zext` (width W <= 32), and
; the gep index becomes `zext iW (and iW src, N-1)`. Exact when N-1 fits in W
; bits: sext(src) and zext(src) both equal src on bits [0,W) and the mask has no
; bit at or above W, so `E(src) & (N-1) == zext(src & (N-1))` for E in
; {sext, zext}. The re-widening is ALWAYS `zext` (never the source's own kind):
; the QRAM emitter strips it and re-extends a narrow rail with ITS kind, and a
; `zext` is what the shared bounds proof (`qromIndexKnownInBounds`) reads as
; value-preserving. The width-boundary fall-backs are pinned by
; control_predmux_accept_qrom_mask_width_bounds.ll, the Bennett-clone shape by
; control_predmux_accept_qrom_mask_clone_i32.ll.
;
; Per function, CHECK pins the mask on the narrow rail feeding the QRAM read and
; its `_unc`; NARROW pins, over the WHOLE function body, that no i64 widening,
; no `and_i64` and no `trunc_i64_to_i32` bracket is left (each was the
; pre-01po.2 lowering: `<ext>_iW_to_i64 -> and_i64_hl -> trunc_i64_to_i32`
; around every QRAM call).
;   * i8 sext / i16 zext source: the masked iW rail gets the QRAM emitter's own
;     `zext_iW_to_i32` bracket (logical width 32 at the call);
;   * N == 2^W, the all-ones mask (`[256 x i8]` on a signed i8, `[2 x i32]` on a
;     signed i1): no `and` at all, the index is zext(src) — sext(src) & 255 ==
;     zext(src) — and the source rail itself feeds the zext_iW_to_i32 bracket;
;   * N == 1, the zero mask, KEEPS its `and` so the source stays a used,
;     uncomputed value (a constant index would orphan it, and an orphaned op
;     outside the region is never uncomputed): an i32 source outside the region
;     gets `and_i32_hl(src, 0)` and its own `_unc`. On an i1 the `and i1 b, false`
;     is a flatten residue: folded, the read is the CLASSICAL tbl[0] (no QRAM
;     alloc, no index rail; a `zext i1 false` residue stays) and the residue
;     folder's guarded eraser removes the orphaned flag.
;     (Pre-01po.2 each of these was
;     `<ext>_iW_to_i64 -> and_i64_hl(.., 1|0|255) -> trunc_i64_to_i32`.)
;   * an i32 source that is a template result (`add`) and a region-internal
;     i32 phi (`select` after the flatten): one `and_i32_hl`, no bracket;
;   * a widening cast with ANOTHER user: it survives for that user, and the
;     read still takes the narrow mask.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NARROW %s < %t.cqd0.ll
@t4 = internal unnamed_addr constant [4 x i32] [i32 7, i32 9, i32 11, i32 13]
@t8h = internal unnamed_addr constant [8 x i16] [i16 1, i16 2, i16 3, i16 4, i16 5, i16 6, i16 7, i16 8]
@t256 = internal unnamed_addr constant [256 x i8] zeroinitializer
@t2 = internal unnamed_addr constant [2 x i32] [i32 5, i32 6]
@t1 = internal unnamed_addr constant [1 x i32] [i32 4]
@t1b = internal unnamed_addr constant [1 x i32] [i32 4]
declare i8 @cq_theta_si8(i8, double)
declare i16 @cq_theta_si16(i16, double)
declare i32 @cq_theta_si32(i32, double)
declare i8 @cq_measure_si8(i8)
declare i16 @cq_measure_si16(i16)
declare i32 @cq_measure_si32(i32)
declare i64 @cq_measure_sll(i64)

; (1) signed i8 index, N = 4.
define i32 @sext_i8_n4(i8 %u0) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u0, double 5.000000e-01)
  %c = icmp ult i8 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i8 %q to i64
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @sext_i8_n4(
; CHECK: %u0.stable = freeze i8 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u0.stable)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i8_hl(i32 %[[Q]], i8 3)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i8_to_i32(i32 %[[M]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_zext_i8_to_i32_unc(i32 %[[X]], i32 %[[M]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cq_template_and_i8_hl_unc(i32 %[[M]], i32 %[[Q]], i8 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; NARROW-LABEL: define i32 @sext_i8_n4(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32

; (2) unsigned i16 index, N = 8.
define i16 @zext_i16_n8(i16 %u0) {
entry:
  %q = call i16 @cq_theta_si16(i16 %u0, double 5.000000e-01)
  %c = icmp ult i16 %q, 8
  br i1 %c, label %arm, label %merge
arm:
  %idx = zext i16 %q to i64
  %g = getelementptr inbounds [8 x i16], ptr @t8h, i64 0, i64 %idx
  %v = load i16, ptr %g, align 2
  br label %merge
merge:
  %rm = phi i16 [ %v, %arm ], [ 99, %entry ]
  %m = call i16 @cq_measure_si16(i16 %rm)
  ret i16 %m
}
; CHECK-LABEL: define i16 @zext_i16_n8(
; CHECK: %u0.stable = freeze i16 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i16(i32 8)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i16(i16 %u0.stable)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i16_hl(i32 %[[Q]], i16 7)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i16_to_i32(i32 %[[M]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i16(i32 %[[T]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_zext_i16_to_i32_unc(i32 %[[X]], i32 %[[M]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cq_template_and_i16_hl_unc(i32 %[[M]], i32 %[[Q]], i16 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; NARROW-LABEL: define i16 @zext_i16_n8(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32

; (3) N == 2^W: a signed i8 into a 256-cell table. The mask would be all-ones
; on i8, so no `and` is built; the bracket is ZEXT (the index is the unsigned
; byte, as the gep read it: sext(src) & 255 == zext(src)), never sext.
define i8 @sext_i8_n256(i8 %u0) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u0, double 5.000000e-01)
  %c = icmp sgt i8 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i8 %q to i64
  %g = getelementptr inbounds [256 x i8], ptr @t256, i64 0, i64 %idx
  %v = load i8, ptr %g, align 1
  br label %merge
merge:
  %rm = phi i8 [ %v, %arm ], [ 99, %entry ]
  %m = call i8 @cq_measure_si8(i8 %rm)
  ret i8 %m
}
; CHECK-LABEL: define i8 @sext_i8_n256(
; CHECK: %u0.stable = freeze i8 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i8(i32 256)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u0.stable)
; CHECK:      %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i8_to_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i8(i32 %[[T]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_zext_i8_to_i32_unc(i32 %[[X]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; NARROW-LABEL: define i8 @sext_i8_n256(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i
; NARROW-NOT: trunc_i64_to_i32
; NARROW-NOT: sext_i8_to_i32

; (4) a sign-extended _Bool-width index (0 or -1), N = 2 = 2^1: the all-ones
; mask is not built; the flag b itself feeds the emitter's zext_i1_to_i32.
define i32 @sext_i1_n2(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ult i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %b = icmp sgt i32 %q, 1
  %idx = sext i1 %b to i64
  %g = getelementptr inbounds [2 x i32], ptr @t2, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @sext_i1_n2(
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 2)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[B]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[X]], i32 %[[B]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[B]],
; NARROW-LABEL: define i32 @sext_i1_n2(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i
; NARROW-NOT: trunc_i64_to_i32

; (4b) a zero-extended _Bool into a ONE-cell table: the i1 zero mask folds, the
; index is 0, so the read is the classical tbl[0] = 4.
define i32 @zext_i1_n1(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ult i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %b = icmp sgt i32 %q, 1
  %idx = zext i1 %b to i64
  %g = getelementptr inbounds [1 x i32], ptr @t1, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @zext_i1_n1(
; CHECK:      %[[G:[a-zA-Z0-9_.]+]] = getelementptr [1 x i32], ptr @t1, i64 0, i64 %{{[a-zA-Z0-9_.]+}}
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = load i32, ptr %[[G]], align 4
; CHECK-NEXT: %[[VF:[a-zA-Z0-9_.]+]] = freeze i32 %[[V]]
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(
; CHECK:      call void @cqrt_xorc_i32_controlled(i32 %[[H]], i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[VF]])
; NARROW-LABEL: define i32 @zext_i1_n1(
; NARROW-NOT: qram
; NARROW-NOT: icmp_sgt
; NARROW-NOT: _to_i
; NARROW-NOT: and_i

; (4c) N == 1 with a source OUTSIDE the region (an `add` in the entry block):
; the zero mask keeps its `and`, so the add stays used and is uncomputed. The
; witness is the add's `_unc`: with a constant 0 index the add is orphaned and
; lowers as a forward `add_i32_hl` with no `_unc` (measured), a live copy of %q.
define i32 @n1_outside(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = add i32 %q, 1
  %c = icmp ult i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i32 %a to i64
  %g = getelementptr inbounds [1 x i32], ptr @t1b, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @n1_outside(
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 1)
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 1)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[M]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[A]], i32 0)
; CHECK:      call void @cq_template_add_i32_hl_unc(i32 %[[A]], i32 %[[Q]], i32 1)
; NARROW-LABEL: define i32 @n1_outside(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32

; (5) the source is a TEMPLATE RESULT (`add`), not a theta rail.
define i32 @tmpl_i32(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ult i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %a = add i32 %q, 1
  %idx = sext i32 %a to i64
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @tmpl_i32(
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[A]], i32 3)
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[M]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[A]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; NARROW-LABEL: define i32 @tmpl_i32(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32

; (6) the atan `id` mechanism at i32: a region-internal i32 phi over constants
; (one of them -1, so known bits cannot bound it), sign-extended. After the
; flatten the phi is a select chain; the mask is built on that i32 value.
define i32 @phi_i32_sext(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 1
  br i1 %c1, label %inner, label %merge
inner:
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %ia, label %ib
ia:
  br label %join
ib:
  br label %join
join:
  %id = phi i32 [ 2, %ia ], [ -1, %ib ]
  %idx = sext i32 %id to i64
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  %s = add i32 %q, %v
  br label %merge
merge:
  %r = phi i32 [ %s, %join ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
; CHECK-LABEL: define i32 @phi_i32_sext(
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; bd r2j3.32 (R11 round 1, item 7): the index merge rail %[[ID]] (its two
; copies bound to their sources) is reversed right after its last reader, the
; mask's `_unc`, its network strip deferred behind that, then freed — all
; pinned with captured handles, before the mask rail's own free.
; CHECK:      %[[R_H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[R_H:[a-zA-Z0-9_.]+]], i32 1)
; CHECK-NEXT: %[[R_H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[R_H]], i32 9)
; CHECK-NEXT: %[[R_G2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[R_H_CMP]], i32 %[[R_H_CMP1]], i32 %[[R_G2]])
; CHECK-NEXT: %[[ID:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[R_G2]], i32 %[[ID]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[R_G2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[R_G2]], i32 %[[ID]], i32 -1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[R_G2]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[ID]], i32 3)
; CHECK-NEXT: %[[R_0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[M]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[ID]], i32 3)
; CHECK-NEXT: call void @cqrt_x(i32 %[[R_G2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[R_G2]], i32 %[[ID]], i32 -1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[R_G2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[R_G2]], i32 %[[ID]], i32 2)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[R_H_CMP]], i32 %[[R_H_CMP1]], i32 %[[R_G2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R_G2]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[R_H_CMP1]], i32 %[[R_H]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[R_H_CMP1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[R_H_CMP]], i32 %[[R_H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[R_H_CMP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[ID]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; NARROW-LABEL: define i32 @phi_i32_sext(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32

; (6b) the widening cast sits in the ENTRY block (outside the moved arm) and
; the gep is its only user: replaced, it is dead, and the flatten's sweep (the
; `track(Idx)` in the mask loop) erases it. Left behind it would lower as a
; stray `sext_i32_to_i64` with its `_unc`.
define i32 @entry_cast(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = sext i32 %q to i64
  %c = icmp ult i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @entry_cast(
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[M]])
; NARROW-LABEL: define i32 @entry_cast(
; NARROW-NOT: _to_i64
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32

; (6c) a speculated read whose value is DEAD: the flatten's sweep erases the
; load, its gep, and every mask instruction this stage minted (the narrow `and`
; and its `zext` are tracked too), so no gate of the read survives.
define i32 @dead_read(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ult i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i32 %q to i64
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  %a = add i32 %q, 3
  br label %merge
merge:
  %rm = phi i32 [ %a, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @dead_read(
; CHECK:      call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; NARROW-LABEL: define i32 @dead_read(
; NARROW-NOT: qram
; NARROW-NOT: and_i
; NARROW-NOT: _to_i

; (7) the widening cast has a SECOND user (an i64 add, measured): the cast
; survives for it, and the read still takes the narrow mask on the i32 rail.
define i32 @shared_cast(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = sext i32 %q to i64
  %w = add i64 %idx, 5
  %mw = call i64 @cq_measure_sll(i64 %w)
  %c = icmp ult i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i64 %idx
  %v = load i32, ptr %g, align 4
  br label %merge
merge:
  %rm = phi i32 [ %v, %arm ], [ 99, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
; CHECK-LABEL: define i32 @shared_cast(
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK:      %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i32_to_i64(i32 %[[Q]])
; CHECK:      (i32 %[[E]], i64 5)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[T]], i32 %[[M]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; NARROW-LABEL: define i32 @shared_cast(
; NARROW-NOT: and_i64
; NARROW-NOT: trunc_i64_to_i32
; NARROW-LABEL: declare
