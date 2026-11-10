/* A template handler's plan for a call site (r7-fuse). Private to checker/rt; cqe.h and the handler contract (M1) are
 * unchanged.
 *
 * What a handler works out from the template name and the operand count alone (which op of its family, the parsed
 * widths, the predicate) is the same at every call of one call site. Before it calls a handler for a resolved call
 * site, the dispatcher points cqe__plan_slot at a word that belongs to that (site, handler) pair for as long as the
 * site's name and operand count stand; the word is 0 until the handler stores a plan in it. A handler that knows the
 * protocol takes the slot (cqe__plan_take: the pointer is cleared, so nothing it calls sees it), and
 *   - with a nonzero word, uses it in place of parsing the name;
 *   - otherwise parses and checks the name as always and, only when every one of those checks passed, stores its
 *     plan (nonzero) in the word.
 * A failed or declined call stores nothing, so it is parsed, and fails or declines, again at every call. With no slot
 * (a handler called directly, a symbol dispatched by name) the handler parses the name at every call. A handler that
 * does not know the protocol ignores the slot. */
#ifndef CQE_PLAN_H_
#define CQE_PLAN_H_

#include <stdint.h>

__attribute__((weak)) uintptr_t *cqe__plan_slot; /* one definition per program (weak: every includer defines it) */

static inline uintptr_t *cqe__plan_take(void) {
  uintptr_t *s = cqe__plan_slot;
  cqe__plan_slot = 0;
  return s;
}

#endif /* CQE_PLAN_H_ */
