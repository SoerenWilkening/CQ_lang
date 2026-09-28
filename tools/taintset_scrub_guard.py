#!/usr/bin/env python3
"""taintset_scrub_guard.py — the STRUCTURAL half of bd test_C_libtooling-8e5r /
-j8sk's pin: a compiler-assisted check that no raw `llvm::Value`-identity table is
(re)added to `cq::TaintSet` or to anything the walk reaches from it. A record gate
(no plugin, no build products beyond the build's own `compile_commands.json`).

⚠ IT IS NOT A PROOF. A clean run means "the walk below, asked of the compiler in
every build configuration that compiles the header, found nothing it refuses" —
never "no raw pointer anywhere in TaintSet". What it deliberately does NOT look at
is listed under RESIDUALS and OUT OF SCOPE; read both before quoting a green run.
The per-table deterministic pin is `ir-pass/tools/scrub_selftest.cpp`; this gate is
the structural backstop in front of it.

`cq::TaintSet` (ir-pass/include/TaintPropagation.h) is where every stage keeps
pointers to IR values across stages that ERASE IR. Since bd 8e5r every such table is
a self-cleaning container (`ir-pass/include/ScrubOnDelete.h`): a key whose Value is
deleted is dropped by LLVM's own `~Value()` callback, so a later allocation at the
freed address can never answer "tainted". That holds only while NOBODY ADDS A RAW
ONE BACK; this gate is what notices.

HISTORY, so the next reader knows what each layer answers (every layer was added
because an adversarial round passed a raw member through the previous one):
  * r1A/r1B (bd urf8): a TEXT scan missed 14-16 of ~23 natural spellings (L5: a
    syntactic answer to a semantic question loses) -> the header is PARSED
    (`-ast-dump=json`) and the compiler is asked about every type.
  * r2 (bd a66j): Homebrew clang with hand-written flags missed a member under
    `#ifdef NDEBUG` -> the flags come from the build's `compile_commands.json`.
  * r3 (bd wop9 / 7gri / jk56, 2026-09-26): 12 in-contract spellings passed with 0
    problems — a POINTER to a library table (`std::set<llvm::Value *> *`), explicit
    and partial SPECIALIZATIONS of a project template, a pointer to a project ALIAS
    whose short name another record shares (LLVM's own `Result`/`Impl`), a pointer
    to a record OUTSIDE `cq::`, ONE of two build configurations, a PCH that changed
    the answer, a handle hidden in a project record used as a KEY, and an
    allowlisted member exempting its whole subtree. The rewrite below answers each of
    those by asking the compiler instead of reading a spelling.
  * review r1 of that rewrite (bd hdxo ehni ofvm ngfa 5ci2 s6ma, 2026-09-28): 13 more
    headers the build compiles passed, 3 of them REGRESSIONS against the old guard — an
    unnamed type defined OUTSIDE the walked record, `*const` qualifiers the parser
    dropped, a `scrub::Set` whose storage argument was never walked, a template pimpl,
    an include-order dependent member, anonymous-namespace / local-class BASES that
    re-spelled as clean records, a malformed database entry that silently dropped a
    configuration, a pointer to a type-erased library base, and identity tables inside
    an allowlisted member. Each is answered below; the self-test carries every probe.

HOW IT ASKS (2026-09-28). Every type the walk judges comes from the COMPILER, never
from the header's text:
  (1) EVERY BUILD CONFIGURATION. The configurations are the distinct compile
      commands in `compile_commands.json` of the translation units that include
      `TaintPropagation.h` (found by a quote-include closure over `ir-pass/include`
      and the TU's own directory). Today there are two: CQPass (`-DCQPass_EXPORTS
      -fPIC`) and cq-opt / cq-scrub-selftest (neither). A problem in ANY
      configuration refuses; a missing database, a missing entry, an entry of this
      tree that cannot be parsed (review r1 F-R1-7) or a header that does not compile
      FAILS CLOSED. A compiler killed by a signal, or a probe that answers nothing and
      reports no error, fails closed too (never read as an answer).
  (2) THE CANONICAL TYPE OF EVERY FIELD. For each data member (static or not,
      public or private, a bit-field, a reference, a member of an anonymous union,
      a member of an unnamed struct reached through its field) the compiler is
      asked `decltype(std::declval<Scope &>().member)` inside an EXPLICIT
      INSTANTIATION's template argument (where access checking does not apply,
      [temp.spec.general]/6) and prints the type's CANONICAL form — aliases,
      typedefs, alias templates and pointee sugar all resolved, every name fully
      qualified. That closes r3's alias cases (`using Result = RawRec; Result *P;`):
      there is no longer a short name to look up.
  (3) THE COMPILER'S OWN IDENTITY FOR EVERY PROJECT TYPE. A project record or class
      template INSTANCE reached by value, by pointer or as a template argument is
      looked up by the compiler (an alias to it; the alias's `RecordType` names the
      definition's AST id) and THAT definition is walked: the explicit or partial
      specialization the build actually selects (also under `NDEBUG`), or the
      implicit instantiation the header itself made. Nothing is dumped or matched
      by name. A class-template specialization the header only POINTS AT (never
      instantiates) is REFUSED — a `.cpp` may explicitly specialize it, and the build
      would then use a body no header shows (a template pimpl, review r1 F-R1-3; the
      non-template pimpl, a pointer to a forward-declared record, was already
      refused). Its primary's forced instantiation is walked as well, so a raw
      primary is reported too. An unnamed record is identified by the compiler's
      `(unnamed struct at FILE:LINE:COL)`: a field of unnamed type is accepted only
      when that very record was walked through a declarator of the record being
      walked (review r1 F-R1-1).
  (4) THE SPELLING IS VERIFIED. The canonical text is re-spelled (every qualified
      name rooted at `::`) and `std::is_same` against the field's real type is
      asserted, so a printed type that does not denote the field's type (an
      explicit specialization prints its template arguments AS WRITTEN, in its own
      scope) is refused, never walked as a different type. A base class must be a
      base (`std::is_base_of`) AND be what its own injected-class-name names when
      looked up THROUGH the derived class (`typename D::B`) — an anonymous-namespace
      or local-class base that re-spells as a same-named clean record fails that
      (review r1 F-R1-6). Both assertions are asked inside an explicit
      instantiation's template argument, so a PRIVATE nested type is no access
      error there.
  (5) NO PCH IN THE GATE'S OWN RUN. `main()` asks every configuration WITHOUT a
      precompiled header. `check()` under `USE_PCH` (the self-test and the
      reviewers' harnesses) compiles with a per-configuration PCH for speed and
      RE-ASKS EVERY CLEAN VERDICT WITHOUT IT — clean is the only verdict a PCH can
      falsify. A refusal under the PCH is reported as is: it can only over-refuse.
  (6) THE INCLUDE-ORDER CHECK (review r1 F-R1-4). No PCH is NOT the same as "the
      build's preprocessing context": a real TU includes other headers BEFORE
      `TaintPropagation.h`, and a member under `#ifdef <a macro one of them defines>`
      exists in the build and not in the probe. So every clean verdict (in the no-PCH
      pass of each configuration) also preprocesses the header's include closure
      twice — alone, and after every header any TU of that configuration includes
      plus every project header (the closure's include guards pre-defined and undefined
      just before it, so it is really re-preprocessed in that context) — and refuses if
      any closure file's text differs. What it cannot see is RESIDUAL R10.
  Two details every probe TU shares, both found by attacking this design: every
  identifier a generated line uses is `#undef`ined after the header (a macro defined
  AFTER the record — `#define Evil Tainted` — would otherwise make
  `declval<S &>().Evil` answer for another member), and an AST node id is trusted
  only inside the compile that printed it (ids are addresses; two identity compiles
  can print the same id for different records). For SPEED only, the identity TU of
  a record also asks the members that record had in earlier passes; an answer is
  used only for a member the pass's own AST lists, and a wrong guess is an ignored
  compile error.

WHAT IT WALKS. Starting at `cq::TaintSet`: every field and static data member at
any depth — nested and anonymous records, members of unnamed structs through their
field, base classes — and every PROJECT type it reaches by value, by pointer, as a
template argument or as a `scrub::Map` MAPPED type. A PROJECT type is any record or
class template whose canonical name is NOT under `llvm::` or `std::` (so `cq::`,
the global namespace and every other namespace alike, r3 (d)). LIBRARY templates
(`llvm::`/`std::`) have every type argument walked, whether held by value or behind
a pointer (r3 (a)). A field is accepted if its canonical type is built from:
  * scalars: builtins (except `void` behind a pointer or as a template argument)
    and enums;
  * a pointer to a LIBRARY record only if it is approved (`APPROVED_POINTEES`, empty
    today — review r1 F-R1-8 made this CLOSED WORLD: `llvm::SmallPtrSetImplBase *`
    erased the arguments of the SmallPtrSet it pointed at); a pointer to a LIBRARY
    class-template instance, whose arguments are walked; never a pointer to a
    `Value`-derived type, to `llvm::Loop` / `llvm::Use` (IR-OWNED), or to a type the
    compiler says is neither a class, a union nor an enum (a misparse fails closed);
  * an APPROVED HANDLE (`HANDLES`, each asserted to derive from
    `llvm::ValueHandleBase`), except anywhere inside an associative KEY;
  * an APPROVED LEAF value type (`LEAVES`);
  * a `cq::scrub::Set`/`List`/`PairSet`/`Map` in the shapes ScrubOnDelete.h ships
    (`Set<std::set<P> | SmallPtrSet<P, N>, P>`, `List<P, N>`, `PairSet<P1, P2>`,
    `Map<P, V>` with V walked); any other argument shape is refused (review r1
    F-R1-5: a `Set`'s storage argument was never walked);
  * a LIBRARY class template whose type arguments are all acceptable, except the
    TYPE-ERASED bases in `TYPE_ERASED_TEMPLATES`;
  * a PROJECT type, whose selected definition's fields and bases are walked.

WHAT IT CATCHES (each with its own diagnostic): a raw pointer to a `Value`-derived
type (also through `*const`, `*volatile`, `*__restrict`); a `Value`-derived type held
by value (an unapproved handle such as `AssertingVH`, a bare pointer at
`LLVM_ENABLE_ABI_BREAKING_CHECKS=0`); a type-erased pointer (`void *`, an unapproved
library pointee) or `void` template argument; the SUGARED spelling `uintptr_t` /
`intptr_t` on the field; a pointer to `llvm::Loop` / `llvm::Use`; a value handle
ANYWHERE in the KEY of an associative container — in the key type itself, in its
template arguments, or inside a project record the key holds (r3 B7: the walk enters
records in KEY mode); an unknown library record held by value; a function type, a
pointer-to-member, a lambda, a member variable template; an unnamed type the walk
did not reach through its own declarator; a canonical spelling that does not denote
the field's type or base; a template pimpl; an include-order dependent header; a
type the walker cannot parse; a header that does not compile.

ALLOWLISTED members (`ALLOWLIST`, keyed by QUALIFIED member path) are STILL WALKED
(r3 B14 / bd jk56), in a RELAXED mode set per entry by `ALLOWLIST_POLICY`:
  "fields" (the default; `BreakRegions`) — a raw pointer, `Loop *`, incomplete
      pointee or unapproved handle is tolerated (listed as a note) only as a record's
      OWN FIELD; any pointer inside a LIBRARY container there (a sequence or a keyed
      container, listed in ASSOCIATIVE or not) is walked strictly (review r1 F-R1-9:
      `EquivalenceClasses<Value *>` and `UniqueVector<Value *>` used to pass as notes).
      That is what makes the reason "never a table asked by IDENTITY" a checked
      premise.
  "any" (`RestoringRoutes`, whose reason is "no writer", not a structure) — raw
      pointers tolerated anywhere but an associative KEY.
Every KEY is strict and every closed-world rule applies in both. The walk of a record
is keyed by mode, so a record reached both through an allowlisted member and through
an ordinary one is walked strictly as well.

RESIDUALS — what this version does NOT close; a reviewer should start here:
  R1 Library code is trusted BY NAME: a type, or an explicit/partial
     specialization of a library template, DECLARED BY A PROJECT HEADER INSIDE
     `namespace llvm` or `namespace std` is judged as library (its body is not
     walked). The project does open `namespace llvm` (forward declarations,
     `DenseMapInfo` specializations), so this is not a spelling the tree avoids.
     The same holds for the `cq::scrub::` containers, the approved HANDLES and
     LEAVES: each is trusted by its name (a project specialization of one is not
     walked). Pinned in the self-test as a known pass (review r1 A7); bd gqda.
  R2 An allowlisted member tolerates raw pointer FIELDS by design; under policy
     "any" (`RestoringRoutes` only) also raw pointer SEQUENCE elements, on which
     `is_contained` would be an identity question. Policy "fields" refuses them.
  R3 The configurations come from `compile_commands.json` TUs that include the
     header through QUOTE includes (`#include "X.h"`) resolvable in `ir-pass/include`
     or the TU's directory; a TU reaching it through a computed `#include MACRO`
     in a target with its own flags is not recognised. Only CONFIGURED builds are
     checked (a member only under `#ifndef NDEBUG` is unseen until a Debug tree is
     configured).
  R4 A field whose access path cannot be spelled (a named record nested inside an
     unnamed struct, a member of an unnamed struct reached through a POINTER field)
     is not asked of the compiler; any non-builtin type there is REFUSED — an
     over-refusal, never a pass.
  R5 A member class template that no field instantiates holds no storage and is
     not walked (the old version walked its PATTERN).
  R6 A handle inside a project record that a KEY reaches only through a POINTER is
     refused (conservative: a pointer key's ordering does not read the pointee).
  R7 Associative containers are known BY NAME (`ASSOCIATIVE`). An unlisted keyed
     library container (`llvm::EquivalenceClasses`, `llvm::FoldingSet`, ...) is
     judged like a sequence: a raw `Value *` in it is still refused (strictly under
     policy "fields" too), but a HANDLE as its key passes, and under policy "any" a
     raw pointer key passes as a note. Type-erased library TEMPLATE bases are known
     by name too (`TYPE_ERASED_TEMPLATES`).
  R8 A BASE is verified by `is_base_of` plus its injected-class-name looked up
     through the derived class. A derived class that declares its OWN member named
     like the base (`struct D : B { using B = int; };`) is refused (over-refusal);
     an injected-class-name that is ambiguous is refused too.
  R9 A PRIVATE nested project type reached through the identity lookup (a KEY, or
     a pointer from another mode) is refused as "no complete definition": the
     identity alias is subject to access checking. An over-refusal, never a pass.
  R10 The include-order check approximates "every real TU's context" by ONE context:
     every header the configuration's TUs include (in first-seen order) plus every
     project header, before the closure. It does not see (a) a `#define` a `.cpp`
     writes before its includes, (b) a condition true only for a COMBINATION of
     macros that neither the lone header nor that union context produces
     (`#if defined(A) && !defined(B)`), (c) a TU-local header the probe directory
     cannot reach. Whatever it sees differently is refused; the rest is IFNDR the
     compiler cannot catch either (TaintSet's token sequence would differ per TU).
  R11 A template pimpl is refused only when the header never instantiates the
     specialization; a `.cpp` that specializes a template the header DOES
     instantiate is a compile error ("explicit specialization after instantiation"),
     so no pass there.

INTENTIONALLY OUT OF SCOPE, and why:
  * an address laundered through a PLAIN INTEGER type (`unsigned long`, `size_t`, or
    an alias of one): to the compiler it IS an integer. Only the `uintptr_t` /
    `intptr_t` sugar on the field is recognisable, and only while it is spelled so.
  * an address laundered through a pointer to a BUILTIN (`const char *`, `unsigned
    char *` — `std::set<const char *>` of reinterpret_cast'd Values) or through raw
    byte storage (`alignas(...) unsigned char Buf[N]` holding a placement-new'd
    table): to the compiler these ARE characters (review r1 F-R1-10; A8 is pinned in
    the self-test as a known pass).
  * pointer-bearing state OUTSIDE `TaintSet` (`ControlPlan`, `SpecPlan`, file-static
    ledgers, local snapshots — bd ibtq): out of this gate's subject.
(Pointers to non-`Value` IR-adjacent LIBRARY objects — `llvm::MDNode *`,
`DominatorTree *` — used to be listed here; since review r1 F-R1-8 they are refused
unless approved in `APPROVED_POINTEES` with a reason.)

It also fails when (a) an ALLOWLIST entry names no member, and (b) a self-cleaning
member is not exercised by `ir-pass/tools/scrub_selftest.cpp` (comments stripped).

`--selftest` is its own mutant validation: null controls clean (in every
configuration and without the PCH), the configuration layer's fail-closed databases,
and every spelling of the five Rule-13 fool corpora it was built against (r1A
`guard_bypass.py`, r1B `guard_fool.py`, r2 `guard_fool_r2.py`, r3
`guard_fool_r3{,b}.py`, review r1 of the rewrite `rv_mutations.py`) plus its own
mutants REFUSED FOR THE RIGHT REASON (the expected diagnostic substring is checked,
so a compile error is not a kill). Known passes (R1, the builtin-pointer out-of-scope
case) are pinned as expected-clean entries labelled RESIDUAL / OUT OF SCOPE, so the
day one of them starts refusing the self-test says so. `--shard K/N` runs the K-th of N
balanced, deterministic slices (`_shards`; the configuration and PCH controls in shard 1), and
`--jobs N` (or CQ_GUARD_JOBS) bounds the compilers this process runs at once; the
ctest entries pass both, so the gate's own -j is respected.

The module keeps the first guard's API (`HEADER`, `SELFTEST`, `SCRUB_HDR`,
`INCLUDE_DIR`, `EXTRA_INCLUDES`, `ALLOWLIST`, `USE_PCH`, `_PCH`,
`check(header_src, selftest_src, allowlist, scrub_src)`), so the reviewers'
harnesses run against it unmodified.
"""
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDE_DIR = os.path.join(ROOT, "ir-pass", "include")
REAL_INCLUDE_DIR = INCLUDE_DIR   # the tree's own headers (config discovery never follows a swap)
HEADER = os.path.join(INCLUDE_DIR, "TaintPropagation.h")
SELFTEST = os.path.join(ROOT, "ir-pass", "tools", "scrub_selftest.cpp")
SCRUB_HDR = os.path.join(INCLUDE_DIR, "ScrubOnDelete.h")
COMPILE_COMMANDS = os.environ.get("CQ_GUARD_COMPILE_COMMANDS",
                                  os.path.join(ROOT, "build", "compile_commands.json"))
