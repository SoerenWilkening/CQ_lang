"""cqcheck user (module usercheck, bead cq-w1-usercheck): the C-oracle check of any program.

NORTHSTAR principle 5's last sentence: `cqcc --cq-check` runs this on the program it compiled.

    user.main(o1: str, lowered: str, entry: str, samples: Optional[int]) -> int   (cq-arch Z1)

`o1` is the program's whole-program `clang -O1` module (cqcc passes the module it linked with the
injection bundle), `lowered` its lowering, `entry` the function both run from. The check is §6 against
the C program only (CLAUDE.md "The §6 checker", oracle (b)); there is no reference.

Inputs. A program has no drivers.txt line, so nothing says which entry arguments are quantum: every
argument of the entry is classical (a handle-cell object aside, below), and the quantum inputs are
the values reaching the program's cq_theta sites (CR §6 item 1, "each cq_theta input replaced by a chosen bit pattern"). Both sides
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

A pointer parameter the lowered entry reads as handle cells (an i32 loaded through it reaches a
rail operand of a cqrt_* or cq_template_* call, a template's `l` shape positions excluded, directly or through a defined callee: a `bool *` to the caller's
quantum registers, CR rule 20, example 60) gets instead an object of HANDLE_CELLS seeded handles,
`static int cqu_objJ[HANDLE_CELLS]` with every cell `cqrt_alloc_iW(0)` in the setup, as 60's
drivers.txt line does (cq-sujz decision 1). The cells are quantum inputs (cq-rbe6): drivers.py's
handle cells, varied by every quantum class of the sampling, the lowered side holding rails at the
sampled values and the C program reading them as its own element type. W is the width of the cqrt
operation the handles reach.
The object is 4 * HANDLE_CELLS bytes on both sides: a C element narrower than the 4-byte cell (60's
bool) leaves indices HANDLE_CELLS .. 4 * HANDLE_CELLS / sizeof - 1 inside the C program's domain but
past the lowered side's cells (a gap, bead cq-562f).

The baseline call (every argument 0) is made up, not spec data: it is filtered by the C program's
domain like every other sample (sampling.sample_set(..., exempt_baseline=False), cq-sujz decision 2),
so 120's register_grid(obj, 0, 0), which reads q[-1][1], is not compared.

A program that defines `main` has it renamed to `__cqu_main` in both modules (the checker's drivers
define `main`); `--entry main` then runs `__cqu_main`. Only `int main(void)` is an entry: argc/argv
would need argv's object to agree with a sampled argc.

`samples` (cqcc --cq-samples): at most that many samples are compared: whole classical groups (the
samples at one argument tuple), sample 0's group first, then spread over their sizes (`subset`);
None compares every sample.

Exit status: 0 when the lowered program is §6-equal to the C program on every compared sample, 1 when
it differs (the reasons are printed), 2 when the check could not be decided (bad arguments, an
internal error of the checker, no sample in the C program's domain, or a gate matching out of the
comparison's search budget with no other difference: undecided, never 'differs', cq-sujz decision 6):
never green.
"""
from __future__ import annotations

import collections
import json
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
HANDLE_CELLS = 64     # seeded handle cells behind a pointer the lowered entry reads handles through
# compare._match_c's reason when its order-consistent search runs out of its node budget (cq-sujz)
_OUT_OF_BUDGET = re.compile(r"exceeded \d+ search nodes without an order-consistent matching")
_ALLOC_C = {1: "_Bool", 8: "signed char", 16: "short", 32: "int"}   # cqrt_alloc_i<W>'s parameter
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
# Handle cells: a pointer parameter the lowered entry reads quantum handles through


_WIDTH = re.compile(r"_i(\d+)(?![0-9])")
ANY_WIDTH = -1        # a rail operand of any width (cqrt_free, a template whose name gives none)
_TW = r"(i\d+|f\d+|bf16)"


def _w(t: str) -> int:
    """A rail width from an ABI type suffix: iN its N; an fp rail 0 (no cell is seeded with one)."""
    return int(t[1:]) if t.startswith("i") else 0


