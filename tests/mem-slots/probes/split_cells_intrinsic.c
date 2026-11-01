#include "CQ.h"
/* cq-597j, 90's memcpy_quantum_len: -O1 initializes the byte cells of d by one punned i32 store (split into a
   seed per cell) and a quantum-length memcpy and memset write cells 0..2 through writeSlotCells. (a) the
   guarded old-value read and d[3]'s read forward from the split store's per-cell seeds (was an internal error);
   (b) d is not a dynamic slot array, so the four seeds are freed (were kept). */
#define _FORTIFY_SOURCE 0
#include <string.h>
int split_cells_intrinsic(unsigned x0, double th, const unsigned char *src) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[4] = {9, 9, 9, 9};
    memcpy(d, src, x & 3);
    memset(d, 0, (x >> 2) & 3);
    return cq_measure(d[0] + d[3]);
}
