; lowering_reject_live_record_routed_base_anc.ll — WARNING (was DECLINE) by THIS campaign's
; guard. The ROUTED-BASE ANCESTOR pin (M-A Increment 3, bd
; test_C_libtooling-6uqc), RE-DISPOSITIONED at Increment 4.
;
; RENAMED FROM lowering_reject_live_record_routed_base_anc_masked.ll: the
; `_masked` suffix recorded that bd test_C_libtooling-lom0's position-free
; over-decline reached this program first and hid whatever was behind it.
; Increment 4 lifted that decline for exactly this shape (flat, phase,
; `!ShareCondFlag`, gate provably after the emitted stream), and what was behind
; it is what Increment 3 shipped for. The mask is gone; the decline is not.
;
; SOURCE — a PHASE region whose routed base is a derived rail, followed by a
; chained theta on that same rail:
;     volatile int off = 3;
;     int q = cq_theta(0, 0.5);
;     int r = q * off;                          // routed base: a FRESH rail
;                                               // (mul is NOT an M-C in-place
;                                               // reassignment), so `q`'s alloc
;                                               // rail is a dead ANCESTOR of it
;     if (r == 5) { r = cq_phi(r, PI); }        // phase arm
;     r = cq_theta(r, 0.25);                    // the chained Ry
;     return cq_measure(r);
;
; MEASURED — the verdict never changed, the OWNER did:
;     HEAD b4e329b   cq controlled lowering: condition predates a non-diagonal
;                    gate under quantum control                  (ArmClassify)
;     Increment 4    cq rotation lowering: non-diagonal gate over a live
;                    derived record                        (RotationLowering)
;
; THIS IS THE INTERLOCK, AND IT IS WHY bd 6uqc SEQUENCED INC 3 BEFORE INC 4.
; `cq_template_mul_i32_hl` mints `r` and leaves `q`'s alloc rail live, dead,
; undischarged and entangled — a full basis record of the wire standing beside a
; non-diagonal gate. Increment 4's accept claim ("once the strip has run the
; region holds no live record") is a claim about the region's OWN flag; it says
; nothing about a record the region merely READ. Increment 3's ancestor walk is
; what closes that, at the late post-uncompute slot where discharge is an
; emitter-recorded fact rather than a prediction.
;
; IF THIS FILE EVER SHOWS `opt` EXIT 0, the lift converted a masked severance
; into a live over-accept — the exact defect the Increment-1 round measured for
; the clone-return rail. The two other severance pins are unmoved and are NOT
; interchangeable evidence: lowering_reject_live_record_switch_mux_out_masked.ll
; declines in `SwitchClassify` (`control flow`) and
; lowering_reject_live_record_valuearm_merge_out_masked.ll on the value-arm path
; (`value-arm swap-route`); neither ever carried lom0's message, and both are
; byte-identical across Increment 4.
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
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
@off = global i32 3, align 4

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %o = load volatile i32, ptr @off, align 4
  %r = mul nsw i32 %o, %q                                      ; the ROUTED BASE
  %c = icmp eq i32 %r, 5
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %merge

merge:
  %w = call i32 @cq_theta_si32(i32 %r, double 2.500000e-01)
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; WARN: warning{{.*}}in function slice{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate).
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero and the gate is in the stream:
; LOWER-LABEL: define{{.*}}@slice(
; LOWER: call void @cqrt_ry_i32(i32 %h_op, double 2.500000e-01)
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(i32 %h)
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.