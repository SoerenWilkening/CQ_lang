#!/usr/bin/env python3
"""free_pairing_check.py — structural Rule-6 free-pairing checker over LOWERED IR.

WHY THIS EXISTS (bd test_C_libtooling-8txa, the CHEAP half)
==========================================================
Rule 6 says a `cqrt_free(%r)` is sound only on a **provably-|0> rail**. The
project's Rule-2 gate is the e2e golden byte-diff — the only layer that links
and runs — but that layer **cannot witness this property**, because a generated
adjoint template prints

    cq_template_<op>_<W>_hl_inv(<forward args>) -> h<fresh>

and **never names the rail it is supposed to restore**. When bd `oudq` moved
atanhl's `cqrt_free` count 300 -> 217, the golden alone could not distinguish
"shared predicate, fewer rails" from "dropped uncompute" — closing that took two
throwaway out-of-band tools. This file promotes the structural one to a committed
gate at the IR layer, where the rail identity IS present (`%r` is an SSA name)
even though the trace has lost it.

WHAT bd `8txa` CHANGED, AND WHAT IT DID NOT
-------------------------------------------
The COMPARE FLAG-STRIP no longer has this defect. It used to be the flag-shaped
instance of it — this docstring's own motivating example was four textually
IDENTICAL `cq_template_fcmp_olt_f80_hl_inv(h67, …)` lines in
`slice_libm_real_log1pl.expected.log` that paired with four DIFFERENT
`cqrt_free`s. 8txa switched that strip to the void, out-first `_unc` ABI, so the
same four lines now read

    cq_template_fcmp_olt_f80_hl_unc(h78,  h60, 0xb.504f333f9de6484p-4)
    cq_template_fcmp_olt_f80_hl_unc(h80,  h60, 0xb.504f333f9de6484p-4)
    cq_template_fcmp_olt_f80_hl_unc(h106, h60, 0xb.504f333f9de6484p-4)
    cq_template_fcmp_olt_f80_hl_unc(h110, h60, 0xb.504f333f9de6484p-4)

— each naming the rail it zeroes, and the golden byte-diff DOES now witness that
pairing for compare flags.

This checker is NOT thereby redundant. It still owns every rail the trace label
cannot speak for: the whole-DAG uncompute spine's data `_unc` chains, the loop
reverse-play write history, and the "was this rail actually |0> at the free"
question, which no label can answer at any ABI. Read `classify()` and the
obligation below for exactly what it does and does not witness.

THE OBLIGATION IT WITNESSES
===========================
For every `cqrt_free(%r)`: **at the free, %r holds a KNOWN CLASSICAL BASIS
STATE and is unentangled** — the property that makes the free (a hardware reset
= projective measurement, Rule 6) collapse nothing. It establishes that by one
of two structural proofs, one per rail class.

MINTED rails — `%r = M(a...)` for a `cq_template_*`, a `cqrt_qram_load_<W>`, a
`cqrt_tape_write_<W>`, or a Phase-6 clone `@__cq_q_*`. The mint creates a fresh
|0> rail and writes `f(a...)` into it, so the free is sound iff that write was
undone:

  (T1) a REVERSAL exists and is claimed ONE-TO-ONE: either the void
       `M_unc(%r, a...)` (which names the rail — no inference needed) or an
       `M_inv(a...)` whose ARGUMENT LIST matches the forward's operand for
       operand. Every `_inv` token is consumed by at most one free, so N frees
       of same-shaped rails need N reversals. A deleted uncompute, or a
       reversal whose operands do not match the forward's, fails here.
  (T2) the forward's own handle operands are UNCHANGED between the forward and
       the reversal — either never written, or written only in a self-cancelling
       way (below). An `_inv` recomputes `f` from the live sources; if a source
       moved in between, it recomputes a DIFFERENT value and leaves the rail
       dirty.
  (T3) the rail itself is unchanged between mint and reversal (the `¬flag`
       `cqrt_x` bracket is such a self-cancelling pair) and is NOT written at
       all between the reversal and the free.

ALLOCATED rails — `%r = cqrt_alloc_<W>(v)`: the conjunction ancillas
(`cqrt_alloc_i1` + the toffoli/cnot flag network), the swap-route work rails,
and the `cq_theta` source rails. `v` is a CLASSICAL value, so the rail starts in
a known basis state and the free is sound iff it is still in one:

  (A1) every basis-changing write is a classical-immediate in-place update
       (`cqrt_addc_<W>` / `cqrt_xorc_<W>`, whose second operand is by ABI a
       classical literal). A known classical state plus a classical offset is
       still a known classical state — no superposition, no entanglement. This
       is the dtzb `break` index rail (`alloc(k)`, `addc(-k)`, free).
  (A2) otherwise the write history REDUCES TO IDENTITY, returning the rail to
       its alloc-time classical `v`. Reduction repeatedly cancels a write
       against an earlier ADJOINT write when every write between them commutes
       with it (see COMMUTATION). `x`/`cnot`/`toffoli`/`cswap`/`xorc`/`copy`
       are self-adjoint; `ry`/`rz` pair with the negated angle; `addc` with the
       negated immediate; a qram store with its `_unc` twin. The plain
       even-length adjoint palindrome the ticket asks for is the common case of
       this reduction; a deleted uncompute toffoli leaves an odd, unpairable
       history and fails here.

Plus two whole-stream invariants:

  (W)  every `_inv` is claimed by EXACTLY ONE free. An `_inv` is the only
       construct in the lowered IR that writes a rail its signature does not
       name, so an unclaimed one is an adjoint whose target cannot be
       identified — the "re-paired to the wrong rail" defect in its purest
       form. Across the 232 committed e2e slices the pairing is an exact
       bijection: 25174 `_inv` tokens, 25174 claims, 0 orphans.
  (F)  the lifetime hygiene that has no other gate anywhere in the project:
       double free, use after free, freeing a measured handle, and freeing a
       non-rail resource token (a `cqrt_qram_alloc_*` array or a
       `cqrt_tape_alloc` tape).

TWO MODELLING DECISIONS THAT ARE PHYSICS, NOT CONVENIENCE
=========================================================
* `cqrt_rz_<W>` IS TRANSPARENT. Rz = diag(1, e^{i.theta}) is DIAGONAL in the
  computational basis: it changes no basis label, so it can neither dirty a
  |0> rail nor invalidate a recorded value. This is exactly Rule 6's phase-arm
  clause ("the rail is |0> for free, Rz|0> = |0>") and the same
  diagonal/non-diagonal split the pass's own `declineStaleRecordOps` /
  `WireWalk` guard uses. It is what lets the canonical swap-routed phase arm
  (`cswap; rz; rz; cswap; free`) verify. `cqrt_ry_<W>` is NOT diagonal and
  stays a full write — dropping an `ry` adjoint before a free IS caught.
* COMMUTATION IS LIMITED TO COMPLEMENTARY FLAG BRANCHES. Two controlled writes
  to the same rail are treated as commuting only when they share a control
  register whose `cqrt_x` parity differs between them AND that register is
  touched by nothing but `cqrt_x` in between — i.e. they provably act on
  disjoint branches of the same flag. That is the `¬flag cqrt_x` bracket the
  two-arm emitter emits (§5b), and it is what makes the if/else `A B A B`
  routing of a shared base reduce to identity. No other reordering is allowed.

WHAT IT DOES **NOT** WITNESS  (read this before quoting the tool)
================================================================
  * PHASE. Because Rz is transparent (above), a dropped or wrong-angle `rz`
    adjoint is INVISIBLE here. That is a real miscompile — it is the golden
    trace's job, and the two gates are complementary by construction: the trace
    sees the angles and not the rail identities, this file sees the rail
    identities and not the angles.
  * The UNITARY. This is a structural check, not a simulator. It proves the
    emitted gate sequence has the SHAPE of a reversal; it does not evaluate it.
    Reduction-to-identity is SUFFICIENT for "unchanged", never necessary:
    `cqrt_x(h); cqrt_cnot(c,h); cqrt_x(h); cqrt_cnot(c,h)` is identity and
    is reported UNPROVEN, not verified. Likewise a Bennett-style uncompute that zeroes an ancilla by
    RECOMPUTING its predicate from updated state — the dtzb `break` fire rail,
    `toffoli(c,eqz,fire) … cnot(eqz',fire)` — is genuinely correct and
    genuinely UNPROVEN here; witnessing it needs the basis-state evaluator that
    is the other, expensive half of bd 8txa.
  * INTERCHANGEABLE reversals. When k frees pair with k character-identical
    `_inv` calls (the log1pl fcmp_olt family), any permutation of the pairing
    satisfies (T1) — correctly so, since identical ops on identically-valued
    rails ARE interchangeable. What it catches is a count or argument mismatch,
    which is what "re-paired to the wrong rail" degenerates into whenever the
    rails are not interchangeable.
  * Rails that are NEVER freed. Rule 6's "a rail not provably |0> is left
    allocated, never freed" is a rule about what the pass must NOT emit; a
    leaked dirty rail is invisible here (and is accepted in the
    qubits-not-scarce regime).
  * The ENTANGLEMENT half of Rule 8. A copy+uncompute that should have been a
    `cqrt_cswap` presents as a well-formed reversal.
  * ESCAPE analysis (`ret` / `cq_invert_*` handles) beyond "was it measured in
    this function", and anything cross-function or cross-stream (below).
  * The FORWARD program. It checks reversal, not computation.

STREAMS / CFG SCOPE. Execution order is only knowable without a simulator on
straight-line code, so the analysis runs per STREAM: a maximal chain of basic
blocks B0 -> B1 -> ... where each Bi ends in an unconditional `br label %B(i+1)`
and B(i+1) has Bi as its only predecessor. That is the shape the lowering emits
(`RegionFlatten` linearizes accepted control regions; the uncompute spine and
the flag network emit adjacent runs). A rail minted in one stream and freed in
another — the dtzb whole-loop reverse-play is the live example — is reported
UNPROVEN, never silently passed (`U1-cross-stream`, or `U3-extern-rail` when it
is also written here). Writes to a handle that arrives from outside ARE
recorded, so "this operand has no writes in this interval" is a fact about the
stream rather than an absence of information.

EXIT STATUS. 0 iff every free site VERIFIED. Non-zero on any VIOLATION, on any
UNPROVEN site (unless `--allow-unproven`), and on any UNCLASSIFIED runtime
symbol. The last is deliberate and mirrors the Prime Directive: a new `cqrt_*`
symbol whose read/write effects this file does not know makes the model
unsound, so it fails loudly rather than checking the rest and reporting success.

MEASURED STANDING (2026-07-26, the 232 committed e2e slices at their stage-2
`opt` output): 54049 `cqrt_free` sites, 54029 VERIFIED, 0 VIOLATIONS, 20
UNPROVEN. All 20 are in the five `slice_loop_break*` slices and are the dtzb
whole-loop reverse-play (10 `A-not-reducible` on the `cq.brk.fire` ancilla,
which a correct Bennett RECOMPUTE zeroes rather than a palindrome, and 10
`U1-cross-stream` on `cq.brk.R`/`cq.brk.idx`, whose write history spans the loop
back-edge). Those five e2e entries therefore pass `--allow-unproven` with that
reason written at the call site; every other slice runs strict.

VALIDATED BEFORE USE. Proof-targeted mutation over the same corpus — blank or
corrupt an instruction some VERIFIED site's own proof consumes, then re-check —
kills 6569 of 6579 mutants (99.8%). All 10 survivors are the same by-design
case: perturbing a classical `cqrt_addc` on an (A1) rail changes WHICH known
classical basis state the rail holds, never whether it holds one, so the free
stays Rule-6 sound. tools/free_pairing_check_test.py is the committed,
ctest-wired subset of that experiment (positive fixtures + hand-planted named
defects + a proof-targeted sweep).

USAGE
    tools/free_pairing_check.py [options] lowered1.ll [lowered2.ll ...]
      -q/--quiet          only print the summary and any findings
      --allow-unproven    downgrade UNPROVEN sites from failure to a report
      --explain           per verified site, the rule and the witness lines
      --stats             print per-category counts
      --json              machine-readable report on stdout
Self-test / mutant validation: tools/free_pairing_check_test.py.
"""

