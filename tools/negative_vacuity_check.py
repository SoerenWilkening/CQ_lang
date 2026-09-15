#!/usr/bin/env python3
"""negative_vacuity_check.py — is a fixture's NEGATIVE actually checking anything?

WHY THIS EXISTS (bd test_C_libtooling-jdec)
===========================================
A negative `CHECK-NOT` that can never match passes forever, for the wrong
reason, and looks exactly like a negative that is doing its job. CLAUDE.md
Rule 12 lists three fixture-hygiene defects that each shipped undetected
through a green suite; this file is the committed instrument for the ones that
are decidable from the fixture plus the lowered module.

It replaces five divergent copies of a throwaway script that had been passed
from session to session (`trackM`, `trackD`, `trackU`, `trackP`, `trackW`
under `docs/prd/.../inc1-records/`). Their measured defects, all of which this
file fixes, are worth naming because they are the instrument failure mode this
project keeps rediscovering — AN INSTRUMENT'S FAILURE MODE IS TO REPORT A PASS:

  * IT PRINTED `checked 0` AND EXITED 0. The inherited matcher recognised only
    the HANDLE form `; NOX-NOT: ... (i32 %h)`, so Track W's batch of 29 real
    negatives — every one of them a SYMBOL negative — scored as zero checks and
    read at a glance as "29 checked, 0 vacuous" (bd jdec). A harness that
    reports `n/a` is a HOLE, not a pass. Here, zero evaluated checks over a
    non-empty batch is EXIT 2.
  * IT NAMED A WORKTREE THAT NO LONGER EXISTS. `REPO` was hard-coded to
    `/Users/sorenwilkening/Desktop/CQ_mphi` (and `CQ_3d8q`, `CQ_undef`,
    `CQ_wx8g` in the copies) — directories deleted when those sessions closed,
    so the shared script the session protocol points every track at raises
    `FileNotFoundError` today. A gate result is a fact about a BINARY: this
    file takes the binary as an argument, defaults it from its own location,
    refuses to run without it, and PRINTS ITS SHA-256 with the verdict.
  * IT SKIPPED SILENTLY. `if o.returncode != 0: continue` dropped every fixture
    whose module declines, with no count and no note.
  * IT ASKED ONE QUESTION. Definedness of an SSA handle, and nothing else.

WHAT IT ASKS
============
  (V0) DID ANYTHING GET COMPILED? A 0-byte `.ll` — and a module with no
       `define` — ACCEPTS through the pass's passthrough early-out, exit 0. Six
       probes once scored ACCEPT on nothing this way, because `sed X.s1.ll >
       X.S1.ll` collides on a case-insensitive filesystem (bd memory
       `empty-module-accepts-vacuity-trap`). A fixture with no function body is
       a HOLE, not a pass.
  (V1) DOES THE PATTERN MATCH THE MODULE'S OWN HEADER? bd `qta2`: a bare
       `-NOT: <word>` can match the `; ModuleID = '<path>'` or
       `source_filename` line, which makes the fixture red for a reason that
       has nothing to do with the lowering — or, where today's path happens not
       to contain it, silently path-dependent.
       ⚠ SCOPED THE WAY FileCheck SCOPES IT, and that correction was forced by
       measurement: a `PFX-NOT` searches only the region between the preceding
       and the following POSITIVE directive of the same prefix, so a `-NOT`
       with any positive `PFX:`/`PFX-LABEL:`/... above it cannot reach the
       header at all. Reporting those as vacuous made the first draft of this
       file cry wolf — which is the "45 MISSED against fixtures that catch
       everything" failure: A HARNESS THAT RUNS A DIFFERENT COMMAND THAN lit
       MEASURES ITSELF, NOT THE FIXTURES. Only a header-reaching `-NOT` is a
       FINDING; the scoped ones are COUNTED and printed as a note, so the
       population stays visible instead of becoming silent.
  (V2) DOES THE NAME THE NEGATIVE MENTIONS EXIST ANYWHERE? The inherited
       question was "is it defined in the LOWERED module", and that question is
       WRONG for the commonest negative in this tree. Measured over all 2039
       fixtures, it produced FIVE findings and ALL FIVE WERE FALSE, in two
       classes:
         * AN ELIMINATION NEGATIVE. `; CHECK-NOT: %s = add i32` in
           spec_result_propagates.ll asserts that the INPUT's `%s = add i32
           %r, %q2` was LOWERED AWAY. Of course the lowered module does not
           define `%s` — THAT IS THE ASSERTION. Same for `%w` in
           spec_reseed_theta_source.ll and `%cq.bank` (twice) in
           railbank_promote_reject_classical_store.ll.
         * A TYPE NAME. `; CHECK-NOT: alloca %union.IEEEl2bits` names an LLVM
           STRUCT TYPE, which is spelled with a `%` and is not an SSA value at
           all.
       So the question asked here is the weaker, correct one: DOES THE NAME
       APPEAR IN NEITHER THE LOWERED OUTPUT NOR THE FIXTURE'S OWN INPUT MODULE?
       A name in the input is a name the negative is about eliminating; a name
       in the output is a name it is about not producing; a name in NEITHER —
       `%h99` — is the `-NOT` that can never match, which is the defect.
       ⚠ The input side deliberately EXCLUDES the fixture's own `;` comment
       lines: a name that occurs only on the CHECK line itself is exactly the
       vacuous case, and counting the directive as its own witness would make
       this rule vacuous in turn.
       Widened three further ways, each because the narrow version reported a
       defect that was not one: quoted SSA names (`%"a b"`), FORMAL PARAMETERS
       and BASIC-BLOCK LABELS all count (`; C5-NOT: br label %head` in
       control_phase_kickback_inloop.ll named a label the output has, and the
       inherited `^%x = ` regex called it vacuous).
  (V3) DOES ANY LOWERED MODULE CONTAIN WHAT THIS NEGATIVE NAMES? Reported as
       a NOTE, never as a verdict, and the reason is the most useful thing
       this file learned about itself.
       ⚠ **V3 CANNOT DISTINGUISH A VACUOUS NEGATIVE FROM A WORKING ONE, AND
       SHIPPING IT AS A VERDICT WAS A MISTAKE CAUGHT BY MEASUREMENT.** The
       first draft asked "does this symbol appear in some lowered module of the
       universe?" and answered VACUOUS when it did not. Run over all 2039
       fixtures against a 1005-module universe it produced **1116 findings and
       every one examined was FALSE**: `; NOUNDEF-NOT: i1 undef` (the pass
       normalises undef seeds away — bd `z9t1` — so its absence IS the
       assertion), `; NOROUTE-NOT: double 0xFFF` (a constant that must never be
       emitted), `; NOROUTE-NOT: cq_phi_` (the front-end postcondition).
       **A `-NOT` naming something the compiler must NEVER emit is the most
       valuable negative in the tree, and "absent from every lowered module" is
       what it means for that negative to be PASSING.** Universe membership
       cannot separate "impossible by construction of the ABI" (a misspelt
       `@cqrt_teleport_i32` — genuinely vacuous) from "forbidden by the
       lowering" (`i1 undef` — genuinely working). Deciding that needs the ABI
       GRAMMAR, not a corpus, and this file does not have it.
       So V3 prints a NOTE with the count, `--strict-unreachable` promotes it
       for a batch whose author asserts otherwise, and the exit code is driven
       by (V0)/(V1)/(V2)/(V4), which are sound.
       The FRONT-END exclusion is kept and widened to the bare spellings
       (`cq_theta_` as well as `@cq_theta_`), because those pin the pass's own
       postcondition — `declineSurvivingIntrinsicCalls` makes "no `@cq_*`
       survives" a checked, LOUD property (Rule 1).
  (V4) IS THE PREFIX EVEN RUN? A `; FOO-NOT:` whose prefix `FOO` is passed to
       no `FileCheck` on any RUN line of that file is never evaluated at all —
       the strongest form of vacuous, and the only one decidable with no
       compiler. MEASURED over `ir-pass/test/*.ll` at the time this file
       landed: 0 of 1994 fixtures. The check is cheap and the population is
       empty today; that is a measurement, not a reason to drop it.
  (V5) IS THE NEGATIVE ABOUT IR THAT WAS NEVER PRINTED? Rule-12 hygiene defect
       (b): a `DS_Error` decline writes 0 bytes to STDOUT, so an IR-text
       `CHECK-NOT` in a decline fixture is pinned by the `not` inversion on the
       RUN line, not by the check. REPORTED AND COUNTED, never failed on: it is
       the documented, accepted shape of ~1000 decline fixtures in this tree,
       and turning it into an error would make this file unusable as a gate.
       `--strict-decline` promotes it, for a batch that claims otherwise.

WHAT IT DOES NOT ASK, AND WILL NOT PRETEND TO
=============================================
  * Whether a POSITIVE `CHECK` is meaningful. That is the injection matrix's
    job (mutate the accept, watch the fixture catch it).
  * Whether a negative is SEMANTICALLY the right negative. A `-NOT` that names
    a real, emittable symbol in a module that defines the handle can still be
    checking the wrong thing.
  * Anything about a fixture whose RUN line the joiner below cannot parse: such
    a fixture is counted as UNPARSED and, like every other non-evaluation here,
    it is REPORTED, and a batch that is entirely unparsed is EXIT 2.
  * Anything about a fixture WHOSE COMPILER INPUT IS NOT `%s`. Measured on this
    tree: `lowering_predmux_purecallee_deep_chain.ll` (bd `ziuw`) GENERATES its
    modules with `%python %S/Inputs/gen_deep_pure_chain.py 60000 accept >
    %t.acc.ll` and runs `cq-opt` on THOSE. Lowering `%s` there answers a
    question about a different module — "A HARNESS THAT RUNS A DIFFERENT
    COMMAND THAN lit MEASURES ITSELF, NOT THE FIXTURES". Such a fixture is
    NOT-MODELLED: counted, reported, never scored. (Without this it was about
    to be reported V0-EMPTY-MODULE, which would have been a fabricated defect
    on a fixture that is fine.)

EXIT CODES
==========
  0  at least one check was evaluated and none was vacuous. NOTEs (V3, V5,
     a latent header collision, an unmodelled stream) are printed and counted
     but do not change the code — each is a POPULATION this file can see and
     cannot adjudicate, and hiding one would be the silence it exists to stop.
  1  at least one VACUOUS finding
  2  A HOLE: nothing was evaluated, the compiler is missing or unusable, a
     module is empty, or V3 was requested with an empty universe. Never 0.

USAGE
=====
  tools/negative_vacuity_check.py [--cq-opt P] [--pass-plugin P]
        [--universe GLOB ...] [--strict-decline] [-v] FIXTURE.ll ...
"""
import argparse
import glob as _glob
import hashlib
import os
import re
import subprocess
import sys

