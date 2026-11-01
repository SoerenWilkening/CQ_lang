// Unit tests of calls::finalize (cq-by8; CR §1.4 "dead originals", rule 18) and of the twins it
// defines (cq-w1-calls; rule 18: the twin recomputes, XORs the result out, uncomputes).
//
// Each case parses a module shaped like what construct() leaves behind (clones already made, call
// sites already retargeted), runs calls::finalize and checks which functions and globals survive.
// The no-clone cases compare the printed module byte for byte before and after.
//
//   calls_finalize_tests            run every positive case
//   calls_finalize_tests <case>     run one case (positive or fatal)
#include <cstdio>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "cq/Calls.h"
#include "cq/Common.h"
#include "cq/Loops.h"
#include "cq/Lowering.h"
#include "cq/Taint.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace cq;

namespace {

int failures = 0;

void fail(const std::string &c, const std::string &msg) {
  ++failures;
  std::fprintf(stderr, "FAIL %s: %s\n", c.c_str(), msg.c_str());
}

std::unique_ptr<Module> parse(LLVMContext &ctx, const char *ir) {
  SMDiagnostic err;
  std::unique_ptr<Module> M = parseAssemblyString(ir, err, ctx);
  if (!M) {
    std::string s;
    raw_string_ostream os(s);
    err.print("finalize_tests", os);
    std::fprintf(stderr, "%s\n", os.str().c_str());
    std::exit(2);
  }
  return M;
}

std::string print(const Module &M) {
  std::string s;
  raw_string_ostream os(s);
  M.print(os, nullptr);
  return os.str();
}

std::set<std::string> globals(const Module &M) {
  std::set<std::string> out;
  for (const GlobalValue &G : M.global_values())
    out.insert(G.getName().str());
  return out;
}

std::string join(const std::set<std::string> &s) {
  std::string r;
  for (const std::string &x : s)
    r += (r.empty() ? "" : " ") + x;
  return r;
}

// Runs finalize and checks that exactly `gone` disappeared and the module still verifies.
void expectDropped(const std::string &c, const char *ir, const std::set<std::string> &gone) {
  LLVMContext ctx;
  auto M = parse(ctx, ir);
  std::set<std::string> before = globals(*M);
  for (const std::string &g : gone)
    if (!before.count(g))
      fail(c, "test bug: @" + g + " is not in the input");
  calls::finalize(*M);
  std::set<std::string> after = globals(*M), lost;
  for (const std::string &g : before)
    if (!after.count(g))
      lost.insert(g);
  if (lost != gone)
    fail(c, "dropped {" + join(lost) + "}, expected {" + join(gone) + "}");
  std::string v;
  raw_string_ostream os(v);
  if (verifyModule(*M, &os))
    fail(c, "module does not verify after finalize: " + os.str());
}

void expectIdentical(const std::string &c, const char *ir) {
  LLVMContext ctx;
  auto M = parse(ctx, ir);
  std::string before = print(*M);
  calls::finalize(*M);
  if (print(*M) != before)
    fail(c, "a module with no clone changed");
}

// A module with no clone: tainted-looking code, unused internal and external functions, ABI calls,
// a function whose name only resembles a clone. finalize must not touch any of it.
const char *kNoClone = R"(
@tbl = internal constant [2 x i32] [i32 1, i32 2]
@fp = global ptr @unused_internal

define i32 @entry(i32 %a, double %t) {
  %q = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %q, double %t)
  %r = call i32 @cq_template_add_i32_hl(i32 %q, i32 1)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
}

define internal i32 @unused_internal(i32 %x) {
  ret i32 %x
}

define internal i32 @dead_internal(i32 %x) {
  %y = call i32 @cq_theta_si32(i32 %x, double 1.0)
  ret i32 %y
}

define i32 @api(i32 %x) {
  ret i32 %x
}

define i32 @__cq_qx_f_10(i32 %x) {
  ret i32 %x
}

define i32 @cq_q_f_10(i32 %x) {
  ret i32 %x
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_theta_si32(i32, double)
declare i32 @unused_decl(i32)
)";

// A module with no function at all in the clone namespace and nothing else.
const char *kEmpty = R"(
@g = global i32 0
declare void @ext()
)";

// 06-shaped: the entry calls the clone, the original has no caller left.
const char *kRetargeted = R"(
define i32 @entry(i32 %a, double %t, i32 %b) {
  %q = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %q, double %t)
  %r = call fastcc i32 @__cq_q_f_10(i32 %q, i32 %b)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
}

