// T2 (cq-arch 2026-11-01): TaintInfo::cellsWritten, the cells of a pointer formal's object a clone may
// store a handle into (CR rules 18, 20). 31's split (one i32 cell: {0}), a store into the second field of
// a {i32, i32} object ({1}), a classical store into a classical object ({}), a non-pointer formal ({}), and
// a quantum store at a variable offset (unimplemented, in a forked child).
#include <cstdio>
#include <string>
#include <sys/wait.h>
#include <unistd.h>

#include "cq/Taint.h"

#include "llvm/AsmParser/Parser.h"
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

define i32 @e(i32 %x0, double %th, i32 %k, i64 %i) {
  %hi = alloca i32, align 4
  %pr = alloca { i32, i32 }, align 4
  %cc = alloca i32, align 4
  %vv = alloca [4 x i32], align 4
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %lo = call i32 @split(i32 %x, i32 %k, ptr %hi)
  %h = load i32, ptr %hi, align 4
  call void @second(i32 %x, ptr %pr)
  %f1p = getelementptr inbounds i8, ptr %pr, i64 4
  %f1 = load i32, ptr %f1p, align 4
  %c = call i32 @classical(i32 %x, ptr %cc, i32 %k)
  %cv = load i32, ptr %cc, align 4
  %s1 = add i32 %lo, %h
  %s2 = add i32 %s1, %f1
  %s3 = add i32 %s2, %c
  %s4 = add i32 %s3, %cv
  %m = tail call i32 @cq_measure_si32(i32 %s4)
  ret i32 %m
}

define internal i32 @split(i32 %v, i32 %k, ptr %p) {
  %a = ashr i32 %v, %k
  store i32 %a, ptr %p, align 4
  %b = and i32 %v, 255
  ret i32 %b
}

define internal void @second(i32 %v, ptr %p) {
  %q = getelementptr inbounds i8, ptr %p, i64 4
  %w = add i32 %v, 1
  store i32 %w, ptr %q, align 4
  ret void
}

define internal i32 @classical(i32 %v, ptr %p, i32 %k) {
  store i32 %k, ptr %p, align 4
  %r = add i32 %v, 3
  ret i32 %r
}

define i32 @e2(i32 %x0, double %th, i64 %i) {
  %vv = alloca [4 x i32], align 4
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  call void @varoff(i32 %x, ptr %vv, i64 %i)
  %g = getelementptr inbounds i8, ptr %vv, i64 8
  %l = load i32, ptr %g, align 4
  %m = tail call i32 @cq_measure_si32(i32 %l)
  ret i32 %m
}

define internal void @varoff(i32 %v, ptr %p, i64 %i) {
  %q = getelementptr inbounds i32, ptr %p, i64 %i
  store i32 %v, ptr %q, align 4
  ret void
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
)";

static const cq::Specialization *cloneOf(const cq::TaintInfo &T, const Function *F) {
  for (const cq::Specialization &S : T.specializations())
    if (S.F == F && !S.isEntry())
      return &S;
  return nullptr;
}

static std::string str(const SmallVectorImpl<unsigned> &v) {
  std::string s = "{";
  for (unsigned c : v)
    s += (s.size() > 1 ? "," : "") + std::to_string(c);
  return s + "}";
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_cellswritten", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});
  struct Case { const char *fn; unsigned arg; SmallVector<unsigned, 4> want; };
  for (const Case &c : {Case{"split", 2, {0}}, Case{"split", 0, {}}, Case{"second", 1, {1}},
                        Case{"classical", 1, {}}}) {
    const cq::Specialization *S = cloneOf(T, M->getFunction(c.fn));
    CHECK(S, "no clone of @" << c.fn);
    if (!S)
      continue;
    SmallVector<unsigned, 4> got = T.cellsWritten(*S, c.arg);
    CHECK(got == c.want, "@" << c.fn << " formal " << c.arg << ": " << str(got) << ", want " << str(c.want));
  }

  // A quantum store at a variable offset through the formal: unimplemented, in a child.
  {
    const cq::Specialization *S = cloneOf(T, M->getFunction("varoff"));
    CHECK(S, "no clone of @varoff");
    int pfd[2];
    if (!S || pipe(pfd) != 0)
      return 2;
    fflush(nullptr);
    pid_t pid = fork();
    if (pid == 0) {
      dup2(pfd[1], 2);
      close(pfd[0]);
      close(pfd[1]);
      (void)T.cellsWritten(*S, 1);
      _exit(0);
    }
    close(pfd[1]);
    std::string out;
    char buf[512];
    ssize_t k;
    while ((k = read(pfd[0], buf, sizeof buf)) > 0)
      out.append(buf, size_t(k));
    close(pfd[0]);
    int status = 0;
    waitpid(pid, &status, 0);
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) != 0, "variable offset: the child exits non-zero");
    CHECK(out.find("cq: unimplemented: taint: cellsWritten: a store through the formal at a variable offset") !=
              std::string::npos,
          "variable offset: got " << out);
  }

  outs() << "taint_cellswritten: " << (checks - failures) << "/" << checks << " checks pass\n";
  return failures ? 1 : 0;
}
