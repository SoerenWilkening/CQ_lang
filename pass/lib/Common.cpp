// cq::unimplemented and cq::internalError (scaffold). The type helpers of Common.h are the abi
// module's (pass/lib/abi/).
#include "cq/Common.h"

#include <functional>
#include <map>
#include <memory>
#include <string>

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/IR/Dominators.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/TargetParser/Triple.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

namespace {
[[noreturn]] void fail(llvm::StringRef prefix, llvm::StringRef what, const llvm::Value *at, const char *file = nullptr,
                       int line = 0) {
  std::string msg;
  llvm::raw_string_ostream os(msg);
  os << prefix << what;
  if (at)
    os << "\n  at: " << *at;
  if (auto *I = llvm::dyn_cast_or_null<llvm::Instruction>(at); I && I->getParent() && I->getFunction())
    os << "\n  in: @" << I->getFunction()->getName();
  if (file) {
    llvm::StringRef f(file);
    size_t p = f.find("pass/");
    os << "\n  site: " << (p == llvm::StringRef::npos ? f : f.substr(p)) << ":" << line;
  }
  // No crash diagnostics: a clean non-zero exit. opt removes its output file on the way out.
  llvm::report_fatal_error(llvm::Twine(os.str()), /*gen_crash_diag=*/false);
}
} // namespace

namespace cq {
void (unimplemented)(llvm::StringRef what, const llvm::Value *at) { fail("cq: unimplemented: ", what, at); }
void (internalError)(llvm::StringRef what, const llvm::Value *at) { fail("cq: internal error: ", what, at); }
void unimplementedAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at) {
  fail("cq: unimplemented: ", what, at, file, line);
}
void internalErrorAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at) {
  fail("cq: internal error: ", what, at, file, line);
}
void noteUnbuiltAt(const char *file, int line, llvm::StringRef what, const llvm::Value *at) {
  llvm::StringRef f(file);
  size_t p = f.find("pass/");
  llvm::errs() << "cq: note: unbuilt: " << what << "  site: " << (p == llvm::StringRef::npos ? f : f.substr(p)) << ":"
               << line;
  if (at) {
    std::string s;
    llvm::raw_string_ostream os(s);
    os << *at;
    llvm::errs() << "  at: " << llvm::StringRef(os.str()).trim();
  }
  llvm::errs() << "\n";
}
} // namespace cq