define i32 @api(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @f(i32 %x, i32 %y) {
  %s = mul i32 %x, %y
  ret i32 %s
}

define internal fastcc i32 @__cq_q_f_10(i32 %x, i32 %y) {
  %r = call i32 @cq_template_mul_i32_hl(i32 %x, i32 %y)
  ret i32 %r
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
)";

// A classical call site (106-shaped: the original runs for a classical job) keeps the original.
const char *kClassicalCaller = R"(
define i32 @entry(i32 %h, i32 %c) {
  %r = call fastcc i32 @__cq_q_f_1(i32 %h)
  %s = call fastcc i32 @f(i32 %c)
  %t = add i32 %r, %s
  ret i32 %t
}

define internal fastcc i32 @f(i32 %x) {
  %s = add i32 %x, 1
  ret i32 %s
}

define internal fastcc i32 @__cq_q_f_1(i32 %x) {
  %r = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  ret i32 %r
}

define internal fastcc void @__cq_q_f_1_unc(i32 %o, i32 %x) {
  call void @cq_template_add_i32_hl_unc(i32 %o, i32 %x, i32 1)
  ret void
}

declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
)";

// Address-taken originals (96: select of function pointers; 102: signal handler) are kept.
const char *kAddressTaken = R"(
define i32 @entry(i32 %h, i1 %c) {
  %p = select i1 %c, ptr @sq, ptr @dbl
  %r = call fastcc i32 @__cq_q_sq_1(i32 %h)
  %s = call fastcc i32 @__cq_q_dbl_1(i32 %h)
  %u = call ptr @signal(i32 30, ptr @hnd)
  %t = select i1 %c, i32 %r, i32 %s
  ret i32 %t
}

define internal i32 @sq(i32 %x) {
  %y = mul i32 %x, %x
  ret i32 %y
}

define internal i32 @dbl(i32 %x) {
  %y = shl i32 %x, 1
  ret i32 %y
}

define internal void @hnd(i32 %x) {
  ret void
}

define internal fastcc i32 @__cq_q_sq_1(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @__cq_q_dbl_1(i32 %x) {
  ret i32 %x
}

define internal fastcc void @__cq_q_hnd_0_ctl(i32 %f, i32 %x) {
  ret void
}

declare ptr @signal(i32, ptr)
)";

// An original in a global initializer (97: @fps) or in @llvm.used is kept.
const char *kUsedGlobal = R"(
@fps = internal unnamed_addr constant [1 x ptr] [ptr @dbl]
@llvm.used = appending global [1 x ptr] [ptr @kept_used], section "llvm.metadata"

define ptr @entry(i32 %h) {
  %r = call fastcc i32 @__cq_q_dbl_1(i32 %h)
  %s = call fastcc i32 @__cq_q_kept_used_1(i32 %h)
  ret ptr @fps
}

define internal i32 @dbl(i32 %x) {
  ret i32 %x
}

define internal i32 @kept_used(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @__cq_q_dbl_1(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @__cq_q_kept_used_1(i32 %x) {
  ret i32 %x
}
)";

// 119-shaped: two originals that only call each other are both dropped.
const char *kMutual = R"(
define i32 @entry(i32 %h, i32 %n) {
  %r = call fastcc i32 @__cq_q_even_step_10(i32 %h, i32 %n)
  ret i32 %r
}

define internal fastcc i32 @even_step(i32 %x, i32 %n) {
  %c = icmp eq i32 %n, 0
  br i1 %c, label %done, label %rec
rec:
  %m = sub i32 %n, 1
  %r = call fastcc i32 @odd_step(i32 %x, i32 %m)
  ret i32 %r
done:
  ret i32 %x
}

define internal fastcc i32 @odd_step(i32 %x, i32 %n) {
  %m = sub i32 %n, 1
  %y = add i32 %x, 1
  %r = call fastcc i32 @even_step(i32 %y, i32 %m)
  ret i32 %r
}

define internal fastcc i32 @__cq_q_even_step_10(i32 %x, i32 %n) {
  %r = call fastcc i32 @__cq_q_odd_step_10(i32 %x, i32 %n)
  ret i32 %r
}

define internal fastcc i32 @__cq_q_odd_step_10(i32 %x, i32 %n) {
  %r = call fastcc i32 @__cq_q_even_step_10(i32 %x, i32 %n)
  ret i32 %r
}
)";

