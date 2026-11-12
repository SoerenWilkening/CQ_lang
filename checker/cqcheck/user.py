"""cqcheck user (module usercheck, bead cq-w1-usercheck): the C-oracle check of any program.

NORTHSTAR principle 5's last sentence: `cqcc --cq-check` runs this on the program it compiled.

    user.main(o1: str, lowered: str, entry: str, samples: Optional[int]) -> int   (cq-arch Z1)

`o1` is the program's whole-program `clang -O1` module (cqcc passes the module it linked with the
injection bundle), `lowered` its lowering, `entry` the function both run from. The check is §6 against
the C program only (CLAUDE.md "The §6 checker", oracle (b)); there is no reference.

Inputs. A program has no drivers.txt line, so nothing says which entry arguments are quantum: every
argument of the entry is classical, and the quantum inputs are
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
own, a zeroed 4096-byte, 16-aligned static array (sampling never varies a pointer). When memory it points
to flows into a cq_theta (drivers.quantum_params; a `bool *` to the caller's registers, example 60), its
first FILL_ELEMENTS elements are quantum inputs as a drivers.txt fill is (drivers.py "Driver objects"), of
the C type the entry loads through it (`_Bool` for an i8 whose loads are all `trunc nuw` to i1). An IR shape with
no such C spelling (byval, sret, a struct or vector parameter, an internal entry) is an internal
error of the checker, `cq: unimplemented: usercheck: ...`.

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
never green. 3 when no sample was compared after every exclusion (NOT COMPARED: rulings Q2 and cq-dbtpi, the guard of
the owner rulings 2026-11-11 Q1 and 2026-11-12 item 4): never green either. A run that compared some is judged on those
and states how many it did not compare, with the reason (owner ruling 2026-11-12, Q2 partial exclusion).
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

PASS_STATUS, FAIL_STATUS, ERROR_STATUS, NOT_COMPARED_STATUS = 0, 1, 2, 3
# rulings Q2 (owner 2026-11-11): the checker's detection is an approximation, and the report says so
Q2_LIMIT = ("rulings Q2: an input on which a bodiless callee receives a pointer into an object holding a QUANTUM cell at "
            "the call is not compared (decided on the C program: the object is the real one, a cell holds a rail; the "
            "lowered run may only narrow it); reach through a global or a stored pointer is not detected, nor a cell "
            "made QUANTUM only by a store under a quantum condition")
# owner ruling 2026-11-12 cq-dbtpi ("as in Q2"), the reason stated with the count
DEFERRED_READ = ("ruling cq-dbtpi: an input on which the program reads the result rail of a deferred host call (a "
                 "host-state result or a non-library bodiless callee's, deferred by ABI 1.11) is not compared (the read "
                 "decided on the C program: the call ran and its result reached a store, branch, load, return or call; "
                 "the lowered run may only narrow it to the calls it deferred)")
MAIN_RENAMED = "__cqu_main"
OBJ_BYTES = 4096
FILL_ELEMENTS = 64    # the quantum inputs behind a pointer parameter (module docstring)
# compare._match_c's reason when its order-consistent search runs out of its node budget (cq-sujz)
_OUT_OF_BUDGET = re.compile(r"exceeded \d+ search nodes without an order-consistent matching")
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


def _fill_ctype(mod, f, p: str, seen: set) -> set:
    """The C element types f loads through its pointer parameter p, and through the defined callees it
    is passed to."""
    from cqcheck import drivers as D
    got: set = set()
    if (f.name, p) in seen:
        return got
    seen.add((f.name, p))
    for ins in f.insts():
        if ins.op == "load" and p in D._operand_roots(f, ins.operands[1], set()):
            t = ins.operands[0].split()[0]
            users = [u for u in f.insts() if ins.dest in u.refs()]
            if t == "i8" and users and all(u.op == "trunc" and re.search(r"\bnuw\b", u.text) and u.text.rstrip().endswith("to i1")
                                           for u in users):
                got.add("_Bool")
            else:
                got.add(D._IR_ELEMENT.get(t, t))
        elif ins.op == "call" and ins.callee in mod.functions:
            g = mod.functions[ins.callee]
            for k, a in enumerate(ins.call_args):
                if k < len(g.params) and g.params[k][1] and p in D._operand_roots(f, a, set()):
                    got |= _fill_ctype(mod, g, g.params[k][1], seen)
    return got


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
    # every argument classical but the elements behind a pointer that feeds a cq_theta (module docstring)
    mod = D.read_module(o1)
    irf = mod.functions["@" + entry]
    qp = D.quantum_params(mod)
    calls = []
    for c in spec.calls:
        args = []
        for j, a in enumerate(c["args"]):
            if D.parse_ctype(a["ctype"]).kind == "p" and ("@" + entry, j) in qp.pointee:
                types = _fill_ctype(mod, irf, irf.params[j][1], set())
                if len(types) > 1 or not all(t in D._INT_TYPES or t in D._FP_TYPES for t in types):
                    unimplemented(f"parameter {j} of {entry} is loaded as {sorted(types)}: one scalar element type is filled")
                ctype = next(iter(types), "unsigned char")
                ect = D.parse_ctype(ctype)
                n = min(FILL_ELEMENTS, OBJ_BYTES // (16 if ect.bits == 80 else ect.storage_bits // 8))
                args.append(dict(a, quantum=True, fill={"ctype": ctype, "w": ect.bits, "n": n}))
            else:
                args.append({k: v for k, v in dict(a, quantum=False).items() if k != "fill"})
        calls.append({"fn": c["fn"], "args": args})
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


def subset(samples: List[dict], n: Optional[int], key=None, spec: Optional[DriverSpec] = None,
           turned=None) -> List[dict]:
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
    (the report names the cut).

    cq-jqjf: when the set has a sample with a cq_theta substitution, so does the subset. CR §6 item 1
    runs the circuit "on basis inputs (each cq_theta input replaced by a chosen bit pattern)", and a
    sampling checker "never narrows the claim" (CR §6): a subset of unsubstituted samples only would
    compare the program at the values the C program gives its quantum registers, never at a chosen
    one (sample 0, the all-zero baseline, has no substitution). So a cut first group whose seeded
    choice holds none swaps its last sample (sample 0 at n = 1) for a seeded substituted one of the
    group, and a subset still without one takes a seeded substituted sample of another group, in a
    free place or in place of the last sample taken. A subset that already holds one is unchanged.

    cq-7is3f (owner 2026-11-10): a sampled PASS also compares a substituted sample with a nonzero angle;
    a subset confined to the all-zero-angle group (the baseline's, which holds the edge, specials and
    exhaustive substitutions and fills small n alone) narrows the claim: 01's negated Ry passed. With
    `turned` (`turned_angles`, the C oracle's angles) such a sample is taken when the set has one
    (`_take_turned`); a subset that already holds one is unchanged."""
    if n is None or n >= len(samples):
        return list(samples)
    if n < 1:
        raise UserCheckError(f"cqcheck user: --samples {n}: at least one sample is compared")
    key = key or (lambda s: json.dumps([s["call"], s["args"]]))
    subst = lambda i: "subst" in samples[i]      # noqa: E731
    groups: Dict[object, List[int]] = {}
    for i, s in enumerate(samples):
        groups.setdefault(key(s), []).append(i)
    first = groups.pop(key(samples[0]))
    rng = random.Random(SUBSET_SEED)
    if len(first) > n:
        cut = [first[0]] + sorted(rng.sample(first[1:], n - 1))
        theta = [i for i in first if subst(i)]
        if theta and not any(subst(i) for i in cut):
            cut[-1] = rng.choice(theta)         # the last of the seeded others, or sample 0 at n = 1
            cut = [cut[0]] + sorted(cut[1:]) if n > 1 else cut
        first = cut
    take = list(first)
    rest = list(groups.values())
    rng.shuffle(rest)
    rest.sort(key=lambda g: _magnitude(spec, samples[g[0]]))      # stable: ties keep the seeded order
    for g in (rest[i] for i in _spread(len(rest))):
        if len(take) + len(g) <= n:
            take += g
    if not any(subst(i) for i in take):
        theta = [i for i in range(len(samples)) if subst(i)]
        if theta:
            one = rng.choice(theta)
            if len(take) >= n:
                take.pop()          # the last taken: sample 0 stays unless it is the only one
            take.append(one)
    if turned is not None:
        _take_turned(samples, n, take, turned, subst, key)
    return [samples[i] for i in sorted(take)]


