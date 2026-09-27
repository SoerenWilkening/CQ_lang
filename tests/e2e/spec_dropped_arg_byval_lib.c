/* spec_dropped_arg_byval_lib.c — the CLASSICAL library TU for the bd vsfp ROUND-5 golden
   slice_spec_dropped_arg_byval_slot.c (bd test_C_libtooling-91k9; Rule-13 r4A probe `bv`).
   Compiles WITHOUT the CQ.h intrinsic surface (C18); the tripwire below fails LOUDLY at compile if
   the harness ever force-includes CQ.h into a lib TU. `h` never reads its `byval` struct. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

struct Big { int x[8]; };

int h(int a, struct Big s) { return a * 3; }
