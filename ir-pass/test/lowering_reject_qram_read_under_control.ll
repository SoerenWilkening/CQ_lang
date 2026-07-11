; lowering_reject_qram_read_under_control.ll — DECLINE (bd 3c6m.13). A tainted-index
; READ of a CONSTANT global table `[N x double]` that sits UNDER TAINTED CONTROL — the
; exact shape openlibm emits for `hi = x - ln2HI[xsb]` (e_exp.c:138), `Zero[sx]`
; (e_fmod.c:48), `tbl[i0]` (s_exp2.c). It is a would-be QROM read (straight-line the
; identical shape LOWERS — lowering_qram_read_fp64.ll); the ONLY blocker is that the
; read is control-dependent on a tainted branch. `declineTaintEscapes` runs BEFORE
; `detectControlRegions`, so the read is the FIRST-tripped tainted instruction.
;
; Empirically (real openlibm bodies, bd 3c6m.13 investigation): ACCEPTING this read and
; hoisting it to unconditional yields ZERO new compiles — the surrounding NESTED tainted
; control (L6, bd 3c6m.14) / inner calls / loops are the real wall. So this shape stays a
; LOUD DECLINE (Prime Directive: accepting a read under tainted control couples QROM-accept
; to control-accept — L6's job). This fixture pins the PRECISE signpost that replaced the
; misleading generic "unsupported instruction" (which implied a missing opcode and sent the
; census down the wrong lever): the pattern is named so future L6 work is directed correctly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq QRAM access: const-global table read under tainted control (needs nested-control lowering)
@ln2 = internal unnamed_addr constant [2 x double] [double 0x3FE62E42FEE00000, double 0xBFE62E42FEE00000]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @exp_like(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %sx = lshr i64 %bits, 63                 ; tainted sign bit → table index
  %cmp = fcmp olt double %q, 0.000000e+00  ; tainted condition
  br i1 %cmp, label %arm, label %merge
arm:                                       ; the const-table read is CONDITIONAL here
  %g = getelementptr inbounds [2 x double], ptr @ln2, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hi = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hi, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
