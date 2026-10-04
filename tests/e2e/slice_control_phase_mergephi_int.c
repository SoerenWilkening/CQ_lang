/* slice_control_phase_mergephi_int.c — bd `3qps` (Track P). THE `int` TWIN of
   `slice_control_phase_mergephi.c`, and it is a MUST-NOT-MOVE pin.

   The only difference is `int b1` instead of `_Bool b1`. That spelling ALREADY
   lowered on the frozen ORACLE (`59ac5b7`) — with a COMPARE over the very same
   merge phi — which is the measurement that proved bd `3qps` was a LEAF-GRAMMAR
   over-decline rather than a wire or physics wall: gate 2c and the kickback's
   wire fence had both already answered CLEAN on this register.

   It is also the spelling the owner refused in as many words ("WE DO NOT WANT TO
   WRITE `int b1`"), so its golden is pinned here to prove the widening did not
   disturb the workaround it replaces.

   The stream differs from the `_Bool` one in exactly the way Rule 7 predicts: an
   `int` condition is a COMPARE, so a flag IS minted (`cq_template_icmp_eq_i32_hl`),
   the kickback rides that ANCILLA with a `cqrt_x` bracket for the negated arm,
   and the flag is stripped and freed. The `_Bool` spelling needs none of that —
   the register is its own flag. */
int slice(void) {
    int a = 5;
    _Bool b0 = 0;
    int  b1 = 0;

    if (a >= 3){
        cq_theta(&b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    if (a >= 3){
        cq_theta(&b1, 0.5);
    }
    if (b1) cq_phi(0.3);

    return (int) cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
