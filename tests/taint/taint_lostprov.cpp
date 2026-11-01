// cq-erjd, cq-n58p, cq-0y74, cq-kuuf (gate 2a review taint-h1): taint is sound where a pointer's
// provenance is lost (NORTHSTAR 1, 2; CR rule 3: a value is quantum iff it derives from cq_theta by LLVM
// data flow through memory and pointers).
//  - cq-erjd: a store of F that follows a load of F in the CFG reaches that load in F's next activation
//    when F runs more than once (two call sites, a call in a loop, recursion); F's own allocas are fresh
//    per activation unless F may recurse. A run-once function keeps the CFG order (88).
//  - cq-n58p: inttoptr of an integer not derived from one ptrtoint (a pointer loaded as an integer: a
//    union pun, *(int **)&G) may point into any object whose address escaped into memory or an integer.
//  - cq-0y74: a pointer read from a cell written by non-pointer stores (a byte-wise copy) likewise.
//  - cq-kuuf: an i64 compare-exchange on a pointer variable writes the cell as an integer; its old value
//    (inttoptr of the extracted i64) likewise.
// Each read below is the gate's repro (tests/mem-slots/probes/taint_lost_*.c); the lowering of those
// reads is not built yet and stops loudly there.
#include <cstdio>
#include <string>

#include "cq/Taint.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

static int failures = 0, checks = 0;
#define CHECK(c, msg)                                                                              \
  do {                                                                                             \
    ++checks;                                                                                      \
    if (!(c)) {                                                                                    \
      ++failures;                                                                                  \
      errs() << "FAIL " << __LINE__ << ": " << msg << "\n";                                        \
    }                                                                                              \
  } while (0)

static const char *IR = R"(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@xg = global i32 0
@yg = global i32 7
@G = global ptr @yg
@U = global ptr null
@P = global i64 0
@B = global ptr null
@H = global ptr null
@C = global ptr @yg
@R = global ptr @yg

; cq-erjd (reent.c): f's load of @G is reached by f's own later store in the second call.
define i32 @f() noinline {
  %p = load ptr, ptr @G
  %r = load i32, ptr %p
  store ptr @xg, ptr @G
  ret i32 %r
}
define i32 @reent(i32 %x0, double %th) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  store i32 %x, ptr @xg
  %a = tail call i32 @f()
  %b = tail call i32 @f()
  %m = tail call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}

; Precision (88): a function that runs once (an entry nothing calls) keeps the CFG order: the
; store after the load is not in the load's provenance.
define i32 @once(i32 %x0, double %th) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  store i32 %x, ptr @xg
  %p = load ptr, ptr @R
  %r = load i32, ptr %p
  store ptr @xg, ptr @R
  ret i32 %r
}

; cq-n58p (upun.c, pun.c): the pointer stored by put, read back as an integer by get.
define void @put() noinline {
  store ptr @xg, ptr @U
  ret void
}
define i32 @get() noinline {
  %l = load i64, ptr @U
  %p = inttoptr i64 %l to ptr
  %r = load i32, ptr %p
  ret i32 %r
}
define i32 @upun(i32 %x0, double %th) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  store i32 %x, ptr @xg
  tail call void @put()
  %v = tail call i32 @get()
  %m = tail call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; cq-0y74 (bytecp.c): @B copied byte-wise into @H by volatile i8 stores.
define void @cp() noinline {
entry:
  br label %loop
loop:
  %i = phi i64 [ 0, %entry ], [ %n, %loop ]
  %s = getelementptr inbounds i8, ptr @B, i64 %i
  %c = load i8, ptr %s
  %d = getelementptr inbounds i8, ptr @H, i64 %i
  store volatile i8 %c, ptr %d
  %n = add nuw nsw i64 %i, 1
  %e = icmp eq i64 %n, 8
  br i1 %e, label %done, label %loop
done:
  ret void
}
define i32 @getH() noinline {
  %p = load ptr, ptr @H
  %r = load i32, ptr %p
  ret i32 %r
}
define i32 @bytecp(i32 %x0, double %th) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  store i32 %x, ptr @xg
  store ptr @xg, ptr @B
  tail call void @cp()
  %v = tail call i32 @getH()
  %m = tail call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; cq-kuuf (cx.c): __atomic_compare_exchange_n on an int * as i64; the old value and a later pointer
; load of the cell.
define ptr @swap() noinline {
  %x = cmpxchg ptr @C, i64 ptrtoint (ptr @yg to i64), i64 ptrtoint (ptr @xg to i64) seq_cst seq_cst, align 8
  %ok = extractvalue { i64, i1 } %x, 1
  %old = extractvalue { i64, i1 } %x, 0
  %op = inttoptr i64 %old to ptr
  %r = select i1 %ok, ptr @yg, ptr %op
  ret ptr %r
}
define i32 @cx(i32 %x0, double %th) {
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  store i32 %x, ptr @xg
  %a = tail call ptr @swap()
  %p = tail call ptr @swap()
  %v = load i32, ptr %p
  %c = load ptr, ptr @C
  %w = load i32, ptr %c
  %s = add i32 %v, %w
  %m = tail call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
)";

static Instruction *named(Function &F, StringRef n) {
  for (Instruction &I : instructions(F))
    if (I.getName() == n)
      return &I;
  errs() << "no instruction %" << n << " in @" << F.getName() << "\n";
  std::exit(2);
}

// The read is quantum in some specialization of F that reads it, and the pointer's provenance names
// @xg's object there.
static void expectRead(const cq::TaintInfo &T, Module &M, const char *fn, const char *read,
                       const char *ptr) {
  Function &F = *M.getFunction(fn);
  cq::ObjectId xg = T.objectOf(M.getGlobalVariable("xg"));
  bool q = false, prov = false;
  for (const cq::Specialization &S : T.specializations()) {
    if (S.F != &F)
      continue;
    if (!read || T.isQuantum(named(F, read), S))
      q = true;
    if (llvm::is_contained(T.provenance(named(F, ptr), S), xg))
      prov = true;
  }
  CHECK(q, "@" << fn << " %" << (read ? read : "") << ": classical, want quantum");
  CHECK(prov, "@" << fn << " %" << ptr << ": provenance misses @xg");
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_lostprov", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});

  expectRead(T, *M, "f", "r", "p");
  expectRead(T, *M, "get", "r", "p");
  expectRead(T, *M, "getH", "r", "p");
  expectRead(T, *M, "cx", "v", "p");
  expectRead(T, *M, "cx", "w", "c");    // the cell written as an i64 holds @xg after the first swap

  // Precision: @once runs once; its later store does not reach its load.
  {
    Function &F = *M->getFunction("once");
    cq::ObjectId xg = T.objectOf(M->getGlobalVariable("xg"));
    for (const cq::Specialization &S : T.specializations())
      if (S.F == &F) {
        CHECK(!T.isQuantum(named(F, "r"), S), "@once %r: quantum, want classical (CFG order holds)");
        CHECK(!llvm::is_contained(T.provenance(named(F, "p"), S), xg),
              "@once %p: provenance names @xg stored after the load");
      }
  }

  outs() << "taint_lostprov: " << checks << " checks, " << failures << " failures\n";
  return failures ? 1 : 0;
}