# check() semantics: compile with a per-configuration PCH first and RE-ASK every clean
# verdict without it. main() sets this to False (the gate's own run never uses a PCH).
USE_PCH = True

# Qualified member path -> reason. An allowlisted member is still WALKED, in a RELAXED
# mode chosen by ALLOWLIST_POLICY (bd jk56; review r1 F-R1-9):
#   "fields" (the default) — a raw pointer is tolerated only as a record's OWN FIELD; inside
#            ANY library container (sequence or keyed, listed in ASSOCIATIVE or not) the
#            walk is strict, so no table of raw pointers can hide there.
#   "any"    — raw pointers are tolerated anywhere except an associative KEY (which is
#            always strict). Used only where the reason is not structural.
ALLOWLIST = {
    "cq::TaintSet::RestoringRoutes": (
        "has NO WRITER anywhere in ir-pass/src (grep `RestoringRoutes.push_back` / "
        "`.emplace_back` finds nothing since drbq Inc 2a); its two readers iterate an "
        "always-empty container. Policy \"any\": its raw `const CallInst *` ELEMENTS (a "
        "SmallVector of SmallVectors) are tolerated, a KEYED container inside it is not. "
        "The day it gains a writer it must become handle-typed or a scrub:: container, "
        "and this entry must go."),
    "cq::TaintSet::BreakRegions": (
        "a per-loop RECORD (`LoopBreakRegion`, LoopPlan.h) of raw block/value/`Loop *` "
        "FIELDS that `lowerLoops` writes and `lowerBreakReversePlay` dereferences — "
        "never a table asked by IDENTITY. That premise is CHECKED (policy \"fields\", bd "
        "jk56 + review r1 F-R1-9): the walk descends into `LoopBreakRegion` and tolerates "
        "a raw pointer only as a direct FIELD; a raw pointer inside any library container "
        "there (EquivalenceClasses, UniqueVector, SmallVector, a map, ...) is refused. Its "
        "hazard is a different one (a dangling RECORD field, UAF-on-read) and is NOT "
        "closed by bd 8e5r; filed as bd test_C_libtooling-emof."),
}
ALLOWLIST_POLICY = {"cq::TaintSet::RestoringRoutes": "any"}   # every other entry: "fields"
RELAXED_MODES = ("relaxed_fields", "relaxed_any")
# Pointers to LIBRARY non-template records the walk accepts without seeing into them, each
# with its reason. CLOSED WORLD since review r1 F-R1-8: a pointer to any other library
# record that is not Value-derived is refused (`llvm::SmallPtrSetImplBase *` erased the
# arguments of the SmallPtrSet it pointed at). Empty today: the tree holds none.
APPROVED_POINTEES = {}
# Library TEMPLATES whose type arguments do not say what they hold (a type-erased base):
# refused by value and behind a pointer.
TYPE_ERASED_TEMPLATES = {
    "llvm::SmallVectorBase": "the size-only base of every SmallVector, element type erased",
}

# Approved value handles, with the reason each is admitted. Each is ALSO checked
# (by the compiler) to derive from `llvm::ValueHandleBase` — a real registered handle.
HANDLES = {
    "llvm::WeakVH": "identity handle: nulled when its Value is deleted, never "
                    "follows a RAUW, so it can never dangle",
    "llvm::WeakTrackingVH": "tracking handle: FOLLOWS a RAUW and is nulled on a plain "
                            "delete, so it can never dangle. Admitted where a record "
                            "must follow a RAUW — which the identity-keyed scrub:: "
                            "containers deliberately do not (d88e's "
                            "LiftedMergePhi::Base/Incomings, PeelClones, RailCondReads, ...)",
}
HANDLE_TEMPLATES = {"llvm::AssertingVH", "llvm::TrackingVH", "llvm::PoisoningVH"}
# Approved leaf value types (hold no Value pointer).
LEAVES = {
    "llvm::StringRef": "a (pointer, length) view of characters — no Value",
    "llvm::DebugLoc": "a metadata tracking reference — no Value",
}
# IR-owned non-Value objects a pointer to which the gate refuses.
IR_OWNED_DENY = {
    "llvm::Loop": "freed with its LoopInfo, not a Value: no ~Value callback observes it (bd emof)",
    "llvm::Use": "owned by its User, not a Value: no ~Value callback observes it",
}
# Associative containers: the KEY (first type argument) is walked in KEY mode.
ASSOCIATIVE = {
    "std::set", "std::multiset", "std::map", "std::multimap", "std::unordered_set",
    "std::unordered_map", "std::unordered_multiset", "std::unordered_multimap",
    "llvm::DenseSet", "llvm::DenseMap", "llvm::SmallDenseSet", "llvm::SmallDenseMap",
    "llvm::SmallSet", "llvm::SmallPtrSet", "llvm::MapVector", "llvm::SetVector",
    "llvm::SmallSetVector", "llvm::ValueMap",
    # keyed by their element (review r1 A6/A6b named the first two)
    "llvm::EquivalenceClasses", "llvm::UniqueVector", "std::priority_queue",
}
# Self-cleaning containers (ScrubOnDelete.h). `Map` also has its MAPPED type walked.
SCRUB_KEYS_ONLY = {"cq::scrub::Set", "cq::scrub::List", "cq::scrub::PairSet"}
SCRUB_MAP = "cq::scrub::Map"
LIBRARY_NS = ("llvm::", "std::")
ROOT_RECORD = "cq::TaintSet"

BUILTINS = {
    "void", "bool", "char", "signed char", "unsigned char", "wchar_t", "char8_t",
    "char16_t", "char32_t", "short", "unsigned short", "int", "unsigned int", "long",
    "unsigned long", "long long", "unsigned long long", "__int128",
    "unsigned __int128", "float", "double", "long double", "std::nullptr_t",
    "std::byte", "_Bool", "__fp16", "_Float16", "__bf16",
}
INTPTR_SUGAR = re.compile(r"\b(?:std::)?u?intptr_t\b")
RECORD_KINDS = {"CXXRecordDecl", "ClassTemplateSpecializationDecl"}


class GuardError(Exception):
    pass


# At most JOBS compiler processes at once, from every thread of this process (bd s6ma /
# review r1 F-R1-13: the self-test used to run ~24 compilers from ONE ctest entry, whatever
# the gate's -j). Set by --jobs or CQ_GUARD_JOBS; the ctest entries pass it explicitly.
JOBS = max(1, int(os.environ.get("CQ_GUARD_JOBS", "4") or 4))
_SEM = [threading.BoundedSemaphore(JOBS)]


def set_jobs(n):
    global JOBS
    JOBS = max(1, int(n))
    _SEM[0] = threading.BoundedSemaphore(JOBS)


def _run(cmd, cwd):
    with _SEM[0]:
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
        except OSError as ex:  # a compiler named by the database that does not exist
            raise GuardError(f"cannot run `{cmd[0]}` (from {COMPILE_COMMANDS}): {ex}")
    if r.returncode < 0:   # killed by a signal: never read its (partial) output as an answer
        raise GuardError(f"`{os.path.basename(cmd[0])}` was killed by signal {-r.returncode} "
                         f"(from {COMPILE_COMMANDS})")
    return r


# ----------------------------------------------------------------------------
# the build's configurations (bd 7gri (a)): every distinct compile command of a
# translation unit that includes TaintPropagation.h
# ----------------------------------------------------------------------------
class Config:
    def __init__(self, label, argv, cwd, srcs=()):
        self.label, self.argv, self.cwd = label, argv, cwd
        self.srcs = sorted(srcs)   # the TUs of this configuration that include the header
        self.key = (tuple(argv), cwd)


_CFGS = None
_CFGS_LOCK = threading.Lock()
_QINC = re.compile(r'^\s*#\s*include\s+"([^"]+)"', re.M)
_CXX_EXT = (".cpp", ".cc", ".cxx", ".c++", ".C")


def _includes_header(src, cache):
    """Does `src` reach TaintPropagation.h through QUOTE includes resolvable in its own
    directory or ir-pass/include? (Textual closure — RESIDUAL R3.)"""
    seen, stack = set(), [os.path.realpath(src)]
    while stack:
        f = stack.pop()
        if f in seen:
            continue
        seen.add(f)
        if f in cache:
            names = cache[f]
        else:
            try:
                names = _QINC.findall(open(f, errors="ignore").read())
            except OSError:
                names = []
            cache[f] = names
        for n in names:
            if os.path.basename(n) == "TaintPropagation.h":
                return True
            for d in (os.path.dirname(f), REAL_INCLUDE_DIR):
                p = os.path.realpath(os.path.join(d, n))
                if os.path.isfile(p):
                    stack.append(p)
                    break
    return False


def _normalize(entry):
    """-> (argv prefix [compiler, flags...], cwd, source path) with output, dependency and
    source arguments removed."""
    cwd = entry.get("directory") or ROOT
    src = os.path.realpath(os.path.join(cwd, entry.get("file", "")))
    argv = entry.get("arguments") or shlex.split(entry["command"])
    if not argv or not isinstance(argv[0], str) or not argv[0]:
        raise ValueError("no compiler in the entry")
    out, skip = [argv[0]], False
    for a in argv[1:]:
        if skip:
            skip = False
            continue
        if a in ("-o", "-MF", "-MT", "-MQ"):
            skip = True
            continue
        if a in ("-c", "-MD", "-MMD") or os.path.realpath(os.path.join(cwd, a)) == src:
            continue
        out.append(a)
    return out, cwd, src


def _configs():
    global _CFGS
    with _CFGS_LOCK:
        if _CFGS is not None:
            return _CFGS
        _CFGS = _configs_from(_load_db(COMPILE_COMMANDS), COMPILE_COMMANDS)
        return _CFGS


def _load_db(cc):
    if not os.path.isfile(cc):
        raise GuardError(f"compile database not found: {cc} — configure the build "
                         f"(CMAKE_EXPORT_COMPILE_COMMANDS is ON) or pass --compile-commands")
    try:
        db = json.load(open(cc))
        assert isinstance(db, list)
    except (ValueError, AssertionError) as ex:
        raise GuardError(f"compile database {cc} is not a JSON list of commands: {ex}")
    return db


def _configs_from(db, cc):
    """The configurations of database `db` (already parsed). An entry that belongs to THIS
    tree (or whose file cannot be told) and cannot be parsed FAILS CLOSED (bd s6ma / review
    r1 F-R1-7: a malformed entry used to drop its whole configuration silently)."""
    groups, cache = {}, {}
    root = os.path.realpath(ROOT) + os.sep
    for i, e in enumerate(db):
        if not isinstance(e, dict) or not isinstance(e.get("file"), str):
            raise GuardError(f"compile database {cc}: entry {i} has no `file` — refused (fail closed)")
        where = os.path.realpath(os.path.join(str(e.get("directory") or ROOT), e["file"]))
        try:
            argv, cwd, src = _normalize(e)
        except (KeyError, ValueError, TypeError, AttributeError) as ex:
            if where.startswith(root):
                raise GuardError(f"compile database {cc}: the entry for {where} cannot be parsed "
                                 f"({type(ex).__name__}: {ex}) — refused (fail closed)")
            continue
        if not src.startswith(root):   # a database of ANOTHER tree is not this build's
            continue
        if not src.endswith(_CXX_EXT) or not os.path.isfile(src):
            continue
        if not _includes_header(src, cache):
            continue
        g = groups.setdefault((tuple(argv), cwd), {"targets": set(), "n": 0, "srcs": set()})
        g["n"] += 1
        g["srcs"].add(src)
        m = re.search(r"CMakeFiles/([^/]+)\.dir/", e.get("output") or e.get("command") or "")
        g["targets"].add(m.group(1) if m else os.path.basename(src))
    if not groups:
        raise GuardError(f"no command in {cc} compiles a translation unit of {ROOT} that "
                         f"includes TaintPropagation.h (a database from another tree?)")
    cfgs = [Config("/".join(sorted(g["targets"])), list(k[0]), k[1], g["srcs"])
            for k, g in groups.items()]
    # the historical primary (CQPass) first, the rest in a stable order
    cfgs.sort(key=lambda c: (0 if "CQPass" in c.label.split("/") else 1, c.label))
    return cfgs


def _base_command():
    """Kept for callers of the previous API: the first configuration's (argv, cwd)."""
    c = _configs()[0]
    return c.argv, c.cwd


# ----------------------------------------------------------------------------
# the precompiled header — a SPEED device for check() under USE_PCH only; a clean
# verdict with it is always re-asked without it (bd 7gri (b))
# ----------------------------------------------------------------------------
_PCH = {"state": None, "dir": None, "by": {}}
_PCH_LOCK = threading.Lock()
EXTRA_INCLUDES = """#include <array>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <unordered_map>
#include <utility>
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/PointerIntPair.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Use.h"
#include "llvm/IR/ValueHandle.h"
"""


def _pch(cfg):
    with _PCH_LOCK:
        if cfg.key in _PCH["by"]:
            return _PCH["by"][cfg.key]
        lines = set(EXTRA_INCLUDES.splitlines()) | {"#include <type_traits>", "#include <utility>"}
        for f in os.listdir(INCLUDE_DIR):
            if f.endswith(".h"):
                for l in open(os.path.join(INCLUDE_DIR, f)):
                    m = re.match(r'\s*#\s*include\s+([<"])([^>"]+)[>"]', l)
                    if m and (m.group(1) == "<" or m.group(2).startswith(("llvm/", "llvm-c/"))):
                        lines.add(f"#include {m.group(1)}{m.group(2)}{'>' if m.group(1) == '<' else chr(34)}")
        if _PCH["dir"] is None:
            _PCH["dir"] = tempfile.mkdtemp(prefix="cq_scrub_guard_pch_")
        n = len(_PCH["by"])
        hdr = os.path.join(_PCH["dir"], f"cq_guard_prefix_{n}.h")
        open(hdr, "w").write("\n".join(sorted(lines)) + "\n")
        pch = hdr + ".pch"
        r = _run(cfg.argv + ["-w", "-x", "c++-header", hdr, "-o", pch], cfg.cwd)
        ok = r.returncode == 0 and os.path.isfile(pch)
        _PCH["by"][cfg.key] = pch if ok else None
        _PCH["state"] = "ok" if ok and _PCH["state"] in (None, "ok") else "failed"
        return _PCH["by"][cfg.key]


class Ctx:
    """One (configuration, PCH on/off) pass over one temp include directory."""

    def __init__(self, tmp, cfg, use_pch):
        self.tmp, self.cfg, self.use_pch = tmp, cfg, use_pch
        self.n = 0
        self.lock = threading.Lock()

    def fresh(self, stem):
        with self.lock:
            self.n += 1
            return os.path.join(self.tmp, f"{stem}_{id(self)}_{self.n}.cpp")


def _compile(ctx, tu, extra, retry=True):
    """Run the configuration's compiler on `tu` (syntax only). With the PCH when the pass
    uses one; `retry` recompiles a FAILED PCH compile without it (for TUs that are
    expected to compile; probe TUs with per-line errors pass retry=False)."""
    cfg = ctx.cfg
    cmd = cfg.argv + ["-fsyntax-only", "-fno-color-diagnostics", "-ferror-limit=0", "-w",
                      f"-I{ctx.tmp}"]
    if ctx.use_pch:
        pch = _pch(cfg)
        if pch:
            r = _run(cmd + ["-include-pch", pch] + extra + [tu], cfg.cwd)
            if r.returncode == 0 or not retry:
                return r
    return _run(cmd + extra + [tu], cfg.cwd)


