#!/usr/bin/env python3
"""taintset_scrub_guard.py — the STRUCTURAL half of bd test_C_libtooling-8e5r /
-j8sk's pin. A record gate (pure Python, no plugin), like keepset_vendor_check.

`cq::TaintSet` (ir-pass/include/TaintPropagation.h) is where every stage keeps
pointers to IR values across stages that ERASE IR. Since bd 8e5r every such
table is a self-cleaning container (`ir-pass/include/ScrubOnDelete.h`): a key
whose Value is deleted is dropped by LLVM's own `~Value()` callback, so a later
allocation at the freed address can never answer "tainted". That holds only
while NOBODY ADDS A RAW ONE BACK. This gate fails when:

  (1) a member (at any nesting depth inside `struct TaintSet`) is a raw
      pointer-bearing container or a raw pointer — `SmallPtrSet<T *>`,
      `DenseMap<T *, ...>`, `DenseSet<...*...>`, `std::set<T *>`,
      `SmallVector<T *>`, `std::vector<T *>`, `std::map`, `MapVector`,
      `SetVector`, `T *Field;` — unless it is on the ALLOWLIST below with a
      written reason;
  (2) an ALLOWLIST entry no longer names a member (a stale allowlist is how an
      exemption outlives its reason);
  (3) a self-cleaning member is NOT exercised by `ir-pass/tools/scrub_selftest.cpp`
      (`T.<Name>` must appear there), so the per-member deterministic pin cannot
      silently skip a new table;
  (4) one of the ALIASES this scan accepts as "self-cleaning" by NAME
      (`TaintedValueSet`, `ScrubPtrSet`, `ScrubMap`, `ScrubCallList`,
      `SpineOpSet`) no longer resolves to a `scrub::` container in
      `ScrubOnDelete.h`. ⚠ This clause exists because the mutation matrix FOUND
      THE HOLE: retargeting `using TaintedValueSet = std::set<llvm::Value *>;`
      (mutant M11) reverted `Tainted` to a raw set and this gate still reported 0
      problems — it trusted the spelling of the member's type. (The self-test
      failed to compile and three pass-level pins went red; the gate did not.)

Handle-typed members (`WeakVH`, `WeakTrackingVH`, records made only of them)
are fine by construction: they null or follow on deletion themselves.

Its own mutant validation is `--selftest`: it feeds the scanner a raw member, a
raw field in a nested record, a foreign record list, a stale allowlist, an
unexercised wrapped member and three retargeted/deleted aliases, and requires
each to fail.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEADER = os.path.join(ROOT, "ir-pass", "include", "TaintPropagation.h")
SELFTEST = os.path.join(ROOT, "ir-pass", "tools", "scrub_selftest.cpp")
SCRUB_HDR = os.path.join(ROOT, "ir-pass", "include", "ScrubOnDelete.h")

# Alias -> what its right-hand side must start with (clause 4).
ALIASES = {
    "TaintedValueSet": r"scrub::Set\s*<",
    "ScrubPtrSet": r"scrub::Set\s*<",
    "ScrubMap": r"scrub::Map\s*<",
    "ScrubCallList": r"scrub::List\s*<",
    "SpineOpSet": r"ScrubPtrSet\s*<",
}

# member name -> reason it may stay a raw pointer container.
ALLOWLIST = {
    "RestoringRoutes": (
        "has NO WRITER anywhere in ir-pass/src (grep `RestoringRoutes.push_back` / "
        "`.emplace_back` finds nothing since drbq Inc 2a); its two readers iterate an "
        "always-empty container. The day it gains a writer it must become "
        "handle-typed or a scrub:: container, and this entry must go."),
    "BreakRegions": (
        "a per-loop RECORD (`LoopBreakRegion`, LoopPlan.h) of raw block/value/`Loop *` "
        "pointers that `lowerLoops` writes and `lowerBreakReversePlay` dereferences — "
        "never a table asked by IDENTITY, so a fresh object at a freed address cannot "
        "answer a membership question through it. Its hazard is a different one (a "
        "dangling RECORD field, UAF-on-read) and is NOT closed by bd 8e5r; filed as "
        "bd test_C_libtooling-emof."),
}

# Element types that are safe by construction (value handles) or are structs
# defined INSIDE TaintSet (whose own fields this gate scans).
HANDLE_TYPES = {"WeakVH", "WeakTrackingVH", "AssertingVH", "TrackingVH", "CallbackVH"}

WRAPPED = re.compile(r"\b(ScrubPtrSet|ScrubMap|ScrubCallList|TaintedValueSet|SpineOpSet|scrub::\w+)\b")
RAW_CONTAINER = re.compile(
    r"\b(SmallPtrSet|DenseMap|DenseSet|SmallDenseMap|SmallDenseSet|SmallVector|SmallSetVector|"
    r"SetVector|MapVector|ValueMap|set|map|unordered_set|unordered_map|vector|list|deque)\s*<")


def strip_comments(src):
    # ONE left-to-right pass: a `/*` inside a `//` comment (e.g. "`cqrt_*`/...")
    # must not open a block comment — a two-regex strip got that wrong and ate
    # part of a member declaration (caught by printing the scanned members).
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


def taintset_body(src):
    m = re.search(r"\bstruct\s+TaintSet\s*\{", src)
    if not m:
        raise SystemExit("taintset_scrub_guard: `struct TaintSet {` not found")
    i, depth = m.end(), 1
    start = i
    while depth:
        c = src[i]
        depth += c == "{"
        depth -= c == "}"
        i += 1
    return src[start:i - 1]


def members(body):
    """Yield (name, declaration) for every data-member statement at any depth."""
    # A frame stack: True for a nested `struct`/`class` body (its statements are
    # data members), False for an inline function body (its statements are code).
    stmt, frames, out = "", [], []
    for c in body:
        if c == "{":
            frames.append(bool(re.search(r"\b(struct|class)\s+\w+\s*$", stmt)))
            stmt = ""
            continue
        if c == "}":
            frames.pop()
            stmt = ""
            continue
        if not all(frames):
            continue
        if c == ";":
            s = " ".join(stmt.split())
            stmt = ""
            if not s or "(" in s or s.startswith(("using ", "typedef ", "friend ", "static_assert")):
                continue
            s = re.sub(r"\s*=.*$", "", s)  # drop a default member initializer
            m = re.search(r"(\w+)\s*$", s)
            if m:
                out.append((m.group(1), s))
            continue
        stmt += c
    return out


def check_aliases(scrub_src):
    """Clause (4): every alias this scan trusts BY NAME must still name a
    scrub:: container (or another trusted alias) in ScrubOnDelete.h."""
    errs = []
    src = strip_comments(scrub_src)
    for alias, rhs in ALIASES.items():
        m = re.search(r"\busing\s+" + alias + r"\s*=\s*(.*?);", src, flags=re.S)
        if not m:
            errs.append(f"alias `{alias}` is not defined in ScrubOnDelete.h")
        elif not re.match(rhs, m.group(1).strip()):
            errs.append(f"alias `{alias}` no longer names a self-cleaning container: "
                        f"`{' '.join(m.group(1).split())}`")
    return errs


def check(header_src, selftest_src, allowlist, scrub_src=None):
    errs = check_aliases(scrub_src if scrub_src is not None else open(SCRUB_HDR).read())
    body = taintset_body(strip_comments(header_src))
    decls = members(body)
    names = {n for n, _ in decls}
    nested = set(re.findall(r"\bstruct\s+(\w+)\s*\{", body))
    for name, d in decls:
        wrapped = bool(WRAPPED.search(d))
        rawish = bool(RAW_CONTAINER.search(d)) and "*" in d
        rawptr = (not RAW_CONTAINER.search(d)) and re.search(r"\*\s*\w+\s*$", d)
        if wrapped:
            if not re.search(r"\bT\." + re.escape(name) + r"\b", selftest_src):
                errs.append(f"self-cleaning member `{name}` is not exercised by scrub_selftest.cpp")
            continue
        if (rawish or rawptr) and name not in allowlist:
            errs.append(f"raw pointer-bearing member `{name}`: `{d}` — use a scrub:: container "
                        f"(ScrubOnDelete.h) or a value handle, or allowlist it with a reason")
            continue
        # A container of a NAMED element type defined elsewhere may carry raw
        # pointers this scanner cannot see: it must be a handle type, a struct
        # defined inside TaintSet, or allowlisted.
        m = RAW_CONTAINER.search(d)
        if m and not rawish and name not in allowlist:
            elems = re.findall(r"(?:llvm::)?([A-Z]\w*)\s*[,>]", d[m.end():])
            foreign = [e for e in elems if e not in HANDLE_TYPES and e not in nested]
            if foreign:
                errs.append(f"member `{name}` holds records of `{foreign[0]}` (defined outside "
                            f"TaintSet, fields unscanned): `{d}` — allowlist it with a reason")
    for name in allowlist:
        if name not in names:
            errs.append(f"stale allowlist entry `{name}`: no such TaintSet member")
    return errs, len(decls)


def selftest():
    hdr = open(HEADER).read()
    st = open(SELFTEST).read()
    sc = open(SCRUB_HDR).read()
    base, _ = check(hdr, st, ALLOWLIST, sc)
    assert not base, f"selftest needs a clean tree first: {base}"
    cases = {
        "raw member": (hdr.replace("struct TaintSet {", "struct TaintSet {\n  llvm::SmallPtrSet<llvm::Value *, 4> NewRaw;", 1), st, ALLOWLIST),
        "raw pointer field": (hdr.replace("struct TaintSet {", "struct TaintSet {\n  llvm::Value *Stray = nullptr;", 1), st, ALLOWLIST),
        "stale allowlist": (hdr, st, dict(ALLOWLIST, Gone="x")),
        "unexercised wrapped": (hdr.replace("struct TaintSet {", "struct TaintSet {\n  ScrubPtrSet<llvm::Value *, 4> NewWrapped;", 1), st, ALLOWLIST),
        "raw revert of Tainted": (hdr.replace("TaintedValueSet Tainted;", "std::set<llvm::Value *> Tainted;", 1), st, ALLOWLIST),
        "raw field in a nested record": (hdr.replace("struct CmpCondRead {", "struct CmpCondRead {\n    llvm::Instruction *RawRead = nullptr;", 1), st, ALLOWLIST),
        "foreign record list": (hdr.replace("struct TaintSet {", "struct TaintSet {\n  llvm::SmallVector<LoopBreakRegion, 2> OtherRegions;", 1), st, ALLOWLIST),
    }
    # Clause (4) mutants act on ScrubOnDelete.h, the TaintSet header unchanged.
    # "alias retargeted" is mutation-matrix mutant M11, which this gate MISSED
    # before clause (4) existed.
    alias_cases = {
        "alias retargeted to a raw std::set (M11)": sc.replace(
            "using TaintedValueSet = scrub::Set<std::set<llvm::Value *>, llvm::Value *>;",
            "using TaintedValueSet = std::set<llvm::Value *>;", 1),
        "ScrubMap retargeted to a raw DenseMap": sc.replace(
            "using ScrubMap = scrub::Map<KeyT, ValT>;",
            "using ScrubMap = llvm::DenseMap<KeyT, ValT>;", 1),
        "alias deleted": sc.replace("using SpineOpSet = ScrubPtrSet<const llvm::CallInst *, 16>;", "", 1),
    }
    for label, text in alias_cases.items():
        assert text != sc, f"alias mutant {label!r} did not apply"
        cases[label] = (hdr, st, ALLOWLIST, text)
    bad = []
    for label, args in cases.items():
        h, s, a = args[:3]
        e, _ = check(h, s, a, args[3] if len(args) > 3 else sc)
        print(f"  mutant {label!r}: {'KILLED' if e else 'MISSED'}")
        if not e:
            bad.append(label)
    print(f"taintset_scrub_guard selftest: {len(cases)} mutants, {len(bad)} missed")
    return 1 if bad else 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    errs, n = check(open(HEADER).read(), open(SELFTEST).read(), ALLOWLIST)
    for e in errs:
        print("taintset_scrub_guard: " + e)
    print(f"taintset_scrub_guard: {n} TaintSet members scanned, {len(ALIASES)} aliases "
          f"verified, {len(errs)} problem(s), {len(ALLOWLIST)} allowlisted")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
