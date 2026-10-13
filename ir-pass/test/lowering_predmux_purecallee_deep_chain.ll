; lowering_predmux_purecallee_deep_chain.ll — bd ziuw. A CRASH PRE-EMPTED THE
; LOUD DECLINE, and this is the fixture that says it no longer does.
;
; `isSpeculatablePureCalleeBodyImpl` <-> `...BodyWalk` was an unbounded mutual
; C++ recursion, one machine frame per call-graph node. On a pure call chain of
; ~37.4k nodes it exhausted the 8MB main-thread stack: **rc=132 (SIGILL), ZERO
; stderr, no diagnostic**, on BOTH `cq-opt` and stock `opt`. Bisected to between
; D=37300 (rc=0) and D=37400 (rc=132), stable across repeats; the lldb backtrace
; was 37k identical `...BodyImpl` frames — the compiler inlines `Walk` into
; `Impl`, so it is one frame per node, MEASURED at 224 bytes by `otool -tvV`
; (37350 x 224 = 7.98MB, a one-frame fit; two frames would have broken at 18.7k).
;
; That is not a decline. `opt` exits non-zero for the wrong reason, prints
; nothing, and the Prime Directive's loud reject never happens — the same
; failure mode bd s6ao's R3 round found in the QROM walk, where the fix was also
; an ITERATIVE REWRITE and not a cap.
;
; *** A DEPTH BUDGET IS STILL FORBIDDEN, BUT NOT FOR THE REASON THIS HEADER FIRST
; GAVE. *** The draft said a cut-off FALSE "is written into the memo and served
; to a SHALLOWER query in the same walk". MEASURED FALSE (the Rule-13 round's
; lens 2, instrumented build, 685 modules / 779 queries): 77 memo hits served
; TRUE, ZERO served FALSE — because one FALSE unwinds every ancestor to the root
; through the same arm and ENDS the query, so no frame survives to read it. The
; reason that survives: a budget-induced FALSE poisons the WHOLE query, making a
; provable callee's verdict an artefact of its graph depth and the pinned counter
; triple depth-dependent. That is an over-DECLINE — safe under the Prime
; Directive, a capability + determinism defect, NOT a silent miscompile — and it
; is still the shape bd xzdx forbids. See PredMuxFlatten.cpp for the full note.
;
; *** SCOPE THE HEADLINE: THIS PINS ONE OF FOUR ONE-FRAME-PER-NODE RECURSIONS.
; *** What this fixture covers is the STRICT/S6 entry — 6.5 mints no clone, so
; nothing else recurses behind it. Three other sites produce the IDENTICAL
; signature (rc=132, zero stderr, no diagnostic), all pre-existing and
; byte-identical on the pinned pre-change binary, none covered here:
;   `SpecializeReject::scanBody` ~4000 nodes, on the LAX S1/S2 path — a chain
;      that short still exits rc=132 with the walk's own SUCCESSFUL
;      `invocations=4001 verdict=1` line as the ONLY stderr, bracketed between
;      D=3500 (rc=0) and D=4000, lldb attributing it beneath the 8MB guard page
;      (bd 3c4i);
;   `ByRefInline::cloneExpr` ~65k, one frame per operand-cone node; and
;   `RegionFlattener::edgePred` ~42k, which is not on the clone path at all — so
;      "lax vs strict consumer" does not even describe it — and whose trigger is
;      a merge phi's INCOMING ORDER alone: swap the two incomings and the
;      byte-identical module survives D=400000 (bd t2fw).
; So "a crash no longer pre-empts the loud decline" is true of S6 and of nothing
; else. Do not read this fixture as covering the rest.
;
; TWO FLAVOURS, and the DECLINE one is the point. Both go through the STRICT
; entry (`isSpeculatableTotalCallee`, S6), which is the widest reachable input
; class since bd 9hea routed 6.5 acceptance through it.
;   ACC  every body speculatable -> verdict=1, the 6.5 arm lowers.
;   DEC  the LEAF reads constant memory (bd wve8 deferred clause 1, which strict
;        mode refuses, and so does the speculation-safe twin's totality walk; it
;        was a conditional branch until batch 053's twin froze such a condition
;        and lowered it, dm7f.29) -> verdict=0, and the FALSE has to travel all
;        60000 levels back to the root. That unwind is exactly what the
;        recursive version could not perform, and the loud
;        "control flow under quantum control" it produces is exactly what the
;        crash used to eat.
;
; ASSERT ON THE COUNTER LINE, NOT THE EXIT CODE. An exit code says the module
; lowered; it never says WHICH gate lowered it (bd memory
; [[correction-audit-gap-2026-08-16]]). `invocations=60001` is what proves the
; walk really visited 60001 nodes rather than declining early somewhere cheap.
;
; THE INPUT IS GENERATED, NOT COMMITTED: 60k functions is 4,838,576 bytes of
; textual IR whose only interesting property is its length. Two `%cq-opt` spawns
; rather than one because the two flavours are genuinely different modules — the
; usual "reuse one lowered file across --check-prefix" rule does not apply.
;
; COSTS — NAME THE HARNESS FOR EACH, because the number that matters is not the
; one you get by running the fixture alone. *** THIS IS THE SLOWEST FIXTURE IN
; THE TREE, BY 9x. *** Measured on a quiet box:
;   ~3.5s   standalone under `lit --filter` (net of ~1.7s lit discovery)
;   17.0s   inside `lit -j12` — i.e. how `ir-pass-lit` actually runs it; the next
;           slowest fixture is 1.88s, and the whole suite is 74.5s wall
;   82-84MB peak RSS vs ~8MB typical; ~9.2MB of `%t` artefacts under build/
; It is NOT a long-pole or flakiness risk, and both halves of that are measured:
; lit schedules slowest-first off `.lit_test_times.txt`, so the 17s starts first
; and is overlapped by the other 11 workers; and the fixture asserts on the
; COUNTER LINE, never a wall time, so it cannot go timing-flaky. Budget a depth
; change off the 17s, not off the 3.5s.
;
; THE TWO cq-opt RUNS, NAMED — the ambiguity here already produced one wrong
; review claim, so do not write them as an unlabelled pair. ACC is the EXPENSIVE
; one: both flavours walk all 60001 nodes, and ACC then LOWERS the module while
; DEC declines and lowers nothing. Quiet box, ACC 1.25s user / 1.36s wall; DEC
; 0.81s / 0.90s. (A Rule-13 lens reported the opposite ordering; two independent
; re-measurements and the structural argument both say ACC > DEC.) Generator
; 0.16-0.23s user / 0.51-0.66s wall.
;
; TWO SIDE-EFFECTS OF A COMMENT-ONLY `.ll`, RECORDED SO NOBODY RE-DISCOVERS THEM
; AS BUGS. This is the ONLY file in the corpus with no `define`/`declare` (its
; module IS empty; the real input arrives via `%t.acc.ll` / `%t.dec.ll` under
; lit's exec root, which nothing else globs). So: (1) it is a VACUOUS row in the
; `cq-opt vs stock opt` equivalence gate — both binaries pass an empty module
; through byte-identically, and that row witnesses nothing about this rewrite;
; the real equivalence evidence for ziuw is the generated-population differential
; recorded in PredMuxFlatten.cpp. (2) That gate samples `--stride 8` over a
; SORTED glob, so inserting any fixture rotates which files the sample covers —
; measured here, 57 of the 134 sampled files change identity. Sample SIZE is
; unaffected; this is not a coverage loss, just not a coverage gain either.
;
; SCOPE OF THE RED HALF, STATED SO IT IS NOT OVER-READ: whether the PRE-FIX
; binary crashes at 60000 depends on frame size and stack limit (8MB here), so a
; future toolchain could in principle survive it — 60000 leaves 1.6x margin over
; the measured threshold, enough to absorb a frame shrink from 224B to 140B.
; Measured: pre-fix rc=132 with ZERO stderr at 60000 on both flavours, and under
; the exact RUN lines below the ACC pipeline dies at FileCheck rc=2
; ("'<stdin>' is empty") and the DEC pipeline at rc=1 (`not` returns 1 on a
; SIGNAL, so a crash cannot masquerade as a successful decline). What the fixture
; pins UNCONDITIONALLY is the positive claim — a chain this deep yields a
; VERDICT.
;
; RUN: %python %S/Inputs/gen_deep_pure_chain.py 60000 accept > %t.acc.ll
; RUN: env CQ_PREDMUX_COUNT=1 %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %t.acc.ll -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=ACC
; RUN: %python %S/Inputs/gen_deep_pure_chain.py 60000 decline > %t.dec.ll
; RUN: env CQ_PREDMUX_COUNT=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %t.dec.ll -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=DEC

; ACC: CQ_PREDMUX_COUNT: pure-callee mode=strict root=f_0 verdict=1 invocations=60001 bodies=60001 hits=0

; DEC: CQ_PREDMUX_COUNT: pure-callee mode=strict root=f_0 verdict=0 invocations=60001 bodies=60001 hits=0
; DEC: error: {{.*}}cq controlled lowering: control flow under quantum control
