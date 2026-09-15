#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    _Bool k[2] = {0};
    a = cq_theta(a, 0.5);
    for (int i = 0; i < 2; ++i) {
        k[i] = cq_theta(k[i], 0.5);
        a = cq_theta(a, -0.5);
    }
    return cq_measure(a) + (int) cq_measure(k[0]) + (int) cq_measure(k[1]);
}
int main(void){(void)slice();return 0;}
