; lowering_reject_qram_volatile_stored.ll — DECLINE PIN (3c6m.14 L6 Inc 3):
; the volatile-const fold must NOT fire for a global that is STORED anywhere
; in the module — the never-stored proof is what makes load==initializer
; sound, and a stored global is genuinely mutable state (folding it would be
; a silent wrong-value miscompile in the classical remainder). The unfolded
; volatile load then blocks the tainted arm (E4 admits no volatile access)
; and the region declines loudly, exactly as before Inc 3.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@vg = internal global double 1.250000e+00, align 8
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  store double 2.500000e+00, ptr @vg, align 8   ; the global IS stored — no fold
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %t = load volatile double, ptr @vg, align 8
  %u = fmul double %q, %t
  br label %merge
merge:
  %r = phi double [ %u, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