TURNED_BATCH = 32     # candidates asked of `turned` at a time (cq-7is3f)


def _take_turned(samples: List[dict], n: int, take: List[int], turned, subst, key) -> None:
    """cq-7is3f (owner 2026-11-10): `take` holds a substituted sample with a nonzero angle when the set
    has one. `turned(indices) -> [bool]` says which samples have a substituted cq_theta reach with a
    nonzero angle (`turned_angles`). A subset that holds one is unchanged; else the first one in a seeded
    order (the samples of classical groups the subset does not compare first, then the others) replaces
    the last sample taken (sample 0 stays unless it is the only one), or fills a free place."""
    mine = [i for i in take if subst(i)]
    if mine and any(turned(mine)):
        return
    groups_in = {key(samples[i]) for i in take}
    taken = set(take)
    rest = [i for i in range(len(samples)) if subst(i) and i not in taken]
    random.Random(SUBSET_SEED + 1).shuffle(rest)
    rest.sort(key=lambda i: key(samples[i]) in groups_in)      # stable: ties keep the seeded order
    for at in range(0, len(rest), TURNED_BATCH):
        part = rest[at:at + TURNED_BATCH]
        hit = next((i for i, t in zip(part, turned(part)) if t), None)
        if hit is not None:
            if len(take) >= n:
                take.pop()
            take.append(hit)
            return