def _json_docs(s):
    dec, i, out = json.JSONDecoder(), 0, []
    while i < len(s):
        while i < len(s) and s[i] in " \n\r\t":
            i += 1
        if i >= len(s):
            break
        o, i = dec.raw_decode(s, i)
        out.append(o)
    return out


def _dump(ctx, tu_text, flt, stem, retry=False):
    tu = ctx.fresh(stem)
    open(tu, "w").write(tu_text)
    r = _compile(ctx, tu, ["-Xclang", "-ast-dump=json", "-Xclang", "-ast-dump-filter",
                           "-Xclang", flt], retry=retry)
    try:
        docs = _json_docs(r.stdout)
    except ValueError:
        docs = []
    return r, docs, tu


def _iter_nodes(docs):
    stack = list(docs)
    while stack:
        n = stack.pop()
        if isinstance(n, dict):
            yield n
            stack.extend(n.get("inner") or [])


def _error_lines(stderr, tu):
    base = os.path.basename(tu)
    out = {}
    for line in stderr.splitlines():
        m = re.search(re.escape(base) + r":(\d+):\d+: error: (.*)", line)
        if m:
            out.setdefault(int(m.group(1)), m.group(2))
    return out


def _first_errors(stderr, k=6):
    return [l for l in stderr.splitlines() if " error: " in l or l.startswith("error:")][:k]


# ----------------------------------------------------------------------------
# the type-string parser (over the compiler's CANONICAL spelling)
# ----------------------------------------------------------------------------
def _split_top(s, sep=","):
    parts, depth, cur = [], 0, []
    for ch in s:
        if ch in "<([{":
            depth += 1
        elif ch in ">)]}":
            depth -= 1
        if ch == sep and depth == 0:
            parts.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if cur or parts:
        parts.append("".join(cur).strip())
    return parts


def _split_scope(q):
    """Split a qualified name at the TOP-LEVEL `::` (never inside `<...>` or `(...)`)."""
    parts, depth, cur, i = [], 0, [], 0
    while i < len(q):
        ch = q[i]
        if ch in "<([":
            depth += 1
        elif ch in ">)]":
            depth -= 1
        if depth == 0 and q.startswith("::", i):
            parts.append("".join(cur))
            cur, i = [], i + 2
            continue
        cur.append(ch)
        i += 1
    parts.append("".join(cur))
    return [p for p in parts if p != ""]


def _balanced(s):
    d = 0
    for ch in s:
        d += ch in "<([{"
        d -= ch in ">)]}"
        if d < 0:
            return False
    return d == 0


_UNNAMED = re.compile(r"^\((?:unnamed|anonymous) (?:struct|class|union|enum)\b")


def parse_type(t):
    """-> ('ptr', inner) | ('arr', inner) | ('anon', text) | ('fn', text) | ('memptr', text)
          | ('tmpl', name, [args], text) | ('named', name) | ('lit', text)"""
    t = " ".join(t.split())
    while True:   # cv / restrict qualifiers, also directly after `*` / `&` (bd ehni / review r1
        #          F-R1-2: `llvm::Value *const *` used to parse as a pointer to a NAMED type
        #          `llvm::Value *const`, which the traits answered "complete, not a Value")
        n = re.sub(r"^(const|volatile|__restrict|restrict)\s+", "", t)
        n = re.sub(r"(?:(?<=\s)|(?<=[*&]))(const|volatile|__restrict|restrict)$", "", n).rstrip()
        if n == t:
            break
        t = n
    if not t:
        return ("lit", t)
    # a NON-TYPE template argument: `4`, `true`, `nullptr`, `(cq::E)1`, `&cq::X`
    if (re.match(r"^-?[0-9]", t) or t in ("true", "false", "nullptr") or t.startswith("&")
            or re.match(r"^\([\w:\s]+\)\s*-?[0-9]", t)):
        return ("lit", t)
    m = re.match(r"^(struct|class|union|enum)\s+(.*)$", t)
    if m:
        t = m.group(2)
    last = _split_scope(t)[-1] if t else t
    if _UNNAMED.match(last):
        return ("anon", t)
    if last.startswith("(lambda"):
        return ("fn", t)
    m = re.match(r"^(.*\S)\s*\[[^\[\]]*\]$", t)
    if m and _balanced(m.group(1)):
        return ("arr", parse_type(m.group(1)))
    if re.search(r"::\*$", t):
        return ("memptr", t)
    if t.endswith("*") or t.endswith("&"):
        inner = t[:-2].rstrip() if t.endswith("&&") else t[:-1].rstrip()
        if _balanced(inner) and inner:
            return ("ptr", parse_type(inner))
    if t.endswith(")") or "(*)" in t or "(&)" in t:
        return ("fn", t)
    if t.endswith(">"):
        depth, start = 0, None
        for i, ch in enumerate(t):
            if ch == "<":
                if depth == 0 and start is None:
                    start = i
                depth += 1
            elif ch == ">":
                depth -= 1
        if start is not None:
            name = t[:start].strip()
            args = [a for a in _split_top(t[start + 1:-1]) if a != ""]
            return ("tmpl", name, [parse_type(a) for a in args], t)
    return ("named", t)


def _render(node):
    k = node[0]
    if k == "ptr":
        return _render(node[1]) + " *"
    if k == "arr":
        return _render(node[1]) + "[]"
    if k == "tmpl":
        return node[3]
    return node[1]


_QUAL_HEAD = re.compile(r"(?<![\w:])([A-Za-z_]\w*)(?=::)")


def _spell(t):
    """The compiler's canonical text, spelled so it denotes the same type from ANY scope:
    every qualified name rooted at `::`, `(anonymous namespace)::` dropped. ⚠ Dropping it is
    NOT meaning-preserving: when the enclosing namespace declares the same name, qualified
    lookup finds THAT one (review r1 F-R1-6, L7 — an earlier version of this comment said
    the members "are visible in the enclosing namespace", which is false under shadowing).
    It is sound only because every use is VERIFIED against the compiler: a field's spelling
    by `is_same` with the member's real type, a base's by `is_base_of` plus the base's own
    injected-class-name looked up through the derived class (`_final`). Global-namespace
    names stay unqualified."""
    t = t.replace("(anonymous namespace)::", "")
    return _QUAL_HEAD.sub(r"::\1", t)


def _spellable(t):
    s = t.replace("(anonymous namespace)::", "")
    return not ("(unnamed " in s or "(anonymous " in s or "(lambda " in s)


def _library(name):
    return name.startswith(LIBRARY_NS)


def _all_library(text):
    """True if every qualified name in `text` is an llvm:: / std:: name (a trait answer
    about it cannot depend on the header under test)."""
    heads = re.findall(r"(?<![\w:])([A-Za-z_]\w*)::", text)
    return all(h in ("llvm", "std") for h in heads) and heads != []


# ----------------------------------------------------------------------------
# the walk
# ----------------------------------------------------------------------------
class FieldJob:
    __slots__ = ("path", "name", "prefix", "sugared", "fallback", "top_level", "mode",
                 "origin", "k", "canon", "ident")

    def __init__(self, path, name, prefix, sugared, fallback, top_level, mode, origin):
        self.path, self.name, self.prefix = path, name, prefix
        self.sugared, self.fallback, self.top_level = sugared, fallback, top_level
        self.mode, self.origin = mode, origin
        self.k, self.canon, self.ident = None, None, None

    @property
    def access(self):
        return f"{self.prefix}.{self.name}"


class Walk:
    def __init__(self, allowlist):
        self.allowlist = allowlist
        self.errs, self.tolerated = [], []
        self.pointee_q = {}   # library name -> [(path, mode, origin)]: Value-derived? complete?
        self.named_q = {}     # library name -> [(path, via, mode, origin)]: enum? Value? handle?
        self.foreign = {}     # (project qname, mode) -> (first path, key origin)
        self.foreign_done = set()
        self.walked = set()   # (identity qname, record AST id, mode)
        self.jobs = []        # FieldJob awaiting its canonical type
        self.done_jobs = []   # FieldJob with a canonical type (for the spelling check)
        self.bases = []       # (path, base canonical text, derived qname)
        self.scrub_fields = []  # (path, name, top_level)
        self.members = 0
        self.seen_paths = set()
        # "strict" | "key" | "relaxed_fields" | "relaxed_any" (allowlisted subtrees; see
        # ALLOWLIST_POLICY) — a RELAXED mode tolerates pointer-class findings, and
        # "relaxed_fields" only as a record's own FIELD, never inside a library container
        self.mode = "strict"
        self.origin = None    # (member path, container) while mode == "key"
        self.canonical = True
        self.cur_ident = None  # the identified record whose tree is being walked (speculation key)
        self.anon_walked = set()  # location keys of the unnamed records walked through their field

    # -- diagnostics -----------------------------------------------------------
    def _err_as(self, path, msg, cls, mode, origin):
        """cls: "ptr" (a pointer-class finding: tolerated in a RELAXED subtree),
        "key" or "world" (never tolerated)."""
        if cls == "ptr" and mode in RELAXED_MODES:
            where = ("a FIELD of an allowlisted member" if mode == "relaxed_fields"
                     else "inside an allowlisted member")
            self.tolerated.append(f"{path}: {msg.split(' — ')[0]} ({where})")
            return
        if mode == "key" and origin is not None:
            msg += f" [inside the KEY of `{origin[1]}` held by `{origin[0]}`]"
        self.errs.append(f"{path}: {msg}")

    def _err(self, path, msg, cls):
        self._err_as(path, msg, cls, self.mode, self.origin)

    def _hkey(self, path, what):
        container = self.origin[1] if self.origin else "?"
        self.errs.append(f"{path}: a value HANDLE ({what}) in the KEY of `{container}`"
                         + (f" held by `{self.origin[0]}`" if self.origin else "")
                         + " — a handle is nulled/retargeted IN PLACE, which breaks the "
                           "container's ordering/hash invariant; refused")

    def _world_noncanon(self, path, what):
        self._err(path, f"`{what}` — this field's type could not be asked of the compiler (its "
                        f"access path cannot be spelled), and only builtins are accepted there "
                        f"(closed world: refused)", "world")

    # -- the type walk -----------------------------------------------------------
    def field_top(self, path, node, top_level, name):
        while node[0] == "arr":
            node = node[1]
        if node[0] == "anon":
            # A field of unnamed record type is accepted ONLY when that very record — keyed by
            # the compiler's own `(unnamed struct at FILE:LINE:COL)` — was walked through a
            # declarator of the record being walked (bd hdxo / review r1 F-R1-1: an unnamed
            # type DEFINED ELSEWHERE, `decltype(Other::U) M;`, used to be accepted unwalked).
            if _anon_key(node[1]) in self.anon_walked:
                return
            self._err(path, f"unnamed type `{node[1]}` defined outside the record the walk is in — "
                            f"the walk cannot follow it (closed world: refused)", "world")
            return
        if node[0] == "tmpl":
            return self._tmpl(path, node, top_level, name)
        return self._t(path, node)

    def _t(self, path, node):
        k = node[0]
        if k == "lit":
            return
        if k == "ptr":
            return self._ptr(path, node[1])
        if k == "arr":
            return self._t(path, node[1])
        if k == "fn":
            self._err(path, f"function or lambda type `{node[1]}` — not understood by the walker "
                            f"(closed world: refused)", "world")
            return
        if k == "memptr":
            self._err(path, f"pointer-to-member type `{node[1]}` — not understood by the walker "
                            f"(closed world: refused)", "world")
            return
        if k == "anon":
            self._err(path, f"unnamed type `{node[1]}` where the walk cannot follow it "
                            f"(closed world: refused)", "world")
            return
        if k == "tmpl":
            return self._tmpl(path, node)
        return self._named(path, node[1])

    def _ptr(self, path, inner):
        while inner[0] in ("ptr", "arr"):   # T ** / T *[N]: judge the innermost pointee
            inner = inner[1]
        k = inner[0]
        if k == "named":
            nm = inner[1]
            if nm == "void":
                self._err(path, "TYPE-ERASED pointer (`void *`) — it can hold a Value address "
                                "the compiler cannot see; refused", "ptr")
                return
            if nm in BUILTINS:
                return
            if nm in HANDLES:
                if self.mode == "key":
                    self._hkey(path, f"pointer to `{nm}`")
                return
            if nm in LEAVES:
                return
            if not self.canonical:
                return self._world_noncanon(path, nm + " *")
            if nm in IR_OWNED_DENY:
                self._err(path, f"pointer to IR-OWNED `{nm}` — {IR_OWNED_DENY[nm]}; refused", "ptr")
                return
            if _library(nm):
                self.pointee_q.setdefault(nm, []).append((path, self.mode, self.origin))
                return
            self._project(path, nm)
            return
        if k == "tmpl":
            self._tmpl(path, inner)
            if self.canonical and _library(inner[1]):
                self.pointee_q.setdefault(inner[3], []).append((path, self.mode, self.origin))
            return
        if k == "anon":
            return self.field_top(path, inner, False, None)   # same rule as a field of that type
        return self._t(path, inner)

    def _tmpl(self, path, node, top_level=False, name=None):
        nm, args, text = node[1], node[2], node[3]
        if not self.canonical:
            return self._world_noncanon(path, text)
        if nm in SCRUB_KEYS_ONLY or nm == SCRUB_MAP:
            bad = _scrub_shape_problem(nm, args)
            if bad:   # bd ofvm / review r1 F-R1-5: a scrub container's other slots are not walked
                self._err(path, f"`{text}`: {bad} — a scrub:: container is trusted by name, so its "
                                f"arguments must have the shape ScrubOnDelete.h ships (closed world: "
                                f"refused)", "world")
                return
            if name is not None:
                self.scrub_fields.append((path, name, top_level))
            if nm == SCRUB_MAP:
                self._arg(path + " [ScrubMap MAPPED type]", args[1], nm)
            return
        if nm in HANDLE_TEMPLATES:
            if self.mode == "key":
                self._hkey(path, f"`{text}`")
            else:
                self._err(path, f"value handle `{text}` is not on the approved list "
                                f"({', '.join(sorted(HANDLES))}) — held BY VALUE; refused", "ptr")
            return
        if nm in TYPE_ERASED_TEMPLATES:
            self._err(path, f"`{text}` is a TYPE-ERASED library base ({TYPE_ERASED_TEMPLATES[nm]}); "
                            f"refused", "world")
            return
        saved = (self.mode, self.origin)
        # An allowlisted member's premise under policy "fields" is "raw pointer FIELDS, never a
        # table": a LIBRARY container's argument that is not a record held by value (a
        # pointer, an array of pointers, ...) is walked STRICTLY there (bd jk56 / review r1
        # F-R1-9); a record held by value keeps the policy for its own fields.
        strict_args = self.mode == "relaxed_fields" and _library(nm)
        try:
            rest = args
            if nm in ASSOCIATIVE and args:
                if self.mode != "key":
                    self.mode, self.origin = "key", (path, nm)
                try:
                    self._arg(path, args[0], nm)
                finally:
                    self.mode, self.origin = saved
                rest = args[1:]
            for a in rest:
                if strict_args and a[0] not in ("named", "tmpl", "lit"):
                    self.mode, self.origin = "strict", None
                try:
                    self._arg(path, a, nm)
                finally:
                    self.mode, self.origin = saved
        finally:
            self.mode, self.origin = saved
        if not _library(nm):
            self._project(path, text)   # the INSTANCE the build selects is walked

    def _arg(self, path, a, via):
        if a[0] == "named":
            if a[1] == "void":
                self._err(path, f"`void` template argument of `{via}` — a TYPE-ERASED holder "
                                f"can hold a Value address; refused", "ptr")
            else:
                self._named(path, a[1], via=via)
        else:
            self._t(path, a)

    def _named(self, path, nm, via=None):
        if nm in BUILTINS:
            return
        if nm in HANDLES:
            if self.mode == "key":
                self._hkey(path, f"`{nm}`")
            return
        if nm in LEAVES:
            return
        if not self.canonical:
            return self._world_noncanon(path, nm)
        if _library(nm):
            self.named_q.setdefault(nm, []).append((path, via, self.mode, self.origin))
            return
        self._project(path, nm)

    def _project(self, path, qname):
        self.foreign.setdefault((qname, self.mode), (path, self.origin))


_ANON_AT = re.compile(r"\((?:unnamed|anonymous) (?:struct|class|union|enum) at ([^()]*)\)")


def _anon_key(text):
    """`(unnamed struct at /tmp/x/TaintPropagation.h:116:19)` -> `TaintPropagation.h:116:19`:
    the compiler's own identity for an unnamed record (its definition's location)."""
    m = _ANON_AT.search(text or "")
    if not m:
        return None
    loc = m.group(1)
    head, _, tail = loc.rpartition(":")
    head2, _, mid = head.rpartition(":")
    return f"{os.path.basename(head2)}:{mid}:{tail}"


