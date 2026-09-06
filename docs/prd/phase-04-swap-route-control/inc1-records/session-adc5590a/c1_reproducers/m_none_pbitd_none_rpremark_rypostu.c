#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    int r = 0;
    int mark = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    int i = 0;
    mark = r;
    if ((a >> i) & 1) { cq_phi(0.2); }
    r = cq_theta(r, 0.25);
    i = i + 1;
    mark = r;
    if ((a >> i) & 1) { cq_phi(0.2); }
    r = cq_theta(r, 0.25);
    i = i + 1;
    a = cq_theta(a, 0.9);
    return cq_measure(a) + cq_measure(r) + cq_measure(mark);
}
int main(void){(void)slice();return 0;}
