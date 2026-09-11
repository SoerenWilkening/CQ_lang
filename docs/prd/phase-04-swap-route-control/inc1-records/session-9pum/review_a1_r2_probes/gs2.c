/* guarded store + condition register MEASURED before */
__attribute__((noinline))
static int guarded_local(int seed) {
    int arr[8] = {0};
    int q = cq_theta(seed, 0.5);
    int m = cq_measure(q);
    int i = cq_theta(seed + 1, 0.5);
    if (q < 3) { arr[i] = 7; }
    int v = arr[i];
    return cq_measure(v) + m;
}
int main(void) { return guarded_local(0); }
