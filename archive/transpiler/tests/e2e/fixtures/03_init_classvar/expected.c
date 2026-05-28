#include <CQ.h>
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    int classic = 7;
    qint_mid_t z = cq_init_si32(classic);
    return 0;
}
