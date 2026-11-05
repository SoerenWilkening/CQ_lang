// Bus.h: the one bus (CR rules 5, 16 Allocation, 20, 21, 22; ABI §1.10). Every function below is the whole API the
// spine, calls, loops and eff call.
#pragma once

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"

namespace cq::bus {
// The one bus handle of the function being lowered: `%m = call i32 @__cq_mem()` emitted once at the entry of out()
// the first time it is asked (§5). Never emitted in a function that makes no bus access.
llvm::Value *mem(LoweringContext &);
// Rule 20 Address arithmetic / rule 21: the x86-64 address of pointer `p` as an Operand: a classical i64 (ptrtoint
// instruction for an instruction or argument, `ptrtoint` constant expression for a global; also inside _hl literals)
// or an i64 address rail (sext_<W>_to_i64 where -O1 wrote no cast, mul/shl_i64_hl per scale, add_i64[_hl] per
// getelementptr, templates recorded with Uncompute). Idempotent per (p, insertion block).
Operand address(LoweringContext &, const llvm::Value *p);
// Rule 20 (a)/(b) through TaintInfo::hostObjectOf: the access stays the plain LLVM instruction (copied classical).
bool hostAccess(LoweringContext &, const llvm::Instruction &access);
// Rule 20 table + rule 5 sentence 1: one qram_load_<W>[_hl][_controlled], recorded as a BusLoad (Uncompute); binds the
// load. A _Bool cell read as i1 is ONE access at i1. Vector/aggregate: one access per lane/scalar field.
void lowerLoad(LoweringContext &, llvm::LoadInst &);
// Rule 5 sentence 3 (kept store, value rail a seed for a classical value, control rail kept) or, when the in-place
// matcher matches, the in-place form. Store of a pointer is an i64 store.
void lowerStore(LoweringContext &, llvm::StoreInst &);
// Rule 4 cmpxchg/atomicrmw: a bus load, the templates, a bus store, by lowerStore's rules (add/sub/xor in place).
void lowerAtomic(LoweringContext &, llvm::Instruction &);
// Rule 22: memcpy/memmove/memset[.inline], realloc's copy, byval copy, struct assignment. Classical length: host loops
// (never unrolled); rail length: K2-bounded loops with per-byte kept predicates p_j, push/pop. Host-resident
// destination: the intrinsic stays (Taint decided).
void lowerMemIntrinsic(LoweringContext &, llvm::MemIntrinsic &);
void lowerCopy(LoweringContext &, Operand dst, Operand src, Operand len, llvm::Value *ctl, llvm::Instruction &at);
// Rule 16 Allocation / rule 20 Allocation: alloca (bus-resident), malloc, calloc, aligned_alloc, VLA ->
// `ptr @__cq_alloc(i64 size, i64 align)`; a rail size allocates K2 and keeps icmp_ugt_i64_hl(n, K2) unless range facts
// bound n. Binds the site to the returned ptr. lifetime/stacksave markers are dropped by the spine.
void lowerAlloc(LoweringContext &, llvm::Instruction &site);
void lowerRealloc(LoweringContext &, llvm::CallBase &);
// Rule 5 "memory version change": is new-IR instruction I one (bus store, in-place form, plain store/intrinsic to a
// host-resident object, observable volatile store, allocation, effect entry, host call not memory(none|read),
// table-clone call, call of a function that writes memory)? writesMemory is the least fixpoint over calls by name.
bool versionChange(const LoweringContext &, const llvm::Instruction &origI);
bool writesMemory(const TaintInfo &, const llvm::Function &);
// An allocation or a bus copy: its lowering notes the change itself, at the __cq_alloc call or the copy's first store.
bool notesOwnChange(const LoweringContext &, const llvm::Instruction &origI);
unsigned K2(const LoweringContext &);   // CQ_K2(f, k) / -cq-k2 / -cq-k2-default / 4096
}
