"""cqcheck user (module usercheck, bead cq-w1-usercheck): the C-oracle check of any program.

NORTHSTAR principle 5's last sentence: `cqcc --cq-check` runs this on the program it compiled.

    user.main(o1: str, lowered: str, entry: str, samples: Optional[int]) -> int   (cq-arch Z1)

`o1` is the program's whole-program `clang -O1` module (cqcc passes the module it linked with the
injection bundle), `lowered` its lowering, `entry` the function both run from. The check is §6 against
the C program only (CLAUDE.md "The §6 checker", oracle (b)); there is no reference.

Inputs. A program has no drivers.txt line, so nothing says which entry arguments are quantum: every
argument of the entry is classical, and the quantum inputs are the values reaching the program's
cq_theta sites (CR §6 item 1, "each cq_theta input replaced by a chosen bit pattern"). Both sides
take the same sampled basis value at each reach of a site: the sample's "subst" (cq-arch Z4) is what
cq_theta returns in the C oracle and what the evaluator's firing Ry leaves on its target (run.py's
theta schedule, dispatch.c). The sampling classes are cq-w0-chk-drivers' (sampling.sample_set): the
classical seeded set over the entry arguments, the trip-count searches, and at the entry's baseline
arguments the substitution classes (edge, specials, exhaustive up to 8 bits, the seeded random set)
over every cq_theta site reachable from the entry. The comparison is cq-w0-chk-compare's against "c",
with the classical key of the DriverSpec (every argument classical: a phase is global when it is
constant over the substituted values with the arguments fixed).

The DriverSpec is the one a drivers.txt line would give, written from the entry's IR signature:
the line `00_user_<entry>|<prototype>|<entry>(<baseline>)|<setup>` sits in a work tree laid out as a
CQ_spec checkout (`_tools/drivers.txt`, `examples/00_user_<entry>/<base>.O1.ll`), which is where
sampling reads it (Z1.1). The prototype spells each IR parameter type as the C type with the same
calling convention (iN with signext/zeroext as the signed/unsigned C integer, half/float/double/
x86_fp80, ptr as void *); the baseline argument is 0. A pointer parameter gets a driver object of its
own, a zeroed 4096-byte, 16-aligned static array (sampling never varies a pointer). An IR shape with
no such C spelling (byval, sret, a struct or vector parameter, an internal entry) is an internal
error of the checker, `cq: unimplemented: usercheck: ...`.

A program that defines `main` has it renamed to `__cqu_main` in both modules (the checker's drivers
define `main`); `--entry main` then runs `__cqu_main`. Only `int main(void)` is an entry: argc/argv
would need argv's object to agree with a sampled argc.

`samples` (cqcc --cq-samples): at most that many samples are compared, a seeded subset of the sample
set that always holds the baseline call; None compares every sample.

Exit status: 0 when the lowered program is §6-equal to the C program on every compared sample, 1 when
it differs (the reasons are printed), 2 when the check could not be decided (bad arguments, an
internal error of the checker): never green.
"""
from __future__ import annotations

import os
import random
import re
import sys
import tempfile
import traceback
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from cqcheck.contracts import DriverSpec

PASS_STATUS, FAIL_STATUS, ERROR_STATUS = 0, 1, 2
MAIN_RENAMED = "__cqu_main"
OBJ_BYTES = 4096
SUBSET_SEED = 20261028
DEFAULT_JOBS = 4      # runner processes when $CQCHECK_JOBS is unset (machine load, CLAUDE.md memory)

_IDENT = r"[-A-Za-z$._0-9]+"
_INT_C = {8: ("signed char", "unsigned char"), 16: ("short", "unsigned short"), 32: ("int", "unsigned"),
          64: ("long long", "unsigned long long"), 128: ("__int128", "unsigned __int128")}
_FP_C = {"half": "_Float16", "float": "float", "double": "double", "x86_fp80": "long double"}
_COMPLEX_RET = {"{ double, double }": "double _Complex", "<2 x float>": "float _Complex",
                "{ x86_fp80, x86_fp80 }": "long double _Complex"}


class UserCheckError(Exception):
    """The check cannot be decided: exit 2 with the message."""


def unimplemented(what: str):
    raise UserCheckError(f"cq: unimplemented: usercheck: {what}")


# ------------------------------------------------------------------------------------------------
# The entry's C prototype from its IR signature


def _attrs_free(text: str) -> str:
    """A parameter or return text without parenthesized attribute arguments (range(i32 0, 3),
    align(8), dereferenceable(4), ...), so the type is a plain token."""
    out, depth = [], 0
    i = 0
    while i < len(text):
        c = text[i]
        if c == "(":
            # an attribute's argument list: drop it with the attribute name kept
            depth += 1
        elif c == ")":
            depth -= 1
        elif depth == 0:
            out.append(c)
        i += 1
    return "".join(out)