def _core_widths(name: str, nargs: int) -> List[Optional[int]]:
    """Per argument of `@cqrt_<name>`, its rail width (0: a rail no cell is seeded with, an f64
    angle or an index of unstated width; ANY_WIDTH: any) or None (no rail: a classical literal,
    angle, size, pointer or word, a QRAM bus or a tape), by the signatures of BACKEND_ABI.md §1."""
    m = re.fullmatch(r"(alloc_.*|qram_alloc_.*|qram_realloc_.*|qram_free|tape_alloc|tape_fmt|push|pop"
                     r"|tape_write_.*_lit|tape_write_str_lit)", name)
    if m:
        return [None] * nargs                                   # alloc(lit), push(w): "Rails. None"
    if name == "free":
        return [ANY_WIDTH]
    m = re.fullmatch(r"measure_" + _TW, name)
    if m:
        return [_w(m.group(1))]
    m = re.fullmatch(r"ry_" + _TW + r"(_qangle)?(_controlled)?", name)
    if m:
        w = _w(m.group(1))
        return ([1] if m.group(3) else []) + [w] + ([0] if m.group(2) else [None])   # [c,] h, θ | A
    if name == "rz_i1":
        return [1, None]                                        # (f, θ)
    if name in ("rz_qangle", "rz_qangle_controlled"):
        return ([1] if name.endswith("_controlled") else []) + [0]                    # [c,] A
    if name in ("not_i1", "and_i1", "or_i1", "xor_i1", "abort_i1"):
        return [1] * nargs
    m = re.fullmatch(r"(copy|xorc)_" + _TW + r"(_controlled)?", name)
    if m:
        w = _w(m.group(2))
        return ([1] if m.group(3) else []) + ([w, w] if m.group(1) == "copy" else [w, None])  # (s, d) | (h, lit)
    m = re.fullmatch(r"qram_(store|load)_" + _TW + r"(_hl)?(_controlled)?(_unc)?", name)
    if m:
        w = _w(m.group(2))
        idx = None if m.group(3) else 0
        out = ([w] if m.group(1) == "load" and m.group(5) else [])                    # load_unc's h
        out += ([1] if m.group(4) else []) + [None, idx]                              # [c,] a, idx | j
        out += [w] if m.group(1) == "store" else []                                   # store's v
        return out
    m = re.fullmatch(r"tape_(fmt|effect)_controlled", name)
    if m:
        return [1, None, None]                                  # (c, t, fmt | name)
    m = re.fullmatch(r"tape_write_" + _TW + r"(_controlled)?", name)
    if m:
        return ([1] if m.group(2) else []) + [None, _w(m.group(1))]                   # [c,] t, h
    unimplemented(f"a call of @cqrt_{name}: no BACKEND_ABI.md §1 signature known to the handle-cell scan")


def _rail_width(callee: str, k: int, nargs: int) -> Optional[int]:
    """The rail width of argument k of a call to callee (ANY_WIDTH, or 0 for a width no cell is
    seeded with), or None when it is no rail handle (BACKEND_ABI.md core signatures and template
    naming)."""
    if callee.startswith("@cqrt_"):
        ws = _core_widths(callee[len("@cqrt_"):], nargs)
        if len(ws) != nargs:
            unimplemented(f"a call of {callee} with {nargs} arguments (BACKEND_ABI.md §1 gives {len(ws)})")
        return ws[k]
    if not callee.startswith("@cq_template_"):
        return None
    parts = callee[len("@cq_template_"):].split("_")
    unc = parts[-1] == "unc"
    if unc:
        parts.pop()
    if parts[-1] == "exc":
        parts.pop()
    if parts[-1] in ("rm", "rmq"):
        if parts.pop() == "rm" and k == nargs - 1:
            return None                      # the classical rounding mode, after the data operands
    # the shape: one letter per data operand, `l` a literal (ABI "cq_template_<op>...[_<shape>]"); an
    # _unc form takes the output handle first, select its condition handle before the arms
    shape = parts[-1] if len(parts) > 2 and re.fullmatch(r"[hlq]+", parts[-1]) else ""
    off = (1 if unc else 0) + (1 if parts[0] == "select" else 0)
    if 0 <= k - off < len(shape) and shape[k - off] == "l":
        return None
    m = _WIDTH.search(callee)
    return int(m.group(1)) if m else ANY_WIDTH


