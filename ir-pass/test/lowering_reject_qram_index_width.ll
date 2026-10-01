; lowering_reject_qram_index_width.ll — LOUD (libcqops handoff b6a): a QRAM index
; whose logical width has no in-scope cast to the i32 index width (`i48`, e.g. a
; C23 `_BitInt(48)` subscript). `resolveQramIndex` narrows i64/i80/i128 by `trunc`
; and re-extends i1/i8/i16; an off-grid width has no `cq_template_*_to_i32`, so it
; fails loudly rather than pass a 48-bit rail as the index. This is a template-
; surface gap (no i48 anywhere in the opcode table), not a physics decline:
; retire this fixture when the integer width grid grows past the six ABI widths.
; Before b6a this input also failed loudly, later, at lowerOps (`no template for
; opcode 'trunc i48'`); the fixture pins which loud message fires first.
; This file pins the const-global read (`lowerQramReads`); the local-array twin
; is lowering_reject_qram_index_width_shadow.ll (one fixture per diagnostic: the
; first error stops `opt`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@t4 = internal constant [4 x i32] [i32 7, i32 9, i32 11, i32 13]
declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_measure_si32(i32)

define i32 @qrom_i48(i64 %u) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  %t = trunc i64 %q to i48
  %g = getelementptr inbounds [4 x i32], ptr @t4, i64 0, i48 %t
  %v = load i32, ptr %g, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: in function qrom_i48 {{.*}}: cq QRAM access: index has no cast to the i32 index width
