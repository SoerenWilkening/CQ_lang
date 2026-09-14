#!/usr/bin/env python3
"""Track A injection (mutation) matrix over the bd `xdu2` W1 rail-bank fixtures.

Rule 12 hygiene defect (c): a fixture that cannot be made to fail pins nothing, and
the validation is by MUTATION with the MISSED count RECORDED — never by re-reading
the prefixes. These fixtures are all DECLINES, so the prior sessions' recipe
(mutate the LOWERED OUTPUT) does not apply: a `DS_Error` decline writes ZERO bytes
to stdout. The mutation target is therefore the fixture's own INPUT MODULE, and the
question is the accept-direction one:

    remove the clause violation -> the fixture MUST go RED.

A mutation is CAUGHT iff the fixture's own RUN line(s) fail on the mutant. A
mutation whose pattern is ABSENT is reported `n/a-HOLE` and counted as a HOLE, NOT
as a pass (PROTOCOL S3: "a mutation harness that reports n/a is a HOLE, not a
pass"); `n/a-shape` is reserved for a mutation deliberately declared inapplicable.

⚠ This harness runs the fixture's OWN RUN lines, flags and all — `--implicit-check-not`
included. A harness that runs a WEAKER command than lit measures itself, not the
fixtures (`CLAUDE.md` L10, the 45-MISSED instrument finding).

⚠ It also self-checks: invoked with no fixture argument it EXITS NON-ZERO rather
than printing `0 mutations, MISSED 0` (the second of the six 2026-09-14 instrument
findings).
"""
import os, re, subprocess, sys, tempfile

ROOT = "/Users/sorenwilkening/Desktop/CQ_xdu2A"
LLVM = "/usr/local/opt/llvm@19/bin"
BUILD = ROOT + "/build"
T = "ir-pass/test/"

def run_lines(fix):
    out, cont = [], ""
    for l in open(fix):
        m = re.match(r'^;\s*RUN:\s?(.*)$', l.rstrip('\n'))
        if not m:
            continue
        t = m.group(1)
        if t.endswith('\\'):
            cont += t[:-1]
            continue
        out.append(cont + t)
        cont = ""
    return out

def passes(path):
    """True iff EVERY RUN line of the fixture at `path` succeeds."""
    env = dict(os.environ, PATH=LLVM + os.pathsep + os.environ["PATH"])
    for t in run_lines(path):
        cmd = (t.replace('%cq-opt', BUILD + '/ir-pass/cq-opt')
                .replace('%cq-pass', BUILD + '/ir-pass/libCQPass.so')
                .replace('%filecheck', LLVM + '/FileCheck')
                .replace('%s', path))
        if subprocess.run(['bash', '-c', cmd], capture_output=True, env=env).returncode != 0:
            return False
    return True

def split(t):
    """(header, body). ⚠ MEASURED HARNESS BUG, kept as a comment because it is the
    exact L10 failure mode: the first spelling of this file applied every mutation
    to the WHOLE fixture, and `lowering_reject_railbank_nonzero_init.ll`'s own
    PROSE quotes the IR line the mutation targets — so the mutation edited the
    COMMENT, the module was unchanged, and the harness reported MISSED against a
    fixture that catches it. A harness that mutates the wrong bytes measures
    itself, not the fixtures."""
    ls = t.splitlines(True)
    i = 0
    while i < len(ls) and (ls[i].startswith(';') or not ls[i].strip()):
        i += 1
    return ''.join(ls[:i]), ''.join(ls[i:])


def mutate_check_line(t, a, b):
    """Rewrite `a`->`b` ONLY inside a `; CHECK...:` directive line. ⚠ The second
    spelling of this helper edited the header wholesale and hit the fixture's PROSE
    (which quotes the very number the CHECK reads), so the anchor's numbers read
    MISSED / n/a-HOLE against fixtures that do read them. Same L10 lesson as
    `split` above: aim the mutation at the bytes whose property is under test."""
    out, hit = [], False
    for l in t.splitlines(True):
        if re.match(r'^;\s*CHECK(-[A-Z]+)?:', l) and a in l and not hit:
            l = l.replace(a, b, 1); hit = True
        out.append(l)
    return (''.join(out), hit)

