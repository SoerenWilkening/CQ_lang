// cq-pu8b: rule 23's floating-point environment is point-wise state in taint. Two facts, MODE (the
// rounding mode is a rail) and FLAGS (the exception-flags rail is not empty), flow through each
// function block by block (joined over predecessors, loops included), through calls (the callee's
// exit state composed with the caller's state, its entry state joined over its callers) and through
// fenv_t / fexcept_t objects. A read is quantum exactly where its fact may hold at that point.
#include <cstdlib>

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

; Rule 23: a constant global (musl's FE_DFL_ENV is a constant pointer) is the constant case, never memory.
@_FE_DFL_ENV = external constant [32 x i8]

; FLAGS: a raise under a quantum predicate reaches the test after the join; a test before it does not.
define i32 @flags_join(double %x0, double %th, double %k) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %t0 = call i32 @fetestexcept(i32 32)
  %c = fcmp ogt double %x, %k
  br i1 %c, label %arm, label %join
arm:
  %r = call i32 @feraiseexcept(i32 32)
  br label %join
join:
  %t1 = call i32 @fetestexcept(i32 32)
  %s = add i32 %t0, %t1
  ret i32 %s
}

; A classical raise outside quantum control leaves FLAGS empty.
define i32 @flags_classical(double %a) {
entry:
  %r = call i32 @feraiseexcept(i32 32)
  %t = call i32 @fetestexcept(i32 32)
  ret i32 %t
}

; MODE: a quantum fesetround makes the mode a rail until a valid constant one; a dynamic-rounding op
; on classical operands in between is quantum, before and after it is classical.
define double @mode_seq(i32 %m0, double %th, double %a, double %b) {
entry:
  %m = call i32 @cq_theta_ui32(i32 %m0, double %th)
  %g0 = call i32 @fegetround()
  %o0 = call double @llvm.experimental.constrained.fadd.f64(double %a, double %b, metadata !"round.dynamic", metadata !"fpexcept.ignore")
  %rc = call i32 @fesetround(i32 %m)
  %g1 = call i32 @fegetround()
  %o1 = call double @llvm.experimental.constrained.fadd.f64(double %a, double %b, metadata !"round.dynamic", metadata !"fpexcept.ignore")
  %o1n = call double @llvm.experimental.constrained.fadd.f64(double %a, double %b, metadata !"round.tonearest", metadata !"fpexcept.ignore")
  %bad = call i32 @fesetround(i32 12345)
  %g2 = call i32 @fegetround()
  %rc2 = call i32 @fesetround(i32 0)
  %g3 = call i32 @fegetround()
  %o3 = call double @llvm.experimental.constrained.fadd.f64(double %a, double %b, metadata !"round.dynamic", metadata !"fpexcept.ignore")
  %s1 = fadd double %o0, %o1
  %s2 = fadd double %s1, %o1n
  %s3 = fadd double %s2, %o3
  ret double %s3
}

; A quantum op that raises makes FLAGS non-empty; one with fpexcept.ignore does not.
define i32 @flags_by_op(double %x0, double %th, double %c) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.ignore")
  %t0 = call i32 @fetestexcept(i32 63)
  %z = call double @llvm.experimental.constrained.fdiv.f64(double %y, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict")
  %t1 = call i32 @fetestexcept(i32 63)
  %s = add i32 %t0, %t1
  ret i32 %s
}

; A loop: the quantum fesetround at the bottom of the body reaches the read at its top on the next
; trip (the back edge), not the read before the loop.
define i32 @mode_loop(i32 %m0, double %th, i32 %n) {
entry:
  %m = call i32 @cq_theta_ui32(i32 %m0, double %th)
  %g0 = call i32 @fegetround()
  br label %body
body:
  %i = phi i32 [ 0, %entry ], [ %i1, %body ]
  %g1 = call i32 @fegetround()
  %rc = call i32 @fesetround(i32 %m)
  %i1 = add i32 %i, 1
  %d = icmp slt i32 %i1, %n
  br i1 %d, label %body, label %out
out:
  %s = add i32 %g0, %g1
  ret i32 %s
}

; A classical fesetround(0) under a quantum predicate: the mode depends on the predicate.
define i32 @mode_under_pred(double %x0, double %th, double %k) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %c = fcmp ogt double %x, %k
  br i1 %c, label %arm, label %join
