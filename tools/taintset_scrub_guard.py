#!/usr/bin/env python3
"""taintset_scrub_guard.py — the STRUCTURAL half of bd test_C_libtooling-8e5r /
-j8sk's pin: a BEST-EFFORT, compiler-assisted check that catches the listed
classes of raw `llvm::Value`-pointer-bearing member being (re)added to
`cq::TaintSet`. A record gate (no plugin, no build products beyond the build's own
`compile_commands.json`).

⚠ IT IS NOT A PROOF AND NOT A CLOSED WORLD. It catches the spelling classes listed
under WHAT IT CATCHES and misses the ones listed under KNOWN GAPS (Rule-13 round r3,
open as bd test_C_libtooling-wop9 / -7gri / -jk56). A clean run means "none of the
checked spellings", never "no raw pointer anywhere in TaintSet". The per-table
deterministic pin is `ir-pass/tools/scrub_selftest.cpp`; this gate is the
structural backstop in front of it. (An earlier version of this docstring said
"THE WALK IS A CLOSED WORLD"; r3 measured 12 in-contract spellings it passes — L7,
corrected here.)

`cq::TaintSet` (ir-pass/include/TaintPropagation.h) is where every stage keeps
pointers to IR values across stages that ERASE IR. Since bd 8e5r every such
table is a self-cleaning container (`ir-pass/include/ScrubOnDelete.h`): a key
whose Value is deleted is dropped by LLVM's own `~Value()` callback, so a later
allocation at the freed address can never answer "tainted". That holds only
while NOBODY ADDS A RAW ONE BACK; this gate catches the common ways of doing so.

⚠ WHY IT ASKS THE COMPILER (Rule-13 r1A F-EA-2 / r1B F-EB-2, bd urf8). The first
version scanned the header TEXT and missed 14-16 of ~23 natural spellings. CLAUDE.md
L5: a syntactic answer to a semantic question loses. So this gate parses the header
(`-Xclang -ast-dump=json -ast-dump-filter TaintSet`) and walks the RECORD's fields
with their DESUGARED types — aliases, typedefs, macros, initialiser styles and
`alignas` are resolved by the compiler before the walk sees them — and asks the
compiler again (`std::is_base_of`, `std::is_enum`, completeness) about every type
it needs to classify.

⚠ WITH ONE OF THE BUILD'S COMPILE COMMANDS (Rule-13 delta r2 F-R2-2, bd a66j). The
second version parsed with Homebrew `clang++` and a hand-written flag set, while
the build uses `/usr/bin/c++ -O3 -DNDEBUG …`: a raw member inside `#ifdef NDEBUG`
shipped in the Release build and the gate never saw it. The compile command is now
READ from the build's `compile_commands.json`: the `CQPass` target's entry for
`ir-pass/src/TaintPropagation.cpp` (`CMAKE_EXPORT_COMPILE_COMMANDS` is ON in the
top-level CMakeLists) — that compiler, its defines, include paths and `-std`.
⚠ That is ONE of the build's configurations for this file, not all of them (KNOWN
GAP G5), and the PCH below can change the answer (G6). It checks the CONFIGURED
build: a member present only in another configuration (e.g. under `#ifndef NDEBUG`
in a Release tree) is not seen until that configuration is configured. A missing
database, a missing entry, or any parse error FAILS CLOSED.

WHAT IT WALKS. Starting at `TaintSet`, the walk visits fields at any depth of:
nested records, anonymous structs/unions, base classes, static data members, and
the PROJECT (`cq::`) records and class-template PATTERNS it reaches by value, as a
template argument, as a `scrub::Map` MAPPED type, or through a pointer whose
pointee is spelled as a `cq::` record or `cq::` template (G1-G4 name the pointer,
specialization and alias forms it does NOT follow). A field it visits is accepted
if its desugared type is built from:

  * scalars: builtins (except `void` in a pointer or template argument) and enums;
  * a pointer to a type that is NOT derived from `llvm::Value` (asked of the
    compiler) and is not on the IR-OWNED deny list (`llvm::Loop`, `llvm::Use`);
  * an APPROVED HANDLE (`HANDLES`, each with its reason; each asserted to derive
    from `llvm::ValueHandleBase`, so a build where it is a bare pointer fails),
    except as (part of) the KEY of an associative container;
  * an APPROVED LEAF value type (`LEAVES`);
  * a `cq::scrub::Set`/`List`/`PairSet` (self-cleaning keys) or a
    `cq::scrub::Map<K, V>` whose V is itself acceptable;
  * any other library class TEMPLATE whose type arguments are all acceptable;
  * a PROJECT record or class template, whose fields and bases are walked (a
    template's PATTERN is walked; its type parameters are checked at each use).

WHAT IT CATCHES (each with its own diagnostic, among the fields it visits): a raw
pointer to a `Value`-derived type; a
`Value`-derived type held by value (the tell of an unapproved handle such as
`AssertingVH`, a bare pointer at `LLVM_ENABLE_ABI_BREAKING_CHECKS=0`); a type-
erased pointer (`void *`, `const void *`) or a `void` template argument
(`shared_ptr<void>`) — each can hold a Value address the compiler cannot see; the
SUGARED spelling `uintptr_t` / `intptr_t`; a pointer to `llvm::Loop` / `llvm::Use`
(IR-owned objects a `~Value` callback does not observe: a `Loop` dies with its
`LoopInfo`, a `Use` with its `User`); a value handle as (part of) an associative-
container KEY when the handle is spelled in the key type itself (`std::set<WeakVH>`,
`pair<WeakVH,int>` — a handle nulled or retargeted in place breaks the container's
ordering/hash invariant; see G7); an unknown non-template record; a function type;
a type the walker cannot parse; a header that does not compile. (Several
diagnostics say "closed world: refused": that names the policy applied to a type
the walk REACHES and cannot classify — it is not a claim that every type is reached.)

KNOWN GAPS — measured by Rule-13 round r3 (`review_r3_8e5r/`, 2026-09-26): each
spelling compiles in the Release build with the raw member present and this gate
reports 0 problems. Open, not fixed; do not quote the gate as covering them.
  G1 (bd wop9) A POINTER to a LIBRARY template holding raw `Value *` is not walked:
     `std::set<llvm::Value *> *`, `llvm::DenseMap<llvm::Value *, unsigned> *`,
     `llvm::SmallVector<llvm::DenseSet<llvm::Value *> *, 2>`. A pointee template's
     arguments are walked only for `cq::` templates; for a library template the
     pointee is only asked "is it Value-derived?" (it is not), and accepted.
  G2 (bd wop9) EXPLICIT and PARTIAL SPECIALIZATIONS of a `cq::` class template are
     not walked — only the primary PATTERN is (`_dump` keeps `CXXRecordDecl` /
     `ClassTemplateDecl` and drops `ClassTemplate[Partial]SpecializationDecl`); a
     specialization selected only under `NDEBUG` passes too.
  G3 (bd wop9) SHORT-NAME alias resolution: a pointer written through an unqualified
     alias (`using Result = RawRec; Result *P;`) is resolved to a name and then
     DUMPED BY SHORT NAME, so records elsewhere in the TU with the same short name
     (LLVM's own `Result`, `Impl`) are walked instead and the member passes; a
     unique short name is refused only by the "no complete definition" fallback —
     safe by luck, not by design.
  G4 (bd wop9) A POINTER to a record OUTSIDE `cq::` (global scope, another
     namespace) is accepted unwalked when it is not `Value`-derived.
  G5 (bd 7gri) It parses ONE translation unit: the CQPass command
     (`-DCQPass_EXPORTS -fPIC`). cq-opt, cq-opt-debugalloc and cq-scrub-selftest
     compile `TaintPropagation.cpp` WITHOUT `-DCQPass_EXPORTS`, so a member under
     `#ifndef CQPass_EXPORTS` ships in the driver every lit RUN line and e2e slice
     uses, and is not seen.
  G6 (bd 7gri) The PCH can CHANGE THE ANSWER: it holds third-party headers outside
     `TaintPropagation.h`'s own include closure (e.g. `llvm/Analysis/LoopInfo.h`),
     and a compile is retried without it only on FAILURE, never on a clean verdict.
     A member under `#ifndef <such a header's guard macro>` passes with the PCH and
     is caught without it.
  G7 (bd jk56) The handle-in-a-KEY rule is SYNTACTIC: a `WeakVH` inside a project
     record used as an associative key (`std::set<RecWithHandle>`) passes —
     `_has_handle` does not look into records.
  G8 (bd jk56) An ALLOWLISTED member exempts its WHOLE TYPE subtree: a raw
     `SmallPtrSet<Value *>` added to `LoopBreakRegion` passes under
     `cq::TaintSet::BreakRegions`' entry, whose reason ("never a table asked by
     IDENTITY") nothing enforces.

INTENTIONALLY OUT OF SCOPE, and why (the r2 reviewer's six out-of-`Value`-scope
spellings are all caught above; what remains by DESIGN is stated here — the gaps
by DEFECT are G1-G8):
  * an address laundered through a PLAIN INTEGER type (`unsigned long`, `size_t`,
    or an alias of one): to the compiler it IS an integer. Only the `uintptr_t` /
    `intptr_t` sugar is recognisable, and only while it is spelled so.
  * pointers to OTHER non-`Value` IR-adjacent objects (`llvm::MDNode *`,
    `DominatorTree *`, other analysis results): their lifetime is not a `~Value`
    event and no scrub container could observe it; the deny list names the two
    this pass has actually held (`Loop`, bd emof; `Use`).
  * pointer-bearing state OUTSIDE `TaintSet` (`ControlPlan`, `SpecPlan`,
    file-static ledgers, local snapshots — bd ibtq): out of this gate's subject.

It also fails when (a) an ALLOWLIST entry (keyed by QUALIFIED member path, never by
a bare name) names no member, and (b) a self-cleaning member is not exercised by
`ir-pass/tools/scrub_selftest.cpp` — searched with comments STRIPPED.

SPEED: every compile reuses one PRECOMPILED HEADER of the third-party headers the
project headers include, built once per run with the same command. If the PCH
cannot be built, or a compile fails WITH it, the compile is retried WITHOUT it and
that result counts — but a CLEAN verdict with the PCH is NOT re-checked without it,
so the PCH is NOT verdict-neutral (G6). The self-test pins only that the PRISTINE
header's verdict is the same with and without it.

`--selftest` is its own mutant validation: null controls clean, and every spelling
of the three Rule-13 fool corpora it was built against (r1A `guard_bypass.py`, r1B
`guard_fool.py`, r2 `guard_fool_r2.py`) plus the guard's own mutants REFUSED FOR THE
RIGHT REASON (the expected diagnostic substring is checked, so a compile error is
not a kill). It does NOT carry r3's G1-G8 spellings: those are the open beads above,
and as expected-refusals they would turn the self-test red until the beads land.

The module keeps the first guard's API (`HEADER`, `SELFTEST`, `SCRUB_HDR`,
`ALLOWLIST`, `check(header_src, selftest_src, allowlist, scrub_src)`), so the
reviewers' harnesses run against it unmodified.
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
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDE_DIR = os.path.join(ROOT, "ir-pass", "include")
HEADER = os.path.join(INCLUDE_DIR, "TaintPropagation.h")
SELFTEST = os.path.join(ROOT, "ir-pass", "tools", "scrub_selftest.cpp")
SCRUB_HDR = os.path.join(INCLUDE_DIR, "ScrubOnDelete.h")
COMPILE_COMMANDS = os.environ.get("CQ_GUARD_COMPILE_COMMANDS",
                                  os.path.join(ROOT, "build", "compile_commands.json"))
USE_PCH = True

# Qualified member path -> reason it may hold a raw pointer. Keyed by the FULL
# path (r1B: a bare-name key such as `F` would exempt every future `F`).
ALLOWLIST = {
    "cq::TaintSet::RestoringRoutes": (
        "has NO WRITER anywhere in ir-pass/src (grep `RestoringRoutes.push_back` / "
        "`.emplace_back` finds nothing since drbq Inc 2a); its two readers iterate an "
        "always-empty container. The day it gains a writer it must become "
        "handle-typed or a scrub:: container, and this entry must go."),
    "cq::TaintSet::BreakRegions": (
        "a per-loop RECORD (`LoopBreakRegion`, LoopPlan.h) of raw block/value/`Loop *` "
        "pointers that `lowerLoops` writes and `lowerBreakReversePlay` dereferences — "
        "never a table asked by IDENTITY, so a fresh object at a freed address cannot "
        "answer a membership question through it. Its hazard is a different one (a "
        "dangling RECORD field, UAF-on-read) and is NOT closed by bd 8e5r; filed as "
        "bd test_C_libtooling-emof."),
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
# Associative containers: a handle anywhere in the KEY (first type argument) is refused.
ASSOCIATIVE = {
    "std::set", "std::multiset", "std::map", "std::multimap", "std::unordered_set",
    "std::unordered_map", "std::unordered_multiset", "std::unordered_multimap",
    "llvm::DenseSet", "llvm::DenseMap", "llvm::SmallDenseSet", "llvm::SmallDenseMap",
    "llvm::SmallSet", "llvm::SmallPtrSet", "llvm::MapVector", "llvm::SetVector",
    "llvm::SmallSetVector", "llvm::ValueMap",
}
# Self-cleaning containers (ScrubOnDelete.h). `Map` also has its MAPPED type walked.
SCRUB_KEYS_ONLY = {"cq::scrub::Set", "cq::scrub::List", "cq::scrub::PairSet"}
SCRUB_MAP = "cq::scrub::Map"
PROJECT_NS = "cq::"
SCRUB_NS = "cq::scrub::"

BUILTINS = {
    "void", "bool", "char", "signed char", "unsigned char", "wchar_t", "char8_t",
    "char16_t", "char32_t", "short", "unsigned short", "int", "unsigned int", "long",
    "unsigned long", "long long", "unsigned long long", "__int128",
    "unsigned __int128", "float", "double", "long double", "std::nullptr_t",
    "std::byte",
}
INTPTR_SUGAR = re.compile(r"\b(?:std::)?u?intptr_t\b")
TPARAM_CANON = re.compile(r"^type-parameter-\d+-\d+$")


class GuardError(Exception):
    pass


# ----------------------------------------------------------------------------
# the build's own compile command
# ----------------------------------------------------------------------------
_BASE = None
_BASE_LOCK = threading.Lock()


def _base_command():
    """-> (argv prefix [compiler, flags...], cwd). The CQPass target's command for
    ir-pass/src/TaintPropagation.cpp, with output/dependency/source arguments removed.
    ⚠ ONE of the build's configurations for that file (KNOWN GAP G5, bd 7gri)."""
    global _BASE
    with _BASE_LOCK:
        if _BASE is not None:
            return _BASE
        cc = COMPILE_COMMANDS
        if not os.path.isfile(cc):
            raise GuardError(f"compile database not found: {cc} — configure the build "
                             f"(CMAKE_EXPORT_COMPILE_COMMANDS is ON) or pass --compile-commands")
        db = json.load(open(cc))
        want = os.path.realpath(os.path.join(ROOT, "ir-pass", "src", "TaintPropagation.cpp"))
        ents = [e for e in db if os.path.realpath(
            os.path.join(e.get("directory", ""), e.get("file", ""))) == want]
        if not ents:
            raise GuardError(f"no entry for {want} in {cc}")
        ents.sort(key=lambda e: 0 if "CQPass.dir" in (e.get("output") or e.get("command", "")) else 1)
        e = ents[0]
        argv = e.get("arguments") or shlex.split(e["command"])
        out, skip = [argv[0]], False
        for i, a in enumerate(argv[1:], 1):
            if skip:
                skip = False
                continue
            if a in ("-o", "-MF", "-MT", "-MQ"):
                skip = True
                continue
            if a in ("-c", "-MD", "-MMD") or os.path.realpath(
                    os.path.join(e.get("directory", ""), a)) == want:
                continue
            out.append(a)
        _BASE = (out, e.get("directory") or ROOT)
        return _BASE


