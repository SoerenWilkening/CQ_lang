"""Per-example verdicts and reports (module chk-report, bead cq-w0-chk-report).

One Verdict per example (contracts.Verdict):

- ``verifier``: ``opt -passes=cq-verify`` over our lowered module.
- ``s6``: §6 against the reference ``lowered.ll`` run in the same evaluator. A textual match after
  normalization short-circuits it (CLAUDE.md "Reports").
- ``c_oracle``: §6 against the C program (the ``.O1.ll`` under the C oracle).
- ``diff_lines``: the size of the normalized textual diff against the reference: a quality signal
  that never fails a verdict. Normalization is our own: the module goes through ``llvm-as`` and
  ``opt -S -discard-value-names`` (LLVM's own local numbering: arguments, then unnamed blocks and
  non-void instructions in textual order, the scheme CQ_spec ``_tools/README.txt`` describes), then
  comments, blank lines, ``; ModuleID`` and ``source_filename`` are dropped and the ``declare`` lines
  are sorted (their order carries no meaning).

Each of ``s6``, ``c_oracle`` and ``verifier`` is one of PASS, FAIL, ERROR or NOT_RUN. Only PASS is
green. ERROR means the check could not be decided (no lowered module, a checker module that is not
built yet, an exception): it is never green. NOT_RUN appears only when the caller asked for one
oracle (``--oracle ref|c``); it is not green either.

The sample set must hold every input class CLAUDE.md "Inputs" requires (cq-h4pn, gaps.py): a class
the sampler left empty without a proof that no input exists, a problem sampling.check_sample_set
finds, a sample outside the C program's domain (sampling.domain_problems) or a trip sample whose
count the C oracle's trip counters do not give (sampling.confirm_trips) turns a §6 check that
passed over that sample set into ERROR (FAIL stays FAIL), each with a ``sampling: ...`` reason.
A class no input can fill (``sampling: impossible: ...``) and the totalization rows the search did
not hit (``sampling: note: ...``) are reasons only. A trip target whose only reaching inputs run past
the checker's cost budget (``sampling: uncovered: ...``, owner ruling 2026-11-01, cq-g8md; CR §6,
coverage) is a reason too, with the inputs the budget stopped and their cost "> budget" (nothing
runs past the budget; an exhausted budget proves nothing, CR §6 of CQ_spec afef520, cq-3nla, cq-hsan). The verdict fields stay
PASS when no comparison failed (the frozen Verdict), but the example's state is UNCOVERED, not green
(state(): owner ruling 2026-11-01, "never counted green"): the gate accepts it (accepted()) when
no comparison failed and every uncovered target is listed; green(), the progress table and the green
counts do not. The table counts such examples apart and shows their first uncovered line, and
``cqcheck run`` and the baseline print them as ``UNCOVERED`` with every such line.

The §6 run composes the sibling checker modules through the functions named in ``SIBLING_API``. A
function that a sibling does not provide yet makes the check ERROR with
``cq: unimplemented: <module>: <function>``; nothing is ever assumed equal. The run_sample entries
are run as their owners' batch forms (cq-3ebz): ``run.run_samples`` and ``oracle.run_samples`` with
``oracle.run_result``, which give each sample the RunResult run_sample would, with one build per
side and the samples in parallel.
"""
from __future__ import annotations

import dataclasses
import difflib
import importlib
import json
import os
import hashlib
import re
import shutil
import subprocess
import threading
import traceback
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Sequence, Tuple

from cqcheck.contracts import Verdict, to_json

PASS, FAIL, ERROR, NOT_RUN = "pass", "fail", "error", "not-run"

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LLVM_BIN = Path("/usr/local/opt/llvm@19/bin")      # CLAUDE.md Pins
LLVM_BIN = Path(os.environ.get("CQ_LLVM_BIN", str(DEFAULT_LLVM_BIN)))
K_CHECK = 4  # CLAUDE.md: both sides run at K = 4.


def spec_dir() -> Path:
    return Path(os.environ.get("CQ_SPEC_DIR", str(ROOT.parent / "CQ_spec"))).resolve()


def build_dir() -> Path:
    return Path(os.environ.get("CQ_BUILD_DIR", str(ROOT / "build"))).resolve()


def plugin_path() -> Path:
    return Path(os.environ.get("CQ_PLUGIN", str(build_dir() / "pass" / "libCQLower.so")))


