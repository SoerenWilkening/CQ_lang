#!/usr/bin/env python3
"""census_common.py — shared corpus + lowered-IR plumbing for the record-family
Increment-0 censuses (bd test_C_libtooling-6uqc plan of record, Inc 0).

WHAT THIS FILE IS
=================
Measurement infrastructure ONLY. Nothing here changes the pass, the runtime or
any test; the whole record-family Inc 0 is a spike whose deliverable is a set of
NUMBERS and the commands that reproduce them. It exists because this project's
second failure mode (after the verify-clean silent miscompile) is a number that
measures the WRONG PROGRAM — the retired `165/174` class — so every census below
is built to be re-run, not hand-copied.

WHAT IT MEASURES
----------------
Nothing on its own. It provides:

  * `lit_fixtures()` / `e2e_slices()` — the two corpora, DERIVED, never listed by
    hand: the lit corpus is a glob of `ir-pass/test/*.ll`; the e2e corpus is read
    out of `ctest --show-only=json-v1`, so a slice's real per-slice flags
    (single-TU `run_slice.sh` vs multi-TU `run_slice_multi.sh`, its `-include`
    set, its lib TUs) come from the harness that actually runs it rather than
    from a guess about CMakeLists.
  * `lower()` — stage 1 (+ llvm-link for multi-TU) + stage 2 (`cq-opt
    -passes=cq-lowering`) into a content-addressed cache under
    `build/.record_census/`. Returns `(rc, path_or_None, stderr)`. A module that
    DECLINES produces NO lowered IR (measured: `opt` exits non-zero and writes
    nothing), which is why census 0.4 cannot use this layer at all and works on
    the pre-lowering IR instead.
  * `fpc` — the `tools/free_pairing_check.py` module, imported wholesale. Rule
    14: that file already owns an exact line-oriented LLVM-IR parser
    (`parse_module`, `Call`, `Function`, `balanced`, `split_args`, `norm_arg`)
    AND the authoritative per-symbol effect model (`classify`). Re-spelling
    either here is how two predicates drift apart (the bd `uow0` lesson), so the
    censuses import them instead.

APPROXIMATION DIRECTIONS (read before quoting any number built on this)
----------------------------------------------------------------------
1. PROGRAM ORDER IS TEXTUAL ORDER WITHIN A FUNCTION. `parse_module` gives blocks
   and a CFG; the censuses linearise a function's calls in source-text order.
   For the shapes that matter this is exact — control lowering FLATTENS its
   regions, so the interesting modules are single-block — but a module with
   surviving control flow (a lowered loop, a classical branch) can have a call
   that textually precedes another and dynamically follows it. Every census
   reports the multi-block function count so the reader can size that.
   DIRECTION: unknown-sign. It is NOT silently one-way, so it is reported.
2. INTERPROCEDURAL EDGES ARE NOT FOLLOWED. A handle passed into a Phase-6 clone
   (`@__cq_q_*`) is opaque here. DIRECTION: UNDER-counts records.
3. `_inv` MINTS ARE UNNAMED. `cq_template_..._inv(args) -> %r` writes a rail the
   signature does not name (the bd 8txa gap). Where an `_inv` could be the
   discharge of a record, the census reports the count BOTH ways.
4. THE LIT CORPUS IS HAND-WRITTEN IR. Several fixtures declare `@cqrt_*` or
   `@cq_template_*` prototypes with deliberately off-ABI signatures to probe a
   guard. Those parse fine and are counted like any other call; a census hit on
   a fixture whose whole point is a malformed prototype is an artefact of the
   fixture, not of the compiler. Per-module lists are emitted for exactly this
   reason.

HOW TO RE-RUN
-------------
    python3 tools/record_census/census_common.py --selftest
prints the corpus sizes and how many modules lower, and is the cheapest check
that the plumbing still resolves the toolchain. Every census script takes
`--json <path>` and `--repo <path>`; with no arguments they assume the repo root
is two levels above this file.

The cache lives under `build/.record_census/` (build/ is .gitignore'd, so
`rm -rf build` is a full reset). It is keyed by SHA-256 of (cq-opt bytes, the
input .ll/.c bytes, the flag string), never by timestamp — a stale hit would not
make a census slow, it would make it LIE.
"""

import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))

LLVM_BIN = "/usr/local/opt/llvm@19/bin"


# ---------------------------------------------------------------------------
# free_pairing_check.py, imported as a module (Rule 14 — do not re-spell its
# parser or its effect model).
# ---------------------------------------------------------------------------