# ----------------------------------------------------------------------------
# the precompiled header (an optimisation that is NOT verdict-neutral: a clean
# verdict with it is not re-checked without it — KNOWN GAP G6, bd 7gri)
# ----------------------------------------------------------------------------
_PCH = {"state": None, "path": None, "dir": None}
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


def _pch():
    if not USE_PCH:
        return None
    with _PCH_LOCK:
        if _PCH["state"] is not None:
            return _PCH["path"] if _PCH["state"] == "ok" else None
        base, cwd = _base_command()
        lines = set(EXTRA_INCLUDES.splitlines())
        for f in os.listdir(INCLUDE_DIR):
            if f.endswith(".h"):
                for l in open(os.path.join(INCLUDE_DIR, f)):
                    m = re.match(r'\s*#\s*include\s+([<"])([^>"]+)[>"]', l)
                    if m and (m.group(1) == "<" or m.group(2).startswith(("llvm/", "llvm-c/"))):
                        lines.add(f"#include {m.group(1)}{m.group(2)}{'>' if m.group(1) == '<' else chr(34)}")
        d = tempfile.mkdtemp(prefix="cq_scrub_guard_pch_")
        _PCH["dir"] = d
        hdr = os.path.join(d, "cq_guard_prefix.h")
        open(hdr, "w").write("\n".join(sorted(lines)) + "\n")
        pch = hdr + ".pch"
        r = subprocess.run(base + ["-w", "-x", "c++-header", hdr, "-o", pch],
                           capture_output=True, text=True, cwd=cwd)
        if r.returncode == 0 and os.path.isfile(pch):
            _PCH.update(state="ok", path=pch)
            return pch
        _PCH.update(state="failed")
        return None