def _scrub_shape_problem(nm, args):
    """The scrub:: containers ScrubOnDelete.h ships, and the argument shapes they are
    trusted with: Set<std::set<P> | llvm::SmallPtrSet<P, N>, P>, List<P, N>,
    PairSet<P1, P2>, Map<P, V> (V walked). Anything else -> a reason string."""
    def ptr(a):
        return a[0] == "ptr"
    if nm == "cq::scrub::Set":
        if len(args) != 2 or not ptr(args[1]):
            return "a Set must be Set<StorageT, P> with P a pointer"
        st, p = args[0], _render(args[1])
        if st[0] != "tmpl":
            return f"the Set's backing storage `{_render(st)}` is not an approved backing"
        if st[1] == "std::set" and len(st[2]) == 1 and _render(st[2][0]) == p:
            return None
        if (st[1] == "llvm::SmallPtrSet" and len(st[2]) == 2 and _render(st[2][0]) == p
                and st[2][1][0] == "lit"):
            return None
        return (f"the Set's backing storage `{st[3]}` is not `std::set<{p}>` or "
                f"`llvm::SmallPtrSet<{p}, N>` (its storage is never walked)")
    if nm == "cq::scrub::List":
        if len(args) != 2 or not ptr(args[0]) or args[1][0] != "lit":
            return "a List must be List<P, N> with P a pointer"
        return None
    if nm == "cq::scrub::PairSet":
        if len(args) != 2 or not ptr(args[0]) or not ptr(args[1]):
            return "a PairSet must be PairSet<P1, P2> with both pointers"
        return None
    if nm == SCRUB_MAP:
        if len(args) != 2 or not ptr(args[0]):
            return "a Map must be Map<P, V> with P a pointer"
        return None
    return "an unknown scrub:: container"


def _decl_prefix(qname):
    return f"std::declval<{_spell(qname)} &>()"


def _walk_record(W, rec, path, qname, prefix, top_level):
    """Walk a record definition (CXXRecordDecl / ClassTemplateSpecializationDecl JSON):
    bases, data members, static data members, nested and anonymous records. `qname` is
    the record's canonical name (None for an unnamed record); `prefix` the expression
    its members are accessed through (None when it cannot be spelled — RESIDUAL R4)."""
    # AST ids are addresses in ONE compiler process; every identified record comes from its
    # own compile, so the id is only unique together with the identity that produced it.
    key = (W.cur_ident, rec.get("id"), W.mode)
    if key in W.walked:
        return
    W.walked.add(key)
    if qname:   # a named record walked here (nested, in this mode) needs no identity lookup later
        W.foreign_done.add((qname, W.mode))
    for b in rec.get("bases", []) or []:
        bt = b.get("type", {})
        text = bt.get("desugaredQualType") or bt.get("qualType", "")
        bpath = path + "::<base>"
        if qname and _spellable(text):
            W.bases.append((bpath, text, qname))
            saved = W.canonical
            W.canonical = True
            try:
                W._t(bpath, parse_type(text))
            finally:
                W.canonical = saved
        else:
            saved = W.canonical
            W.canonical = False
            try:
                W._t(bpath, parse_type(text))
            finally:
                W.canonical = saved
    inner = rec.get("inner", []) or []
    for i, c in enumerate(inner):
        kind = c.get("kind")
        if kind in ("FieldDecl", "VarDecl"):
            nm = c.get("name")
            if not nm:
                continue   # the implicit field of an anonymous record, or an unnamed bit-field
            p = f"{path}::{nm}"
            W.members += 1
            W.seen_paths.add(p)
            t = c.get("type", {})
            sugared = t.get("qualType", "")
            mode, origin = W.mode, W.origin
            if p in W.allowlist and mode == "strict":
                pol = ALLOWLIST_POLICY.get(p, "fields")
                mode, origin = ("relaxed_any" if pol == "any" else "relaxed_fields"), None
            if INTPTR_SUGAR.search(sugared):
                W._err_as(p, f"`{sugared}` — an address laundered through uintptr_t/intptr_t can "
                             f"alias a Value; refused", "world", mode, origin)
                continue
            job = FieldJob(p, nm, prefix, sugared, t.get("desugaredQualType") or sugared,
                           top_level, mode, origin)
            job.ident = W.cur_ident
            W.jobs.append(job)
        elif kind == "VarTemplateDecl":
            W._err(f"{path}::{c.get('name')}", "member VARIABLE TEMPLATE — its instantiations are "
                                               "storage the walk does not follow (closed world: "
                                               "refused)", "world")
        elif kind == "CXXRecordDecl" and c.get("completeDefinition") and not c.get("isImplicit"):
            nm = c.get("name")
            if nm:
                q = f"{qname}::{nm}" if qname else None
                _walk_record(W, c, f"{path}::{nm}", q, _decl_prefix(q) if q else None, False)
                continue
            nxt = inner[i + 1] if i + 1 < len(inner) else None
            if not (nxt and nxt.get("kind") in ("FieldDecl", "VarDecl")):
                continue   # no declarator: no storage (a typedef'd unnamed record is reached by name)
            ntype = nxt.get("type", {})
            ntext = (ntype.get("desugaredQualType") or "") + (ntype.get("qualType") or "")
            if "(unnamed " not in ntext and "(anonymous " not in ntext:
                continue
            nq = ntype.get("qualType", "").rstrip()
            key = _anon_key(ntext)
            if key:
                W.anon_walked.add(key)
            if not nxt.get("name"):
                sub = prefix                                   # anonymous: members injected
            elif prefix and nq.endswith("]") and "*" not in nq and "&" not in nq:
                sub = f"{prefix}.{nxt['name']}[0]"             # an array of unnamed type
            elif prefix and not re.search(r"[*&\]]$", nq):
                sub = f"{prefix}.{nxt['name']}"                # a field of unnamed type
            else:
                sub = None                                     # RESIDUAL R4: not spelled
            _walk_record(W, c, f"{path}::(anonymous)", None, sub, False)


# ----------------------------------------------------------------------------
# compiler questions
# ----------------------------------------------------------------------------
ROB_PRELUDE = """namespace cq_guard_canon {
template <class T> struct box {};
template <class Tag, class T> struct robt { friend constexpr auto get(Tag) { return box<T>{}; } };
template <bool B> struct req;
template <> struct req<true> { using type = int; };
template <class C, int K> struct chk {};
}
"""


def _check_line(k, cond):
    # An assertion asked inside an EXPLICIT INSTANTIATION's template argument, so a PRIVATE
    # nested type in `cond` is not an access error (a static_assert would be); a false
    # `cond` is an error ON THIS LINE (`req<false>` is undefined), never inside a header.
    return (f"template struct cq_guard_canon::chk<typename cq_guard_canon::req<{cond}>::type, "
            f"{k}>;")
BOX = "cq_guard_canon::box<"


_KEYWORDS = set("""alignas alignof and asm auto bool break case catch char char8_t char16_t
char32_t class const constexpr const_cast continue decltype default delete do double
dynamic_cast else enum explicit export extern false float for friend goto if inline int long
mutable namespace new noexcept not nullptr operator or private protected public register
reinterpret_cast return short signed sizeof static static_assert static_cast struct switch
template this thread_local throw true try typedef typeid typename union unsigned using virtual
void volatile wchar_t while xor _Bool __int128""".split())


_HELPER_NAMES = ("std declval get complete derived llvm Value ValueHandleBase is_same is_base_of "
                 "is_enum is_class conjunction void_t false_type true_type req chk type value")


def _undefs(texts):
    """`#undef` every identifier the generated lines use (a macro defined AFTER the record —
    `#define Evil Tainted` — would otherwise make `declval<S &>().Evil` ask about another
    member). Names are undefined only in the probe TU, after the header was parsed."""
    ids = set()
    for t in texts:
        ids.update(re.findall(r"[A-Za-z_]\w*", t))
    return [f"#undef {i}" for i in sorted(ids) if i not in _KEYWORDS]


def _head(texts):
    """The first lines of every probe TU: the header, the two standard headers the probe
    needs (before any #undef), the #undefs, then the probe's own helper templates."""
    return (['#include "TaintPropagation.h"', "#include <type_traits>", "#include <utility>"]
            + _undefs(list(texts) + [ROB_PRELUDE, _ID_HELPER, _HELPER_NAMES])
            + ROB_PRELUDE.splitlines() + [_ID_HELPER])


def _tag_line(k, access):
    # The member's type is taken inside an EXPLICIT INSTANTIATION's template argument, where
    # access checking does not apply ([temp.spec.general]/6), and carried out through a
    # friend of the instantiation (found by ADL on the tag). One line per member.
    return (f"namespace cq_guard_canon {{ struct tag{k} {{ friend constexpr auto get(tag{k}); }}; }} "
            f"template struct cq_guard_canon::robt<cq_guard_canon::tag{k}, decltype({access})>;")


def _rob_line(k, access):
    return _tag_line(k, access) + f" namespace cq_guard_canon {{ using c{k} = decltype(get(tag{k}{{}})); }}"


_ROB_ALIAS = re.compile(r"^(?:c|.*_cq_guard_c)(\d+)$")


def _rob_results(docs):
    got = {}
    for d in _iter_nodes(docs):
        if d.get("kind") == "TypeAliasDecl":
            m = _ROB_ALIAS.match(d.get("name", ""))
            if m:
                t = d.get("type", {})
                s = t.get("desugaredQualType") or t.get("qualType", "")
                if s.startswith(BOX) and s.endswith(">"):
                    got[int(m.group(1))] = s[len(BOX):-1].strip()
    return got


def _new_k(state, access):
    with state["lock"]:
        k = state["next_k"]
        state["next_k"] += 1
        state["access"][k] = access
        return k


def _rob(ctx, jobs, state):
    """Ask the compiler the canonical type of every job's member not already answered in
    this pass (speculatively, by an identity TU). Sets job.k / job.canon (None: failed)."""
    ask = []
    for j in jobs:
        key = (j.prefix, j.name)
        if key in state["rob_cache"]:
            j.k, j.canon = state["rob_cache"][key]
            continue
        j.k = _new_k(state, j.access)
        ask.append(j)
    if not ask:
        return
    lines, where = _head([j.access for j in ask]), {}
    for j in ask:
        lines.append(_rob_line(j.k, j.access))
        where[len(lines)] = j
    r, docs, tu = _dump(ctx, "\n".join(lines) + "\n", "cq_guard_canon::c", "cq_guard_rob")
    got = _rob_results(docs)
    bad = _error_lines(r.stderr, tu)
    if not got and not bad:   # no answer AND no error: the compiler did not do its job
        raise GuardError("the member-type probe produced no answer and no diagnostic "
                         f"(rc {r.returncode}) — the compiler misbehaved; this gate fails closed")
    for ln, j in where.items():
        if ln not in bad and j.k in got:
            j.canon = got[j.k]
            state["rob_cache"][(j.prefix, j.name)] = (j.k, j.canon)


_ID_HELPER = ("namespace cq_guard_idh { template <typename T, typename = void> struct complete : "
              "std::false_type {}; template <typename T> struct complete<T, std::void_t<decltype("
              "sizeof(T))>> : std::true_type {}; }")

# Speculation (SPEED only): identity qname -> the (prefix, member) questions its record tree
# needed in earlier passes. The identity TU asks them too, so a pass that meets the same
# members skips a compile. An answer is only ever USED for a member the pass's own JSON
# lists, asked in the pass's own TU; a wrong guess is a compile error that is ignored.
_SPEC = {}
_SPEC_LOCK = threading.Lock()


def _identify(ctx, qname, idx, retry=False, state=None, force=False):
    """-> (kind, payload, errors NOT on speculative lines): ("record", [definition nodes]) |
    ("enum", None) | ("uninstantiated", None) | ("missing", None) | ("error", text). The
    compiler resolves `qname` (an alias to it); the alias's RecordType names the
    definition's AST id, and THAT node is returned — the specialization the build selects,
    the implicit instantiation the header already made, or the record. Nothing is matched
    by name. A class-template specialization the header itself never instantiated is
    reported as "uninstantiated" unless `force` (bd ngfa / review r1 F-R1-3: a .cpp may
    explicitly specialize it — a template PIMPL — so the primary's instantiation is not
    necessarily what the build uses). With `state`, the members this record's tree had in
    earlier passes are asked in the same TU (answers go to state['rob_cache']); never for a
    template instance, whose members would instantiate it."""
    comps = _split_scope(qname)
    j = next((i for i, c in enumerate(comps) if "<" in c), None)
    fcomps = list(comps[: j + 1] if j is not None else comps)
    fcomps[-1] = fcomps[-1].split("<")[0]
    short = fcomps[-1]
    filters = [("::".join(fcomps), fcomps[:-1])]
    if len(fcomps) > 1:
        filters.append((short, []))   # e.g. an INLINE namespace the canonical print elides
    spelled = _spell(qname)
    spec = []
    if state is not None and "<" not in qname:
        with _SPEC_LOCK:
            pairs = sorted(_SPEC.get(qname, ()))
        spec = [(_new_k(state, f"{p}.{n}"), (p, n)) for p, n in pairs
                if (p, n) not in state["rob_cache"]]
    last_err, errs = None, []
    for fi, (flt, ns) in enumerate(filters):
        use_spec = spec if fi == 0 else []
        alias = f"{short}_cq_guard_id_{idx}_{fi}"
        opens = "".join("namespace { " if c == "(anonymous namespace)" else f"namespace {c} {{ "
                        for c in ns)
        lines = _head([spelled] + ns + [f"{pn[0]}.{pn[1]}" for _, pn in use_spec])
        spec_lines = {}
        for k, pn in use_spec:
            lines.append(_tag_line(k, f"{pn[0]}.{pn[1]}"))
            spec_lines[len(lines)] = k
        lines.append(f"namespace cq_guard_idns {{ {opens}")
        lines.append(f"using {alias} = {spelled};" + (
            f" constexpr bool {alias}_c = ::cq_guard_idh::complete<{alias}>::value;" if force else ""))
        for k, pn in use_spec:   # named so the dump filter matches them too
            lines.append(f"using {short}_cq_guard_c{k} = decltype(get(::cq_guard_canon::tag{k}{{}}));")
            spec_lines[len(lines)] = k
        lines.append("} " * len(ns) + "}")
        r, docs, tu = _dump(ctx, "\n".join(lines) + "\n", flt, "cq_guard_id", retry=retry and not use_spec)
        eline = _error_lines(r.stderr, tu)
        bad_k = {spec_lines[ln] for ln in eline if ln in spec_lines}
        errs = [l for l in _first_errors(r.stderr, 50)
                if not any(re.search(re.escape(os.path.basename(tu)) + f":{ln}:", l) for ln in spec_lines)][:6]
        if use_spec:
            got = _rob_results(docs)
            with state["lock"]:
                for k, pn in use_spec:
                    if k in got and k not in bad_k:
                        state["rob_cache"][pn] = (k, got[k])
        target = None
        for n in _iter_nodes(docs):
            if n.get("kind") == "TypeAliasDecl" and n.get("name") == alias:
                target = n
                break
        if target is None:
            last_err = "; ".join(errs[:3]) or "the compiler did not resolve it"
            continue
        tid = tkind = None
        stack = list(reversed(target.get("inner") or []))
        while stack:   # DFS, NOT into template arguments (their records are not the target)
            n = stack.pop()
            if n.get("kind") == "TemplateArgument":
                continue
            if n.get("kind") in ("RecordType", "EnumType") and isinstance(n.get("decl"), dict):
                tid, tkind = n["decl"].get("id"), n["kind"]
                break
            stack.extend(reversed(n.get("inner") or []))
        if tkind == "EnumType":
            return ("enum", None, errs)
        if tid is None:
            return ("error", f"`{qname}` does not name a record or enum", errs)
        same = [n for n in _iter_nodes(docs) if n.get("id") == tid and n.get("kind") in RECORD_KINDS]
        nodes = [n for n in same if n.get("completeDefinition")]
        if nodes:
            return ("record", nodes, errs)
        if not force and any(n.get("kind") == "ClassTemplateSpecializationDecl" for n in same):
            return ("uninstantiated", None, errs)
    if last_err:
        return ("error", last_err, errs)
    return ("missing", None, errs)


_TRAIT_CACHE = {}
_TRAIT_LOCK = threading.Lock()