# A FileCheck directive line. The prefix is required to be UPPERCASE because
# this tree spells every prefix that way and prose in a `;` comment otherwise
# matches in the hundreds — MEASURED: a permissive prefix regex reported 719
# fixtures with an "orphan prefix", every one of them a comment like
# `; bd 3qlq: ...`. A checker that cries wolf 719 times is a checker nobody
# reads (CLAUDE.md L10: a gate expected to be red is a gate people stop
# reading).
DIRECTIVE_RE = re.compile(
    r"^;\s*([A-Z][A-Z0-9_]*)-(NOT|NEXT|DAG|SAME|LABEL|EMPTY|COUNT-\d+):\s*(.*)$")
PLAIN_CHECK_RE = re.compile(r"^;\s*([A-Z][A-Z0-9_]*):\s*(.*)$")
RUN_RE = re.compile(r"^;\s*RUN:\s?(.*)$")
PREFIX_FLAG_RE = re.compile(r"--?check-prefix(?:es)?[= ]([A-Za-z0-9_,-]+)")
# `%h`, `%0`, `%"quoted name"`.
SSA_RE = re.compile(r"%(?:\"[^\"]+\"|[-\w.$]+)")
DEFINED_RE = re.compile(r"^\s*(%(?:\"[^\"]+\"|[-\w.$]+))\s*=", re.M)
DEFINE_LINE_RE = re.compile(r"^define\s", re.M)
# A BASIC-BLOCK LABEL. `%head` in `br label %head` is defined by a `head:` line,
# not by a `%x = ` line — the inherited regex knew only the latter, so
# `; C5-NOT: br label %head` in control_phase_kickback_inloop.ll was reported
# VACUOUS when the label is right there in the output. Found by running this
# file over the tree before shipping it, which is the whole point.
LABEL_RE = re.compile(r"^([-\w.$]+):", re.M)
# The front-end intrinsics — see (V3)'s exclusion.
FRONTEND_STEMS = ("cq_theta_", "cq_phi_", "cq_measure_", "cq_invert_")


