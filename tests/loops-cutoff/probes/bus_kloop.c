/* Rule 14 over the bus: every bus access of a K-loop trip is under its trip predicate. Each entry is checked §6 against
 * its own C program. Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h bus_kloop.c */
/* Exit read of the loaded value: a region value is not frozen after the exit. */
int scan_gt(int x0, double t, int n) {
    int x = x0;
    cq_theta(&x, t);
    int a[6];
    for (int i = 0; i < 6; i++) a[i] = (n + i + x) & 7;
    int *p = a, c;
    while ((c = *p) > 3) p++;
    return cq_measure(c);
}
/* A loop whose exit tests a rail indexes a host-resident array: the read in a trip C would not run stays out of memory. */
int local_read(int x0, double t, int n) {
    int x = x0;
    cq_theta(&x, t);
    int c[4];
    for (int i = 0; i < 4; i++) c[i] = n * i + 1;
    int s = 0;
    for (int i = 0; i < (x & 7); i++) s += c[i & 3];
    return cq_measure(s);
}
/* do-while with a loaded latch test. */
int do_scan(int x0, double t, int n) {
    int x = x0;
    cq_theta(&x, t);
    int a[6];
    for (int i = 0; i < 6; i++) a[i] = (x + i * n) & 3;
    int s = 0, i = 0;
    do { s += i; i++; } while (a[i]);
    return cq_measure(s);
}
/* A controlled store in each trip, read back after the loop. */
int fill_until(int x0, double t, int n) {
    int x = x0;
    cq_theta(&x, t);
    int a[8];
    for (int i = 0; i < 8; i++) a[i] = x - i;
    for (int i = 0; i < (x & 7); i++) a[i] = n + i;
    return cq_measure(a[x & 3]);
}
/* A pointer chase over a local list: the carried pointer is an i64 rail seeded by its classical start. */
struct bk_node { int v; struct bk_node *next; };
int chase(int x0, double t, int key) {
    int x = x0;
    cq_theta(&x, t);
    struct bk_node c = {x & 3, 0}, b = {x & 1, &c}, a = {x & 2, &b};
    struct bk_node *p = &a;
    int i = 0;
    while (p) {
        if (p->v == key) break;
        p = p->next;
        i++;
    }
    return cq_measure(i);
}
/* Classical bound: a load copy of a trip is overtaken by the next trip's store. */
int cb_overtaken(int x0, double t, int n) {
    int x = x0;
    cq_theta(&x, t);
    int a[6];
    a[0] = x;
    int s = 0;
    for (int i = 0; i < (n & 3) + 1; i++) {
        int v = a[i];
        s += v;
        a[i + 1] = s + 1;
    }
    return cq_measure(s);
}
/* Classical bound and a quantum exit tested on a loaded value (117's shape, ruling Q15). */
int cb_qexit(int x0, double t, int n) {
    int x = x0;
    cq_theta(&x, t);
    int a[4];
    for (int i = 0; i < 4; i++) a[i] = (x >> i) & 1;
    int r = -1;
    for (int k = 0; k < (n & 3) + 1; k++)
        if (a[k] == 1) { r = k; break; }
    return cq_measure(r);
}
