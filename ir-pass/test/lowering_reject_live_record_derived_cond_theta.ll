; lowering_reject_live_record_derived_cond_theta.ll — DECLINE: bd
; test_C_libtooling-6uqc's OWN P4 shape, the straight-line silent-accept this
; guard exists to close (M-A Increment 1).
;
; SOURCE (clang -O1 emits exactly the SSA below):
;     a = cq_theta(a, 0.5);
;     int f = sqrt(a + 3.0) <= 5.0;   // compiler-materialized temporaries
;     int m = cq_measure(f);
;     a = cq_theta(a, 0.5);           // <-- THIS GATE
;     return m + cq_measure(a);
;
; MEASURED AT HEAD BEFORE THIS GUARD: `opt` exit 0, verify-clean,
; `free_pairing_check.py` 0 violations — and the emitted stream is
;     cqrt_alloc_i32 / cqrt_ry_i32(%h, 0.5)
;     cq_template_sitofp_i32_to_f64(%h)          -> %h_cast
;     cq_template_fadd_f64_hl(%h_cast, 3.0)      -> %h_op
;     cq_template_sqrt_f64(%h_op)                -> %h_intr
;     cq_template_fcmp_ole_f64_hl(%h_intr, 5.0)  -> %h_cmp
;     cq_template_zext_i1_to_i32(%h_cmp)         -> %h_cast1 ; measured
;     cqrt_ry_i32(%h, 0.5)                       ; <-- fires HERE
; `%h_cast`, `%h_op`, `%h_intr` and `%h_cmp` are never uncomputed, never freed,
; and have NO user after the second `Ry`. They are DEAD basis records of `%h`,
; still entangled with it when the non-diagonal gate fires, so `%h`'s reduced
; state is diagonal and the Ry cannot interfere amplitudes across `a`: the
; emitted unitary is not the source's. C ends those temporaries' lifetime at the
; `;`, so the faithful lowering is Bennett compute+uncompute (bd 6uqc option (b),
; mechanism M-B); until that ships, DECLINE (Prime Directive).
;
; WHY NO OTHER LAYER CATCHES IT: `declineStaleRecordOps` only fires on an op
; SCHEDULED PAST a theta (here every producer precedes it — the
; lowering_stale_record_add_before_theta.ll accept boundary), and the wire walk
; runs only for branch conditions. There is no branch here at all.
;
; `%h_cast1` is EXEMPT (measured before the gate, clause 4) and `%h`'s own
; alloc-minted parent is an ANCESTOR (Inc 3) — the decline is carried purely by
; the four dead DESCENDANT records.
;
; THIS DECLINE IS PHYSICALLY LOAD-BEARING, and that is what separates it from the
; two over-declines in the same family. Only ONE BIT leaves this program before
; the gate — the zext of the `fcmp` — while `%h_cast`, `%h_op` and `%h_intr` are
; FULL-PRECISION f64 rails of the wire that stay coherent. A one-bit measurement
; cannot collapse them, so they hold which-path information nothing extracted, and
; the wire's reduced state really is diagonal when the `Ry` fires: amplitudes the
; source meant to interfere cannot. Compare
; lowering_reject_live_record_dead_compare_flag.ll and
; lowering_reject_live_record_two_hop.ll, where every dead rail is a BIJECTION of
; something already measured and therefore carries zero incremental which-path
; information — those two are deliberate over-declines pinning structure. This one
; is the real defect. Do not treat the three as interchangeable evidence.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @llvm.sqrt.f64(double)

define i32 @slice(i32 %u0) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %cast = sitofp i32 %q to double
  %add  = fadd double %cast, 3.000000e+00
  %rt   = call double @llvm.sqrt.f64(double %add)
  %cmp  = fcmp ole double %rt, 5.000000e+00
  %f    = zext i1 %cmp to i32
  %m    = call i32 @cq_measure_si32(i32 %f)
  %q2   = call i32 @cq_theta_si32(i32 %q, double 5.000000e-01)  ; chained, in-place Ry
  %m2   = call i32 @cq_measure_si32(i32 %q2)
  %r    = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
