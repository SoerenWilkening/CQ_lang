; lowering_reject_io_fanout.ll — DECLINE (Phase 7.6, Rule-13 R2): the central
; verify-clean hazard. A tainted value taped by `printf` must be a TERMINAL (or
; measured) value — its lineage must be CLOSED at the sink. Here `mid = q+5` is
; taped, but `mid` ALSO feeds `top = mid*2` (a derived value that is then dead and
; reverse-played by the whole-DAG uncompute spine). The spine anchors that
; reversal at the dead terminal `top`, which PRECEDES the printf — so without this
; guard the reversal would reverse-play and `cqrt_free` `mid`'s rail BEFORE the
; tape write reads it, recording |0> instead of `mid` (a verify-clean
; use-after-free). The fan-out is declined LOUDLY (PRD-7.6 §6.3, the Rule-8
; linear-lineage bail) — over-declining is safe, over-accepting is a silent
; miscompile.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @printf(ptr, ...)
@.d = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %mid = add i32 %q, 5
  %top = mul i32 %mid, 2
  %tr = call i32 @cq_phi_si32(i32 %top, double 3.000000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.d, i32 %mid)
  ret void
}

; CHECK: error{{.*}}cq I/O output sink: tainted argument has continued lineage (only a terminal or measured value may be taped)
