; lowering_reject_qram_read_defer_region_declines.ll — DECLINE PIN (3c6m.14 L6
; Inc 3, Rule-13 coverage, LENS-5): a claimable const-global QROM read under
; control whose region ALSO contains an unknown call, so PredMux cannot claim
; it (E4 admits no non-curated call). The read's carve verdict is DeferControl
; (which SUPPRESSES the pre-detection escape decline for the read itself), so
; soundness depends on the enclosing region ALWAYS resolving loudly when
; PredMux leaves it — never silently passing the deferred read to the backend.
; Here the leftover unknown call trips `declineTaintEscapes` after PredMux
; declines to claim the region: the whole region declines loudly. Pins the
; iw81.7 divergence fence for the QROM-read defer path (a deferred read is
; ALWAYS resolved — flattened+lowered, or a loud region decline).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@ln2 = internal unnamed_addr constant [2 x double] [double 0x3FE62E42FEE00000, double 0xBFE62E42FEE00000]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare void @sink(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %sx = lshr i64 %bits, 63
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [2 x double], ptr @ln2, i64 0, i64 %sx
  %v = load double, ptr %g, align 8       ; claimable QROM read → carve DeferControl
  call void @sink(double %v)               ; ... but an unknown call blocks the claim
  %hi = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hi, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
