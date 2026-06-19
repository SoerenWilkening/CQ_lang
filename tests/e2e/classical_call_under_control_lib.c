/* classical_call_under_control_lib.c — the CLASSICAL library translation unit for
   the Phase 6.5 e2e golden (test_C_libtooling-mvna.11, WI-5.7). Like
   specialize_lib.c it must compile WITHOUT the CQ.h intrinsic surface (C18 —
   run_slice_multi.sh applies `-include CQ.h` to the CQ TU only); the tripwire
   below fails LOUDLY at compile if the harness ever force-includes CQ.h into a lib
   TU rather than silently producing a wrong artifact.

   `ext_f` is the body 6.5 routes under control: a VISIBLE, PURELY-CLASSICAL,
   side-effect-free i32 helper. clang -O1 infers `memory(none)` (readnone) +
   nounwind + willreturn, so `classifyClassicalCallArm` proves it pure (the inert-
   hoist precondition, §2.13). Its argument at the call site is the CLASSICAL
   constant 7, so NO taint reaches it — this is route-merge (6.5), not clone-on-
   taint. `ext_f(7) = 107` is the value the merge materializes into a fresh rail
   (`cqrt_alloc_i32(107)`); the call itself runs classically and emits NO trace
   line (only the cqrt_ and cq_template_ symbols print). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int ext_f(int a) {
    return a + 100;
}