def is_frontend_pattern(pat):
    """Does this negative pin the pass's own no-surviving-intrinsic
    postcondition? Matched on the STEM, with or without a leading `@` or a
    `call ...` prefix — the bare spelling `; NOROUTE-NOT: cq_phi_` is the one
    the tree actually uses, and the first draft's `@`-anchored list missed it."""
    return any(st in pat for st in FRONTEND_STEMS)
# A pattern that is ABOUT IR rather than about a diagnostic string.
IRISH_RE = re.compile(r"(@cqrt_|@cq_template_|@__cq_q_|^\s*call\b|"
                      r"^\s*define\b|^\s*phi\b|%[-\w.$]+\s*=)")

VACUOUS = "VACUOUS"
NOTE = "NOTE"


class Finding:
    def __init__(self, kind, code, path, line_no, line, msg):
        self.kind, self.code, self.path = kind, code, path
        self.line_no, self.line, self.msg = line_no, line, msg

    def __str__(self):
        return (f"  {self.kind}/{self.code} {os.path.basename(self.path)}"
                f":{self.line_no}: {self.msg}  |  {self.line.strip()}")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def run_lines(text):
    """The RUN pipelines of a fixture, with `\\` continuations joined.

    Returns (pipelines, ok). `ok` is False when a continuation is left open at
    EOF — an UNPARSED fixture, which is reported rather than silently treated
    as having no RUN lines at all.
    """
    out, cur = [], None
    for line in text.split("\n"):
        m = RUN_RE.match(line)
        if not m:
            continue
        body = m.group(1)
        cur = body if cur is None else cur + " " + body
        if cur.rstrip().endswith("\\"):
            cur = cur.rstrip()[:-1]
        else:
            out.append(cur)
            cur = None
    return out, cur is None