// 33-shaped: a chain f -> g -> h of originals, all retargeted.
const char *kChain = R"(
define i32 @entry(i32 %x) {
  %r = call fastcc i32 @__cq_q_f_1(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @f(i32 %x) {
  %r = call fastcc i32 @g(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @g(i32 %x) {
  %r = call fastcc i32 @h(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @h(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @__cq_q_f_1(i32 %x) {
  %r = call fastcc i32 @__cq_q_g_1(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @__cq_q_g_1(i32 %x) {
  %r = call fastcc i32 @__cq_q_h_1(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @__cq_q_h_1(i32 %x) {
  ret i32 %x
}
)";

// The chain again, but the entry also calls f classically: f is live, so are g and h through it.
const char *kLiveChain = R"(
define i32 @entry(i32 %x, i32 %c) {
  %r = call fastcc i32 @__cq_q_f_1(i32 %x)
  %s = call fastcc i32 @f(i32 %c)
  %t = add i32 %r, %s
  ret i32 %t
}

define internal fastcc i32 @f(i32 %x) {
  %r = call fastcc i32 @g(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @g(i32 %x) {
  %r = call fastcc i32 @h(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @h(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @__cq_q_f_1(i32 %x) {
  %r = call fastcc i32 @__cq_q_g_1(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @__cq_q_g_1(i32 %x) {
  %r = call fastcc i32 @__cq_q_h_1(i32 %x)
  ret i32 %r
}

define internal fastcc i32 @__cq_q_h_1(i32 %x) {
  ret i32 %x
}
)";

// 170-shaped: an externally visible injected-library original whose every call was retargeted is
// dropped (CR §1.4 drops __muldc3); a bounds clone (§1.4 _b) and a libm-named clone are read too.
const char *kExternal = R"(
define { double, double } @entry(double %a, double %b, i32 %h, i32 %n) {
  %r = call fastcc { i32, i32 } @__cq_q___muldc3_1100(i32 %h, i32 %h, double %a, double %b)
  %s = call fastcc i32 @__cq_q_memcmp_001_b3(ptr null, ptr null, i32 %n)
  %t = call fastcc i32 @__cq_q_sin_1(i32 %h)
  ret { double, double } zeroinitializer
}

define { double, double } @__muldc3(double %a, double %b, double %c, double %d) {
  %x = fmul double %a, %c
  %r = insertvalue { double, double } zeroinitializer, double %x, 0
  ret { double, double } %r
}

define i32 @memcmp(ptr %a, ptr %b, i64 %n) {
  ret i32 0
}

define internal fastcc { i32, i32 } @__cq_q___muldc3_1100(i32 %a, i32 %b, double %c, double %d) {
  ret { i32, i32 } zeroinitializer
}

define internal fastcc i32 @__cq_q_memcmp_001_b3(ptr %a, ptr %b, i32 %n) {
  ret i32 %n
}

declare i32 @__cq_q_sin_1(i32)
)";

// What only a dropped body referenced goes with it when it has no symbol of its own (a local
// helper, a local table, CQ.h declarations); an external declaration nothing else uses goes too,
// an externally visible helper and global stay.
const char *kDeadRefs = R"(
@tbl = internal constant [2 x i32] [i32 1, i32 2]
@tblp = internal constant ptr @tbl
@ext_g = global i32 0

define i32 @entry(i32 %h) {
  %r = call fastcc i32 @__cq_q_f_1(i32 %h)
  ret i32 %r
}

define internal fastcc i32 @f(i32 %x) {
  %p = load ptr, ptr @tblp
  %a = getelementptr i32, ptr %p, i32 %x
  %v = load i32, ptr %a
  %w = call i32 @helper(i32 %v)
  %e = call i32 @ext_helper(i32 %w)
  %g = load i32, ptr @ext_g
  %t = call i32 @cq_theta_si32(i32 %e, double 1.0)
  %u = add i32 %t, %g
  ret i32 %u
}

define internal i32 @helper(i32 %x) {
  call void @only_helper_decl()
  ret i32 %x
}

define i32 @ext_helper(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @__cq_q_f_1(i32 %x) {
  ret i32 %x
}

declare i32 @cq_theta_si32(i32, double)
declare void @only_helper_decl()
)";

// A helper and a table a dropped original shares with live code stay.
const char *kSharedRefs = R"(
@tbl = internal constant [2 x i32] [i32 1, i32 2]

define i32 @entry(i32 %h, i32 %c) {
  %r = call fastcc i32 @__cq_q_f_1(i32 %h)
  %s = call i32 @helper(i32 %c)
  %a = getelementptr i32, ptr @tbl, i32 %c
  %v = load i32, ptr %a
  %t = add i32 %s, %v
  ret i32 %t
}

define internal fastcc i32 @f(i32 %x) {
  %a = getelementptr i32, ptr @tbl, i32 %x
  %v = load i32, ptr %a
  %w = call i32 @helper(i32 %v)
  ret i32 %w
}

define internal i32 @helper(i32 %x) {
  ret i32 %x
}

define internal fastcc i32 @__cq_q_f_1(i32 %x) {
  ret i32 %x
}
)";

// Only a rule 27 declared clone, of a function with no body here: nothing to drop, unused
// declarations included (only what a dropped body referenced is ever considered).
const char *kDeclaredOnly = R"(
define i32 @entry(i32 %h) {
  %r = call i32 @__cq_q_ext_1(i32 %h)
  ret i32 %r
}

define internal i32 @unused_internal(i32 %x) {
  ret i32 %x
}

declare i32 @ext(i32)
declare i32 @__cq_q_ext_1(i32)
declare void @unused_decl()
)";

// A twin alone still names its original.
const char *kTwinOnly = R"(
define void @entry(i32 %o, i32 %h) {
  call fastcc void @__cq_q_f_1_unc(i32 %o, i32 %h)
  ret void
}

define internal fastcc i32 @f(i32 %x) {
  ret i32 %x
}

define internal fastcc void @__cq_q_f_1_unc(i32 %o, i32 %x) {
  ret void
}
)";


// --- twins (cq-w1-calls) ---

// 07-shaped: the entry calls the twin of a lowered clone; finalize defines it from the clone's body
// with the copy-out turned into an XOR into %out.
// A field-wise result (CR §1.4, 165/64): { handle, classical i64, handle }. The twin takes one out per
// handle field, in field order; each copy-out targets its out, the classical field and the insertvalue
// chain go.
const char *kTwinFieldwise = R"(
define i32 @entry(i32 %a, double %t, i64 %c) {
  %q = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %q, double %t)
  %r = call fastcc { i32, i64, i32 } @__cq_q_g_10(i32 %q, i64 %c)
  %h0 = extractvalue { i32, i64, i32 } %r, 0
  %h2 = extractvalue { i32, i64, i32 } %r, 2
  call void @__cq_q_g_10_unc(i32 %h0, i32 %h2, i32 %q, i64 %c)
  call void @cqrt_free(i32 %h0)
  call void @cqrt_free(i32 %h2)
  %m = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %m
}

define internal fastcc { i32, i64, i32 } @g(i32 %v, i64 %c) {
  %s = mul i32 %v, %v
  %d = add i64 %c, 1
  %t = add i32 %v, 1
  %a = insertvalue { i32, i64, i32 } poison, i32 %s, 0
  %b = insertvalue { i32, i64, i32 } %a, i64 %d, 1
  %e = insertvalue { i32, i64, i32 } %b, i32 %t, 2
  ret { i32, i64, i32 } %e
}

define internal fastcc { i32, i64, i32 } @__cq_q_g_10(i32 %0, i64 %1) {
  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)
  %4 = add i64 %1, 1
  %5 = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)
  %6 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %6)
  %7 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %5, i32 %7)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %0, i32 1)
  call void @cqrt_free(i32 %5)
  call void @cq_template_mul_i32_unc(i32 %3, i32 %0, i32 %0)
  call void @cqrt_free(i32 %3)
  %8 = insertvalue { i32, i64, i32 } poison, i32 %6, 0
  %9 = insertvalue { i32, i64, i32 } %8, i64 %4, 1
  %10 = insertvalue { i32, i64, i32 } %9, i32 %7, 2
  ret { i32, i64, i32 } %10
}

declare void @__cq_q_g_10_unc(i32, i32, i32, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
)";

const char *kTwinFieldwiseExpected = R"(define internal void @__cq_q_g_10_unc(i32 %out0, i32 %out1, i32 %0, i64 %1) {
  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)
  %4 = add i64 %1, 1
  %5 = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)
  call void @cqrt_copy_i32(i32 %3, i32 %out0)
  call void @cqrt_copy_i32(i32 %5, i32 %out1)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %0, i32 1)
  call void @cqrt_free(i32 %5)
  call void @cq_template_mul_i32_unc(i32 %3, i32 %0, i32 %0)
  call void @cqrt_free(i32 %3)
  ret void
}
)";

const char *kTwinDefine = R"(
define i32 @entry(i32 %a, double %t, i32 %c) {
  %q = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %q, double %t)
  %r = call fastcc i32 @__cq_q_f_10(i32 %q, i32 %c)
  call void @__cq_q_f_10_unc(i32 %r, i32 %q, i32 %c)
  call void @cqrt_free(i32 %r)
  %m = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %m
}

