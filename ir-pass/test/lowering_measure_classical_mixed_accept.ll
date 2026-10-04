; lowering_measure_classical_mixed_accept.ll — ACCEPT: a QUANTUM measure and a
; CLASSICAL measure in the SAME function, plus a measure OF a measure result. bd
; test_C_libtooling-21mg.
;
; This is the discriminating half of 21mg. `lowering_measure_classical_accept.ll`
; proves a purely-classical module emits nothing; this one proves the two
; dispositions coexist per-call-site, selected by TAINT and nothing else (Rule 3):
; the theta-derived operand still gets `cqrt_measure_<W>(handle)`, the classical
; one still gets nothing, in one `lowerMeasures` walk over one `taint.MeasureCalls`.
; A predicate that keyed on anything else — the operand's TYPE, the presence of a
; theta in the module, the call's position — would move one of the two.
;
; SOURCE INTENT (probe `trackC/probes/c8_theta_and_classical.c`):
;     int q = 5; cq_theta(&q, 0.5); int c = 11;
;     return cq_measure(q) + cq_measure(c);
;
; @f_measure_of_measure is the ORDER-INDEPENDENCE case: a `cq_measure` of another
; `cq_measure`'s RESULT. A measure result is a taint SINK and is never tainted
; (`isMeasureSink`), so the OUTER call is classical and collapses onto the inner
; call's value — exactly one gate and one trace line for the pair. It is correct
; under either processing order (`taint.MeasureCalls` is in block order, so the
; inner is rewritten first and the outer's operand is already the emitted
; `cqrt_measure_i32`; with the order reversed the outer would collapse onto the
; still-unlowered inner call, which is then lowered in place — same module), and it
; is the one shape where the two dispositions touch the same SSA edge.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOINTR < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f_mixed(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %mq = call i32 @cq_measure_si32(i32 %q)      ; QUANTUM  -> cqrt_measure_i32(h)
  %mc = call i32 @cq_measure_si32(i32 11)      ; CLASSICAL -> the literal 11
  %r = add nsw i32 %mq, %mc
  ret i32 %r
}
; the rail is minted and rotated exactly once, the quantum measure fires on the
; HANDLE, and the classical one leaves nothing behind — `%r` adds the measured
; value to the bare literal:
; CHECK-LABEL: define i32 @f_mixed(i32 %u0)
; CHECK:         %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT:    call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT:    %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:    %r = add nsw i32 %[[M]], 11
; CHECK-NEXT:    ret i32 %r

define i32 @f_measure_of_measure(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %q)      ; QUANTUM
  %m2 = call i32 @cq_measure_si32(i32 %m1)     ; CLASSICAL (a measure result is a sink)
  ret i32 %m2
}
; CHECK-LABEL: define i32 @f_measure_of_measure(i32 %u0)
; CHECK:         %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT:    call void @cqrt_ry_i32(i32 %[[H2]], double 2.500000e-01)
; CHECK-NEXT:    %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NEXT:    ret i32 %[[M2]]

; ── WHOLE-FILE COUNTS, in their own prefixes (Rule 12 (a)) ──────────────────────
;
; EXACTLY TWO measurement gates in the module — one per QUANTUM measure. A third
; would mean a classical measure minted one; a first-only would mean the quantum
; one was swallowed by the classical path:
; ⚠ ANY WIDTH, not `call i32 @cqrt_measure_i32(`: an injected `cqrt_measure_i1`
; was MISSED by 0 of the prefixes when this counted the i32 spelling only
; (injection matrix, 2026-09-13). The `call ` anchor keeps the lazy `declare`
; lines out of the count.
; MCNT-COUNT-2: call {{.*}}@cqrt_measure_
; MCNT-NOT:     call {{.*}}@cqrt_measure_
;
; EXACTLY TWO rails — the two thetas. A third `cqrt_alloc` is a rail minted for
; CLASSICAL data (the f64/angle miscompile family), which is the single worst
; outcome this change could have:
; ⚠ ANY WIDTH again, for the same measured reason — and it is the f64 spelling
; that matters most here, since "allocate for classical data" at f64 IS the
; angle/f64 miscompile family.
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
;
; no front-end intrinsic survives (Rule 1's checked postcondition), and NOTHING
; ELSE is emitted either — no bracket and no free anywhere in the module (both
; rails are terminal and LEFT ALLOCATED, Rule 6: Ry(θ)|0> != |0>). Without these
; two lines an injected `cqrt_x` / `cqrt_free` on the rail was MISSED by 0 of 4
; prefixes (injection matrix, 2026-09-13).
; NOINTR-NOT: call{{.*}}@cq_measure_
; NOINTR-NOT: call{{.*}}@cq_theta_
; NOINTR-NOT: call void @cqrt_x(
; NOINTR-NOT: call void @cqrt_free(
;
; ACC-NOT: operand not recognized
; ACC-NOT: under quantum control
; ACC-NOT: undef/poison literal
