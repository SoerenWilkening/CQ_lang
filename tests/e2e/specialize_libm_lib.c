/* specialize_libm_lib.c — the CLASSICAL library translation unit for the
   bd 3c6m.3 golden (libm-in-clone specialization). Like specialize_intrinsic_lib.c
   it must compile WITHOUT the CQ.h intrinsic surface (C18 — run_slice_multi.sh
   applies `-include CQ.h` to the CQ TU only); the tripwire below fails LOUDLY at
   compile if the harness ever force-includes CQ.h into a lib TU.

   `ilogb_helper` is exactly the body the 3c6m.3 fix accepts: a VISIBLE,
   PURELY-CLASSICAL, NON-RECURSIVE, single-basic-block i32 body whose only
   non-arithmetic op is a curated DIRECT-libm call. clang -O1 leaves `ilogb` a
   DIRECT `@ilogb` call to a declaration-only libc extern (NOT an `@llvm.*`
   intrinsic), which `isLibmCall` recognizes by EXACT name over the curated
   libm_table.yaml set. A libm call needs an fp operand, but a tainted clone arg
   is an i32 HANDLE, so the `(double) n` cast (`sitofp i32→f64`) reaches the fp
   domain; `ilogb` (f64→i32, CrossUnary) then returns an i32 directly, satisfying
   the i32-return ABI gate with no output cast. The caller hands a TAINTED
   argument, so the specializer clones this into `__cq_q_ilogb_helper_1`, lowers
   the sitofp + ilogb to the frozen `cq_template_sitofp_i32_to_f64` /
   `cq_template_ilogb_f64_to_i32` producers, and Bennett-wraps it (compute ->
   cqrt_copy_i32 -> LIFO reverse via `_unc` -> free) — each Class-2 `_unc`
   recomputing from its still-live source. Pre-fix this whole candidate
   loud-declined (the libm call read as a declaration-only nested call, then
   FpAbi'd on the fp operand in the transitive worklist). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

#include <math.h>

int ilogb_helper(int n) {
    return ilogb((double) n);
}
