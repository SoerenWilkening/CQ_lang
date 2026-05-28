/* test_header_compile.c - generated-header parse gate.
 *
 * Purpose: prove the generated runtime/cq_templates.h parses clean
 * under -Wall -Wextra -Wpedantic -Werror. No bodies are exercised
 * here - the static library cq_templates only defines the 14 hand-
 * written stubs; the other 666 symbols are declarations only. Linking
 * is not attempted: we compile this TU as a sanity check on the
 * header. The CMake target accomplishes that by building it into an
 * object-only static library so the linker never resolves the
 * undefined decls.
 */
#include "cq_templates.h"

int main(void) { return 0; }