import argparse
import json
import re
import sys
from collections import Counter

# ---------------------------------------------------------------------------
# Effect model — the read/write/mint behaviour of every symbol the pass emits.
#
# Handle-ness of an operand is decided DYNAMICALLY (an operand is a rail iff
# this analysis already saw it minted), so the `_hl`/`_lh`/`_qq` operand-shape
# grammar never has to be re-parsed here; a classical literal or a classical
# SSA value simply is not in the rail table. Rule 15 (width-only ABI) means the
# width suffix is irrelevant to the effect model, so every entry below is keyed
# by the width-stripped stem.
# ---------------------------------------------------------------------------

_W = r"(?:i1|i8|i16|i32|i64|i80|i128|f16|f32|f64|f80|f128)"

ALL = "ALL"            # every operand is read
ALL_BUT_0 = "ALL_BUT_0"  # `_unc(out, srcs...)` — out is written, srcs read


class Unclassified(Exception):
    def __init__(self, sym):
        super().__init__(f"unclassified runtime symbol: @{sym}")
        self.sym = sym


class Effect:
    """Per-call effect record.

    reads/writes are operand INDICES (or the ALL / ALL_BUT_0 sentinels).
    `mints` is None (void or classical return), 'rail', 'array', 'tape', or
    'implicit-rail' (an `_inv`: it does write a rail, but the ABI does not say
    which — the whole reason this file exists).
    `diagonal` marks a write that changes no computational-basis label.
    `controls` are the operand indices whose value selects the branch the write
    acts on (used only by the complementary-branch commutation rule).
    """

    __slots__ = ("role", "reads", "writes", "mints", "adjoint_of", "base",
                 "diagonal", "controls", "classical_imm")

    def __init__(self, role, reads=(), writes=(), mints=None, adjoint_of=None,
                 base=None, diagonal=False, controls=(), classical_imm=False):
        self.role = role
        self.reads = reads
        self.writes = tuple(writes)
        self.mints = mints
        # 'self' | 'negate-arg<N>' | 'twin:<symbol>' | None
        self.adjoint_of = adjoint_of
        self.base = base            # forward stem for an _inv/_unc twin
        self.diagonal = diagonal    # phase-only: invisible to the basis ledger
        self.controls = tuple(controls)
        self.classical_imm = classical_imm  # addc/xorc: keeps a classical state


