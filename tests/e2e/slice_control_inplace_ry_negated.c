/* slice_control_inplace_ry_negated.c — the FALSE-SUCCESSOR polarity of the
   control-in-place rotation arm (Rule 9; bd test_C_libtooling-drbq Inc 1).

   SOURCE INTENT — identical to slice_control_inplace_ry.c except the condition:
       if (q != 5) r = cq_theta(r, 0.9);

   `clang -O1` canonicalizes `!=` to `icmp eq` and SWAPS the branch successors, so
   the gate arm is the FALSE one and the gate must fire on the NEGATED flag. The
   in-place emitter brackets it in the self-inverse `cqrt_x(flag)` pair — the SAME
   bracket the swap route puts around a negated route, so the two spellings of
   "fires on not-f" cannot drift.

   THE BRACKET IS A PAIR, and the golden is what witnesses that: a stray single
   `cqrt_x` would leave the flag INVERTED when `icmp_eq_i32_hl_unc` recomputes
   `q == 5`, so the strip would XOR 1 onto a flag holding 1's complement and the
   `cqrt_free` would reset a rail holding |1> — a hidden measurement of an
   entangled ancilla (Rule 6). The trace shows both X's around the one controlled
   gate.

   Trace-only runtime, flattened CFG: every gate fires unconditionally, so the
   trace is deterministic regardless of q. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    if (q != 5) {                  /* -> icmp eq + swapped successors (Rule 9) */
        r = cq_theta(r, 0.9);      /* the arm Ry, fired on NOT-flag            */
    }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
