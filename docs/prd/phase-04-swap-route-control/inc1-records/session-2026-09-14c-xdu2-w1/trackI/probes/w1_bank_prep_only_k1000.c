/* w1_bank_prep_only.c — the ROLLED half of the same program. Declines
   `cq taint escape: tainted value stored to memory` until L-1a lands. */
int slice(void) {
    _Bool b[1000] = {0};
    for (int i = 0; i < 1000; i++) b[i] = cq_theta(b[i], 0.5);
    int s = 0;
    for (int i = 0; i < 1000; i++) s += (int) cq_measure(b[i]);
    return s;
}
int main(void) { (void) slice(); return 0; }
