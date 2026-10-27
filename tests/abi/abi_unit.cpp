// cq-w0-abi unit tests: widths i1 i7 i100 i128 f16 f80, every template shape, _rm/_rmq/_exc, _s,
// every core form, every clone suffix, rule 27's asm clone name, and the rejection of non-canonical
// spellings (parse -> nullopt, name -> internal error).
#include "cq/Abi.h"
#include "cq/Common.h"
#include "../../pass/lib/abi/AbiLiteral.h"

#include <cstdio>
#include <cstdlib>
#include <functional>
#include <string>
#include <sys/wait.h>
#include <unistd.h>

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

using namespace cq;
using namespace cq::abi;

static unsigned gChecks = 0, gFails = 0;

#define CHECK(cond, ...)                                                                           \
  do {                                                                                             \
    ++gChecks;                                                                                     \
    if (!(cond)) {                                                                                 \
      ++gFails;                                                                                    \
      std::fprintf(stderr, "FAIL %s:%d: %s: ", __FILE__, __LINE__, #cond);                         \
      std::fprintf(stderr, __VA_ARGS__);                                                           \
      std::fprintf(stderr, "\n");                                                                  \
    }                                                                                              \
  } while (0)

// Runs f in a child; passes when the child dies (report_fatal_error) instead of returning.
static bool dies(const std::function<void()> &f) {
  std::fflush(nullptr);
  pid_t pid = fork();
  if (pid == 0) {
    std::freopen("/dev/null", "w", stderr);
    f();
    _exit(0);
  }
  int st = 0;
  waitpid(pid, &st, 0);
  return !(WIFEXITED(st) && WEXITSTATUS(st) == 0);
}

static std::string str(llvm::Type *t) {
  std::string s;
  llvm::raw_string_ostream os(s);
  t->print(os);
  return s;
}

static llvm::LLVMContext C;

// ---------------------------------------------------------------------------------------------
static void testTypes() {
  // The death harness itself: a returning body is not a death, a fatal error is.
  CHECK(!dies([] {}), "dies() of an empty body");
  CHECK(!dies([] { TemplateSpec s; s.op = "add"; s.w = {Kind::Int, 32}; name(s, false); }), "valid name");
  CHECK(dies([] { internalError("probe"); }), "dies() of internalError");
  struct { llvm::Type *t; Kind k; unsigned bits; } rows[] = {
      {llvm::Type::getInt1Ty(C), Kind::Int, 1},       {llvm::IntegerType::get(C, 7), Kind::Int, 7},
      {llvm::IntegerType::get(C, 100), Kind::Int, 100}, {llvm::Type::getInt128Ty(C), Kind::Int, 128},
      {llvm::Type::getHalfTy(C), Kind::Fp, 16},       {llvm::Type::getFloatTy(C), Kind::Fp, 32},
      {llvm::Type::getDoubleTy(C), Kind::Fp, 64},     {llvm::Type::getX86_FP80Ty(C), Kind::Fp, 80},
  };
  for (auto &r : rows) {
    RailType rt = railTypeOf(r.t);
    CHECK(rt.kind == r.k && rt.bits == r.bits, "railTypeOf(%s)", str(r.t).c_str());
    CHECK(irTypeOf(C, rt) == r.t, "irTypeOf(railTypeOf(%s))", str(r.t).c_str());
  }
  CHECK(handleTy(C) == llvm::Type::getInt32Ty(C), "handleTy is i32");
  CHECK(dies([] { railTypeOf(llvm::Type::getFP128Ty(C)); }), "fp128 has no rail type");
  // bf16 is a CR §1.1 rail at 3aaafe1, but RailType cannot tell it from f16 until the freeze-rule
  // bead cq-dvj lands; until then railTypeOf(bfloat) is cq::unimplemented.
  CHECK(dies([] { railTypeOf(llvm::Type::getBFloatTy(C)); }), "bfloat waits on cq-dvj");
  CHECK(dies([] { railTypeOf(llvm::PointerType::getUnqual(C)); }), "ptr is not a rail");
  CHECK(dies([] { railTypeOf(llvm::FixedVectorType::get(llvm::Type::getInt32Ty(C), 4)); }), "vector");
  CHECK(dies([] { irTypeOf(C, {Kind::Fp, 128}); }), "f128");
  CHECK(dies([] { irTypeOf(C, {Kind::Int, 0}); }), "i0");
}

// ---------------------------------------------------------------------------------------------
// Template rows: canonical name of the forward form, and its signature.
struct TRow { const char *sym; const char *sig; };
static const TRow kTemplates[] = {
    // integer binary, widths i1 i7 i100 i128, shapes bare / hl / lh
    {"cq_template_and_i1", "i32 (i32, i32)"},
    {"cq_template_xor_i1_hl", "i32 (i32, i1)"},
    {"cq_template_add_i7_hl", "i32 (i32, i7)"},
    {"cq_template_add_i100", "i32 (i32, i32)"},
    {"cq_template_mul_i128_hl", "i32 (i32, i128)"},
    {"cq_template_sub_i7_lh", "i32 (i7, i32)"},
    {"cq_template_shl_i100_lh", "i32 (i100, i32)"},
    {"cq_template_udiv_i128_lh", "i32 (i128, i32)"},
    {"cq_template_srem_i1_hl", "i32 (i32, i1)"},
    {"cq_template_ashr_i128", "i32 (i32, i32)"},
    {"cq_template_usub_sat_i7_lh", "i32 (i7, i32)"},
    {"cq_template_uadd_sat_i100_hl", "i32 (i32, i100)"},
    {"cq_template_smax_i128", "i32 (i32, i32)"},
    {"cq_template_umin_i7_hl", "i32 (i32, i7)"},
    {"cq_template_uadd_overflow_i128_hl", "i32 (i32, i128)"},
    {"cq_template_sadd_overflow_i7", "i32 (i32, i32)"},
    {"cq_template_smul_overflow_i100_hl", "i32 (i32, i100)"},
    {"cq_template_usub_overflow_i128_lh", "i32 (i128, i32)"},
    {"cq_template_ssub_overflow_i7_lh", "i32 (i7, i32)"},
    // fp binary, widths f16 f80; _lh on a commutative fp op is the NaN-literal spelling
    {"cq_template_fadd_f16", "i32 (i32, i32)"},
    {"cq_template_fadd_f16_hl", "i32 (i32, half)"},
    {"cq_template_fadd_f80_lh", "i32 (x86_fp80, i32)"},
    {"cq_template_fmul_f16_lh", "i32 (half, i32)"},
    {"cq_template_fsub_f80_lh", "i32 (x86_fp80, i32)"},
    {"cq_template_fdiv_f16_hl", "i32 (i32, half)"},
    {"cq_template_frem_f80_hl", "i32 (i32, x86_fp80)"},
    {"cq_template_copysign_f16_lh", "i32 (half, i32)"},
    {"cq_template_fmax_f80_lh", "i32 (x86_fp80, i32)"},
    {"cq_template_fmin_f16_hl", "i32 (i32, half)"},
    {"cq_template_is_fpclass_f80_hl", "i32 (i32, i32)"},
    {"cq_template_is_fpclass_f16_hl", "i32 (i32, i32)"},
    // compares
    {"cq_template_icmp_eq_i1", "i32 (i32, i32)"},
    {"cq_template_icmp_slt_i128_hl", "i32 (i32, i128)"},
    {"cq_template_icmp_uge_i7_hl", "i32 (i32, i7)"},
    {"cq_template_icmp_sle_i100", "i32 (i32, i32)"},
    {"cq_template_fcmp_uno_f16_hl", "i32 (i32, half)"},
    {"cq_template_fcmp_oge_f80", "i32 (i32, i32)"},
    {"cq_template_fcmp_true_f80_hl", "i32 (i32, x86_fp80)"},
    {"cq_template_fcmps_ogt_f64_hl_exc", "i32 (i32, double)"},
    {"cq_template_fcmps_ult_f16", "i32 (i32, i32)"},
    // select: arms bare / hl / lh / ll; the condition is always a handle
    {"cq_template_select_i1", "i32 (i32, i32, i32)"},
    {"cq_template_select_i7_hl", "i32 (i32, i32, i7)"},
    {"cq_template_select_i100_lh", "i32 (i32, i100, i32)"},
    {"cq_template_select_i128_ll", "i32 (i32, i128, i128)"},
    {"cq_template_select_f16_hl", "i32 (i32, i32, half)"},
    {"cq_template_select_f80_ll", "i32 (i32, x86_fp80, x86_fp80)"},
    // ternary: qqq (bare), qql, qlq, qll, llq; fshl/fshr take lqq/lql as well; fma takes lqq/lql
    // as the NaN-literal spellings (CR §1.2, 3aaafe1; the literal is checked on the call)
    {"cq_template_fma_f64_lqq", "i32 (double, i32, i32)"},
    {"cq_template_fma_f32_lql", "i32 (float, i32, float)"},
    {"cq_template_fma_f80_lql_rm", "i32 (x86_fp80, i32, x86_fp80, i32)"},
    {"cq_template_fma_f80", "i32 (i32, i32, i32)"},
    {"cq_template_fma_f16_qql", "i32 (i32, i32, half)"},
    {"cq_template_fma_f80_qlq", "i32 (i32, x86_fp80, i32)"},
    {"cq_template_fma_f64_qll", "i32 (i32, double, double)"},
    {"cq_template_fma_f16_llq", "i32 (half, half, i32)"},
    {"cq_template_fshl_i7", "i32 (i32, i32, i32)"},
    {"cq_template_fshl_i100_qql", "i32 (i32, i32, i100)"},
    {"cq_template_fshr_i128_qlq", "i32 (i32, i128, i32)"},
    {"cq_template_fshl_i32_qll", "i32 (i32, i32, i32)"},
    {"cq_template_fshr_i7_llq", "i32 (i7, i7, i32)"},
    {"cq_template_fshl_i100_lqq", "i32 (i100, i32, i32)"},
    {"cq_template_fshr_i128_lql", "i32 (i128, i32, i128)"},
    {"cq_template_fshl_i7_lql", "i32 (i7, i32, i7)"},
    // unary
    {"cq_template_fneg_f16", "i32 (i32)"},
    {"cq_template_fabs_f80", "i32 (i32)"},
    {"cq_template_sqrt_f80", "i32 (i32)"},
    {"cq_template_floor_f16", "i32 (i32)"},
    {"cq_template_ceil_f80", "i32 (i32)"},
    {"cq_template_trunc_f16", "i32 (i32)"},
    {"cq_template_rint_f80", "i32 (i32)"},
    {"cq_template_round_f16", "i32 (i32)"},
    {"cq_template_abs_i100", "i32 (i32)"},
    {"cq_template_ctlz_i7", "i32 (i32)"},
    {"cq_template_cttz_i128", "i32 (i32)"},
    {"cq_template_ctpop_i1", "i32 (i32)"},
    {"cq_template_bswap_i128", "i32 (i32)"},
    // casts
    {"cq_template_zext_i1_to_i100", "i32 (i32)"},
    {"cq_template_sext_i7_to_i128", "i32 (i32)"},
    {"cq_template_trunc_i128_to_i7", "i32 (i32)"},
    {"cq_template_trunc_i100_to_i1", "i32 (i32)"},
    {"cq_template_fpext_f16_to_f80", "i32 (i32)"},
    {"cq_template_fptrunc_f80_to_f16", "i32 (i32)"},
    {"cq_template_sitofp_i100_to_f16", "i32 (i32)"},
    {"cq_template_uitofp_i1_to_f80", "i32 (i32)"},
    {"cq_template_fptosi_f16_to_i7", "i32 (i32)"},
    {"cq_template_fptoui_f80_to_i128", "i32 (i32)"},
    {"cq_template_bitcast_f16_to_i16", "i32 (i32)"},
    {"cq_template_bitcast_i80_to_f80", "i32 (i32)"},
    // _rm / _rmq / _exc
    {"cq_template_fadd_f64_hl_rm", "i32 (i32, double, i32)"},
    {"cq_template_fadd_f64_hl_rmq", "i32 (i32, double, i32)"},
    {"cq_template_fadd_f64_hl_rm_exc", "i32 (i32, double, i32)"},
    {"cq_template_fdiv_f80_rmq_exc", "i32 (i32, i32, i32)"},
    {"cq_template_fmul_f16_lh_rm", "i32 (half, i32, i32)"},
    {"cq_template_fadd_f64_ll_rmq", "i32 (double, double, i32)"},
    {"cq_template_fadd_f64_ll_rmq_exc", "i32 (double, double, i32)"},
    {"cq_template_fsub_f16_exc", "i32 (i32, i32)"},
    {"cq_template_sqrt_f64_l_rmq", "i32 (double, i32)"},
    {"cq_template_sqrt_f80_rm_exc", "i32 (i32, i32)"},
    {"cq_template_fma_f64_lll_rmq", "i32 (double, double, double, i32)"},
    {"cq_template_fma_f16_qll_rmq_exc", "i32 (i32, half, half, i32)"},
    {"cq_template_sitofp_i128_to_f32_rm", "i32 (i32, i32)"},
    {"cq_template_fptosi_f80_to_i100_exc", "i32 (i32)"},
    {"cq_template_fptrunc_f64_to_f16_rmq_exc", "i32 (i32, i32)"},
    {"cq_template_fcmp_olt_f80_hl_exc", "i32 (i32, x86_fp80)"},
    // QROM, plain and strided
    {"cq_template_qrom_load_i32", "i32 (ptr, i64, i32)"},
    {"cq_template_qrom_load_i7", "i32 (ptr, i64, i32)"},
    {"cq_template_qrom_load_f80", "i32 (ptr, i64, i32)"},
    {"cq_template_qrom_load_i128_s", "i32 (ptr, i64, i64, i32)"},
    {"cq_template_qrom_load_f16_s", "i32 (ptr, i64, i64, i32)"},
};

// The forward signature "i32 (args)" -> the _unc signature "void (i32, args)".
static std::string uncSig(const std::string &fwd) {
  std::string args = fwd.substr(fwd.find('(') + 1);
  return args == ")" ? "void (i32)" : "void (i32, " + args;
}

static void testTemplates() {
  llvm::Module M("t", C);
  for (const TRow &r : kTemplates) {
    for (bool unc : {false, true}) {
      std::string sym = std::string(r.sym) + (unc ? "_unc" : "");
      bool u = !unc;
      auto s = parseTemplate(sym, &u);
      CHECK(s.has_value(), "parseTemplate(%s)", sym.c_str());
      if (!s)
        continue;
      CHECK(u == unc, "unc flag of %s", sym.c_str());
      CHECK(name(*s, unc) == sym, "name(parse(%s)) = %s", sym.c_str(), name(*s, unc).c_str());
      llvm::FunctionCallee fc = declare(M, *s, unc);
      std::string want = unc ? uncSig(r.sig) : r.sig;
      CHECK(str(fc.getFunctionType()) == want, "declare(%s) = %s, want %s", sym.c_str(),
            str(fc.getFunctionType()).c_str(), want.c_str());
      CHECK(llvm::cast<llvm::Function>(fc.getCallee())->getName() == sym, "declared name %s", sym.c_str());
      // Idempotent: a second declare returns the same function.
      CHECK(declare(M, *s, unc).getCallee() == fc.getCallee(), "declare twice %s", sym.c_str());
    }
  }

  // Specs built by hand name as expected (the field reading, not only the round trip).
  {
    TemplateSpec s;
    s.op = "icmp"; s.pred = "ugt"; s.w = {Kind::Int, 128}; s.shape = "hl";
    CHECK(name(s, false) == "cq_template_icmp_ugt_i128_hl", "%s", name(s, false).c_str());
  }
  {
    TemplateSpec s;
    s.op = "fadd"; s.w = {Kind::Fp, 64}; s.shape = "hl"; s.rm = TemplateSpec::RmLit; s.exc = true;
    CHECK(name(s, true) == "cq_template_fadd_f64_hl_rm_exc_unc", "%s", name(s, true).c_str());
  }
  {
    TemplateSpec s;
    s.op = "qrom_load"; s.w = {Kind::Fp, 80}; s.strided = true;
    CHECK(name(s, false) == "cq_template_qrom_load_f80_s", "%s", name(s, false).c_str());
  }
  {
    TemplateSpec s;
    s.op = "trunc"; s.w = {Kind::Int, 64}; s.to = RailType{Kind::Int, 7};
    CHECK(name(s, false) == "cq_template_trunc_i64_to_i7", "%s", name(s, false).c_str());
    auto p = parseTemplate("cq_template_trunc_i64_to_i7", nullptr);
    CHECK(p && p->op == "trunc" && p->to && p->to->bits == 7 && p->w.bits == 64, "trunc cast fields");
    auto q = parseTemplate("cq_template_trunc_f64", nullptr);
    CHECK(q && q->op == "trunc" && !q->to && q->w.kind == Kind::Fp, "trunc fp fields");
  }
  {
    auto p = parseTemplate("cq_template_select_i8_lh_unc", nullptr);
    CHECK(p && p->op == "select" && p->shape == "lh" && p->w.bits == 8 && p->w.kind == Kind::Int &&
              p->rm == TemplateSpec::NoRm && !p->exc && !p->strided && p->pred.empty(),
          "select fields");
    auto q = parseTemplate("cq_template_fcmps_ogt_f64_hl_exc", nullptr);
    CHECK(q && q->op == "fcmps" && q->pred == "ogt" && q->exc, "fcmps fields");
    auto r = parseTemplate("cq_template_fadd_f64_ll_rmq", nullptr);
    CHECK(r && r->rm == TemplateSpec::RmRail && r->shape == "ll", "rmq fields");
    auto o = parseTemplate("cq_template_umul_overflow_i32_hl", nullptr);
    CHECK(o && o->op == "umul_overflow", "overflow op with underscore");
    auto f = parseTemplate("cq_template_is_fpclass_f64_hl", nullptr);
    CHECK(f && f->op == "is_fpclass", "is_fpclass op");
  }

  // Non-canonical or malformed spellings are rejected by the parser.
  const char *bad[] = {
      "cq_template_add_i32_lh",           // commutative: handle first
      "cq_template_smax_i32_lh",          // commutative
      "cq_template_uadd_overflow_i32_lh", // commutative
      "cq_template_icmp_eq_i32_lh",       // compares never take _lh
      "cq_template_fcmp_olt_f64_lh",      // compares never take _lh
      "cq_template_add_i32_hh",           // all-handle shape is bare
      "cq_template_fma_f64_qqq",          // all-handle shape is bare
      "cq_template_fma_f64_hhl",          // ternary letters are q/l
      "cq_template_add_i32_ql",           // binary letters are h/l
      "cq_template_add_i32_ll",           // no quantum operand without _rmq
      "cq_template_fadd_f64_ll",          // no quantum operand without _rmq
      "cq_template_sqrt_f64_l",           // no quantum operand without _rmq
      "cq_template_sqrt_f64_h",           // all-handle shape is bare
      "cq_template_add_i32_hll",          // shape length
      "cq_template_qrom_load_i32_hl",     // qrom takes no shape
      "cq_template_qrom_load_i32_rm",     // qrom takes no rounding mode
      "cq_template_qrom_load_s_i32",      // the strided form is qrom_load_<W>_s
      "cq_template_add_i32_s",            // _s is qrom only
      "cq_template_add_f64",              // integer op on fp width
      "cq_template_fadd_i32",             // fp op on integer width
      "cq_template_add_i32_rm",           // _rm needs fp
      "cq_template_sub_i32_hl_exc",       // _exc needs fp
      "cq_template_trunc_f64_to_i32",     // trunc cast is int to int
      "cq_template_trunc_i64",            // trunc without _to_ is the fp op
      "cq_template_zext_i32_to_i8",       // zext widens
      "cq_template_zext_i32",             // casts need _to_
      "cq_template_fpext_f64_to_f32",     // fpext widens
      "cq_template_sitofp_f64_to_i32",    // int to fp
      "cq_template_bitcast_i64_to_i64",   // bitcast changes kind
      "cq_template_bitcast_f64_to_i32",   // bitcast keeps the width
      "cq_template_add_i32_to_i64",       // non-cast takes no _to_
      "cq_template_bswap_i24",            // multiple of 16
      "cq_template_is_fpclass_f64",       // the class mask is always a literal
      "cq_template_is_fpclass_f64_lh",    // ditto
      "cq_template_icmp_i32",             // predicate missing
      "cq_template_icmp_foo_i32",         // unknown predicate
      "cq_template_icmp_oeq_i32",         // fcmp predicate on icmp
      "cq_template_fcmp_slt_f64",         // icmp predicate on fcmp
      "cq_template_add_eq_i32",           // add takes no predicate
      "cq_template_add_i0",               // width >= 1
      "cq_template_add_i07",              // canonical decimal
      "cq_template_fadd_f128",            // no f128 rail
      "cq_template_fadd_f8",              // no f8 rail
      "cq_template_add",                  // no width
      "cq_template_add_",                 // no width
      "cq_template_add_i32_unc_unc",      // one _unc
      "cq_template_add_i32_exc_rm",       // suffix order
      "cq_template_fadd_f64_rm_rmq",      // one rounding suffix
      "cq_template_add_i32_hl_",          // trailing underscore
      "cq_template_frobnicate_i32",       // unknown op
      "cq_template_fadd_f64_hl_inv",      // retired _inv
      "cq_template_select_i32_hh",        // all-handle arms are bare
      "cqrt_template_add_i32",            // wrong namespace
      "cq_template_add_i32_hl_exc",       // _exc needs fp
  };
  for (const char *b : bad)
    CHECK(!parseTemplate(b, nullptr).has_value(), "parseTemplate accepted %s", b);

  // name() and declare() of a non-canonical spec are internal errors, never a spelling.
  CHECK(dies([] { TemplateSpec s; s.op = "add"; s.w = {Kind::Int, 32}; s.shape = "lh"; name(s, false); }),
        "name(add lh)");
  {
    TemplateSpec s; s.op = "fma"; s.w = {Kind::Fp, 64}; s.shape = "lqq";
    CHECK(!dies([s] { name(s, false); }) && name(s, false) == "cq_template_fma_f64_lqq", "name(fma lqq)");
    s.shape = "lql";
    CHECK(!dies([s] { name(s, true); }) && name(s, true) == "cq_template_fma_f64_lql_unc", "name(fma lql)");
  }
  CHECK(dies([] { TemplateSpec s; s.op = "icmp"; s.w = {Kind::Int, 32}; name(s, false); }), "icmp no pred");
  CHECK(dies([] { TemplateSpec s; s.op = "qrom_load_s"; s.w = {Kind::Int, 32}; name(s, false); }),
        "qrom_load_s op");
  CHECK(dies([] {
          llvm::Module M2("m", C);
          TemplateSpec s; s.op = "add"; s.w = {Kind::Int, 32}; s.shape = "hh";
          declare(M2, s, false);
        }),
        "declare(add hh)");
  // A conflicting prior declaration is an internal error.
  CHECK(dies([] {
          llvm::Module M2("m", C);
          M2.getOrInsertFunction("cq_template_add_i32",
                                 llvm::FunctionType::get(llvm::Type::getInt32Ty(C), {llvm::Type::getInt64Ty(C)}, false));
          TemplateSpec s; s.op = "add"; s.w = {Kind::Int, 32};
          declare(M2, s, false);
        }),
        "conflicting declaration");
}

// ---------------------------------------------------------------------------------------------
static const TRow kCores[] = {
    {"cqrt_alloc_i1", "i32 (i1)"},
    {"cqrt_alloc_i7", "i32 (i7)"},
    {"cqrt_alloc_i100", "i32 (i100)"},
    {"cqrt_alloc_i128", "i32 (i128)"},
    {"cqrt_alloc_f16", "i32 (half)"},
    {"cqrt_alloc_f80", "i32 (x86_fp80)"},
    {"cqrt_free", "void (i32)"},
    {"cqrt_measure_i1", "i1 (i32)"},
    {"cqrt_measure_i7", "i7 (i32)"},
    {"cqrt_measure_i128", "i128 (i32)"},
    {"cqrt_measure_f16", "half (i32)"},
    {"cqrt_measure_f80", "x86_fp80 (i32)"},
    {"cqrt_ry_i100", "void (i32, double)"},
    {"cqrt_ry_f80_controlled", "void (i32, i32, double)"},
    {"cqrt_ry_i32_qangle", "void (i32, i32)"},
    {"cqrt_ry_f16_qangle_controlled", "void (i32, i32, i32)"},
    {"cqrt_rz_i1", "void (i32, double)"},
    {"cqrt_rz_qangle", "void (i32)"},
    {"cqrt_rz_qangle_controlled", "void (i32, i32)"},
    {"cqrt_not_i1", "void (i32)"},
    {"cqrt_and_i1", "void (i32, i32, i32)"},
    {"cqrt_or_i1", "void (i32, i32, i32)"},
    {"cqrt_xor_i1", "void (i32, i32)"},
    {"cqrt_copy_i128", "void (i32, i32)"},
    {"cqrt_copy_f80_controlled", "void (i32, i32, i32)"},
    {"cqrt_xorc_i7", "void (i32, i7)"},
    {"cqrt_xorc_i100_controlled", "void (i32, i32, i100)"},
    {"cqrt_xorc_f16", "void (i32, half)"},
    {"cqrt_qram_alloc_i8", "i32 (i32)"},
    {"cqrt_qram_alloc_f80", "i32 (i32)"},
    {"cqrt_qram_realloc_i8", "i32 (i32, i32)"},
    {"cqrt_qram_realloc_i8_unc", "void (i32, i32)"},
    {"cqrt_qram_store_i32", "void (i32, i32, i32)"},
    {"cqrt_qram_store_i32_unc", "void (i32, i32, i32)"},
    {"cqrt_qram_store_i7_hl", "void (i32, i32, i32)"},
    {"cqrt_qram_store_i128_controlled", "void (i32, i32, i32, i32)"},
    {"cqrt_qram_store_i32_hl_controlled", "void (i32, i32, i32, i32)"},
    {"cqrt_qram_store_i32_hl_controlled_unc", "void (i32, i32, i32, i32)"},
    {"cqrt_qram_load_i32", "i32 (i32, i32)"},
    {"cqrt_qram_load_i32_unc", "void (i32, i32, i32)"},
    {"cqrt_qram_load_f16_hl", "i32 (i32, i32)"},
    {"cqrt_qram_load_i8_hl_unc", "void (i32, i32, i32)"},
    {"cqrt_qram_load_i100_controlled", "i32 (i32, i32, i32)"},
    {"cqrt_qram_load_i32_controlled_unc", "void (i32, i32, i32, i32)"},
    {"cqrt_qram_load_i32_hl_controlled_unc", "void (i32, i32, i32, i32)"},
    {"cqrt_qram_free", "void (i32)"},
    {"cqrt_tape_alloc", "i32 ()"},
    {"cqrt_tape_fmt", "void (i32, ptr)"},
    {"cqrt_tape_fmt_controlled", "void (i32, i32, ptr)"},
    {"cqrt_tape_effect_controlled", "void (i32, i32, ptr)"},
    {"cqrt_tape_write_f80", "i32 (i32, i32)"},
    {"cqrt_tape_write_i7_controlled", "i32 (i32, i32, i32)"},
    {"cqrt_tape_write_i128_lit", "void (i32, i128)"},
    {"cqrt_tape_write_f16_lit", "void (i32, half)"},
    {"cqrt_tape_write_str_lit", "void (i32, ptr)"},
    {"cqrt_abort_i1", "void (i32)"},
    {"cqrt_push", "void (i32)"},
    {"cqrt_pop", "i32 ()"},
};

static void testCores() {
  llvm::Module M("c", C);
  for (const TRow &r : kCores) {
    auto s = parseCore(r.sym);
    CHECK(s.has_value(), "parseCore(%s)", r.sym);
    if (!s)
      continue;
    CHECK(name(*s) == r.sym, "name(parse(%s)) = %s", r.sym, name(*s).c_str());
    llvm::FunctionCallee fc = declare(M, *s);
    CHECK(str(fc.getFunctionType()) == r.sig, "declare(%s) = %s, want %s", r.sym,
          str(fc.getFunctionType()).c_str(), r.sig);
  }
  // Field reading.
  {
    CoreSpec s{Core::QramStore, {Kind::Int, 32}, /*ctl=*/true, /*hl=*/true, /*unc=*/true};
    CHECK(name(s) == "cqrt_qram_store_i32_hl_controlled_unc", "%s", name(s).c_str());
    CoreSpec a{Core::AndI1};
    CHECK(name(a) == "cqrt_and_i1", "fixed i1 with unset width");
    auto p = parseCore("cqrt_and_i1");
    CHECK(p && p->op == Core::AndI1 && p->w.bits == 1, "and_i1 fields");
    auto q = parseCore("cqrt_ry_i32_qangle");
    CHECK(q && q->op == Core::RyQAngle && q->w.bits == 32 && !q->ctl, "qangle fields");
    auto t = parseCore("cqrt_tape_write_i8_lit");
    CHECK(t && t->op == Core::TapeWriteLit && t->w.bits == 8, "tape_write_lit fields");
    auto u = parseCore("cqrt_tape_write_str_lit");
    CHECK(u && u->op == Core::TapeWriteStrLit, "tape_write_str_lit fields");
    auto x = parseCore("cqrt_xorc_i32_controlled");
    CHECK(x && x->op == Core::Xorc && x->ctl, "xorc fields");
    auto f = parseCore("cqrt_free");
    CHECK(f && f->op == Core::Free && f->w.bits == 0, "free fields");
  }
  const char *bad[] = {
      "cqrt_measure_i32_controlled", // a measurement is never conditioned (retired)
      "cqrt_x", "cqrt_cnot", "cqrt_toffoli", "cqrt_cswap", // retired
      "cqrt_phase_f64", "cqrt_phase_f64_controlled",      // retired
      "cqrt_rz_i32",                                       // retired
      "cqrt_ry_i32_controlled_inv",                        // retired
      "cqrt_copy_i32_unc",            // an involution is its own _unc
      "cqrt_not_i1_unc",
      "cqrt_and_i1_controlled",       // no controlled Toffoli form
      "cqrt_tape_effect",             // exists only as _controlled
      "cqrt_free_i32",                // free takes no width
      "cqrt_alloc",                   // alloc needs a width
      "cqrt_alloc_i0", "cqrt_alloc_f128",
      "cqrt_ry_i32_qangle_hl",        // no _hl
      "cqrt_qram_store_i32_controlled_hl", // suffix order
      "cqrt_qram_load_i32_unc_controlled", // suffix order
      "cqrt_qram_alloc_i32_unc",      // no _unc
      "cqrt_tape_write_i32_lit_controlled", // no controlled literal write
      "cqrt_rz_i1_controlled",        // not in §1.3
      "cqrt_push_i32", "cqrt_pop_",
      "cqrt_xor_i8",                  // i1 only
      "cqrt_abort_i8",
      "cqrt_ry_qangle",
      "cq_template_add_i32",          // wrong namespace
  };
  for (const char *b : bad)
    CHECK(!parseCore(b).has_value(), "parseCore accepted %s", b);
  CHECK(dies([] { name(CoreSpec{Core::Copy, {Kind::Int, 32}, false, false, true}); }), "copy unc");
  CHECK(dies([] { name(CoreSpec{Core::TapeEffect}); }), "uncontrolled tape effect");
  CHECK(dies([] { name(CoreSpec{Core::Alloc}); }), "alloc without width");
  CHECK(dies([] { name(CoreSpec{Core::Measure, {Kind::Int, 8}, true}); }), "controlled measure");
  CHECK(dies([] { name(CoreSpec{Core::Free, {Kind::Int, 32}}); }), "free with width");
  CHECK(dies([] { name(CoreSpec{Core::XorI1, {Kind::Int, 8}}); }), "xor_i1 at i8");
}

// ---------------------------------------------------------------------------------------------
static void testClones() {
  struct Row { const char *sym; CloneSpec spec; };
  CloneSpec all{"ext_fn", "1011", {255, 18446744073709551615ull}, true, true, true, 4, true};
  const Row rows[] = {
      {"__cq_q_f_10", {"f", "10", {}}},
      {"__cq_q___divdc3_0011", {"__divdc3", "0011", {}}},
      {"__cq_q_bump_c_10", {"bump_c", "10", {}}},
      {"__cq_q_pick8_10", {"pick8", "10", {}}},
      {"__cq_q_f.1_1", {"f.1", "1", {}}},
      {"__cq_q_memcmp_00111001111_b3", {"memcmp", "00111001111", {3}}},
      {"__cq_q_memcmp_00111001111_b3_unc", {"memcmp", "00111001111", {3}, false, false, false, 0, true}},
      {"__cq_q_f_110_b3_7_0", {"f", "110", {3, 7, 0}}},
      {"__cq_q_g_0_ctl", {"g", "0", {}, true}},
      {"__cq_q_even_step_100_pure", {"even_step", "100", {}, false, true}},
      {"__cq_q_prep_11000_adj", {"prep", "11000", {}, false, false, true}},
      {"__cq_q_chain_10_d3", {"chain", "10", {}, false, false, false, 3}},
      {"__cq_q_chain_10_d12_unc", {"chain", "10", {}, false, false, false, 12, true}},
      {"__cq_q_sin_1_unc", {"sin", "1", {}, false, false, false, 0, true}},
      {"__cq_q_step_1100_ctl_unc", {"step", "1100", {}, true, false, false, 0, true}},
      {"__cq_q_ext_fn_1011_b255_18446744073709551615_ctl_pure_adj_d4_unc", all},
      {"__cq_q_tick_", {"tick", "", {}}},
      {"__cq_q_asm_2b8fbda969a8aaa9_10_ctl", {"asm_2b8fbda969a8aaa9", "10", {}, true}},
  };
  for (const Row &r : rows) {
    CHECK(name(r.spec) == r.sym, "name -> %s, want %s", name(r.spec).c_str(), r.sym);
    auto p = parseClone(r.sym);
    CHECK(p.has_value(), "parseClone(%s)", r.sym);
    if (!p)
      continue;
    const CloneSpec &a = *p, &b = r.spec;
    CHECK(a.fn == b.fn && a.mask == b.mask && a.bounds == b.bounds && a.ctl == b.ctl && a.pure == b.pure &&
              a.adj == b.adj && a.depth == b.depth && a.unc == b.unc,
          "parseClone(%s) fields (fn=%s mask=%s)", r.sym, a.fn.c_str(), a.mask.c_str());
  }
  const char *bad[] = {
      "__cq_q_f",               // no mask
      "__cq_q_f_12",            // mask is binary
      "__cq_q__1",              // empty fn
      "__cq_q_10",              // empty fn
      "__cq_q_f_1_b03",         // canonical decimal
      "__cq_q_f_1_b",           // empty bound
      "__cq_q_f_1_d0",          // depth >= 1
      "__cq_q_f_1_d01",
      "__cq_q_f_1_unc_ctl",     // suffix order
      "__cq_q_f_1_pure_ctl",    // suffix order
      "__cq_q_f_1_d2_adj",      // suffix order
      "__cq_q_f_1_ctl_b3",      // suffix order
      "__cq_q_f_1_b99999999999999999999", // bound overflows u64
      "cq_q_f_1",               // prefix
      "__cq_q_f_1_inv",         // unknown suffix: "inv" is not a mask
  };
  for (const char *b : bad)
    CHECK(!parseClone(b).has_value(), "parseClone accepted %s", b);
  // CR §1.4 (ruling 2026-10-27): two distinct clones may spell the same name; name() spells both
  // without error (the calls module uniquifies the symbol), and the normative right-to-left reading
  // returns the bounded one.
  {
    CloneSpec a{"a_1_b2", "1", {}}, b{"a", "1", {2, 1}};
    CHECK(!dies([a] { name(a); }) && !dies([b] { name(b); }), "ambiguous pair names without error");
    CHECK(name(a) == "__cq_q_a_1_b2_1" && name(b) == "__cq_q_a_1_b2_1", "pair: %s / %s", name(a).c_str(),
          name(b).c_str());
    auto p = parseClone("__cq_q_a_1_b2_1");
    CHECK(p && p->fn == "a" && p->mask == "1" && p->bounds == std::vector<uint64_t>({2, 1}),
          "right-to-left reading of the ambiguous name");
    CloneSpec c{"q_0_b5_6", "1", {}, true};
    CHECK(!dies([c] { name(c); }) && name(c) == "__cq_q_q_0_b5_6_1_ctl", "fn ending in _<mask>_b<N>_<N>");
  }
  // Rule 27 symbols (no bounds) read right to left: suffix words, then the mask, fn the rest.
  {
    auto p = parseClone("__cq_q_my_lib_10_fn_0110_ctl_adj_unc");
    CHECK(p && p->fn == "my_lib_10_fn" && p->mask == "0110" && p->bounds.empty() && p->ctl && !p->pure &&
              p->adj && p->depth == 0 && p->unc,
          "rule-27 symbol fields (fn=%s mask=%s)", p ? p->fn.c_str() : "-", p ? p->mask.c_str() : "-");
    auto q = parseClone("__cq_q_strtod_r_10_ctl");
    CHECK(q && q->fn == "strtod_r" && q->mask == "10" && q->ctl && !q->unc, "rule-27 strtod_r_10_ctl");
    auto r = parseClone("__cq_q_f_10_01");
    CHECK(r && r->fn == "f_10" && r->mask == "01" && r->bounds.empty(), "rightmost binary token is the mask");
  }
  CHECK(dies([] { name(CloneSpec{"f", "1_ctl", {}}); }), "mask with junk");
  CHECK(dies([] { name(CloneSpec{"", "1", {}}); }), "empty fn");
  CHECK(dies([] { name(CloneSpec{"f", "12", {}}); }), "non-binary mask");
  // Names that only look like suffixes are not ambiguous: the mask is the last token before them.
  CHECK(name(CloneSpec{"set_ctl", "1", {}}) == "__cq_q_set_ctl_1", "fn ending in a suffix word");
  CHECK(name(CloneSpec{"x_1", "", {}, true}) == "__cq_q_x_1__ctl", "empty mask after a digit token");
  CHECK(name(CloneSpec{"a_1_d2", "1", {}}) == "__cq_q_a_1_d2_1", "fn ending in a depth-like token");

  // Rule 27 (3aaafe1): "asm_" + the first 16 lowercase hex digits of sha256(asm string, one NUL byte,
  // constraint string). Expected values from python3 hashlib:
  //   hashlib.sha256(b"nop" + b"\0" + b"").hexdigest()[:16]               == "9314237daa0a6eec"
  //   hashlib.sha256(b"movl $1, $0" + b"\0" + b"=r,r").hexdigest()[:16]  == "74108121eae7511a"
  // (without the NUL they would be 2b8fbda969a8aaa9 and 84487680bd4378e8).
  llvm::InlineAsm *nop = llvm::InlineAsm::get(llvm::FunctionType::get(llvm::Type::getVoidTy(C), false), "nop", "",
                                              true);
  CHECK(asmCloneFn(*nop) == "asm_9314237daa0a6eec", "asm nop -> %s", asmCloneFn(*nop).c_str());
  llvm::Type *i32 = llvm::Type::getInt32Ty(C);
  llvm::InlineAsm *mov = llvm::InlineAsm::get(llvm::FunctionType::get(i32, {i32}, false), "movl $1, $0", "=r,r",
                                              false);
  CHECK(asmCloneFn(*mov) == "asm_74108121eae7511a", "asm mov -> %s", asmCloneFn(*mov).c_str());
  CHECK(name(CloneSpec{asmCloneFn(*mov), "1", {}, false, false, false, 0, true}) ==
            "__cq_q_asm_74108121eae7511a_1_unc",
        "asm clone twin name");
}

// CR §1.2 (3aaafe1): fma lqq/lql and fadd/fmul _lh keep a NaN literal in front; a non-NaN constant
// there should have commuted, so the call is rejected.
static void testFpLiteralPosition() {
  using detail::checkFpLiteralPosition;
  llvm::Module M("lit", C);
  llvm::Type *i32 = llvm::Type::getInt32Ty(C), *d = llvm::Type::getDoubleTy(C), *f = llvm::Type::getFloatTy(C);
  llvm::Function *host = llvm::Function::Create(llvm::FunctionType::get(llvm::Type::getVoidTy(C), {i32, d}, false),
                                                llvm::Function::ExternalLinkage, "host", M);
  llvm::IRBuilder<> B(llvm::BasicBlock::Create(C, "e", host));
  llvm::Value *q = host->getArg(0), *x = host->getArg(1);
  llvm::Value *nan = llvm::ConstantFP::getNaN(d), *one = llvm::ConstantFP::get(d, 1.0);
  llvm::Value *nanF = llvm::ConstantFP::getNaN(f), *twoF = llvm::ConstantFP::get(f, 2.0);
  auto call = [&](const char *sym, bool unc, llvm::ArrayRef<llvm::Value *> args) {
    bool u = false;
    auto s = parseTemplate(sym, &u);
    CHECK(s && u == unc, "parseTemplate(%s)", sym);
    return B.CreateCall(declare(M, *s, unc), args);
  };
  struct { llvm::CallInst *ci; bool ok; const char *what; } rows[] = {
      {call("cq_template_fma_f64_lqq", false, {nan, q, q}), true, "fma lqq NaN"},
      {call("cq_template_fma_f64_lqq", false, {one, q, q}), false, "fma lqq 1.0"},
      {call("cq_template_fma_f32_lql", false, {nanF, q, twoF}), true, "fma lql NaN"},
      {call("cq_template_fma_f32_lql", false, {twoF, q, nanF}), false, "fma lql 2.0 (NaN addend)"},
      {call("cq_template_fma_f64_lql_unc", true, {q, nan, q, one}), true, "fma lql_unc NaN"},
      {call("cq_template_fma_f64_lql_unc", true, {q, one, q, nan}), false, "fma lql_unc 1.0"},
      {call("cq_template_fma_f64_lqq", false, {x, q, q}), true, "fma lqq runtime literal (cq-5iy)"},
      {call("cq_template_fma_f64_qlq", false, {q, one, q}), true, "fma qlq 1.0"},
      {call("cq_template_fma_f64_llq", false, {one, one, q}), true, "fma llq: no product handle to swap"},
      {call("cq_template_fadd_f64_lh", false, {nan, q}), true, "fadd lh NaN"},
      {call("cq_template_fadd_f64_lh", false, {one, q}), false, "fadd lh 1.0"},
      {call("cq_template_fmul_f64_lh_unc", true, {q, one, q}), false, "fmul lh_unc 1.0"},
      {call("cq_template_fsub_f64_lh", false, {one, q}), true, "fsub lh 1.0: not commutative"},
  };
  for (auto &r : rows) {
    std::string why = checkFpLiteralPosition(*r.ci);
    CHECK(why.empty() == r.ok, "%s: %s", r.what, why.empty() ? "accepted" : why.c_str());
  }
  // A call of something that is not a canonical template is not silently accepted.
  llvm::Function *other = llvm::Function::Create(llvm::FunctionType::get(i32, {i32}, false),
                                                 llvm::Function::ExternalLinkage, "cq_template_fma_f64_qqq", M);
  CHECK(!checkFpLiteralPosition(*B.CreateCall(other, {q})).empty(), "non-canonical template call");
}

int main() {
  testTypes();
  testTemplates();
  testCores();
  testClones();
  testFpLiteralPosition();
  std::printf("abi_unit: %u checks, %u failures\n", gChecks, gFails);
  return gFails ? 1 : 0;
}
