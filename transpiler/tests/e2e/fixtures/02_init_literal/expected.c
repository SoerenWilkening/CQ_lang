#include "qint.h"
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_t x = init_qint(5, 16);
    return 0;
}
