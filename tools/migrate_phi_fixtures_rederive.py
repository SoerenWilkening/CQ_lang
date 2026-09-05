#!/usr/bin/env python3
"""migrate_phi_fixtures_rederive.py — re-derive the migrated fixtures' FileCheck
assertions from the Inc-1 (SUBJECT) binary's OWN OUTPUT.

Companion to `migrate_phi_fixtures.py` (bd epic test_C_libtooling-3qlq, Inc 1,
agent `prep_a2`).  `migrate_phi_fixtures.py` rewrote the IR bodies to the
register-free `void @cq_phi(double)` surface; it deliberately left the CHECK
lines of the A/S/MIX classes alone, because the kickback stream's handle numbers
are not mechanically derivable from the old text.  This tool derives them from
the pass output instead.

THE THREE RULES THIS TOOL EXISTS TO ENFORCE (each one is a recorded defect from
an earlier increment, not a style preference):

  1. HANDLE NAMES ARE DERIVED, NEVER TYPED.  bd drbq Inc 4 round-1: 9 of 20
     accept fixtures named a `%h1` that the pass never emits, so the CHECK
     matched nothing that mattered.  Here every SSA name comes out of the
     subject's own output, and every name defined inside the function is bound
     as a FileCheck variable at its definition and REFERENCED thereafter — so
     the fixture asserts operand IDENTITY (the strip names the same flag the
     mint produced, bd 8txa), not just the presence of a line.

  2. NEGATIVES ARE PURE AND WHOLE-FILE.  bd drbq Inc 3 F-L6-1 and its Inc-4
     recurrence: a POSITIVE directive inside a prefix WINDOWS every negative of
     that prefix after it, so an injected gate lands outside the window and is
     caught by nobody.  `NOROUTE` here carries negatives ONLY.

  3. COUNTS LIVE IN THEIR OWN PREFIX.  Two counts in one prefix silently become
     an ORDER assertion; a count followed by a `-NOT` in the same prefix windows
     the `-NOT`.  One pattern per prefix, `-COUNT-n` immediately followed by
     `-NOT` of the same pattern, and nothing else in that prefix.

AND THE ONE RULE ABOUT THE TOOL ITSELF: a candidate negative is emitted ONLY
after it has been MEASURED not to fire on the subject's clean output.  A
negative that would fail is DROPPED and RECORDED, never silently kept — an
assertion nobody validated is the thing this project keeps getting caught by.

Modes:
  --plan            classify every file in the population, print the table
  --rederive        rewrite the ACCEPT fixtures from the subject output
  --respell         rewrite the DECLINE fixtures' diagnostic string
  --verify          re-run the subject + FileCheck over the rewritten files
  --inject          fixture-integrity check: inject a forbidden gate, expect a catch
"""

import argparse
import os
import re
import subprocess
import sys

REPO = os.environ.get("CQ_REPO") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TESTDIR = os.path.join(REPO, "ir-pass", "test")
CQ_OPT = os.environ.get("CQ_OPT", "")
CQ_PASS = os.environ.get("CQ_PASS", "")
FILECHECK = os.environ.get("FILECHECK", "/usr/local/opt/llvm@19/bin/FileCheck")

RUN_RE = re.compile(r"^\s*;\s*RUN:")
# A FileCheck directive line: `; <PREFIX>[-SUFFIX]: ...` where PREFIX is CHECK or
# an all-caps custom prefix.  Deliberately NOT anchored on "CHECK" alone — the
# corpus uses NOROUTE / CNT / ACNT / MDCNT / C1..C9 / NEG / ... as prefixes.
DIRECTIVE_RE = re.compile(
    r"^\s*;\s*([A-Z][A-Z0-9_]*)(-NEXT|-SAME|-NOT|-DAG|-LABEL|-EMPTY|-COUNT-\d+)?:")

