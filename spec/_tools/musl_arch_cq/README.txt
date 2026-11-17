The CQ "architecture" for building musl as a quantum library bundle (owner, 2026-10-20). musl keeps every
machine-specific primitive in arch/<cpu>/{atomic_arch.h,pthread_arch.h,syscall_arch.h} as inline asm, which the
pass cannot read. These three headers replace them (put this directory first on the include path, keep
arch/x86_64 after it for bits/ and the rest) with the one builtin whose contract equals the instruction, so the
code the pass sees is the code musl intends, spelled as IR: __atomic_* -> cmpxchg/atomicrmw/fence (94),
__builtin_ctzll/clzll -> llvm.cttz/ctlz (56, 108), __builtin_trap -> llvm.trap (108, 45), the thread pointer ->
the address of one TLS object (single thread, 67/108), the syscall -> a bodiless __cq_syscall (a host call;
under quantum control a tape entry, 102). Everything not defined here falls back to musl's own C in
src/internal/atomic.h. Nothing else in musl is touched.