arm:
  %r = call i32 @fesetround(i32 0)
  br label %join
join:
  %g = call i32 @fegetround()
  ret i32 %g
}

; Calls. @set_mode sets a quantum mode, @reset_mode a classical one, @read_mode reads it, @nothing
; leaves the environment alone.
define i32 @set_mode(i32 %m) {
  %r = call i32 @fesetround(i32 %m)
  ret i32 %r
}
define void @reset_mode() {
  %r = call i32 @fesetround(i32 0)
  ret void
}
define i32 @read_mode() {
  %g = call i32 @fegetround()
  ret i32 %g
}
define void @nothing() {
  ret void
}
define i32 @calls_q(i32 %m0, double %th) {
entry:
  %m = call i32 @cq_theta_ui32(i32 %m0, double %th)
  %g0 = call i32 @fegetround()
  %r = call i32 @set_mode(i32 %m)
  %g1 = call i32 @fegetround()
  call void @nothing()
  %g2 = call i32 @fegetround()
  %h = call i32 @read_mode()
  call void @reset_mode()
  %g3 = call i32 @fegetround()
  %s0 = add i32 %g0, %g1
  %s1 = add i32 %s0, %g2
  %s2 = add i32 %s1, %h
  %s3 = add i32 %s2, %g3
  ret i32 %s3
}
; The same @nothing from a caller whose mode is classical: the state passes through per caller.
define i32 @calls_c(i32 %a) {
entry:
  call void @nothing()
  %g = call i32 @fegetround()
  ret i32 %g
}
; @reset_mode under a quantum predicate: the mode depends on the predicate after the join.
define i32 @call_under_pred(double %x0, double %th, double %k) {
entry:
  %x = call double @cq_theta_f64(double %x0, double %th)
  %c = fcmp ogt double %x, %k
  br i1 %c, label %arm, label %join
arm:
  call void @reset_mode()
  br label %join
join:
  %g = call i32 @fegetround()
  ret i32 %g
}

; fenv_t: feholdexcept saves the state and empties FLAGS, feupdateenv merges the saved FLAGS back,
; fesetenv(FE_DFL_ENV) (never saved) empties both.
define i32 @env_objects(double %x0, double %th, double %k) {
entry:
  %e = alloca [32 x i8]
  %x = call double @cq_theta_f64(double %x0, double %th)
  %c = fcmp ogt double %x, %k
  br i1 %c, label %arm, label %join
arm:
  %r = call i32 @feraiseexcept(i32 32)
  br label %join
join:
  %h = call i32 @feholdexcept(ptr %e)
  %t0 = call i32 @fetestexcept(i32 32)
  %u = call i32 @feupdateenv(ptr %e)
  %t1 = call i32 @fetestexcept(i32 32)
  %d = call i32 @fesetenv(ptr @_FE_DFL_ENV)
  %t2 = call i32 @fetestexcept(i32 32)
  %s0 = add i32 %t0, %t1
  %s1 = add i32 %s0, %t2
  ret i32 %s1
}

; fexcept_t: the saved FLAGS part comes back with fesetexceptflag.
define i32 @flag_objects(double %x0, double %th, double %c) {
entry:
  %f = alloca i16
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fdiv.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict")
  %g = call i32 @fegetexceptflag(ptr %f, i32 32)
  %h = call i32 @feholdexcept(ptr %f)
  %t0 = call i32 @fetestexcept(i32 32)
  %s = call i32 @fesetexceptflag(ptr %f, i32 32)
  %t1 = call i32 @fetestexcept(i32 32)
  %r = add i32 %t0, %t1
  ret i32 %r
}

; cq-fqlf (rule 23, principle 1): a call of an environment body with classical data while FLAGS holds is never the own
; symbol; the classical root @peek_root stays classical.
define i32 @peek_root(i32 %m) {
  %t = call i32 @fetestexcept(i32 %m)
  ret i32 %t
}
define i32 @calls_peek(double %x0, double %th, double %c) {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict")
  %p = call i32 @peek_root(i32 32)
  ret i32 %p
}

