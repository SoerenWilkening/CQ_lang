#!/usr/bin/env python3
"""fixture_guard_liveness.py — prove the bd 261j(a) NOFREE guards actually EXECUTE.

WHY THIS EXISTS. bd 261j(a) removed a hidden measurement: the whole-DAG uncompute
spine used to emit `cqrt_free` on a rail RECORDED onto a kept output tape, leaving
an entangled rail reset (Rules 5/6/8). That change is INVISIBLE to both shipped
quality gates — `opt -verify` is clean either way, the e2e golden byte-diff cannot
witness "freed at |0>" at any ABI, and `free_pairing_check.py` CERTIFIED the
original defective frees (via A2-reduces-to-identity, T1-unc-reversal, and two
further proof paths found in the Rule-13 round). So the ONLY regression protection
for this defect class is a set of FileCheck negatives in
`ir-pass/test/lowering_io_tape_*.ll`.

And those negatives are easy to write so they never run. A `CHECK-NOT` is bounded
by the NEXT positive directive OF ITS OWN PREFIX, so a block like

    ; NOFREE:     %[[A:...]] = call i32 @cqrt_alloc_i32(i32 %u0)
    ; NOFREE-NOT: call void @cqrt_free(i32 %[[A]])
    ; NOFREE:     %[[B:...]] = call i32 @cqrt_alloc_i32(i32 %u1)     <-- closes A's window
    ; NOFREE-NOT: call void @cqrt_free(i32 %[[B]])

silently reduces A's guard to the span between the two allocs — the forward stream,
where no `cqrt_free` can ever appear. The fixture still PASSES, and it is guarding
nothing. That exact defect shipped TWICE in this family: once in the original
CHECK-NOT placement, and again in the repair that moved them into a shared prefix.
A guard nobody has tried to defeat is a guard nobody should trust — the same
argument `tools/free_pairing_check_test.py` makes for the Rule-6 checker.

WHAT IT DOES. For every `NOFREE*` prefix in every tape fixture:
  1. lower the fixture with the real pass;
  2. resolve the handle the prefix's anchor binds (by matching the anchor's own
     FileCheck pattern against the real output);
  3. INJECT `call void @cqrt_free(i32 <handle>)` as the last instruction before
     `ret` — the hardest position for a stale window to reach, and exactly the
     free the pre-261j compiler emitted;
  4. re-run FileCheck with that prefix and require it to FAIL.
A prefix whose FileCheck still passes has a DEAD window and is reported.

WHAT IT DOES NOT WITNESS. It proves the guards RUN, not that they guard the right
thing: it says nothing about whether a rail SHOULD be frozen (that is the lit
fixtures' positive CHECK lines plus Rule-13 review), and nothing about rails no
fixture mentions. It is a test-of-tests, not a correctness gate.
"""

import os
import re
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LLVM = "/usr/local/opt/llvm@19/bin"
OPT = os.path.join(LLVM, "opt")
FILECHECK = os.path.join(LLVM, "FileCheck")
PLUGIN = os.path.join(REPO, "build", "ir-pass", "libCQPass.so")
TESTDIR = os.path.join(REPO, "ir-pass", "test")

PREFIX_RE = re.compile(r"^;\s*([A-Z0-9]*NOFREE[A-Z0-9]*?)(-NOT)?:\s*(.*)$")


def anchor_to_regex(pat):
    """Turn a FileCheck anchor pattern into a Python regex with one capture for the
    bound variable. Handles `%[[NAME:re]]` (definition) and `{{re}}` (inline)."""
    out, i, var_group = [], 0, None
    while i < len(pat):
        if pat.startswith("%[[", i):
            end = pat.index("]]", i)
            body = pat[i + 3:end]
            name, _, sub = body.partition(":")
            if sub:
                out.append("(%" + sub + ")")
                var_group = name
            else:
                out.append("%[A-Za-z0-9_.]+")
            i = end + 2
        elif pat.startswith("{{", i):
            end = pat.index("}}", i)
            out.append("(?:" + pat[i + 2:end] + ")")
            i = end + 2
        else:
            out.append(re.escape(pat[i]))
            i += 1
    return "".join(out), var_group


def guards_in(path):
    """([(prefix, anchor_pattern)], [unanchored_prefix]) for this fixture.

    A NOFREE* prefix with a `-NOT` but NO positive directive of its own is
    UNANCHORED: its window is the whole input, so it cannot be dead and there is
    nothing to inject against. Those are returned separately and COUNTED rather
    than silently dropped — an undercount in this tool's own success line is the
    same class of defect it exists to catch.
    """
    anchors, has_not = {}, set()
    for line in open(path):
        m = PREFIX_RE.match(line.rstrip("\n"))
        if not m:
            continue
        prefix, is_not, body = m.group(1), m.group(2), m.group(3).strip()
        if is_not:
            has_not.add(prefix)
        elif prefix not in anchors:
            anchors[prefix] = body
    return ([(p, anchors[p]) for p in sorted(anchors) if p in has_not],
            sorted(p for p in has_not if p not in anchors))


