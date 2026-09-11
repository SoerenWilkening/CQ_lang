#include <stdio.h>
int g_probe;
int main(void) {
    int b0 = cq_theta(0, 0.5);
    int s = 0;
    if (b0 == 1) { s = 4; }
    g_probe = s;
    printf("%d %d\n", cq_measure(b0), g_probe);
    return 0;
}