def _compile(tu_dir, tu, extra):
    """Run the build's compiler on `tu` (syntax only). With the PCH first; on any
    failure retried without it, and only that result is returned. ⚠ A SUCCESS with
    the PCH is returned as is (KNOWN GAP G6, bd 7gri)."""
    base, cwd = _base_command()
    cmd = base + ["-fsyntax-only", "-fno-color-diagnostics", "-ferror-limit=0", "-w",
                  f"-I{tu_dir}"]
    pch = _pch()
    if pch:
        r = subprocess.run(cmd + ["-include-pch", pch] + extra + [tu],
                           capture_output=True, text=True, cwd=cwd)
        if r.returncode == 0:
            return r
    return subprocess.run(cmd + extra + [tu], capture_output=True, text=True, cwd=cwd)


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


# ----------------------------------------------------------------------------
# the type-string parser (over the compiler's DESUGARED, canonical spelling)
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


def parse_type(t):
    """-> ('ptr', inner) | ('arr', inner) | ('anon', text) | ('fn', text)
          | ('tmpl', name, [args]) | ('named', name) | ('lit', text)"""
    t = " ".join(t.split())
    while True:
        n = re.sub(r"^(const|volatile)\s+", "", t)
        n = re.sub(r"\s+(const|volatile)$", "", n)
        if n == t:
            break
        t = n
    if not t:
        return ("lit", t)
    if re.match(r"^-?[0-9]", t) or t in ("true", "false"):
        return ("lit", t)
    m = re.match(r"^(struct|class|union|enum)\s+(.*)$", t)
    if m and not m.group(2).startswith("("):
        t = m.group(2)
    if "(unnamed " in t or "(anonymous " in t:
        if t.startswith("(") or re.match(r"^(struct|class|union)\s+\(", t):
            return ("anon", t)
    m = re.match(r"^(.*\S)\s*\[[^\[\]]*\]$", t)
    if m and _balanced(m.group(1)):
        return ("arr", parse_type(m.group(1)))
    if t.endswith("*") or t.endswith("&"):
        inner = t[:-2].rstrip() if t.endswith("&&") else t[:-1].rstrip()
        if _balanced(inner):
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
            return ("tmpl", name, [parse_type(a) for a in args])
    return ("named", t)


