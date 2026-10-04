/* slice_control_value_polarity.c — e2e smoke for the NEGATED-POLARITY value
   diamond, and the subject of `e2e-value-polarity-twin-identical`; its twin is
   slice_control_value_polarity_twin.c.

   `if (q != 5) { … }`. `clang -O1` canonicalises that to `icmp eq i32 %q, 5`
   with the successors SWAPPED (Rule 9), so the gate arm is the FALSE successor
   and the region arrives with `ArmNegated` set. `emitValueRegion` then has to
   put the arm value in the select's FALSE slot (`TrueVal = Q`) — a select always
   means "the true operand when the flag is 1", so a swapped pair here would
   produce `out = f ? R(p) : p` for a program that means `out = f ? p : R(p)`:
   the arm fires on exactly the wrong half of the superposition.

   WHY THIS PAIR EXISTS (Inc-2 Rule-13 round-1 review, finding F-V1-7).
   `control_swap_value_diamond_polarity.ll` pins the emitted SYMBOLS for this
   shape, but symbols cannot see an operand swap: the multiset
   `{copy_controlled, x, copy_controlled, x}` is identical either way, and so is
   the free/strip pairing that stage 2b checks. Byte identity against the
   PRE-HOISTED SELECT spelling — which reaches the same emitter through its own
   front door with NO polarity decision to make — is the measurement that does
   see it. Six-op chain so `-O1` keeps a real br-diamond. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int p = 7;
    cq_theta(&q, 0.5);
    cq_theta(&p, 0.25);
    if (q != 5) {                  /* -> icmp eq + swapped successors (ArmNegated) */
        p = p + 3;
        p = p * 5;
        p = p ^ 9;
        p = p + 1;
        p = p * 7;
        p = p ^ 2;
    }
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
