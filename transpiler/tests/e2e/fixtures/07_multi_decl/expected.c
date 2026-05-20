#include "qint.h"
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_t a = init_qint(3, 16); qint_t b = init_qint(2, 16);
    return 0;
}