namespace cq {
using namespace llvm;
// A library function LLVM knows by semantics (TargetLibraryInfo for the module's triple), with its
// LibFunc in lf.
// The C name a declared clone is named after (CR §1.4 fn). Rule 18: an LLVM math intrinsic on a
// quantum operand is the call of the libm function of the same name: llvm.<n>.<types> is n for a
// double, nf for a float, nl for an x86_fp80 first operand (175).
std::string calleeName(const Function &F, const Value *at) {
  if (!F.isIntrinsic())
    return F.getName().str();
  StringRef n = F.getName();
  if (!n.consume_front("llvm.") || n.empty())
    internalError("calls: an intrinsic whose name is not llvm.<name>.<types>", at);
  std::string base = n.take_until([](char c) { return c == '.'; }).str();
  Type *t = F.arg_size() ? F.getFunctionType()->getParamType(0) : nullptr;
  // The intrinsics whose C function has another name (taint's libmNameOf names the same): IEEE 754-2019
  // minimum/maximum are C23 fminimum/fmaximum; powi has no C name and is LLVM's own libcall,
  // compiler-rt's __powi<m>f2.
  if (F.getIntrinsicID() == Intrinsic::minimum)
    base = "fminimum";
  else if (F.getIntrinsicID() == Intrinsic::maximum)
    base = "fmaximum";
  else if (F.getIntrinsicID() == Intrinsic::powi && t &&
           (t->isFloatTy() || t->isDoubleTy() || t->isX86_FP80Ty()))
    return t->isFloatTy() ? "__powisf2" : t->isDoubleTy() ? "__powidf2" : "__powixf2";
  if (t && t->isDoubleTy())
    return base;
  if (t && t->isFloatTy())
    return base + "f";
  if (t && t->isX86_FP80Ty())
    return base + "l";
  // Owner 2026-11-03 (no fences): whatever LLVM does. Codegen promotes half/bfloat to float and scalarises a vector
  // per element, so the name is the element type's: half/bfloat -> the float name, anything else the double name.
  if (Type *e = t ? t->getScalarType() : nullptr; e && (e->isHalfTy() || e->isBFloatTy() || e->isFloatTy()))
    return base + "f";
  if (Type *e = t ? t->getScalarType() : nullptr; e && e->isX86_FP80Ty())
    return base + "l";
  return base;
}

bool streamName(StringRef n) {
  // C17 7.21 and POSIX.1-2017 <stdio.h>, less the string formatters; the stream functions of C17 7.29 and
  // POSIX.1-2017 <wchar.h>, less the wide string formatters swprintf, vswprintf, swscanf, vswscanf (cq-ojgho, owner
  // 2026-11-10); CR rule 16's five descriptor calls.
  static const char *names[] = {
      "fopen",       "freopen",      "fclose",         "fflush",          "setbuf",         "setvbuf",
      "fprintf",     "printf",       "vfprintf",       "vprintf",         "fscanf",         "scanf",
      "vfscanf",     "vscanf",       "fgetc",          "getc",            "getchar",        "fgets",
      "gets",        "fputc",        "putc",           "putchar",         "fputs",          "puts",
      "ungetc",      "fread",        "fwrite",         "fgetpos",         "fseek",          "fsetpos",
      "ftell",       "rewind",       "clearerr",       "feof",            "ferror",         "perror",
      "remove",      "rename",       "tmpfile",        "tmpnam",          "getline",        "getdelim",
      "fdopen",      "fileno",       "popen",          "pclose",          "fseeko",         "ftello",
      "dprintf",     "vdprintf",     "flockfile",      "funlockfile",     "ftrylockfile",   "getc_unlocked",
      "getchar_unlocked", "putc_unlocked", "putchar_unlocked", "ctermid", "fmemopen",       "open_memstream",
      "renameat",    "tempnam",      "open",           "close",           "read",           "write",
      "lseek",       "fwprintf",     "wprintf",        "vfwprintf",       "vwprintf",       "fwscanf",
      "wscanf",      "vfwscanf",     "vwscanf",        "fgetwc",          "fgetws",         "fputwc",
      "fputws",      "fwide",        "getwc",          "getwchar",        "putwc",          "putwchar",
      "ungetwc",     "open_wmemstream"};
  for (const char *x : names)
    if (n == x)
      return true;
  return false;
}

static StringRef cName(const Function &F) {
  StringRef n = F.getName();
  if (n.starts_with("\01_"))
    n = n.drop_front(2);
  return n;
}

// cq-o1swj (CR 778-779, rule 16: "recognised by name and signature"): the prototypes of the interfaces rule 16 names that
// LLVM's TargetLibraryInfo does not know, from the ISO C / POSIX declarations as musl's headers write them (stdio.h,
// wchar.h, unistd.h, signal.h, fenv.h, setjmp.h, pthread.h). One letter per type, the result first, then each
// parameter, a trailing '.' for "...": i i32 (int, unsigned, wchar_t, wint_t, clockid_t), l i64 (size_t, ssize_t,
// off_t), p ptr (every pointer, va_list, jmp_buf, a function pointer), v void; the two handle types whose class the
// platform's headers choose: t pthread_t (musl unsigned long, the Darwin SDK a pointer: i64 or ptr), k pthread_key_t
// (musl unsigned, the Darwin SDK unsigned long: i32 or i64). rule 24's pthread_* is the closed list of POSIX <pthread.h>
// functions (musl's pthread.h less the _GNU_SOURCE _np extensions and the cleanup macros), never a prefix.
static const char *protoOf(StringRef n) {
  static const std::pair<const char *, const char *> protos[] = {
      // <stdio.h> (C17 7.21, POSIX.1-2017)
      {"freopen", "pppp"}, {"tmpnam", "pp"}, {"getline", "lppp"}, {"getdelim", "lppip"}, {"dprintf", "iip."},
      {"vdprintf", "iipp"}, {"fmemopen", "pplp"}, {"open_memstream", "ppp"}, {"renameat", "iipip"},
      {"tempnam", "ppp"},
      // <unistd.h>
      {"close", "ii"}, {"lseek", "llil"},
      // <wchar.h> (C17 7.29, POSIX.1-2017)
      {"fwprintf", "ipp."}, {"wprintf", "ip."}, {"vfwprintf", "ippp"}, {"vwprintf", "ipp"}, {"fwscanf", "ipp."},
      {"wscanf", "ip."}, {"vfwscanf", "ippp"}, {"vwscanf", "ipp"}, {"fgetwc", "ip"}, {"fgetws", "ppip"},
      {"fputwc", "iip"}, {"fputws", "ipp"}, {"fwide", "ipi"}, {"getwc", "ip"}, {"getwchar", "i"}, {"putwc", "iip"},
      {"putwchar", "ii"}, {"ungetwc", "iip"}, {"open_wmemstream", "ppp"},
      // <signal.h>
      {"signal", "pip"}, {"raise", "ii"},
      // <fenv.h> (C17 7.6)
      {"feclearexcept", "ii"}, {"fegetexceptflag", "ipi"}, {"feraiseexcept", "ii"}, {"fesetexceptflag", "ipi"},
      {"fetestexcept", "ii"}, {"fegetround", "i"}, {"fesetround", "ii"}, {"fegetenv", "ip"}, {"feholdexcept", "ip"},
      {"fesetenv", "ip"}, {"feupdateenv", "ip"},
      // <setjmp.h>
      {"setjmp", "ip"}, {"longjmp", "vpi"},
      // <pthread.h> (POSIX.1-2017)
      {"pthread_create", "ipppp"}, {"pthread_detach", "it"}, {"pthread_exit", "vp"}, {"pthread_join", "itp"},
      {"pthread_self", "t"}, {"pthread_equal", "itt"}, {"pthread_setcancelstate", "iip"},
      {"pthread_setcanceltype", "iip"}, {"pthread_testcancel", "v"}, {"pthread_cancel", "it"},
      {"pthread_getschedparam", "itpp"}, {"pthread_setschedparam", "itip"}, {"pthread_setschedprio", "iti"},
      {"pthread_once", "ipp"}, {"pthread_mutex_init", "ipp"}, {"pthread_mutex_lock", "ip"},
      {"pthread_mutex_unlock", "ip"}, {"pthread_mutex_trylock", "ip"}, {"pthread_mutex_timedlock", "ipp"},
      {"pthread_mutex_destroy", "ip"}, {"pthread_mutex_consistent", "ip"}, {"pthread_mutex_getprioceiling", "ipp"},
      {"pthread_mutex_setprioceiling", "ipip"}, {"pthread_cond_init", "ipp"}, {"pthread_cond_destroy", "ip"},
      {"pthread_cond_wait", "ipp"}, {"pthread_cond_timedwait", "ippp"}, {"pthread_cond_broadcast", "ip"},
      {"pthread_cond_signal", "ip"}, {"pthread_rwlock_init", "ipp"}, {"pthread_rwlock_destroy", "ip"},
      {"pthread_rwlock_rdlock", "ip"}, {"pthread_rwlock_tryrdlock", "ip"}, {"pthread_rwlock_timedrdlock", "ipp"},
      {"pthread_rwlock_wrlock", "ip"}, {"pthread_rwlock_trywrlock", "ip"}, {"pthread_rwlock_timedwrlock", "ipp"},
      {"pthread_rwlock_unlock", "ip"}, {"pthread_spin_init", "ipi"}, {"pthread_spin_destroy", "ip"},
      {"pthread_spin_lock", "ip"}, {"pthread_spin_trylock", "ip"}, {"pthread_spin_unlock", "ip"},
      {"pthread_barrier_init", "ippi"}, {"pthread_barrier_destroy", "ip"}, {"pthread_barrier_wait", "ip"},
      {"pthread_key_create", "ipp"}, {"pthread_key_delete", "ik"}, {"pthread_getspecific", "pk"},
      {"pthread_setspecific", "ikp"}, {"pthread_attr_init", "ip"}, {"pthread_attr_destroy", "ip"},
      {"pthread_attr_getguardsize", "ipp"}, {"pthread_attr_setguardsize", "ipl"}, {"pthread_attr_getstacksize", "ipp"},
      {"pthread_attr_setstacksize", "ipl"}, {"pthread_attr_getdetachstate", "ipp"},
      {"pthread_attr_setdetachstate", "ipi"}, {"pthread_attr_getstack", "ippp"}, {"pthread_attr_setstack", "ippl"},
      {"pthread_attr_getscope", "ipp"}, {"pthread_attr_setscope", "ipi"}, {"pthread_attr_getschedpolicy", "ipp"},
      {"pthread_attr_setschedpolicy", "ipi"}, {"pthread_attr_getschedparam", "ipp"},
      {"pthread_attr_setschedparam", "ipp"}, {"pthread_attr_getinheritsched", "ipp"},
      {"pthread_attr_setinheritsched", "ipi"}, {"pthread_mutexattr_destroy", "ip"},
      {"pthread_mutexattr_getprioceiling", "ipp"}, {"pthread_mutexattr_getprotocol", "ipp"},
      {"pthread_mutexattr_getpshared", "ipp"}, {"pthread_mutexattr_getrobust", "ipp"},
      {"pthread_mutexattr_gettype", "ipp"}, {"pthread_mutexattr_init", "ip"},
      {"pthread_mutexattr_setprioceiling", "ipi"}, {"pthread_mutexattr_setprotocol", "ipi"},
      {"pthread_mutexattr_setpshared", "ipi"}, {"pthread_mutexattr_setrobust", "ipi"},
      {"pthread_mutexattr_settype", "ipi"}, {"pthread_condattr_init", "ip"}, {"pthread_condattr_destroy", "ip"},
      {"pthread_condattr_setclock", "ipi"}, {"pthread_condattr_setpshared", "ipi"},
      {"pthread_condattr_getclock", "ipp"}, {"pthread_condattr_getpshared", "ipp"},
      {"pthread_rwlockattr_init", "ip"}, {"pthread_rwlockattr_destroy", "ip"},
      {"pthread_rwlockattr_setpshared", "ipi"}, {"pthread_rwlockattr_getpshared", "ipp"},
      {"pthread_barrierattr_destroy", "ip"}, {"pthread_barrierattr_getpshared", "ipp"},
      {"pthread_barrierattr_init", "ip"}, {"pthread_barrierattr_setpshared", "ipi"}, {"pthread_atfork", "ippp"},
      {"pthread_getconcurrency", "i"}, {"pthread_setconcurrency", "ii"}, {"pthread_getcpuclockid", "itp"},
      // musl's internal names of the mutex calls a lifted mtx_* body calls (src/internal/pthread_impl.h; CR rule 24)
      {"__pthread_mutex_lock", "ip"}, {"__pthread_mutex_trylock", "ip"}, {"__pthread_mutex_timedlock", "ipp"},
      {"__pthread_mutex_unlock", "ip"}};
  for (const auto &[name, sig] : protos)
    if (n == name)
      return sig;
  return nullptr;
}

static bool typeFits(Type *t, char c) {
  switch (c) {
  case 'i': return t->isIntegerTy(32);
  case 'l': return t->isIntegerTy(64);
  case 'p': return t->isPointerTy();
  case 'v': return t->isVoidTy();
  case 't': return t->isIntegerTy(64) || t->isPointerTy();
  case 'k': return t->isIntegerTy(32) || t->isIntegerTy(64);
  default: return false;
  }
}

static bool protoFits(const FunctionType *FT, StringRef sig) {
  bool va = sig.consume_back(".");
  if (sig.empty() || FT->isVarArg() != va || FT->getNumParams() + 1 != sig.size() ||
      !typeFits(FT->getReturnType(), sig[0]))
    return false;
  for (unsigned i = 0; i < FT->getNumParams(); ++i)
    if (!typeFits(FT->getParamType(i), sig[i + 1]))
      return false;
  return true;
}

// A function whose C name rule 16 lists is that interface when its prototype is the interface's (cq-o1swj, CR 778-779
// "by name and signature"): the one LLVM's TargetLibraryInfo knows for the name, or for a name it does not know (lseek,
// getline, fesetround, signal, pthread_create, ...) protoOf's. Any other prototype, and a name in neither, is the
// program's own function of that name. Linkage is not read: CR names no linkage condition, and a module whose library
// bodies are internalized (the musl rows) still has rule 16's interfaces.
static bool listedInterface(const Function &F) {
  LibFunc lf;
  static const TargetLibraryInfoImpl names{Triple()};
  StringRef n = cName(F);
  if (names.getLibFunc(n, lf))
    return libFuncOf(F, lf);
  const char *sig = protoOf(n);
  return sig && protoFits(F.getFunctionType(), sig);
}

bool streamCallee(const Function &F) {
  if (F.isIntrinsic() || !streamName(cName(F)))
    return false;
  return listedInterface(F);
}

// cq-rrc52 (CR rule 16): the ISO C and POSIX interfaces rule 16 names besides the stream calls: malloc, calloc,
// aligned_alloc, realloc, free; signal, raise; rule 23's fenv functions (C17 7.6); rule 24's setjmp, longjmp and
// pthread_* (cq-o1swj: the POSIX <pthread.h> functions protoOf lists, a closed list, not a prefix) and musl's
// internal __pthread_mutex_* names of rule 24's mutex calls (cq-dbtpi).
static bool rule16Name(StringRef n) {
  static const char *names[] = {"malloc",          "calloc",        "aligned_alloc",   "realloc",        "free",
                                "signal",          "raise",         "feclearexcept",   "fegetexceptflag", "feraiseexcept",
                                "fesetexceptflag", "fetestexcept",  "fegetround",      "fesetround",     "fegetenv",
                                "feholdexcept",    "fesetenv",      "feupdateenv",     "setjmp",         "longjmp"};
  for (const char *x : names)
    if (n == x)
      return true;
  return (n.starts_with("pthread_") || n.starts_with("__pthread_mutex_")) && protoOf(n);
}

bool rule24Mutex(StringRef n) {
  static const char *names[] = {"pthread_mutex_lock",    "pthread_mutex_trylock", "pthread_mutex_timedlock",
                                "pthread_mutex_unlock",  "pthread_mutex_init",    "pthread_mutex_destroy",
                                "__pthread_mutex_lock",  "__pthread_mutex_trylock", "__pthread_mutex_timedlock",
                                "__pthread_mutex_unlock"};
  for (const char *x : names)
    if (n == x)
      return true;
  return false;
}

// "A body the bundle has for one of them is never lifted for the call" (CR rule 16).
bool hostCallee(const Function &F) {
  if (F.isDeclaration())
    return true;
  if (F.isIntrinsic())
    return false;
  return streamCallee(F) || (rule16Name(cName(F)) && listedInterface(F));
}

bool libFuncOf(const Function &F, LibFunc &lf) {
  static thread_local std::unique_ptr<TargetLibraryInfoImpl> impl;
  static thread_local std::string triple;
  const Module *M = F.getParent();
  if (!impl || triple != M->getTargetTriple()) {
    triple = M->getTargetTriple();
    impl = std::make_unique<TargetLibraryInfoImpl>(Triple(triple));
  }
  TargetLibraryInfo TLI(*impl, &F);
  if (TLI.getLibFunc(F, lf))
    return true;
  // cq-my17 (99): an asm label "\01_n" on a Mach-O target (global prefix '_') is the symbol of C
  // function n (the Darwin headers label fwrite, fputs, ... this way). It is that library function
  // when n's prototype is (TLI checks it on a scratch declaration named n).
  StringRef n = F.getName();
  const DataLayout &DL = M->getDataLayout();
  if (!n.starts_with("\01") || DL.getGlobalPrefix() != '_' || !n.drop_front(1).starts_with("_"))
    return false;
  // Keyed by content (triple, name, prototype), never by a Function pointer another module may reuse.
  std::string key = M->getTargetTriple() + '\n' + n.str() + '\n';
  {
    raw_string_ostream os(key);
    F.getFunctionType()->print(os);
  }
  static thread_local std::map<std::string, std::pair<bool, LibFunc>> cache;
  if (auto it = cache.find(key); it != cache.end()) {
    lf = it->second.second;
    return it->second.first;
  }
  LLVMContext C;
  Module scratch("cq-libfunc", C);
  scratch.setTargetTriple(M->getTargetTriple());
  scratch.setDataLayout(DL);
  // Rebuild the prototype in the scratch context (opaque pointers: every type is context-free here).
  std::function<Type *(Type *)> tr = [&](Type *t) -> Type * {
    if (t->isVoidTy()) return Type::getVoidTy(C);
    if (t->isIntegerTy()) return Type::getIntNTy(C, t->getIntegerBitWidth());
    if (t->isPointerTy()) return PointerType::get(C, t->getPointerAddressSpace());
    if (t->isFloatTy()) return Type::getFloatTy(C);
    if (t->isDoubleTy()) return Type::getDoubleTy(C);
    if (t->isX86_FP80Ty()) return Type::getX86_FP80Ty(C);
    if (t->isFP128Ty()) return Type::getFP128Ty(C);
    return nullptr;
  };
  FunctionType *FT = F.getFunctionType();
  Type *ret = tr(FT->getReturnType());
  SmallVector<Type *, 8> ps;
  bool ok = ret != nullptr;
  for (Type *p : FT->params()) {
    Type *t = tr(p);
    ok = ok && t;
    ps.push_back(t);
  }
  bool known = false;
  if (ok) {
    Function *D = Function::Create(FunctionType::get(ret, ps, FT->isVarArg()), GlobalValue::ExternalLinkage,
                                   n.drop_front(2), &scratch);
    TargetLibraryInfo STLI(*impl, D);
    known = STLI.getLibFunc(*D, lf);
  }
  cache[key] = {known, lf};
  return known;
}

namespace {
template <typename Fn> bool withSCEV(const BasicBlock &header, Fn fn) {
  Function &F = const_cast<Function &>(*header.getParent());
  DominatorTree DT(F);
  LoopInfo LI(DT);
  AssumptionCache AC(F);
  TargetLibraryInfoImpl TLII(Triple(F.getParent()->getTargetTriple()));
  TargetLibraryInfo TLI(TLII, &F);
  ScalarEvolution SE(F, TLI, AC, DT, LI);
  Loop *L = LI.getLoopFor(&header);
  while (L && L->getHeader() != &header)
    L = L->getParentLoop();
  if (!L)
    internalError("exitCountKnown: no loop headed by the block", header.getTerminator());
  return fn(SE, *L);
}
} // namespace

bool exitCountKnown(const BasicBlock &header, const BasicBlock &exiting) {
  return withSCEV(header, [&](ScalarEvolution &SE, Loop &L) {
    return !isa<SCEVCouldNotCompute>(SE.getExitCount(&L, &exiting, ScalarEvolution::SymbolicMaximum));
  });
}

bool exitCondCountKnown(const BasicBlock &header, const Value &cond, bool exitIfTrue) {
  return withSCEV(header, [&](ScalarEvolution &SE, Loop &L) {
    ScalarEvolution::ExitLimit EL =
        SE.computeExitLimitFromCond(&L, const_cast<Value *>(&cond), exitIfTrue, /*ControlsOnlyExit=*/false);
    return !isa<SCEVCouldNotCompute>(EL.SymbolicMaxNotTaken);
  });
}
} // namespace cq
