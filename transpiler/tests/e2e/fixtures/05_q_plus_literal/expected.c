#include <CQ.h>
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_mid_t a = cq_init_i32(3);
    qint_mid_t d; d.val = a.val + 5;
    return 0;
}
