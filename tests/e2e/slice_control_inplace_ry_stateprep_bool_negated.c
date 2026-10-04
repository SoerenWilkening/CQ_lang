/* slice_control_inplace_ry_stateprep_bool_negated.c — THE POLARITY TWIN of
   `slice_control_inplace_ry_stateprep_bool.c` (bd `drbq.14`, the 2026-09-11
   owner ruling; F2's `CondWire` narrowing).

   Identical source with ONE token changed, `==` to `!=`. It exists because
   `clang -O1` CANONICALISES an inequality diamond (Rule 9): the compare is
   emitted as `icmp eq` and the ARM becomes the FALSE successor, so the emitter
   must control on `!flag` — which it does with a self-inverse `cqrt_x` BRACKET
   around the arm gate, NOT by minting a second flag or by inverting the
   predicate.

   READ THE GOLDEN AGAINST THE `==` TWIN'S: the two are the same nine lines plus
   TWO `cqrt_x(h1)` calls, one on each side of the controlled gate. Everything
   else is byte-identical in shape — same compare, same `_unc` strip with the
   SAME operands, same single `cqrt_free`, same frozen prepped rail. That is the
   whole of polarity handling, and it is where a polarity bug would show: an
   UNPAIRED `cqrt_x` leaves the flag inverted at the strip, so the `_unc` does
   not return it to |0> and line 7 becomes a dirty free. The pair is the
   assertion.

   ⚠ THE STRIP IS COMPUTED ON THE *UNBRACKETED* FLAG. The second `cqrt_x`
   precedes the `_unc`, so by the time the strip runs the flag again holds the
   compare's own value — which is what makes `cq_template_icmp_eq_i32_hl_unc`
   with the source compare's operands the correct adjoint. Reading the two `x`
   calls as "an inverted flag" and the strip as "the inverse predicate" would be
   two mistakes that cancel on paper and not in the circuit.

   Everything the `==` twin's header says about what this golden does and does
   NOT witness (no trace can answer a STATE question; stage 2b never reads the
   alloc's seed) applies here verbatim. */
int slice(void) {
    int  q = 0; cq_theta(&q, 0.5); /* the condition register                    */
    _Bool r = 0;                   /* the `_Bool` seed — F2's old collider       */
    if (q != 1) {                  /* `-O1` emits `icmp eq` + a FALSE-arm branch */
        cq_theta(&r, 0.9);         /* `r` is classically 0 here: a STATE PREP    */
    }
    return (int) cq_measure(q) + (int) cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
