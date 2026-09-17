/* PART B — the hoisted rail is read in the loop AND AFTER it.  The loop-exit
   anchor must NOT discharge a rail that is still live: a `mul_..._unc` before
   the trailing read would zero the rail the read then consumes. */
int slice(void) {
    int a = 0;
    a = cq_theta(a, 0.5);
    int p = a * 3;
    int s = 0;
    for (int i = 0; i < 2; ++i) s += cq_measure((p >> i) & 1);
    s += cq_measure((p >> 8) & 1);
    return s + cq_measure(a);
}
int main(void) { return slice(); }
