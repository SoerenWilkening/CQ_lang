; lowering_reject_qram_pun_load_fp.ll — DECLINE (bd 38t2 Rule-13 clearance): a
; TYPE-PUNNED sub-width fp load from a wider fp QROM cell — `load float` through a
; `[4 x double]` const-table gep (real C: `float v = *(const float*)&tbl[q];`).
; Without the accessed-type == cell-type pun fence this ACCEPTED and emitted a
; full-cell `cqrt_qram_load_f64` whose handle (HandleWidth recorded f64) RAUWs into
; f32-typed users (cqrt_measure_f32) — a wrong-width gate stream for a user-declared
; 32-bit read. With the fence the access is NOT a qram shape and the tainted index
; reaching the un-matched gep/load loud-declines at the taint-escape guard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tbl = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0]
declare i32 @cq_theta_si32(i32, double)
declare float @cq_measure_f32(float)

define float @pun_load(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [4 x double], ptr @tbl, i64 0, i64 %i
  %v = load float, ptr %g, align 4             ; PUN: f32 load from an f64 cell
  %m = call float @cq_measure_f32(float %v)
  ret float %m
}

; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
