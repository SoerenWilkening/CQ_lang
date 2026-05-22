#include <CQ.h>
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    int classic = 7;
    qint_mid_t a = cq_init_i32(3);
    qint_mid_t e; e.val = a.val + classic;
    return 0;
}
