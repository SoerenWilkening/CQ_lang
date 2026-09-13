# -*- coding: utf-8 -*-
"""Injection matrix for the Track-L L-0 H-10 pins (bd boi6), run by the landing
agent of 2026-09-13 (MERGE_C_1.md item B.3).

Same spelling as `inject_C.py` (Rule 14: one runner, two mutation sets) — mutate
the LOWERED stream, re-run every FileCheck prefix the fixture declares, report
MISSED (no prefix reddened) / DIRTY (the clean stream already fails a prefix) /
n/a (the mutation does not apply).

The mutation set is the one `trackL/ready/README.md` §"What the landing agent
still owes" item 3 names, i.e. SCOPE_boi6 §5:

  extra_x_on_register    a `cqrt_x` on the USER register (the thing a kickback
                         must never do — bd memory diagonal-only-on-user-registers)
  extra_free             a free of a rail that is not provably |0>
  extra_uncontrolled_ry  a second uncontrolled `cqrt_ry` on the condition register
  extra_cswap            the retired swap route reappearing
  handle_in_angle_slot   the rail handle in the classical angle (immediate) slot
                         — the LiteralIntegrity family
  gate_moved_out_of_body the rz hoisted OUT of the loop body into the preheader:
                         one activation instead of K, the ROLLED claim broken
  drop_ry / extra_alloc  the surrounding rail discipline (RYCNT / ACNT)
"""
import subprocess, re, os, tempfile

SUBJ = "/Users/sorenwilkening/Desktop/CQ_21mg"
FC = "/usr/local/opt/llvm@19/bin/FileCheck"
T = SUBJ + "/ir-pass/test/"

FILES = [
    T + "control_phase_kickback_rail_inloop_carried_theta_first.ll",
    T + "control_phase_kickback_rail_inloop_carried_theta_first_negated.ll",
]


def lower(f):
    p = subprocess.run([SUBJ + "/build/ir-pass/cq-opt", "-load-pass-plugin",
                        SUBJ + "/build/ir-pass/libCQPass.so",
                        "-passes=cq-lowering", "-S", f], capture_output=True)
    return p.returncode, p.stdout.decode()


def prefixes(f):
    s = open(f, encoding='utf-8').read()
    out = [m.group(1) for m in re.finditer(r'--check-prefix=(\w+)', s)]
    if re.search(r'^; RUN: %filecheck %s < ', s, re.M):
        out.insert(0, "CHECK")
    return out


def fc(f, pfx, text):
    with tempfile.NamedTemporaryFile('w', suffix='.ll', delete=False,
                                     encoding='utf-8') as t:
        t.write(text)
        p = t.name
    args = [FC, f, "--input-file", p]
    if pfx != "CHECK":
        args += ["--check-prefix=" + pfx]
    r = subprocess.run(args, capture_output=True)
    os.unlink(p)
    return r.returncode == 0


def _rail(t):
    m = re.search(r'(%[\w.]+) = call i32 @cqrt_alloc_\w+\(', t)
    return m.group(1) if m else None


def _body_insert(t, line):
    """Insert INSIDE the loop body (right after the header label)."""
    # ⚠ the printed label carries a `; preds = …` comment — anchoring on
    # `^header:\n` silently returns None and every body mutant reads as n/a,
    # which is indistinguishable from a mutant that cannot apply (Rule 12(c)).
    m = re.search(r'^header:[^\n]*\n', t, re.M)
    if not m:
        return None
    return t[:m.end()] + line + t[m.end():]


def _entry_insert(t, line):
    m = re.search(r'^entry:[^\n]*\n', t, re.M)
    if not m:
        return None
    return t[:m.end()] + line + t[m.end():]


def m_extra_x_on_register(t):
    h = _rail(t)
    return _body_insert(t, "  call void @cqrt_x(i32 %s)\n" % h) if h else None


def m_extra_free(t):
    h = _rail(t)
    return _body_insert(t, "  call void @cqrt_free(i32 %s)\n" % h) if h else None


def m_extra_uncontrolled_ry(t):
    h = _rail(t)
    return _body_insert(
        t, "  call void @cqrt_ry_i1(i32 %s, double 1.000000e-01)\n" % h) if h else None


def m_extra_cswap(t):
    h = _rail(t)
    return _body_insert(
        t, "  call void @cqrt_cswap(i32 %s, i32 %s, i32 %s)\n" % (h, h, h)) if h else None


def m_handle_in_angle_slot(t):
    """The rail handle where the classical angle literal belongs."""
    h = _rail(t)
    m = re.search(r'(call void @cqrt_rz_i1\(i32 [%\w.]+, double )([^)]+)\)', t)
    if not h or not m:
        return None
    return t[:m.start()] + m.group(1) + h + ")" + t[m.end():]


def m_gate_moved_out_of_body(t):
    """Hoist the branch-phase rz OUT of the loop body into the preheader: the
    gate fires once instead of once per activation."""
    m = re.search(r'^  call void @cqrt_rz_i1\([^\n]*\n', t, re.M)
    if not m:
        return None
    line = m.group(0)
    return _entry_insert(t[:m.start()] + t[m.end():], line)


def m_extra_rz_untagged(t):
    """A SECOND branch phase on the register, untagged: the mutant the MDCNT /
    MDTAG count prefixes exist for (a moved gate keeps the count at 1, so those
    two are only exercised by an EXTRA one)."""
    h = _rail(t)
    return _body_insert(
        t, "  call void @cqrt_rz_i1(i32 %s, double 3.000000e-01)\n" % h) if h else None


def m_drop_ry(t):
    m = re.search(r'^  call void @cqrt_ry_[^\n]*\n', t, re.M)
    return t[:m.start()] + t[m.end():] if m else None


def m_extra_alloc(t):
    return _body_insert(t, "  %inja = call i32 @cqrt_alloc_i1(i1 false)\n")


MUTS = [("extra_x_on_register", m_extra_x_on_register),
        ("extra_free", m_extra_free),
        ("extra_uncontrolled_ry", m_extra_uncontrolled_ry),
        ("extra_cswap", m_extra_cswap),
        ("handle_in_angle_slot", m_handle_in_angle_slot),
        ("gate_moved_out_of_body", m_gate_moved_out_of_body),
        ("extra_rz_untagged", m_extra_rz_untagged),
        ("drop_ry", m_drop_ry),
        ("extra_alloc", m_extra_alloc)]

nmiss = nna = ndirty = total = 0
for f in FILES:
    rc, low = lower(f)
    if rc != 0:
        print("SKIP (declines):", os.path.basename(f))
        continue
    pfx = prefixes(f)
    dirty = [p for p in pfx if not fc(f, p, low)]
    if dirty:
        ndirty += 1
        print("DIRTY %-62s clean stream fails %s" % (os.path.basename(f), dirty))
    for name, fn in MUTS:
        mut = fn(low)
        if mut is None or mut == low:
            nna += 1
            print("n/a    %-62s %s" % (os.path.basename(f), name))
            continue
        total += 1
        caught = [p for p in pfx if not fc(f, p, mut)]
        if not caught:
            nmiss += 1
            print("MISSED %-62s %s" % (os.path.basename(f), name))
        else:
            print("caught %-62s %-24s by %s" % (os.path.basename(f), name, caught))
print("\nfixtures=%d mutations=%d MISSED=%d DIRTY=%d n/a=%d"
      % (len(FILES), total, nmiss, ndirty, nna))
