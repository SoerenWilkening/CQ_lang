; lowering_reject_live_record_clone_return_rail.ll — WARNING (was DECLINE): the COPY-DESTINATION
; severance class, closed by M-A Increment 3 (bd test_C_libtooling-6uqc). This is
; the residual over-accept the Inc-1 Rule-13 round found and OWNED — "if this
; starts to decline, that is the scope closing" — and Increment 3 is that closing.
;
; SOURCE (`clang -O1` emits this SSA up to strength reduction — a `* 2` arrives as
; `shl nsw …, 1`, which lowers out of place exactly like the `mul` spelled here; NO control flow anywhere):
;     __attribute__((noinline)) static int inner(int x){ return x + 3; }
;     a = cq_theta(a, 0.5);
;     int r = inner(a);        // clone hop; the Bennett wrap returns `cqq.out`
;     int u = r * 2;           // OUT-OF-PLACE (mul), so `r` is NOT reassigned
;     int m = cq_measure(u);   // ...u is measured before the gate => EXEMPT
;     a = cq_theta(a, 0.7);    // T — and NOTHING declined it before Inc 3
;
; WHAT IS STANDING AT THE GATE. `@__cq_q_inner_1` computes `x+3` into `%h_op`,
; `cqrt_copy_i32`s it into a fresh `cqrt_alloc_i32`-minted `cqq.out`, uncomputes
; and frees `%h_op`, and RETURNS THE COPY. In the caller that returned rail is a
; full basis record of the wire — entangled with it, never uncomputed and never
; freed by anyone — so the chained `cqrt_ry_i32(%h, 0.7)` fires over a live
; record and the emitted unitary is not the source's. bd 6uqc's own P4 defect,
; wearing a clone call.
;
; WHY INCREMENT 1 MISSED IT, precisely. Its record walk followed PRODUCER edges,
; and `cqq.out` has none to follow: the SSA value comes from `cqrt_alloc_i32(0)`,
; whose only operand is a classical seed, and the basis content arrives through a
; VOID `cqrt_copy_i32`. Increment 1 crossed the clone CALL (`isCloneCallHop`) to
; reach records DOWNSTREAM of the result but deliberately did not count the
; result RAIL — the ruled-deferred copy-destination class. Increment 3 counts it:
; a non-void `__cq_q_*` result IS a record, and so is any rail that is the
; DESTINATION operand of a void `cqrt_copy_<W>` / `cqrt_copy_<W>_controlled`.
;
; VEHICLE-OP NOTE — WHY `mul` AND NOT `add`. With `u = r + 1` the M-C in-place
; rewrite (Increment 2a) converts the caller's op to `cqrt_addc_i32(%r, 1)`, so
; `u` and `r` are ONE register and the user's `cq_measure(u)` measures the
; returned rail ITSELF before the gate — clause 4 exempts it and the module
; lowers. That spelling is the accept control
; lowering_live_record_clone_return_rail_measured_accept.ll. `mul` is
; information-losing and therefore outside the dtzb in-place bijection family at
; every M-C batch, so the copy rail stays a distinct, dead, undischarged record.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0, emitting
;   %r = call fastcc i32 @__cq_q_inner_1(i32 %h)
;   %h_op = call i32 @cq_template_mul_i32_hl(i32 %r, i32 2)
;   %m1 = call i32 @cqrt_measure_i32(i32 %h_op)
;   call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; — the over-accept this fixture closes.
;
; NOTE ON WHAT THIS FILE CANNOT CHECK. The `inBennettClone` fence (a void
; `cqrt_addc` must never appear inside @__cq_q_inner_1, because the wrap's
; ForwardStream scan cannot collect one and would leave the borrowed argument
; permanently shifted) is NOT pinned here: a negative fixture FileChecks only the
; DIAGNOSTIC stream, and no module is printed. That fence lives in the accept
; twin lowering_live_record_clone_return_rail_measured_accept.ll, whose CLONE
; prefix asserts it on the same clone body.
;
;
; ⚠ NOW A WARNING, NOT A DECLINE — owner ruling 2026-08-29 (bd
; test_C_libtooling-lyyf, shipped as M-A Increment 7b): "we can always apply any
; unitary operation we want … it is the user's fault to have produced a badly
; functioning code" (Rule 17). The dephasing-by-leftover-record class is the
; USER's circuit, so `opt` prints `warning: …`, exits ZERO, and hands back the
; lowered module. THE ANALYSIS AND THE MESSAGE STRING ARE UNCHANGED — only the
; severity moved, so everything this header says about WHY the record counts
; still holds verbatim. The record is LEFT ALLOCATED and never freed (Rule 6 is
; untouched: nothing frees a rail that is not provably |0>), which the
; `NOFREEREC` prefix below pins alongside the gate that IS now emitted. The file KEEPS its
; `reject_` name deliberately — see RotationLowering.h, which also states what
; the ruling does NOT cover (every wrong-value and dirty-free guard stays loud).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEREC < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %r  = call fastcc i32 @inner(i32 %q)                        ; -> the `cqq.out` copy rail
  %u  = mul nsw i32 %r, 2                                     ; out of place: %r stays distinct
  %m  = call i32 @cq_measure_si32(i32 %u)                     ; exempt (clause 4)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; T — over the live copy rail
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %s  = add nsw i32 %m2, %m
  ret i32 %s
}

define internal fastcc i32 @inner(i32 %x) {
  %a = add nsw i32 %x, 3
  ret i32 %a
}

; WARN: warning{{.*}}in function main{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@main(
; LOWER: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %r)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.