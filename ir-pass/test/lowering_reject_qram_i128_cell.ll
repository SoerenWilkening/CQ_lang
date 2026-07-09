; lowering_reject_qram_i128_cell.ll — DECLINE (Phase 7.5 Inc 1): a tainted-index READ
; of a const table whose ELEMENT is `i128`. i128 is a recognized INTERMEDIATE-only
; width with NO reversible copy (n0ui Tier-1) — there is no `cqrt_qram_load_i128`, so
; an i128 cell must decline, never mint a phantom. As of bd 38t2 the cell gate is
; `widthHasQramCell` (int {i1..i64} + fp {f16,f32,f64,f80}); i128 (bits>64) stays OUT,
; alongside fp128 (lowering_reject_qram_fp128_cell.ll). Deferred with the 7.1 i128
; follow-up (PRD-7.5 §2.3, §5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tbl128 = internal unnamed_addr constant [2 x i128] [i128 1, i128 2]
declare i32 @cq_theta_si32(i32, double)

; The loaded value is left dead (ret void) so the read reaches the QRAM element-
; width gate rather than the pre-existing non-i32 `ret` guard.
define void @qrom_read_i128(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [2 x i128], ptr @tbl128, i64 0, i64 %i
  %v = load i128, ptr %g
  ret void
}

; CHECK: error{{.*}}cq QRAM read: array element is not a reversible cell