def _int_ctype(bits: int, words: List[str]) -> str:
    if bits == 1:
        return "_Bool"
    if bits not in _INT_C:
        unimplemented(f"an i{bits} entry parameter or return has no C integer type")
    return _INT_C[bits][1 if "zeroext" in words else 0]


def _param_ctype(text: str, where: str) -> str:
    """The C type of one IR parameter ("i8 noundef zeroext %2")."""
    if re.search(r"\b(byval|sret|inalloca|preallocated|byref)\b", text):
        unimplemented(f"{where}: parameter {text!r} is passed in memory (byval/sret)")
    t = text.strip()
    if t.startswith(("{", "<", "[", "%")) and not re.match(r"%\d+$", t):
        unimplemented(f"{where}: parameter {text!r} has an aggregate or vector IR type")
    words = _attrs_free(t).split()
    ty = words[0] if words else ""
    m = re.fullmatch(r"i(\d+)", ty)
    if m:
        return _int_ctype(int(m.group(1)), words)
    if ty in _FP_C:
        return _FP_C[ty]
    if ty == "ptr":
        return "void *"
    unimplemented(f"{where}: parameter {text!r}: IR type {ty!r} has no C spelling here")


def _ret_ctype(ret: str, where: str) -> str:
    """The C return type of a define's return text ("dso_local noundef zeroext i1", "{ double, double }")."""
    for ir, c in _COMPLEX_RET.items():
        if ir in ret:
            return c
    if "{" in ret or "<" in ret or "[" in ret:
        unimplemented(f"{where}: return type {ret!r} has no C spelling here")
    words = _attrs_free(ret).split()
    for w in reversed(words):
        m = re.fullmatch(r"i(\d+)", w)
        if m:
            return _int_ctype(int(m.group(1)), words)
        if w in _FP_C:
            return _FP_C[w]
        if w == "ptr":
            return "void *"
        if w == "void":
            return "void"
    unimplemented(f"{where}: return type {ret!r} has no C spelling here")


def _define_line(text: str, fn: str) -> Optional[str]:
    for line in text.splitlines():
        if line.startswith("define ") and re.search(r"@" + re.escape(fn) + r"\(", line):
            return line
    return None


def entry_prototype(o1_text: str, fn: str) -> Tuple[str, List[str]]:
    """(the C prototype of fn, its parameter C types), from fn's define line in the .O1.ll."""
    from cqcheck import drivers as D
    line = _define_line(o1_text, fn)
    if line is None:
        raise UserCheckError(f"cqcheck user: the entry {fn} has no definition in the -O1 module")
    m = re.search(r"@" + re.escape(fn) + r"\(", line)
    head = line[len("define "):m.start()]
    if re.search(r"\b(internal|private)\b", head):
        unimplemented(f"the entry {fn} has internal linkage (a static function the driver cannot call)")
    params = D._parse_params(D._balanced(line, m.end() - 1))
    if any(t == "..." for t, _ in params):
        unimplemented(f"the entry {fn} is variadic")
    pct = [_param_ctype(t, fn) for t, _ in params]
    ret = _ret_ctype(head, fn)
    return f"{ret} {fn}({', '.join(pct) if pct else 'void'});", pct


# ------------------------------------------------------------------------------------------------
# The work tree


def rename_main(text: str) -> str:
    return re.sub(r"@main(?![-A-Za-z$._0-9])", "@" + MAIN_RENAMED, text)


def _defines(text: str, fn: str) -> bool:
    return _define_line(text, fn) is not None


def build_spec(o1_text: str, entry: str, root: Path) -> Tuple[DriverSpec, Path]:
    """The work tree under root and the DriverSpec of the entry (every argument classical). Returns
    (spec, the example directory holding <base>.O1.ll)."""
    from cqcheck import drivers as D
    if not re.fullmatch(r"[A-Za-z_]\w*", entry):
        unimplemented(f"the entry name {entry!r} is not a C identifier")
    base = "user_" + entry
    example = "00_" + base
    exdir = root / "examples" / example
    exdir.mkdir(parents=True)
    o1 = exdir / f"{base}.O1.ll"
    o1.write_text(o1_text)
    proto, pct = entry_prototype(o1_text, entry)
    if entry == MAIN_RENAMED and pct:
        unimplemented("main with parameters (argc/argv) as the entry; pass --entry with a function "
                      "that takes scalar arguments")
    setup, args = [], []
    for j, ct in enumerate(pct):
        if ct.endswith("*"):
            nm = f"cqu_obj{j}"
            setup.append(f"static unsigned char {nm}[{OBJ_BYTES}] __attribute__((aligned(16)));")
            args.append(nm)
        else:
            args.append("0")
    fields = [example, proto, f"{entry}({','.join(args)})"] + ([" ".join(setup)] if setup else [])
    tools = root / "_tools"
    tools.mkdir()
    (tools / "drivers.txt").write_text("|".join(fields) + "\n")
    line = D.read_drivers_txt(tools / "drivers.txt")[example]
    spec = D.build_driver_spec(line, D.read_module(o1))
    calls = [{"fn": c["fn"], "args": [{"ctype": a["ctype"], "quantum": False} for a in c["args"]]}
             for c in spec.calls]
    return DriverSpec(example=spec.example, protos=spec.protos, setup=spec.setup, calls=calls), exdir