def _balanced(s):
    d = 0
    for ch in s:
        d += ch in "<([{"
        d -= ch in ">)]}"
        if d < 0:
            return False
    return d == 0


def _render(node):
    k = node[0]
    if k == "ptr":
        return _render(node[1]) + " *"
    if k == "arr":
        return _render(node[1]) + "[]"
    if k == "tmpl":
        return node[1] + "<" + ", ".join(_render(a) for a in node[2]) + ">"
    return node[1]


def _has_handle(node):
    k = node[0]
    if k == "named":
        return node[1] in HANDLES
    if k == "tmpl":
        return node[1] in HANDLE_TEMPLATES or any(_has_handle(a) for a in node[2])
    if k in ("ptr", "arr"):
        return _has_handle(node[1])
    return False


# ----------------------------------------------------------------------------
# the walk
# ----------------------------------------------------------------------------
class Walk:
    def __init__(self, allowlist):
        self.allowlist = allowlist
        self.errs = []
        self.pointee_q = {}   # type name -> [paths] (need: is it Value-derived?)
        self.named_q = {}     # type name -> [(path, via)] (need: enum? class? Value?)
        self.foreign = {}     # project record/template name -> [paths] (need its fields)
        self.scrub_fields = []  # (path, name, top_level)
        self.members = 0
        self.seen_paths = set()
        self.walked = set()   # qualified names of records already walked
        self.tparams = set()  # template type-parameter names of the pattern being walked
        self.scope = "cq"     # qualified name of the record whose fields are being walked
        self.unresolved = []  # (path, scope, kind, node, via): names written UNQUALIFIED

    def _is_tparam(self, nm):
        return nm in self.tparams or bool(TPARAM_CANON.match(nm))

    def field_type(self, path, t, top_level=False, name=None):
        self._t(path, parse_type(t), top_level, name)

    def _t(self, path, node, top_level=False, name=None):
        k = node[0]
        if k == "lit":
            return
        if k == "ptr":
            inner = node[1]
            if inner[0] == "ptr":           # T ** : judge the innermost pointee
                return self._t(path, inner)
            if inner[0] == "named":
                nm = inner[1]
                if nm == "void":
                    self.errs.append(f"{path}: TYPE-ERASED pointer (`void *`) — it can hold a "
                                     f"Value address the compiler cannot see; refused")
                    return
                if nm in BUILTINS or self._is_tparam(nm):
                    return
                if "::" not in nm:
                    self.unresolved.append((path, self.scope, "ptr", inner, None))
                    return
                if nm in IR_OWNED_DENY:
                    self.errs.append(f"{path}: pointer to IR-OWNED `{nm}` — "
                                     f"{IR_OWNED_DENY[nm]}; refused")
                    return
                if nm.startswith(PROJECT_NS) and not nm.startswith(SCRUB_NS):
                    self.foreign.setdefault(nm, []).append(path)   # walk what it points to
                self.pointee_q.setdefault(nm, []).append(path)
                return
            if inner[0] == "tmpl":
                if "::" not in inner[1]:
                    self.unresolved.append((path, self.scope, "ptr", inner, None))
                    return
                if inner[1].startswith(PROJECT_NS) and not inner[1].startswith(SCRUB_NS):
                    self.foreign.setdefault(inner[1], []).append(path)
                    for a in inner[2]:
                        self._t(path, a) if a[0] != "named" else self._named(path, a[1], via=inner[1])
                self.pointee_q.setdefault(_render(inner), []).append(path)
                return
            if inner[0] == "anon":
                return
            self.errs.append(f"{path}: pointer to `{_render(inner)}` — form not understood "
                             f"by the walker (closed world: refused)")
            return
        if k == "arr":
            return self._t(path, node[1])
        if k == "fn":
            self.errs.append(f"{path}: function type `{node[1]}` — not understood by the "
                             f"walker (closed world: refused)")
            return
        if k == "anon":
            return  # anonymous records are walked as nested definitions
        if k == "tmpl":
            nm = node[1]
            if "::" not in nm:
                self.unresolved.append((path, self.scope, "tmpl", node, None))
                return
            if nm in SCRUB_KEYS_ONLY:
                if name is not None:
                    self.scrub_fields.append((path, name, top_level))
                return
            if nm == SCRUB_MAP:
                if name is not None:
                    self.scrub_fields.append((path, name, top_level))
                if len(node[2]) >= 2:
                    self._t(path + " [ScrubMap MAPPED type]", node[2][1])
                return
            if nm in ASSOCIATIVE and node[2] and _has_handle(node[2][0]):
                self.errs.append(f"{path}: a value HANDLE in the KEY of `{nm}` — a handle is "
                                 f"nulled/retargeted IN PLACE, which breaks the container's "
                                 f"ordering/hash invariant; refused")
                return
            if nm in HANDLE_TEMPLATES:
                self.errs.append(f"{path}: value handle `{_render(node)}` is not on the approved "
                                 f"list ({', '.join(sorted(HANDLES))}) — held BY VALUE; refused")
                return
            if nm.startswith(PROJECT_NS):
                self.foreign.setdefault(nm, []).append(path)   # a project class TEMPLATE
            for a in node[2]:
                if a[0] == "named":
                    if a[1] == "void":
                        self.errs.append(f"{path}: `void` template argument of `{nm}` — a "
                                         f"TYPE-ERASED holder can hold a Value address; refused")
                    elif a[1] not in BUILTINS:
                        self._named(path, a[1], via=nm)
                else:
                    self._t(path, a)
            return
        if k == "named":
            self._named(path, node[1])

    def _named(self, path, nm, via=None):
        if nm in BUILTINS or self._is_tparam(nm):
            return
        if nm in HANDLES or nm in LEAVES:
            return
        if "::" not in nm:
            self.unresolved.append((path, self.scope, "named", ("named", nm), via))
            return
        if nm.startswith(PROJECT_NS):
            self.foreign.setdefault(nm, []).append(path)
            return
        self.named_q.setdefault(nm, []).append((path, via))


