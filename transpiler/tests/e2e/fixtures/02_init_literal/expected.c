#include <CQ.h>
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_mid_t x = cq_init_i32(5);
    return 0;
}
