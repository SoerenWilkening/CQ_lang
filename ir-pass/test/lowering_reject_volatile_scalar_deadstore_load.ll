; lowering_reject_volatile_scalar_deadstore_load.ll — DECLINE PIN (bd k710): a
; single LOAD forfeits the whole stage. "Dead store" means the slot is never read;
; one read and the store is live, whatever fenv does or does not model.
;
; The load here is also UNDEF-READING (nothing has stored yet on that path), which
; is why zco4's promotion does not rescue it either — its gate 5
; `everyLoadIsStoreDefined` refuses. So the volatile store survives and the tainted
; value dies on the existing escape decline. Both stages decline, independently and
; for their own correct reasons; neither claims a slot whose contents are observed.
;
; This is the boundary between this stage and its two siblings, stated as a test:
;   * foldVolatileConstAllocaLoads (etiq) needs loads AND a Constant store  -> no
;   * promoteVolatileScalarLocals (zco4) needs loads to promote             -> no
;   * eraseDeadVolatileScalarStores (k710) needs ZERO loads                 -> no
; A shape that satisfies none of the three is exactly what the loud decline is for.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)

define float @probe(float %u0, float %u1) {
entry:
  %u = alloca float, align 4
  %q = call float @cq_theta_f32(float %u0, double 5.000000e-01)
  %p = call float @cq_theta_f32(float %u1, double 5.000000e-01)
  %pre = load volatile float, ptr %u, align 4      ; ONE read — stage forfeits
  %uu = fmul float %p, %p
  store volatile float %uu, ptr %u, align 4
  %s = fadd float %q, %pre
  %m = call float @cq_measure_f32(float %s)
  ret float %m
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
