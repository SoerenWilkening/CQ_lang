/* slice_control_inplace_ry_loop_ifelse.c — the if/else of two chained Ry on ONE
   register, ROLLED inside a classically-bounded loop (bd test_C_libtooling-fmt3,
   2026-09-28).

   ⚠ THIS IS AN ACCEPT THAT fmt3 CREATED, NOT ONE IT WAS ASKED FOR — read why.
   Before fmt3, `-O1` merged the two arm calls into ONE `cq_theta` with a
   tainted-condition SELECT on the angle; an angle select on a cycle is refused
   (`classifyAngleSelect` S7), so this program DECLINED `control flow inside a
   loop body` (measured on the frozen oracle `9a230646` with the pre-fmt3 header).
   fmt3 put `nomerge` on every `cq_theta_*` (owner ruling, option B), so the
   if/else survives and reaches the drbq Inc-3 ROLLED in-place Ry arm, whose
   if/else form was until now reachable only from hand IR
   (`control_inplace_ry_inloop_ifelse.ll`). Per trip it emits
       f = cmp; cRy(f, r, 0.9); X f; cRy(f, r, 0.3); X f; strip; free
   — the flag's X pair on the compare ANCILLA only.

   THE WITNESS is `e2e-inplace-ry-loop-ifelse-twin-identical`: this ROLLED golden
   is byte-identical to the hand-unrolled twin
   `slice_control_inplace_ry_loop_ifelse_unrolled.c`, whose three flat if/else
   regions lower through the same Rule-13-cleared flat emitter. The condition
   register `q` is re-rotated every trip, so the condition is loop-VARIANT (the
   LICM-hoisted form declines, CLAUDE.md §2 P4), and `r` is the loop-carried
   in-place rail. STRICT stage 2b. */
int slice(void) {
    int q = 0;
    int r = 7;

    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);

    for (int i = 0; i < 3; ++i) {
        if ((q & 6) == 4) cq_theta(&r, 0.9);
        else              cq_theta(&r, 0.3);
        cq_theta(&q, 0.1);
    }

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