def _walk_record(W, rec, path, top_level):
    """Walk a CXXRecordDecl JSON node: bases, fields, static members, nested records."""
    W.walked.add(path)
    saved_scope = W.scope
    W.scope = path
    try:
        _walk_record_body(W, rec, path, top_level)
    finally:
        W.scope = saved_scope


def _walk_record_body(W, rec, path, top_level):
    for b in rec.get("bases", []) or []:
        bt = b.get("type", {})
        W.field_type(path + "::<base>", bt.get("desugaredQualType") or bt.get("qualType", ""))
    for c in rec.get("inner", []) or []:
        kind = c.get("kind")
        if kind in ("FieldDecl", "VarDecl"):
            nm = c.get("name", "<unnamed>")
            p = f"{path}::{nm}"
            W.members += 1
            W.seen_paths.add(p)
            if p in W.allowlist:
                continue
            t = c.get("type", {})
            sugared = t.get("qualType", "")
            if INTPTR_SUGAR.search(sugared):
                W.errs.append(f"{p}: `{sugared}` — an address laundered through "
                              f"uintptr_t/intptr_t can alias a Value; refused")
                continue
            W.field_type(p, t.get("desugaredQualType") or sugared, top_level=top_level, name=nm)
        elif kind == "CXXRecordDecl" and c.get("completeDefinition"):
            nm = c.get("name")
            _walk_record(W, c, f"{path}::{nm or '(anonymous)'}", top_level=False)
        elif kind == "ClassTemplateDecl":
            _walk_template(W, c, f"{path}::{c.get('name')}")


