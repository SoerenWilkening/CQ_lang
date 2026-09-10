/* m02 — AREA 1: a GUARDED STORE arm under a bare rail condition in the round-2
   window (GuardedStoreArmEmit is not one of the four recording sites). */
int ext_f(int a);
static int arr[8];
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    if (b) arr[q & 7] = 3;
    return cq_measure(arr[q & 7]) + cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