def _turned_angle(bits) -> bool:
    """An f64 angle bit pattern (T1.1) that is neither ±0 nor a NaN: its sign shows in an Ry."""
    if bits is None:
        return False
    v = int(bits, 16) if isinstance(bits, str) else int(bits)
    mag = v & 0x7FFF_FFFF_FFFF_FFFF
    return mag != 0 and mag <= 0x7FF0_0000_0000_0000


def turned_angles(c_module: Path, spec: DriverSpec, samples: List[dict]):
    """The `turned` of `subset` for the C program: runs the asked samples in the C oracle and says of each
    whether one of its substituted cq_theta sites ("subst" keys) is reached with a nonzero angle."""
    from cqcheck import oracle

    def turned(idx: List[int]) -> List[bool]:
        runs = oracle.run_samples(c_module, spec, [samples[i] for i in idx])
        return [not r.failed and any(e.get("ev") == "site" and e.get("kind") == "theta"
                                     and f"{e.get('fn')}:{e.get('site')}" in samples[i]["subst"]
                                     and _turned_angle(e.get("angle")) for e in r.events)
                for i, r in zip(idx, runs)]
    return turned


EXTRA_PER_GROUP = 256         # cq-pdstc: samples added per classical group with an unidentified measurement
_UNIDENTIFIED = re.compile(r"sample (\{)")


def _unidentified_extras(reasons: List[str], chosen: List[dict], samples: List[dict], key) -> List[dict]:
    """The samples of the set, not compared yet, of the classical groups in which a measurement of ours went
    unidentified (cq-pdstc): at most EXTRA_PER_GROUP per group, in a seeded order."""
    from cqcheck import compare
    bad = set()
    for r in reasons:
        m = _UNIDENTIFIED.search(r)
        if m and "match no C measurement here" in r:
            try:
                bad.add(key(json.JSONDecoder().raw_decode(r, m.start(1))[0]))
            except (ValueError, KeyError, TypeError):
                continue
    if not bad:
        return []
    have = {compare._skey(s) for s in chosen}
    out: List[dict] = []
    for k in sorted(bad, key=repr):
        rest = [s for s in samples if key(s) == k and compare._skey(s) not in have]
        random.Random(SUBSET_SEED + 2).shuffle(rest)
        out += rest[:EXTRA_PER_GROUP]
    return out