def _final(ctx, W, state, names):
    """One TU: every successful member question re-stated, then (a) the SPELLING checks —
    each field's canonical text, re-spelled, must be the field's type (std::is_same) and
    each base's must be a base (std::is_base_of) — and (b) the trait questions about
    library names. Returns (props, spelling problems)."""
    ks = sorted({j.k for j in W.done_jobs if j.canon is not None})
    texts = ([state["access"][k] for k in ks] + [j.canon for j in W.done_jobs if j.canon]
             + [b[1] + " " + b[2] for b in W.bases] + list(names))
    lines = _head(texts)
    lines += [_rob_line(k, state["access"][k]) for k in ks]
    lines += ["namespace cq_guard {",
              "template <typename T, typename = void> struct complete : std::false_type {};",
              "template <typename T> struct complete<T, std::void_t<decltype(sizeof(T))>> : std::true_type {};",
              "template <typename B, typename T> struct derived : std::conjunction<complete<T>, "
              "std::is_class<T>, std::is_base_of<B, T>> {};",
              "}"]
    role = {}
    seen_k = set()
    for j in W.done_jobs:
        if j.canon is None or j.k in seen_k or not _spellable(j.canon):
            continue
        seen_k.add(j.k)
        lines.append(_check_line(j.k, f"std::is_same<::cq_guard_canon::box<{_spell(j.canon)}>, "
                                      f"::cq_guard_canon::c{j.k}>::value"))
        role[len(lines)] = ("spell", j)
    for b, (bpath, text, dq) in enumerate(W.bases):
        # The re-spelled base must BE the base: a base of `dq`, AND what the base's own
        # injected-class-name names when looked up THROUGH `dq` (bd 5ci2 / review r1 F-R1-6:
        # an anonymous-namespace or local-class base re-spelled as a same-named clean record
        # that is also a base passed `is_base_of` alone). Ambiguity is an error on this line.
        bshort = _split_scope(text)[-1].split("<")[0].strip() if text else ""
        cond = f"std::is_base_of<{_spell(text)}, {_spell(dq)}>::value"
        if re.match(r"^[A-Za-z_]\w*$", bshort):
            cond += f" && std::is_same<typename {_spell(dq)}::{bshort}, {_spell(text)}>::value"
        else:
            cond = "false"   # a base the check cannot name is not trusted
        lines.append(_check_line(1000000 + b, cond))
        role[len(lines)] = ("base", (bpath, text))
    names = sorted(names)
    for i, n in enumerate(names):
        T = _spell(n)
        for prop, expr in (("complete", f"cq_guard::complete<{T}>::value"),
                           ("enum", f"std::is_enum<{T}>::value"),
                           ("class", f"std::is_class<{T}>::value"),
                           ("union", f"std::is_union<{T}>::value"),
                           ("value", f"cq_guard::derived<llvm::Value, {T}>::value"),
                           ("vhbase", f"cq_guard::derived<llvm::ValueHandleBase, {T}>::value")):
            lines.append(f'static_assert(!{expr}, "CQPROP|{i}|{prop}");')
            role[len(lines)] = ("trait", n)
    tu = ctx.fresh("cq_guard_final")
    # a CANARY that always fails: a probe whose diagnostics do not include it did not run
    # (review r1 F-R1-11: a silent compiler must not read as "every answer is no")
    lines.append('static_assert(sizeof(char) == 0, "CQALIVE");')
    open(tu, "w").write("\n".join(lines) + "\n")
    r = _compile(ctx, tu, [], retry=False)
    if "CQALIVE" not in r.stderr:
        raise GuardError(f"the trait/spelling probe did not report its canary (rc {r.returncode}) — "
                         f"the compiler misbehaved; this gate fails closed")
    props = {n: set() for n in names}
    spell_bad, other = [], []
    for line in r.stderr.splitlines():
        m = re.search(r"CQPROP\|(\d+)\|(\w+)", line)
        if m:
            props[names[int(m.group(1))]].add(m.group(2))
            continue
        if "CQALIVE" in line:
            continue
        m = re.search(re.escape(os.path.basename(tu)) + r":(\d+):\d+: error: (.*)", line)
        if m:
            ro = role.get(int(m.group(1)))
            if ro and ro[0] == "spell":
                spell_bad.append(("field", ro[1].path, ro[1].canon))
            elif ro and ro[0] == "base":
                spell_bad.append(("base",) + tuple(ro[1]))
            else:
                other.append(line)
        elif " error: " in line or line.startswith("error:"):
            other.append(line)
    if other:
        raise GuardError("trait/spelling probe did not compile:\n  " + "\n  ".join(other[:8]))
    return props, sorted(set(spell_bad))


_INC_ANY = re.compile(r'^\s*#\s*include\s*([<"])([^>"]+)[>"]', re.M)
_MARKER = re.compile(r'^#\s+\d+\s+"((?:[^"\\]|\\.)*)"')


def _closure(tmp, start="TaintPropagation.h"):
    seen, stack = [], [start]
    while stack:
        f = stack.pop()
        if f in seen:
            continue
        seen.append(f)
        for q, name in _INC_ANY.findall(open(os.path.join(tmp, f), errors="ignore").read()):
            if q == '"' and os.path.isfile(os.path.join(tmp, name)):
                stack.append(name)
    return seen


def _guard_macro(text):
    lines = [l.strip() for l in _strip_comments(text).splitlines() if l.strip()]
    if len(lines) >= 2:
        m1 = re.match(r"^#\s*ifndef\s+(\w+)$", lines[0])
        m2 = re.match(r"^#\s*define\s+(\w+)$", lines[1])
        if m1 and m2 and m1.group(1) == m2.group(1):
            return m1.group(1)
    return None


def _preprocessed(ctx, text, stem, files):
    """-E `text` in the probe dir -> {file: [non-empty lines]} for the files in `files`."""
    tu = ctx.fresh(stem)
    open(tu, "w").write(text)
    r = _run(ctx.cfg.argv + ["-E", "-w", f"-I{ctx.tmp}", tu], ctx.cfg.cwd)
    if r.returncode != 0:
        raise GuardError("the include-order check could not preprocess:\n  "
                         + "\n  ".join(_first_errors(r.stderr, 4)))
    want = {os.path.realpath(os.path.join(ctx.tmp, f)): f for f in files}
    out, cur = {}, None
    for line in r.stdout.splitlines():
        m = _MARKER.match(line)
        if m:
            cur = want.get(os.path.realpath(m.group(1).encode().decode("unicode_escape")))
            continue
        if cur is not None and line.strip():
            out.setdefault(cur, []).append(" ".join(line.split()))
    return out


def _context_problem(ctx):
    """bd ngfa / review r1 F-R1-4: the probe TUs include `TaintPropagation.h` FIRST, while a
    real TU includes other headers before it — a member under `#ifdef <a macro another
    header defines>` exists in the build and not in the probe. Preprocess the header's
    include closure twice — alone (the probe's context) and after EVERY header any TU of this
    configuration includes plus every project header (the closure's include guards defined
    first and undefined just before, so it is really re-preprocessed in that context) — and
    refuse if any closure file's text differs. -> a problem string, or None."""
    files = _closure(ctx.tmp)
    guards = {}
    for f in files:
        g = _guard_macro(open(os.path.join(ctx.tmp, f), errors="ignore").read())
        if not g:
            return (f"`{f}` has no `#ifndef X / #define X` include guard, so the include-order "
                    f"check cannot re-preprocess it in the build's context (closed world: refused)")
        guards[f] = g
    incs, seen = [], set()
    for src in ctx.cfg.srcs:
        try:
            text = open(src, errors="ignore").read()
        except OSError:
            continue
        for q, name in _INC_ANY.findall(text):
            if q == '"' and not (os.path.isfile(os.path.join(ctx.tmp, name))
                                 or name.startswith(("llvm/", "llvm-c/"))):
                continue   # a TU-local header this probe dir cannot reach
            line = f'#include "{name}"' if q == '"' else f"#include <{name}>"
            if line not in seen:
                seen.add(line)
                incs.append(line)
    for f in sorted(os.listdir(ctx.tmp)):
        if f.endswith(".h") and f'#include "{f}"' not in seen:
            seen.add(f'#include "{f}"')
            incs.append(f'#include "{f}"')
    maxi = ("\n".join(f"#define {g}" for g in guards.values()) + "\n" + "\n".join(incs) + "\n"
            + "\n".join(f"#undef {g}" for g in guards.values()) + '\n#include "TaintPropagation.h"\n')
    with ThreadPoolExecutor(2) as ex:
        f_min = ex.submit(_preprocessed, ctx, '#include "TaintPropagation.h"\n', "cq_guard_ctxmin", files)
        f_max = ex.submit(_preprocessed, ctx, maxi, "cq_guard_ctxmax", files)
        lo, hi = f_min.result(), f_max.result()
    for f in files:
        a, b = lo.get(f), hi.get(f)
        if a == b:
            continue
        if a is None or b is None:
            return (f"`{f}` is not preprocessed in both contexts of the include-order check "
                    f"(closed world: refused)")
        i = next((k for k in range(min(len(a), len(b))) if a[k] != b[k]), min(len(a), len(b)))
        da = a[i] if i < len(a) else "<end>"
        db = b[i] if i < len(b) else "<end>"
        return (f"`{f}` preprocesses DIFFERENTLY after the headers this configuration's TUs "
                f"include (an include-order dependent member, e.g. under `#ifdef` of another "
                f"header's macro?) — first difference: alone `{da[:120]}` vs in context "
                f"`{db[:120]}` (closed world: refused)")
    return None


def _check_one(tmp, cfg, use_pch, allowlist, selftest_src):
    """One (configuration, PCH) pass -> (errors, members walked, tolerated notes)."""
    ctx = Ctx(tmp, cfg, use_pch)
    W = Walk(allowlist)
    state = {"rob_cache": {}, "next_k": 0, "access": {}, "lock": threading.Lock()}
    # the root, by the compiler's identity; a header that does not compile fails closed
    rootq = ROOT_RECORD
    kind, found, errs = _identify(ctx, rootq, 0, state=state)
    if errs:   # re-asked with no speculative line and (under the PCH) retried without it
        kind, found, errs = _identify(ctx, rootq, 0, retry=True)
    if errs:   # ANY error in the root TU: the header does not compile
        return (["the TaintSet header does not compile — refused (fail closed):\n    "
                 + "\n    ".join(errs)], 0, [])
    if kind != "record":
        return ([f"no complete `{rootq}` definition could be identified ({kind}: {found}) — refused"],
                0, [])
    if len(found) != 1:
        return ([f"expected exactly one complete `{rootq}` definition, found {len(found)}"], 0, [])
    W.cur_ident = rootq
    _walk_record(W, found[0], rootq, rootq, _decl_prefix(rootq), True)
    idx = 1
    while True:
        if W.jobs:
            jobs, W.jobs = W.jobs, []
            _rob(ctx, [j for j in jobs if j.prefix is not None], state)
            for j in jobs:
                W.mode, W.origin = j.mode, j.origin
                if j.canon is not None:
                    W.canonical = True
                    W.done_jobs.append(j)
                    W.field_top(j.path, parse_type(j.canon), j.top_level, j.name)
                else:
                    W.canonical = False
                    W.field_top(j.path, parse_type(j.fallback), j.top_level, j.name)
            W.mode, W.origin, W.canonical = "strict", None, True
        todo = [k for k in W.foreign if k not in W.foreign_done]
        if not todo and not W.jobs:
            break
        if todo:
            ids = list(range(idx, idx + len(todo)))
            idx += len(todo)
            # the same record reached in two modes is identified (and speculated) once
            uniq = sorted({q for q, _ in todo})
            with ThreadPoolExecutor(4) as ex:
                got = dict(zip(uniq, ex.map(lambda a: _identify(ctx, a[0], a[1], state=state)[:2],
                                            zip(uniq, range(idx, idx + len(uniq))))))
            idx += len(uniq)
            pimpl = sorted(q for q in uniq if got[q][0] == "uninstantiated")
            for q in pimpl:   # walk what the primary WOULD give too (a raw primary refuses twice)
                got[q] = ("pimpl",) + tuple(_identify(ctx, q, idx, force=True)[:2])
                idx += 1
            for qname, mode in todo:
                kind, found = got[qname][-2:] if got[qname][0] == "pimpl" else got[qname]
                W.foreign_done.add((qname, mode))
                path, origin = W.foreign[(qname, mode)]
                if got[qname][0] == "pimpl":
                    W._err_as(path, f"project class-template specialization `{qname}` is only "
                                    f"POINTED AT: the header never instantiates it, so a .cpp may "
                                    f"explicitly specialize it (a template pimpl) and the build would "
                                    f"use a body this walk cannot see — make it complete in the header "
                                    f"(hold it by value, or explicitly instantiate it there) (closed "
                                    f"world: refused)", "world", mode, origin)
                if kind == "enum":
                    continue
                if kind != "record":
                    W._err_as(path, f"project type `{qname}` is reached, but no complete definition "
                                    f"was found ({kind}{': ' + found if found else ''}) — refused",
                              "world", mode, origin)
                    continue
                W.mode, W.origin, W.canonical, W.cur_ident = mode, origin, True, qname
                for rec in found:
                    _walk_record(W, rec, qname, qname, _decl_prefix(qname), False)
                W.mode, W.origin = "strict", None
    with _SPEC_LOCK:   # speed only: what later passes may ask speculatively
        for j in W.done_jobs:
            if j.ident:
                _SPEC.setdefault(j.ident, set()).add((j.prefix, j.name))
    names = set(W.named_q) | set(W.pointee_q) | set(HANDLES)
    cache_key = (cfg.key, use_pch)
    with _TRAIT_LOCK:
        cached = {n: _TRAIT_CACHE[(cache_key, n)] for n in names if (cache_key, n) in _TRAIT_CACHE}
    try:
        props, spell_bad = _final(ctx, W, state, names - set(cached))
    except GuardError as ex:
        return ([str(ex)], W.members, W.tolerated)
    if use_pch:   # only under the PCH is completeness independent of the mutated header
        with _TRAIT_LOCK:
            for n, v in props.items():
                if _all_library(n):
                    _TRAIT_CACHE[(cache_key, n)] = v
    props.update(cached)
    for what, path, text in spell_bad:
        if what == "base":
            W.errs.append(f"{path}: the base's canonical spelling `{text}` does not name this "
                          f"record's base when re-spelled (an anonymous-namespace or local class "
                          f"re-spelled as a same-named record, or an AS-WRITTEN specialization?) — "
                          f"its identity cannot be trusted; closed world: refused")
        else:
            W.errs.append(f"{path}: the compiler's canonical spelling `{text}` does not denote this "
                          f"type when re-spelled (an explicit specialization prints its arguments "
                          f"AS WRITTEN?) — its identity cannot be trusted; closed world: refused")
    for h in HANDLES:
        if "vhbase" not in props.get(h, set()):
            W.errs.append(f"approved handle `{h}` is NOT derived from llvm::ValueHandleBase "
                          f"in this build — it is not a handle here; refused")
    for n, entries in W.pointee_q.items():
        p = props.get(n, set())
        for path, mode, origin in sorted(set(entries), key=str):
            if "value" in p:
                W._err_as(path, f"RAW POINTER to `{n}`, which derives from llvm::Value — use a "
                                f"scrub:: container or a value handle (WeakVH / WeakTrackingVH), or "
                                f"allowlist the qualified member with a reason", "ptr", mode, origin)
            elif "complete" not in p:
                W._err_as(path, f"pointer to INCOMPLETE type `{n}` — cannot prove it is not an "
                                f"llvm::Value (closed world: refused)", "ptr", mode, origin)
            elif not p & {"class", "union", "enum"}:
                # a pointee that is neither a class nor an enum means the walker misread the
                # type (bd ehni / review r1 F-R1-2: the next misparse fails CLOSED)
                W._err_as(path, f"pointer to `{n}`, which the compiler says is neither a class, a "
                                f"union nor an enum — the walker misread this type (closed world: "
                                f"refused)", "world", mode, origin)
            elif "enum" in p:
                continue
            elif "<" not in n and n not in APPROVED_POINTEES:
                W._err_as(path, f"pointer to LIBRARY record `{n}` — not derived from llvm::Value, "
                                f"but an object the walk cannot see into (a type-erased container "
                                f"base such as `llvm::SmallPtrSetImplBase`, an analysis result, ...); "
                                f"approve it in APPROVED_POINTEES with a reason, or change the type "
                                f"(closed world: refused)", "ptr", mode, origin)
    for n, uses in W.named_q.items():
        p = props.get(n, set())
        if "enum" in p:
            continue
        for path, via, mode, origin in sorted(set(uses), key=str):
            if "value" in p:
                W._err_as(path, f"`{n}` (derives from llvm::Value) held BY VALUE"
                                + (f" as a template argument of `{via}`" if via else "")
                                + " — the tell of an UNAPPROVED handle (e.g. AssertingVH is a bare "
                                  "pointer at LLVM_ENABLE_ABI_BREAKING_CHECKS=0); refused",
                          "ptr", mode, origin)
            elif "vhbase" in p:
                if mode == "key":
                    W.errs.append(f"{path}: a value HANDLE (`{n}`) in the KEY of `{origin[1] if origin else '?'}` "
                                  f"— a handle is nulled/retargeted IN PLACE, which breaks the "
                                  f"container's ordering/hash invariant; refused")
                else:
                    W._err_as(path, f"value handle `{n}` is not on the approved list "
                                    f"({', '.join(sorted(HANDLES))}) — held BY VALUE; refused",
                              "ptr", mode, origin)
            else:
                W._err_as(path, f"record type `{n}`"
                                + (f" (template argument of `{via}`)" if via else "")
                                + " is not a scalar, an approved handle/leaf, a scrub:: container "
                                  "or a project record — closed world: approve it in "
                                  "taintset_scrub_guard.py with a reason, or change the type",
                          "world", mode, origin)
    for a in allowlist:
        if a not in W.seen_paths:
            W.errs.append(f"stale allowlist entry `{a}`: no such member")
    st = _strip_comments(selftest_src)
    for path, nm, top in W.scrub_fields:
        pat = (r"\bT\." if top else r"\.") + re.escape(nm) + r"\b"
        if not re.search(pat, st):
            W.errs.append(f"self-cleaning member `{path}` is not exercised by "
                          f"ir-pass/tools/scrub_selftest.cpp (comments do not count)")
    if not W.errs and not use_pch:   # a clean verdict in the build's own context owes this too
        try:
            prob = _context_problem(ctx)
        except GuardError as ex:
            prob = f"{ex} — this gate FAILS CLOSED"
        if prob:
            W.errs.append(prob)
    return (sorted(set(W.errs)), W.members, sorted(set(W.tolerated)))