def prefixes_run(pipelines):
    """(every prefix any RUN pipeline uses, the subset this file MODELS).

    ⚠ A PREFIX IS ONLY MODELLED WHEN ITS FileCheck READS THE STREAM THIS FILE
    REPRODUCES — the plain lowering of `%s` on stdout. Measured on this tree,
    ignoring that produced FABRICATED findings in two families:

      * `railbank_promote_reject_classical_store.ll`'s `OUT`/`NOTS` prefixes
        read `--input-file=%t.dbg`, the output of
        `env CQ_RAILBANK_DBG=1 %cq-opt ...`. `%cq.bank` is absent from the
        plain lowering AND from every accepting module's stdout — and it is a
        name `RailBankPromote.cpp` mints (`SSA.Initialize(Plan.CellTy,
        "cq.bank")`), visible only on the DBG stream. Two VACUOUS verdicts, both
        wrong, both about a stream never inspected.
      * the generator fixture handled in `check_fixture`.

    A HARNESS THAT RUNS A DIFFERENT COMMAND THAN lit MEASURES ITSELF, NOT THE
    FIXTURES — so an unmodelled prefix is COUNTED and SKIPPED, never scored.
    """
    used, modelled, merged, plain_files = set(), set(), set(), set()
    # First pass: which `%t.X` files hold the PLAIN lowering of `%s`?
    for p in pipelines:
        for seg in p.split("|"):
            if "cq-opt" not in seg or "%s" not in seg:
                continue
            if re.search(r"\benv\s+CQ_\w*DBG", seg) or "CQ_" in seg.split("%cq-opt")[0]:
                continue                      # a debug stream, not plain IR
            m = re.search(r"[>]\s*(%t[\w.]*)", seg) or \
                re.search(r"-o\s+(%t[\w.]*)", seg)
            if m:
                plain_files.add(m.group(1))
    for p in pipelines:
        if "filecheck" not in p.lower():
            continue
        flags = PREFIX_FLAG_RE.findall(p)
        here = set()
        for f in flags:
            here.update(x for x in f.split(",") if x)
        if not here:
            here.add("CHECK")
        used |= here
        # What does THIS FileCheck read?
        m = re.search(r"--input-file=(\S+)", p) or re.search(r"<\s*(\S+)", p)
        if m:
            src = m.group(1)
            ok = src in plain_files
        else:
            # Piped: the producing segment is the one before the filecheck.
            segs = p.split("|")
            idx = next((i for i, x in enumerate(segs)
                        if "filecheck" in x.lower()), 0)
            prod = segs[idx - 1] if idx else ""
            ok = ("cq-opt" in prod and "%s" in prod
                  and not re.search(r"\bCQ_\w*DBG", prod))
            # `2>&1` merges the DIAGNOSTIC into the checked stream. That is the
            # whole shape of the ~1000 decline fixtures here (every one of
            # them uses it), and it IS reproducible — stdout plus stderr — so
            # it is modelled rather than skipped. The first spelling excluded
            # it and thereby blinded this file to half the corpus, which is
            # the same "instrument reports a pass about a question it never
            # asked" it exists to stop.
            if ok and "2>&1" in prod:
                merged |= here
        if ok:
            modelled |= here
    return used, modelled, merged


