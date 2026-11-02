// T2 (cq-arch 2026-11-01): TaintInfo::cellsWritten, the cells of a pointer formal's object a clone may
// store a handle into (CR rules 18, 20). 31's split (one i32 cell: {0}), a store into the second field of
// a {i32, i32} object ({1}), a classical store into a classical object ({}), a non-pointer formal ({}), and
// a quantum store at a variable offset (unimplemented, in a forked child). cq-ee23: stores through
// pointers derived by ptrtoint/add/inttoptr ({2}, 31-style C '*(int*)((uintptr_t)p+8)'), freeze ({1}),
// insertvalue/extractvalue ({3}); an integer made of the formal stored to memory is the escape
// (unimplemented). cq-lv9a: a cell is a scalar leaf of the pointee's C type (an i64 store at byte 8 of
// int[4] is {2,3}, an i8 at byte 1 is {0}). cq-1c5j: through the formal handed on to a call ({3}). T3: cellsRotated of a rotation in place through the formal ({1}; cellsWritten {}).
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

define i32 @e9(i32 %x0, double %th) {
  %o = alloca [4 x i32], align 4
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  call void @handon(i32 %x, ptr %o)
  %g = getelementptr inbounds i8, ptr %o, i64 12
  %l = load i32, ptr %g, align 4
  %m = tail call i32 @cq_measure_si32(i32 %l)
  ret i32 %m
}

