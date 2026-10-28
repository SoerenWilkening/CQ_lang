/* cq_standin.h (cq-rft): the checker's one model of a function nothing defines (CR §6, owner ruling
 * at CQ_spec eb8a11a: one deterministic stand-in of the C name and the argument bits; the model is
 * the checker's, not the spec's). The single source both sides include:
 *   - the C oracle (checker/oracle/OracleInstr.cpp `stubs`, checker/oracle/cqo_rt.c `__cqo_mix`)
 *     defines every external still undefined after libc/libm with it;
 *   - the evaluator (checker/rt/dispatch.c `cqe_standin`, stubs from checker/rt/stubgen.py) defines
 *     every rule 27 declared clone __cq_q_<fn>_<mask>[...] nothing links, and its _unc twin, with it.
 *
 * The function of (fn, args):
 *   h = CQ_STANDIN_BASIS
 *   for each byte b of the C name fn:                 h = cq_standin_mix(h, b)
 *   for each non-pointer scalar argument, in order,
 *     for each 64-bit word w of its bit pattern (zero-extended to a whole number of words, low
 *     word first; fp as its bit pattern, x86_fp80 as 80 bits = 2 words):  h = cq_standin_mix(h, w)
 *   result = the low W bits of h, W the C result type's width (fp: as a bit pattern, f80: h
 *   zero-extended to 80 bits); void: nothing; a pointer result: null. No memory effect.
 * A declared clone's trailing K argument (rule 27), its _ctl predicate, a pointer's (object, tag,
 * idx, cell count) and a twin's out handles and snapshot pointers are not arguments of fn: they are
 * never mixed. A quantum argument mixes its rail's value. The twin XORs the same value out.
 *
 * C17 and C++17 (header only, static inline). */
#ifndef CQ_STANDIN_H
#define CQ_STANDIN_H

#include <stddef.h>
#include <stdint.h>

#define CQ_STANDIN_BASIS 0xcbf29ce484222325ULL /* FNV-1a-64 offset basis */
#define CQ_STANDIN_PRIME 0x100000001b3ULL      /* FNV-1a-64 prime */

static inline uint64_t cq_standin_mix(uint64_t h, uint64_t w) { return (h ^ w) * CQ_STANDIN_PRIME; }

/* h after the name bytes. */
static inline uint64_t cq_standin_name(const char *name, size_t n) {
  uint64_t h = CQ_STANDIN_BASIS;
  for (size_t i = 0; i < n; ++i)
    h = cq_standin_mix(h, (uint64_t)(unsigned char)name[i]);
  return h;
}

#endif