define internal fastcc i32 @f(i32 %v, i32 %c) {
  %s = mul i32 %v, %v
  %t = add i32 %s, %c
  ret i32 %t
}

define internal fastcc i32 @__cq_q_f_10(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 %1)
  %5 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %4, i32 %5)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %3, i32 %1)
  call void @cqrt_free(i32 %4)
  call void @cq_template_mul_i32_unc(i32 %3, i32 %0, i32 %0)
  call void @cqrt_free(i32 %3)
  ret i32 %5
}

declare void @__cq_q_f_10_unc(i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
)";

const char *kTwinDefineExpected = R"(define internal void @__cq_q_f_10_unc(i32 %out, i32 %0, i32 %1) {
  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 %1)
  call void @cqrt_copy_i32(i32 %4, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %3, i32 %1)
  call void @cqrt_free(i32 %4)
  call void @cq_template_mul_i32_unc(i32 %3, i32 %0, i32 %0)
  call void @cqrt_free(i32 %3)
  ret void
}
)";

// 33-shaped: the twin of g calls the twin of h, which finalize defines in turn; a classical branch in
// the clone (119's depth test) is kept, every return's copy-out becomes an XOR.
const char *kTwinChain = R"(
define i32 @entry(i32 %q, i32 %c, i32 %n) {
  %r = call fastcc i32 @__cq_q_g_100(i32 %q, i32 %c, i32 %n)
  call void @__cq_q_g_100_unc(i32 %r, i32 %q, i32 %c, i32 %n)
  call void @cqrt_free(i32 %r)
  ret i32 0
}

