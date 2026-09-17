/* sx — the ABI control for the `65533` literal in the new narrow golden.  A
 * NATIVE C caller emits `signext` on the int16_t parameter; the pass's
 * `declare i32 @cq_template_add_i16_hl(i32, i16)` does NOT.  If these two print
 * different values, the emitted call passes a different operand than the source
 * wrote. */
#include <stdint.h>
int32_t cq_template_add_i16_hl(int32_t, int16_t);
int32_t cq_template_add_i8_hl(int32_t, int8_t);
int main(void) {
    cq_template_add_i16_hl(0, (int16_t)-3);
    cq_template_add_i8_hl(0, (int8_t)-3);
    return 0;
}
