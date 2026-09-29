#include <stdlib.h>
int h(int a, int k);
int main(int argc, char **argv) {
    int m = atoi(argv[1]);
    int q = cq_theta(m & 7, 0.5);
    int kq = cq_theta(m & 3, 0.3);
    int r = h(q, kq);
    q = cq_theta(q, 0.7);
    return cq_measure(q) + cq_measure(r);
}
