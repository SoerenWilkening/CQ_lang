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
 * The phase (cq-743m): every activation of fn is also the phase P(theta_fn), theta_fn = cq_standin_angle(fn):
 *   theta_fn = (1 + (h_name >> 44)) * 2^-19, h_name the h after the name bytes: an exact double in (0, 2],
 *   never the identity. CR §1.4 `_ctl`: "applies [the predicate] to everything that is not a template on
 *   SSA values: rotations, phases, ..."; so the forward clone emits the phase unguarded, its `_ctl` form
 *   under its predicate, `_pure` and every twin none (rule 18's twin recomputes through `_pure`). The C side
 *   reaches the same phase at every call of fn (a cq_phi(theta_fn) site of the call), so a declared clone
 *   called without its predicate (or with a wrong one) changes the phase total CR §6 item 2 compares.
 *   Only for a callee whose declared clone is the checker's stand-in (stubgen.py), never a clone the
 *   driver line defines (161, 190).
 * A declared clone __cq_q_<fn>_<1...1>_t(handles..., i32 K) (rule 27, CR §1.4) takes a pointer as a handle to
 * an i64 address rail. A pointer is an argument never mixed: an address differs per run (CR §6: pointer values
 * are compared only relationally). The trailing K, the _ctl predicate and a twin's out handles are not arguments
 * of fn. A quantum argument mixes its rail's value. The twin XORs the same value out; a table twin frees it.
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

/* theta_fn as its f64 bit pattern (cq-743m; above). */
static inline uint64_t cq_standin_angle(const char *name, size_t n) {
  double t = (double)(1 + (cq_standin_name(name, n) >> 44)) / 524288.0; /* 2^19 */
  uint64_t b;
  __builtin_memcpy(&b, &t, sizeof b);
  return b;
}

#endif
