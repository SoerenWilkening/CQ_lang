/* slice_control_grover_loop_two_regs.c — bd test_C_libtooling-8h7d.5 (Rule-13
   round 1, finding OD1) e2e: TWO INDEPENDENT QUANTUM REGISTERS, each with its own
   tainted `if`, inside ONE classically-bounded loop.

   THIS SHAPE DID NOT COMPILE AT ba35c1f. It declined with

       cq controlled lowering: condition predates a non-diagonal gate under quantum control

   and the reason had nothing to do with either register: `WireWalk::phiTracksWire`
   — the fence that decides whether a loop-header phi may act as the
   record-refresh barrier — asked whether ANY `cq_theta` sat between an incoming
   and its edge, regardless of which WIRE that theta rotates. With two registers
   in one body, each one's rotations refused the other one's barrier, so neither
   phi could ever be claimed and the whole shape was unreachable. The same
   blindness made the disposition depend on SOURCE ORDER: minting an unrelated
   second register BEFORE the first compiled, minting it AFTER did not.

   The test is now per WIRE (a theta rotates the wire its arg-0 names), which is
   what this slice exercises end to end.

   WHAT THE TRACE SHOWS, and why it is the witness (Rule 2 — no simulator): the
   two per-register streams interleaved in SOURCE order on two handles. Gates on
   distinct wires commute, so this is the same circuit as the hand-unrolled twin
   slice_control_grover_loop_two_regs_unrolled.c — byte-identical goldens, `cmp`'d
   in ctest (e2e-grover-loop-two-regs-twin-identical). Every ancilla (two flags,
   two work rails per trip) is minted, stripped and freed inside its own
   iteration; the only rails left allocated are the two measured registers.
   STRICT stage 2b (no `--allow-unproven`).

   THE OTHER HALF OF THE GROUPING RULE has no e2e twin because it declines: two
   rail chains rooted at the SAME mint (`int a = q, b = q;` — an alias, Rule 8)
   are ONE physical register and must interfere, which is
   ir-pass/test/lowering_reject_inloop_rail_alias_shared_mint.ll. */
#define CQ_PI 3.14159265358979323846
int slice(void) {
    int a = 0, b = 0;
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.25);
    for (int i = 0; i < 2; ++i) {
        if (a == 5) {
            a = cq_phi(a, CQ_PI);
        }
        if (b == 3) {
            b = cq_phi(b, CQ_PI);
        }
        a = cq_theta(a, -0.5);
        b = cq_theta(b, -0.25);
        a = cq_theta(a, 0.5);
        b = cq_theta(b, 0.25);
    }
    return cq_measure(a) + cq_measure(b);
}
int main(void) { (void) slice(); return 0; }
