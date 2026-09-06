# BRIEF_prep_c_audit — Inc 1 prep (c): extend `tools/golden_multiset_audit.py` to the four PRD §10.2 substitutions
Read `$SP/briefs/BRIEF_common.md` first. Agent name: `prep_c`. Model: opus.

## Where you work
Worktree `$SP/wt/prep-c`, branch `3qlq-inc1-audit`. You touch `tools/golden_multiset_audit.py`
and a new self-test `tools/golden_multiset_audit_test.py` (mutant validation — "a checker
nobody has tried to fool is a checker nobody should trust"). Nothing else.

## What the instrument is
Read the 863-line header of `tools/golden_multiset_audit.py` completely. It is the Inc-2a
golden-regeneration witness: given an OLD golden and a NEW golden it proves the diff is
EXACTLY the admitted substitution and nothing else (handle renumbering aside), with a scope
check asked of the OLD trace first, and a reducer that rewrites the old trace into the
expected new one. Keep its architecture; ADD a mode `--epic 3qlq` whose admitted
substitutions are the FOUR of PRD §10.2, each applied per region:
 (a) the flat 2a line `cqrt_rz_<W>_controlled(f, h, θ)` → `cqrt_rz_i1(f, θ)` (same f, same θ;
     h disappears from that line; the `cqrt_x(f)` bracket, mint, strip, free unchanged);
 (b) the routed quintuple `cqrt_alloc_<W>(0) -> w; cqrt_cswap(f, q, w); cqrt_rz_<W>(w, θ);
     cqrt_cswap(f, q, w); cqrt_free(w)` → the ONE line `cqrt_rz_i1(f, θ)` (the nest and the
     switch: N cases → N per-case flags each with its own rz_i1 — read `SwitchRouteEmit.cpp`
     and `NestedRouteEmit.cpp` for the exact old stream; for the NEST the new stream is the
     conjunction flag `cqrt_toffoli(fa, fb, g)`, `rz_i1(g, θ)`, toffoli undo, per-leaf strip
     — define the admitted new shape from PRD §3 "Compound conditions" and say in the header
     that it is DEFINED FROM THE PRD, not measured, until the implementer's trace exists);
 (c) an UNCONTROLLED `cqrt_rz_<W>(h, θ)` line DELETED (no other change);
 (d) the 2b pair `cqrt_rz_<W>(h, B)` + `cqrt_rz_<W>_controlled(f, h, A−B)` → the exact
     two-gate form `cqrt_x(f); cqrt_rz_i1(f, B); cqrt_x(f); cqrt_rz_i1(f, A)` (A and B read
     back from the OLD trace: B from the unconditional line, A = B + the controlled angle —
     in hex-float; the sum is an IEEE check with a tolerance you STATE, and the header must
     say why: the old trace carries fl(A−B), so A is recoverable only to ½ ulp).
Anything else — a moved `_unc`, a changed free order, a handle that stops being freed, an
extra or missing gate, an Ry line that changed — is a FINDING and the exit code is non-zero.
Handle RENUMBERING is the only tolerated drift: the reducer must renumber the old trace
after dropping the work rails and compare structurally (it already does for 2a — reuse).

## Self-test (Rule 12 for instruments; ctest `e2e-free-pairing-selftest` is the model)
`tools/golden_multiset_audit_test.py`: synthesize old/new trace pairs for each of (a)–(d)
that must PASS, and mutants that must FAIL: a dropped strip, a dropped flag free, a wrong θ
on the new rz_i1, an rz_i1 on the wrong flag (f ≠ the mint of that region), a surviving
`_controlled` line, a surviving `cqrt_cswap`, an Ry line changed, (d) with A off by 1 ulp
beyond tolerance, a deleted Rz that was under control (i.e. (c) applied where (a) was
expected). Run it: `python3 tools/golden_multiset_audit_test.py` — report pass/fail counts.
Do NOT register a ctest entry (the orchestrator decides; instruments are pending an owner
cost decision — same status as inplace_twin_matrix.py).

## Dry run on real goldens
Run the extended audit in `--epic 3qlq` mode with OLD = each of the 63 goldens
(`grep -l cqrt_rz tests/e2e/*.expected.log`) and NEW = the REDUCTION the tool itself
produces (i.e. self-consistency: reduce(old) must pass against itself), and list which of
the 63 fall in which substitution class by their OLD signature (a/b/c/d, or MIXED, or
OUT-OF-SCOPE). That table goes in the tool's header and in your hand-back. It is the map the
orchestrator uses when the real regenerated goldens arrive.

## Commit
Two commits: the tool extension; the self-test. Hand back per BRIEF_common.
