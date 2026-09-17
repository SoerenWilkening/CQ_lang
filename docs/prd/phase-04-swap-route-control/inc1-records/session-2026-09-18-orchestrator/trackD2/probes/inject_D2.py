#!/usr/bin/env python3
"""Track D2 injection (mutation) matrix over bd `test_C_libtooling-drbq.12`'s ACCEPT
fixtures.

Rule 12 hygiene defect (c): a fixture that cannot be made to fail pins nothing, and
the validation is by MUTATION with the MISSED count RECORDED — never by re-reading
the prefixes. These fixtures are ACCEPTS, so the mutation target is the LOWERED
OUTPUT (the `%t.cqd0.ll` every RUN line FileChecks), and the question is the
miscompile-direction one:

    perturb the emitted stream -> the fixture MUST go RED.

A mutation is CAUGHT iff at least one of the fixture's FileCheck RUN lines fails on
the mutated output.

⚠ THE HARNESS RUNS THE FIXTURE'S OWN RUN LINES, FLAGS AND ALL — every
`--check-prefix` and every `--implicit-check-not`. A harness that runs a WEAKER
command than lit measures itself, not the fixtures (CLAUDE.md L10, the 45-MISSED
instrument finding). The only substitution is the FileCheck INPUT: `< %t.cqd0.ll`
is redirected to the mutant.

⚠ It self-checks: invoked with no fixture argument it EXITS NON-ZERO rather than
printing `0 mutations, MISSED 0` (the second of the six 2026-09-14 instrument
findings). It also refuses a fixture whose baseline does not pass, and refuses a
mutation whose pattern is ABSENT — reported `n/a-HOLE` and counted as a HOLE, never
as a pass (PROTOCOL S3: "a mutation harness that reports n/a is a HOLE").
"""
import os, re, subprocess, sys

WT = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad7349188dd3b67bd"
LLVM = "/usr/local/opt/llvm@19/bin"
BUILD = WT + "/build"


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


def lower(fix, out):
    cmd = [BUILD + "/ir-pass/cq-opt", "-load-pass-plugin",
           BUILD + "/ir-pass/libCQPass.so", "-passes=cq-lowering", "-S", fix,
           "-o", out]
    return subprocess.run(cmd, capture_output=True).returncode


def checks_pass(fix, lowered):
    """True iff EVERY FileCheck RUN line of `fix` succeeds against `lowered`."""
    env = dict(os.environ, PATH=LLVM + os.pathsep + os.environ["PATH"])
    ran = 0
    for t in run_lines(fix):
        if "%filecheck" not in t:
            continue          # the cq-opt line; we supply the lowered file ourselves
        cmd = (t.replace('%filecheck', LLVM + '/FileCheck')
                .replace('%s', fix))
        cmd = re.sub(r'<\s*%t\.cqd0\.ll', '< ' + lowered, cmd)
        ran += 1
        if subprocess.run(['bash', '-c', cmd], capture_output=True,
                          env=env).returncode != 0:
            return False, ran
    assert ran, "fixture has no FileCheck RUN line — nothing to measure"
    return True, ran


def mutants(text):
    """(name, mutated-text or None) — None means the pattern is ABSENT (a HOLE)."""
    L = text.split("\n")

    def first(pat):
        for i, l in enumerate(L):
            if re.search(pat, l):
                return i
        return None

    def drop(pat, name):
        i = first(pat)
        return (name, None) if i is None else (name, "\n".join(L[:i] + L[i + 1:]))

    def dup(pat, name):
        i = first(pat)
        return (name, None) if i is None else (name, "\n".join(L[:i + 1] + [L[i]] + L[i + 1:]))

    def inject_before(pat, line, name):
        i = first(pat)
        return (name, None) if i is None else (name, "\n".join(L[:i] + [line] + L[i:]))

    def retype(pat, old, new, name):
        i = first(pat)
        if i is None:
            return (name, None)
        if old not in L[i]:
            return (name, None)
        return (name, "\n".join(L[:i] + [L[i].replace(old, new, 1)] + L[i + 1:]))

    # The register the region controls on: arg-0 of the first alloc.
    m = re.search(r'(%[\w.]+) = call i32 @cqrt_alloc_', text)
    reg = m.group(1) if m else None

    out = [
        drop(r'call void @cqrt_free\(', "drop-first-free"),
        drop(r'@cq_template_icmp_\w+_unc\(', "drop-first-strip"),
        drop(r'= call i32 @cq_template_icmp_\w+_hl\(', "drop-first-mint"),
        drop(r'call void @cqrt_ry_\w+_controlled\(', "drop-controlled-ry"),
        drop(r'call void @cqrt_rz_i1\(', "drop-kickback-rz"),
        drop(r'call void @cqrt_toffoli\(', "drop-first-toffoli"),
        dup(r'= call i32 @cq_template_icmp_\w+_hl\(', "dup-first-mint"),
        dup(r'call void @cqrt_free\(', "dup-first-free"),
        retype(r'= call i32 @cq_template_icmp_\w+_hl\(', ", i32 5)", ", i32 6)",
               "mint-literal-5-to-6"),
        retype(r'call void @cqrt_ry_\w+_controlled\(', "double 9.000000e-01",
               "double 8.000000e-01", "controlled-angle-perturbed"),
    ]
    if reg:
        out.append(inject_before(r'= call i32 @cq_template_icmp_\w+_hl\(',
                                 "  call void @cqrt_x(i32 %s)" % reg,
                                 "inject-cqrt_x-on-user-register"))
        out.append(inject_before(r'ret ',
                                 "  call void @cqrt_ry_i32(i32 %s, double 1.230000e+00)" % reg,
                                 "inject-stray-ry-before-ret"))
    return out


def main():
    fixtures = sys.argv[1:]
    if not fixtures:
        sys.stderr.write("inject_D2: no fixture argument — refusing to report "
                         "'0 mutations, MISSED 0'\n")
        return 2
    tmp = "/tmp/inject_D2"
    os.makedirs(tmp, exist_ok=True)
    total = caught = missed = holes = 0
    print("fixture\tmutation\tverdict")
    for fix in fixtures:
        base = os.path.join(tmp, os.path.basename(fix) + ".base.ll")
        if lower(fix, base) != 0:
            print("%s\t-\tBASELINE-DECLINES (not an accept fixture)" % fix)
            return 3
        ok, nchecks = checks_pass(fix, base)
        if not ok:
            print("%s\t-\tBASELINE-RED (fixture does not pass unmutated)" % fix)
            return 3
        text = open(base).read()
        for name, mut in mutants(text):
            total += 1
            if mut is None:
                holes += 1
                print("%s\t%s\tn/a-HOLE (pattern absent)" % (os.path.basename(fix), name))
                continue
            mp = os.path.join(tmp, os.path.basename(fix) + "." + name + ".ll")
            open(mp, "w").write(mut)
            ok, _ = checks_pass(fix, mp)
            if ok:
                missed += 1
                print("%s\t%s\tMISSED" % (os.path.basename(fix), name))
            else:
                caught += 1
                print("%s\t%s\tcaught" % (os.path.basename(fix), name))
    print()
    print("inject_D2: %d fixture(s), %d mutation(s), %d caught, MISSED %d, "
          "n/a-HOLE %d" % (len(fixtures), total, caught, missed, holes))
    return 0


if __name__ == "__main__":
    sys.exit(main())