def _rail_position(callee: str, k: int, nargs: int) -> bool:
    """Argument k of a call to callee is a rail handle."""
    return _rail_width(callee, k, nargs) is not None


def _handle_widths(mod, f, v: str, seen: set) -> Tuple[bool, set]:
    """(v reaches a handle operand, the rail widths of the operations it reaches): v an i32 SSA
    value of f, followed through phi/select and into defined callees."""
    if (f.name, v) in seen:
        return False, set()
    seen.add((f.name, v))
    used, widths = False, set()
    for inst in f.insts():
        if v not in inst.refs():
            continue
        if inst.op == "call" and inst.callee:
            for k, a in enumerate(inst.call_args):
                if v not in a.split():
                    continue
                if inst.callee.startswith(("@cqrt_", "@cq_template_")):
                    w = _rail_width(inst.callee, k, len(inst.call_args))
                    if w is None:
                        continue
                    used = True
                    if w != ANY_WIDTH:
                        widths.add(w)
                elif inst.callee in mod.functions:
                    g = mod.functions[inst.callee]
                    if k < len(g.params):
                        u, w = _handle_widths(mod, g, g.params[k][1], seen)
                        used, widths = used or u, widths | w
        elif inst.op in ("phi", "select") and inst.dest:
            u, w = _handle_widths(mod, f, inst.dest, seen)
            used, widths = used or u, widths | w
    return used, widths


def _cell_widths(mod, f, p: str, seen: set) -> Tuple[bool, set]:
    """Whether f reads handles through the pointer p (an i32 load rooted at p reaching a handle
    operand, in f or in a defined callee p is passed to), and their rail widths."""
    from cqcheck import drivers as D
    if (f.name, "ptr", p) in seen:
        return False, set()
    seen.add((f.name, "ptr", p))
    used, widths = False, set()
    for inst in f.insts():
        if inst.op == "load" and inst.dest and inst.operands and inst.operands[0] == "i32" \
                and p in D._operand_roots(f, inst.operands[1], set()):
            u, w = _handle_widths(mod, f, inst.dest, seen)
            used, widths = used or u, widths | w
        elif inst.op == "call" and inst.callee in mod.functions:
            g = mod.functions[inst.callee]
            for k, a in enumerate(inst.call_args):
                if k < len(g.params) and a.split()[0] == "ptr" and p in D._operand_roots(f, a, set()):
                    u, w = _cell_widths(mod, g, g.params[k][1], seen)
                    used, widths = used or u, widths | w
    return used, widths


def handle_cell_params(low_path: Path, entry: str) -> Dict[int, int]:
    """param index -> rail width, for each pointer parameter of the lowered entry it reads quantum
    handles through."""
    from cqcheck import drivers as D
    mod = D.read_module(low_path)
    f = mod.functions.get("@" + entry)
    if f is None:
        raise UserCheckError(f"cqcheck user: the entry {entry} has no definition in the lowered module")
    out: Dict[int, int] = {}
    for j, (t, p) in enumerate(f.params):
        if not t.split() or t.split()[0] != "ptr":
            continue
        used, widths = _cell_widths(mod, f, p, set())
        if not used:
            continue
        if len(widths) != 1 or next(iter(widths)) not in _ALLOC_C:
            unimplemented(f"parameter {j} of {entry} holds handles of rail widths {sorted(widths)} "
                          f"(one of i1, i8, i16, i32 is seeded)")
        out[j] = next(iter(widths))
    return out


# ------------------------------------------------------------------------------------------------
# The work tree


def rename_main(text: str) -> str:
    return re.sub(r"@main(?![-A-Za-z$._0-9])", "@" + MAIN_RENAMED, text)


def _defines(text: str, fn: str) -> bool:
    return _define_line(text, fn) is not None