LAST_RUN = {}   # main()'s report: the passes run and the tolerated notes of the last check()


def check(header_src, selftest_src, allowlist, scrub_src=None, extra_headers=None):
    """-> (errors, members walked). Parses the given texts in a temp include dir with
    EVERY build configuration that compiles the header. Under USE_PCH each configuration
    is asked with a PCH first and every clean verdict is re-asked without it; without
    USE_PCH the configurations are asked (in parallel) without one. A problem in any
    pass refuses; each problem names the pass it came from unless it is the first."""
    try:
        cfgs = _configs()
    except GuardError as ex:
        return ([f"{ex} — this gate FAILS CLOSED, it never skips"], 0)
    tmp = tempfile.mkdtemp(prefix="cq_scrub_guard_")
    try:
        for f in os.listdir(INCLUDE_DIR):
            if f.endswith(".h"):
                shutil.copyfile(os.path.join(INCLUDE_DIR, f), os.path.join(tmp, f))
        open(os.path.join(tmp, "TaintPropagation.h"), "w").write(header_src)
        if scrub_src is not None:
            open(os.path.join(tmp, "ScrubOnDelete.h"), "w").write(scrub_src)
        for f, text in (extra_headers or {}).items():
            open(os.path.join(tmp, f), "w").write(text)

        def label(i, cfg, pch):
            return "" if i == 0 else f"[{cfg.label}{'' if pch else ', no PCH'}] "

        run_log, members, tolerated = [], 0, []
        try:
            if USE_PCH:
                passes = [(c, True) for c in cfgs] + [(c, False) for c in cfgs]
                for i, (cfg, pch) in enumerate(passes):
                    errs, n, tol = _check_one(tmp, cfg, pch, allowlist, selftest_src)
                    run_log.append((cfg.label, pch, len(errs)))
                    members, tolerated = max(members, n), tolerated or tol
                    if errs:
                        LAST_RUN.update(passes=run_log, tolerated=tolerated)
                        return ([label(i, cfg, pch) + e for e in errs], n)
            else:
                with ThreadPoolExecutor(len(cfgs)) as ex:
                    res = list(ex.map(lambda c: _check_one(tmp, c, False, allowlist, selftest_src), cfgs))
                for i, (cfg, (errs, n, tol)) in enumerate(zip(cfgs, res)):
                    run_log.append((cfg.label, False, len(errs)))
                    members, tolerated = max(members, n), tolerated or tol
                for i, (cfg, (errs, n, tol)) in enumerate(zip(cfgs, res)):
                    if errs:
                        LAST_RUN.update(passes=run_log, tolerated=tolerated)
                        return ([label(i, cfg, False) + e for e in errs], n)
        except GuardError as ex:
            return ([f"{ex} — this gate FAILS CLOSED, it never skips"], members)
        LAST_RUN.update(passes=run_log, tolerated=tolerated)
        return ([], members)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def _strip_comments(src):
    out, i, n = [], 0, len(src)
    while i < n:
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            out.append(" ")
        elif src[i] in "\"'":
            q, j = src[i], i + 1
            while j < n and src[j] != q:
                j += 2 if src[j] == "\\" else 1
            out.append(src[i:j + 1])
            i = j + 1
        else:
            out.append(src[i])
            i += 1
    return "".join(out)


# ----------------------------------------------------------------------------
# mutant self-test: all four Rule-13 fool corpora + the guard's own mutants
# ----------------------------------------------------------------------------
ANCH = "struct TaintSet {"
RAW = "RAW POINTER"
BYVAL = "held BY VALUE"
REC = "closed world"
COV = "not exercised"
STALE = "stale allowlist"
VOIDP = "TYPE-ERASED"
INTPTR = "uintptr_t/intptr_t"
IROWN = "IR-OWNED"
HKEY = "HANDLE"
NOCOMPILE = "does not compile"
SPELL = "canonical spelling"
NOREC = "no complete definition"