define internal fastcc i32 @g(i32 %v, i32 %c, i32 %n) {
  ret i32 %v
}

define internal fastcc i32 @h(i32 %v, i32 %c) {
  ret i32 %v
}

define internal fastcc i32 @__cq_q_g_100(i32 %0, i32 %1, i32 %2) {
  %b = icmp slt i32 %2, 1
  br i1 %b, label %base, label %rec
base:
  %f0 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %f0)
  ret i32 %f0
rec:
  %hr = call fastcc i32 @__cq_q_h_10(i32 %0, i32 %1)
  %gm = call i32 @cq_template_mul_i32(i32 %hr, i32 %0)
  %f1 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %gm, i32 %f1)
  call void @cq_template_mul_i32_unc(i32 %gm, i32 %hr, i32 %0)
  call void @cqrt_free(i32 %gm)
  call void @__cq_q_h_10_unc(i32 %hr, i32 %0, i32 %1)
  call void @cqrt_free(i32 %hr)
  ret i32 %f1
}

define internal fastcc i32 @__cq_q_h_10(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %1)
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %4)
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %0, i32 %1)
  call void @cqrt_free(i32 %3)
  ret i32 %4
}

declare void @__cq_q_g_100_unc(i32, i32, i32, i32)
declare void @__cq_q_h_10_unc(i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
)";

// 119-shaped: the forward clone fires a phase, so the twin recomputes through the _pure clone.
const char *kTwinPure = R"(
define i32 @entry(i32 %q, double %p) {
  %r = call fastcc i32 @__cq_q_f_10(i32 %q, double %p)
  call void @__cq_q_f_10_unc(i32 %r, i32 %q, double %p)
  call void @cqrt_free(i32 %r)
  ret i32 0
}

define internal fastcc i32 @f(i32 %v, double %p) {
  ret i32 %v
}

define internal fastcc i32 @__cq_q_f_10(i32 %0, double %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  call void @cqrt_rz_i1(i32 %3, double %1)
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %4)
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %0, i32 3)
  call void @cqrt_free(i32 %3)
  ret i32 %4
}

define internal fastcc i32 @__cq_q_f_10_pure(i32 %0, double %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %4)
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %0, i32 3)
  call void @cqrt_free(i32 %3)
  ret i32 %4
}

declare void @__cq_q_f_10_unc(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
)";

// Rule 27: the twin of a declared clone stays a declaration (whatever is linked defines it).
const char *kTwinDeclared = R"(
define i32 @entry(i32 %h, i32 %c) {
  %r = call i32 @__cq_q_ext_10(i32 %h, i32 %c, i32 4)
  %s = call i32 @cq_template_add_i32_hl(i32 %r, i32 1)
  call void @__cq_q_ext_10_unc(i32 %r, i32 %h, i32 %c, i32 4)
  call void @cqrt_free(i32 %r)
  ret i32 %s
}
declare i32 @ext(i32, i32)
declare i32 @__cq_q_ext_10(i32, i32, i32)
declare void @__cq_q_ext_10_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
)";

// A twin of a clone with a phase and no _pure clone would replay the phase.
const char *kTwinEffect = R"(
define i32 @entry(i32 %q, double %p) {
  %r = call fastcc i32 @__cq_q_f_10(i32 %q, double %p)
  call void @__cq_q_f_10_unc(i32 %r, i32 %q, double %p)
  ret i32 0
}
define internal fastcc i32 @f(i32 %v, double %p) {
  ret i32 %v
}
define internal fastcc i32 @__cq_q_f_10(i32 %0, double %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  call void @cqrt_rz_i1(i32 %3, double %1)
  %4 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %3, i32 %4)
  call void @cq_template_add_i32_hl_unc(i32 %3, i32 %0, i32 3)
  call void @cqrt_free(i32 %3)
  ret i32 %4
}
declare void @__cq_q_f_10_unc(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
)";

