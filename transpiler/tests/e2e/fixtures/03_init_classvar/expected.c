#include "qint.h"
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    int classic = 7;
    qint_t z = init_qint(classic, 16);
    return 0;
}