def subset(samples: List[dict], n: Optional[int]) -> List[dict]:
    """At most n samples: the baseline (sample 0) and a seeded choice of the rest, in set order."""
    if n is None or n >= len(samples):
        return list(samples)
    if n < 1:
        raise UserCheckError(f"cqcheck user: --samples {n}: at least one sample is compared")
    rest = sorted(random.Random(SUBSET_SEED).sample(range(1, len(samples)), n - 1))
    return [samples[0]] + [samples[i] for i in rest]


# ------------------------------------------------------------------------------------------------
# The check


def check(o1: Path, lowered: Path, entry: str, samples: Optional[int], work: Path) -> Tuple[int, List[str]]:
    """(status, report lines)."""
    from cqcheck import compare, oracle, run, sampling
    o1_text = Path(o1).read_text()
    low_text = Path(lowered).read_text()
    if _defines(o1_text, "main"):
        o1_text, low_text = rename_main(o1_text), rename_main(low_text)
        if entry == "main":
            entry = MAIN_RENAMED
    if not _defines(low_text, entry):
        raise UserCheckError(f"cqcheck user: the entry {entry} has no definition in the lowered module")
    spec, exdir = build_spec(o1_text, entry, work)
    c_module = next(exdir.glob("*.O1.ll"))
    low = work / f"{exdir.name.split('_', 1)[1]}.lowered.ll"
    low.write_text(low_text)

    ss = sampling.sample_set(spec, exdir)
    chosen = subset(ss.samples, samples)
    nsubst = sum(1 for s in chosen if "subst" in s)
    lines = [f"cqcheck user: entry {entry}: {len(chosen)} samples"
             + (f" of {len(ss.samples)}" if len(chosen) != len(ss.samples) else "")
             + f", {nsubst} with cq_theta substitution"]
    jobs = int(os.environ.get("CQCHECK_JOBS", DEFAULT_JOBS))
    ours = run.run_samples(low, spec, chosen, "ours", jobs, c_module=c_module)
    cres = [oracle.run_result(r, spec, c_module) for r in oracle.run_samples(c_module, spec, chosen)]
    if len(ours) != len(chosen) or len(cres) != len(chosen):
        raise UserCheckError(f"cqcheck user: {len(ours)} lowered and {len(cres)} C results "
                             f"for {len(chosen)} samples")
    reasons = list(compare.compare(ours, cres, "c", classical_key=compare.classical_key_from_driver(spec)))
    if reasons:
        lines.append(f"cqcheck user: FAIL: the lowered program differs from the C program "
                     f"({len(reasons)} reasons)")
        lines += [f"  c: {r}" for r in reasons]
        return FAIL_STATUS, lines
    lines.append("cqcheck user: PASS: §6-equal to the C program on every sample")
    return PASS_STATUS, lines


def main(o1: str, lowered: str, entry: str, samples: Optional[int]) -> int:
    """cq-arch Z1: the C-oracle check of one program; the exit status (0 pass, 1 fail, 2 error)."""
    try:
        for p, what in ((o1, "--o1"), (lowered, "--lowered")):
            if not Path(p).is_file():
                raise UserCheckError(f"cqcheck user: {what} {p}: no such file")
        with tempfile.TemporaryDirectory(prefix="cqu-") as tmp:
            status, lines = check(Path(o1), Path(lowered), entry, samples, Path(tmp))
    except UserCheckError as e:
        print(str(e), file=sys.stderr)
        return ERROR_STATUS
    except Exception as e:  # noqa: BLE001 - an internal error of the checker is never a verdict
        tb = traceback.extract_tb(e.__traceback__)
        at = f" at {Path(tb[-1].filename).name}:{tb[-1].lineno}" if tb else ""
        print(f"cqcheck user: ERROR: {type(e).__name__}: {e}{at}", file=sys.stderr)
        return ERROR_STATUS
    print("\n".join(lines))
    return status