; cq-1c5j: the formal handed on to a call (musl frexp's int *e to its recursive call): put4's write at
; byte 4 of its formal is byte 12 of this one's object, cell 3.
define internal void @handon(i32 %v, ptr %p) {
  %q = getelementptr inbounds i8, ptr %p, i64 8
  call void @put4(i32 %v, ptr %q)
  ret void
}

define internal void @put4(i32 %v, ptr %p) {
  %q = getelementptr inbounds i8, ptr %p, i64 4
  %w = add i32 %v, 1
  store i32 %w, ptr %q, align 4
  ret void
}

define internal void @varoff(i32 %v, ptr %p, i64 %i) {
  %q = getelementptr inbounds i32, ptr %p, i64 %i
  store i32 %v, ptr %q, align 4
  ret void
}

define i32 @e3(i32 %x0, double %th) {
  %o1 = alloca [4 x i32], align 4
  %o2 = alloca [4 x i32], align 4
  %o3 = alloca [4 x i32], align 4
  %o4 = alloca [4 x i32], align 4
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  call void @viaint(i32 %x, ptr %o1)
  %g1 = getelementptr inbounds i8, ptr %o1, i64 8
  %l1 = load i32, ptr %g1, align 4
  call void @viafreeze(i32 %x, ptr %o2)
  %g2 = getelementptr inbounds i8, ptr %o2, i64 4
  %l2 = load i32, ptr %g2, align 4
  call void @viaagg(i32 %x, ptr %o3)
  %g3 = getelementptr inbounds i8, ptr %o3, i64 12
  %l3 = load i32, ptr %g3, align 4
  call void @intescape(i32 %x, ptr %o4)
  %l4 = load i32, ptr %o4, align 4
  %s1 = add i32 %l1, %l2
  %s2 = add i32 %s1, %l3
  %s3 = add i32 %s2, %l4
  %m = tail call i32 @cq_measure_si32(i32 %s3)
  ret i32 %m
}

define internal void @viaint(i32 %v, ptr %p) {
  %i = ptrtoint ptr %p to i64
  %j = add i64 %i, 8
  %q = inttoptr i64 %j to ptr
  %w = add i32 %v, 1
  store i32 %w, ptr %q, align 4
  ret void
}

define internal void @viafreeze(i32 %v, ptr %p) {
  %f = freeze ptr %p
  %q = getelementptr inbounds i8, ptr %f, i64 4
  %w = add i32 %v, 1
  store i32 %w, ptr %q, align 4
  ret void
}

define internal void @viaagg(i32 %v, ptr %p) {
  %a = insertvalue { ptr, i32 } undef, ptr %p, 0
  %b = extractvalue { ptr, i32 } %a, 0
  %q = getelementptr inbounds i8, ptr %b, i64 12
  %w = add i32 %v, 1
  store i32 %w, ptr %q, align 4
  ret void
}

@slot = internal global i64 0

define internal void @intescape(i32 %v, ptr %p) {
  %i = ptrtoint ptr %p to i64
  store i64 %i, ptr @slot, align 8
  store i32 %v, ptr %p, align 4
  ret void
}

define i32 @e4(i32 %x0, double %th, double %t) {
  %o = alloca [4 x i32], align 4
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  %g = getelementptr inbounds i8, ptr %o, i64 4
  store i32 %x, ptr %g, align 4
  call void @rot(ptr %o, double %t, i32 %x)
  %l = load i32, ptr %g, align 4
  %m = tail call i32 @cq_measure_si32(i32 %l)
  ret i32 %m
}

define i32 @e5(i32 %x0, double %th) {
  %o1 = alloca [4 x i32], align 8
  %o2 = alloca [4 x i32], align 8
  %o3 = alloca [4 x i32], align 8
  %x = tail call i32 @cq_theta_si32(i32 %x0, double %th)
  call void @wide(i32 %x, ptr %o1)
  %g1 = getelementptr inbounds i8, ptr %o1, i64 12
  %l1 = load i32, ptr %g1, align 4
  call void @byte(i32 %x, ptr %o2)
  %l2 = load i32, ptr %o2, align 4
  call void @viaint2(i32 %x, ptr %o3)
  %g3 = getelementptr inbounds i8, ptr %o3, i64 8
  %l3 = load i32, ptr %g3, align 4
  %s1 = add i32 %l1, %l2
  %s2 = add i32 %s1, %l3
  %m = tail call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m
}

; cq-lv9a: an i64 store over int cells 2 and 3
define internal void @wide(i32 %v, ptr %p) {
  %q = getelementptr inbounds i8, ptr %p, i64 8
  %w = zext i32 %v to i64
  %w2 = mul i64 %w, 4294967297
  store i64 %w2, ptr %q, align 8
  ret void
}

; cq-lv9a: an i8 store into byte 1 of int cell 0
define internal void @byte(i32 %v, ptr %p) {
  %q = getelementptr inbounds i8, ptr %p, i64 1
  %w = trunc i32 %v to i8
  store i8 %w, ptr %q, align 1
  ret void
}

define internal void @viaint2(i32 %v, ptr %p) {
  %i = ptrtoint ptr %p to i64
  %a = add i64 %i, -4
  %b = add i64 %a, 12
  %q = inttoptr i64 %b to ptr
  store i32 %v, ptr %q, align 4
  ret void
}

; T3: *(p + 1) = cq_theta(*(p + 1)): a rotation in place of cell 1, no handle write
define internal void @rot(ptr %p, double %t, i32 %x) {
  %q = getelementptr inbounds i8, ptr %p, i64 4
  %v = load i32, ptr %q, align 4
  %r = tail call i32 @cq_theta_si32(i32 %v, double %t)
  store i32 %r, ptr %q, align 4
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
                        Case{"classical", 1, {}}, Case{"viaint", 1, {2}}, Case{"viafreeze", 1, {1}},
                        Case{"viaagg", 1, {3}}, Case{"rot", 0, {}}, Case{"wide", 1, {2, 3}},
                        Case{"byte", 1, {0}}, Case{"viaint2", 1, {2}}, Case{"handon", 1, {3}}}) {
    const cq::Specialization *S = cloneOf(T, M->getFunction(c.fn));
    CHECK(S, "no clone of @" << c.fn);
    if (!S)
      continue;
    SmallVector<unsigned, 4> got = T.cellsWritten(*S, c.arg);
    CHECK(got == c.want, "@" << c.fn << " formal " << c.arg << ": " << str(got) << ", want " << str(c.want));
  }
  // T3: cellsRotated.
  for (const Case &c : {Case{"rot", 0, {1}}, Case{"second", 1, {}}, Case{"split", 2, {}}}) {
    const cq::Specialization *S = cloneOf(T, M->getFunction(c.fn));
    CHECK(S, "no clone of @" << c.fn);
    if (!S)
      continue;
    SmallVector<unsigned, 4> got = T.cellsRotated(*S, c.arg);
    CHECK(got == c.want, "@" << c.fn << " formal " << c.arg << " rotated: " << str(got) << ", want " << str(c.want));
  }

  // Unimplemented shapes, each in a child.
  auto refused = [&](const char *fn, unsigned arg, const std::string &want) {
    const cq::Specialization *S = cloneOf(T, M->getFunction(fn));
    CHECK(S, "no clone of @" << fn);
    int pfd[2];
    if (!S || pipe(pfd) != 0)
      return;
    fflush(nullptr);
    pid_t pid = fork();
    if (pid == 0) {
      dup2(pfd[1], 2);
      close(pfd[0]);
      close(pfd[1]);
      (void)T.cellsWritten(*S, arg);
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
    CHECK(WIFEXITED(status) && WEXITSTATUS(status) != 0, "@" << fn << ": the child exits non-zero");
    CHECK(out.find(want) != std::string::npos, "@" << fn << ": got " << out);
  };
  refused("varoff", 1, "cq: unimplemented: taint: cellsWritten: a store through the formal at a variable offset");
  refused("intescape", 1, "cq: unimplemented: taint: cellsWritten: the formal escapes into memory");

  outs() << "taint_cellswritten: " << (checks - failures) << "/" << checks << " checks pass\n";
  return failures ? 1 : 0;
}
