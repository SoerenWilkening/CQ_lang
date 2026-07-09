; lowering_reject_qram_fp128_cell.ll — DECLINE (bd 38t2): a tainted-index READ of a
; const table whose ELEMENT is `fp128` (IEEE quad). 38t2 admits the fp cell widths
; {f16,f32,f64,f80} (widthHasQramCell), but fp128 stays OUT: `abiWidthFromType` returns
; "" for it (no sound c_type on this x86-64 build — `long double` is fp80, so an fp128
; c_type would be a silent fp128-into-fp80 ABI miscompile). So there is no
; `cqrt_qram_*_fp128` and the element-width gate declines at kMsgQramCell. This is the
; NEW fp boundary that replaces the old blanket fp decline
; (lowering_reject_qram_fp_cell.ll, removed in 38t2). A PERMANENT decline on this build.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tblq = internal unnamed_addr constant [2 x fp128] [fp128 0xL00000000000000000000000000000000, fp128 0xL00000000000000000000000000000000]
declare i32 @cq_theta_si32(i32, double)

define void @qrom_read_fp128(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [2 x fp128], ptr @tblq, i64 0, i64 %i
  %v = load fp128, ptr %g
  ret void
}

; CHECK: error{{.*}}cq QRAM read: array element is not a reversible cell