def _mutants(hdr, st, sc, loopplan):
    def ins(member, pre="", more=""):  # `more`: extra #include lines, in the include section
        assert hdr.count(ANCH) == 1
        h = hdr.replace("#include <set>\n", "#include <set>\n" + EXTRA_INCLUDES + more, 1)
        assert h != hdr, "include anchor missing"
        return h.replace(ANCH, pre + ANCH + "\n  " + member, 1)

    def ins_noextra(member, pre=""):   # the header's own include closure (no EXTRA_INCLUDES)
        return hdr.replace(ANCH, pre + ANCH + "\n  " + member, 1)

    def ins_global(member, pre):       # `pre` at GLOBAL scope, before `namespace cq {`
        h = hdr.replace("#include <set>\n", "#include <set>\n" + EXTRA_INCLUDES, 1)
        assert h.count("namespace cq {") >= 1
        return h.replace("namespace cq {", pre + "namespace cq {", 1).replace(ANCH, ANCH + "\n  " + member, 1)

    def after_taintset(h, text):       # `text` right after TaintSet's closing brace
        end = "SpineOpSet SpineOps;\n};"
        assert h.count(end) == 1, "TaintSet end anchor missing"
        return h.replace(end, end + "\n" + text, 1)

    LB = "struct LoopBreakRegion {"
    assert loopplan.count(LB) == 1

    def lb(member, more=""):           # a member added to the ALLOWLISTED LoopBreakRegion
        lp2 = loopplan.replace(LB, LB + "\n  " + member, 1)
        if more:
            anchor = '#include "llvm/ADT/DenseMap.h"\n'
            if anchor in lp2:
                lp2 = lp2.replace(anchor, anchor + more, 1)
            else:
                lp2 = lp2.replace(LB, more + LB, 1)
        return {"LoopPlan.h": lp2}
    RAWREC = "struct R2RawRec { llvm::Value *P = nullptr; };\n"
    RAWTMPL = "template <typename T> struct R2RawHolder { llvm::Value *P = nullptr; T X{}; };\n"
    AL = ALLOWLIST
    M = [("NULL: pristine tree", hdr, st, sc, AL, None),
         ("NULL: pristine + the mutants' extra includes", ins(""), st, sc, AL, None),
         ("NULL: a CLEAN project class template (T only) held by value",
          ins("R2CleanHolder<int> CH;", "template <typename T> struct R2CleanHolder { T X{}; unsigned N = 0; };\n"),
          st, sc, AL, None),
         ("NULL: a CLEAN NESTED TaintSet record held by an unqualified pointer",
          hdr.replace("llvm::SmallVector<CmpCondRead, 4> CmpCondReads;",
                      "llvm::SmallVector<CmpCondRead, 4> CmpCondReads;\n  CmpCondRead *CCRPtr = nullptr;", 1),
          st, sc, AL, None),
         ("NULL: a CLEAN project record held by pointer",
          ins("R2CleanRec *CRP = nullptr;", "struct R2CleanRec { unsigned N = 0; llvm::WeakVH H; };\n"),
          st, sc, AL, None),
         ("NULL: a bit-field member", ins("unsigned R3Bits : 3;"), st, sc, AL, None),
         ("NULL: a CLEAN explicit specialization (the primary holds a raw Value*; the one used does not)",
          ins("R4Sp<unsigned> R4S;", "template <typename T> struct R4Sp { llvm::Value *P = nullptr; };\n"
              "template <> struct R4Sp<unsigned> { unsigned X = 0; };\n"), st, sc, AL, None),
         ("NULL: a CLEAN global-namespace record held by pointer",
          ins_global("R4G *R4GP = nullptr;", "struct R4G { unsigned X = 0; };\n"), st, sc, AL, None),
         ("NULL: a CLEAN project enum by value and a PRIVATE clean member",
          ins("R4E E = R4E::A; R4Priv PV;", "enum class R4E { A, B };\nclass R4Priv { unsigned N = 0; };\n"),
          st, sc, AL, None),
         ("NULL: a CLEAN PRIVATE nested record type held by value (the spelling check is access-free)",
         ins("private:\n  struct R4PN { unsigned X = 0; };\n  R4PN PN;\n  public:"), st, sc, AL, None),
        ("NULL (by design, policy \"fields\"): a raw pointer FIELD added to the ALLOWLISTED LoopBreakRegion",
          hdr, st, sc, AL, None, lb("llvm::Value *R4ToleratedField = nullptr;")),
         ("NULL: a CLEAN project template instance held by value AND by pointer (instantiated by the header)",
          ins("R5T<int> R5TV; R5T<int> *R5TP = nullptr;", "template <class T> struct R5T { T X{}; };\n"),
          st, sc, AL, None),
         ("NULL: an #ifdef on a macro NO header defines (the include-order check stays quiet)",
          ins("#ifdef CQ_GUARD_R5_NEVER_DEFINED\n  llvm::Value *R5Never = nullptr;\n#endif"), st, sc, AL, None),
         ("RESIDUAL R1 pinned (bd gqda, review r1 A7): a by-value template a PROJECT header declares in namespace llvm",
          ins_global("llvm::RvEvilBox<int> RvBox;",
                     "namespace llvm { template <class T> struct RvEvilBox { std::set<llvm::Value *> S; }; }\n"),
          st, sc, AL, None),
         ("OUT OF SCOPE pinned (review r1 A8): type erasure through a BUILTIN pointer, std::set<const char *>",
          ins("std::set<const char *> RvCharIdx;"), st, sc, AL, None),
         ("CONFIG: a raw member under `#ifndef NDEBUG` is invisible in a Release build "
          "(the gate checks the CONFIGURED build)",
          ins("#ifndef NDEBUG\n  llvm::Value *DebugOnly = nullptr;\n#endif"), st, sc, AL, None)]
    # -- the guard's own mutants (incl. mutation-matrix M11)
    M += [
        ("self: raw SmallPtrSet member", ins("llvm::SmallPtrSet<llvm::Value *, 4> NewRaw;"), st, sc, AL, RAW),
        ("self: raw pointer field", ins("llvm::Value *Stray = nullptr;"), st, sc, AL, RAW),
        ("self: stale allowlist", hdr, st, sc, dict(AL, **{"cq::TaintSet::Gone": "x"}), STALE),
        ("self: allowlist keyed by a bare name does not exempt", hdr.replace(
            "llvm::WeakVH F;", "llvm::Function *F = nullptr;", 1), st, sc, dict(AL, F="x"), RAW),
        ("self: unexercised wrapped member", ins("ScrubPtrSet<llvm::Value *, 4> NewWrapped;"), st, sc, AL, COV),
        ("self: raw revert of Tainted", hdr.replace(
            "TaintedValueSet Tainted;", "std::set<llvm::Value *> Tainted;", 1), st, sc, AL, RAW),
        ("self: raw field in a nested record", hdr.replace(
            "struct CmpCondRead {", "struct CmpCondRead {\n    llvm::Instruction *RawRead = nullptr;", 1),
         st, sc, AL, RAW),
        ("self: foreign record list (not allowlisted)", ins("llvm::SmallVector<LoopBreakRegion, 2> OtherRegions;"),
         st, sc, AL, RAW),
        ("self/M11: TaintedValueSet retargeted to a raw std::set", hdr, st, sc.replace(
            "using TaintedValueSet = scrub::Set<std::set<llvm::Value *>, llvm::Value *>;",
            "using TaintedValueSet = std::set<llvm::Value *>;", 1), AL, RAW),
        ("self: ScrubMap retargeted to a raw DenseMap", hdr, st, sc.replace(
            "using ScrubMap = scrub::Map<KeyT, ValT>;",
            "using ScrubMap = llvm::DenseMap<KeyT, ValT>;", 1), AL, RAW),
        ("self: d88e's raw LiftedMergePhi::F restored (F-EB-1)", hdr.replace(
            "llvm::WeakVH F;", "llvm::Function *F = nullptr;", 1), st, sc, AL, RAW),
        ("self: AssertingVH for F (a bare pointer here)", ins(
            "llvm::AssertingVH<llvm::Function> FA;"), st, sc, AL, BYVAL),
        ("self: a header that does not compile fails closed", ins("this is not C++;"), st, sc, AL, NOCOMPILE),
    ]
    # -- r1A guard_bypass.py
    M += [
        ("r1A llvm::SmallSet<Value*>", ins("llvm::SmallSet<llvm::Value *, 4> X;"), st, sc, AL, RAW),
        ("r1A std::multiset<Value*>", ins("std::multiset<llvm::Value *> X;"), st, sc, AL, RAW),
        ("r1A std::array<Value*,4>", ins("std::array<llvm::Value *, 4> X;"), st, sc, AL, RAW),
        ("r1A std::optional<Value*>", ins("std::optional<llvm::Value *> X;"), st, sc, AL, RAW),
        ("r1A llvm::StringMap<Value*>", ins("llvm::StringMap<llvm::Value *> X;"), st, sc, AL, RAW),
        ("r1A std::pair<Value*,int> by value", ins("std::pair<llvm::Value *, int> X;"), st, sc, AL, RAW),
        ("r1A lowercase ptr typedef in container", ins("llvm::SmallPtrSet<vptr_t, 4> X;",
                                                       "using vptr_t = llvm::Value *;\n"), st, sc, AL, RAW),
        ("r1A template alias container", ins("PtrSetOf<llvm::Value> X;",
                                             "template <typename T> using PtrSetOf = llvm::SmallPtrSet<T *, 4>;\n"),
         st, sc, AL, RAW),
        ("r1A by-value foreign record", ins("LoopBreakRegion LastBreak;"), st, sc, AL, RAW),
        ("r1A default init with parens", ins("std::set<llvm::Value *> X = std::set<llvm::Value *>();"),
         st, sc, AL, RAW),
        ("r1A alignas member", ins("alignas(8) llvm::Value *Stray;"), st, sc, AL, RAW),
        ("r1A raw ptr, brace-init", ins("llvm::Value *Stray{nullptr};"), st, sc, AL, RAW),
        ("r1A brace-init raw DenseMap (X{})", ins("llvm::DenseMap<llvm::Value *, unsigned> X{};"), st, sc, AL, RAW),
        ("r1A brace-init raw SmallPtrSet (X{})", ins("llvm::SmallPtrSet<llvm::Instruction *, 4> X{};"), st, sc, AL, RAW),
        ("r1A unique_ptr to raw map", ins("std::unique_ptr<llvm::DenseMap<llvm::Value *, int>> X;"), st, sc, AL, RAW),
    ]
    # -- r1B guard_fool.py
    M += [
        ("r1B G1 brace-initialized std::set<Value*>", ins("std::set<llvm::Value *> NewRaw{};"), st, sc, AL, RAW),
        ("r1B G2 llvm::SmallSet<Value*,8>", ins("llvm::SmallSet<llvm::Value *, 8> NewRaw;"), st, sc, AL, RAW),
        ("r1B G3 alias declared outside TaintSet", ins("RawTbl NewRaw;", "using RawTbl = std::set<llvm::Value *>;\n"),
         st, sc, AL, RAW),
        ("r1B G4 typedef inside TaintSet", ins(
            "typedef llvm::DenseMap<llvm::Value *, unsigned> RawMap;\n  RawMap NewRaw;"), st, sc, AL, RAW),
        ("r1B G5 macro-spelled type", ins("CQ_RAW_SET NewRaw;", "#define CQ_RAW_SET std::set<llvm::Value *>\n"),
         st, sc, AL, RAW),
        ("r1B G6 parenthesised template arg", ins("llvm::SmallPtrSet<llvm::Value *, (4)> NewRaw;"), st, sc, AL, RAW),
        ("r1B G7 std::unordered_map<const Value*,..>", ins("std::unordered_map<const llvm::Value *, unsigned> NewRaw;"),
         st, sc, AL, RAW),
        ("r1B G8 SmallDenseMap", ins("llvm::SmallDenseMap<llvm::Value *, unsigned, 4> NewRaw;"), st, sc, AL, RAW),
        ("r1B G9 MapVector", ins("llvm::MapVector<llvm::Value *, unsigned> NewRaw;"), st, sc, AL, RAW),
        ("r1B G10 pointer in a pair KEY", ins("llvm::DenseSet<std::pair<llvm::Value *, unsigned>> NewRaw;"),
         st, sc, AL, RAW),
        ("r1B G11 std::array<Value*,4>", ins("std::array<llvm::Value *, 4> NewRaw;"), st, sc, AL, RAW),
        ("r1B G12 std::optional<Instruction*>", ins("std::optional<llvm::Instruction *> NewRaw;"), st, sc, AL, RAW),
        ("r1B G13 std::pair<Value*,unsigned> field", ins("std::pair<llvm::Value *, unsigned> NewRaw;"), st, sc, AL, RAW),
        ("r1B G14 StringMap<Value*>", ins("llvm::StringMap<llvm::Value *> NewRaw;"), st, sc, AL, RAW),
        ("r1B G15 nested record declared final", ins(
            "struct RawRec final { llvm::Value *P = nullptr; };\n  llvm::SmallVector<RawRec, 2> Recs;"), st, sc, AL, RAW),
        ("r1B G16 anonymous struct member", ins("struct { llvm::Value *P = nullptr; } Anon;"), st, sc, AL, RAW),
        ("r1B G17 union member", ins("union { llvm::Value *P; unsigned U; } Un;"), st, sc, AL, RAW),
        ("r1B G18 raw key, wrapped MAPPED type + a selftest mention", ins(
            "llvm::DenseMap<llvm::Value *, ScrubPtrSet<llvm::Value *, 4>> NewRaw;"), st + "\n// T.NewRaw\n", sc, AL, RAW),
        ("r1B G19 wrapped member 'exercised' by a COMMENT only", ins(
            "ScrubPtrSet<llvm::Value *, 4> NewWrapped;"), st + "\n// T.NewWrapped is exercised elsewhere\n", sc, AL, COV),
        ("r1B G20 foreign record held directly", ins("LoopBreakRegion OneRegion;"), st, sc, AL, RAW),
        ("r1B G21 decltype/paren default initializer", ins(
            "llvm::DenseMap<llvm::Value *, unsigned> NewRaw = decltype(NewRaw)();"), st, sc, AL, RAW),
        ("r1B G22 ScrubMap with a RAW MAPPED pointer (+ exercised)", ins(
            "ScrubMap<llvm::Value *, llvm::Instruction *> NewMap;"),
         st + '\nstatic void g22(cq::TaintSet &T) { (void)T.NewMap; }\n', sc, AL, RAW),
        ("r1B G23 class-scope alias shadowing ScrubPtrSet", ins(
            "template <typename P, unsigned N> using ScrubPtrSet = llvm::SmallPtrSet<P, N>;"), st, sc, AL, RAW),
        ("r1B G24 nested record with a BASE class carrying the pointer", ins(
            "struct RawRec2 : Base0 { unsigned K = 0; };\n  llvm::SmallVector<RawRec2, 2> Recs2;",
            "struct Base0 { llvm::Value *P = nullptr; };\n"), st, sc, AL, RAW),
        ("r1B G25 AssertingVH<Instruction> member", ins("llvm::AssertingVH<llvm::Instruction> AV;"), st, sc, AL, BYVAL),
        ("r1B G27 AssertingVH as a ScrubMap MAPPED value", ins(
            "ScrubMap<llvm::Value *, llvm::AssertingVH<llvm::Value>> AVMap;"),
         st + '\nstatic void g27(cq::TaintSet &T) { (void)T.AVMap; }\n', sc, AL, BYVAL),
    ]
    # -- r2 delta guard_fool_r2.py (A1-A11; A12 was caught already)
    M += [
        ("r2 A1 project CLASS TEMPLATE holding a raw Value*, instantiated <int>",
         ins("R2RawHolder<int> R2H;", RAWTMPL), st, sc, AL, RAW),
        ("r2 A2 SmallVector of a project class template spec",
         ins("llvm::SmallVector<R2RawHolder<unsigned>, 2> R2HV;", RAWTMPL), st, sc, AL, RAW),
        ("r2 A3 type-erased identity set SmallPtrSet<const void *>",
         ins("llvm::SmallPtrSet<const void *, 8> R2Seen;"), st, sc, AL, VOIDP),
        ("r2 A4 uintptr_t-keyed DenseMap", ins("llvm::DenseMap<std::uintptr_t, unsigned> R2ByAddr;"),
         st, sc, AL, INTPTR),
        ("r2 A5 #ifdef NDEBUG raw member (the Release build defines NDEBUG)",
         ins("#ifdef NDEBUG\n  llvm::Value *R2RelOnly = nullptr;\n#endif"), st, sc, AL, RAW),
        ("r2 A6 vector of POINTERS to a project record holding raw Value*",
         ins("llvm::SmallVector<R2RawRec *, 2> R2RecPtrs;", RAWREC), st, sc, AL, RAW),
        ("r2 A7 ScrubMap MAPPED pointer to a project record holding raw Value*",
         ins("ScrubMap<llvm::Value *, R2RawRec *> R2MapRec;", RAWREC),
         st + "\nstatic void r2a7(cq::TaintSet &T) { (void)T.R2MapRec; }\n", sc, AL, RAW),
        ("r2 A8 std::shared_ptr<void>", ins("std::shared_ptr<void> R2Opaque;"), st, sc, AL, VOIDP),
        ("r2 A9 DenseMap<llvm::Loop *, unsigned>", ins("llvm::DenseMap<llvm::Loop *, unsigned> R2LoopKey;"),
         st, sc, AL, IROWN),
        ("r2 A10 SmallVector<llvm::Use *>", ins("llvm::SmallVector<llvm::Use *, 4> R2Uses;"), st, sc, AL, IROWN),
        ("r2 A11 std::set<llvm::WeakVH> (a handle as an ORDERED key)", ins("std::set<llvm::WeakVH> R2WSet;"),
         st, sc, AL, HKEY),
        ("r2 A12 raw ptr behind `using` in another header, by value",
         ins("R2Alias R2AliasMember;", "using R2Alias = llvm::SmallPtrSet<llvm::Instruction *, 4>;\n"), st, sc, AL, RAW),
    ]
    # -- r3 guard_fool_r3.py / guard_fool_r3b.py (bd wop9 / 7gri / jk56) + this fix's own
    R3KEY = ("struct R3Key { llvm::WeakVH H; bool operator<(const R3Key &O) const {"
             " return static_cast<llvm::Value *>(H) < static_cast<llvm::Value *>(O.H); } };\n")
    M += [
        ("r3 B1 explicit FULL specialization of a project class template holds a raw Value*",
         ins("R3Spec<unsigned> R3S;", "template <typename T> struct R3Spec { T X{}; };\n"
             "template <> struct R3Spec<unsigned> { llvm::Value *P = nullptr; };\n"), st, sc, AL, RAW),
        ("r3 B2 PARTIAL specialization of a project class template holds a raw Value*",
         ins("R3PS<int *> R3P;", "template <typename T> struct R3PS { T X{}; };\n"
             "template <typename T> struct R3PS<T *> { llvm::Value *P = nullptr; };\n"), st, sc, AL, RAW),
        ("r3 B2b full specialization selected only under NDEBUG (Release) via a constexpr flag",
         ins("R3N<kR3Rel> R3NM;", "#ifdef NDEBUG\nconstexpr bool kR3Rel = true;\n#else\nconstexpr bool kR3Rel = false;\n"
             "#endif\ntemplate <bool B> struct R3N { unsigned X = 0; };\n"
             "template <> struct R3N<true> { llvm::SmallPtrSet<llvm::Value *, 4> Raw; };\n"), st, sc, AL, RAW),
        ("r3 B3 raw member present in cq-opt's build but not in CQPass's (#ifndef CQPass_EXPORTS)",
         ins("#ifndef CQPass_EXPORTS\n  llvm::Value *R3NotPlugin = nullptr;\n#endif"), st, sc, AL, RAW),
        ("r3 B3' raw member present in CQPass's build only (#ifdef CQPass_EXPORTS)",
         ins("#ifdef CQPass_EXPORTS\n  llvm::Value *R3PluginOnly = nullptr;\n#endif"), st, sc, AL, RAW),
        ("r3 B4 raw member hidden by the PCH context (#ifndef LLVM_ANALYSIS_LOOPINFO_H)",
         ins_noextra("#ifndef LLVM_ANALYSIS_LOOPINFO_H\n  llvm::Value *R3PchCtx = nullptr;\n#endif"),
         st, sc, AL, RAW),
        ("r3 B7 value handle wrapped in a project record, as an ordered std::set KEY",
         ins("std::set<R3Key> R3KS;", R3KEY), st, sc, AL, HKEY),
        ("r3 B7' the same record as a DenseMap KEY through a std::pair",
         ins("std::map<std::pair<R3Key, int>, unsigned> R3KM;", R3KEY), st, sc, AL, HKEY),
        ("r3 B8 unqualified pointer to an ALIAS whose short name is also a clean record's",
         ins("R3Rec *R3AP = nullptr;", "namespace r3other { struct R3Rec { unsigned X = 0; }; }\n"
             "struct R3RawRec2 { llvm::Value *P = nullptr; };\nusing R3Rec = R3RawRec2;\n"), st, sc, AL, RAW),
        ("r3 B8/Result alias named like LLVM's PassManager `Result`, no decoy",
         ins("Result *R3AP = nullptr;", "struct R3RawRec3 { llvm::Value *P = nullptr; };\nusing Result = R3RawRec3;\n"),
         st, sc, AL, RAW),
        ("r3 B8/Impl alias named like LLVM's Bitfields `Impl`, no decoy",
         ins("Impl *R3AP = nullptr;", "struct R3RawRec4 { llvm::Value *P = nullptr; };\nusing Impl = R3RawRec4;\n"),
         st, sc, AL, RAW),
        ("r3 B14 raw identity table added to the ALLOWLISTED LoopBreakRegion (LoopPlan.h)",
         hdr, st, sc, AL, RAW, lb("llvm::SmallPtrSet<llvm::Value *, 4> R3IdentityTable;")),
        ("r3 B14' a handle-keyed set added to the ALLOWLISTED LoopBreakRegion",
         hdr, st, sc, AL, HKEY, lb("std::set<llvm::WeakVH> R4HandleKeys;")),
        ("r3 B14'' a Loop*-keyed map added to the ALLOWLISTED LoopBreakRegion",
         hdr, st, sc, AL, IROWN, lb("llvm::DenseMap<llvm::Loop *, unsigned> R4LoopKeys;")),
        ("r3 C1 raw POINTER to a library container of raw Value*: std::set<llvm::Value *> *",
         ins("std::set<llvm::Value *> *R3SetPtr = nullptr;"), st, sc, AL, RAW),
        ("r3 C2 raw POINTER to llvm::DenseMap<llvm::Value *, unsigned>",
         ins("llvm::DenseMap<llvm::Value *, unsigned> *R3MapPtr = nullptr;"), st, sc, AL, RAW),
        ("r3 C3 raw POINTER to llvm::SmallPtrSet<llvm::Instruction *, 4>",
         ins("llvm::SmallPtrSet<llvm::Instruction *, 4> *R3SPSPtr = nullptr;"), st, sc, AL, RAW),
        ("r3 C4 pointer to a GLOBAL-namespace record holding a raw Value*",
         ins_global("R3G *R3GP = nullptr;", "struct R3G { llvm::Value *P = nullptr; };\n"), st, sc, AL, RAW),
        ("r3 C4b the same GLOBAL record held BY VALUE",
         ins_global("R3G R3GV;", "struct R3G { llvm::Value *P = nullptr; };\n"), st, sc, AL, RAW),
        ("r3 C5 pointer to a record in a NON-cq project namespace holding a raw Value*",
         ins_global("cqx::R3X *R3XP = nullptr;", "namespace cqx { struct R3X { llvm::Value *P = nullptr; }; }\n"),
         st, sc, AL, RAW),
        ("r3 C6 SmallVector of POINTERS to a raw library table",
         ins("llvm::SmallVector<llvm::DenseSet<llvm::Value *> *, 2> R3VecOfTblPtr;"), st, sc, AL, RAW),
        ("new: a NON-cq project class TEMPLATE by value (library-template trust was by namespace)",
         ins_global("cqx::R4H<int> R4HM;", "namespace cqx { template <class T> struct R4H { llvm::Value *P; T X; }; }\n"),
         st, sc, AL, RAW),
        ("new: pointer to an ALIAS TEMPLATE instance of a raw project template",
         ins("R4Hold<int> *R4HP = nullptr;", RAWTMPL + "template <class T> using R4Hold = R2RawHolder<T>;\n"),
         st, sc, AL, RAW),
        ("new: raw pointer in a record in an INLINE namespace, behind a same-short-name decoy",
         ins("R4Raw *R4IP = nullptr;", "inline namespace r4v1 { struct R4Raw { llvm::Value *P = nullptr; }; }\n"
             "namespace r4decoy { struct R4Raw { unsigned X = 0; }; }\n"), st, sc, AL, RAW),
        ("new: a PRIVATE nested record type with a raw field, held by value",
         ins("private:\n  struct R4PR { llvm::Value *P = nullptr; };\n  R4PR PRR;\n  public:"), st, sc, AL, RAW),
        ("new: a PRIVATE raw member of a project record held by value",
         ins("R4PrivRaw PR;", "class R4PrivRaw { llvm::Value *Hidden = nullptr; public: unsigned N = 0; };\n"),
         st, sc, AL, RAW),
        ("new: a raw REFERENCE member", ins("llvm::Value &R4Ref;"), st, sc, AL, RAW),
        ("new: a raw pointer in an ANONYMOUS union member", ins("union { llvm::Value *R4U1; unsigned R4U2; };"),
         st, sc, AL, RAW),
        ("new: an explicit specialization whose AS-WRITTEN argument re-spells as a clean decoy",
         ins_global("R4S<R4Alias *> R4SM;", "struct R4Alias { unsigned X = 0; };\n").replace(
             ANCH, "struct R4Raw2 { unsigned Y = 0; };\nusing R4Alias = R4Raw2;\n"
                   "template <class T> struct R4S { unsigned Z = 0; };\n"
                   "template <> struct R4S<R4Alias *> { llvm::Value *P = nullptr; };\n" + ANCH, 1),
         st, sc, AL, SPELL),
        ("new: a macro defined AFTER TaintSet renames a raw member to a scrub member",
         after_taintset(ins("llvm::Value *R4Evil = nullptr;"), "#define R4Evil Tainted"),
         st, sc, AL, RAW),
        ("new: many project template INSTANCES identified in one round, one raw",
         ins("R4C<1> C1; R4C<2> C2; R4C<3> C3; R4D<4> D4; R4C<5> C5; R4C<6> C6;",
             "template <int N> struct R4C { unsigned X = N; };\n"
             "template <int N> struct R4D { llvm::Value *P = nullptr; };\n"), st, sc, AL, RAW),
        ("new: a member VARIABLE TEMPLATE", ins("template <class T> static inline T R4VT{};"), st, sc, AL, REC),
        ("new: a pointer-to-member", ins("int LoopBreakRegion::*R4MP = nullptr;"), st, sc, AL, REC),
        ("new: pointer to a FORWARD-DECLARED project record", ins("R4Fwd *R4FP = nullptr;", "struct R4Fwd;\n"),
         st, sc, AL, NOREC),
        ("new: a handle behind a pointer in a KEY record (RESIDUAL R6, conservative)",
         ins("std::set<R4KP> R4KPS;", "struct R4KH { llvm::WeakVH H; };\nstruct R4KP { R4KH *P = nullptr; "
             "bool operator<(const R4KP &O) const { return P < O.P; } };\n"), st, sc, AL, HKEY),
    ]
    # -- review r1 of this rewrite (guard_fool_r1.py / rv_mutations.py; bd hdxo ehni ofvm ngfa
    #    5ci2 s6ma) + this round's own variants
    RVSTORE = "struct RvStore : std::set<llvm::Value *> { std::set<llvm::Value *> Hidden; };\n"
    st_rv = st + "\nstatic void rv_touch(cq::TaintSet &T) { (void)T.RvScrubbed.size(); }\n"
    M += [
        ("r1 C1 unnamed struct DEFINED INSIDE TaintSet holding std::set<Value*>",
         ins("struct { std::set<llvm::Value *> T; } RvIn;"), st, sc, AL, RAW),
        ("r1 C2 const llvm::Value ** (innermost pointee)", ins("const llvm::Value **RvSlots2 = nullptr;"),
         st, sc, AL, RAW),
        ("r1 C3 static std::set<llvm::Value *> member", ins("static inline std::set<llvm::Value *> RvOrderIdx0;"),
         st, sc, AL, RAW),
        ("r1 C4 explicit specialization IN THE HEADER of a pointed-at template",
         ins("RvImpl<int> *RvP0 = nullptr;", "template <class T> struct RvImpl { int Clean = 0; };\n"
             "template <> struct RvImpl<int> { std::set<llvm::Value *> T; };\n"), st, sc, AL, RAW),
        ("r1 A1 unnamed struct type DEFINED OUTSIDE TaintSet, held by value via decltype (bd hdxo)",
         ins("decltype(RvHolder::U) RvAnon;", "struct RvHolder { struct { std::set<llvm::Value *> T; } U; };\n"),
         st, sc, AL, "defined outside the record"),
        ("r1 A1b a global unnamed struct via an alias, as a STATIC member (bd hdxo)",
         ins_global("static inline RvAnonT RvAnonS;",
                    "inline struct { std::set<llvm::Value *> T; } RvGlobalAnon;\n").replace(
             ANCH, "using RvAnonT = decltype(::RvGlobalAnon);\n" + ANCH, 1),
         st, sc, AL, "defined outside the record"),
        ("r1 A2 const llvm::Value *const * (cv on the inner pointer, bd ehni)",
         ins("const llvm::Value *const *RvSlots = nullptr; unsigned RvNumSlots = 0;"), st, sc, AL, RAW),
        ("r1 A2b llvm::Value *volatile * inside a SmallVector (bd ehni)",
         ins("llvm::SmallVector<llvm::Value *volatile *, 2> RvVSlots;"), st, sc, AL, RAW),
        ("r1 A2' a CONST raw pointer member, llvm::Value *const", ins("llvm::Value *const RvCP = nullptr;"),
         st, sc, AL, RAW),
        ("r1 A2'' llvm::Value *__restrict * (restrict on the inner pointer)",
         ins("llvm::Value *__restrict *RvRP = nullptr;"), st, sc, AL, RAW),
        ("r1 A3 template PIMPL: a clean primary only POINTED AT (a .cpp may specialize it, bd ngfa)",
         ins("RvImpl<int> *RvP = nullptr;", "template <class T> struct RvImpl { int Clean = 0; };\n"),
         st, sc, AL, "only POINTED AT"),
        ("r1 A3' the same pimpl through std::unique_ptr (no completeness required, bd ngfa)",
         ins("std::unique_ptr<RvImpl<int>> RvU;", "template <class T> struct RvImpl { int Clean = 0; };\n"),
         st, sc, AL, "only POINTED AT"),
        ("r1 A4 a base re-spelled through an ANONYMOUS NAMESPACE (bd 5ci2)",
         ins("RvMid RvM;", "struct RvB { int Clean = 0; };\n"
             "namespace { struct RvB { std::set<llvm::Value *> T; }; struct RvMid : RvB, ::cq::RvB {}; }\n"),
         st, sc, AL, "base's canonical spelling"),
        ("r1 A4' a SINGLE anonymous-namespace base shadowed by a clean same-named record (bd 5ci2)",
         ins("RvMid3 RvM3;", "struct RvB3 { int Clean = 0; };\n"
             "namespace { struct RvB3 { std::set<llvm::Value *> T; }; struct RvMid3 : RvB3 {}; }\n"),
         st, sc, AL, "base's canonical spelling"),
        ("r1 A4b a LOCAL class base re-spelled as a same-named global base (bd 5ci2)",
         ins_global("::RvMid2 RvM2;", "struct RvL { int Clean = 0; };\n"
                    "inline auto rvMake() { struct RvL { std::set<llvm::Value *> T; }; return RvL{}; }\n"
                    "struct RvMid2 : decltype(rvMake()), RvL {};\n"),
         st, sc, AL, "base's canonical spelling"),
        ("r1 A4b' a LOCAL class base that DERIVES from the same-named clean record (single base, bd 5ci2)",
         ins_global("::RvMid4 RvM4;", "struct RvL4 { int Clean = 0; };\n"
                    "inline auto rvMake4() { struct RvL4 : ::RvL4 { std::set<llvm::Value *> T; }; "
                    "return RvL4{}; }\n"
                    "struct RvMid4 : decltype(rvMake4()) {};\n"),
         st, sc, AL, "base's canonical spelling"),
        ("r1 A5 INCLUDE ORDER: a raw table under #ifdef of a header real TUs include first (bd ngfa)",
         ins("\n#ifdef CQ_IRPASS_CQ_LOWERING_PASS_H_\n  static inline std::set<llvm::Value *> RvOrderIdx;\n#endif\n"),
         st, sc, AL, "preprocesses DIFFERENTLY"),
        ("r1 A5' INCLUDE ORDER through an LLVM header only a .cpp includes (#ifdef LLVM_ANALYSIS_LAZYVALUEINFO_H)",
         ins("#ifdef LLVM_ANALYSIS_LAZYVALUEINFO_H\n  std::set<llvm::Value *> RvLviCtx;\n#endif"),
         st, sc, AL, "preprocesses DIFFERENTLY"),
        ("r1 A5'' a member under #ifdef of an LLVM header the PCH holds (refused by the PCH pass itself)",
         ins_noextra("#ifdef LLVM_ANALYSIS_LOOPINFO_H\n  std::set<llvm::Value *> RvLoopCtx;\n#endif"),
         st, sc, AL, RAW),
        ("r1 A6 llvm::EquivalenceClasses<llvm::Value *> in the ALLOWLISTED LoopBreakRegion (F-R1-9)",
         hdr, st, sc, AL, RAW,
         lb("llvm::EquivalenceClasses<llvm::Value *> RvEq;", '#include "llvm/ADT/EquivalenceClasses.h"\n')),
        ("r1 A6b llvm::UniqueVector<llvm::Value *> in the ALLOWLISTED LoopBreakRegion (F-R1-9)",
         hdr, st, sc, AL, RAW,
         lb("llvm::UniqueVector<llvm::Value *> RvUV;", '#include "llvm/ADT/UniqueVector.h"\n')),
        ("r1 A6' a raw pointer SEQUENCE in the ALLOWLISTED LoopBreakRegion (was RESIDUAL R2)",
         hdr, st, sc, AL, RAW, lb("llvm::SmallVector<llvm::Value *, 4> RvList;")),
        ("r1 A9 scrub::Set<StorageT, P> whose StorageT is a project record with a raw table (bd ofvm)",
         ins("scrub::Set<RvStore, llvm::Value *> RvScrubbed;", RVSTORE), st_rv, sc, AL,
         "trusted by name"),
        ("r1 C5 the same RvStore as a plain FIELD", ins("RvStore RvStoreField;", RVSTORE), st, sc, AL, RAW),
        ("r1 A10 llvm::SmallPtrSetImplBase * (a type-erased library base, F-R1-8)",
         ins("llvm::SmallPtrSetImplBase *RvErased = nullptr;"), st, sc, AL, "APPROVED_POINTEES"),
        ("r1 A10' llvm::SmallVectorBase<unsigned> * (a type-erased library TEMPLATE base)",
         ins("llvm::SmallVectorBase<unsigned> *RvErasedT = nullptr;"), st, sc, AL, VOIDP),
        ("r1 K1 KEY record whose BASE holds a WeakVH",
         ins("std::set<RvKD> RvKS;", "struct RvKB { llvm::WeakVH H; };\n"
             "struct RvKD : RvKB { bool operator<(const RvKD &O) const { return this < &O; } };\n"),
         st, sc, AL, HKEY),
        ("r1 K2 KEY std::tuple<WeakVH, int>",
         ins("std::set<std::tuple<llvm::WeakVH, int>> RvKT;", more="#include <tuple>\n"), st, sc, AL, HKEY),
        ("r1 K3 KEY std::variant<int, WeakVH> of a std::map",
         ins("std::map<std::variant<int, llvm::WeakVH>, int> RvKV;", more="#include <variant>\n"),
         st, sc, AL, HKEY),
    ]
    # -- extra spellings
    M += [
        ("new: static data member", ins("static inline llvm::Value *Global = nullptr;"), st, sc, AL, RAW),
        ("new: Value** double pointer", ins("llvm::Value **PP = nullptr;"), st, sc, AL, RAW),
        ("new: C array of raw pointers", ins("llvm::Instruction *Arr[4] = {};"), st, sc, AL, RAW),
        ("new: unknown non-template record", ins("llvm::APInt Big;"), st, sc, AL, REC),
        ("new: project template reached only by POINTER", ins("R2RawHolder<int> *R2HP = nullptr;", RAWTMPL),
         st, sc, AL, RAW),
        ("new: pair<WeakVH,int> as a DenseSet KEY", ins("llvm::DenseSet<std::pair<llvm::WeakVH, int>> R2PK;"),
         st, sc, AL, HKEY),
        ("new: project record written UNQUALIFIED, held by pointer",
         ins("R2RawRec *RRP = nullptr;", RAWREC), st, sc, AL, RAW),
        ("new: NESTED TaintSet record with a raw field, held by an unqualified pointer",
         hdr.replace("llvm::SmallVector<CmpCondRead, 4> CmpCondReads;",
                     "llvm::SmallVector<CmpCondRead, 4> CmpCondReads;\n  struct R2NRaw { llvm::Value *P = nullptr; };\n"
                     "  R2NRaw *NRawPtr = nullptr;", 1), st, sc, AL, RAW),
    ]
    return M