def out_dir() -> Path:
    """Where `run` keeps its per-example verdicts, lowered modules and diffs (read by `progress`)."""
    return build_dir() / "cqcheck"


# --------------------------------------------------------------------------------------------
# Examples


@dataclass(frozen=True)
class Example:
    name: str        # NN_name, the directory name
    dir: Path

    @property
    def number(self) -> str:
        return self.name.split("_", 1)[0]

    @property
    def base(self) -> str:
        return self.name.split("_", 1)[1]

    @property
    def c(self) -> Path:
        return self.dir / f"{self.base}.c"

    @property
    def o1(self) -> Path:
        return self.dir / f"{self.base}.O1.ll"

    @property
    def reference(self) -> Path:
        return self.dir / f"{self.base}.lowered.ll"


_EXAMPLE_DIR = re.compile(r"^[0-9]{2,}_[A-Za-z0-9_]+$")


def all_examples(spec: Optional[Path] = None) -> List[Example]:
    """Every example of the pinned corpus, counted from the directory."""
    root = (spec or spec_dir()) / "examples"
    out = sorted((Example(d.name, d) for d in root.iterdir() if d.is_dir() and _EXAMPLE_DIR.match(d.name)),
                 key=lambda e: (int(e.number), e.name))
    if not out:
        raise RuntimeError(f"cq: no examples under {root}")
    return out


def resolve_examples(names: Sequence[str], spec: Optional[Path] = None) -> List[Example]:
    """`NN`, `NN_name` or a unique prefix. An unknown or ambiguous name is an error, never skipped."""
    every = all_examples(spec)
    by_name = {e.name: e for e in every}
    out = []
    for n in names:
        n = n.rstrip("/").split("/")[-1]
        if n in by_name:
            out.append(by_name[n])
            continue
        if n.isdigit():
            hits = [e for e in every if int(e.number) == int(n)]
        else:
            hits = [e for e in every if e.name.startswith(n)]
        if len(hits) != 1:
            raise ValueError(f"cq: example {n!r} matches {[e.name for e in hits] or 'nothing'}")
        out.append(hits[0])
    return out


def ours_path(ex: Example, ours: Path) -> Path:
    """Our lowered module for `ex` inside a directory given by --ours. Accepted layouts:
    DIR/NN_name/name.lowered.ll (the corpus layout), DIR/name.lowered.ll, DIR/NN_name.lowered.ll."""
    cands = [ours / ex.name / f"{ex.base}.lowered.ll", ours / f"{ex.base}.lowered.ll",
             ours / f"{ex.name}.lowered.ll"]
    for c in cands:
        if c.is_file():
            return c
    raise FileNotFoundError(f"no lowered module for {ex.name} in {ours} (looked for "
                            + ", ".join(str(c.relative_to(ours)) for c in cands) + ")")


# --------------------------------------------------------------------------------------------
# Tools