// A clone that returns a rail other than its copy-out has no twin by rule 18's construction.
const char *kTwinNoCopyOut = R"(
define i32 @entry(i32 %q) {
  %r = call fastcc i32 @__cq_q_f_1(i32 %q)
  call void @__cq_q_f_1_unc(i32 %r, i32 %q)
  ret i32 0
}
define internal fastcc i32 @f(i32 %v) {
  ret i32 %v
}
define internal fastcc i32 @__cq_q_f_1(i32 %0) {
  %2 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  ret i32 %2
}
declare void @__cq_q_f_1_unc(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
)";

// 119-shaped (cq-mjwb): the return phi is chosen classically, so the clone copies out on each
// incoming edge into a result rail of its own and returns the phi of those rails; the base case's
// edge (critical) has a block of its own. The twin XORs each arm into %out and returns void.
const char *kTwinReturnPhi = R"(
define i32 @entry(i32 %q, i32 %n) {
  %r = call fastcc i32 @__cq_q_f_10(i32 %q, i32 %n)
  call void @__cq_q_f_10_unc(i32 %r, i32 %q, i32 %n)
  call void @cqrt_free(i32 %r)
  ret i32 0
}

define internal fastcc i32 @f(i32 %v, i32 %n) {
  ret i32 %v
}

define internal fastcc i32 @__cq_q_f_10(i32 %0, i32 %1) {
  %z = icmp slt i32 %1, 1
  br i1 %z, label %base, label %arm

base:
  %b = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %b)
  br label %join

arm:
  %u = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  %a = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %u, i32 %a)
  call void @cq_template_add_i32_hl_unc(i32 %u, i32 %0, i32 3)
  call void @cqrt_free(i32 %u)
  br label %join

join:
  %r = phi i32 [ %b, %base ], [ %a, %arm ]
  ret i32 %r
}

declare void @__cq_q_f_10_unc(i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
)";

const char *kTwinReturnPhiExpected = R"(define internal void @__cq_q_f_10_unc(i32 %out, i32 %0, i32 %1) {
  %z = icmp slt i32 %1, 1
  br i1 %z, label %base, label %arm

base:                                             ; preds = %2
  call void @cqrt_copy_i32(i32 %0, i32 %out)
  br label %join

arm:                                              ; preds = %2
  %u = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)
  call void @cqrt_copy_i32(i32 %u, i32 %out)
  call void @cq_template_add_i32_hl_unc(i32 %u, i32 %0, i32 3)
  call void @cqrt_free(i32 %u)
  br label %join

join:                                             ; preds = %arm, %base
  ret void
}
)";

// The same, with a classical arm seeding its result rail (alloc_<W>(5)): its twin would XOR the
// constant into %out, which is not built.
const char *kTwinClassicalArm = R"(
define i32 @entry(i32 %q, i32 %n) {
  %r = call fastcc i32 @__cq_q_f_10(i32 %q, i32 %n)
  call void @__cq_q_f_10_unc(i32 %r, i32 %q, i32 %n)
  call void @cqrt_free(i32 %r)
  ret i32 0
}

define internal fastcc i32 @f(i32 %v, i32 %n) {
  ret i32 %v
}

define internal fastcc i32 @__cq_q_f_10(i32 %0, i32 %1) {
  %z = icmp slt i32 %1, 1
  br i1 %z, label %base, label %arm

base:
  %b = call i32 @cqrt_alloc_i32(i32 5)
  br label %join

arm:
  %a = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %0, i32 %a)
  br label %join

join:
  %r = phi i32 [ %b, %base ], [ %a, %arm ]
  ret i32 %r
}

declare void @__cq_q_f_10_unc(i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
)";

std::string printFn(const Module &M, StringRef name) {
  const Function *F = M.getFunction(name);
  if (!F)
    return "<missing @" + name.str() + ">";
  std::string s;
  raw_string_ostream os(s);
  F->print(os);
  return os.str();
}

// Runs finalize; checks the module verifies, every named twin is defined (internal, C calling
// convention) and `check` on the result.
void expectTwins(const std::string &c, const char *ir, const std::vector<std::string> &defined,
                 const std::vector<std::string> &declared, std::function<void(Module &)> check = {}) {
  LLVMContext ctx;
  auto M = parse(ctx, ir);
  calls::finalize(*M);
  std::string v;
  raw_string_ostream os(v);
  if (verifyModule(*M, &os))
    fail(c, "module does not verify after finalize: " + os.str());
  for (const std::string &n : defined) {
    Function *F = M->getFunction(n);
    if (!F || F->isDeclaration())
      fail(c, "twin @" + n + " is not defined");
    else if (!F->hasInternalLinkage() || F->getCallingConv() != CallingConv::C)
      fail(c, "twin @" + n + " is not internal with the C calling convention");
  }
  for (const std::string &n : declared) {
    Function *F = M->getFunction(n);
    if (!F || !F->isDeclaration())
      fail(c, "@" + n + " should stay a declaration");
  }
  if (check)
    check(*M);
}