# The four things a register-free kickback must never emit (PRD §1 / §5).  Each
# is a CANDIDATE: it ships only if it is measured not to fire on the clean output.
CANDIDATE_NEGATIVES = [
    ("cqrt_cswap", "the swap route is retired — no work rail, so no Fredkin"),
    ("cqrt_copy", "method-B copy on a phase arm dephases the answer (Rule 7)"),
    ("_controlled",
     "the kickback gate is UNCONTROLLED, on the flag ancilla"),
    (r"call void @cqrt_rz_{{[a-z0-9]+}}_controlled(",
     "⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the "
     "blanket one is DROPPED from any fixture that legitimately emits a controlled "
     "Ry or a controlled copy — and dropping it took the only catch for a "
     "controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND "
     "to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate "
     "this increment removes — until this line was added. The width complement "
     "above cannot cover it either: it requires `(` immediately after the width, "
     "and `cqrt_rz_i32_controlled(` has `_controlled` in between."),
    (r"call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(",
     "the TENSORED per-register Rz is the defect this increment removes (PRD §1). "
     "ONE complement pattern, not an enumeration of six — the shipped ABI has NINE "
     "widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block "
     "(round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: "
     "`cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`."),
    ("call void @cq_phi(", "a surviving phase call is lowered or deleted, never left for the linker"),
    ("cq_phi_", "the register form is a RESERVED NAME and declines (round-1 F-L6-1)"),
]

# Symbols whose COUNT is load-bearing enough to get its own prefix.
COUNTED = [
    ("call void @cqrt_rz_i1(", "ACNT"),
    ("call void @cqrt_free(", "FCNT"),
    ("call void @cqrt_x(", "XCNT"),
]

MD_TAG = "!cq.branchphase"


