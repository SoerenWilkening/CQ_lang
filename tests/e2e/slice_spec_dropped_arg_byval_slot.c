/* slice_spec_dropped_arg_byval_slot.c — bd test_C_libtooling-vsfp ROUND 5 / bd
   test_C_libtooling-91k9 (2-TU, run_slice_multi.sh; library TU spec_dropped_arg_byval_lib.c:
   `int h(int a, struct Big s) { return a * 3; }`). Rule-13 r4A F-YA-1, probe `bv`.

   `h` never reads its `byval` struct `s`, so the specializer records that slot dead. Rounds 3-4
   NEUTRALISED it to `null` (`ptr noundef nonnull byval(%struct.Big) align 8 null`) — opt exit 0,
   verifier clean, stage 2b STRICT clean — and the LINKED EXECUTABLE SIGSEGVed (the call site's
   byval copy reads address 0). Round 5 rewrites only the slots the pre-`specialize()` drop's own
   eligibility admits (an int/fp scalar, no `byval`), so the struct is passed as written. This
   slice is the only layer that RUNS the program, which is the layer that saw the crash: its golden
   is byte-identical to the ORACLE's trace (measured), and the harness's `pipefail` fails on a
   crash. `m` comes from argv (argc + 4 under the harness, bd 46oo). */
#include <stdlib.h>
struct Big { int x[8]; };
int h(int a, struct Big s);

__attribute__((noinline)) int slice(int m) {
    struct Big b = {{m, 1, 2, 3, 4, 5, 6, 7}};
    int q = m & 7; cq_theta(&q, 0.5);
    int r = h(q, b);
    return cq_measure(r) + b.x[0];
}

int main(int argc, char **argv) {
    (void)argv;
    (void)slice(argc + 4);
    return 0;
}