def body_only(fn):
    """Lift a body mutation to a whole-fixture one."""
    def g(t):
        h, b = split(t)
        nb = fn(b)
        return None if nb is None or nb == b else h + nb
    return g

def sub(a, b, n=1):
    def f(t):
        return t.replace(a, b, n) if a in t else None
    return body_only(f)

def drop(pat):
    def f(t):
        new, k = re.subn(pat, '', t, count=1, flags=re.M)
        return new if k else None
    return body_only(f)

# fixture -> [(mutation name, fn)].  Each mutation REMOVES the clause violation, so
# the fixture must go RED.  The clause each one targets is named.
MUTS = {
 "lowering_reject_railbank_vla.ll": [
   ("C1: the VLA becomes a bounded alloca",
    sub("%3 = alloca i8, i64 %2, align 16", "%3 = alloca [3 x i8], align 16")),
 ],
 "lowering_reject_railbank_global.ll": [
   ("C1: the global bank becomes a function-local alloca",
    body_only(lambda t: (t.replace("define i32 @main() local_unnamed_addr #0 {\n  br label %3",
                         "define i32 @main() local_unnamed_addr #0 {\n  %bb = alloca [3 x i8], align 1\n  br label %3", 1)
                .replace("ptr @g", "ptr %bb"))
              if "ptr @g" in t else None)),
 ],
 "lowering_reject_railbank_escape.ll": [
   ("C1: the address no longer escapes to an opaque callee",
    drop(r'^\s*call void @sink\(ptr noundef nonnull %1\) #4\n')),
 ],
 "lowering_reject_railbank_nonzero_init.ll": [
   ("C1: the non-zero memset fill becomes zero", sub("%1, i8 1, i64 3", "%1, i8 0, i64 3")),
 ],
 "lowering_reject_railbank_noninjective.ll": [
   ("C2': the i>>1 index becomes the affine {0,+,1} IV, over a bank of matching size",
    body_only(lambda t: (t.replace("[2 x i8]", "[4 x i8]")
                .replace("store i16 0, ptr %1, align 2", "store i32 0, ptr %1, align 2")
                .replace("%20 = lshr i32 %16, 1", "%20 = add nsw i32 %16, 0")
                .replace("%28 = lshr i32 %16, 1", "%28 = add nsw i32 %16, 0"))
              if "lshr i32 %16, 1" in t else None)),
 ],
 "lowering_reject_railbank_fp_cell.ll": [
   ("C3: the f64 cell becomes an i64 cell (a width WITH a reversible copy)",
    body_only(lambda t: (t.replace("[3 x double]", "[3 x i64]")
                .replace("load double, ptr", "load i64, ptr")
                .replace("store double %6", "store i64 %6")
                .replace("call double @cq_theta_f64(double noundef %5,", "call i64 @cq_theta_sll(i64 noundef %5,")
                .replace("declare double @cq_theta_f64(double noundef, double noundef)", "declare i64 @cq_theta_sll(i64 noundef, double noundef)")
                .replace("call double @cq_measure_f64(double noundef %14)", "call i64 @cq_measure_sll(i64 noundef %14)")
                .replace("declare double @cq_measure_f64(double noundef)", "declare i64 @cq_measure_sll(i64 noundef)")
                .replace("%16 = fptosi double %15 to i32", "%16 = trunc i64 %15 to i32"))
              if "[3 x double]" in t else None)),
   # ⚠ The first spelling of this mutation injected an `llvm.lifetime.start` and
   # read MISSED — because a lifetime marker is ADMITTED by the alloca-wide scan,
   # i.e. the mutation was not an escape at all. A mutation that does not perturb
   # the property is a HARNESS bug, never a fixture finding.
   ("C3 (weaker, isolating the ORDER): a REAL escape is injected, so C1 fires FIRST",
    sub("  br label %2\n", "  %esc = ptrtoint ptr %1 to i64\n  br label %2\n")),
 ],
 "lowering_reject_railbank_oversized.ll": [
   ("C6: the store loop's trip count becomes N", sub("%21 = icmp eq i64 %20, 3", "%21 = icmp eq i64 %20, 8")),
 ],
 "lowering_reject_railbank_two_stores.ll": [
   ("C4: the second store site is removed",
    drop(r'^\s*store i8 %19, ptr %15, align 1, !tbaa !6\n')),
 ],
 "lowering_reject_railbank_inloop_read.ll": [
   ("C6: the in-loop read of cell 0 becomes a read of THIS trip's own cell",
    sub("  %15 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11",
        "  %15g = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5\n"
        "  %15 = load i8, ptr %15g, align 1, !tbaa !6, !range !10, !noundef !11")),
 ],
 "lowering_reject_railbank_mixed_access.ll": [
   ("C1: the byte view is moved off the bank",
    sub("%4 = getelementptr inbounds i8, ptr %1, i64 1", "%4 = getelementptr inbounds i8, ptr %2, i64 0")),
 ],
 "lowering_reject_railbank_alias.ll": [
   ("C4: the cell address stops fanning out",
    body_only(lambda t: (t.replace("  %addr = ptrtoint ptr %g to i64\n", "")
                .replace("  store i64 %addr, ptr %out, align 8\n", ""))
              if "%addr = ptrtoint" in t else None)),
 ],
 "lowering_reject_railbank_nowidth_cell.ll": [
   ("C3: the i96 cell becomes an i32 cell (a width abiWidthFromType knows)",
    body_only(lambda t: (t.replace("[3 x i96]", "[3 x i32]")
                .replace("%w = zext i32 %q to i96", "%w = add i32 %q, 0")
                .replace("store i96 %w", "store i32 %w"))
              if "[3 x i96]" in t else None)),
 ],
 "lowering_reject_railbank_tainted_index_keeps_qram.ll": [
   ("C2: the index becomes classical (the shape leaves 7.5's axis entirely)",
    sub("%3 = and i32 %2, 3", "%3 = and i32 3, 3")),
 ],
 "lowering_reject_railbank_tainted_index_in_loop_keeps_qram.ll": [
   ("C2: the tainted index becomes the loop IV (the shape becomes a rail bank)",
    body_only(lambda t: re.sub(r'= add nsw i32 %\d+, %\d+\n', '= add nsw i32 0, 0\n', t, count=1) if 'add nsw i32' in t else None)),
 ],

 "lowering_reject_railbank_nested_walk.ll": [
   ("C2': the OUTER loop's back edge is removed, so the walk is not re-executed",
    sub("br i1 %6, label %2, label %17, !llvm.loop !6",
        "br i1 %6, label %17, label %17, !llvm.loop !6")),
 ],
 "lowering_reject_railbank_dynamic_object.ll": [
   ("C1: the bank object is hoisted to the entry block (what clang -O1 itself does)",
    body_only(lambda t: (t.replace("entry:\n  br label %outer",
                         "entry:\n  %b = alloca [3 x i8], align 1\n  br label %outer")
                .replace("  ; \u26a0 NOT in the entry block: a fresh bank object per outer trip.\n  %b = alloca [3 x i8], align 1\n", ""))
              if "%b = alloca" in t else None)),
 ],
 "lowering_reject_railbank_wrapping_index.ll": [
   # ⚠ This mutation is ALSO the documented R-2 residual control (see the fixture
   # header): with the flags present SCEV believes them and the module classifies
   # `Bank`, even though 300 trips force the i8 recurrence to wrap — i.e. the input's
   # own `nuw` promise is one it breaks. Used here as a MUTATION because it isolates
   # `hasNoSelfWrap()` from its neighbours; deliberately NOT shipped as a fixture.
   ("C2': the recurrence is flagged no-wrap, so SCEV believes it",
    sub("%inc = add i8 %i, 1", "%inc = add nuw nsw i8 %i, 1")),
 ],
 # ── the `Bank` ANCHORS. A mutation must make the anchor DISAPPEAR.
 "lowering_railbank_bank_anchor_n3.ll": [
   ("the bank's zero initializer becomes non-zero (C1 fires, anchor gone)",
    sub("%1, i8 0, i64 3", "%1, i8 1, i64 3")),
   ("the store loop's trip count stops matching N (C6 fires, anchor gone)",
    sub("%21 = icmp eq i64 %20, 3", "%21 = icmp eq i64 %20, 2")),
 ],
 "lowering_railbank_bank_anchor_uninit.ll": [
   ("a second store site is injected (C4 fires, anchor gone)",
    sub("  store i8 %13, ptr %9, align 1, !tbaa !6",
        "  store i8 %13, ptr %9, align 1, !tbaa !6\n  store i8 %13, ptr %9, align 1, !tbaa !6")),
   ("the store loop's trip count stops matching N (C6 fires, anchor gone)",
    sub("%21 = icmp eq i64 %20, 3", "%21 = icmp eq i64 %20, 2")),
 ],
 "lowering_railbank_bank_anchor_promoted.ll": [
   ("the bank's zero initializer becomes non-zero (C1 fires, anchor gone)",
    sub("%1, i8 0, i64 3", "%1, i8 1, i64 3")),
   ("the store loop's trip count stops matching N (C6 fires, anchor gone)",
    sub("%17 = icmp eq i64 %16, 3", "%17 = icmp eq i64 %16, 2")),
 ],
 "lowering_railbank_bank_anchor_intcells.ll": [
   ("the bank's zero initializer becomes non-zero (C1 fires, anchor gone)",
    sub("%1, i8 0, i64 12", "%1, i8 1, i64 12")),
   ("the store loop's trip count stops matching N (C6 fires, anchor gone)",
    sub("%19 = icmp eq i64 %18, 3", "%19 = icmp eq i64 %18, 2")),
 ],
}

