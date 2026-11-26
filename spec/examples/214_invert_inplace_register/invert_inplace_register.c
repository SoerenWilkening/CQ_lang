/* Rule 17 with rule 6 (owner 2026-11-26): inside a cq_invert region an in-place add or xor of a register is one gate on
   its rail, recorded and reversed at the end; after the region the register is that rail with what the reversed gates
   left. A memory cell's in-place form beside it inverts the same way. */
typedef unsigned char u8;
/* Two items of a knapsack state preparation (PREP) and its adjoint: the region returns rem and profit to their values
   before the first PREP, and its Ry's are PREP's, reversed, with PREP's predicates. */
#define PREP                                         \
    if (rem >= 5) cq_theta(&x0, t);                  \
    rem -= x0 ? 5 : 0;                               \
    profit += x0 ? 18 : 0;                           \
    if (rem >= 9) cq_theta(&x1, t);                  \
    rem -= x1 ? 9 : 0;                               \
    profit += x1 ? 27 : 0;
int invert_prepare(u8 r0, double tr, u8 p0, double tp, double t, double p) {
    bool x0 = 0, x1 = 0;
    u8 rem = r0, profit = p0;
    cq_theta(&rem, tr);
    cq_theta(&profit, tp);
    PREP
    if (profit > 40) cq_phi(p);                      /* the oracle: it pins PREP's profit before the region */
    cq_invert_begin();
    PREP
    cq_invert_end();
    return cq_measure(rem) + cq_measure(profit) + cq_measure(x0) + cq_measure(x1);
}
/* The old value has a reader after the update (t and a are one SSA value): the update is in place all the same, the
   region's reader reads a copy taken before the gate, and t after the end is the register. */
int invert_old_value(unsigned a0, double ta, unsigned w, unsigned k, double p, double q) {
    unsigned a = a0;
    cq_theta(&a, ta);
    unsigned t = a;
    cq_invert_begin();
    a += w;
    if (a * t == k) cq_phi(p);                       /* reads the image and the old value */
    cq_invert_end();
    if (t == k) cq_phi(q);
    return cq_measure(a);
}
/* A bus cell and a register updated in place by the same operand in one region. */
unsigned g;
unsigned invert_cell(unsigned x0, double tx, unsigned r0, double tr) {
    unsigned x = x0, r = r0;
    cq_theta(&x, tx);
    cq_theta(&r, tr);
    cq_invert_begin();
    g += x;
    r ^= x;
    cq_invert_end();
    return cq_measure(r) + cq_measure(x);
}
