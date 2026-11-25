// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include <cstdint>
#include <string>

#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

// Common.h
namespace cq {
[[noreturn]] void unimplemented(llvm::StringRef what, const llvm::Value *at = nullptr); // "cq: unimplemented: ..."
[[noreturn]] void internalError(llvm::StringRef what, const llvm::Value *at = nullptr);
// Every stop names its source site ("  site: file:line" after the message): tools/stopcheck.py groups the musl
// functions by it (owner 2026-11-03). The macros route the call sites above through these.
[[noreturn]] void unimplementedAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at = nullptr);
[[noreturn]] void internalErrorAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at = nullptr);
// Owner 2026-11-03: no fence stops the pass. Every unimplemented() site is a no-op: the code behind it runs on
// the shape; the structural verifier, a crash, or the §6 sweep judge the result, never a fence.
#define unimplemented(...) ((void)0)
#define internalError(...) internalErrorAt(__FILE__, __LINE__, __VA_ARGS__)
// Owner 2026-11-05: a shape not built yet is not a stop. One non-fatal line on stderr names the site; the code runs on.
// "cq: note: unbuilt: <what>  site: file:line" (then "  at: <instruction>" when `at` is given, still one line).
void noteUnbuiltAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at = nullptr);
#define noteUnbuilt(...) noteUnbuiltAt(__FILE__, __LINE__, __VA_ARGS__)
enum class Kind : uint8_t { Int, Fp, BFloat };
struct RailType { Kind kind; unsigned bits; };      // i<N> (N >= 1), f16, f32, f64, f80, bf16 (BFloat: bits == 16)
RailType railTypeOf(llvm::Type *);                  // iN/half/float/double/x86_fp80/bfloat; ptr is i64 (rule 21)
llvm::Type *irTypeOf(llvm::LLVMContext &, RailType);
llvm::IntegerType *handleTy(llvm::LLVMContext &);   // i32
using Mask = std::string;                           // CR §1.4 digits, '1' = quantum, left to right
struct Operand { llvm::Value *v; bool handle; };    // a rail handle, or a classical value of the new IR
// cq-my17 (rule 16, 99): F is a library function LLVM knows (TargetLibraryInfo for the module's triple,
// prototype checked), its LibFunc in lf; a Mach-O asm label "\01_n" names C function n.
bool libFuncOf(const llvm::Function &F, llvm::LibFunc &lf);
// CR rule 16's stream calls by C name (a leading "\01_" removed): every <stdio.h> and <wchar.h> stream function, input
// and output alike, and the POSIX descriptor calls open, close, read, write, lseek; never the string formatters
// sprintf, snprintf, sscanf, swprintf, swscanf and their v forms (injected and lifted; cq-ojgho).
bool streamName(llvm::StringRef cname);
// cq-pt57w (CR rule 16): F is a stream call recognised by name and signature (its prototype checked where LLVM's
// TargetLibraryInfo knows the name). "A body the bundle has for one of them is never lifted for the call."
bool streamCallee(const llvm::Function &F);
// CR rule 16: a call of F by name is at the host boundary: F has no body, or it is one of the ISO C and POSIX
// interfaces rule 16 names (a stream call, malloc and its family, signal, raise, rule 23's fenv functions, rule 24's
// setjmp, longjmp and pthread_*) whose body is never lifted (cq-pt57w, cq-rrc52). Rule 16 classifies the call;
// nothing descends into F's body for it.
bool hostCallee(const llvm::Function &F);
// CR rule 24: the mutex calls, no-ops returning 0, by C name (a leading "\01_" removed): pthread_mutex_lock, _trylock,
// _timedlock, _unlock, _init, _destroy, and musl's internal names __pthread_mutex_lock, _trylock, _timedlock, _unlock
// of the same functions, which a lifted mtx_* body calls (owner ruling 2026-11-12 on cq-dbtpi).
bool rule24Mutex(llvm::StringRef cname);
// CR rule 16 (owner rulings 2026-11-12 signal's EINVAL store, 2026-11-13 errno accessor): F is an errno accessor,
// __errno_location (musl, glibc) or __error (a Darwin-built module), by name and signature int *(void). A call of one
// returns an address and has no effect: no effect entry, no event; it is made as it stands, unguarded.
bool errnoAccessor(const llvm::Function &F);
// The C name of a callee: the function's own, or the libm function an LLVM math intrinsic stands for (rule 18).
std::string calleeName(const llvm::Function &F, const llvm::Value *at);
// cq-z6q1 (CR rule 14; 189): the exit of the loop headed by `header` from block `exiting` has an exit count
// SCEV computes (its symbolic maximum): a classical exit test that bounds the trip count. A classical exit
// whose count LLVM cannot compute (189's NULL read from memory) is no classical bound. Its own analyses.
bool exitCountKnown(const llvm::BasicBlock &header, const llvm::BasicBlock &exiting);
// cq-s7c4 (CR rule 14): one disjunct `cond` of an exit test of the loop headed by `header` (the loop exits
// when cond == exitIfTrue) bounds the trip count on its own: SCEV computes a symbolic maximum for it. A
// classical disjunct of a quantum exit (`stop || q`, `stop` loop-invariant) that bounds nothing makes no
// classical bound (case 2, not case 3).
bool exitCondCountKnown(const llvm::BasicBlock &header, const llvm::Value &cond, bool exitIfTrue);
}
