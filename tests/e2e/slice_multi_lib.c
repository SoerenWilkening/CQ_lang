/* slice_multi_lib.c — a CLASSICAL library translation unit for the multi-file
   harness smoke (Phase 6 DD-6). It must compile WITHOUT the CQ.h intrinsic
   surface: C18 requires run_slice_multi.sh / cqc to apply `-include CQ.h` to the
   CQ TU ONLY, never to a classical lib (else the lib's stock arithmetic would
   taint-lower spuriously).

   The #error below is a PERMANENT compile-time tripwire for exactly that trap:
   if the harness ever force-includes CQ.h into a lib TU, `cq_theta` becomes a
   macro and this fixture fails LOUDLY at compile rather than silently producing
   a wrong artifact. Under correct (no-CQ.h) compilation it is plain C. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int lib_bias(void) { return 0; }
