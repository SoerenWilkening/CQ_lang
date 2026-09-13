# -*- coding: utf-8 -*-
"""Injection matrix for bd 21mg (Track C) — adapted from
session-l4x4/probes/impl/inject.py (Rule 14: one spelling, not a second).

Mutate the LOWERED stream of each 21mg ACCEPT fixture, re-run every FileCheck
prefix the fixture declares, and report MISSED (no prefix reddened) / DIRTY (the
CLEAN stream already fails a prefix) / n/a (the mutation does not apply).

The mutation set is the one the BRIEF names, expressed as the streams a WRONG
implementation of this change would actually emit:
  extra_measure_i32 / extra_measure_i1  a classical measure that minted a GATE
  extra_alloc_i32 / extra_alloc_f64     a classical measure that minted a RAIL
                                        (the f64/angle miscompile family)
  classical_becomes_quantum             the classical operand replaced by a fresh
                                        rail + a measure of it — the exact stream
                                        a predicate that ignored taint produces
  drop_measure                          a QUANTUM measure swallowed by the
                                        classical path (the other direction)
  drop_alloc / extra_x / extra_free     the surrounding rail discipline
"""
import subprocess, re, glob, os, tempfile

SUBJ = "/Users/sorenwilkening/Desktop/CQ_21mg"
FC = "/usr/local/opt/llvm@19/bin/FileCheck"
T = SUBJ + "/ir-pass/test/"

FILES = [
    T + "lowering_measure_classical_accept.ll",
    T + "lowering_measure_classical_mixed_accept.ll",
    T + "lowering_measure_round2_sixfive_handle.ll",
    T + "control_measure_classical_bool_owner.ll",
]


def lower(f):
    p = subprocess.run([SUBJ + "/build/ir-pass/cq-opt", "-load-pass-plugin",
                        SUBJ + "/build/ir-pass/libCQPass.so",
                        "-passes=cq-lowering", "-S", f], capture_output=True)
    return p.returncode, p.stdout.decode()


def prefixes(f):
    s = open(f, encoding='utf-8').read()
    out = []
    for m in re.finditer(r'--check-prefix=(\w+)', s):
        out.append(m.group(1))
    if re.search(r'^; RUN: %filecheck %s < ', s, re.M):
        out.insert(0, "CHECK")
    # the ACC prefix is checked against stderr+stdout of a SECOND run, not against
    # the mutated text; scanning it here would be meaningless (it is all -NOT).
    return [p for p in out if p != "ACC"]


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


def _first_body_line(t):
    """The first instruction line inside the first `define` — an insertion point
    every lowered module has."""
    m = re.search(r'^define [^\n]*\{\n(?:\w+:\n)?', t, re.M)
    return m.end() if m else None


def _insert(t, line):
    at = _first_body_line(t)
    if at is None:
        return None
    return t[:at] + line + t[at:]


def _first_rail(t):
    m = re.search(r'(%[\w.]+) = call i32 @cqrt_alloc_\w+\(', t)
    return m.group(1) if m else None


def m_extra_measure_i32(t):
    return _insert(t, "  %injm = call i32 @cqrt_measure_i32(i32 0)\n")


def m_extra_measure_i1(t):
    return _insert(t, "  %injm1 = call i1 @cqrt_measure_i1(i32 0)\n")


def m_extra_alloc_i32(t):
    return _insert(t, "  %inja = call i32 @cqrt_alloc_i32(i32 0)\n")


def m_extra_alloc_f64(t):
    return _insert(t, "  %injf = call i32 @cqrt_alloc_f64(double 0.000000e+00)\n")


def m_classical_becomes_quantum(t):
    """The owner fixture's classical measure, lowered the WRONG way: a fresh rail
    for the classical `i1 false` plus a measure of it."""
    m = re.search(r'  (%[\w.]+) = zext i1 false to i32\n', t)
    if not m:
        return None
    rep = ("  %injq = call i32 @cqrt_alloc_i1(i1 false)\n"
           "  %injqm = call i1 @cqrt_measure_i1(i32 %injq)\n"
           "  " + m.group(1) + " = zext i1 %injqm to i32\n")
    return t[:m.start()] + rep + t[m.end():]


def m_drop_measure(t):
    m = re.search(r'  [^\n]*call [^\n]*@cqrt_measure_[^\n]*\n', t)
    if not m:
        return None
    return t[:m.start()] + t[m.end():]


def m_drop_alloc(t):
    m = re.search(r'  [^\n]*= call i32 @cqrt_alloc_[^\n]*\n', t)
    if not m:
        return None
    return t[:m.start()] + t[m.end():]


def m_extra_x(t):
    b = _first_rail(t)
    if not b:
        return None
    return _insert(t, "  call void @cqrt_x(i32 %s)\n" % b)


def m_extra_free(t):
    b = _first_rail(t)
    if not b:
        return None
    return _insert(t, "  call void @cqrt_free(i32 %s)\n" % b)


MUTS = [("extra_measure_i32", m_extra_measure_i32),
        ("extra_measure_i1", m_extra_measure_i1),
        ("extra_alloc_i32", m_extra_alloc_i32),
        ("extra_alloc_f64", m_extra_alloc_f64),
        ("classical_becomes_quantum", m_classical_becomes_quantum),
        ("drop_measure", m_drop_measure),
        ("drop_alloc", m_drop_alloc),
        ("extra_x", m_extra_x),
        ("extra_free", m_extra_free)]

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
        print("DIRTY %-48s clean stream fails %s" % (os.path.basename(f), dirty))
    for name, fn in MUTS:
        mut = fn(low)
        if mut is None or mut == low:
            nna += 1
            print("n/a    %-48s %s" % (os.path.basename(f), name))
            continue
        total += 1
        caught = [p for p in pfx if not fc(f, p, mut)]
        if not caught:
            nmiss += 1
            print("MISSED %-48s %s" % (os.path.basename(f), name))
print("\nfixtures=%d mutations=%d MISSED=%d DIRTY=%d n/a=%d"
      % (len(FILES), total, nmiss, ndirty, nna))