def _load_fpc(repo=REPO):
    path = os.path.join(repo, "tools", "free_pairing_check.py")
    spec = importlib.util.spec_from_file_location("cq_free_pairing_check", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


fpc = _load_fpc()


# ---------------------------------------------------------------------------
# Toolchain resolution.
# ---------------------------------------------------------------------------

def tools(repo=REPO):
    """(cq_opt, plugin, clang, llvm_link). cq-opt is preferred over stock opt:
    identical `-passes=cq-lowering` pipeline, 0.124s vs 0.345s fixed spawn cost,
    and gated equivalent over all lit fixtures (CLAUDE.md Build & Test)."""
    cq_opt = os.path.join(repo, "build", "ir-pass", "cq-opt")
    plugin = os.path.join(repo, "build", "ir-pass", "libCQPass.so")
    clang = os.path.join(LLVM_BIN, "clang")
    llvm_link = os.path.join(LLVM_BIN, "llvm-link")
    if not os.path.exists(cq_opt):
        cq_opt = os.path.join(LLVM_BIN, "opt")
    for p in (cq_opt, plugin, clang):
        if not os.path.exists(p):
            raise SystemExit(f"census: missing tool {p} — build the tree first "
                             f"(cmake --build build -j8)")
    return cq_opt, plugin, clang, llvm_link


def cache_dir(repo=REPO):
    d = os.path.join(repo, "build", ".record_census")
    os.makedirs(d, exist_ok=True)
    return d


def _sha(*parts):
    h = hashlib.sha256()
    for p in parts:
        if isinstance(p, str):
            p = p.encode()
        h.update(p)
        h.update(b"\0")
    return h.hexdigest()


_TOOL_KEY = None


def tool_key(repo=REPO):
    global _TOOL_KEY
    if _TOOL_KEY is None:
        cq_opt, plugin, clang, _ = tools(repo)
        with open(cq_opt, "rb") as f:
            a = hashlib.sha256(f.read()).hexdigest()
        with open(plugin, "rb") as f:
            b = hashlib.sha256(f.read()).hexdigest()
        _TOOL_KEY = _sha(a, b, clang)
    return _TOOL_KEY


# ---------------------------------------------------------------------------
# Corpus 1 — the lit fixtures.
# ---------------------------------------------------------------------------

_RUN_RE = re.compile(r"^\s*;\s*RUN:\s*(.*)$")


def lit_fixtures(repo=REPO):
    """[(name, path, is_negative)] over ir-pass/test/*.ll.

    `is_negative` is the fixture's OWN declaration (a `RUN:` line that runs
    `%cq-opt` under `not`), not an inference from behaviour — census 0.4 needs
    the declared intent, and `lower()` independently reports the actual exit
    code, so a disagreement between the two is itself visible.
    """
    d = os.path.join(repo, "ir-pass", "test")
    out = []
    for fn in sorted(os.listdir(d)):
        if not fn.endswith(".ll"):
            continue
        path = os.path.join(d, fn)
        with open(path, "r", errors="replace") as f:
            text = f.read()
        neg = False
        for line in text.split("\n"):
            m = _RUN_RE.match(line)
            if not m:
                continue
            cmd = m.group(1)
            # `not %cq-opt …`, `not env … %cq-opt …`, `env … not %cq-opt …`
            if re.search(r"\bnot\b[^|]*%cq-opt", cmd):
                neg = True
        out.append((fn[:-3], path, neg))
    return out


# ---------------------------------------------------------------------------
# Corpus 2 — the e2e slices, read out of the configured ctest.
# ---------------------------------------------------------------------------

def e2e_slices(repo=REPO):
    """[dict] describing every e2e entry that actually compiles a slice.

    Derived from `ctest --show-only=json-v1` in build/, so the per-slice flags
    are the ones the harness really uses. Entries that are not slice runs
    (the free-pairing selftest, the vendor/census python gates) are dropped and
    reported by `kind='non-slice'`.
    """
    build = os.path.join(repo, "build")
    try:
        raw = subprocess.run(["ctest", "--show-only=json-v1"], cwd=build,
                             capture_output=True, text=True, check=True).stdout
    except Exception as exc:  # pragma: no cover - environment problem
        raise SystemExit(f"census: could not enumerate ctest entries: {exc}")
    data = json.loads(raw)
    out = []
    for t in data.get("tests", []):
        name = t.get("name", "")
        cmd = t.get("command", [])
        if not name.startswith("e2e-"):
            continue
        script = next((c for c in cmd if c.endswith("run_slice.sh")
                       or c.endswith("run_slice_multi.sh")), None)
        if script is None:
            out.append({"name": name, "kind": "non-slice"})
            continue
        i = cmd.index(script)
        a = cmd[i + 1:]
        if script.endswith("run_slice_multi.sh"):
            # CLANG OPT LLVMLINK PASS INC CQSRC LIBSRCS RT TPL GOLDEN [FLAGS]
            out.append({"name": name, "kind": "multi", "clang": a[0],
                        "llvm_link": a[2], "inc": a[4], "src": a[5],
                        "libsrcs": [s for s in a[6].split() if s],
                        "golden": a[9]})
        else:
            # CLANG OPT PASS INC SRC RT TPL GOLDEN [FLAGS]
            out.append({"name": name, "kind": "single", "clang": a[0],
                        "inc": a[3], "src": a[4], "golden": a[7]})
    return out


# ---------------------------------------------------------------------------
# Lowering.
# ---------------------------------------------------------------------------

def _run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def _cached(key, repo, suffix=".ll"):
    return os.path.join(cache_dir(repo), key + suffix)


def lower_ll(path, repo=REPO):
    """Run `cq-opt -passes=cq-lowering` on a .ll. -> (rc, out_path|None, stderr)."""
    cq_opt, plugin, _, _ = tools(repo)
    with open(path, "rb") as f:
        key = _sha(tool_key(repo), "ll", f.read())
    outp = _cached(key, repo)
    errp = _cached(key, repo, ".err")
    rcp = _cached(key, repo, ".rc")
    if os.path.exists(rcp):
        rc = int(open(rcp).read())
        err = open(errp, errors="replace").read() if os.path.exists(errp) else ""
        return rc, (outp if rc == 0 and os.path.exists(outp) else None), err
    r = _run([cq_opt, "-load-pass-plugin", plugin, "-passes=cq-lowering",
              "-S", path, "-o", outp])
    with open(errp, "w") as f:
        f.write(r.stderr)
    with open(rcp, "w") as f:
        f.write(str(r.returncode))
    if r.returncode != 0 and os.path.exists(outp):
        os.remove(outp)
    return r.returncode, (outp if r.returncode == 0 else None), r.stderr


def stage1_ll(slice_info, repo=REPO):
    """Stage 1 (+ llvm-link for multi-TU) for an e2e slice -> (path|None, err).

    This is the PRE-LOWERING module — the IR the pass is handed. Census 0.4 uses
    it because a declining module yields no lowered IR at all.
    """
    _, _, clang, llvm_link = tools(repo)
    parts = [("src", slice_info["src"])] + [("lib", p)
                                            for p in slice_info.get("libsrcs", [])]
    blobs = []
    for _, p in parts:
        with open(p, "rb") as f:
            blobs.append(f.read())
    key = _sha(tool_key(repo), "s1", slice_info["src"], *blobs)
    outp = _cached(key, repo, ".s1.ll")
    errp = _cached(key, repo, ".s1.err")
    if os.path.exists(errp):
        err = open(errp, errors="replace").read()
        return (outp if os.path.exists(outp) else None), err
    tmp = os.path.join(cache_dir(repo), "tmp." + key)
    os.makedirs(tmp, exist_ok=True)
    try:
        inc = slice_info["inc"]
        cq_ll = os.path.join(tmp, "cq.ll")
        r = _run([clang, "-I" + inc, "-include", "CQ.h", "-O1", "-emit-llvm",
                  "-S", slice_info["src"], "-o", cq_ll])
        if r.returncode != 0:
            with open(errp, "w") as f:
                f.write(r.stderr)
            return None, r.stderr
        link_in = [cq_ll]
        for i, lib in enumerate(slice_info.get("libsrcs", [])):
            lib_ll = os.path.join(tmp, f"lib_{i}.ll")
            r = _run([clang, "-I" + inc, "-O1", "-emit-llvm", "-S", lib,
                      "-o", lib_ll])
            if r.returncode != 0:
                with open(errp, "w") as f:
                    f.write(r.stderr)
                return None, r.stderr
            link_in.append(lib_ll)
        if len(link_in) > 1:
            r = _run([llvm_link, "-S"] + link_in + ["-o", outp])
            if r.returncode != 0:
                with open(errp, "w") as f:
                    f.write(r.stderr)
                return None, r.stderr
        else:
            shutil.copyfile(cq_ll, outp)
        with open(errp, "w") as f:
            f.write("")
        return outp, ""
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def lower_slice(slice_info, repo=REPO):
    """Stage 1 + stage 2 for an e2e slice. -> (rc, out_path|None, stderr)."""
    s1, err = stage1_ll(slice_info, repo)
    if s1 is None:
        return 127, None, "stage-1 failed: " + err
    return lower_ll(s1, repo)


# ---------------------------------------------------------------------------
# Lowered-IR call stream helpers, shared by 0.1 and 0.2.
# ---------------------------------------------------------------------------

class LoweredFn:
    """A function's calls in SOURCE-TEXT order, with the raw line text kept.

    `calls` is the linearisation described in APPROXIMATION 1 above. `nblocks`
    lets a census report how much of its corpus is genuinely straight-line.
    """

    def __init__(self, fn, lines):
        self.name = fn.name
        self.fn = fn
        self.nblocks = len(fn.blocks)
        self.calls = []
        for _, calls, _ in fn.blocks:
            self.calls.extend(calls)
        self.calls.sort(key=lambda c: c.line)
        self.lines = lines
        # 1-based [start, end] raw line range of this `define`, so a census can
        # scan for USES the call parser does not model (`ret`, `store`, `phi`,
        # an `icmp` on a handle). Filled by `parse_lowered`.
        self.start_line = 0
        self.end_line = 0

    def raw_lines(self):
        """[(lineno, text)] for the body of this define, 1-based linenos."""
        return [(n, self.lines[n - 1])
                for n in range(self.start_line, self.end_line + 1)
                if 0 < n <= len(self.lines)]


_DEFINE_LINE_RE = re.compile(r"^define\s.*?@([\w.$\"]+)\s*\(")


def _define_ranges(lines):
    """[(name, start_lineno, end_lineno)] over a whole .ll, 1-based inclusive."""
    out, i = [], 0
    while i < len(lines):
        m = _DEFINE_LINE_RE.match(lines[i])
        if m:
            start = i + 1
            j = i + 1
            while j < len(lines) and lines[j] != "}":
                j += 1
            out.append((m.group(1).strip('"'), start, j + 1))
            i = j + 1
        else:
            i += 1
    return out


def parse_lowered(path):
    """-> (text, [LoweredFn])."""
    with open(path, "r", errors="replace") as f:
        text = f.read()
    lines = text.split("\n")
    fns = [LoweredFn(fn, lines) for fn in fpc.parse_module(text)]
    ranges = _define_ranges(lines)
    # `parse_module` and `_define_ranges` walk the same `define` lines in the
    # same order, so position-matching is exact; assert it rather than assume it
    # (a silent mismatch would give a census the WRONG function's line range,
    # which is the "measures the wrong program" failure mode in miniature).
    if len(ranges) == len(fns):
        for lf, (nm, a, b) in zip(fns, ranges):
            if lf.name != nm:
                raise SystemExit(f"census: define-order mismatch in {path}: "
                                 f"{lf.name} vs {nm}")
            lf.start_line, lf.end_line = a, b
    else:
        raise SystemExit(f"census: define-count mismatch in {path}: "
                         f"{len(fns)} parsed vs {len(ranges)} raw")
    return text, fns


_TEMPLATE_MINT = re.compile(r"^cq_template_.*(?<!_unc)(?<!_inv)$")


def mint_kind(call):
    """'alloc' | 'record' | 'inv' | 'tape' | 'array' | None.

    'record' is the census's RECORD class exactly as the plan of record defines
    it: a `cq_template_*` result or a `cqrt_qram_load_<W>` result. `cqrt_alloc_*`
    rails are deliberately NOT records (Rule 6 legitimately leaves one allocated,
    and four committed fixtures declare that leak correct) — but every census
    below ALSO reports them separately, because an alloc-minted ancestor of a
    chained theta is still physically a live entangled record (bd nepx's h0).
    """
    if call.res is None:
        return None
    s = call.sym
    if re.fullmatch(rf"cqrt_alloc_{fpc._W}", s) or s == "cqrt_alloc_handle":
        return "alloc"
    if re.fullmatch(rf"cqrt_qram_alloc_{fpc._W}", s):
        return "array"
    if s == "cqrt_tape_alloc" or re.fullmatch(
            rf"cqrt_tape_write_{fpc._W}(_controlled)?", s):
        return "tape"
    if re.fullmatch(rf"cqrt_qram_load_{fpc._W}", s):
        return "record"
    if s.startswith("cq_template_") or s.startswith("__cq_q_"):
        if s.endswith("_unc"):
            return None
        if s.endswith("_inv"):
            return "inv"
        return "record"
    return None


def is_in_place_gate(sym):
    return (re.fullmatch(rf"cqrt_(ry|rz)_{fpc._W}", sym) is not None
            or re.fullmatch(rf"cqrt_(addc|xorc)_{fpc._W}", sym) is not None
            or sym in ("cqrt_x", "cqrt_h"))


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if "--selftest" not in argv:
        print(__doc__)
        return 0
    lits = lit_fixtures()
    pos = sum(1 for _, _, n in lits if not n)
    print(f"lit fixtures: {len(lits)} ({pos} positive, {len(lits) - pos} negative)")
    sl = e2e_slices()
    print(f"e2e entries: {len(sl)} "
          f"({sum(1 for s in sl if s['kind'] == 'single')} single, "
          f"{sum(1 for s in sl if s['kind'] == 'multi')} multi, "
          f"{sum(1 for s in sl if s['kind'] == 'non-slice')} non-slice)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