def build_spec(o1_text: str, entry: str, root: Path,
               cells: Optional[Dict[int, int]] = None) -> Tuple[DriverSpec, Path]:
    """The work tree under root and the DriverSpec of the entry (every argument classical). `cells`:
    param index -> rail width of each pointer parameter that gets seeded handle cells. Returns
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
    setup, args, allocs = [], [], set()
    for j, ct in enumerate(pct):
        if ct.endswith("*") and j in (cells or {}):
            nm, w = f"cqu_obj{j}", cells[j]
            allocs.add(w)
            setup.append(f"static int {nm}[{HANDLE_CELLS}]; for (int cqu_i = 0; cqu_i < {HANDLE_CELLS}; "
                         f"cqu_i++) {nm}[cqu_i] = cqrt_alloc_i{w}(0);")
            args.append(nm)
        elif ct.endswith("*"):
            nm = f"cqu_obj{j}"
            setup.append(f"static unsigned char {nm}[{OBJ_BYTES}] __attribute__((aligned(16)));")
            args.append(nm)
        else:
            args.append("0")
    proto += "".join(f"int cqrt_alloc_i{w}({_ALLOC_C[w]});" for w in sorted(allocs))
    fields = [example, proto, f"{entry}({','.join(args)})"] + ([" ".join(setup)] if setup else [])
    tools = root / "_tools"
    tools.mkdir()
    (tools / "drivers.txt").write_text("|".join(fields) + "\n")
    line = D.read_drivers_txt(tools / "drivers.txt")[example]
    spec = D.build_driver_spec(line, D.read_module(o1))
    # every argument classical but a handle-cell object (drivers.handle_cells): its cells are quantum
    # inputs, sampled like any other (cq-rbe6), and no part of the classical key
    calls = [{"fn": c["fn"], "args": [dict(a, quantum=True) if a.get("cells") else
                                      {"ctype": a["ctype"], "quantum": False} for a in c["args"]]}
             for c in spec.calls]
    return DriverSpec(example=spec.example, protos=spec.protos, setup=spec.setup, calls=calls), exdir


def _magnitude(spec: Optional[DriverSpec], sample: dict) -> int:
    """The sum of the magnitudes of a sample's integer arguments (signed ones as |value|): a proxy for
    the size of the run (loop bounds, array lengths), so a subset spreads over small and large
    programs."""
    from cqcheck import drivers as D
    if spec is None:
        return 0
    tot = 0
    for a, v in zip(spec.calls[sample["call"]]["args"], sample["args"]):
        ct = D.parse_ctype(a["ctype"])
        if ct.kind != "i" or not isinstance(v, str) or not v.startswith("0x"):
            continue
        x = int(v, 16) & ((1 << ct.bits) - 1)
        if ct.signed and x >> (ct.bits - 1):
            x = (1 << ct.bits) - x
        tot += x
    return tot


def _spread(m: int) -> List[int]:
    """0 .. m-1 in van der Corput order (0, m/2, m/4, 3m/4, ...): every prefix is spread evenly over
    the range, and the first index is 0."""
    if m <= 0:
        return []
    bits = max(1, (m - 1).bit_length())
    order, seen = [], set()
    for j in range(1 << bits):
        i = (int(format(j, f"0{bits}b")[::-1], 2) * m) >> bits
        if i not in seen:
            seen.add(i)
            order.append(i)
    return order


def subset(samples: List[dict], n: Optional[int], key=None, spec: Optional[DriverSpec] = None) -> List[dict]:
    """At most n samples, in set order: whole classical groups (`key`, the comparison's classical
    key: the samples sharing the entry's arguments and differing in their cq_theta substitutions),
    sample 0's group first, then the others spread over their size range (`_magnitude`, ties in a
    seeded order; `_spread`: the smallest, the median, the quartiles, ...), each taken when it fits.
    Owner 2026-11-01: a subset spreads over the classical groups, never only the smallest (117 at
    200 of 2205 samples took 9 of 107 groups, all near t = 0: cq-w71h). cq-sujz decision 6: the
    matching against the C program tells rails apart by their values over a group, so a group cut
    down to one sample leaves equal-looking rails it cannot match within its budget, and a large
    program (117 at nq = t = 7) has more gates than the budget can order; fewer samples, never a
    bigger budget. A first group larger than n is cut to sample 0 and a seeded choice of its others
    (the report names the cut)."""
    if n is None or n >= len(samples):
        return list(samples)
    if n < 1:
        raise UserCheckError(f"cqcheck user: --samples {n}: at least one sample is compared")
    key = key or (lambda s: json.dumps([s["call"], s["args"]]))
    groups: Dict[object, List[int]] = {}
    for i, s in enumerate(samples):
        groups.setdefault(key(s), []).append(i)
    first = groups.pop(key(samples[0]))
    rng = random.Random(SUBSET_SEED)
    if len(first) > n:
        first = [first[0]] + sorted(rng.sample(first[1:], n - 1))
    take = list(first)
    rest = list(groups.values())
    rng.shuffle(rest)
    rest.sort(key=lambda g: _magnitude(spec, samples[g[0]]))      # stable: ties keep the seeded order
    for g in (rest[i] for i in _spread(len(rest))):
        if len(take) + len(g) <= n:
            take += g
    return [samples[i] for i in sorted(take)]


# ------------------------------------------------------------------------------------------------
# The check


def verdict(reasons: List[str]) -> int:
    """The status of a comparison's reasons: pass with none; undecided (2) when every one is a gate
    matching out of its search budget (no difference found, none ruled out: cq-sujz decision 6);
    differs (1) otherwise."""
    if not reasons:
        return PASS_STATUS
    if all(_OUT_OF_BUDGET.search(r) for r in reasons):
        return ERROR_STATUS
    return FAIL_STATUS


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
    low = work / f"user_{entry}.lowered.ll"
    low.write_text(low_text)
    spec, exdir = build_spec(o1_text, entry, work, handle_cell_params(low, entry))
    c_module = next(exdir.glob("*.O1.ll"))

    # the all-zero baseline is made up: domain-filtered like every other sample (cq-sujz)
    ss = sampling.sample_set(spec, exdir, exempt_baseline=False)
    if not ss.samples:
        raise UserCheckError(f"cqcheck user: entry {entry}: no sample inside the C program's domain")
    ckey = compare.classical_key_from_driver(spec)
    chosen = subset(ss.samples, samples, ckey, spec)
    nsubst = sum(1 for s in chosen if "subst" in s)
    # a subset is a sampled verdict and says so (owner 2026-11-01)
    size = collections.Counter(ckey(s) for s in ss.samples)
    took = collections.Counter(ckey(s) for s in chosen)
    cut = [f"{n} of {size[k]}" for k, n in took.items() if n < size[k]]
    lines = [f"cqcheck user: entry {entry}: {len(chosen)} samples"
             + (f" of {len(ss.samples)} (SAMPLED: {len(took)} of {len(size)} classical groups"
                + (f", {len(cut)} cut to {', '.join(cut)}" if cut else "") + ")"
                if len(chosen) != len(ss.samples) else "")
             + f", {nsubst} with cq_theta substitution"]
    jobs = int(os.environ.get("CQCHECK_JOBS", DEFAULT_JOBS))
    ours = run.run_samples(low, spec, chosen, "ours", jobs, c_module=c_module)
    cres = [oracle.run_result(r, spec, c_module) for r in oracle.run_samples(c_module, spec, chosen)]
    if len(ours) != len(chosen) or len(cres) != len(chosen):
        raise UserCheckError(f"cqcheck user: {len(ours)} lowered and {len(cres)} C results "
                             f"for {len(chosen)} samples")
    from cqcheck import drivers as D
    reasons = list(compare.compare(ours, cres, "c", classical_key=ckey,
                                   registers=D.theta_registers(D.read_module(c_module))))
    status = verdict(reasons)
    if status == ERROR_STATUS:
        lines.append(f"cqcheck user: UNDECIDED: the gate matching against the C program ran out of its "
                     f"search budget on {len(reasons)} classical group(s) and found no difference "
                     f"elsewhere; compare fewer or smaller samples (--samples)")
        lines += [f"  c: {r}" for r in reasons]
        return ERROR_STATUS, lines
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