def lower(cq_opt, plugin, path):
    """(stdout, stderr, returncode) of the pass on one fixture."""
    try:
        o = subprocess.run([cq_opt, "-load-pass-plugin", plugin,
                            "-passes=cq-lowering", "-S", path],
                           capture_output=True, text=True)
    except OSError as e:
        print(f"negative_vacuity_check: cannot run {cq_opt}: {e}",
              file=sys.stderr)
        sys.exit(2)
    return o.stdout, o.stderr, o.returncode


def check_fixture(path, cq_opt, plugin, strict_decline, stats, deferred,
                  batch_outputs):
    findings = []
    text = open(path).read()
    pipelines, parsed = run_lines(text)
    if not parsed:
        stats["unparsed"] += 1
        return findings
    used, modelled, merged = prefixes_run(pipelines)
    # Is `%s` actually what the compiler is given? See "WHAT IT DOES NOT ASK".
    # ⚠ PER PIPELINE SEGMENT, not per pipeline. The real instance's RUN line is
    # `%cq-opt ... -S %t.acc.ll ... | %filecheck %s --check-prefix=ACC`, which
    # contains both `cq-opt` and `%s` while feeding the compiler `%t.acc.ll`.
    # Asking the looser question let that fixture through and manufactured a
    # V0-EMPTY-MODULE on it — the guard's own first spelling was the bug it
    # exists to prevent.
    if not any("%s" in seg for pl in pipelines for seg in pl.split("|")
               if "cq-opt" in seg):
        stats["not_modelled"] += 1
        return findings

    # (V0) — did anything get compiled?
    if not DEFINE_LINE_RE.search(text):
        stats["empty_modules"] += 1
        findings.append(Finding(
            VACUOUS, "V0-EMPTY-MODULE", path, 1, "",
            "the fixture defines no function: a module with no body ACCEPTS "
            "through the pass's passthrough early-out, so every verdict about "
            "it is vacuous (bd memory `empty-module-accepts-vacuity-trap`)"))
        return findings

    out, err, rc = lower(cq_opt, plugin, path)
    declines = rc != 0
    if declines:
        stats["declining"] += 1
    else:
        batch_outputs.append(out)
    header = "\n".join(l for l in out.splitlines()
                       if l.startswith("; ModuleID") or
                       l.startswith("source_filename"))
    positives_seen = set()
    defined = set(DEFINED_RE.findall(out))
    for m in re.finditer(r"^define\s[^@]*@[\w.$\"]+\s*\(([^)]*)\)", out, re.M):
        defined.update(SSA_RE.findall(m.group(1)))
    defined.update("%" + lbl for lbl in LABEL_RE.findall(out))
    # The fixture's OWN module text, comment lines removed — see (V2). A name
    # the input carries is a name an ELIMINATION negative is legitimately about.
    module_in = "\n".join(l for l in text.split("\n")
                          if not l.lstrip().startswith(";"))

    for i, line in enumerate(text.split("\n"), 1):
        m = DIRECTIVE_RE.match(line)
        if m:
            pfx, kind, pat = m.group(1), m.group(2), m.group(3)
        else:
            m2 = PLAIN_CHECK_RE.match(line)
            if not m2 or m2.group(1) in ("RUN", "REQUIRES", "XFAIL",
                                         "UNSUPPORTED"):
                continue
            # A bare `; PFX:` counts only when PFX is a prefix this fixture's
            # RUN lines actually pass — otherwise it is prose.
            if m2.group(1) not in used:
                continue
            pfx, kind, pat = m2.group(1), "CHECK", m2.group(2)

        # The stream THIS prefix's FileCheck reads: stdout, or stdout+stderr
        # when the RUN line merged them with `2>&1`.
        stream = (out + "\n" + err) if pfx in merged else out
        # A prefix whose FileCheck reads a stream this file does not
        # reproduce is SKIPPED — counted, never scored. (V4) still applies:
        # a prefix no RUN line uses at all is vacuous whatever it reads.
        if pfx in used and pfx not in modelled:
            if kind == "NOT":
                stats["unmodelled_stream"] += 1
            continue

        # (V4) — is the prefix even run?
        if pfx not in used:
            stats["checked"] += 1
            findings.append(Finding(
                VACUOUS, "V4-PREFIX-NEVER-RUN", path, i, line,
                f"prefix `{pfx}` is passed to no FileCheck on any RUN line of "
                f"this fixture, so this directive is never evaluated"))
            continue

        if kind != "NOT":
            positives_seen.add(pfx)
            continue                      # only NEGATIVES are this file's job
        stats["checked"] += 1
        pat = pat.strip()

        # (V1) — header collision, scoped the way FileCheck scopes a -NOT.
        if pat and pat in header and pfx not in merged:
            if pfx in positives_seen:
                stats["v1_scoped_out"] += 1
                findings.append(Finding(
                    NOTE, "V1-HEADER-BUT-SCOPED", path, i, line,
                    f"`{pat}` also occurs in the module's "
                    f"ModuleID/source_filename line, but a positive `{pfx}` "
                    f"directive precedes this one, so FileCheck's search "
                    f"region starts below the header and the collision is "
                    f"latent rather than live (bd qta2). It becomes live the "
                    f"day that positive directive is deleted or reordered."))
            else:
                findings.append(Finding(
                    VACUOUS, "V1-MATCHES-HEADER", path, i, line,
                    f"`{pat}` matches the lowered module's own "
                    f"ModuleID/source_filename line and NO positive `{pfx}` "
                    f"directive precedes it, so FileCheck's search region "
                    f"includes the header: this negative is about the file's "
                    f"PATH, not about the lowering (bd qta2)"))
            continue

        # (V2) — handle definedness.
        names = SSA_RE.findall(pat)
        missing = [n for n in names
                   if n not in defined and n not in module_in
                   and n not in stream]
        if names and missing and not declines:
            # DEFERRED to phase 2 — see `resolve_deferred`. A name absent from
            # this fixture's input AND output may still be one the compiler
            # mints elsewhere, and calling it vacuous without asking is a
            # FABRICATED FINDING (measured: `%cq.bank`, which
            # RailBankPromote.cpp mints by that exact name).
            deferred.append(("V2-HANDLE-UNDEFINED", path, i, line, missing[0],
                             f"{missing[0]} appears in NEITHER the lowered "
                             f"module, nor this fixture's own input, nor any "
                             f"lowered module of the {{N}}-module universe, so "
                             f"this negative names nothing that could ever be "
                             f"there to match"))
            continue

        # (V2), continued: a name the MERGED stream carries is accounted for.
        if pfx in merged and names and all(n in stream for n in names):
            pass
        # (V5) — a decline writes 0 bytes of IR to stdout.
        if declines and IRISH_RE.search(pat):
            stats["decline_ir_negatives"] += 1
            findings.append(Finding(
                VACUOUS if strict_decline else NOTE, "V5-DECLINE-NO-STDOUT",
                path, i, line,
                "the module DECLINES, so stdout carries 0 bytes of IR and this "
                "IR-shaped negative is pinned by the `not` on the RUN line "
                "rather than by the check (Rule-12 hygiene defect (b))"))
            continue

        # (V3) — reachability against the universe, also deferred.
        if names or not pat:
            continue
        if is_frontend_pattern(pat):
            stats["frontend_exempt"] += 1
            continue
        probe = pat.split("{{")[0].strip()
        if len(probe) < 4:
            stats["v3_too_short"] += 1
            continue
        if probe in module_in or probe in stream:
            continue                      # an ELIMINATION negative, as in (V2)
        deferred.append(("V3-UNREACHABLE-SYMBOL", path, i, line, probe,
                         f"`{probe}` appears in no lowered module of the "
                         f"{{N}}-module universe, so nothing this compiler "
                         f"emits could ever match it"))
    return findings


