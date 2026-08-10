; lowering_reject_uncompute_premeasure_taped.ll — DECLINE. Third sibling of
; lowering_reject_uncompute_uninvertible_taped.ll (bd 261j(a) mechanism family).
;
; `lowering_uncompute_dead_sibling_premeasure.ll`'s shape — a dead template terminal
; `%dead = q + 7` whose register lineage is LATER measured through the upstream
; handle `%q` — PLUS a tape write on `%dead`. The tape write makes `%dead` recorded,
; so the freeze engages; the measured-lineage reject must fire first and unchanged.
;
; This one is a weaker discriminator than its two siblings and is here as a
; REGRESSION pin rather than a proof: `MeasuredUpstream` is set during recovery from
; the rail's user scan, not from `D.Calls`, so even a prune-based freeze would still
; hit it. What it pins is that the freeze does not REORDER the driver's checks —
; a measured lineage stays a LOUD reject (Rules 5/6: freeing a register a user
; measurement still reads is a hidden collapse), and never degrades into the silent
; "left allocated" outcome a freeze produces. The two failure modes look identical
; in the IR (nothing emitted) and are told apart ONLY by the exit code and this
; message, which is precisely why it is worth a fixture.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define i32 @slice(i32 %x) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %dead = add i32 %q, 7                                      ; tainted template terminal
  %r    = call i32 (ptr, ...) @printf(ptr @.str, i32 %dead)  ; RECORDED onto the kept tape
  %m    = call i32 @cq_measure_si32(i32 %q)                  ; measures the register upstream
  ret i32 %m
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
