/* guarded store + a blind-visible staler on the CONDITION wire before the guard */
__attribute__((noinline))
static int guarded_local(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);
    int q2 = cq_theta(q, 0.9);
    int i = cq_theta(seed + 1, 0.5);
    if (q < 3) { arr[i] = 7; }
    int v = arr[q2];
    return cq_measure(v);
}
int main(void) { return guarded_local(0); }