def classify(sym):
    """Map a callee name to an Effect, or None if the symbol is not ours.

    Raises Unclassified for a `cqrt_*` symbol this model does not know: a new
    runtime primitive changes what "written" means, so it must be added here
    before any verdict from this file means anything.
    """
    # ---- allocation / lifetime -------------------------------------------
    if re.fullmatch(rf"cqrt_alloc_{_W}", sym):
        return Effect("alloc", mints="rail")
    if re.fullmatch(rf"cqrt_qram_alloc_{_W}", sym):
        return Effect("alloc-array", mints="array")
    if sym == "cqrt_tape_alloc":
        return Effect("alloc-tape", mints="tape")
    if sym == "cqrt_alloc_handle":
        return Effect("alloc", mints="rail")
    if sym == "cqrt_free":
        return Effect("free")
    if re.fullmatch(rf"cqrt_measure_{_W}", sym):
        # Recorded as a WRITE with no adjoint: a measurement is irreversible, so
        # a rail it touched can never afterwards be shown "unchanged" for some
        # later reversal, and can never be freed (F8).
        return Effect("measure", reads=(0,), writes=(0,))

    # ---- in-place gates ---------------------------------------------------
    if re.fullmatch(rf"cqrt_rz_{_W}", sym):
        # DIAGONAL: Rz = diag(1, e^{i.theta}) relabels nothing (Rule 6 phase arm).
        return Effect("gate", writes=(0,), adjoint_of="negate-arg1",
                      diagonal=True)
    if re.fullmatch(rf"cqrt_ry_{_W}", sym):
        return Effect("gate", writes=(0,), adjoint_of="negate-arg1")
    if sym == "cqrt_x":
        return Effect("gate", writes=(0,), adjoint_of="self")
    if sym == "cqrt_h":
        # Self-adjoint; the pass does not emit it. Classified for safety.
        return Effect("gate", writes=(0,), adjoint_of="self")
    if sym == "cqrt_cnot":
        return Effect("gate", reads=(0,), writes=(1,), adjoint_of="self",
                      controls=(0,))
    if sym == "cqrt_toffoli":
        return Effect("gate", reads=(0, 1), writes=(2,), adjoint_of="self",
                      controls=(0, 1))
    if sym == "cqrt_cswap":
        return Effect("gate", reads=(0,), writes=(1, 2), adjoint_of="self",
                      controls=(0,))
    if re.fullmatch(rf"cqrt_copy_{_W}", sym):
        # dst ^= src — an involution (cq_runtime.h: "no cqrt_copy_<W>_inv twin")
        return Effect("gate", reads=(0,), writes=(1,), adjoint_of="self")
    if re.fullmatch(rf"cqrt_copy_{_W}_controlled", sym):
        return Effect("gate", reads=(0, 1), writes=(2,), adjoint_of="self",
                      controls=(0,))
    if re.fullmatch(rf"cqrt_addc_{_W}", sym):
        return Effect("gate", writes=(0,), adjoint_of="negate-arg1",
                      classical_imm=True)
    if re.fullmatch(rf"cqrt_xorc_{_W}", sym):
        return Effect("gate", writes=(0,), adjoint_of="self",
                      classical_imm=True)

    # ---- output tape (7.6) ------------------------------------------------
    if re.fullmatch(rf"cqrt_tape_write_{_W}", sym):
        return Effect("mint", reads=(1,), writes=(0,), mints="rail")
    if re.fullmatch(rf"cqrt_tape_write_{_W}_controlled", sym):
        return Effect("mint", reads=(0, 2), writes=(1,), mints="rail",
                      controls=(0,))

    # ---- QRAM (7.5) -------------------------------------------------------
    if re.fullmatch(rf"cqrt_qram_load_{_W}", sym):
        return Effect("mint", reads=(0, 1), mints="rail")
    m = re.fullmatch(rf"cqrt_qram_load_({_W})_unc", sym)
    if m:
        return Effect("unc", reads=(1, 2), writes=(0,),
                      base=f"cqrt_qram_load_{m.group(1)}")
    if re.fullmatch(rf"cqrt_qram_store_{_W}", sym):
        return Effect("gate", reads=(1, 2), writes=(0,),
                      adjoint_of="twin:" + sym + "_unc")
    m = re.fullmatch(rf"cqrt_qram_store_({_W})_unc", sym)
    if m:
        return Effect("gate", reads=(1, 2), writes=(0,),
                      adjoint_of="twin:cqrt_qram_store_" + m.group(1))
    if re.fullmatch(rf"cqrt_qram_store_{_W}_controlled", sym):
        return Effect("gate", reads=(0, 2, 3), writes=(1,), controls=(0,),
                      adjoint_of="twin:" + sym + "_unc")
    m = re.fullmatch(rf"cqrt_qram_store_({_W})_controlled_unc", sym)
    if m:
        return Effect("gate", reads=(0, 2, 3), writes=(1,), controls=(0,),
                      adjoint_of="twin:cqrt_qram_store_" + m.group(1) +
                                 "_controlled")

    # ---- generated templates + specialization clones ----------------------
    # Grammar (TemplateName.h):
    #   cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv]
    #   cq_template_..._unc(out, forward operands...)      (DD-3 slot order)
    #   @__cq_q_<callee>_<mask>[_unc]                      (Phase 6.3)
    if sym.startswith("cq_template_") or sym.startswith("__cq_q_"):
        ctl = (0,) if "_controlled" in sym else ()
        if sym.endswith("_unc"):
            # `_unc` puts `out` in slot 0 (DD-3), so a control — if a
            # `..._controlled_unc` twin is ever generated; none exists today,
            # EmitInverse declines controlled callees — shifts to slot 1.
            return Effect("unc", reads=ALL_BUT_0, writes=(0,),
                          base=sym[: -len("_unc")],
                          controls=(1,) if ctl else ())
        if sym.endswith("_inv"):
            # The 8txa gap: writes a rail the signature does not name.
            return Effect("inv", reads=ALL, mints="implicit-rail",
                          base=sym[: -len("_inv")], controls=ctl)
        return Effect("mint", reads=ALL, mints="rail", controls=ctl)

    if sym.startswith("cqrt_"):
        raise Unclassified(sym)
    return None  # @llvm.*, @printf, user classical calls — not our surface.


