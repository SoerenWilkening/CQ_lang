#include <math.h>
volatile int off = 3;
int slice(void){
    int a = 0;
    int r = 0;
    a = cq_theta(a, 0.5);
    r = cq_theta(r, 0.3);
    if (sqrt(a + 3.) <= 3.5) { r = cq_theta(r, 0.9); }
    r = r + off;
    if (sqrt(a + 3.) <= 3.5) { r = cq_theta(r, 0.9); }
    r = r + off;
    return cq_measure(a) + cq_measure(r);
}
int main(void){(void)slice();return 0;}
