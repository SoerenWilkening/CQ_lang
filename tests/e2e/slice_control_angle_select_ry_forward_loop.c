/* slice_control_angle_select_ry_forward_loop.c — an Ry ANGLE SELECT on `r`,
   then a classically-bounded loop that rotates the SAME rail every trip, at the
   LINK layer (bd test_C_libtooling-3paw).

   Before 3paw this declined `control flow inside a loop body under quantum
   control`: `lowerLoops`' Case-A collapse re-spells the loop's post-gate names
   of `r` as the rail's root mint, which is also the select's base, and the
   angle-select classifier read them as pre-gate members of the base's wire.
   IR-level pins: `control_angle_select_forward_rail_cycle_frozen.ll` (accept)
   and its two decline twins named in that header.

   THE CIRCUIT. `r` gets Ry(.25), then Ry(.9) on q == 5 and Ry(.3) otherwise
   (by difference: ry(r, .3); flag f = (q == 5); cRy(f, r, fl(.9 - .3)); strip;
   free f), then Ry(.1) on every one of the n + 1 = 3 trips, on the same handle.
   `cq_n` is volatile so the trip count is a run-time value and the loop stays
   rolled in the lowered IR (the trace shows the three dynamic executions).

   THE WITNESS is the twin gate `e2e-angle-select-ry-forward-loop-twin-identical`:
   this golden must be byte-identical to
   `slice_control_angle_select_ry_forward_loop_unrolled_twin.c`'s, which writes
   the by-difference diamond and the three loop gates by hand and lowered on the
   compiler before 3paw. STRICT stage 2b (the flag is the only free). */
volatile int cq_n = 2;

int slice(void) {
    int q = 3;
    int r = 7;
    int n = cq_n;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    cq_theta(&r, (q == 5) ? 0.9 : 0.3);            /* the angle select */
    for (int i = 0; i <= n; i++) cq_theta(&r, 0.1); /* forward gate, rolled */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
