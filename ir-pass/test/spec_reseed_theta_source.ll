; spec_reseed_theta_source.ll — Phase 6.1 WI-1.9 hardening (Rule-13 axis-(g)
; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@cls` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces an
; integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; is no longer a Phase-6 site at all: the call stays an ordinary classical call, no
; clone is built and nothing is scrubbed, i.e. the property this file pins would have
; no subject. The ONE added line in `@cls`, `%vsfp.read`, is a DEAD READ that keeps
; the parameter used, so the clone is still built, still returns classical and is
; still scrubbed. (Its forward/adjoint template pair now sits in the CLONE body; the
; caller-side checks below are unchanged.) That population — a callee that READS the
; argument yet returns classical — is IR-ONLY from C at -O1. The NODROP prefix pins
; that the drop does NOT fire here; a widening of the drop retires this subject and
; must re-derive it (CLAUDE.md L8).
;
; regression). The §2.7 return-taint SCRUB (for a `ReturnTainted=false` clone)
; must NOT walk through a PRIMARY taint source. Here a classical-return clone
; result `%r` (correctly scrubbed) feeds a FRESH `cq_theta` — a NEW taint source
; whose qubit `%re` is quantum REGARDLESS of its classical arg-0 seed (Rule 3).
; The scrub's never-scrub set therefore includes `taint.ThetaCalls`: it stops at
; `%re` and prunes its downstream cone, so `%w = add %re, 8` STAYS tainted and
; lowers to `cq_template_add_i32_hl` (reading the new qubit handle as arg 0, the
; classical literal `8` as arg 1), and the measure sees a real handle.
;
; Pre-fix the scrub over-walked `%r → %re → %w`, un-tainting the qubit cone — a
; spurious LOUD decline on this valid program (`cq_measure_<sfx> operand not
; recognized`). The fix keeps the qubit cone tainted; the GENUINE-classical
; scrub (spec_result_classical.ll) must stay un-lowered, so both directions hold.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the `q + c` lowers IN PLACE
; to the frozen `cqrt_addc_<W>` (its parent handle has no data use after it), so
; no ancestor rail is minted and the measurement reads the rail itself. Nothing
; else this file pins has moved.
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.vsfp.err
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.vsfp.err
; NODROP-NOT: CQ_DEADARG_DBG
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @cls(i32 %t, i32 %c) {
entry:
  %vsfp.read = mul i32 %t, 3   ; bd vsfp: a DEAD READ keeps this parameter used
  %y = add i32 %c, %c
  ret i32 %y
}

define void @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cls(i32 %q, i32 7)                          ; classical return -> %r scrubbed
  %re = call i32 @cq_theta_si32(i32 %r, double 2.500000e-01)  ; FRESH theta source from %r
  %w  = add i32 %re, 8                                        ; quantum: stays tainted
  %m  = call i32 @cq_measure_si32(i32 %w)
  ret void
}

; %r is scrubbed (classical-return clone) but the fresh theta seeded from it is a
; real qubit: alloc+ry, then the downstream add lowers to a data template, then
; a real measure on that handle — NO loud decline.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_cls_01(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK:     %[[RE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[RE]], double 2.500000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[RE]], i32 8)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[RE]])
;
; The qubit cone was NOT over-scrubbed into a raw classical add, and no decline.
; CHECK-NOT: cq_measure_{{.*}}operand not recognized
; CHECK-NOT: %w = add i32