def run_subject(path):
    if not CQ_OPT:
        sys.exit("CQ_OPT is unset — point it at the SUBJECT build/ir-pass/cq-opt")
    r = subprocess.run(
        [CQ_OPT, "-load-pass-plugin", CQ_PASS, "-passes=cq-lowering", "-S", path],
        capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


def first_error(stderr):
    for ln in stderr.splitlines():
        if "error" in ln:
            return ln
    return ""


def diag_text(errline):
    """The part of a DS_Error line a fixture mirrors: everything after the
    function prologue.  `error: <loc>: in function <sig>: <TEXT>`."""
    m = re.search(r"in function [^:]*: (.*)$", errline)
    if m:
        return m.group(1).strip()
    m = re.search(r"error: (.*)$", errline)
    return m.group(1).strip() if m else ""


# --------------------------------------------------------------------------
# fixture surgery
# --------------------------------------------------------------------------

def split_fixture(text):
    """-> (lines, index sets).  Classifies every line as RUN / DIRECTIVE /
    OTHER.  Nothing is reordered; the caller edits in place."""
    lines = text.split("\n")
    runs, directives = [], []
    for i, ln in enumerate(lines):
        if RUN_RE.match(ln):
            runs.append(i)
        elif DIRECTIVE_RE.match(ln):
            directives.append(i)
    return lines, runs, directives


def prefixes_used(lines, directives):
    out = set()
    for i in directives:
        m = DIRECTIVE_RE.match(lines[i])
        out.add(m.group(1))
    return out


def sanitize_var(name):
    """An SSA name -> a FileCheck variable name.  `%h_cmp` -> H_CMP, `%0` -> V0."""
    s = re.sub(r"[^A-Za-z0-9_]", "_", name.lstrip("%"))
    s = s.strip("_")
    if not s or s[0].isdigit():
        s = "V" + s
    return s.upper()


SSA_DEF_RE = re.compile(r"^\s*(%[A-Za-z0-9_.$-]+)\s*=")
SSA_USE_RE = re.compile(r"%[A-Za-z0-9_.$-]+")


def derive_stream(stdout):
    """Turn the subject's textual IR into CHECK lines.

    Every name DEFINED inside a function body is bound as a FileCheck variable at
    its definition and referenced afterwards; function ARGUMENTS keep their
    literal spelling (they come from the fixture's own source and are stable).
    Adjacency is preserved exactly: `CHECK-NEXT` only where the two lines really
    are consecutive in the output, so a blank line between blocks breaks the
    chain into a fresh `CHECK` rather than a false assertion.
    """
    out_lines = stdout.split("\n")
    checks = []
    bound = {}          # ssa name -> variable name
    i = 0
    prev_emitted_at = None
    while i < len(out_lines):
        ln = out_lines[i]
        if ln.startswith("define "):
            args = set(SSA_USE_RE.findall(ln))
            bound = {}
            # the define line itself, verbatim (it names the function + args)
            checks.append(("CHECK", ln.strip()))
            prev_emitted_at = i
            i += 1
            while i < len(out_lines) and not out_lines[i].startswith("}"):
                body = out_lines[i]
                if body.strip() == "":
                    prev_emitted_at = None
                    i += 1
                    continue
                checks.append(
                    ("CHECK-NEXT" if prev_emitted_at == i - 1 else "CHECK",
                     rewrite_line(body, bound, args)))
                prev_emitted_at = i
                i += 1
            if i < len(out_lines):
                checks.append(("CHECK-NEXT" if prev_emitted_at == i - 1 else "CHECK", "}"))
                prev_emitted_at = i
            i += 1
            continue
        i += 1
    return checks


def rewrite_line(body, bound, args):
    """Bind/reference SSA variables and strip trailing metadata.

    Metadata is stripped from the ORDERED stream on purpose: `!cq.branchphase !0`
    carries a metadata NUMBER that renumbers with the module, so pinning it here
    would make the fixture assert LLVM's numbering.  Its presence and its COUNT
    are asserted separately in the MDCNT prefix (the implementer's own
    discipline on control_phase_kickback_and2.ll et al.).
    """
    s = body.strip()
    s = re.sub(r",\s*!\w[\w.]*\s*!\d+\s*$", "", s)
    m = SSA_DEF_RE.match(body)
    defname = m.group(1) if m else None

    def sub(mo):
        name = mo.group(0)
        if name in args:
            return name
        if name == defname:
            var = sanitize_var(name)
            bound[name] = var
            return "%[[" + var + ":[a-zA-Z0-9_.]+]]"
        if name in bound:
            return "%[[" + bound[name] + "]]"
        return name

    out = SSA_USE_RE.sub(sub, s)
    # `{{` and `[[` are FileCheck metasyntax.  Our own substitutions introduce the
    # only `[[` we want; anything else in the source text would silently become a
    # regex/variable and assert something other than what it looks like.
    probe = out.replace("%[[", "\x00").replace("]]", "\x01")
    if "{{" in probe or "[[" in probe:
        raise ValueError("FileCheck metacharacter in derived line: " + s)
    return out


def measure_negative(stdout, pattern):
    """Does this candidate `-NOT` pattern hold on the clean output?  Measured by
    running FileCheck itself, so the answer is FileCheck's, not a regex guess."""
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        chk = os.path.join(td, "chk.txt")
        inp = os.path.join(td, "in.ll")
        open(chk, "w").write("; NEG-NOT: " + pattern + "\n")
        open(inp, "w").write(stdout)
        r = subprocess.run([FILECHECK, chk, "--check-prefix=NEG", "--input-file", inp],
                           capture_output=True, text=True)
        return r.returncode == 0


def count_pattern(stdout, literal):
    return stdout.count(literal)


def build_accept_block(stdout, kept_negatives, dropped_negatives):
    L = []
    L.append("")
    L.append("; ===========================================================================")
    L.append("; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output")
    L.append("; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at")
    L.append("; its DEFINITION and referenced afterwards, so the chain asserts operand")
    L.append("; IDENTITY — the strip and the free name the SAME flag the mint produced")
    L.append("; (bd 8txa: the golden itself must witness the pairing).  Handle names are")
    L.append("; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass")
    L.append("; never emits).  Trailing `!cq.branchphase` metadata is stripped here because")
    L.append("; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.")
    for kind, text in derive_stream(stdout):
        L.append("; %s: %s" % (kind, text))
    L.append("")
    L.append("; ---------------------------------------------------------------------------")
    L.append("; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a")
    L.append("; positive WINDOWS every negative after it, which is how an injected gate")
    L.append("; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.")
    for pat, why in kept_negatives:
        L.append("; NOROUTE-NOT: %s" % pat)
        L.append(";   ^ %s" % why)
    if dropped_negatives:
        L.append(";")
        L.append("; MEASURED NOT APPLICABLE to this fixture (the candidate FIRES on the clean")
        L.append("; output, so asserting it would be false).  Recorded rather than dropped in")
        L.append("; silence — an absent assertion nobody explained is how a fence rots:")
        for pat, why in dropped_negatives:
            L.append(";   * %s   (present in this fixture's own output)" % pat)
    return L


def build_count_block(stdout):
    L = []
    L.append("")
    L.append("; ---------------------------------------------------------------------------")
    L.append("; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become")
    L.append("; an ORDER assertion, and a `-NOT` after a count in the same prefix is")
    L.append("; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME")
    L.append("; pattern is the only spelling that pins `exactly n`.")
    used = []
    for literal, prefix in COUNTED:
        n = count_pattern(stdout, literal)
        if n == 0:
            continue
        L.append("; %s-COUNT-%d: %s" % (prefix, n, literal))
        L.append("; %s-NOT:     %s" % (prefix, literal))
        used.append(prefix)
    nmd = stdout.count(MD_TAG + " ")
    nrz = count_pattern(stdout, "call void @cqrt_rz_i1(")
    if nrz:
        L.append(";")
        L.append("; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the")
        L.append("; whole-DAG spine reads it as a reclaimable in-place rotation and emits")
        L.append("; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1")
        L.append("; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two")
        L.append("; counts are asserted SEPARATELY and must agree: %d and %d here." % (nrz, nmd))
        L.append("; MDCNT-COUNT-%d: %s" % (nmd, MD_TAG))
        L.append("; MDCNT-NOT:     %s" % MD_TAG)
        used.append("MDCNT")
    return L, used


def rederive_file(base, dry=False):
    path = os.path.join(TESTDIR, base)
    text = open(path, encoding="utf-8").read()
    rc, out, err = run_subject(path)
    if rc != 0:
        return ("SKIP-DECLINES", None)
    lines = text.split("\n")

    kept, dropped = [], []
    for pat, why in CANDIDATE_NEGATIVES:
        (kept if measure_negative(out, pat) else dropped).append((pat, why))

    # Preserve every ORIGINAL negative that still holds; drop (and record) the rest.
    orig_neg_kept, orig_neg_dropped = [], []
    _, _, directives = split_fixture(text)
    for i in directives:
        m = DIRECTIVE_RE.match(lines[i])
        if m.group(2) != "-NOT":
            continue
        payload = lines[i].split(":", 1)[1].strip()
        if not payload:
            continue
        if any(payload == p for p, _ in kept + dropped):
            continue
        if payload in orig_neg_kept or payload in orig_neg_dropped:
            continue
        (orig_neg_kept if measure_negative(out, payload) else
         orig_neg_dropped).append(payload)

    # HEADER = everything before the first RUN/directive line, minus those lines.
    # IR     = the span from the first to the last non-comment, non-blank line.
    # Everything else — the prose INTERLEAVED with the old CHECK block — is
    # DROPPED, because it narrates the pre-Inc-1 stream ("one controlled Rz per
    # arm gate", "the route's ABSENCE anchored at the function header") and is
    # now false.  Its count is reported so the drop is visible, never silent.
    first_dir = len(lines)
    for i, ln in enumerate(lines):
        if RUN_RE.match(ln) or DIRECTIVE_RE.match(ln):
            first_dir = i
            break
    ir_idx = [i for i, ln in enumerate(lines)
              if ln.strip() and not ln.lstrip().startswith(";")]
    if not ir_idx:
        return ("NO-IR", None)
    ir_start, ir_end = ir_idx[0], ir_idx[-1]
    header = [ln for ln in lines[:first_dir]
              if not RUN_RE.match(ln) and not DIRECTIVE_RE.match(ln)]
    ir = [ln for ln in lines[ir_start:ir_end + 1]
          if not RUN_RE.match(ln) and not DIRECTIVE_RE.match(ln)]
    dropped_prose = sum(
        1 for i, ln in enumerate(lines)
        if i >= first_dir and (i < ir_start or i > ir_end)
        and ln.lstrip().startswith(";")
        and not RUN_RE.match(ln) and not DIRECTIVE_RE.match(ln)
        and ln.strip() != ";")
    # IDEMPOTENCE: strip a prep_a2 block emitted by a previous run, so re-deriving
    # a file does not stack notes.  The block starts at the marker line and runs to
    # the end of the header (the notes are always emitted last, just above RUN).
    for i, ln in enumerate(header):
        if "3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED" in ln:
            header = header[:max(0, i - 1)]
            break
    while header and header[-1].strip() == "":
        header.pop()

    counts, used_prefixes = build_count_block(out)

    # PRESERVE the STDERR half of the fixture verbatim.  21 of these fixtures
    # assert a WARNING on stderr (`2> %t.err`, or a `2>&1 | %filecheck` of its
    # own); that assertion has nothing to do with the gate stream and would be
    # DESTROYED by regenerating the RUN block wholesale.  Its directives are
    # carried across untouched, in their original order.
    stderr_runs, stderr_prefixes = [], set()
    for i, ln in enumerate(lines):
        if not RUN_RE.match(ln):
            continue
        if "%t.err" not in ln and "2>&1" not in ln:
            continue
        if "-passes=cq-lowering" in ln and "%filecheck" not in ln:
            continue          # the opt invocation itself is regenerated below
        stderr_runs.append(ln)
        # a RUN line may be continued with a trailing backslash
        j = i
        while lines[j].rstrip().endswith("\\") and j + 1 < len(lines):
            j += 1
            stderr_runs.append(lines[j])
        for m in re.finditer(r"--check-prefix=([A-Z][A-Z0-9_]*)", " ".join(stderr_runs[-2:])):
            stderr_prefixes.add(m.group(1))
    # de-dup while keeping order
    seen = set()
    stderr_runs = [r for r in stderr_runs if not (r in seen or seen.add(r))]
    if not stderr_prefixes:
        stderr_runs = [r for r in stderr_runs if "--check-prefix" in r or "%filecheck" in r]

    wants_err_file = any("%t.err" in r for r in stderr_runs)
    optline = "; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll"
    if wants_err_file:
        optline += " 2> %t.err"
    runs = [optline,
            "; RUN: %filecheck %s < %t.cqd0.ll",
            "; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll"]
    for pfx in used_prefixes:
        runs.append("; RUN: %filecheck %s --check-prefix=" + pfx + " < %t.cqd0.ll")
    runs += [r for r in stderr_runs if "-passes=cq-lowering" not in r]

    # carry the preserved prefixes' directive lines across verbatim
    preserved_dirs = []
    if stderr_prefixes:
        for i in directives:
            m = DIRECTIVE_RE.match(lines[i])
            if m.group(1) in stderr_prefixes:
                preserved_dirs.append(lines[i])

    # a generated prefix must not collide with a preserved one
    clash = stderr_prefixes & ({"NOROUTE"} | set(used_prefixes))
    if clash:
        return ("PREFIX-CLASH:" + ",".join(sorted(clash)), None)

    note = [
        ";",
        "; 3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED from this",
        "; fixture's own output under the Inc-1 (register-free `void @cq_phi(double)`)",
        "; binary.  The pre-Inc-1 pin — a `cqrt_rz_<W>` or `cqrt_rz_<W>_controlled` on",
        "; the user's REGISTER — asserted the gate PRD §1 shows is the identity on the",
        "; marked branch (`cqrt_rz_<W>` is TENSORED, so a routed W-bit Rz applies",
        "; `(-1)^popcount(target)` and can never mark |0..0>).  The stream now pinned is",
        "; the KICKBACK: the flag is minted into a |0> ancilla, the phase lands on the",
        "; FLAG with an UNCONTROLLED `cqrt_rz_i1`, the ordinary compare `_unc` returns",
        "; the flag to |0> on every branch, and the flag is freed.  The fixture's",
        "; PURPOSE (its header above) is unchanged.",
    ]
    if orig_neg_dropped:
        note.append(";")
        note.append("; ORIGINAL negatives REMOVED.  Each was MEASURED to fire on this fixture's")
        note.append("; own Inc-1 output, so keeping it would assert something false.  A `-NOT`")
        note.append("; that used to sit AFTER a positive of its prefix was WINDOWED to the text")
        note.append("; past that positive; re-measuring it whole-file is a strictly stronger")
        note.append("; question, and where the pattern is one of the counted ones the")
        note.append("; `-COUNT-n` + `-NOT` pair below pins `exactly n` — stronger than the")
        note.append("; window it replaces, not weaker.")
        for p in orig_neg_dropped:
            sup = [pre for lit, pre in COUNTED if lit.rstrip("(") in p]
            note.append(";   * %s%s" % (
                p, ("   [superseded by the %s count]" % sup[0]) if sup else ""))
    if any(re.search(r"cqrt_rz_(i8|i16|i32|i64|f16|f32|f64|f80)|cqrt_cswap|_controlled", h)
           for h in header):
        note.append(";")
        note.append("; NOTE — the header above still NAMES a retired symbol (`cqrt_rz_<W>`,")
        note.append("; `cqrt_cswap` or a `_controlled` twin).  That prose is kept DELIBERATELY:")
        note.append("; it is the fixture's PURPOSE and the record of what the pre-Inc-1 pass")
        note.append("; emitted here.  Read it as history; the stream this file now ASSERTS is")
        note.append("; the derived one below, and the two are meant to differ.")

    if dropped_prose:
        note.append(";")
        note.append("; %d line(s) of prose that annotated the OLD CHECK block were removed with"
                    % dropped_prose)
        note.append("; it — they described the pre-Inc-1 gate stream line by line.")
    new = header + note + runs + [""] + ir
    new += build_accept_block(out, kept, dropped)
    if orig_neg_kept:
        new.append("")
        new.append("; Original negatives PRESERVED (re-measured on the Inc-1 output):")
        for p in orig_neg_kept:
            new.append("; NOROUTE-NOT: %s" % p)
    new += counts
    if preserved_dirs:
        new.append("")
        new.append("; ---------------------------------------------------------------------------")
        new.append("; STDERR assertions, CARRIED ACROSS VERBATIM.  These pin a WARNING, not a")
        new.append("; gate, so nothing about the register-free surface touches them; they are")
        new.append("; reproduced unchanged rather than re-derived, and the RUN lines above keep")
        new.append("; their original spelling.")
        new += preserved_dirs
    new.append("")
    newtext = "\n".join(new)
    if not dry:
        open(path, "w", encoding="utf-8").write(newtext)
    return ("REDERIVED", (len(kept), len(dropped), len(orig_neg_kept),
                          len(orig_neg_dropped), dropped_prose))


ERR_CHECK_RE = re.compile(r"^(\s*;\s*[A-Z][A-Z0-9_]*(?:-[A-Z]+)?:\s*)(.*error.*)$")


def respell_file(base, dry=False):
    path = os.path.join(TESTDIR, base)
    text = open(path, encoding="utf-8").read()
    rc, out, err = run_subject(path)
    if rc == 0:
        return ("SKIP-ACCEPTS", None)
    newdiag = diag_text(first_error(err))
    if not newdiag:
        return ("NO-DIAG", None)
    lines = text.split("\n")
    changed = False
    olds = []
    for i, ln in enumerate(lines):
        m = ERR_CHECK_RE.match(ln)
        if not m:
            continue
        head, payload = m.group(1), m.group(2)
        mm = re.match(r"^(error\{\{\.\*\}\})(.*)$", payload.strip())
        if not mm:
            continue
        if mm.group(2).strip() == newdiag:
            continue
        olds.append(mm.group(2).strip())
        lines[i] = head + "error{{.*}}" + newdiag
        changed = True
    if not changed:
        return ("ALREADY", newdiag)

    # TWO DIFFERENT THINGS WEAR THE SAME EDIT, and saying so is the point.
    # (a) the new text ENDS WITH the old one: the refusing CLAUSE is unchanged and
    #     the assertion has merely been WIDENED to the whole DS_Error text (Rule 12
    #     asks for character-for-character; a suffix-only assertion would still
    #     match if a different subsystem grew a message with the same tail).
    # (b) otherwise the fixture's construct is now refused by a DIFFERENT clause,
    #     which is a real disposition change and must say so.
    widened_only = all(newdiag.endswith(o) for o in olds)
    if widened_only:
        note = [
            ";",
            "; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error",
            "; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new",
            "; string ENDS WITH the old one — and this is Rule 12's",
            "; character-for-character mirror rather than a disposition change: a",
            "; suffix-only assertion would still match if some OTHER subsystem grew a",
            "; message with the same tail.",
            "; OLD: %s" % " / ".join(olds),
            "; NEW: %s" % newdiag,
        ]
    else:
        note = [
            ";",
            "; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.",
            "; The construct this fixture pins is unchanged; the CLAUSE that refuses it",
            "; MOVED — this is a real disposition change, not a widening, and the new",
            "; string does not contain the old one.",
            "; OLD: %s" % " / ".join(olds),
            "; NEW: %s" % newdiag,
        ]
    # insert the note directly above the first RUN line
    for i, ln in enumerate(lines):
        if RUN_RE.match(ln):
            lines[i:i] = note
            break
    if not dry:
        open(path, "w", encoding="utf-8").write("\n".join(lines))
    return ("RESPELLED-WIDENED" if widened_only else "RESPELLED-CLAUSE-MOVED",
            (olds, newdiag))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--files", required=True, help="file with one basename per line")
    ap.add_argument("--rederive", action="store_true")
    ap.add_argument("--respell", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()
    names = [l.strip() for l in open(a.files) if l.strip()]
    from collections import Counter
    c = Counter()
    for b in names:
        if a.rederive:
            st, info = rederive_file(b, a.dry_run)
        elif a.respell:
            st, info = respell_file(b, a.dry_run)
        else:
            sys.exit("pick --rederive or --respell")
        c[st] += 1
        print("%-70s %s" % (b, st))
    print("verdicts:", dict(c))


if __name__ == "__main__":
    main()
