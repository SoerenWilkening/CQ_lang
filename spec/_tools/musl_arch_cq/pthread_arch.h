/* CQ arch: one thread (single-thread collapse, 106), so the thread pointer is the address of one TLS object
 * provided by the bundle; a global like any other (67, 108), no intrinsic. */
extern char __cq_tp[];
static inline uintptr_t __get_tp() { return (uintptr_t)__cq_tp; }
#define MC_PC gregs[REG_RIP]