; cq-1bbg: an object's saved part is per specialization: the clone of @save_root that @calls_save reaches saves a
; flags rail, which never reaches the own symbol's restore.
define i32 @save_root(double %x) {
  %e = alloca [32 x i8]
  %s = call i32 @fegetenv(ptr %e)
  %y = call double @llvm.experimental.constrained.fdiv.f64(double %x, double 3.0, metadata !"round.dynamic", metadata !"fpexcept.strict")
  %r = call i32 @fesetenv(ptr %e)
  %t = call i32 @fetestexcept(i32 32)
  ret i32 %t
}
define i32 @calls_save(double %x0, double %th, double %c) {
  %x = call double @cq_theta_f64(double %x0, double %th)
  %y = call double @llvm.experimental.constrained.fmul.f64(double %x, double %c, metadata !"round.dynamic", metadata !"fpexcept.strict")
  %p = call i32 @save_root(double %y)
  ret i32 %p
}

; cq-1bbg: a save under a quantum predicate makes the object's part select(c, saved, old), a rail.
define i32 @save_pred(double %x0, double %th, double %k) {
entry:
  %e = alloca [32 x i8]
  %x = call double @cq_theta_f64(double %x0, double %th)
  %s0 = call i32 @fegetenv(ptr %e)
  %z = call i32 @feraiseexcept(i32 32)
  %c = fcmp ogt double %x, %k
  br i1 %c, label %arm, label %join
arm:
  %s1 = call i32 @fegetenv(ptr %e)
  br label %join
join:
  %r = call i32 @fesetenv(ptr %e)
  %t = call i32 @fetestexcept(i32 32)
  ret i32 %t
}

declare double @cq_theta_f64(double, double)
declare i32 @fegetenv(ptr)
declare i32 @cq_theta_ui32(i32, double)
declare i32 @fetestexcept(i32)
declare i32 @feraiseexcept(i32)
declare i32 @fegetround()
declare i32 @fesetround(i32)
declare i32 @feholdexcept(ptr)
declare i32 @feupdateenv(ptr)
declare i32 @fesetenv(ptr)
declare i32 @fegetexceptflag(ptr, i32)
declare i32 @fesetexceptflag(ptr, i32)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata)
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
  return nullptr; // a module function no taint fact reached is not published
}

int main() {
  LLVMContext Ctx;
  SMDiagnostic Err;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Err, Ctx);
  if (!M) {
    Err.print("taint_fenv", errs());
    return 2;
  }
  cq::TaintInfo T = cq::computeTaint(*M, {});
  auto expect = [&](const char *fn, std::initializer_list<std::pair<const char *, bool>> vals) {
    Function &F = *M->getFunction(fn);
    const cq::Specialization *S = entryOf(T, &F);
    if (!S) {
      CHECK(!T.isTainted(F), "@" << fn << " tainted but has no entry specialization");
      for (auto &[n, q] : vals)
        CHECK(!q, "@" << fn << " %" << n << " should be quantum, the function is not tainted");
      return;
    }
    for (auto &[n, q] : vals)
      CHECK(T.isQuantum(named(F, n), *S) == q,
            "@" << fn << " %" << n << " should be " << (q ? "quantum" : "classical"));
  };
  expect("flags_join", {{"t0", false}, {"t1", true}});
  expect("flags_classical", {{"t", false}});
  expect("mode_seq", {{"g0", false}, {"o0", false}, {"rc", true}, {"g1", true}, {"o1", true},
                      {"o1n", false}, {"bad", false}, {"g2", true}, {"rc2", false}, {"g3", false},
                      {"o3", false}});
  expect("flags_by_op", {{"y", true}, {"t0", false}, {"z", true}, {"t1", true}});
  expect("mode_loop", {{"g0", false}, {"g1", true}});
  expect("mode_under_pred", {{"g", true}});
  expect("calls_q", {{"g0", false}, {"g1", true}, {"g2", true}, {"h", true}, {"g3", false}});
  expect("calls_c", {{"g", false}});
  expect("call_under_pred", {{"g", true}});
  expect("env_objects", {{"t0", false}, {"t1", true}, {"t2", false}});
  expect("flag_objects", {{"t0", false}, {"t1", true}});
  expect("peek_root", {{"t", false}});
  expect("calls_peek", {{"p", true}});
  expect("save_root", {{"t", false}});
  expect("save_pred", {{"t", true}});
  outs() << "taint_fenv: " << (checks - failures) << "/" << checks << " checks pass\n";
  return failures ? 1 : 0;
}