def _db_cases():
    """Fail-closed cases of the CONFIGURATION layer (review r1 F-R1-7 + the earlier ones):
    each database must make `_configs_from` raise; the intact one must not. Pure Python, no
    compile. -> [(label, ok, detail)]"""
    db = _load_db(COMPILE_COMMANDS)
    root = os.path.realpath(ROOT)
    other = os.path.join(os.path.dirname(root), "cq_guard_no_such_tree")

    def mal(e):   # the cq-opt configuration's entries lose their command
        t = e.get("output") or e.get("command") or ""
        if "cq-opt" in t or "cq-scrub-selftest" in t:
            e = {k: v for k, v in e.items() if k != "command"}
            e["arguments"] = []
        return e
    cases = [
        ("DB control: the intact database (2+ configurations)", db, False),
        ("DB F1: MALFORMED entries of ONE configuration (review r1 F-R1-7)", [mal(dict(e)) for e in db], True),
        ("DB: an entry without `file`", db + [{"directory": root, "command": "c++ -c x.cpp"}], True),
        ("DB: a database of ANOTHER tree", [dict(e, file=e["file"].replace(root, other),
                                                 directory=e["directory"].replace(root, other),
                                                 command=e.get("command", "").replace(root, other))
                                            for e in db], True),
        ("DB: not a list of commands", {"a": 1}, True),
    ]
    out = []
    for label, d, expect_err in cases:
        try:
            if not isinstance(d, list):
                raise GuardError("not a JSON list of commands")
            got = _configs_from(d, "<selftest db>")
            ok, detail = (not expect_err and len(got) >= 2), f"{len(got)} configuration(s)"
        except GuardError as ex:
            ok, detail = expect_err, str(ex).splitlines()[0][:160]
        out.append((label, ok, detail))
    return out


def _shards(entries, n):
    """-> {label: shard index 0..n-1}, deterministic and BALANCED: the expected-clean
    entries (the costly ones — every pass, the no-PCH re-ask and the include-order check)
    round-robin by label first, starting at shard 2 because shard 1 also runs the PCH
    equivalence control; then the mutants, continuing the rotation. (A label-hash split
    measured 754 / 395 / 458 s under load: shard 1 drew the nulls.)"""
    nulls = sorted(m[0] for m in entries if m[5] is None)
    muts = sorted(m[0] for m in entries if m[5] is not None)
    return {l: (i + 1) % n for i, l in enumerate(nulls + muts)}


def selftest(jobs=None, shard=(1, 1)):
    """The guard's own mutant validation. `shard` = (k, n): run only the k-th of n balanced
    slices of the entries (`_shards`; the configuration and PCH-equivalence controls run in
    shard 1), so the corpus can be split across ctest entries; `jobs` bounds the compilers
    in flight."""
    jobs = jobs or JOBS
    k, n = shard
    hdr = open(HEADER).read()
    st = open(SELFTEST).read()
    sc = open(SCRUB_HDR).read()
    lp = open(os.path.join(INCLUDE_DIR, "LoopPlan.h")).read()
    global USE_PCH
    bad = []
    cfgs = _configs()
    if k == 1:
        for label, ok, detail in _db_cases():
            print(f"  {'ok ' if ok else 'BAD'} {label}: {detail}", flush=True)
            if not ok:
                bad.append(label)
        # PCH EQUIVALENCE CONTROL: the pristine answer must not depend on the PCH.
        saved = USE_PCH
        USE_PCH = False
        no_pch = check(hdr, st, ALLOWLIST, sc)
        USE_PCH = saved
        with_pch = check(hdr, st, ALLOWLIST, sc)
        pch_ok = (no_pch == with_pch) and not no_pch[0]
        print(f"  {'ok ' if pch_ok else 'BAD'} PCH equivalence control: without PCH {no_pch[1]} members / "
              f"{len(no_pch[0])} problems, with PCH {with_pch[1]} / {len(with_pch[0])} "
              f"(PCH {_PCH['state']}; {len(cfgs)} configurations: {', '.join(c.label for c in cfgs)})",
              flush=True)
        for e in no_pch[0][:3]:
            print("        " + e.splitlines()[0][:200])
        if not pch_ok:
            bad.append("PCH equivalence control")
    every = _mutants(hdr, st, sc, lp)
    labels = [m[0] for m in every]
    dup = sorted({l for l in labels if labels.count(l) > 1})
    if dup:   # the shard key is the label: two entries with one label would share a fate
        print(f"  BAD duplicate mutant labels: {dup}")
        bad.append("duplicate labels")
    assign = _shards(every, n)
    muts = [m for m in every if assign[m[0]] == k - 1]
    if not muts:
        print(f"  BAD shard {k}/{n} selected no mutant — a vacuous shard is a failure")
        bad.append("empty shard")

    def run(m):
        label, h, s, x, al, expect = m[:6]
        extra = m[6] if len(m) > 6 else None
        errs, n_ = check(h, s, al, x, extra_headers=extra)
        return label, expect, errs, n_

    with ThreadPoolExecutor(jobs) as ex:   # each verdict is printed as it completes
        for fut in as_completed([ex.submit(run, m) for m in muts]):
            label, expect, errs, nmem = fut.result()
            if expect is None:
                ok = not errs
                verdict = "clean" if ok else "PROBLEMS"
            else:
                hit = [e for e in errs if expect in e]
                ok = bool(hit)
                verdict = "KILLED (right reason)" if ok else (
                    "KILLED FOR THE WRONG REASON" if errs else "MISSED")
            print(f"  {'ok ' if ok else 'BAD'} {verdict:28s} {label}   [{nmem} members]", flush=True)
            if not ok:
                bad.append(label)
                for e in errs[:3]:
                    print("        " + e.splitlines()[0][:200], flush=True)
    nm = sum(1 for m in muts if m[5] is not None)
    extra_ctl = (len(_db_cases()) + 1) if k == 1 else 0
    print(f"taintset_scrub_guard selftest shard {k}/{n} (--jobs {jobs}): {len(muts) - nm + extra_ctl} "
          f"null/configuration/equivalence controls, {nm} mutants (of {len(every)} entries in all "
          f"shards), {len(bad)} failed")
    return 1 if bad else 0


def main():
    global COMPILE_COMMANDS, USE_PCH
    args = sys.argv[1:]
    i, shard = 0, (1, 1)
    while i < len(args):  # unknown arguments are refused, never ignored
        if args[i] == "--compile-commands" and i + 1 < len(args):
            COMPILE_COMMANDS = args[i + 1]
            i += 2
        elif args[i] == "--jobs" and i + 1 < len(args) and args[i + 1].isdigit() and int(args[i + 1]) > 0:
            set_jobs(int(args[i + 1]))
            i += 2
        elif (args[i] == "--shard" and i + 1 < len(args)
              and re.match(r"^[1-9]\d*/[1-9]\d*$", args[i + 1])):
            k, n = (int(x) for x in args[i + 1].split("/"))
            if k > n:
                print(f"taintset_scrub_guard: bad --shard {args[i + 1]}", file=sys.stderr)
                return 2
            shard = (k, n)
            i += 2
        elif args[i] in ("--no-pch", "--selftest"):
            i += 1
        else:
            print(f"taintset_scrub_guard: unknown argument `{args[i]}`", file=sys.stderr)
            return 2
    if "--no-pch" in args:
        USE_PCH = False
    if shard != (1, 1) and "--selftest" not in args:
        print("taintset_scrub_guard: --shard only applies to --selftest", file=sys.stderr)
        return 2
    try:
        if "--selftest" in args:
            return selftest(shard=shard)
        USE_PCH = False   # the gate's own verdict is asked WITHOUT a PCH (bd 7gri (b))
        errs, n = check(open(HEADER).read(), open(SELFTEST).read(), ALLOWLIST, open(SCRUB_HDR).read())
        for e in errs:
            print("taintset_scrub_guard: " + e)
        for t in LAST_RUN.get("tolerated", []):
            print("taintset_scrub_guard: note (allowlisted, RELAXED): " + t)
        passes = ", ".join(f"{lbl}{'' if not pch else ' +PCH'}: {ne} problem(s)"
                           for lbl, pch, ne in LAST_RUN.get("passes", []))
        print(f"taintset_scrub_guard: {n} members walked [{passes or 'no pass ran'}] (flags from "
              f"{COMPILE_COMMANDS}), {len(errs)} problem(s), {len(ALLOWLIST)} allowlisted, "
              f"{len(LAST_RUN.get('tolerated', []))} tolerated field finding(s)")
        return 1 if errs else 0
    finally:
        if _PCH["dir"]:
            shutil.rmtree(_PCH["dir"], ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
