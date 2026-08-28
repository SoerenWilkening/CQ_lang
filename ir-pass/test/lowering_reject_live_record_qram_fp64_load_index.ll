; lowering_reject_live_record_qram_fp64_load_index.ll — DECLINE: the LOAD-INDEX
; ancestors of a QRAM read are live basis records of the loaded rail (M-A
; Increment 3, bd test_C_libtooling-6uqc).
;
; ⚠ THIS FILE REVERSES A SHIPPED, RULE-13-CLEARED POSITIVE, BY OWNER RULING.
; The module below is byte-for-byte the program that shipped as
; lowering_qram_fp64_measure_no_dirty_free.ll (bd 38t2). That fixture's thesis was
; "the compiler emits EXACTLY the user's forward gate stream, with zero
; `cqrt_free`, zero `_unc` and no inserted measurement in the measured cone —
; emitted == written = correct-by-construction". THE EMISSION CLAIM IS STILL TRUE
; AND IS STILL PINNED (the rewritten
; lowering_qram_fp64_measure_no_dirty_free.ll keeps every CHECK-NOT); what the
; owner ruled (2026-08-27 / 2026-08-28, bd test_C_libtooling-6uqc) is that
; "emitted == written" is NOT a soundness argument when a live entangled record
; stands at a NON-DIAGONAL gate. That is the whole premise of this campaign.
;
; THE PHYSICS, in the stream's own terms. The emitted forward program is:
;     %arr1    = cqrt_qram_alloc_f64(8)
;     %h       = cqrt_alloc_f64(%u0) ; ry(0.5) ; rz(0.3)        the carrier
;     %h2      = cqrt_alloc_f64(0.0) ; ry(0.1)                  index register q
;     %h_cast  = cq_template_fptosi_f64_to_i32(%h2)             qi
;     cqrt_qram_store_f64(%arr1, %h_cast, %h)
;     %h3      = cqrt_alloc_f64(0.0) ; ry(0.2)                  index register p
;     %h_cast4 = cq_template_fptosi_f64_to_i32(%h3)             pi
;     %0       = cqrt_qram_load_f64(%arr1, %h_cast4)            <-- THE WIRE
;     cqrt_ry_f64(%0, 1.0)                                      <-- T
;     cqrt_measure_f64(%0)
; The loaded value is `[pi == qi] · carrier` — a function of `pi`. `%h_cast4`
; (the fptosi rail holding `pi`) and `%h3` (the alloc rail holding `p`) are
; therefore BASIS RECORDS of the wire's value. Neither is read again after the
; load, neither is uncomputed, neither is freed: they are dead, undischarged and
; entangled when the chained `cqrt_ry_f64(%0, 1.0)` fires. The wire's reduced
; state is diagonal in `pi`, so the Ry — the very phase-to-amplitude conversion
; the original fixture existed to demonstrate — acts on a MIXTURE. That is bd
; test_C_libtooling-nepx's argument, at fp width, with the records on the
; ancestor side.
;
; WHICH RAILS THE WALK REACHES, AND WHICH IT DOES NOT — this is the ruled-deferral
; boundary and it is visible here. The backward walk enters the load's operands:
; `%arr1` is a `cqrt_qram_alloc_*` handle and the walk STOPS there (severance
; class 4, the QRAM ARRAY CELL class, owner-ruled deferred 2026-08-27 point 4 and
; pinned by lowering_qram_array_record_chained_theta_accept.ll), so `%h`, `%h2`
; and `%h_cast` — reachable only THROUGH the array — are never counted. The
; decline is carried entirely by the INDEX side: `%h_cast4` and `%h3`.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0 — this exact module lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @shadow_fp_measure(double %u0) {
entry:
  %arr = alloca [8 x double], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 64, i1 false)
  %c  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %cp = call double @cq_phi_f64(double %c, double 3.000000e-01)
  %q  = call double @cq_theta_f64(double 0.0, double 1.000000e-01)
  %qi = fptosi double %q to i32
  %iq = sext i32 %qi to i64
  %gq = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %iq
  store double %cp, ptr %gq, align 8
  %p  = call double @cq_theta_f64(double 0.0, double 2.000000e-01)
  %pi = fptosi double %p to i32
  %ip = sext i32 %pi to i64
  %gp = getelementptr inbounds [8 x double], ptr %arr, i64 0, i64 %ip
  %v  = load double, ptr %gp, align 8                              ; load-back at a DIFFERENT index
  %w  = call double @cq_theta_f64(double %v, double 1.000000e+00)  ; T — chained Ry over the index records
  %m  = call double @cq_measure_f64(double %w)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