def main():
    if not os.path.exists(PLUGIN):
        print("fixture_guard_liveness: plugin not built:", PLUGIN, file=sys.stderr)
        return 2
    # DISCOVERY IS BY PREFIX NAME, NOT BY FILENAME — and the distinction from
    # "by guard" is deliberate, because the honest version of this sentence is the
    # point of the tool. This used to scan only `lowering_io_tape_*`, the family bd
    # 261j(a) created, so a NOFREE* prefix anywhere else fell outside the checker
    # while the suite read green. That was NOT hypothetical and NOT new with bd uow0:
    # `control_swap_abort_park.ll` has carried a NOFREE prefix since 2026-06-23.
    #
    # WHAT IS STILL OUTSIDE, stated so nobody mistakes this for full coverage: a
    # negative spelled in the MAIN prefix (`CHECK-NOT: ... cqrt_free`) is not
    # discovered — that is the majority spelling in this tree. The `NOFREE*`
    # convention is what makes a guard checkable, so a Rule-6 negative that matters
    # should be written with its own NOFREE* prefix and a single anchor.
    # Scanning every fixture costs one file READ each; `opt` runs only for the
    # handful that carry a guard, so the sweep stays ~as fast as the old one.
    fixtures = sorted(f for f in os.listdir(TESTDIR) if f.endswith(".ll"))
    dead, checked, unanchored, skipped = [], 0, 0, []
    with tempfile.TemporaryDirectory() as tmp:
        for fx in fixtures:
            path = os.path.join(TESTDIR, fx)
            guards, loose = guards_in(path)
            for p in loose:
                # No positive directive of its own ⇒ the window is the whole input,
                # so the guard cannot be dead and there is nothing to inject
                # against. Counted, never dropped silently.
                unanchored += 1
                print(f"  n/a   {fx} :: {p} (unanchored — window is the whole input)")
            if not guards:
                continue
            out = os.path.join(tmp, "out.ll")
            r = subprocess.run([OPT, "-load-pass-plugin", PLUGIN,
                                "-passes=cq-lowering", "-S", path, "-o", out],
                               capture_output=True)
            if r.returncode != 0:
                # A guard we CANNOT check is not a guard we may assume good. The old
                # code printed SKIP and still returned 0 — a test-of-tests reporting
                # "0 DEAD" after checking nothing. Fail loudly instead: it fires only
                # when someone adds an anchored NOFREE guard to a declining fixture,
                # and that is exactly the moment to notice.
                print(f"  SKIP  {fx}: pass declined (rc={r.returncode}) — "
                      f"{len(guards)} anchored guard(s) UNCHECKED")
                skipped.append((fx, r.returncode, len(guards)))
                continue
            body = open(out).read()
            for prefix, anchor in guards:
                checked += 1
                rx, var = anchor_to_regex(anchor)
                m = re.search(rx, body)
                if not m or not var:
                    dead.append((fx, prefix, "anchor did not bind a handle"))
                    print(f"  ????  {fx} :: {prefix} — anchor unresolvable")
                    continue
                handle = m.group(1)
                inject = f"  call void @cqrt_free(i32 {handle})\n"
                mut, done = [], False
                for line in body.splitlines(keepends=True):
                    if not done and line.startswith("  ret "):
                        mut.append(inject)
                        done = True
                    mut.append(line)
                mpath = os.path.join(tmp, "mut.ll")
                open(mpath, "w").write("".join(mut))
                fc = subprocess.run([FILECHECK, path, f"--check-prefix={prefix}"],
                                    stdin=open(mpath), capture_output=True)
                if fc.returncode == 0:
                    dead.append((fx, prefix, handle))
                    print(f"  DEAD  {fx} :: {prefix} (guarding {handle})")
                else:
                    print(f"  live  {fx} :: {prefix} (guarding {handle})")
    print(f"\nfixture_guard_liveness: {checked} guard(s) checked, {len(dead)} DEAD, "
          f"{unanchored} unanchored (not checkable, not dead)")
    if dead:
        print("A NOFREE guard that survives an injected cqrt_free is not a guard.")
        print("Give each guarded handle its OWN --check-prefix and RUN line: a")
        print("CHECK-NOT is bounded by the next positive directive of its prefix.")
        return 1
    if skipped:
        print("An anchored NOFREE guard in a fixture the pass DECLINES cannot be")
        print("checked, and an unchecked guard must not report green:")
        for fx, rc, n in skipped:
            print(f"  {fx}: pass rc={rc}, {n} guard(s) unchecked")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