# ------------------------------------------------------------------------------------------------
# The check


def verdict(reasons: List[str], compared: Optional[int] = None) -> int:
    """The status of a comparison's reasons: not compared (3) when `compared` (compare's stats) is 0, whatever the
    reasons (the guard: a verdict with zero compared samples is never PASS); pass with none; undecided (2) when every
    one is a gate matching out of its search budget (no difference found, none ruled out: cq-sujz decision 6);
    differs (1) otherwise."""
    if compared == 0:
        return NOT_COMPARED_STATUS
    if not reasons:
        return PASS_STATUS
    if all(_OUT_OF_BUDGET.search(r) for r in reasons):
        return ERROR_STATUS
    return FAIL_STATUS


# The one thread's TLS object (CQ_spec LIBC_COVERAGE.md: musl's pthread_arch.h, __cq_tp, "provided by the bundle"), as
# __init_tp leaves it: zero, but struct __pthread's `locale` (offset 168) at a zero locale_t, what libc.global_locale holds at
# startup (the C locale).
_TLS_DEF = ('@__cq_locale = internal global [6 x ptr] zeroinitializer, align 8\n'
            '@__cq_tp = internal global <{ [168 x i8], ptr, [3920 x i8] }> <{ [168 x i8] zeroinitializer, ptr @__cq_locale, '
            '[3920 x i8] zeroinitializer }>, align 16')
_EXTERN_DATA = re.compile(r'^@("[^"]*"|[-A-Za-z$._0-9]+) = external (?:[a-z_]+ )*?(?:global|constant) ([^\n]*?)(, align \d+)?$', re.M)


def host_standard_streams(text: str) -> str:
    """Ruling Q6 (2026-11-11): the bundle defines no stdin, stdout or stderr; the standard streams are the host library's
    objects (CR rule 16, BACKEND_ABI §1.11), and the owner's output ruling of 2026-11-12 (item 4) has the C reference
    perform the write on the host. A program compiled against musl's <stdio.h> names them `stdin`, `stdout`, `stderr`
    (`FILE *const`); a host that does not define those names but defines Darwin's `__stdinp`, `__stdoutp`, `__stderrp` (the
    same object, a `FILE *`) is linked by the host's name, on both sides: the C program's host fprintf gets the host's
    stream (a zeroed stand-in object made it fprintf(NULL)), and the lowered program's bus load reads it at its host
    address (example 99), so its tape field is the host's stream (rt_tape.c stream_text). A name the host defines stays."""
    from cqcheck import oracle
    for name in ("stdin", "stdout", "stderr"):
        decl = re.search(r'^@' + name + r' = external [^\n]*$', text, re.M)
        host = f"__{name}p"
        if not decl or oracle._host_defines(name) or not oracle._host_defines(host):
            continue
        if re.search(r'^@' + host + r' = ', text, re.M):
            text = text[:decl.start()] + text[decl.end() + 1:]
        text = re.sub(r'@' + name + r'(?![-A-Za-z$._0-9])', '@' + host, text)
    return text


def define_undefined_data(text: str) -> str:
    """A whole program defines its data: an external global the host C library does not define (a library's bundle-provided
    object) would stop both links. It is a zeroed object on both sides (__cq_tp: _TLS_DEF; [0 x T], an unsized extern:
    4096 bytes, as a driver object). The standard streams are the host's (host_standard_streams)."""
    from cqcheck import oracle
    text = host_standard_streams(text)

    def define(m: "re.Match[str]") -> str:
        name, ty = m.group(1).strip('"'), m.group(2)
        if oracle._host_defines(name):
            return m.group(0)
        if name == "__cq_tp":
            return _TLS_DEF
        if re.fullmatch(r"\[0 x .*\]", ty):
            ty = f"[{OBJ_BYTES} x i8]"
        return f"@{m.group(1)} = internal global {ty} zeroinitializer, align 16"

    return _EXTERN_DATA.sub(define, text)