def _walk_template(W, tdecl, path):
    params = {c.get("name") for c in tdecl.get("inner", []) or []
              if c.get("kind") in ("TemplateTypeParmDecl", "NonTypeTemplateParmDecl",
                                   "TemplateTemplateParmDecl") and c.get("name")}
    saved = W.tparams
    W.tparams = saved | params
    try:
        for c in tdecl.get("inner", []) or []:
            if c.get("kind") == "CXXRecordDecl" and c.get("completeDefinition"):
                _walk_record(W, c, path, top_level=False)
    finally:
        W.tparams = saved
    W.walked.add(path)


def _dump(tu_dir, name):
    r = _compile(tu_dir, os.path.join(tu_dir, "cq_guard_probe.cpp"),
                 ["-Xclang", "-ast-dump=json", "-Xclang", "-ast-dump-filter", "-Xclang", name])
    if r.returncode != 0:
        return None, r.stderr
    short = name.split("::")[-1]
    return [d for d in _json_docs(r.stdout) if d.get("name") == short and (
        (d.get("kind") == "CXXRecordDecl" and d.get("completeDefinition"))
        or d.get("kind") == "ClassTemplateDecl")], ""


_TRAIT_CACHE = {}
_TRAIT_LOCK = threading.Lock()


def _requalify(node, qname):
    return ("named", qname) if node[0] == "named" else ("tmpl", qname, node[2])


def _resolve(tu_dir, items):
    """Qualify each UNQUALIFIED type name the way C++ lookup from its field's scope
    would: innermost enclosing record/namespace first, then outward, then the global
    namespace. One TU; each candidate is one line, and a candidate EXISTS iff its
    line compiles. -> {(name, scope): qualified-name or None}."""
    keys = sorted({(it[3][1], it[1]) for it in items})
    lines = ['#include "TaintPropagation.h"']
    where = {}  # line number -> (key, candidate)
    for i, (nm, scope) in enumerate(keys):
        parts = scope.split("::")
        cands = ["::".join(parts[:k]) + "::" + nm for k in range(len(parts), 0, -1)] + [nm]
        for j, c in enumerate(cands):
            lines.append(f"template <class... Ts> using cq_guard_r{i}_{j} = ::{c}<Ts...>;"
                         if any(it[3][0] == "tmpl" and it[3][1] == nm for it in items)
                         else f"using cq_guard_r{i}_{j} = ::{c};")
            where[len(lines)] = ((nm, scope), c, j)
    path = os.path.join(tu_dir, "cq_guard_resolve.cpp")
    open(path, "w").write("\n".join(lines) + "\n")
    r = _compile(tu_dir, path, [])
    bad = set()
    for line in r.stderr.splitlines():
        m = re.search(r"cq_guard_resolve\.cpp:(\d+):\d+: error", line)
        if m:
            bad.add(int(m.group(1)))
    out = {}
    for ln in sorted(where):
        key, cand, j = where[ln]
        if ln not in bad and key not in out:
            out[key] = cand
    return {k: out.get(k) for k in keys}


def _traits(tu_dir, names):
    """Ask the compiler, for each type name: complete? enum? class? Value-derived?
    ValueHandleBase-derived? Returns {name: set(props)}; raises on a compile failure
    that is not one of the property asserts."""
    lines = ['#include "TaintPropagation.h"', "#include <type_traits>",
             "namespace cq_guard {",
             "template <typename T, typename = void> struct complete : std::false_type {};",
             "template <typename T> struct complete<T, std::void_t<decltype(sizeof(T))>> : std::true_type {};",
             "template <typename B, typename T> struct derived : std::conjunction<complete<T>, std::is_class<T>, std::is_base_of<B, T>> {};",
             "}"]
    names = sorted(names)
    for i, n in enumerate(names):
        T = f"::{n}" if not n.startswith("::") else n
        lines += [
            f'static_assert(!cq_guard::complete<{T}>::value, "CQPROP|{i}|complete");',
            f'static_assert(!std::is_enum<{T}>::value, "CQPROP|{i}|enum");',
            f'static_assert(!std::is_class<{T}>::value, "CQPROP|{i}|class");',
            f'static_assert(!cq_guard::derived<llvm::Value, {T}>::value, "CQPROP|{i}|value");',
            f'static_assert(!cq_guard::derived<llvm::ValueHandleBase, {T}>::value, "CQPROP|{i}|vhbase");',
        ]
    path = os.path.join(tu_dir, "cq_guard_traits.cpp")
    open(path, "w").write("\n".join(lines) + "\n")
    r = _compile(tu_dir, path, [])
    props = {n: set() for n in names}
    other = []
    for line in r.stderr.splitlines():
        m = re.search(r"CQPROP\|(\d+)\|(\w+)", line)
        if m:
            props[names[int(m.group(1))]].add(m.group(2))
        elif " error: " in line or line.startswith("error:"):
            other.append(line)
    if other:
        raise GuardError("trait probe did not compile:\n  " + "\n  ".join(other[:8]))
    return props


