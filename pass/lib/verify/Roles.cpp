// Operand roles of every ABI call (CR §1.2 template grammar, §1.3 core gates, §1.4 clones).
#include "Roles.h"

#include "llvm/ADT/Twine.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::verify {
namespace {

[[noreturn]] void malformed(const CallBase &CB, const Twine &why) {
  std::string s;
  raw_string_ostream os(s);
  os << "cq: verify: malformed ABI call: " << why << "\n    in @" << CB.getFunction()->getName() << ": " << CB;
  report_fatal_error(Twine(os.str()), /*gen_crash_diag=*/false);
}

void templateRoles(Sig &S, const CallBase &CB, unsigned nargs) {
  const abi::TemplateSpec &T = *S.tmpl;
  SmallVector<Role, 6> fwd;
  unsigned lead = 0, trail = T.rm != abi::TemplateSpec::NoRm ? 1 : 0;
  if (T.op == "select") {
    fwd.push_back(Role::Read);
    lead = 1;
  }
  unsigned fwdArgs = S.unc ? nargs - 1 : nargs;
  if (fwdArgs < lead + trail || (S.unc && nargs == 0))
    malformed(CB, "too few operands for the template's spelling");
  unsigned data = fwdArgs - lead - trail;
  if (T.shape.empty()) {
    fwd.append(data, Role::Read);
  } else {
    if (T.shape.size() != data)
      malformed(CB, "shape '" + T.shape + "' does not cover " + Twine(data) + " data operands");
    for (char c : T.shape)
      fwd.push_back(c == 'l' ? Role::Classical : Role::Read);
  }
  if (trail)
    fwd.push_back(T.rm == abi::TemplateSpec::RmRail ? Role::Read : Role::Classical);
  if (S.unc) {
    S.roles.push_back(Role::UncOut);
    S.res = Res::None;
  } else {
    S.res = Res::Dirty;
  }
  S.roles.append(fwd.begin(), fwd.end());
}

// CR §1.3. The control flag is argument 0 of a _controlled form.
void coreRoles(Sig &S, const CallBase &CB) {
  using abi::Core;
  const abi::CoreSpec &C = *S.core;
  SmallVector<Role, 6> &R = S.roles;
  if (C.ctl)
    R.push_back(Role::Read);
  switch (C.op) {
  case Core::Alloc:
    R.push_back(Role::Classical);
    S.res = Res::Known;
    break;
  case Core::Free:
    R.push_back(Role::Free);
    S.res = Res::None;
    break;
  case Core::Measure:
    R.push_back(Role::Measure);
    S.res = Res::Classical;
    break;
  case Core::Ry:
    R.append({Role::Rotate, Role::Classical});
    S.res = Res::None;
    break;
  case Core::RyQAngle:
    R.append({Role::Rotate, Role::Read});
    S.res = Res::None;
    break;
  case Core::RzI1:
    R.append({Role::Read, Role::Classical});
    S.res = Res::None;
    break;
  case Core::RzQAngle:
    R.push_back(Role::Read);
    S.res = Res::None;
    break;
  case Core::NotI1:
    R.push_back(Role::Write);
    S.res = Res::None;
    break;
  case Core::AndI1:
  case Core::OrI1:
    R.append({Role::Read, Role::Read, Role::Write});
    S.res = Res::None;
    break;
  case Core::XorI1:
    R.append({Role::Read, Role::Write});
    S.res = Res::None;
    break;
  case Core::Copy:
    R.append({Role::Read, Role::Write});
    S.res = Res::None;
    break;
  case Core::Xorc:
    R.append({Role::Write, Role::Classical});
    S.res = Res::None;
    break;
  case Core::QramAlloc:
    R.push_back(Role::Classical);
    S.res = Res::Known;
    break;
  case Core::QramStore:
    R.append({Role::Read, C.hl ? Role::Classical : Role::Read, Role::Read});
    S.res = Res::None;
    break;
  case Core::QramSwap:
    R.append({Role::Read, C.hl ? Role::Classical : Role::Read, Role::Swap});
    S.res = Res::None;
    break;
  case Core::QramLoad:
    if (C.unc)
      R.insert(R.begin(), Role::UncOut);
    R.append({Role::Read, C.hl ? Role::Classical : Role::Read});
    S.res = C.unc ? Res::None : Res::Dirty;
    break;
  case Core::TapeAlloc:
    S.res = Res::Known;
    break;
  case Core::TapeFmt:
    R.append({Role::Read, Role::Classical});
    S.res = Res::None;
    break;
  case Core::TapeEffect:
    if (!C.ctl)  // only the _controlled form exists; its flag is argument 0 either way
      R.push_back(Role::Read);
    R.append({Role::Read, Role::Classical, Role::Classical});
    S.res = Res::None;
    break;
  case Core::TapeEffectW:   // CR §1.3: (c, t, name, n) -> r; the flag is argument 0
    R.append({Role::Read, Role::Classical, Role::Classical});
    S.res = Res::Known;
    break;
  case Core::TapeWrite:
    R.append({Role::Read, Role::Read});
    S.res = Res::Dirty;
    break;
  case Core::TapeWriteLit:
    R.append({Role::Read, Role::Classical});
    S.res = Res::None;
    break;
  case Core::AbortI1:
    R.push_back(Role::Read);
    S.res = Res::None;
    break;
  case Core::Push:
    R.push_back(Role::Word);
    S.res = Res::None;
    break;
  case Core::Pop:
    S.res = Res::Word;
    break;
  case Core::InvertBegin:
  case Core::InvertEnd:
    S.res = Res::None;   // rule 17: events of the host execution, no rail
    break;
  }
  (void)CB;
}

} // namespace