void twinDefine() {
  expectTwins("twin_define", kTwinDefine, {"__cq_q_f_10_unc"}, {}, [](Module &M) {
    std::string got = printFn(M, "__cq_q_f_10_unc");
    if (got != kTwinDefineExpected)
      fail("twin_define", "twin body:\n" + got + "expected:\n" + kTwinDefineExpected);
    if (M.getFunction("f"))
      fail("twin_define", "the original @f has no classical caller and should be dropped");
  });
}

void twinFieldwise() {
  expectTwins("twin_fieldwise", kTwinFieldwise, {"__cq_q_g_10_unc"}, {}, [](Module &M) {
    std::string got = printFn(M, "__cq_q_g_10_unc");
    if (got != kTwinFieldwiseExpected)
      fail("twin_fieldwise", "twin body:\n" + got + "expected:\n" + kTwinFieldwiseExpected);
  });
}

void twinChain() {
  expectTwins("twin_chain", kTwinChain, {"__cq_q_g_100_unc", "__cq_q_h_10_unc"}, {}, [](Module &M) {
    Function *T = M.getFunction("__cq_q_g_100_unc");
    unsigned rets = 0, xors = 0;
    for (Instruction &I : instructions(*T)) {
      if (auto *R = dyn_cast<ReturnInst>(&I)) {
        ++rets;
        if (R->getReturnValue())
          fail("twin_chain", "a twin returns a value");
      }
      if (auto *CB = dyn_cast<CallInst>(&I)) {
        StringRef n = CB->getCalledFunction()->getName();
        if (n == "cqrt_alloc_i32" && isa<ConstantInt>(CB->getArgOperand(0)) &&
            cast<ConstantInt>(CB->getArgOperand(0))->isZero())
          fail("twin_chain", "a result rail alloc survived in the twin");
        if (n == "cqrt_copy_i32" && CB->getArgOperand(1) == T->getArg(0))
          ++xors;
      }
    }
    if (rets != 2 || xors != 2)
      fail("twin_chain", "expected two returns, each preceded by an XOR into %out; got " + std::to_string(rets) +
                             " returns, " + std::to_string(xors) + " XORs");
  });
}

void twinPure() {
  expectTwins("twin_pure", kTwinPure, {"__cq_q_f_10_unc"}, {}, [](Module &M) {
    for (Instruction &I : instructions(*M.getFunction("__cq_q_f_10_unc")))
      if (auto *CB = dyn_cast<CallInst>(&I); CB && CB->getCalledFunction()->getName() == "cqrt_rz_i1")
        fail("twin_pure", "the twin replays the phase: it must recompute through the _pure clone");
  });
}

void twinReturnPhi() {
  expectTwins("twin_return_phi", kTwinReturnPhi, {"__cq_q_f_10_unc"}, {}, [](Module &M) {
    std::string got = printFn(M, "__cq_q_f_10_unc");
    if (got != kTwinReturnPhiExpected)
      fail("twin_return_phi", "twin body:\n" + got + "expected:\n" + kTwinReturnPhiExpected);
  });
}

void twinDeclared() { expectTwins("twin_declared", kTwinDeclared, {}, {"__cq_q_ext_10", "__cq_q_ext_10_unc"}); }

// --- fatal inputs ---

const char *kUniquified = R"(
define i32 @entry(i32 %h) {
  %r = call fastcc i32 @__cq_q_f_1(i32 %h)
  %s = call fastcc i32 @__cq_q_f_1.1(i32 %h)
  ret i32 %r
}
define internal fastcc i32 @f(i32 %x) {
  ret i32 %x
}
define internal fastcc i32 @__cq_q_f_1(i32 %x) {
  ret i32 %x
}
define internal fastcc i32 @__cq_q_f_1.1(i32 %x) {
  ret i32 %x
}
)";

// "__cq_q_a_10_b3_1" reads as a clone of @a (mask 10, bounds 3, 1) and of @a_10_b3 (mask 1).
const char *kAmbiguous = R"(
define i32 @entry(i32 %h) {
  %r = call fastcc i32 @__cq_q_a_10_b3_1(i32 %h, i32 0)
  ret i32 %r
}
define internal fastcc i32 @a(i32 %x, i32 %y) {
  ret i32 %x
}
define internal fastcc i32 @a_10_b3(i32 %x) {
  ret i32 %x
}
define internal fastcc i32 @__cq_q_a_10_b3_1(i32 %x, i32 %y) {
  ret i32 %x
}
)";

