/* test_header_compile.c - runtime-header parse gate.
 *
 * Purpose: prove the generated runtime/cq_templates.h AND the
 * hand-written runtime/cq_runtime.h parse clean under -Wall -Wextra
 * -Wpedantic -Werror (cq_templates.h does not include cq_runtime.h,
 * so the core-ABI header must be pulled in explicitly to be covered
 * by this gate). No bodies are exercised here - the static library
 * cq_templates only defines the 14 hand-written stubs; the other 666
 * symbols are declarations only. Linking is not attempted: we compile
 * this TU as a sanity check on the headers. The CMake target
 * accomplishes that by building it into an object-only static library
 * so the linker never resolves the undefined decls.
 */
#include "cq_runtime.h"
#include "cq_templates.h"
#include "cq_intrinsic_templates.h"  /* Phase 7.1 Increment E sibling surface */

int main(void) { return 0; }
