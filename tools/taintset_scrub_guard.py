#!/usr/bin/env python3
"""taintset_scrub_guard.py — the STRUCTURAL half of bd test_C_libtooling-8e5r /
-j8sk's pin, asked of the COMPILER. A record gate (no plugin, no build products).

`cq::TaintSet` (ir-pass/include/TaintPropagation.h) is where every stage keeps
pointers to IR values across stages that ERASE IR. Since bd 8e5r every such
table is a self-cleaning container (`ir-pass/include/ScrubOnDelete.h`): a key
whose Value is deleted is dropped by LLVM's own `~Value()` callback, so a later
allocation at the freed address can never answer "tainted". That holds only
while NOBODY ADDS A RAW ONE BACK, and this gate is what says so.

⚠ WHY IT ASKS CLANG (Rule-13 r1A F-EA-2 / r1B F-EB-2, bd urf8). The first
version scanned the header TEXT and missed 14-16 of ~23 natural spellings: brace
initialisers, `SmallSet`, aliases and typedefs, macros, `std::pair`/`array`/
`optional`, anonymous structs and unions, a foreign record held by value, a raw
pointer as a `ScrubMap` MAPPED value, `AssertingVH`. CLAUDE.md L5: a syntactic
answer to a semantic question loses. So this gate compiles the header
(`clang++ -Xclang -ast-dump=json -ast-dump-filter TaintSet`), and walks the
RECORD's fields with their DESUGARED types — every alias, typedef, macro,
initialiser style and `alignas` is resolved by the compiler before the walk sees
it — and asks the compiler again (`std::is_base_of`, `std::is_enum`,
completeness) about every type it needs to classify.

THE WALK IS A CLOSED WORLD. A field (at any depth: nested records, anonymous
structs/unions, base classes, static data members, records held by value or as a
template argument, the MAPPED type of a `scrub::Map`) is accepted only if its
desugared type is built from:

  * scalars: builtins and enums;
  * a pointer to a type that is NOT derived from `llvm::Value` (asked of clang);
  * an APPROVED HANDLE (`HANDLES` below, each with its reason; each is asserted
    to derive from `llvm::ValueHandleBase`, so a build where it is a bare pointer
    fails here);
  * an APPROVED LEAF value type (`LEAVES`);
  * a `cq::scrub::Set`/`List`/`PairSet` (self-cleaning keys) or a
    `cq::scrub::Map<K, V>` whose V is itself acceptable;
  * any other class TEMPLATE whose type arguments are all acceptable;
  * a PROJECT record (defined under `cq::`), whose fields and bases are walked.

Anything else FAILS: a raw pointer to a Value-derived type (`Function`,
`BasicBlock`, `Instruction`, ...), a Value-derived type held by value (the tell
of an unapproved handle such as `AssertingVH`, a bare pointer at
`LLVM_ENABLE_ABI_BREAKING_CHECKS=0`), an unknown non-template record, a type the
walker cannot parse, a header that does not compile, or a missing clang.

It also fails when (a) an ALLOWLIST entry (keyed by QUALIFIED member path, never
by a bare name) names no member, and (b) a self-cleaning member is not exercised
by `ir-pass/tools/scrub_selftest.cpp` — searched with comments STRIPPED, so a
`// T.X` mention does not count (r1B G19).

`--selftest` is its own mutant validation: the pristine header must be clean,
header-with-extra-includes must be clean (null controls), and every spelling of
BOTH Rule-13 fool corpora (r1A `guard_bypass.py`, r1B `guard_fool.py`) plus the
first guard's own mutants must be refused — each for the RIGHT reason (the
expected diagnostic substring is checked, so a mutant killed only because it
failed to compile does not count as caught).

The module keeps the first guard's API (`HEADER`, `SELFTEST`, `SCRUB_HDR`,
`ALLOWLIST`, `check(header_src, selftest_src, allowlist, scrub_src)`), so the
reviewers' harnesses run against it unmodified.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDE_DIR = os.path.join(ROOT, "ir-pass", "include")
HEADER = os.path.join(INCLUDE_DIR, "TaintPropagation.h")
SELFTEST = os.path.join(ROOT, "ir-pass", "tools", "scrub_selftest.cpp")
SCRUB_HDR = os.path.join(INCLUDE_DIR, "ScrubOnDelete.h")

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
# (by clang) to derive from `llvm::ValueHandleBase` — a real registered handle.
HANDLES = {
    "llvm::WeakVH": "identity handle: nulled when its Value is deleted, never "
                    "follows a RAUW, so it can never dangle",
    "llvm::WeakTrackingVH": "tracking handle: FOLLOWS a RAUW and is nulled on a plain "
                            "delete, so it can never dangle. Admitted where a record "
                            "must follow a RAUW — which the identity-keyed scrub:: "
                            "containers deliberately do not (d88e's "
                            "LiftedMergePhi::Base/Incomings, PeelClones, RailCondReads, ...)",
}
# Approved leaf value types (hold no Value pointer).
LEAVES = {
    "llvm::StringRef": "a (pointer, length) view of characters — no Value",
    "llvm::DebugLoc": "a metadata tracking reference — no Value",
}
# Self-cleaning containers (ScrubOnDelete.h). `Map` also has its MAPPED type walked.
SCRUB_KEYS_ONLY = {"cq::scrub::Set", "cq::scrub::List", "cq::scrub::PairSet"}
SCRUB_MAP = "cq::scrub::Map"
PROJECT_NS = "cq::"

BUILTINS = {
    "void", "bool", "char", "signed char", "unsigned char", "wchar_t", "char8_t",
    "char16_t", "char32_t", "short", "unsigned short", "int", "unsigned int", "long",
    "unsigned long", "long long", "unsigned long long", "__int128",
    "unsigned __int128", "float", "double", "long double", "std::nullptr_t",
    "std::byte",
}


# ----------------------------------------------------------------------------
# toolchain
# ----------------------------------------------------------------------------
def _find_clang():
    env = os.environ.get("CQ_GUARD_CLANG")
    if env:
        return env
    for c in ("/usr/local/opt/llvm@19/bin/clang++", "/opt/homebrew/opt/llvm@19/bin/clang++"):
        if os.access(c, os.X_OK):
            return c
    for name in ("llvm-config-19", "llvm-config"):
        cfg = shutil.which(name)
        if cfg:
            r = subprocess.run([cfg, "--bindir"], capture_output=True, text=True)
            cand = os.path.join(r.stdout.strip(), "clang++")
            if r.returncode == 0 and os.access(cand, os.X_OK):
                return cand
    return None


def _find_llvm_include(clang):
    env = os.environ.get("CQ_GUARD_LLVM_INCLUDE")
    if env:
        return env
    if clang:
        cand = os.path.normpath(os.path.join(os.path.dirname(clang), "..", "include"))
        if os.path.isfile(os.path.join(cand, "llvm", "IR", "Value.h")):
            return cand
    return None


CLANG = None
LLVM_INCLUDE = None
_TRAIT_CACHE = {}


def _toolchain():
    global CLANG, LLVM_INCLUDE
    if CLANG is None:
        CLANG = _find_clang()
    if LLVM_INCLUDE is None:
        LLVM_INCLUDE = _find_llvm_include(CLANG)
    return CLANG, LLVM_INCLUDE


def _clang(tu_dir, tu, extra):
    clang, inc = _toolchain()
    cmd = [clang, "-std=c++17", "-fsyntax-only", "-fno-color-diagnostics",
           "-ferror-limit=0", "-D__STDC_CONSTANT_MACROS", "-D__STDC_FORMAT_MACROS",
           "-D__STDC_LIMIT_MACROS", f"-I{tu_dir}", "-isystem", inc, *extra, tu]
    return subprocess.run(cmd, capture_output=True, text=True)


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
# the type-string parser (over clang's DESUGARED, canonical spelling)
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
    # leading/trailing cv
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
    # trailing array extent
    m = re.match(r"^(.*\S)\s*\[[^\[\]]*\]$", t)
    if m and _balanced(m.group(1)):
        return ("arr", parse_type(m.group(1)))
    # trailing pointer / reference (at depth 0)
    if t.endswith("*") or t.endswith("&"):
        inner = t.rstrip("*&").rstrip()
        if t.endswith("&&"):
            inner = t[:-2].rstrip()
        else:
            inner = t[:-1].rstrip()
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


# ----------------------------------------------------------------------------
# the walk
# ----------------------------------------------------------------------------
class Walk:
    def __init__(self, allowlist):
        self.allowlist = allowlist
        self.errs = []
        self.pointee_q = {}   # type name -> [paths] (need: is it Value-derived?)
        self.named_q = {}     # type name -> [paths] (need: enum? class? Value-derived?)
        self.foreign = {}     # project record name -> [paths] (need its fields)
        self.scrub_fields = []  # (path, name, top_level)
        self.members = 0
        self.seen_paths = set()
        self.walked = set()   # qualified names of records already walked in place

    def field_type(self, path, t, top_level=False, name=None):
        self._t(path, parse_type(t), t, top_level, name)

    def _t(self, path, node, raw, top_level=False, name=None, by_value=True):
        k = node[0]
        if k == "lit":
            return
        if k == "ptr":
            inner = node[1]
            if inner[0] == "ptr":           # T ** : judge the innermost pointee
                return self._t(path, inner, raw, by_value=False)
            if inner[0] in ("named", "tmpl"):
                nm = inner[1] if inner[0] == "named" else None
                if nm is not None and nm in BUILTINS:
                    return
                if inner[0] == "tmpl":
                    self.pointee_q.setdefault(_render(inner), []).append(path)
                else:
                    self.pointee_q.setdefault(nm, []).append(path)
                return
            if inner[0] == "anon":
                return  # pointer to an anonymous record: not a Value
            if inner[0] in ("arr", "fn"):
                self.errs.append(f"{path}: pointer to `{_render(inner)}` — form not "
                                 f"understood by the walker (closed world: refused)")
                return
            return
        if k == "arr":
            return self._t(path, node[1], raw)
        if k == "fn":
            self.errs.append(f"{path}: function type `{node[1]}` — not understood by the "
                             f"walker (closed world: refused)")
            return
        if k == "anon":
            return  # anonymous records are walked as nested definitions
        if k == "tmpl":
            nm = node[1]
            if nm in SCRUB_KEYS_ONLY:
                if name is not None:
                    self.scrub_fields.append((path, name, top_level))
                return
            if nm == SCRUB_MAP:
                if name is not None:
                    self.scrub_fields.append((path, name, top_level))
                if len(node[2]) >= 2:
                    self._t(path + " [ScrubMap MAPPED type]", node[2][1], raw)
                return
            for a in node[2]:
                if a[0] == "named" and a[1] not in BUILTINS:
                    # a class type as a template argument is held BY VALUE as far
                    # as this walk knows (SmallVector<Rec>) — classify it.
                    self._named(path, a[1], via=nm)
                else:
                    self._t(path, a, raw)
            return
        if k == "named":
            self._named(path, node[1])

    def _named(self, path, nm, via=None):
        if nm in BUILTINS:
            return
        if nm in HANDLES or nm in LEAVES:
            return
        if nm.startswith(PROJECT_NS):
            self.foreign.setdefault(nm, []).append(path)
            return
        self.named_q.setdefault(nm, []).append((path, via))


def _render(node):
    k = node[0]
    if k == "ptr":
        return _render(node[1]) + " *"
    if k == "arr":
        return _render(node[1]) + "[]"
    if k == "tmpl":
        return node[1] + "<" + ", ".join(_render(a) for a in node[2]) + ">"
    return node[1]


def _walk_record(W, rec, path, top_level):
    """Walk a CXXRecordDecl JSON node: bases, fields, static members, nested records."""
    W.walked.add(path)
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
            W.field_type(p, t.get("desugaredQualType") or t.get("qualType", ""),
                         top_level=top_level, name=nm)
        elif kind == "CXXRecordDecl" and c.get("completeDefinition"):
            nm = c.get("name")
            _walk_record(W, c, f"{path}::{nm or '(anonymous)'}", top_level=False)
        elif kind == "ClassTemplateDecl":
            for cc in c.get("inner", []) or []:
                if cc.get("kind") == "CXXRecordDecl" and cc.get("completeDefinition"):
                    _walk_record(W, cc, f"{path}::{c.get('name')}<>", top_level=False)


def _dump(tu_dir, name):
    r = _clang(tu_dir, os.path.join(tu_dir, "cq_guard_probe.cpp"),
               ["-Xclang", "-ast-dump=json", "-Xclang", "-ast-dump-filter", "-Xclang", name])
    if r.returncode != 0:
        return None, r.stderr
    return [d for d in _json_docs(r.stdout)
            if d.get("kind") == "CXXRecordDecl" and d.get("name") == name.split("::")[-1]
            and d.get("completeDefinition")], ""


def _traits(tu_dir, names):
    """Ask clang, for each type name: complete? enum? class? Value-derived?
    ValueHandleBase-derived? Returns {name: set(props)} or raises on a compile
    failure that is not one of the property asserts."""
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
    r = _clang(tu_dir, path, [])
    props = {n: set() for n in names}
    other = []
    for line in r.stderr.splitlines():
        m = re.search(r"CQPROP\|(\d+)\|(\w+)", line)
        if m:
            props[names[int(m.group(1))]].add(m.group(2))
        elif " error: " in line:
            other.append(line)
    if other:
        raise RuntimeError("trait probe did not compile:\n  " + "\n  ".join(other[:8]))
    return props


def check(header_src, selftest_src, allowlist, scrub_src=None):
    """-> (errors, members_scanned). Compiles the given texts in a temp include dir."""
    clang, inc = _toolchain()
    if (not clang or not os.access(clang, os.X_OK) or not inc
            or not os.path.isfile(os.path.join(inc, "llvm", "IR", "Value.h"))):
        return ([f"clang++ / LLVM include dir not usable (clang={clang}, include={inc}); "
                 f"pass --clang/--llvm-include or set CQ_GUARD_CLANG / CQ_GUARD_LLVM_INCLUDE "
                 f"— this gate FAILS CLOSED, it never skips"], 0)
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
            first = [l for l in err.splitlines() if " error: " in l][:6]
            return (["the TaintSet header does not compile — refused (fail closed):\n    "
                     + "\n    ".join(first or err.splitlines()[:6])], 0)
        if len(recs) != 1:
            return ([f"expected exactly one complete `TaintSet` definition, found {len(recs)}"], 0)
        W = Walk(allowlist)
        _walk_record(W, recs[0], "cq::TaintSet", top_level=True)
        # foreign project records reached by value: dump and walk each (iterate:
        # a foreign record may itself reach another one)
        while True:
            todo = [n for n in W.foreign if n not in W.walked]
            if not todo:
                break
            with ThreadPoolExecutor(4) as ex:
                dumps = list(ex.map(lambda n: (n, _dump(tmp, n.split("::")[-1])), todo))
            for n, (rs, e) in dumps:
                W.walked.add(n)
                if not rs:
                    W.errs.append(f"{W.foreign[n][0]}: project record `{n}` held by value, "
                                  f"but no complete definition was found — refused")
                    continue
                for r in rs:
                    _walk_record(W, r, n, top_level=False)
        # ask clang about every named type and every pointee
        names = set(W.named_q) | set(W.pointee_q) | set(HANDLES)
        # Trait answers for llvm::/std:: types do not depend on the header under
        # test, so they are cached across calls (the self-test's mutants).
        cached = {n: _TRAIT_CACHE[n] for n in names if n in _TRAIT_CACHE}
        ask = names - set(cached)
        try:
            props = dict(cached)
            if ask:
                fresh = _traits(tmp, ask)
                props.update(fresh)
                for n, v in fresh.items():
                    if n.startswith(("llvm::", "std::")):
                        _TRAIT_CACHE[n] = v
        except RuntimeError as ex:
            return ([str(ex)], W.members)
        for h, why in HANDLES.items():
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
                                  f"({', '.join(sorted(HANDLES))}) — refused")
                else:
                    W.errs.append(f"{path}: record type `{n}`"
                                  + (f" (template argument of `{via}`)" if via else "")
                                  + " is not a scalar, an approved handle/leaf, a scrub:: "
                                  "container or a project record — closed world: approve it "
                                  "in taintset_scrub_guard.py with a reason, or change the type")
        # allowlist staleness
        for a in allowlist:
            if a not in W.seen_paths:
                W.errs.append(f"stale allowlist entry `{a}`: no such member")
        # selftest coverage, comments stripped
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
# mutant self-test: both Rule-13 fool corpora + the first guard's own mutants
# ----------------------------------------------------------------------------
EXTRA_INCLUDES = """#include <array>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <unordered_map>
#include <utility>
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/IR/ValueHandle.h"
"""
ANCH = "struct TaintSet {"
RAW = "RAW POINTER"
BYVAL = "held BY VALUE"
REC = "closed world"
COV = "not exercised"
STALE = "stale allowlist"
NOT_HANDLE = "not on the approved list"


def _mutants(hdr, st, sc):
    def ins(member, pre=""):
        assert hdr.count(ANCH) == 1
        h = hdr.replace("#include <set>\n", "#include <set>\n" + EXTRA_INCLUDES, 1)
        assert h != hdr, "include anchor missing"
        return h.replace(ANCH, pre + ANCH + "\n  " + member, 1)
    M = []  # (label, header, selftest, scrubhdr, allowlist, expected-substring or None)
    AL = ALLOWLIST
    M += [("NULL: pristine tree", hdr, st, sc, AL, None),
          ("NULL: pristine + the mutants' extra includes", ins(""), st, sc, AL, None)]
    # -- the first guard's own mutants (incl. mutation-matrix M11)
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
    ]
    # -- r1A guard_bypass.py (each with the declarations it needs, so the kill is
    #    for the right reason and not a compile error)
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
        # extra spellings this rewrite adds
        ("new: static data member", ins("static inline llvm::Value *Global = nullptr;"), st, sc, AL, RAW),
        ("new: Value** double pointer", ins("llvm::Value **PP = nullptr;"), st, sc, AL, RAW),
        ("new: C array of raw pointers", ins("llvm::Instruction *Arr[4] = {};"), st, sc, AL, RAW),
        ("new: unknown non-template record", ins("llvm::APInt Big;"), st, sc, AL, REC),
    ]
    return M


def selftest(jobs=6):
    hdr = open(HEADER).read()
    st = open(SELFTEST).read()
    sc = open(SCRUB_HDR).read()
    muts = _mutants(hdr, st, sc)

    def run(m):
        label, h, s, x, al, expect = m
        errs, n = check(h, s, al, x)
        return label, expect, errs, n

    with ThreadPoolExecutor(jobs) as ex:
        res = list(ex.map(run, muts))
    bad = []
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
    print(f"taintset_scrub_guard selftest: {len(muts) - nm} null controls, {nm} mutants, "
          f"{len(bad)} failed")
    return 1 if bad else 0


def main():
    args = sys.argv[1:]
    global CLANG, LLVM_INCLUDE
    if "--clang" in args:
        CLANG = args[args.index("--clang") + 1]
    if "--llvm-include" in args:
        LLVM_INCLUDE = args[args.index("--llvm-include") + 1]
    if "--selftest" in args:
        return selftest()
    errs, n = check(open(HEADER).read(), open(SELFTEST).read(), ALLOWLIST, open(SCRUB_HDR).read())
    for e in errs:
        print("taintset_scrub_guard: " + e)
    clang, inc = _toolchain()
    print(f"taintset_scrub_guard: {n} TaintSet members walked (compiler: {clang}), "
          f"{len(errs)} problem(s), {len(ALLOWLIST)} allowlisted")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
