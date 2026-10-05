; lowering_reject_live_record_post_theta_user_rz.ll — WARNING (was DECLINE) (owner ruling
; 2026-08-28 on the Rule-13 round's F2 finding, bd test_C_libtooling-6uqc). This
; file was the PENDING-RULING accept pin `..._post_theta_user_rz_accept.ll`; the
; ruling came down for the ENUMERATED data-use list, so it is now the negative.
; It is the pin of `RotationLowering`'s F2 boundary (`isTeardownUse`'s rotation
; row and the observing-sink walk's "ALL rotations are non-uses").
;
; SOURCE (`clang -O1` emits exactly the SSA below; attribute groups and metadata
; trimmed):
;
;     int main(void) {
;       int a = 1; cq_theta(&a, 0.5);
;       int c = a + 3;          // ONE record of the wire
;       cq_theta(&a, 0.7);      // T — chained, in-place Ry
;       cq_theta(&c, 1.0);      // a USER rotation naming the record AFTER T — and NOTHING observes c
;       return cq_measure(a);
;     }
;     int observed(void) { ...the same..., then return cq_measure(a) + cq_measure(c); }
;
; THE RULING: a bare post-gate ROTATION on a record is NOT a clause-3 data use.
; A record exempts only if its lineage reaches an OBSERVING sink after the gate
; (measure / ret / tape / a template read that flows to one). A rotation written
; onto a register nothing ever observes is unobservable, so it cannot make `%2`
; "the program's own data"; in `@main` `%2` is a dead, undischarged, entangled
; record at `T`, and the module warns — the SAME verdict the rotation-BEFORE
; spelling (`int c = a+3; cq_theta(&c,1.0); cq_theta(&a,0.7);`) gets, for the
; same physics at the gate (a gate on the record disentangles nothing).
;
; WHAT STILL ACCEPTS, so the boundary is not over-read: rotate `c` and then
; MEASURE it (or return/tape it) — `@observed` below, in the same module. The
; measure is an observing sink, `%2` is live user data, and its dephasing of `T`
; is source semantics; the guard is silent on that function (the `WARN-NOT`
; below). lowering_stale_record_add_before_theta.ll is the ruled accept boundary
; without the user rotation.
;
; The message tells the author exactly what to do: measure `c` or drop it.
;
; History: pre-3qlq the user rotation was the register form `c = cq_phi(c, 1.0)`
; (an in-place Rz). The 3qlq migration deleted it as an uncontrolled phase, which
; left only the bare dead record and left the F2 boundary with no pin; bd jttf
; (2026-10-05) re-spelled the user rotation as the in-place Ry above (the ruling
; covers every rotation, so `cqrt_ry` on the record is the same question) and
; added the observed twin so the boundary is pinned from both sides.
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
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #2
  %2 = add nsw i32 %1, 3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.000000e+00) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  ret i32 %5
}

define i32 @observed() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #2
  %2 = add nsw i32 %1, 3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.000000e+00) #2
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %6 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

; WARN: warning{{.*}}in function main{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; ONE report per offending GATE, never per record (the message carries the
; gate's !dbg, so a second record on the same rotation would print a duplicate),
; and NONE for `@observed`:
; WARN-NOT: warning
;
; THE PROGRAM LOWERS. `opt` exits zero; T and the user rotation are both in the
; stream, the record's rail is never reversed:
; LOWER-LABEL: define{{.*}}@main(
; LOWER:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; LOWER-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 0x3FE6666666666666)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %[[C]], double 1.000000e+00)
; LOWER-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; LOWER-NEXT: ret i32 %[[M]]
; LOWER-LABEL: define{{.*}}@observed(
; LOWER:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; LOWER-NEXT: %[[C2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H2]], i32 3)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 0x3FE6666666666666)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %[[C2]], double 1.000000e+00)
; LOWER-NEXT: call i32 @cqrt_measure_i32(i32 %[[H2]])
; LOWER-NEXT: call i32 @cqrt_measure_i32(i32 %[[C2]])
; and the record is LEFT ALLOCATED — never freed dirty (Rule 6), which is the
; whole of what the ruling changes about the emitted circuit.
; NOFREEREC-NOT: call void @cqrt_free(
; It is its OWN prefix, with no positive directive, so its window is the
; WHOLE lowered module rather than the span after the gate — a free emitted
; BEFORE the rotation would be caught too. That is also the spelling
; tools/fixture_guard_liveness.py recognizes (`NOFREE*`), which counts it as
; unanchored-and-therefore-not-dead rather than passing over it in silence.