def check(header_src, selftest_src, allowlist, scrub_src=None):
    """-> (errors, members_scanned). Parses the given texts in a temp include dir with
    the build's own compile command."""
    try:
        _base_command()
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
        open(os.path.join(tmp, "cq_guard_probe.cpp"), "w").write('#include "TaintPropagation.h"\n')
        recs, err = _dump(tmp, "TaintSet")
        if recs is None:
            first = [l for l in err.splitlines() if " error: " in l or l.startswith("error:")][:6]
            return (["the TaintSet header does not compile — refused (fail closed):\n    "
                     + "\n    ".join(first or err.splitlines()[:6])], 0)
        recs = [r for r in recs if r.get("kind") == "CXXRecordDecl"]
        if len(recs) != 1:
            return ([f"expected exactly one complete `TaintSet` definition, found {len(recs)}"], 0)
        W = Walk(allowlist)
        _walk_record(W, recs[0], "cq::TaintSet", top_level=True)
        # project records and class templates reached by value, by a `cq::`-spelled
        # pointer or as a template argument: dump (BY SHORT NAME — KNOWN GAP G3) and
        # walk each (iterate: one may reach another)
        while True:
            if W.unresolved:
                items, W.unresolved = W.unresolved, []
                res = _resolve(tmp, items)
                for path, scope, kind, node, via in items:
                    q = res.get((node[1], scope))
                    if q is not None and "::" not in q:
                        q = "::" + q  # resolved in the GLOBAL namespace
                    if q is None:
                        W.errs.append(f"{path}: unqualified type `{node[1]}` does not resolve from "
                                      f"scope `{scope}` — closed world: refused")
                        continue
                    saved = W.scope
                    W.scope = scope
                    try:
                        qn = _requalify(node, q)
                        if kind == "ptr":
                            W._t(path, ("ptr", qn))
                        elif kind == "tmpl":
                            W._t(path, qn)
                        else:
                            W._named(path, q, via=via)
                    finally:
                        W.scope = saved
            todo = [n for n in W.foreign if n not in W.walked]
            if not todo and not W.unresolved:
                break
            with ThreadPoolExecutor(4) as ex:
                dumps = list(ex.map(lambda n: (n, _dump(tmp, n.split("::")[-1])), todo))
            for n, (rs, e) in dumps:
                W.walked.add(n)
                if not rs:
                    W.errs.append(f"{W.foreign[n][0]}: project type `{n}` is reached, but no "
                                  f"complete definition was found — refused")
                    continue
                for r in rs:
                    if r.get("kind") == "ClassTemplateDecl":
                        _walk_template(W, r, n)
                    else:
                        _walk_record(W, r, n, top_level=False)
        names = set(W.named_q) | set(W.pointee_q) | set(HANDLES)
        with _TRAIT_LOCK:
            cached = {n: _TRAIT_CACHE[n] for n in names if n in _TRAIT_CACHE}
        ask = names - set(cached)
        try:
            props = dict(cached)
            if ask:
                fresh = _traits(tmp, ask)
                props.update(fresh)
                with _TRAIT_LOCK:
                    for n, v in fresh.items():
                        if n.startswith(("llvm::", "std::")):
                            _TRAIT_CACHE[n] = v
        except GuardError as ex:
            return ([str(ex)], W.members)
        for h in HANDLES:
            if "vhbase" not in props.get(h, set()):
                W.errs.append(f"approved handle `{h}` is NOT derived from llvm::ValueHandleBase "
                              f"in this build — it is not a handle here; refused")
        for n, paths in W.pointee_q.items():
            p = props.get(n, set())
            if "value" in p:
                for path in sorted(set(paths)):
                    W.errs.append(f"{path}: RAW POINTER to `{n}`, which derives from "
                                  f"llvm::Value — use a scrub:: container or a value handle "
                                  f"(WeakVH / WeakTrackingVH), or allowlist the qualified member "
                                  f"with a reason")
            elif "complete" not in p and n not in BUILTINS:
                for path in sorted(set(paths)):
                    W.errs.append(f"{path}: pointer to INCOMPLETE type `{n}` — cannot prove it "
                                  f"is not an llvm::Value (closed world: refused)")
        for n, uses in W.named_q.items():
            p = props.get(n, set())
            if "enum" in p:
                continue
            for path, via in sorted(set(uses)):
                if "value" in p:
                    W.errs.append(f"{path}: `{n}` (derives from llvm::Value) held BY VALUE"
                                  + (f" as a template argument of `{via}`" if via else "")
                                  + " — the tell of an UNAPPROVED handle (e.g. AssertingVH is a "
                                  "bare pointer at LLVM_ENABLE_ABI_BREAKING_CHECKS=0); refused")
                elif "vhbase" in p:
                    W.errs.append(f"{path}: value handle `{n}` is not on the approved list "
                                  f"({', '.join(sorted(HANDLES))}) — held BY VALUE; refused")
                else:
                    W.errs.append(f"{path}: record type `{n}`"
                                  + (f" (template argument of `{via}`)" if via else "")
                                  + " is not a scalar, an approved handle/leaf, a scrub:: "
                                  "container or a project record — closed world: approve it "
                                  "in taintset_scrub_guard.py with a reason, or change the type")
        for a in allowlist:
            if a not in W.seen_paths:
                W.errs.append(f"stale allowlist entry `{a}`: no such member")
        st = _strip_comments(selftest_src)
        for path, nm, top in W.scrub_fields:
            pat = (r"\bT\." if top else r"\.") + re.escape(nm) + r"\b"
            if not re.search(pat, st):
                W.errs.append(f"self-cleaning member `{path}` is not exercised by "
                              f"ir-pass/tools/scrub_selftest.cpp (comments do not count)")
        return (sorted(set(W.errs)), W.members)
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
# mutant self-test: all three Rule-13 fool corpora + the guard's own mutants
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
HKEY = "HANDLE in the KEY"
NOCOMPILE = "does not compile"


