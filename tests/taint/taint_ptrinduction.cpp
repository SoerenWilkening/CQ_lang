// cq-0hdy: a pointer header phi advanced by a fixed classical GEP per trip is the trip index's
// function start + j * step (rule 14 re-rolled by SCEV, 189, 190), so its offset stays classical in
// a loop with a quantum exit and the object it walks stays a slot array (rule 20; 190's memcmp clone).
// A pointer advanced by a quantum step, or chosen by the exit, stays quantum; an integer counter
// read after the loop stays a carried rail (05).
#include <cstdio>
#include <string>

#include "cq/Taint.h"

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

; 190's memcmp_qlen with musl memcmp inlined by hand: a quantum length and quantum bytes decide
; the exit; l and r advance by gep 1.
define i32 @cmp(i32 %x0, double %tx, i8 %u0, double %tu) {
entry:
  %a = alloca [3 x i8], align 1
  %b = alloca [3 x i8], align 1
  %x = tail call i32 @cq_theta_ui32(i32 %x0, double %tx)
  %u = tail call i8 @cq_theta_ui8(i8 %u0, double %tu)
  store i8 %u, ptr %a, align 1
  %a1 = getelementptr inbounds i8, ptr %a, i64 1
  store i8 7, ptr %a1, align 1
  store i8 %u, ptr %b, align 1
  %b1 = getelementptr inbounds i8, ptr %b, i64 1
  store i8 %u, ptr %b1, align 1
  %n3 = and i32 %x, 3
  %n = zext i32 %n3 to i64
  %z = icmp eq i64 %n, 0
  br i1 %z, label %done, label %loop
loop:
  %r = phi ptr [ %r1, %latch ], [ %b, %entry ]
  %l = phi ptr [ %l1, %latch ], [ %a, %entry ]
  %k = phi i64 [ %k1, %latch ], [ %n, %entry ]
  %lv = load i8, ptr %l, align 1
  %rv = load i8, ptr %r, align 1
  %eq = icmp eq i8 %lv, %rv
  br i1 %eq, label %latch, label %diff
latch:
  %k1 = add i64 %k, -1
  %l1 = getelementptr inbounds i8, ptr %l, i64 1
  %r1 = getelementptr inbounds i8, ptr %r, i64 1
  %e = icmp eq i64 %k1, 0
  br i1 %e, label %done, label %loop
diff:
  %d = sub i8 %lv, %rv
  %dz = zext i8 %d to i32
  br label %done
done:
  %res = phi i32 [ %dz, %diff ], [ 0, %entry ], [ 0, %latch ]
  %m = tail call i32 @cq_measure_si32(i32 %res)
  ret i32 %m
}

; The same walk advanced by a quantum stride: a quantum offset, a QRAM.
define i32 @qstep(i32 %x0, double %tx, i8 %u0, double %tu) {
entry:
  %a = alloca [8 x i8], align 1
  %x = tail call i32 @cq_theta_ui32(i32 %x0, double %tx)
  %u = tail call i8 @cq_theta_ui8(i8 %u0, double %tu)
  store i8 %u, ptr %a, align 1
  %s = and i32 %x, 1
  %sx = zext i32 %s to i64
  br label %loop
loop:
  %l = phi ptr [ %l1, %loop ], [ %a, %entry ]
  %lv = load i8, ptr %l, align 1
  %l1 = getelementptr inbounds i8, ptr %l, i64 %sx
  %c = icmp ne i8 %lv, 0
  br i1 %c, label %loop, label %done
done:
  %m = tail call i8 @cq_measure_ui8(i8 %lv)
  %mz = zext i8 %m to i32
  ret i32 %mz
}

; An integer counter beside the pointer walk, read after the loop: still a carried rail (05).
define i32 @count(i32 %x0, double %tx) {
entry:
  %a = alloca [4 x i32], align 4
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %tx)
  store i32 %x, ptr %a, align 4
  br label %loop
loop:
  %p = phi ptr [ %p1, %loop ], [ %a, %entry ]
  %n = phi i32 [ %n1, %loop ], [ 0, %entry ]
  %v = load i32, ptr %p, align 4
  %n1 = add i32 %n, 1
  %p1 = getelementptr inbounds i32, ptr %p, i64 1
  %c = icmp ne i32 %v, 0
  br i1 %c, label %loop, label %done
done:
  %m = tail call i32 @cq_measure_si32(i32 %n1)
  ret i32 %m
}

declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_theta_si32(i32, double)
declare i8 @cq_theta_ui8(i8, double)
declare i32 @cq_measure_si32(i32)
declare i8 @cq_measure_ui8(i8)
)";

static Instruction *named(Function &F, StringRef n) {
  for (Instruction &I : instructions(F))
    if (I.getName() == n)
      return &I;
  errs() << "no instruction %" << n << " in @" << F.getName() << "\n";
  std::exit(2);
}

static const cq::Specialization *entryOf(const cq::TaintInfo &T, const Function *F) {
  for (const cq::Specialization &S : T.specializations())
    if (S.F == F && S.isEntry())
      return &S;
  return nullptr;
}

static void expectQ(const cq::TaintInfo &T, Function &F,
                    std::initializer_list<std::pair<const char *, bool>> want) {
  const cq::Specialization *S = entryOf(T, &F);
  CHECK(S, "no entry specialization of @" << F.getName());
  if (!S)
    return;
  for (auto &[n, w] : want)
    CHECK(T.isQuantum(named(F, n), *S) == w,
          "@" << F.getName() << " %" << n << ": quantum " << !w << ", want " << w);
}

static void expectClass(const cq::TaintInfo &T, Function &F, const char *site, cq::ObjClass want) {
  CHECK(T.classOf(T.objectOf(named(F, site))) == want,
        "@" << F.getName() << " %" << site << ": class " << int(T.classOf(T.objectOf(named(F, site))))
            << ", want " << int(want));
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_ptrinduction", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});

  Function &C = *M->getFunction("cmp");
  expectQ(T, C,
          {{"l", false}, {"r", false}, {"l1", false}, {"r1", false}, {"k", true}, {"lv", true},
           {"eq", true}, {"res", true}});
  expectClass(T, C, "a", cq::ObjClass::Slot);
  expectClass(T, C, "b", cq::ObjClass::Slot);
  if (const cq::Specialization *S = entryOf(T, &C)) {
    CHECK(T.offsetKind(named(C, "lv"), *S) == cq::OffsetKind::Classical, "@cmp %lv: quantum offset");
    CHECK(T.offsetKind(named(C, "rv"), *S) == cq::OffsetKind::Classical, "@cmp %rv: quantum offset");
  }

  Function &Q = *M->getFunction("qstep");
  expectQ(T, Q, {{"l", true}});
  expectClass(T, Q, "a", cq::ObjClass::Qram);

  Function &N = *M->getFunction("count");
  expectQ(T, N, {{"p", false}, {"n", true}, {"n1", true}});
  expectClass(T, N, "a", cq::ObjClass::Slot);

  std::printf("taint_ptrinduction: %d/%d checks pass\n", checks - failures, checks);
  return failures ? 1 : 0;
}
