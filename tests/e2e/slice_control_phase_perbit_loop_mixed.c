/* slice_control_phase_perbit_loop_mixed.c — bd test_C_libtooling-3qlq Increment 1,
   the Rule-13 CLEARANCE finding **C-1** (the BLOCK verdict, 2026-09-05).

   THE MIXED LOOP: D4's per-bit idiom on a loop-INVARIANT condition register,
   inside a loop that ALSO CARRIES a second tainted register.

       int q = cq_theta(u, 0.5);            // INVARIANT: the body gates nothing on it
       int r = cq_theta(u, 0.3);            // CARRIED:   rotated once per trip
       for (int i = 0; i < 3; i++) {
           if ((q >> i) & 1) cq_phi(0.2);   // D4's per-bit kickback
           cq_theta(&r, 0.1);            // the ancilla
       }
       cq_theta(&q, 0.9);                // the DIFFUSION — this is what makes
       return cq_measure(q) + cq_measure(r);//   a leaked bit rail a WRONG UNITARY

   WHAT IT MEASURES, AND WHY IT EXISTS. `slice_control_phase_perbit_loop.c` has
   no carried register, so `collapseRailPhisIn` returns `NotClaimed` and the
   round-1 F-L5-1 fix (`invariantRegisterRoots`) supplies `q` as a Root. Add ONE
   ancilla rotation to the body and the SAME loop returns `Collapsed` instead —
   and the `Collapsed` branch used to hand `markIfRailLocal` the carried root
   ALONE, whose "accumulating loop-invariant tainted input" clause then refused on
   `q`. Nothing was marked, and the body's three `cq_template_and_i32_hl` bit
   rails were minted and NEVER `_unc`-reversed, never freed. MEASURED at 542d588:
   `and_i32_hl` 3 / `and_i32_hl_unc` **0**, at `opt` exit 0, verify-clean and
   STRICT stage 2b `0 violation(s)` — the checker is structurally blind to a
   leaked TEMPLATE-minted rail, as its own header says.

   Three live records of `q`'s low bits then survive into `cqrt_ry_i32(h0, 0.9)`,
   which mixes `x` with `x ^ 2^i` on branches carrying DISTINCT ancilla labels:
   their interference is destroyed (Rule 8). The hand-unrolled twin — the
   program's meaning — discharged all three, and so did the pre-3qlq oracle on the
   register-surface spelling of the same source (rolled == unrolled, 37 = 37).

   THE FIX (`LoopLowering::collapseFlattenedLoopRails`): on `Collapsed`, ALSO
   collect the loop-INVARIANT roots — into a separate set, unioned only on
   success — with `invariantRegisterRoots` skipping any candidate the collapse
   already owns. The proof is clause (ii)'s own (I1) argument, unwidened.

   THE WITNESS is BYTE IDENTITY with `slice_control_phase_perbit_loop_mixed_unrolled.c`;
   the gate is `e2e-phase-perbit-loop-mixed-twin-identical`. Per trip the trace
   must read: and_hl -> icmp_eq_hl mint -> x -> cqrt_rz_i1(flag, 0.2) -> x ->
   icmp_eq_hl_unc strip -> and_hl_unc -> free(bit rail) -> free(flag) ->
   cqrt_ry_i32(r, 0.1). Three trips, then the diffusion and the two measures.
   No cswap, no work rail, no `_controlled`, and the ONLY Rz width is i1.

   PRE-INCREMENT DISPOSITION: the pre-fix SUBJECT (542d588) ACCEPTS this program
   and emits the 31-line LEAKING trace above; the pre-3qlq ORACLE (52d7764)
   DECLINES the void-`cq_phi` spelling outright
   (`cq controlled lowering: control flow under quantum control`, as for every
   P6 slice). Measured 2026-09-05.
   Class: PRD §6.2 P6 (P1 inside the 8h7d.5 rolled loop), mixed-register variant. */

int slice(int u) {
    int q = u; cq_theta(&q, 0.5);
    int r = u; cq_theta(&r, 0.3);

    for (int i = 0; i < 3; ++i) {
        if ((q >> i) & 1) cq_phi(0.2);
        cq_theta(&r, 0.1);
    }

    cq_theta(&q, 0.9);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(5); return 0; }
