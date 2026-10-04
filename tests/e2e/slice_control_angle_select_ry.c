/* slice_control_angle_select_ry.c — ANGLE-SELECT BY DIFFERENCE, Ry stem, at the
   LINK layer (bd test_C_libtooling-drbq Increment 2b; control-in-place-PRD
   §12.3). The only test layer that LINKS, so it proves every emitted symbol
   resolves and signature-matches against the runtime (Rule 2).

   ⚠⚠ SINCE bd test_C_libtooling-fmt3 (2026-09-28) THIS FILE NO LONGER REACHES THE
   ANGLE SELECT, AND EVERYTHING BELOW ABOUT THE FOLD IS HISTORY. `include/CQ.h`
   now puts `nomerge` on every `cq_theta_*` declaration (owner ruling, option B:
   the same SimplifyCFG merge could ERASE a branch and hand the pass a different,
   legitimate-looking program), so `-O1` keeps this if/else as an if/else and it
   lowers through the in-place Ry arm's if/else form:
       flag f = (q == 5); cRy(f, r, 0.9); X f; cRy(f, r, 0.3); X f; strip; free
   — the SAME unitary (f=1: Ry(0.9); f=0: Ry(0.3); the X pair is on the compare
   ANCILLA, never on a user register, and returns it to its value before the
   strip), and it is now EXACT where the by-difference form was 2^-54 rad off.
   The golden was REGENERATED deliberately to that stream (STRICT 2b: 2 verified,
   0 violation). The by-difference stream this header describes, and the twin gate,
   moved WITH the angle-select spelling to `slice_control_angle_select_ry_ternary.c`
   (`cq_theta(&r, (q == 5) ? 0.9 : 0.3);`), whose golden is this file's
   PRE-fmt3 golden byte for byte. Teaching the pass to emit the cheaper
   by-difference form for this if/else too is a follow-up bead, not a defect.

   THE SOURCE IS THE POINT. This is the plain C `if/else` with a rotation on ONE
   register in each arm — the shape the increment exists for:

       if (q == 5) cq_theta(&r, 0.9); else cq_theta(&r, 0.3);

   `clang -O1` NEVER hands that to the pass as a diamond. SimplifyCFG merges the
   two arms into ONE call whose ANGLE is a tainted-condition `select`
   (`select i1 %c, double 0.9, double 0.3` feeding `cq_theta` arg-1), so the
   branch CFG is gone before the pass runs (Rule 9) and no swap-route emitter can
   ever see it. Before 2b this declined `rotation angle under quantum control`.

   THE LOWERING is angle additivity on one axis: `Ry(0.9) = Ry(0.3)·Ry(0.9-0.3)`.
   So the emitted stream is an UNCONDITIONAL `ry(r, 0.3)`, the ordinary flag mint,
   ONE `cqrt_ry_i32_controlled(f, r, fl(0.9-0.3))`, the ordinary `_unc` strip, one
   `cqrt_free`.

   *** THE CONTROLLED ANGLE IS NOT 0.6, AND THE GOLDEN SAYS SO. *** This comment
   used to write it as `Ry(0.6)` / `0.6`; the committed trace emits
   `0x1.3333333333334p-1`, while `fl(0.6)` is `0x1.3333333333333p-1` — one ulp
   apart. `fl(0.9) - fl(0.3)` is not `fl(0.6)`. The realized true-arm angle is
   `0.3 + fl(0.9-0.3)`, which differs from `fl(0.9)` by exactly `2^-54` rad
   (round-1 Rule-13 review, lens L7-F1/F3). That is physically nothing and it is
   the shape this increment exists for — but it is the FIRST INSTANCE of the
   error, so the golden is right and the arithmetic claim has to be written the
   way the golden shows it. No route, no work rail, no `cqrt_x` (a select always means "true
   value when the flag is 1", so there is no polarity case).

   THE FLAG STRIP IS VALID for the same reason the Inc-1 arm's is: the only
   register this stream relabels is `r`, whose rail is disjoint from `q`'s (two
   separate `cq_theta` sources), so `q == q0` at the strip and the flag returns
   to |0> before `cqrt_free` (PRD §3).

   ITS TWIN, `slice_control_angle_select_ry_twin.c`, writes the SAME circuit by
   hand (`cq_theta(&r,0.3); if (q==5) cq_theta(&r, 0.9-0.3);`) — an
   ordinary Inc-1 in-place diamond that the PRE-2b binary already lowered. The
   two goldens are byte-identical and `e2e-angle-select-ry-twin-identical`
   enforces it; that identity, not this trace on its own, is the increment's
   central witness. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    if (q == 5) cq_theta(&r, 0.9);      /* since fmt3 NOT folded: two calls, */
    else        cq_theta(&r, 0.3);      /* one if/else (CQ.h nomerge)         */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
