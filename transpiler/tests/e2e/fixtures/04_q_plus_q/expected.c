#include <CQ.h>
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_mid_t a = cq_init_si32(3);
    qint_mid_t b = cq_init_si32(2);
    qint_mid_t c; c.val = a.val + b.val;
    return 0;
}