def check(o1: Path, lowered: Path, entry: str, samples: Optional[int], work: Path) -> Tuple[int, List[str]]:
    """(status, report lines)."""
    from cqcheck import compare, oracle, run, sampling
    o1_text = sampling.natural_cycles(define_undefined_data(Path(o1).read_text()), work)
    low_text = define_undefined_data(Path(lowered).read_text())
    if _defines(o1_text, "main"):
        o1_text, low_text = rename_main(o1_text), rename_main(low_text)
        if entry == "main":
            entry = MAIN_RENAMED
    if not _defines(low_text, entry):
        raise UserCheckError(f"cqcheck user: the entry {entry} has no definition in the lowered module")
    low = work / f"user_{entry}.lowered.ll"
    low.write_text(low_text)
    spec, exdir = build_spec(o1_text, entry, work)
    c_module = next(exdir.glob("*.O1.ll"))

    # the all-zero baseline is made up: domain-filtered like every other sample (cq-sujz)
    ss = sampling.sample_set(spec, exdir, exempt_baseline=False)
    if not ss.samples:
        whys = sorted({str(e.get("empty"))[:200] for cls in ss.classes.values() if isinstance(cls, dict)
                       for e in cls.values() if isinstance(e, dict) and e.get("empty")})
        raise UserCheckError(f"cqcheck user: entry {entry}: no sample inside the C program's domain"
                             + ("; reasons: " + " | ".join(whys) if whys else ""))
    ckey = compare.classical_key_from_driver(spec)
    chosen = subset(ss.samples, samples, ckey, spec, turned_angles(c_module, spec, ss.samples))
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
    regs = D.theta_registers(D.read_module(c_module))
    stats: Dict[str, object] = {}
    reasons = list(compare.compare(ours, cres, "c", classical_key=ckey, registers=regs, stats=stats))
    # cq-pdstc: a measurement of ours is identified only from samples of its classical arguments (cq-1ye9c). A
    # subset (--samples, --light) may hold too few of a group to show C taking the quantum arm: the group's other
    # samples of the set (domain-filtered like every sample) are compared too, at most EXTRA_PER_GROUP per group, in a
    # seeded order, before such a measurement is reported.
    extra = _unidentified_extras(reasons, chosen, ss.samples, ckey)
    if extra:
        chosen = chosen + extra
        ours += run.run_samples(low, spec, extra, "ours", jobs, c_module=c_module)
        cres += [oracle.run_result(r, spec, c_module) for r in oracle.run_samples(c_module, spec, extra)]
        stats = {}
        reasons = list(compare.compare(ours, cres, "c", classical_key=ckey, registers=regs, stats=stats))
        lines.append(f"cqcheck user: {len(extra)} more samples of {len({ckey(s) for s in extra})} classical "
                     f"group(s) compared, where a measurement was unidentified (cq-pdstc; now {len(chosen)} samples)")
    status = verdict(reasons, stats.get("compared"))
    nq2 = len(stats.get("q2") or [])
    ndr = len(stats.get("deferred") or [])
    lines.append(f"cqcheck user: compared {stats.get('compared')} of {len(chosen)} samples")
    if nq2:
        lines.append(f"cqcheck user: {nq2} of {len(chosen)} samples not compared ({Q2_LIMIT})")
    if ndr:
        lines.append(f"cqcheck user: {ndr} of {len(chosen)} samples not compared ({DEFERRED_READ})")
    if status == NOT_COMPARED_STATUS:
        lines.append(f"cqcheck user: NOT COMPARED: no sample was compared ({len(chosen)} run, {nq2} excluded by rulings Q2, "
                     f"{ndr} by ruling cq-dbtpi); never a PASS")
        lines += [f"  c: {r}" for r in reasons]
        return NOT_COMPARED_STATUS, lines
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
    lines.append(f"cqcheck user: PASS: §6-equal to the C program on every compared sample ({stats.get('compared')} compared)")
    return PASS_STATUS, lines


def main(o1: str, lowered: str, entry: str, samples: Optional[int], light: bool = False) -> int:
    """cq-arch Z1: the C-oracle check of one program; the exit status (0 pass, 1 fail, 2 error)."""
    if light:
        from cqcheck import sampling as _s
        _s.LIGHT = True
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