const Sig &SigCache::get(const CallBase &CB) {
  const Function *F = CB.getCalledFunction();
  if (!F)
    return Indirect;
  auto It = Cache.find(F);
  if (It != Cache.end())
    return It->second;
  Sig S;
  S.callee = F->getName().str();
  StringRef name = F->getName();
  unsigned nargs = F->arg_size();
  if (name.starts_with("cq_template_")) {
    bool unc = false;
    S.tmpl = abi::parseTemplate(name, &unc);
    if (!S.tmpl)
      malformed(CB, "@" + name + " is not a template name (CR §1.2)");
    S.kind = Kind::Template;
    S.unc = unc;
    if (unc)
      S.fwd = name.drop_back(4).str();
    templateRoles(S, CB, nargs);
  } else if (name.starts_with("cqrt_")) {
    S.core = abi::parseCore(name);
    if (!S.core)
      malformed(CB, "@" + name + " is not a core gate name (CR §1.3)");
    S.kind = Kind::Core;
    S.unc = S.core->unc;
    if (S.unc)
      S.fwd = name.drop_back(4).str();
    coreRoles(S, CB);
    if (S.roles.size() != nargs)
      malformed(CB, "@" + name + " takes " + Twine(S.roles.size()) + " operands by its spelling, declared with " +
                        Twine(nargs));
  } else if (name.starts_with("__cq_q_")) {
    S.clone = abi::parseClone(name);
    if (!S.clone)
      malformed(CB, "@" + name + " is not a clone name (CR §1.4)");
    S.kind = Kind::Clone;
    S.unc = S.clone->unc;
    if (S.unc)
      S.fwd = name.drop_back(4).str();
  } else if (name == "__cq_unbound") {
    S.roles.push_back(Role::Read);   // CR rule 20: the one host function an address rail is passed to
    S.res = Res::None;
  }
  if (S.kind == Kind::Template && S.roles.size() != nargs)
    malformed(CB, "@" + name + " takes " + Twine(S.roles.size()) + " operands by its spelling, declared with " +
                      Twine(nargs));
  return Cache.try_emplace(F, std::move(S)).first->second;
}

} // namespace cq::verify
