/* slice_qram_local_store_measured_index.c — bd test_C_libtooling-01po.4 e2e golden.
 *
 * A local array in a NON-main helper: `arr[b] = 0; v = arr[p];`, then a chained
 * cq_theta on the STORE's index `b`, then both `b` and `v` measured. The measured
 * load result is copied out to a kept carrier and its DAG reversed — and the
 * whole-DAG walk used to follow the array into its store, reach `b`, find it
 * measured and decline the module ("cq uncompute: dead chain would free a measured
 * register"), although the same body lowers in main.
 *
 * Golden contract: the module lowers. The load is reversed against the UNCHANGED
 * array and index (`cqrt_qram_load_i32_unc`) right after the copy-out and its rail
 * freed; the index `p`'s Ry is reverse-played (p left allocated); the STORE is not
 * reversed and the array keeps its cells (the owner-deferred array-record class,
 * as main does); `b` is never touched by the spine. */
#include "CQ.h"

__attribute__((noinline)) static int local_store_measured_index(_Bool u0, _Bool u1) {
    int arr[8] = {0};
    _Bool b = u0; cq_theta(&b, 0.5);
    arr[b] = 0;
    _Bool p = u1; cq_theta(&p, 0.5);
    int v = arr[p];
    cq_theta(&b, -0.5);
    return cq_measure(b) + cq_measure(v);
}

int main(int argc, char **argv) {
    (void)argv;
    return local_store_measured_index(argc > 1, argc > 2);
}