def _mutants(hdr, st, sc):
    def ins(member, pre=""):
        assert hdr.count(ANCH) == 1
        h = hdr.replace("#include <set>\n", "#include <set>\n" + EXTRA_INCLUDES, 1)
        assert h != hdr, "include anchor missing"
        return h.replace(ANCH, pre + ANCH + "\n  " + member, 1)
    RAWREC = "struct R2RawRec { llvm::Value *P = nullptr; };\n"
    RAWTMPL = "template <typename T> struct R2RawHolder { llvm::Value *P = nullptr; T X{}; };\n"
    AL = ALLOWLIST
    M = [("NULL: pristine tree", hdr, st, sc, AL, None),
         ("NULL: pristine + the mutants' extra includes", ins(""), st, sc, AL, None),
         ("NULL: a CLEAN project class template (T only) held by value",
          ins("R2CleanHolder<int> CH;", "template <typename T> struct R2CleanHolder { T X{}; unsigned N = 0; };\n"),
          st, sc, AL, None),
         ("NULL: a CLEAN NESTED TaintSet record held by an unqualified pointer (lookup resolves it)",
          hdr.replace("llvm::SmallVector<CmpCondRead, 4> CmpCondReads;",
                      "llvm::SmallVector<CmpCondRead, 4> CmpCondReads;\n  CmpCondRead *CCRPtr = nullptr;", 1),
          st, sc, AL, None),
         ("NULL: a CLEAN project record held by pointer",
          ins("R2CleanRec *CRP = nullptr;", "struct R2CleanRec { unsigned N = 0; llvm::WeakVH H; };\n"),
          st, sc, AL, None),
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


def selftest(jobs=6):
    hdr = open(HEADER).read()
    st = open(SELFTEST).read()
    sc = open(SCRUB_HDR).read()
    # PCH EQUIVALENCE CONTROL: the pristine answer must not depend on the PCH.
    global USE_PCH
    saved = USE_PCH
    USE_PCH = False
    no_pch = check(hdr, st, ALLOWLIST, sc)
    USE_PCH = saved
    with_pch = check(hdr, st, ALLOWLIST, sc)
    pch_ok = (no_pch == with_pch) and not no_pch[0]
    print(f"  {'ok ' if pch_ok else 'BAD'} PCH equivalence control: without PCH {no_pch[1]} members / "
          f"{len(no_pch[0])} problems, with PCH {with_pch[1]} / {len(with_pch[0])} "
          f"(PCH {_PCH['state']})")
    muts = _mutants(hdr, st, sc)

    def run(m):
        label, h, s, x, al, expect = m
        errs, n = check(h, s, al, x)
        return label, expect, errs, n

    with ThreadPoolExecutor(jobs) as ex:
        res = list(ex.map(run, muts))
    bad = [] if pch_ok else ["PCH equivalence control"]
    for label, expect, errs, n in res:
        if expect is None:
            ok = not errs
            verdict = "clean" if ok else "PROBLEMS"
        else:
            hit = [e for e in errs if expect in e]
            ok = bool(hit)
            verdict = "KILLED (right reason)" if ok else (
                "KILLED FOR THE WRONG REASON" if errs else "MISSED")
        print(f"  {'ok ' if ok else 'BAD'} {verdict:28s} {label}   [{n} members]")
        if not ok:
            bad.append(label)
            for e in errs[:3]:
                print("        " + e.splitlines()[0][:200])
    nm = sum(1 for m in muts if m[5] is not None)
    print(f"taintset_scrub_guard selftest: {len(muts) - nm + 1} null/equivalence controls, {nm} mutants, "
          f"{len(bad)} failed")
    return 1 if bad else 0


def main():
    global COMPILE_COMMANDS, USE_PCH
    args = sys.argv[1:]
    i = 0
    while i < len(args):  # unknown arguments are refused, never ignored
        if args[i] == "--compile-commands" and i + 1 < len(args):
            COMPILE_COMMANDS = args[i + 1]
            i += 2
        elif args[i] in ("--no-pch", "--selftest"):
            i += 1
        else:
            print(f"taintset_scrub_guard: unknown argument `{args[i]}`", file=sys.stderr)
            return 2
    if "--no-pch" in args:
        USE_PCH = False
    try:
        if "--selftest" in args:
            return selftest()
        errs, n = check(open(HEADER).read(), open(SELFTEST).read(), ALLOWLIST, open(SCRUB_HDR).read())
        for e in errs:
            print("taintset_scrub_guard: " + e)
        cmd = _base_command()[0][0] if not errs or n else "?"
        print(f"taintset_scrub_guard: {n} TaintSet members walked (compiler: {cmd}, flags from "
              f"{COMPILE_COMMANDS}, PCH {_PCH['state']}), {len(errs)} problem(s), "
              f"{len(ALLOWLIST)} allowlisted")
        return 1 if errs else 0
    finally:
        if _PCH["dir"]:
            shutil.rmtree(_PCH["dir"], ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