# EXPECTATION mutations: the anchors' `cells=/abi=/trips=` numbers must be
# load-bearing. Mutating the EXPECTATION (not the input) must also go RED.
EXPECT = {
 "lowering_railbank_bank_anchor_n3.ll":       [("anchor cells= is read", "cells=3", "cells=9"),
                                               ("anchor abi= is read",   "abi=i8",  "abi=i64"),
                                               ("anchor trips= is read", "trips=3", "trips=9")],
 "lowering_railbank_bank_anchor_uninit.ll":   [("anchor cells= is read", "cells=3", "cells=9")],
 "lowering_railbank_bank_anchor_promoted.ll": [("anchor cells= is read", "cells=3", "cells=9")],
 "lowering_railbank_bank_anchor_intcells.ll": [("anchor abi= is read",   "abi=i32", "abi=i8")],
}

def main(argv):
    fixtures = argv or sorted(set(list(MUTS) + list(EXPECT)))
    if not argv:
        # the harness self-check: a no-argument invocation is a MISCONFIGURATION,
        # not a clean run. Exit non-zero AFTER doing the work, so the number is
        # still printed but can never be quoted as a pass.
        pass
    tot = caught = missed = hole = 0
    for fx in fixtures:
        p = os.path.join(ROOT, T, fx)
        if not os.path.exists(p):
            print("  MISSING FIXTURE %s" % fx); hole += 1; continue
        base = open(p).read()
        if not passes(p):
            print("  ⚠ BASELINE RED: %s (the un-mutated fixture already fails)" % fx); hole += 1; continue
        for name, fn in MUTS.get(fx, []):
            tot += 1
            new = fn(base)
            if new is None or new == base:
                print("  n/a-HOLE  %-52s %s" % (fx, name)); hole += 1; continue
            with tempfile.NamedTemporaryFile('w', suffix='.ll', delete=False) as f:
                f.write(new); mp = f.name
            ok = passes(mp)
            os.unlink(mp)
            if ok:
                print("  MISSED    %-52s %s" % (fx, name)); missed += 1
            else:
                print("  caught    %-52s %s" % (fx, name)); caught += 1
        for name, a, b in EXPECT.get(fx, []):
            tot += 1
            mutated, hit = mutate_check_line(base, a, b)
            if not hit:
                print("  n/a-HOLE  %-52s %s" % (fx, name)); hole += 1; continue
            with tempfile.NamedTemporaryFile('w', suffix='.ll', delete=False) as f:
                f.write(mutated); mp = f.name
            ok = passes(mp)
            os.unlink(mp)
            if ok:
                print("  MISSED    %-52s %s [expectation]" % (fx, name)); missed += 1
            else:
                print("  caught    %-52s %s [expectation]" % (fx, name)); caught += 1
    print("\n%d mutations over %d fixtures: %d caught, MISSED %d, n/a-HOLE %d"
          % (tot, len(fixtures), caught, missed, hole))
    if not argv:
        print("(invoked with no fixture argument — the default fixture set; "
              "exiting non-zero so this run can never be cited as a pass)")
        return 2
    return 1 if (missed or hole) else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
