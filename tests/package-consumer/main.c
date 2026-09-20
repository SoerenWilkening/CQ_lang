#include <stdbool.h>
#include <stdint.h>

/* A lowered CQ module carries this declaration in its IR. Keep the consumer
 * independent of backend-private headers while forcing the selected archive
 * to satisfy one real emitted symbol. */
extern int32_t cqrt_alloc_i1(bool value);

int main(void) {
    return cqrt_alloc_i1(false) < 0;
}
