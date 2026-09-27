/* spec_dropped_arg_volatile_global_lib.c — the CLASSICAL library TU for the bd
   test_C_libtooling-vsfp ROUND-3 golden slice_spec_dropped_arg_volatile_global.c (bd
   test_C_libtooling-stl3 / bd test_C_libtooling-tzfa; Rule-13 r2B F-WB-1/F-WB-2, probe
   `k19`). Compiles WITHOUT the CQ.h intrinsic surface (C18); the tripwire below fails
   LOUDLY at compile if the harness ever force-includes CQ.h into a lib TU.

   `h`'s only read of `a` is the condition of an arm that reads a never-stored
   internal `volatile` global. The volatile-const global fold folds that load to its
   initializer; before bd vsfp round 3 it left the EMPTIED diamond standing, so `a`
   stayed branch-live, the dead-argument drop could not predict the slot, the clone's
   own flatten killed the read, and round 2's backstop ACCEPTED the phantom read
   because the operand had another reader — leaving the uncompute spine one consumer
   too many, so the caller's template rail `3q` was never uncomputed (a Rule-8 wrong
   unitary: `q` fully dephased across its phase oracle). Round 3 folds the emptied arm
   (bd stl3), so the drop's slot B rewrites the call to `h(0, m)`. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

static volatile int K = 7;

int h(int a, int k) {
    if (a > 3)
        (void)K;
    return k + 1;
}