# ---------------------------------------------------------------------------
# Parsing. LLVM prints one instruction per line, so a line-oriented parser is
# exact; nothing below depends on formatting the verifier does not guarantee
# (Rule 9 — no assumptions about naming or ordering, only about the textual
# grammar `llvm-as` accepts).
# ---------------------------------------------------------------------------

DEFINE_RE = re.compile(r"^define\s.*?@([\w.$\"]+)\s*\(")
LABEL_RE = re.compile(r"^([-\w.$]+):")
CALL_RE = re.compile(
    r"^\s*(?:(%[-\w.$]+|%\"[^\"]+\")\s*=\s*)?"
    r"(?:tail\s+|musttail\s+|notail\s+)?call\s+"
    r"(?:[^@()]|\([^()]*\))*?@([\w.$]+|\"[^\"]+\")\s*\(")
TERM_BR_UNCOND_RE = re.compile(r"^\s*br\s+label\s+%([-\w.$]+)\s*$")
TERM_TARGETS_RE = re.compile(r"label\s+%([-\w.$]+)")
TERM_START_RE = re.compile(r"^\s*(br|switch|ret|unreachable|indirectbr|resume)\b")


def split_args(s):
    """Split a call's argument text on top-level commas."""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{<":
            depth += 1
        elif ch in ")]}>":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        out.append(cur.strip())
    return out


def norm_arg(a):
    """Canonical `(type, value)` for one argument, parameter attributes dropped.

    `i32 noundef %0` -> `i32 %0`; `x86_fp80 0xK3FFE…` -> unchanged. Every symbol
    in the runtime ABI takes scalars only (i32 handles plus classical literals),
    so first-token/last-token is an exact normalisation here — and it is the
    reason a `noundef` on a Phase-6 clone argument does not desynchronise a
    forward from its `_unc` twin.
    """
    toks = a.split()
    if not toks:
        return a
    return toks[0] + " " + toks[-1]


def arg_value(a):
    toks = a.split()
    return toks[-1] if toks else a


class Call:
    __slots__ = ("line", "res", "sym", "args", "vals", "eff", "text",
                 "ctl_parity")

    def __init__(self, line, res, sym, args, text):
        self.line = line
        self.res = res
        self.sym = sym
        self.args = [norm_arg(a) for a in args]
        self.vals = [arg_value(a) for a in args]
        self.eff = None
        self.text = text
        self.ctl_parity = ()   # per-control `cqrt_x` parity at this position

    def key(self):
        return (self.sym, tuple(self.args))

    def read_idx(self):
        r = self.eff.reads
        if r == ALL:
            return range(len(self.vals))
        if r == ALL_BUT_0:
            return range(1, len(self.vals))
        return r


class Function:
    def __init__(self, name):
        self.name = name
        self.blocks = []          # [(label, [Call], terminator_text)]
        self.succ = {}
        self.preds = {}


def parse_module(text):
    """Split a .ll into functions -> basic blocks -> calls, with a CFG."""
    funcs = []
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        m = DEFINE_RE.match(lines[i])
        if not m:
            i += 1
            continue
        fn = Function(m.group(1))
        i += 1
        cur_label, cur_calls, term = "%__entry", [], ""
        while i < len(lines) and lines[i] != "}":
            ln = lines[i]
            lm = LABEL_RE.match(ln)
            if lm:
                fn.blocks.append((cur_label, cur_calls, term))
                cur_label, cur_calls, term = "%" + lm.group(1), [], ""
                i += 1
                continue
            cm = CALL_RE.match(ln)
            if cm:
                open_at = ln.index("(", cm.end() - 1)
                depth, j = 0, open_at
                while j < len(ln):
                    if ln[j] == "(":
                        depth += 1
                    elif ln[j] == ")":
                        depth -= 1
                        if depth == 0:
                            break
                    j += 1
                cur_calls.append(Call(i + 1, cm.group(1),
                                      cm.group(2).strip('"'),
                                      split_args(ln[open_at + 1:j]), ln.strip()))
            elif TERM_START_RE.match(ln):
                term = ln.strip()
            i += 1
        fn.blocks.append((cur_label, cur_calls, term))
        for label, _, t in fn.blocks:
            tgt = ["%" + x for x in TERM_TARGETS_RE.findall(t)]
            fn.succ[label] = tgt
            fn.preds.setdefault(label, [])
            for x in tgt:
                fn.preds.setdefault(x, []).append(label)
        funcs.append(fn)
        i += 1
    return funcs


def build_streams(fn):
    """Maximal single-pred / unconditional-successor block chains.

    A stream is a run of blocks whose concatenation is a valid linear execution
    trace: Bi ends in `br label %B(i+1)` and B(i+1)'s only predecessor is Bi.
    """
    by_label = {lbl: (lbl, calls, t) for lbl, calls, t in fn.blocks}
    consumed, streams = set(), []
    for lbl, calls, t in fn.blocks:
        if lbl in consumed:
            continue
        chain, cur_t = [lbl], t
        consumed.add(lbl)
        while True:
            m = TERM_BR_UNCOND_RE.match("  " + cur_t)
            if not m:
                break
            nxt = "%" + m.group(1)
            if nxt in consumed or nxt not in by_label:
                break
            if fn.preds.get(nxt, []) != [chain[-1]]:
                break
            chain.append(nxt)
            consumed.add(nxt)
            cur_t = by_label[nxt][2]
        merged = []
        for c in chain:
            merged.extend(by_label[c][1])
        streams.append((chain, merged))
    return streams


# ---------------------------------------------------------------------------
# Numeric helpers for adjoint matching (negated angle / negated immediate).
# ---------------------------------------------------------------------------

def _hex_neg(a, b):
    """LLVM hex float payloads: negation flips the SIGN (top) bit.

    Covers `0x…` (double, 16 nibbles), `0xK…` (x86_fp80, 20), `0xL…` (fp128,
    32) and `0xH…` (half, 4) — for each the sign bit is bit 4*len-1. `0xM…`
    (ppc_fp128) is deliberately NOT handled: its negation touches both member
    doubles, so falling through to "not a negation" over-declines, which is the
    safe direction. The pass emits `cqrt_rz`/`cqrt_ry` angles as `double`, so
    this path only fires on hand-written or future wider-angle IR.
    """
    for pre in ("0xK", "0xL", "0xH", "0x"):
        if a.startswith(pre) and b.startswith(pre):
            ha, hb = a[len(pre):], b[len(pre):]
            if len(ha) != len(hb) or not ha or not hb:
                return False
            try:
                va, vb = int(ha, 16), int(hb, 16)
            except ValueError:
                return False
            return va ^ vb == 1 << (4 * len(ha) - 1)
    return False


def is_negation(a, b):
    """True iff argument strings `a` and `b` are `x` and `-x`."""
    ta, tb = a.split(), b.split()
    if len(ta) < 2 or len(tb) < 2 or ta[:-1] != tb[:-1]:
        return False
    va, vb = ta[-1], tb[-1]
    if va.lower().startswith("0x") or vb.lower().startswith("0x"):
        return _hex_neg(va, vb)
    try:
        na = float(va) if ("." in va or "e" in va.lower()) else int(va)
        nb = float(vb) if ("." in vb or "e" in vb.lower()) else int(vb)
    except ValueError:
        return False
    return na == -nb


# ---------------------------------------------------------------------------
# The analysis.
# ---------------------------------------------------------------------------

VIOLATION = "VIOLATION"    # demonstrably unsound
UNPROVEN = "UNPROVEN"      # outside the structural proofs this file can give


class Finding:
    def __init__(self, kind, code, fn, line, handle, msg):
        self.kind, self.code, self.fn = kind, code, fn
        self.line, self.handle, self.msg = line, handle, msg
        self.path = None

    def __str__(self):
        return (f"{self.kind} {self.code} @{self.fn} line {self.line} "
                f"[{self.handle}]: {self.msg}")


class Rail:
    __slots__ = ("name", "kind", "origin", "pos", "writes", "measured_at")

    def __init__(self, name, kind, origin, pos):
        self.name, self.kind = name, kind
        self.origin, self.pos = origin, pos
        self.writes = []          # [(pos, Call)] basis-changing, stream order
        self.measured_at = None


class StreamAnalysis:
    def __init__(self, fnname, calls, module_defs):
        self.fnname, self.calls = fnname, calls
        self.module_defs = module_defs
        self.rails = {}
        self.findings = []
        self.verified = self.sites = 0
        self.inv_pool = {}          # (base, args) -> [positions]
        self.inv_claimed = set()
        self.freed_names = {}
        self.x_parity = {}          # register -> `cqrt_x` count so far
        self._stable_memo = {}
        self.proofs = []            # [(fn, free_line, handle, rule, lines)]

    # -- main scan ---------------------------------------------------------
    def run(self):
        for pos, c in enumerate(self.calls):
            c.eff = classify(c.sym)
            if c.eff is None:
                continue
            e = c.eff
            for v in c.vals:
                if v in self.freed_names and e.role != "free":
                    self.add(VIOLATION, "F2-use-after-free", c, v,
                             f"@{c.sym} uses {v} after its cqrt_free at line "
                             f"{self.freed_names[v]}")
            # Parity MOD 2 — `cqrt_x` is an involution, so only the polarity of
            # the flag at this point matters, not how many brackets deep it is.
            c.ctl_parity = tuple(self.x_parity.get(c.vals[i], 0) & 1
                                 for i in e.controls if i < len(c.vals))
            if e.role == "free":
                self.sites += 1
                self.check_free(pos, c)
                continue
            if e.role == "measure":
                r = self.rail_for_write(c.vals[0])
                r.measured_at = c.line
                r.writes.append((pos, c))
                continue
            if e.role == "inv":
                self.inv_pool.setdefault((e.base, tuple(c.args)),
                                         []).append(pos)
            if not e.diagonal:
                for wi in e.writes:
                    if wi < len(c.vals):
                        self.rail_for_write(c.vals[wi]).writes.append((pos, c))
            if c.sym == "cqrt_x":
                self.x_parity[c.vals[0]] = self.x_parity.get(c.vals[0], 0) + 1
            if e.mints in ("rail", "array", "tape") and c.res:
                kind = {"rail": "alloc" if e.role == "alloc" else "mint",
                        "array": "array", "tape": "tape"}[e.mints]
                self.rails[c.res] = Rail(c.res, kind, c, pos)
        self.check_orphan_reversals()
        return self.findings

    def check_orphan_reversals(self):
        """Every `_inv` must be claimed by exactly one free.

        An `_inv` is the ONLY construct in the lowered IR that writes a rail the
        signature does not name (bd 8txa). If no free claims it, this file
        cannot say which rail it acted on — and one extra adjoint on a live rail
        is precisely the "re-paired to the wrong rail" defect the golden trace
        is blind to. Across the committed e2e corpus the pairing is an exact
        bijection (25174 tokens, 25174 claims), so an orphan is a real signal.
        """
        for positions in self.inv_pool.values():
            for p in positions:
                if p in self.inv_claimed:
                    continue
                c = self.calls[p]
                self.add(UNPROVEN, "W-orphan-reversal", c, c.res or "<void>",
                         f"`{c.text}` is an adjoint no cqrt_free claims; the "
                         f"ABI does not name the rail it acts on, so the rail "
                         f"it left (or dirtied) cannot be identified here")

    def rail_for_write(self, name):
        """The record for `name`, materialising an EXTERN one if it was not
        minted in this stream.

        Without this, a write to a handle that arrives from outside (a Phase-6
        clone parameter, a rail defined in another block) would be INVISIBLE:
        `unchanged_over` would report the operand stable because it had no
        recorded writes, and `commutes` would take a flag's `cqrt_x` parity at
        face value while a `cnot` retargeted it. Recording externs makes the
        in-stream write history complete for every handle, so "no writes here"
        is a fact rather than an absence of information. An extern rail can
        never be VERIFIED at a free (its incoming state is unknown) — see
        `U3-extern-rail`.
        """
        r = self.rails.get(name)
        if r is None:
            r = Rail(name, "extern", None, -1)
            self.rails[name] = r
        return r

    def add(self, kind, code, c, handle, msg):
        self.findings.append(Finding(kind, code, self.fnname, c.line, handle,
                                     msg))

    def ok(self, c, r, rule, witness):
        """Record a discharged free site plus the lines its proof consumed."""
        self.verified += 1
        self.proofs.append((self.fnname, c.line, r.name, rule,
                            tuple(sorted(set(witness) | {r.origin.line}))))

    # -- reduction to identity --------------------------------------------
    def writes_in(self, name, lo, hi):
        r = self.rails.get(name)
        return [] if r is None else [(p, c) for p, c in r.writes if lo < p < hi]

    def unchanged_over(self, name, lo, hi, depth=0):
        """(ok, witness lines) — `name`'s writes inside (lo, hi) net to identity."""
        if depth > 6:
            return False, frozenset()
        memo = (name, lo, hi)
        if memo in self._stable_memo:
            return self._stable_memo[memo]
        # cycle guard: assume not stable while recursing
        self._stable_memo[memo] = (False, frozenset())
        ok, _why, lines = self.reduces_to_identity(
            self.writes_in(name, lo, hi), depth + 1)
        self._stable_memo[memo] = (ok, lines)
        return ok, lines

    def adjoint_matches(self, a, b):
        """Is call `b` the adjoint of call `a` on their shared target rail?"""
        ea = a.eff
        if ea is None or ea.adjoint_of is None:
            return False
        if a.ctl_parity != b.ctl_parity:
            # Same gate on the complementary branch of its flag is NOT the
            # adjoint — composing the two is a full, unconditional operation.
            return False
        if ea.adjoint_of == "self":
            return a.key() == b.key()
        if ea.adjoint_of.startswith("negate-arg"):
            n = int(ea.adjoint_of[len("negate-arg"):])
            if a.sym != b.sym or len(a.args) != len(b.args):
                return False
            for i, (x, y) in enumerate(zip(a.args, b.args)):
                if i == n:
                    if not is_negation(x, y):
                        return False
                elif x != y:
                    return False
            return True
        if ea.adjoint_of.startswith("twin:"):
            want = ea.adjoint_of[len("twin:"):]
            return b.sym == want and a.vals == b.vals
        return False

    def commutes(self, u_pos, u, w_pos, w):
        """Do writes `u` and `w` to the same rail provably commute?

        The ONLY admitted reason is complementary flag branches: they share a
        control register whose `cqrt_x` parity differs, and that register is
        touched by nothing but `cqrt_x` between them — so the two writes act on
        disjoint branches of the same flag. This is exactly the `¬flag`
        `cqrt_x` bracket the two-arm phase emitter emits (§5b).
        """
        ucs = [(u.vals[i], p) for i, p in zip(u.eff.controls, u.ctl_parity)
               if i < len(u.vals)]
        wcs = [(w.vals[i], p) for i, p in zip(w.eff.controls, w.ctl_parity)
               if i < len(w.vals)]
        for reg, pu in ucs:
            for reg2, pw in wcs:
                if reg != reg2 or pu == pw:
                    continue
                if reg not in self.rails:
                    # Never minted and never written here: its write history is
                    # not this stream's to know, so the parity claim is not
                    # backed by anything. Decline rather than assume.
                    continue
                lo, hi = min(u_pos, w_pos), max(u_pos, w_pos)
                if all(c.sym == "cqrt_x"
                       for _, c in self.writes_in(reg, lo, hi)):
                    return True
        return False

    def reduces_to_identity(self, ws, depth=0):
        """Cancel adjoint pairs (commutation-aware).

        Returns (ok, reason, witness) where `witness` is the set of SOURCE LINES
        the proof consumed — every cancelled pair, plus the pairs any nested
        operand-stability check consumed. Deleting or corrupting any witness
        line must break this proof; that is what the mutant self-test targets.
        """
        stack, witness = [], set()
        for p, c in ws:
            placed = False
            for k in range(len(stack) - 1, -1, -1):
                pk, ck = stack[k]
                if not self.adjoint_matches(ck, c):
                    continue
                if not all(self.commutes(stack[m][0], stack[m][1], p, c)
                           for m in range(k + 1, len(stack))):
                    continue
                ok, sub = self.pair_operands_unchanged(ck, pk, p, depth)
                if not ok:
                    continue
                witness |= sub
                witness.add(ck.line)
                witness.add(c.line)
                del stack[k]
                placed = True
                break
            if not placed:
                stack.append((p, c))
        if not stack:
            return True, None, frozenset(witness)
        p, c = stack[0]
        return False, (f"write `{c.text}` (line {c.line}) is never cancelled "
                       f"by an adjoint ({len(stack)} of {len(ws)} write(s) "
                       f"left after reduction)"), frozenset(witness)

    def pair_operands_unchanged(self, c1, p1, p2, depth):
        acc = set()
        for ri in c1.read_idx():
            if ri >= len(c1.vals):
                continue
            v = c1.vals[ri]
            if v not in self.rails:
                continue
            ok, lines = self.unchanged_over(v, p1, p2, depth)
            if not ok:
                return False, frozenset()
            acc |= lines
        return True, frozenset(acc)

    # -- the free site -----------------------------------------------------
    def check_free(self, pos, c):
        name = c.vals[0]
        if name in self.freed_names:
            self.add(VIOLATION, "F1-double-free", c, name,
                     f"already freed at line {self.freed_names[name]}")
            return
        self.freed_names[name] = c.line
        r = self.rails.get(name)
        if r is None:
            where = self.module_defs.get(name)
            if where is None:
                self.add(UNPROVEN, "U2-unknown-def", c, name,
                         "no definition for the freed handle in this function")
            else:
                self.add(UNPROVEN, "U1-cross-stream", c, name,
                         f"handle is defined by @{where[1]} outside this "
                         f"straight-line stream, so its write history is not "
                         f"linearly ordered here")
            return
        if r.kind == "extern":
            where = self.module_defs.get(name)
            self.add(UNPROVEN, "U3-extern-rail", c, name,
                     f"handle is written in this stream but minted outside it"
                     + (f" (by @{where[1]})" if where else "")
                     + "; its state on entry to this stream is unknown")
            return
        if r.kind in ("array", "tape"):
            self.add(VIOLATION, "F9-free-of-nonrail", c, name,
                     f"{r.kind} resource token minted by @{r.origin.sym} is "
                     f"not a rail and must never be freed")
            return
        if r.measured_at is not None:
            self.add(VIOLATION, "F8-free-after-measure", c, name,
                     f"handle was measured at line {r.measured_at}; the "
                     f"measurement owns it (Rule 6)")
            return
        if r.kind == "alloc":
            self.check_alloc_rail(pos, c, r)
        else:
            self.check_minted_rail(pos, c, r)

    def check_alloc_rail(self, pos, c, r):
        ws = [(p, w) for p, w in r.writes if r.pos < p < pos]
        # (A1) classical-immediate updates keep a known classical basis state.
        if ws and all(w.eff.classical_imm for _, w in ws):
            self.ok(c, r, "A1-classical-immediate", {w.line for _, w in ws})
            return
        # (A2) otherwise the history must return the rail to its alloc value.
        ok, why, wit = self.reduces_to_identity(ws)
        if ok:
            self.ok(c, r, "A2-reduces-to-identity", wit)
        else:
            self.add(UNPROVEN, "A-not-reducible", c, r.name,
                     f"rail allocated at line {r.origin.line} by "
                     f"@{r.origin.sym}: {why}; cannot prove it holds a known "
                     f"classical basis state at the free")

    def check_minted_rail(self, pos, c, r):
        fwd, base = r.origin, r.origin.sym
        fwd_args = tuple(fwd.args)

        # (T1a) an explicit `_unc(%r, forward args...)` naming the rail.
        rev_pos = rev_kind = None
        for p, w in r.writes:
            if r.pos < p < pos and w.eff.role == "unc" and \
                    w.eff.base == base and tuple(w.args[1:]) == fwd_args:
                rev_pos, rev_kind = p, "_unc"
        # (T1b) otherwise an unclaimed `_inv(forward args...)` token.
        if rev_pos is None:
            # EARLIEST unclaimed token in the window, not the latest. Free
            # sites are visited in stream order (increasing right endpoint), so
            # "smallest feasible available token" is the optimal matching here;
            # taking the latest can strand a later free whose window is
            # narrower and report a reversal that exists as missing.
            cands = [p for p in self.inv_pool.get((base, fwd_args), [])
                     if r.pos < p < pos and p not in self.inv_claimed]
            if cands:
                rev_pos, rev_kind = min(cands), "_inv"
                self.inv_claimed.add(rev_pos)
        if rev_pos is None:
            pre = [(p, w) for p, w in r.writes if r.pos < p < pos]
            # If the rail's own writes net to identity it DEMONSTRABLY still
            # holds f(args) at the free; only an unrecognised write history
            # leaves room for some other zeroing mechanism.
            inert, _why, _wit = self.reduces_to_identity(pre)
            self.add(VIOLATION if inert else UNPROVEN, "T1-no-reversal", c,
                     r.name,
                     f"rail minted at line {fwd.line} by `{fwd.text}` is freed "
                     f"with no matching @{base}_inv / @{base}_unc reversal in "
                     f"between" + ("" if not pre else
                     f" ({len(pre)} intervening write(s), first "
                     f"`{pre[0][1].text}` at line {pre[0][1].line})"))
            return

        rev = self.calls[rev_pos]
        witness = {fwd.line, rev.line}
        # (T3) rail unchanged mint->reversal, untouched reversal->free.
        ok, why, wit = self.reduces_to_identity(
            [(p, w) for p, w in r.writes if r.pos < p < rev_pos])
        if not ok:
            self.add(UNPROVEN, "T3-rail-written-before-reversal", c, r.name,
                     f"rail minted at line {fwd.line}: {why}, so the "
                     f"{rev_kind} at line {rev.line} does not provably zero it")
            return
        witness |= wit
        post = [(p, w) for p, w in r.writes if rev_pos < p < pos]
        if post:
            self.add(VIOLATION, "T3-rail-written-after-reversal", c, r.name,
                     f"rail is written by `{post[0][1].text}` (line "
                     f"{post[0][1].line}) after its {rev_kind} reversal at "
                     f"line {rev.line} and before the free")
            return
        # (T2) forward operands must be unchanged across [mint, reversal].
        for v in fwd.vals:
            if v not in self.rails:
                continue
            ok, wit = self.unchanged_over(v, r.pos, rev_pos)
            if not ok:
                bad = self.writes_in(v, r.pos, rev_pos)
                self.add(UNPROVEN, "T2-operand-mutated", c, r.name,
                         f"forward operand {v} of `{fwd.text}` (line "
                         f"{fwd.line}) is written by `{bad[0][1].text}` (line "
                         f"{bad[0][1].line}) with no proof it is restored "
                         f"before the {rev_kind} reversal at line {rev.line}, "
                         f"so the reversal may recompute a different value")
                return
            witness |= wit
        self.ok(c, r, "T1-" + rev_kind.strip("_") + "-reversal", witness)


def check_module(text):
    """Returns (findings, verified_count, free_site_count, proofs).

    `proofs` is one record per VERIFIED free site: the rule that discharged it
    and the set of source lines the proof consumed. It is what
    tools/free_pairing_check_test.py mutates, so the self-test can plant a
    defect in exactly the instructions a proof rests on rather than shotgunning
    the module and drowning in semantically-null mutants.
    """
    funcs = parse_module(text)
    module_defs = {}
    for fn in funcs:
        for _, calls, _ in fn.blocks:
            for c in calls:
                if c.res:
                    module_defs[c.res] = (fn.name, c.sym)
    findings, verified, sites, proofs = [], 0, 0, []
    for fn in funcs:
        for _chain, calls in build_streams(fn):
            if not calls:
                continue
            sa = StreamAnalysis(fn.name, calls, module_defs)
            findings.extend(sa.run())
            verified += sa.verified
            sites += sa.sites
            proofs.extend(sa.proofs)
    return findings, verified, sites, proofs


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Rule-6 free-pairing checker over lowered CQ IR.")
    ap.add_argument("files", nargs="+")
    ap.add_argument("-q", "--quiet", action="store_true")
    ap.add_argument("--allow-unproven", action="store_true",
                    help="report UNPROVEN free sites without failing")
    ap.add_argument("--stats", action="store_true")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--explain", action="store_true",
                    help="print, per verified free site, the rule that "
                         "discharged it and the source lines its proof rests on")
    args = ap.parse_args(argv)

    all_findings, verified, sites, unclassified = [], 0, 0, []
    for path in args.files:
        try:
            with open(path) as fh:
                text = fh.read()
        except OSError as e:
            print(f"free_pairing_check: cannot read {path}: {e}",
                  file=sys.stderr)
            return 2
        try:
            f, v, s, proofs = check_module(text)
        except Unclassified as e:
            unclassified.append((path, e.sym))
            continue
        for x in f:
            x.path = path
        all_findings.extend(f)
        verified += v
        sites += s
        if args.explain:
            for fn, line, handle, rule, lines in proofs:
                print(f"{path}: OK @{fn} line {line} [{handle}] via {rule} "
                      f"(witness lines {','.join(str(x) for x in lines)})")

    viol = [f for f in all_findings if f.kind == VIOLATION]
    unpr = [f for f in all_findings if f.kind == UNPROVEN]

    if args.json:
        def dump(fs):
            return [{"code": f.code, "file": f.path, "fn": f.fn,
                     "line": f.line, "handle": f.handle, "msg": f.msg}
                    for f in fs]
        print(json.dumps({"files": len(args.files), "free_sites": sites,
                          "verified": verified, "violations": dump(viol),
                          "unproven": dump(unpr),
                          "unclassified": [{"file": p, "symbol": s}
                                           for p, s in unclassified]},
                         indent=2))
    else:
        for path, sym in unclassified:
            print(f"free_pairing_check: {path}: UNCLASSIFIED SYMBOL @{sym} — "
                  f"add its read/write effects to classify() before trusting "
                  f"any verdict from this file", file=sys.stderr)
        for f in viol:
            print(f"{f.path}: {f}", file=sys.stderr)
        for f in unpr:
            print(f"{f.path}: {f}",
                  file=sys.stdout if args.allow_unproven else sys.stderr)
        if not args.quiet or viol or unpr or unclassified:
            print(f"free_pairing_check: {len(args.files)} file(s), {sites} "
                  f"cqrt_free site(s): {verified} verified, {len(viol)} "
                  f"violation(s), {len(unpr)} unproven"
                  + (f", {len(unclassified)} unclassified symbol(s)"
                     if unclassified else ""))
    if args.stats:
        for k, n in Counter(f.code for f in all_findings).most_common():
            print(f"   {n:6d}  {k}")

    if unclassified or viol:
        return 1
    if unpr and not args.allow_unproven:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