// An externally visible function rewritten in place (it calls ABI symbols) that also has a clone
// and no in-module caller.
const char *kInPlace = R"(
define i32 @g(i32 %a, double %t) {
  %q = call i32 @cqrt_alloc_i32(i32 %a)
  call void @cqrt_ry_i32(i32 %q, double %t)
  %m = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %m
}
define i32 @entry(i32 %h, double %t) {
  %r = call fastcc i32 @__cq_q_g_10(i32 %h, double %t)
  ret i32 %r
}
define internal fastcc i32 @__cq_q_g_10(i32 %h, double %t) {
  ret i32 %h
}
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
)";

// materialize reads the result kind from the run's TaintInfo; with no call site lowered yet there is none.
void materializeNoTaint() {
  LLVMContext ctx;
  auto M = parse(ctx, "define internal i32 @f(i32 %x) {\n  ret i32 %x\n}\n");
  Specialization S;
  S.F = M->getFunction("f");
  S.mask = "1";
  calls::materialize(*M, S);
}

const std::map<std::string, std::function<void()>> kPositive = {
    {"noop_no_clone", [] { expectIdentical("noop_no_clone", kNoClone); }},
    {"noop_clone_namespace_absent", [] { expectIdentical("noop_clone_namespace_absent", kEmpty); }},
    {"drop_retargeted", [] { expectDropped("drop_retargeted", kRetargeted, {"f"}); }},
    {"keep_classical_caller", [] { expectDropped("keep_classical_caller", kClassicalCaller, {}); }},
    {"keep_address_taken", [] { expectDropped("keep_address_taken", kAddressTaken, {}); }},
    {"keep_used_global", [] { expectDropped("keep_used_global", kUsedGlobal, {}); }},
    {"drop_mutual_recursion", [] { expectDropped("drop_mutual_recursion", kMutual, {"even_step", "odd_step"}); }},
    {"drop_chain", [] { expectDropped("drop_chain", kChain, {"f", "g", "h"}); }},
    {"keep_live_chain", [] { expectDropped("keep_live_chain", kLiveChain, {}); }},
    {"drop_external_original", [] { expectDropped("drop_external_original", kExternal, {"__muldc3", "memcmp"}); }},
    {"drop_dead_references",
     [] {
       expectDropped("drop_dead_references", kDeadRefs,
                     {"f", "helper", "tbl", "tblp", "cq_theta_si32", "only_helper_decl"});
     }},
    {"keep_shared_references", [] { expectDropped("keep_shared_references", kSharedRefs, {"f"}); }},
    {"declared_clone_only", [] { expectDropped("declared_clone_only", kDeclaredOnly, {}); }},
    {"twin_only", [] { expectDropped("twin_only", kTwinOnly, {"f"}); }},
    {"twin_define", twinDefine},
    {"twin_fieldwise", twinFieldwise},
    {"twin_chain", twinChain},
    {"twin_pure", twinPure},
    {"twin_declared", twinDeclared},
    {"twin_return_phi", twinReturnPhi},
};

const std::map<std::string, std::function<void()>> kFatal = {
    {"fatal_uniquified", [] { expectDropped("fatal_uniquified", kUniquified, {}); }},
    {"fatal_ambiguous", [] { expectDropped("fatal_ambiguous", kAmbiguous, {}); }},
    {"fatal_inplace_entry", [] { expectDropped("fatal_inplace_entry", kInPlace, {}); }},
    {"fatal_materialize_no_taint", materializeNoTaint},
    {"fatal_twin_effect", [] { expectTwins("fatal_twin_effect", kTwinEffect, {}, {}); }},
    {"fatal_twin_no_copyout", [] { expectTwins("fatal_twin_no_copyout", kTwinNoCopyOut, {}, {}); }},
    {"fatal_twin_classical_arm", [] { expectTwins("fatal_twin_classical_arm", kTwinClassicalArm, {}, {}); }},
};

} // namespace

int main(int argc, char **argv) {
  if (argc > 1) {
    std::string c = argv[1];
    if (auto it = kPositive.find(c); it != kPositive.end())
      it->second();
    else if (auto jt = kFatal.find(c); jt != kFatal.end()) {
      jt->second();
      std::fprintf(stderr, "FAIL %s: expected a fatal error\n", c.c_str());
      return 1;
    } else {
      std::fprintf(stderr, "unknown case %s\n", c.c_str());
      return 2;
    }
  } else {
    for (auto &[name, fn] : kPositive)
      fn();
  }
  if (failures)
    return 1;
  std::printf("ok\n");
  return 0;
}
