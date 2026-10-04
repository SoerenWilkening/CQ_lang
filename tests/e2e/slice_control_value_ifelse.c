/* slice_control_value_ifelse.c — e2e smoke for the TWO-ARM value if/else
   (retire-swap-route-PRD §7.2 shape V2) under the Inc-2 controlled-copy merge.
   Subject of the `e2e-value-ifelse-twin-identical` gate; its twin is
   slice_control_value_ifelse_twin.c.

       if (q > 5) { p = p+3; p = p*5; p = p^9; p = p+1; p = p*7; p = p^2; }
       else       { p = p+4; p = p*3; p = p^6; p = p+2; p = p*9; p = p^1; }

   BOTH arms carry a pure value chain over the same base `p` (base-identity).
   Both chains are HOISTED into the pred and run unconditionally; the merge is
   `out ^= f . R1(p)` then, X-bracketed, `out ^= (not f) . R2(p)` — no work rail,
   no `cqrt_cswap`, no reverse-play. Six ops per arm because a shorter arm folds
   to a tainted select at -O1 (SimplifyCFG speculation), which is 4.4 territory.
   EXACTLY ONE `cqrt_free` (the flag): `p`, `out` and both chain finals are left
   allocated (keep-source-live — every one of them is a function of `p`, which is
   itself kept, so nothing new is recorded; freeing any is a hidden measurement).
   Pre-3qlq this program emitted 54 trace lines through the swap route (two work
   rails, eight cswaps, an uncontrolled copy-out and two reverse-plays); it now
   emits 33. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int p = 7;
    cq_theta(&q, 0.5);
    cq_theta(&p, 0.25);
    if (q > 5) { p = p + 3; p = p * 5; p = p ^ 9; p = p + 1; p = p * 7; p = p ^ 2; }
    else       { p = p + 4; p = p * 3; p = p ^ 6; p = p + 2; p = p * 9; p = p ^ 1; }
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
