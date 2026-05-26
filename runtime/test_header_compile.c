/* test_header_compile.c - Phase 3 M3 acceptance gate.
 *
 * Purpose: prove the generated runtime/cq_templates.h parses clean
 * under -Wall -Wextra -Wpedantic -Werror. No bodies are exercised
 * here - the static library cq_templates only defines the 14 Phase 2
 * stubs; the other 666 symbols are declarations only. Linking is not
 * attempted: we compile this TU as a sanity check on the header. The
 * CMake target accomplishes that by building it into an object-only
 * static library so the linker never resolves the undefined decls.
 *
 * Spec: phases/phase3/PLAN.md §4.3 (red test for the generated header).
 */
#include "cq_templates.h"

int main(void) { return 0; }