def _run(cmd: List[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, **kw)


def _first_error_line(stderr: bytes) -> str:
    text = stderr.decode(errors="replace").strip()
    for line in text.splitlines():
        if "cq: " in line:
            return line.strip()
    return text.splitlines()[0].strip() if text else "(no message)"


_PLUGIN_HASH: Dict[Tuple[str, int, int], str] = {}


def plugin_hash() -> str:
    """sha256 of the pass plugin's bytes (memoized per file state)."""
    p = plugin_path()
    try:
        st = p.stat()
    except OSError:
        return "missing:" + str(p)
    k = (str(p), st.st_mtime_ns, st.st_size)
    if k not in _PLUGIN_HASH:
        _PLUGIN_HASH[k] = hashlib.sha256(p.read_bytes()).hexdigest()
    return _PLUGIN_HASH[k]


def _tool_cache(kind: str, *parts: str) -> Path:
    """The cache entry of one opt run (cq-8m6v): a deterministic function of the plugin's bytes, the
    toolchain and the input text, so a warm run starts no tool. Under $CQE_CACHE (run._cache_root)."""
    from cqcheck import run
    h = hashlib.sha256()
    for x in (kind, plugin_hash(), str(LLVM_BIN), *parts):
        h.update(x.encode() + b"\0")
    return run._cache_root() / kind / h.hexdigest()[:24]


def _publish_entry(final: Path, files: Dict[str, bytes]) -> None:
    tmp = final.with_name(f"{final.name}.{os.getpid()}.{threading.get_ident()}.tmp")
    tmp.mkdir(parents=True, exist_ok=True)
    for n, b in files.items():
        (tmp / n).write_bytes(b)
    try:
        os.replace(tmp, final)
    except OSError:
        shutil.rmtree(tmp, ignore_errors=True)   # another process published the same entry


# Rule 27, rulings Q6: the corpus's root lists, a build input of the lowering.


def lower(ex: Example, dest: Path) -> Tuple[Optional[Path], str]:
    """Our lowering of `ex`: its .O1.ll through `opt -passes=cq-lower` at K = 4. Returns (path, "")
    or (None, the internal error). Nothing is kept from a failed run but the linked input.

    The injection bundle (CR rule 18, CLAUDE.md "Pipeline"; cq-b041) is linked first, as the C oracle
    links it, when the module declares without a body a symbol the bundle defines (oracle.bundle_for):
    `llvm-link -S <.O1.ll> --only-needed <bundle files>` into ``<base>.linked.ll`` beside `dest`, one
    textual unit with the user module first. Otherwise the .O1.ll goes in as clang wrote it."""
    from cqcheck import oracle
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        dest.unlink()
    src = Path(ex.o1)
    text = src.read_text()
    bundle = oracle.bundle_for(text) or oracle.entries_bundle(text)   # owner ruling 2026-11-12: the result entries
    # cached by (plugin, toolchain, K, input, the bundle linked into it): every file the run leaves
    # and its result
    # (the paths too: opt writes its input's path into the module, and messages name them)
    entry = _tool_cache("lower", f"-cq-k-default={K_CHECK}", "\n".join(_example_roots(ex)), str(src), str(dest), text,
                        oracle.bundle_key(bundle) if bundle else "")
    linked_name = f"{ex.base}.linked.ll"
    if not (entry / "result").exists():
        res, err = _lower_uncached(ex, src, bundle, dest)
        files = {"result": ("ok" if res else "err:" + err).encode()}
        if res is not None:
            files["lowered.ll"] = dest.read_bytes()
        if bundle and (dest.parent / linked_name).exists():
            files["linked.ll"] = (dest.parent / linked_name).read_bytes()
        _publish_entry(entry, files)
        return res, err
    if (entry / "linked.ll").exists():
        shutil.copyfile(entry / "linked.ll", dest.parent / linked_name)
    result = (entry / "result").read_text()
    if result != "ok":
        return None, result[4:]
    shutil.copyfile(entry / "lowered.ll", dest)
    return dest, ""


def _example_roots(ex: Example) -> list:
    """CR rule 27: the root list this example links, the `roots=` field of its drivers.txt line."""
    from cqcheck import drivers
    line = drivers.read_drivers_txt().get(ex.name)
    return list(line.roots) if line else []


def _lower_uncached(ex: Example, src: Path, bundle: List[Path], dest: Path) -> Tuple[Optional[Path], str]:
    if bundle:
        from cqcheck import oracle
        linked = dest.parent / f"{ex.base}.linked.ll"
        decls = dest.parent / f"{ex.base}.libm.ll"
        libm = oracle.bundle_libm_decls(src.read_text(), bundle)
        decls.write_text(libm)
        # owner ruling 2026-11-12 (cq-cdf9z; driver/cq_entries.py): the result entries the pass's rewriteDeferredResults
        # calls after this link, declared in a unit that names them in @llvm.compiler.used, linked before the bundle
        ce = oracle._entries_mod()
        text = src.read_text()
        ents = ce.decls(text)
        entf = dest.parent / f"{ex.base}.entries.ll"
        if ents:
            head = "".join(l + "\n" for l in text.splitlines() if l.startswith(("target datalayout", "target triple")))
            used = ", ".join(f"ptr @{n}" for n in ce.names(ents))
            entf.write_text(head + "".join(d + "\n" for d in ents) + f"@llvm.compiler.used = appending global "
                            f'[{len(ents)} x ptr] [{used}], section "llvm.metadata"\n')
        r = _run([str(LLVM_BIN / "llvm-link"), "-S", str(src), *([str(decls)] if libm else []), *([str(entf)] if ents else []),
                  "--only-needed", *map(str, bundle), "-o", str(linked)])
        if r.returncode != 0:
            return None, f"llvm-link with the injection bundle exited {r.returncode}: {_first_error_line(r.stderr)}"
        src = linked
    # CR rule 27, §0: a root list is an input of this example alone; with none a module with no cq_* call passes through.
    roots = _example_roots(ex)
    rootsf = dest.parent / f"{ex.base}.roots"
    if roots:
        rootsf.write_text("\n".join(roots) + "\n")
    r = _run([str(LLVM_BIN / "opt"), f"-load-pass-plugin={plugin_path()}", "-passes=cq-lower",
              f"-cq-k-default={K_CHECK}", *([f"-cq-roots={rootsf}"] if roots else []), "-S", str(src), "-o", str(dest)])
    if r.returncode != 0:
        if dest.exists():
            dest.unlink()
        return None, f"cq-lower exited {r.returncode}: {_first_error_line(r.stderr)}"
    return dest, ""


def verify(lowered: Path, reference: bool = False) -> Tuple[str, str]:
    """The structural verifier (NORTHSTAR principle 4) over our output. `reference=True` runs it in
    reference mode, `cq-verify<reference>` (S1), for a CQ_spec reference lowered.ll."""
    passes = "cq-verify<reference>" if reference else "cq-verify"
    entry = _tool_cache("verify", passes, str(lowered), Path(lowered).read_text())
    if (entry / "result").exists():
        d = json.loads((entry / "result").read_text())
        return d[0], d[1]
    out = _verify_uncached(lowered, passes)
    _publish_entry(entry, {"result": json.dumps(list(out)).encode()})
    return out


def _verify_uncached(lowered: Path, passes: str) -> Tuple[str, str]:
    r = _run([str(LLVM_BIN / "opt"), f"-load-pass-plugin={plugin_path()}", f"-passes={passes}",
              "-disable-output", str(lowered)])
    if r.returncode == 0:
        return PASS, ""
    msg = _first_error_line(r.stderr)
    # The verifier names its check in a report_fatal_error; an unbuilt verifier is not a verdict.
    if "cq: unimplemented:" in msg:
        return ERROR, f"verifier: {msg}"
    return FAIL, f"verifier: {msg}"


# --------------------------------------------------------------------------------------------
# Normalized textual diff


class NormalizeError(Exception):
    pass


def _strip_comment(line: str) -> str:
    in_str = False
    i = 0
    while i < len(line):
        c = line[i]
        if c == '"':
            in_str = not in_str
        elif c == "\\" and in_str:
            i += 1
        elif c == ";" and not in_str:
            return line[:i]
        i += 1
    return line


def normalize(path: Path) -> List[str]:
    """The module as LLVM prints it with value names discarded, minus comments, blank lines,
    `; ModuleID` and `source_filename`, with the `declare` lines sorted after everything else."""
    asm = _run([str(LLVM_BIN / "llvm-as"), "-o", "-", str(path)])
    if asm.returncode != 0:
        raise NormalizeError(f"llvm-as: {_first_error_line(asm.stderr)}")
    r = _run([str(LLVM_BIN / "opt"), "-S", "-discard-value-names", "-passes=verify", "-o", "-"],
             input=asm.stdout)
    if r.returncode != 0:
        raise NormalizeError(f"opt: {_first_error_line(r.stderr)}")
    body, decls = [], []
    for line in r.stdout.decode().splitlines():
        code = _strip_comment(line).rstrip()
        if not code.strip() or code.startswith("source_filename"):
            continue
        (decls if code.startswith("declare ") else body).append(code)
    return body + sorted(decls)


def textual_diff(ours: Path, ref: Path) -> Tuple[int, str]:
    """(number of differing lines, unified diff) between the normalized modules."""
    a, b = normalize(ref), normalize(ours)
    diff = list(difflib.unified_diff(a, b, "reference", "ours", lineterm="", n=2))
    changed = sum(1 for d in diff if d[:1] in "+-" and not d.startswith(("+++", "---")))
    return changed, "\n".join(diff)


# --------------------------------------------------------------------------------------------
# The §6 run, composed from the sibling modules

# The functions the §6 run calls in the sibling checker modules: (module file, owning module, name,
# signature). Proposed in bead cq-w0-chk-report's freeze-rule bead; the owning bead implements it.
# The sibling functions evaluate() calls: a subset of the cross-module API frozen by cq-zew (Z1 in
# cq-arch; tests/checker-api/check_api.py holds the whole frozen list and checks this one against it).
SIBLING_API: List[Tuple[str, str, str, str]] = [
    ("drivers", "chk-drivers", "driver_spec", "(example: str, example_dir: Path) -> DriverSpec"),
    ("sampling", "chk-drivers", "sample_set", "(spec: DriverSpec, example_dir: Path) -> SampleSet"),
    ("run", "chk-core", "run_sample",
     "(lowered: Path, spec: DriverSpec, sample: dict, side: str) -> RunResult"),
    ("oracle", "chk-oracle", "run_sample", "(o1: Path, spec: DriverSpec, sample: dict) -> RunResult"),
    ("compare", "chk-compare", "compare",
     "(ours: Sequence[RunResult], other: Sequence[RunResult], against: str, "
     "classical_key: Optional[Callable[[dict], Hashable]] = None) -> List[str]"),
    ("compare", "chk-compare", "classical_key_from_driver",
     "(driver: DriverSpec) -> Callable[[dict], Hashable]"),
]


class Unimplemented(Exception):
    """A sibling function that is not provided yet: the check is ERROR, never assumed green."""


def sibling(module: str, name: str) -> Callable:
    owner = next((o for m, o, n, _ in SIBLING_API if m == module and n == name), module)
    mod = importlib.import_module(f"cqcheck.{module}")
    fn = getattr(mod, name, None)
    if not callable(fn):
        raise Unimplemented(f"cq: unimplemented: {owner}: {module}.{name}")
    return fn


def _exc_reason(where: str, e: BaseException) -> str:
    if isinstance(e, Unimplemented):
        return f"{where}: {e}"
    tb = traceback.extract_tb(e.__traceback__)
    at = f" at {Path(tb[-1].filename).name}:{tb[-1].lineno}" if tb else ""
    return f"{where}: {type(e).__name__}: {e}{at}"


def _side_results(runner: Callable, path: Path, spec, samples, *extra) -> list:
    """`runner(path, spec, samples, *extra)` runs the whole sample set as one batch (cq-3ebz: one
    build per side, the samples in parallel); one RunResult per sample, in order."""
    samples = list(samples)
    if not samples:
        raise RuntimeError("the sample set is empty")
    results = list(runner(path, spec, samples, *extra))
    if len(results) != len(samples):
        raise RuntimeError(f"{len(results)} results for {len(samples)} samples")
    return results


def _evaluator_batch(lowered: Path, spec, samples, side: str) -> list:
    """Every sample in the evaluator: run.run_samples, each result run.run_sample's (Z1)."""
    return sibling("run", "run_samples")(lowered, spec, samples, side)


def _oracle_batch(o1: Path, spec, samples, raw: Optional[list] = None) -> list:
    """Every sample under the C oracle: oracle.run_samples, each made the RunResult that
    oracle.run_sample (Z1) returns by oracle.run_result. `raw`, when given, receives the
    oracle.SampleRun of each sample (their trip counters confirm the trip class, cq-h4pn)."""
    to_result = sibling("oracle", "run_result")
    runs = list(sibling("oracle", "run_samples")(o1, spec, samples))
    if raw is not None:
        raw.extend(runs)
    return [to_result(r, spec, o1) for r in runs]


def _sample_set_gaps(ex: Example, spec, ss) -> Tuple[List[str], List[str]]:
    """(failing lines, reported lines) of the sample set (cq-h4pn; gaps.py): sampling's own
    acceptance (check_sample_set), the classes it left empty, and every sample inside the C
    program's domain (sampling.domain_problems). A MISSING class or a problem fails; an IMPOSSIBLE
    class and a NOTE are reported only."""
    from cqcheck import gaps
    found = gaps.sample_gaps(spec, ss, ex.dir, LLVM_BIN)
    bad = [g.line() for g in found if g.kind == gaps.MISSING]
    bad += [f"sampling: outside the domain: {p}" for p in gaps.domain_check(spec, ex.dir, ss)]
    return bad, [g.line() for g in found if g.kind != gaps.MISSING]


# An uncut run of a trip sample (55 at m = 2^31 - 1) ends at the oracle's own caps; the hang guard stays out of it.
UNCUT_TIMEOUT_MS = 20000


def _trip_disagreements(ex: Example, spec, ss, c_raw: Optional[list], samples: list) -> List[str]:
    """Each trip sample's count in the C oracle's trip counters (sampling.confirm_trips), from the
    C oracle's runs of the §6 comparison, or from a run of the trip samples alone when the C
    oracle was not asked for."""
    import json
    from cqcheck import gaps
    idx = gaps.trip_samples(ss)
    if not idx:
        return []
    runs = ({json.dumps(s, sort_keys=True): r for s, r in zip(samples, c_raw)} if c_raw is not None else {})
    need = [ss.samples[i] for i in idx if json.dumps(ss.samples[i], sort_keys=True) not in runs]
    if need:
        runs.update(zip((json.dumps(s, sort_keys=True) for s in need),
                        sibling("oracle", "run_samples")(ex.o1, spec, need)))
    # cq-97oj (4): the trip counters count uncut (the K cut applies only to the compared run): each
    # trip sample's trip events with the cutoff off join its compared run's
    import copy
    from cqcheck import sampling
    trip = [ss.samples[i] for i in idx]
    for smp, ur in zip(trip, sibling("oracle", "run_samples")(ex.o1, spec, trip, timeout_ms=UNCUT_TIMEOUT_MS,
                                                                  k=sampling.uncut_k(Path(ex.o1)))):
        key = json.dumps(smp, sort_keys=True)
        r = runs[key]
        r = runs[key] = copy.copy(r)
        r.events = list(r.events) + [e for e in ur.events if e.get("ev") == "trip" and e not in r.events]
    return [f"sampling: trip sample disagrees: {d}" for d in gaps.confirm_trips(ss, runs)]


def _compare(ours_results, other_results, against: str, spec, o1: Optional[Path] = None) -> Tuple[str, List[str]]:
    # Z1: a consumer that holds the DriverSpec passes its classical key (CR §6 global phases are
    # judged with the classical arguments fixed). Against the C program, the register webs of its
    # cq_theta sites (bead cq-ia96, rule 10's overwrite by an identity-angle prep).
    key = sibling("compare", "classical_key_from_driver")(spec)
    extra = {}
    if o1 is not None:
        from cqcheck import drivers as D
        extra["registers"] = D.theta_registers(D.read_module(Path(o1)))
    reasons = list(sibling("compare", "compare")(ours_results, other_results, against,
                                                 classical_key=key, **extra))
    return (PASS, []) if not reasons else (FAIL, [f"{against}: {r}" for r in reasons])


def _prebuild(ex: Example, ours: Path, need_ref_run: bool) -> None:
    """The executables of the §6 run, built while the sample set is generated (cq-8m6v): the sampler's
    probe build and the C oracle's program (the sampler runs both), ours and the reference in the
    evaluator. Each is
    the cache entry the run itself asks for (the drivers depend on the DriverSpec and the drivers.txt
    pointer expressions only), so the run finds it built; a failure here is ignored and met again,
    with its own reason, when the run asks for the same build."""
    from cqcheck import drivers, oracle, run
    try:
        spec = drivers.driver_spec(ex.name, ex.dir)
    except Exception:  # noqa: BLE001 - the run reports it
        return
    def one(build) -> None:
        try:
            build()
        except Exception:  # noqa: BLE001 - see the docstring
            pass

    # side by side: each is a chain of tool starts that waits on nothing of the others
    def probe() -> None:
        import tempfile
        from cqcheck import sampling
        if sampling.cached(spec, ex.dir):
            return                       # the sample set is kept: no probe runs
        with tempfile.TemporaryDirectory(prefix=f"cqd-{ex.name}-pre-") as tmp:
            sampling.ProbeBuild(spec, ex.dir, Path(tmp)).close()

    builds = [probe, lambda: oracle.executable(ex.o1, spec), lambda: run.build(ours, spec, [])]
    if need_ref_run:
        builds.append(lambda: run.build(ex.reference, spec, []))
    ts = [threading.Thread(target=one, args=(b,), daemon=True) for b in builds]
    for t in ts:
        t.start()
    for t in ts:
        t.join()


def _start_prebuild(ex: Example, ours: Path, need_ref_run: bool):
    t = threading.Thread(target=_prebuild, args=(ex, ours, need_ref_run), daemon=True)
    t.start()
    return t


class _SkipDiff(Exception):
    pass


def evaluate(ex: Example, ours: Optional[Path], oracle: str = "both", lower_error: str = "",
             short_circuit: bool = True, diff_out: Optional[Path] = None,
             reference_mode: bool = False, substitution: Any = True) -> Verdict:
    """The Verdict for one example. `ours` is our lowered module, or None with `lower_error` when
    the pass produced nothing. `oracle` is ref, c or both. `short_circuit=False` forces the §6 run
    on a textual match (the baseline runs a reference against itself). `reference_mode=True` runs
    the verifier as `cq-verify<reference>` (S1): `ours` is a CQ_spec reference (the baseline).
    `substitution=False` runs only the samples without cq_theta substitution (the self-test's
    rotation classes, cq-lkth: there a skipped or moved Ry leaves every value as it is, so the
    rotation list is the first difference); `substitution="only"` runs only the samples with it (the
    self-test's SUBST_ONLY classes, cq-3o3v); never the verdict of `run`."""
    reasons: List[str] = []
    if ours is None:
        why = lower_error or "no lowered module"
        return Verdict(ex.name, ERROR if oracle in ("ref", "both") else NOT_RUN,
                       ERROR if oracle in ("c", "both") else NOT_RUN, ERROR, None, [why])

    verifier, why = verify(ours, reference=reference_mode)
    if why:
        reasons.append(why)

    diff_lines = None
    try:
        # quick mode ($CQ_QUICK=1, `cqcheck run` without --full): no textual diff, a quality signal
        # that never fails (CLAUDE.md Reports); it costs four tool starts per example
        if os.environ.get("CQ_QUICK") == "1":
            raise _SkipDiff()
        diff_lines, diff = textual_diff(ours, ex.reference)
        if diff_out is not None:
            diff_out.parent.mkdir(parents=True, exist_ok=True)
            diff_out.write_text(diff + ("\n" if diff else ""))
    except _SkipDiff:
        pass
    except NormalizeError as e:
        reasons.append(f"diff: {e}")

    want_ref, want_c = oracle in ("ref", "both"), oracle in ("c", "both")
    s6 = c_oracle = NOT_RUN
    matched = diff_lines == 0 and short_circuit
    if want_ref and matched:
        s6 = PASS
        reasons.append("s6: textual match with the reference (§6 run short-circuited)")
    need_ref_run = want_ref and not matched

    if need_ref_run or want_c:
        pre = _start_prebuild(ex, ours, need_ref_run)
        try:
            spec = sibling("drivers", "driver_spec")(ex.name, ex.dir)
            ss = sibling("sampling", "sample_set")(spec, ex.dir)
            samples = ss.samples
            if substitution == "only":
                samples = [sm for sm in samples if "subst" in sm]
            elif not substitution:
                samples = [sm for sm in samples if "subst" not in sm]
            ours_results = _side_results(_evaluator_batch, ours, spec, samples, "ours")
        except Exception as e:  # noqa: BLE001 - every failure is an ERROR verdict with its reason
            r = _exc_reason("setup (drivers, sampling, our run)", e)
            reasons.append(r)
            if need_ref_run:
                s6 = ERROR
            if want_c:
                c_oracle = ERROR
        else:
            # cq-h4pn: a class the sampler left empty without a proof that no input exists, or a
            # sample set its own checks reject, keeps every §6 check over it from being green
            try:
                sampling_bad, sampling_notes = _sample_set_gaps(ex, spec, ss)
            except Exception as e:  # noqa: BLE001
                sampling_bad, sampling_notes = [_exc_reason("sampling gaps", e)], []
            reasons += sampling_bad
            c_raw: Optional[list] = [] if want_c else None
            c_samples = samples
            if need_ref_run:
                try:
                    ref_results = _side_results(_evaluator_batch, ex.reference, spec, samples, "ref")
                    s6, rs = _compare(ours_results, ref_results, "ref", spec)
                    reasons += rs
                except Exception as e:  # noqa: BLE001
                    s6 = ERROR
                    reasons.append(_exc_reason("s6", e))
            if want_c:
                try:
                    # rulings Q10: a call C gives no meaning to is compared against the reference only
                    from cqcheck import drivers as _D
                    o1mod = _D.read_module(Path(ex.o1))
                    in_c = [not _D.c_out_of_domain(spec, sm, o1mod) for sm in samples]
                    c_samples = [sm for sm, k in zip(samples, in_c) if k]
                    c_results = _side_results(_oracle_batch, ex.o1, spec, c_samples, c_raw)
                    c_ours = [r for r, k in zip(ours_results, in_c) if k]
                    c_oracle, rs = _compare(c_ours, c_results, "c", spec, ex.o1)
                    reasons += rs
                except Exception as e:  # noqa: BLE001
                    c_oracle = ERROR
                    reasons.append(_exc_reason("c_oracle", e))
                    c_raw = None
            try:
                trip_bad = _trip_disagreements(ex, spec, ss, c_raw, c_samples)
            except Exception as e:  # noqa: BLE001
                trip_bad = [_exc_reason("sampling trip confirmation", e)]
            reasons += trip_bad
            if sampling_bad or trip_bad:
                if need_ref_run and s6 == PASS:
                    s6 = ERROR
                if want_c and c_oracle == PASS:
                    c_oracle = ERROR
            reasons += sampling_notes
        if pre is not None:
            pre.join()

    return Verdict(ex.name, s6, c_oracle, verifier, diff_lines, reasons)


def uncovered(v: Verdict) -> List[str]:
    """The uncovered coverage targets listed in a verdict (cq-g8md): its ``sampling: uncovered:`` lines."""
    return [r for r in v.reasons if r.startswith("sampling: uncovered:")]


GREEN, UNCOVERED, FAILING = "green", "uncovered", "fail"


def accepted(v: Verdict) -> bool:
    """The gate (owner ruling 2026-11-01, cq-g8md): §6, C oracle and verifier all PASS, no comparison
    failed; uncovered targets, each listed in the reasons, are allowed."""
    return v.s6 == PASS and v.c_oracle == PASS and v.verifier == PASS


def green(v: Verdict) -> bool:
    """Version 1's per-example condition: §6, C oracle and verifier all PASS, and no uncovered target
    (an example with one is UNCOVERED, never counted green: CR §6, coverage)."""
    return accepted(v) and not uncovered(v)


def state(v: Verdict) -> str:
    """GREEN, UNCOVERED (accepted by the gate, not green) or FAILING."""
    return GREEN if green(v) else UNCOVERED if accepted(v) else FAILING


def requested_accepted(v: Verdict) -> bool:
    """Every check the run asked for passed (NOT_RUN is the caller's choice of oracle); uncovered
    targets allowed (the gate)."""
    return all(x in (PASS, NOT_RUN) for x in (v.s6, v.c_oracle)) and v.verifier == PASS \
        and (v.s6, v.c_oracle) != (NOT_RUN, NOT_RUN)


def requested_green(v: Verdict) -> bool:
    """requested_accepted with no uncovered target."""
    return requested_accepted(v) and not uncovered(v)


# --------------------------------------------------------------------------------------------
# Storage and the printed report


def verdict_store() -> Path:
    return out_dir() / "verdicts"


def save_verdict(v: Verdict) -> None:
    d = verdict_store()
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{v.example}.json").write_text(to_json(v) + "\n")


def load_verdicts() -> Dict[str, Verdict]:
    out = {}
    d = verdict_store()
    if d.is_dir():
        for f in sorted(d.glob("*.json")):
            data = json.loads(f.read_text())
            out[data["example"]] = Verdict(**data)
    return out


def format_table(verdicts: Sequence[Verdict]) -> str:
    rows = [("example", "s6", "c_oracle", "verifier", "diff", "first reason")]
    for v in verdicts:
        unc = uncovered(v) if accepted(v) else []
        rows.append((v.example, v.s6, v.c_oracle, v.verifier,
                     "-" if v.diff_lines is None else str(v.diff_lines),
                     unc[0] if unc else v.reasons[0] if v.reasons else ""))
    widths = [max(len(r[i]) for r in rows) for i in range(5)]
    lines = ["  ".join(c.ljust(w) for c, w in zip(r[:5], widths)) + "  " + r[5] for r in rows]
    n = len(verdicts)
    counts = {k: sum(1 for v in verdicts if getattr(v, k) == PASS) for k in ("s6", "c_oracle", "verifier")}
    lines.append(f"{n} examples: s6 pass {counts['s6']}, c_oracle pass {counts['c_oracle']}, "
                 f"verifier pass {counts['verifier']}, green {sum(1 for v in verdicts if green(v))}, "
                 f"uncovered {sum(1 for v in verdicts if state(v) == UNCOVERED)} (all three pass, every uncovered "
                 f"target listed; not green), "
                 f"textual match {sum(1 for v in verdicts if v.diff_lines == 0)}")
    return "\n".join(lines)


def verdict_dict(v: Verdict) -> dict:
    return dataclasses.asdict(v)
