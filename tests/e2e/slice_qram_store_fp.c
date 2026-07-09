/* slice_qram_store_fp.c — bd 38t2 e2e smoke: an alloca-backed tainted-index fp
 * cell STORE of a COHERENT CARRIER + LOAD (Shadow-shaped, fp element). `arr[q] = x`
 * where `x = cq_theta(...)` is an fp superposition carrier and `q` a tainted integer
 * index, followed by `arr[p]` (a tainted-index fp load), then measured. Lowers
 * COHERENTLY to cqrt_qram_alloc_f64 (array-handle birth) + cqrt_qram_store_f64 (void
 * in-place; the backend owns the per-store tape) + cqrt_qram_load_f64 (Toffoli
 * copy-out), then the loaded value is measured. Storing a theta/phi-derived fp
 * carrier into a memory cell is FAITHFUL reversible QRAM (a CNOT-copy of the fp bit
 * pattern; the phase lives in the joint amplitude — bd
 * [38t2-fp-cell-commits-to-basis-sound]). `main` is resident, so the array/rails are
 * reclaimed at process exit (no reversal is emitted — the escaped/observed case). */
#include "CQ.h"

int main(void) {
    double arr[8] = {0};
    int q = cq_theta(0, 0.5);      /* tainted integer index */
    int p = cq_theta(1, 0.5);      /* tainted integer index */
    double x = cq_theta(7.0, 0.5); /* tainted fp carrier value */
    arr[q] = x;                    /* fp cell store of a carrier — coherent table write */
    double v = arr[p];             /* fp cell load — coherent table read */
    return (int)cq_measure(v);
}