# Below this many modules a universe cannot answer "the compiler never emits
# this" — it can only answer "these few modules do not". A one-module universe
# said `@cqrt_ry_i32` was unreachable while the compiler emits it constantly.
MIN_UNIVERSE = 2


def resolve_deferred(deferred, universe, n_modules, stats,
                     strict_unreachable=False):
    """Phase 2: decide the (V2)/(V3) candidates against the whole universe."""
    out = []
    for code, path, i, line, token, msg in deferred:
        if token in universe:
            stats["resolved_by_universe"] += 1
            continue
        if code == "V3-UNREACHABLE-SYMBOL" and not strict_unreachable:
            stats["v3_notes"] += 1
            continue
        if n_modules < MIN_UNIVERSE:
            stats["undecidable_small_universe"] += 1
            out.append(Finding(
                NOTE, code + "-UNDECIDABLE", path, i, line,
                f"`{token}` is absent here, but the universe is only "
                f"{n_modules} module(s) — too small to say the compiler never "
                f"emits it. Re-run over a BATCH (that is what this file is "
                f"for) rather than one fixture."))
            continue
        out.append(Finding(VACUOUS, code, path, i, line,
                           msg.replace("{N}", str(n_modules))))
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("fixtures", nargs="*")
    ap.add_argument("--cq-opt", default=None)
    ap.add_argument("--pass-plugin", default=None)
    ap.add_argument("--universe", nargs="*", default=None,
                    help="fixtures whose lowered output forms the (V3) "
                         "universe; globs allowed")
    ap.add_argument("--strict-decline", action="store_true")
    ap.add_argument("--strict-unreachable", action="store_true",
                    help="promote (V3) from a NOTE to a verdict — see (V3): "
                         "it cannot tell a vacuous negative from a working one")
    ap.add_argument("-v", "--verbose", action="store_true")
    args = ap.parse_args(argv)

    if not args.fixtures:
        # An injection matrix once printed `0 mutations, MISSED 0, N/A 0` when
        # invoked with no fixture argument. Nothing is the same as nothing.
        print("negative_vacuity_check: no fixtures given — nothing was "
              "checked, which is a HOLE, not a pass", file=sys.stderr)
        return 2

    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(here)
    cq_opt = args.cq_opt or os.environ.get("CQ_OPT") or \
        os.path.join(root, "build", "ir-pass", "cq-opt")
    plugin = args.pass_plugin or os.environ.get("CQ_PASS") or \
        os.path.join(root, "build", "ir-pass", "libCQPass.so")
    for p, what in ((cq_opt, "cq-opt"), (plugin, "pass plugin")):
        if not os.path.exists(p):
            print(f"negative_vacuity_check: {what} not found at {p} — a gate "
                  f"result is a fact about a BINARY, and there is no binary "
                  f"here. Pass --cq-opt/--pass-plugin or build the tree.",
                  file=sys.stderr)
            return 2

    fixtures = []
    for f in args.fixtures:
        fixtures.extend(sorted(_glob.glob(f)) if any(c in f for c in "*?[")
                        else [f])
    fixtures = [f for f in fixtures if os.path.exists(f)]
    if not fixtures:
        print("negative_vacuity_check: the fixture list expanded to nothing",
              file=sys.stderr)
        return 2

    stats = {"checked": 0, "declining": 0, "unparsed": 0, "empty_modules": 0,
             "frontend_exempt": 0, "v3_too_short": 0, "universe_modules": 0,
             "decline_ir_negatives": 0, "v1_scoped_out": 0,
             "not_modelled": 0, "resolved_by_universe": 0,
             "undecidable_small_universe": 0, "unmodelled_stream": 0,
             "v3_notes": 0}

    # THE UNIVERSE. By default it is THE BATCH ITSELF — every accepting
    # fixture's lowered output, collected in the same single pass that checks
    # them, so (V2)/(V3) are decidable with no extra spawns and no extra flag.
    # `--universe` ADDS to it (a wider corpus than the batch under test).
    extra_parts, extra_n = [], 0
    if args.universe is not None:
        uni = []
        for f in args.universe:
            uni.extend(sorted(_glob.glob(f)) if any(c in f for c in "*?[")
                       else [f])
        for f in uni:
            uout, _uerr, urc = lower(cq_opt, plugin, f)
            if urc == 0 and uout:
                extra_parts.append(uout)
                extra_n += 1
        if not extra_parts:
            print("negative_vacuity_check: --universe was given but every "
                  "member declined or is empty, so it would silently widen "
                  "nothing", file=sys.stderr)
            return 2

    findings, deferred, batch_outputs = [], [], []
    for f in fixtures:
        findings.extend(check_fixture(f, cq_opt, plugin, args.strict_decline,
                                      stats, deferred, batch_outputs))
    universe = "\n".join(batch_outputs + extra_parts)
    stats["universe_modules"] = len(batch_outputs) + extra_n
    findings.extend(resolve_deferred(deferred, universe,
                                     stats["universe_modules"], stats,
                                     args.strict_unreachable))

    for x in findings:
        print(str(x), file=sys.stderr if x.kind == VACUOUS else sys.stdout)

    bad = [x for x in findings if x.kind == VACUOUS]
    print(f"negative_vacuity_check: {len(fixtures)} fixture(s), "
          f"{stats['checked']} directive(s) evaluated, "
          f"{len(bad)} VACUOUS, {stats['decline_ir_negatives']} decline-stdout "
          f"note(s), {stats['v1_scoped_out']} latent header collision(s), "
          f"{stats['declining']} declining module(s), "
          f"{stats['unparsed']} unparsed, {stats['not_modelled']} not-modelled "
          f"(compiler input is not %s), {stats['frontend_exempt']} "
          f"front-end-intrinsic exemption(s), "
          f"{stats['v3_notes']} unreachable-symbol note(s), "
          f"{stats['unmodelled_stream']} on an unmodelled stream, "
          f"{stats['resolved_by_universe']} resolved by the universe, "
          f"{stats['undecidable_small_universe']} undecidable (universe too "
          f"small), universe {stats['universe_modules']} module(s)"
          + f"  [cq-opt {sha256(cq_opt)[:16]}]")

    if stats["checked"] == 0:
        # THE bd jdec DEFECT, made loud. `checked 0` is indistinguishable at a
        # glance from `checked N, 0 vacuous`, and that is how a batch of 29
        # real negatives was scored as verified when it had not been read.
        print("negative_vacuity_check: ZERO directives were evaluated over a "
              "non-empty batch — the matcher selected nothing, which is a "
              "HOLE, not a pass (bd test_C_libtooling-jdec)", file=sys.stderr)
        return 2
    if stats["unparsed"] + stats["not_modelled"] == len(fixtures):
        print("negative_vacuity_check: every fixture was unparsable or feeds "
              "the compiler something other than %s — nothing was checked",
              file=sys.stderr)
        return 2
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
