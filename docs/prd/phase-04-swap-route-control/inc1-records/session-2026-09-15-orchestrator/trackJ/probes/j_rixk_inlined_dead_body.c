/* j_rixk_inlined_dead_body.c — bd `test_C_libtooling-rixk`, the reproducer.
   VERBATIM COPY of session-2026-09-14c/trackI/probes/w1_flat_prep_only.c.

   Eleven lines of C with NO LOOP. `-O1` inlines `slice` into `main` AND KEEPS
   the out-of-line body (external linkage, and the call is dropped because the
   result is unused), so the module has SIX static `cqrt_alloc` sites and THREE
   executed allocations.

   BEFORE (shipped checker):  6 rail mint(s) of which 6 left allocated
   AFTER  (this session):     3 rail mint(s) of which 3 left allocated
   EXECUTED (`./a | grep -c cqrt_alloc`): 3

   Both measured on the session ORACLE cq-opt 0e280fc62a91cec2. */

/* w1_flat_prep_only.c — the FLAT twin candidate for the L-1a byte-identity gate.
   Three scalar `_Bool`s, an unconditional prep on each, three measurements.
   EVERY TRIP IS IDENTICAL BY CONSTRUCTION, which is the property SCOPE_L1a §5
   says the byte-identity gate "must therefore be built on". */
int slice(void) {
    _Bool b0 = 0, b1 = 0, b2 = 0;
    b0 = cq_theta(b0, 0.5);
    b1 = cq_theta(b1, 0.5);
    b2 = cq_theta(b2, 0.5);
    return (int) cq_measure(b0) + (int) cq_measure(b1) + (int) cq_measure(b2);
}
int main(void) { (void) slice(); return 0; }
