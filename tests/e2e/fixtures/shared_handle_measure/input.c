/* tests/e2e/fixtures/shared_handle_measure/input.c — E2E fixture locking
 * the trace shape for the PRD's "edge case: shared handle when both `a`
 * and `b` are measured" worked example. PLAN §4.20 / M20.
 *
 * Per phases/phase2/PRD.md §"On assignment and surviving operations":
 * `quantum int b = a;` is pure quantum-to-quantum same-type assignment
 * (Codegen Pattern 6). Clang's SROA erases the temporary `b`, so both
 * measurements lower to the *same* handle. The trace below — one alloc
 * and two measures of that single handle — is therefore the EXPECTED,
 * CORRECT shape, not a bug.
 *
 * WARNING TO FUTURE CONTRIBUTORS: the absence of a `cq_template_copy_*`
 * call here is correct by design. Phase 2 ships no `cq_copy_<sfx>`
 * intrinsic, and emitting one to "fix" this fixture would reintroduce
 * exactly the misfeature the PRD §"On assignment and surviving
 * operations" section rules out. Per ROADMAP design principle 5
 * ("C philosophy: no foot-gun protection"), the compiler does not
 * detect or warn that the user might have meant two physically
 * independent registers — entangled copies would yield the same
 * measurement outcome anyway, so the shared-handle trace is
 * semantically equivalent to a CNOT-copied `b`.
 */
#include <CQ.h>
int main(void) {
  quantum int a = 5;
  quantum int b = a;
  (int) a;
  (int) b;
  return 0;
}
