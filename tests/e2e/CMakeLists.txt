# tests/e2e/CMakeLists.txt — Phase 2 end-to-end vertical slice.
#
# The only test layer that LINKS — it proves every symbol the pass emits
# resolves and is signature-correct against the runtime + template libs.
# Tools come from LLVM_TOOLS_BINARY_DIR (set by the root find_package(LLVM));
# the plugin and libs are resolved via generator expressions so the test
# tracks the just-built artifacts.
set(_E2E_CLANG "${LLVM_TOOLS_BINARY_DIR}/clang")
# Stage 2 runs the same single pipeline the lit layer does, so it uses the same
# purpose-built driver: cq-opt links only the LLVM components the pass needs and
# costs 0.124s of fixed per-spawn cost against stock opt's 0.238s. It accepts
# and ignores `-load-pass-plugin`, so the runners' command line is unchanged.
# Equivalence to stock opt is gated by the cq-opt-equivalence ctest entry over
# all 1069 lit fixtures (stdout + stderr + exit code). Falls back to stock opt
# if the target is somehow unavailable.
if(TARGET cq-opt)
  set(_E2E_OPT "$<TARGET_FILE:cq-opt>")
else()
  set(_E2E_OPT "${LLVM_TOOLS_BINARY_DIR}/opt")
endif()
# Phase 6 (DD-6 §7.2): llvm-link for the multi-file harness run_slice_multi.sh,
# mirroring _E2E_CLANG/_E2E_OPT (C19). Resolves to the same LLVM-19 toolchain
# (/usr/local/opt/llvm@19/bin/llvm-link). NOTE: new add_test entries require a
# cmake re-configure — e2e does not auto-discover (unlike the lit .ll fixtures).
set(_E2E_LLVM_LINK "${LLVM_TOOLS_BINARY_DIR}/llvm-link")

# bd test_C_libtooling-8txa: stage 2b of run_slice.sh is the Rule-6 free-pairing
# check over the lowered IR (tools/free_pairing_check.py). It is Python, so
# resolve the interpreter once here rather than trusting whatever `python3` a
# test shell happens to see; the project already requires python3 for
# tools/gen_templates.py, so a missing interpreter is a hard configure error.
find_program(_E2E_PYTHON NAMES python3 python REQUIRED)

# ...and then resolve THROUGH it to the real interpreter. `python3` on PATH is
# very often a version-manager SHIM (pyenv/asdf/rbenv-style): a bash script that
# re-execs `pyenv exec`, which on this machine costs ~0.25s of pure shell
# version-resolution BEFORE CPython even starts — MEASURED 0.39s via the shim vs
# 0.145s via the interpreter it selects, 8 interleaved reps, on a real lowered
# .ll. Stage 2b runs once per e2e entry, so that is ~60s of CPU spent on shell
# bookkeeping across the layer. `sys.executable` is exactly the interpreter the
# shim would have chosen, so this changes WHICH BINARY IS SPAWNED and nothing
# else — same interpreter, same version, same site config. Guarded: if the probe
# fails or names a path that is not there, keep whatever find_program resolved.
execute_process(
  COMMAND "${_E2E_PYTHON}" -c "import sys; sys.stdout.write(sys.executable)"
  OUTPUT_VARIABLE _E2E_PYTHON_REAL
  ERROR_QUIET)
if(_E2E_PYTHON_REAL AND EXISTS "${_E2E_PYTHON_REAL}")
  message(STATUS "cq e2e: python ${_E2E_PYTHON} -> ${_E2E_PYTHON_REAL}")
  set(_E2E_PYTHON "${_E2E_PYTHON_REAL}")
endif()

# bd dgn5 — stage-3 link. `clang s2.ll tpl.a rt.a -o slice` spawns THREE
# processes (driver, -cc1, ld), two of which dyld-bind libclang-cpp.dylib
# (77MB) + libLLVM.dylib (140MB), and the driver hands ld `-lto_library`
# unconditionally so ld ALSO dlopens libLTO -> libLLVM. Nothing here uses LTO
# (stage 3 is deliberately -O0, bd szpr). Splitting into `clang -c` + a direct
# ld call MEASURED 0.74-0.94s -> 0.35-0.44s per slice.
#
# The link line is DERIVED from the driver itself (`clang -###`) and re-derived
# on every reconfigure, so SDK / platform-version / clang-runtime drift is
# picked up automatically; see tools/derive_link_line.py for exactly what is
# stripped and why. A stale line fails LOUDLY at link, never silently.
#
# DEGRADES GRACEFULLY BY DESIGN: if derivation fails (a non-Darwin driver, an
# unrecognised job list), CQ_LD stays empty and both runners fall back to the
# original single clang command, which is exactly equivalent and merely slower.
# That is why this is a WARNING and not a FATAL_ERROR — a perf optimisation
# must never be able to break the build.
# Stage-1 frontend cache. Stage 1 does NOT depend on the cq-lowering plugin --
# only on this clang, its flags, CQ.h and the slice source -- so it is a byte-
# identical recompute on every run while the plugin (the thing you actually
# iterate on) changes underneath it. MEASURED 0.428s CPU per slice, ~104s across
# the layer. tools/s1_cache_key.py hashes the EXPENSIVE half (clang's own bytes,
# its --version, every header under include/, the flag string) exactly once,
# here; run_slice.sh adds only the source bytes per slice. Read that file's
# header before touching this: a stale hit would not make a test slow, it would
# make it LIE, so every key component is content and never a timestamp.
# Cache lives under the build dir => `rm -rf build` is a full reset.
# NOTE: run_slice_multi.sh is deliberately NOT cached -- it compiles several TUs
# per test and there are only 20 such entries (~9s CPU), so the added key
# surface is not worth it.
set(_E2E_S1_CACHE "${CMAKE_CURRENT_BINARY_DIR}/.s1cache")
execute_process(
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/s1_cache_key.py"
          "${_E2E_CLANG}" "${CMAKE_SOURCE_DIR}/include"
          -- "-I${CMAKE_SOURCE_DIR}/include" -include CQ.h -O1 -emit-llvm -S
  RESULT_VARIABLE _E2E_S1_RV
  OUTPUT_VARIABLE _E2E_S1_BASE
  ERROR_VARIABLE _E2E_S1_ERR)
if(_E2E_S1_RV EQUAL 0 AND _E2E_S1_BASE)
  message(STATUS "cq e2e: stage-1 cache key ${_E2E_S1_BASE}")
else()
  message(WARNING "cq e2e: stage-1 cache key failed (${_E2E_S1_ERR}); "
                  "caching disabled, tests stay correct and merely slower.")
  set(_E2E_S1_BASE "")
  set(_E2E_S1_CACHE "")
endif()

set(_E2E_LINK_WRAPPER "${CMAKE_CURRENT_BINARY_DIR}/cq_link.sh")
execute_process(
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/derive_link_line.py"
          "${_E2E_CLANG}" "${_E2E_LINK_WRAPPER}"
  RESULT_VARIABLE _E2E_LINK_RV
  OUTPUT_QUIET
  ERROR_VARIABLE _E2E_LINK_ERR)
if(_E2E_LINK_RV EQUAL 0 AND EXISTS "${_E2E_LINK_WRAPPER}")
  message(STATUS "cq e2e: stage-3 link via derived ${_E2E_LINK_WRAPPER}")
else()
  message(WARNING "cq e2e: could not derive the stage-3 link line "
                  "(${_E2E_LINK_ERR}); falling back to the clang driver. "
                  "Tests stay correct, the e2e layer is just slower.")
  set(_E2E_LINK_WRAPPER "")
endif()

# Phase 2 canonical slice: theta -> add_hl -> measure.
add_test(NAME e2e-slice-theta-add-measure
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.expected.log")

# Phase 3 (WP6): Q+Q and Q+C arithmetic across the HH/HL/LH operand shapes,
# pinning the post-O1 opcode stream (mul HH, add_hl, sub_lh, shl_lh).
add_test(NAME e2e-slice-qq-hl-arith
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qq_hl_arith.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qq_hl_arith.expected.log")

# Phase 3 (WP6): data-position icmp/fcmp measured through the zext flag-handle
# bridge (compare -> zext_i1_to_i32 -> cqrt_measure_i32).
add_test(NAME e2e-slice-compare-measure
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_measure.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_measure.expected.log")

# Phase 7.1 (8rvn, iw81.4 §4.4): the UNORDERED fcmp predicates lower, link, and
# trace end-to-end. Negated relational compares (`!(x>=k)`->ult, etc.) and
# `__builtin_isunordered`->uno, which Clang -O1 folds straight to the unordered
# twins, now resolve against the regenerated `cq_template_fcmp_<pred>_f32_hl`
# surface (this is the only layer that LINKS).
add_test(NAME e2e-slice-fcmp-unordered
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fcmp_unordered.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fcmp_unordered.expected.log")

# Phase 4.1 (WI-4): RSSA swap-routed PHASE-arm diamond. The only layer that
# LINKS — it proves every symbol the swap-route emitter mints (the icmp flag
# template + its `_hl_inv` strip, cqrt_cswap, the |0> rail alloc/free, the
# verbatim arm rz) resolves and signature-matches against the runtime. Tainted
# `if (q>5) { rz(q,a); rz(q,b); }` lowers to the pinned routed stream (§5a):
# flag mint -> rail alloc -> cswap in -> verbatim rz -> cswap back -> rail free
# -> icmp_inv flag-strip -> flag free; ZERO controlled gates, exactly two frees.
add_test(NAME e2e-slice-control-phase-diamond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_diamond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_diamond.expected.log")

# Issue a8c0: the idiomatic conditional phase `if (q != 0) q = cq_phi(q, a)` whose
# else edge `clang -O1` const-folds to `0` (the merge is `phi [phase(q), 0]`).
# Pre-a8c0 the classifier over-declined it (the `Base == Routed` gate saw the
# folded `0`, not the qubit). The straight-through const-fold re-anchor proves
# `q == 0` on that edge and re-anchors the routed handle to `q`, so it lowers as a
# clean phase arm (¬flag cqrt_x brackets — the arm fires on the `q != 0` FALSE
# edge — the Rz on the rail, strip with icmp_eq_inv, merge RAUW'd to q). LINK-proves
# the a8c0 stream resolves against the runtime; the golden is the trace contract.
add_test(NAME e2e-slice-control-phase-ifne
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifne.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifne.expected.log")

# Phase 4.1 follow-on (test_C_libtooling-9hh): two-arm PHASE if/else routing a
# DERIVED base (a pre-region cq_phi result). Links the dual-rail §5b stream —
# both rails, the cqrt_x ¬flag bracket, and the pre-region cqrt_rz that must
# precede the flag mint — against the runtime. The arms are asymmetric (2 vs 1
# gates) deliberately: symmetric one-gate arms canonicalize at -O1 into the
# 4.4-deferred tainted ANGLE SELECT, which declines (Rule 9).
add_test(NAME e2e-slice-control-phase-ifelse-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifelse_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_ifelse_derived.expected.log")

# Phase 4.2 (WI-6, test_C_libtooling-paj.6): the VALUE-arm diamond. The only
# layer that LINKS. The 6-op linear chain `if (q>5) { p=p+3; p=p*5; p=p^9;
# p=p+1; p=p*7; p=p^2; }` SURVIVES -O1 as a clean br-diamond (a short arm folds
# to a tainted SELECT at -O1 — SimplifyCFG speculation); clang reassociates the
# constants, so the golden pins the POST-reassociation stream.
#
# ⚠ REGENERATED AT bd test_C_libtooling-3qlq Inc 2 (2026-09-05): 28 -> 23 lines.
# The swap route is RETIRED for value arms. The old stream was `flag mint -> |0>
# rail -> cswap in -> chain verbatim on the rail -> cswap back -> alloc out ->
# cqrt_copy_i32(p,out) -> cswap -> reversed chain _unc -> cswap -> rail free ->
# icmp_inv strip -> flag free` (4 cswap = 4W Toffoli + 8W CNOT, one W-bit work
# rail, TWO frees). The new stream hoists the chain onto the ORIGINAL p and
# merges with the 4.4 controlled-XOR copy pair: `chain on p (M-C converts the
# in-place links on the FRESH intermediate rails) -> flag mint -> alloc out ->
# copy_controlled(f, armvalue, out) -> x -> copy_controlled(f, p, out) -> x ->
# icmp_inv strip -> ONE free`. The whole diff was audited line by line and is
# exactly that substitution (progress record: impl_inc2.md AUDIT 1).
#
# THE WITNESS IS slice_control_value_diamond_twin.c — the PRE-HOISTED SELECT
# spelling of the same program, whose golden must be byte-identical
# (`e2e-value-diamond-twin-identical`). NOTE it is NOT the `?:` spelling: `-O1`
# compiles `p = (q>5) ? R(p) : p` to the SAME diamond at this arm size (measured
# 2026-09-05), so the `?:` "twin" would be this program.
add_test(NAME e2e-slice-control-value-diamond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond.expected.log")

# bd test_C_libtooling-3qlq Inc 2 — THE VALUE-ARM TWIN GROUP (3 subject/twin
# pairs + 3 `cmp` gates below). Each twin is the PRE-HOISTED SELECT spelling
# (`int t = R(p); p = (q>5) ? t : p;`) of its subject diamond: `clang -O1` hands
# that to the pass as a straight-line chain plus a `select`, which is EXACTLY the
# shape Inc 2 rewrites the diamond into, and which lowers through the
# Rule-13-cleared 4.4 `SelectMergeEmit`. Byte identity of the two goldens is the
# increment's witness (the drbq Inc-2b by-difference-twin precedent).
add_test(NAME e2e-slice-control-value-diamond-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond_twin.expected.log")

# The if/else value arm (V2): both chains hoisted, `out ^= f.R1(p)` then, X-
# bracketed, `out ^= !f.R2(p)`. 54 -> 33 trace lines vs the pre-3qlq route.
add_test(NAME e2e-slice-control-value-ifelse
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_ifelse.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_ifelse.expected.log")

add_test(NAME e2e-slice-control-value-ifelse-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_ifelse_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_ifelse_twin.expected.log")

# The mixed-stem chain (`sub`/`and`/`or`/`shl`/`xor`/`mul`) — the pair that would
# catch a hoist that changed operand order (`sub` is non-commutative) or the M-C
# in-place disposition relative to the manual straight-line spelling.
add_test(NAME e2e-slice-control-value-mixedops
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_mixedops.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_mixedops.expected.log")

add_test(NAME e2e-slice-control-value-mixedops-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_mixedops_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_mixedops_twin.expected.log")

# THE NEGATED-POLARITY PAIR (bd test_C_libtooling-3qlq Inc 2, Rule-13 round-1
# review finding F-V1-7). `if (q != 5)` — `clang -O1` canonicalises it to
# `icmp eq` with the successors SWAPPED, so the region arrives with `ArmNegated`
# and `emitValueRegion` must put the arm value in the select's FALSE slot. The
# fixture `control_swap_value_diamond_polarity.ll` pins the emitted SYMBOLS, but
# symbols cannot see an operand swap — the multiset
# {copy_controlled, x, copy_controlled, x} and the strip/free pairing stage 2b
# checks are identical either way. Byte identity against the PRE-HOISTED SELECT
# spelling, which reaches the same emitter with no polarity decision to make, is
# the only measurement in the tree that does see it.
add_test(NAME e2e-slice-control-value-polarity
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_polarity.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_polarity.expected.log")

add_test(NAME e2e-slice-control-value-polarity-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_polarity_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_polarity_twin.expected.log")

# THE ACCEPT-CLASS WIDENING THAT RIDES ON INC 2 (round-1 review finding F-V1-1;
# owner disposition OQ-22 KEEP+PIN). `int e = (p == r);` — a Q+Q DATA compare
# read off a value-arm merge — DECLINED on the pre-3qlq oracle 52d7764 with
# `no template for opcode 'icmp i1' in tainted context`, because the retired
# `emitValueRegion` recorded no `taint.HandleWidth` for the merged register and
# `CompareLowering::rewriteCompare`'s Q+Q path needs a RECORDED logical width.
# Routing the diamond through `emitSelectRegion` inherits that entry (bd
# p119.6). e2e is the only layer that LINKS, so this is what proves
# `cq_template_icmp_eq_i32` and its `_unc` twin resolve and signature-match when
# reached from a value-arm merge. The width axis is pinned at the IR level by
# control_swap_value_accept_{i8_merge_cast,i64_merge_cast,qq_compare_*}.ll. NO
# twin gate: the claim here is that the symbols LINK, not a byte identity.
add_test(NAME e2e-slice-control-value-merge-qq-compare
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_merge_qq_compare.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_merge_qq_compare.expected.log")

# The DERIVED-base value diamond (a pre-region `cq_phi` on the value register;
# the 9hh discipline). NO twin gate: the pre-hoisted select twin of this program
# DECLINES `control flow` on BOTH the pre-3qlq oracle and this binary, because
# `SelectClassify` conservatively refuses a coherent Rz-lineage select OPERAND
# while the `br`-value classifier deliberately ACCEPTS a derived base. Inc 2
# reuses the select EMITTER, not the select CLASSIFIER, so the two dispositions
# stay different by design; a `compare_files` gate here would assert something
# false. See the slice header.
add_test(NAME e2e-slice-control-value-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_derived.expected.log")

# THE THREE VALUE-ARM TWIN GATES. `cmp` over committed goldens — no clang, no
# opt, no plugin, milliseconds. Same construction as the 8h7d.5 rolled-loop and
# drbq Inc-2b angle-select twin gates.
add_test(NAME e2e-value-diamond-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_diamond_twin.expected.log")

add_test(NAME e2e-value-ifelse-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_ifelse.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_ifelse_twin.expected.log")

add_test(NAME e2e-value-mixedops-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_mixedops.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_mixedops_twin.expected.log")

# The FOURTH gate (round-1 review F-V1-7): negated polarity. Added by the
# round-1 FIX agent, not by the increment.
add_test(NAME e2e-value-polarity-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_polarity.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_value_polarity_twin.expected.log")

# 3c6m.14 L6 / bd 20xt.5 (d): PredMux tolerates `unreachable` switch-defaults.
# The only layer that LINKS — proves the (d)-flattened nest (a tainted special-
# case branch over an EXHAUSTIVE `switch (q&3)` whose dead default clang lowers
# to a shared `unreachable` block, the minimized atan2l quadrant shape) lowers to
# the 4.4 select-merge substrate and its whole symbol set resolves + signature-
# matches against the runtime (Rule 2/16; (d) adds NO new runtime ABI). LLVM's
# PostDominatorTree treats `unreachable` as a 2nd exit, so the standard merge
# lookup bails (virtual-root ipdom) and the nest would decline `nested control
# flow`; (d) recomputes the merge ignoring the unreachable exit so it flattens.
# The `unreachable` arm contributes NO predicate and NO merge incoming; case 3 is
# the sound chain fallback. Deterministic straight-line trace (every gate fires
# unconditionally); flags/out-rails follow the standard 4.4 bookkeeping.
add_test(NAME e2e-slice-predmux-unreachable-switch
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_unreachable_switch.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_unreachable_switch.expected.log")

# bd 20xt.5.1 blocker (e): PredMux post-flatten residual-select fold. A tainted
# nest whose classical fp80-const special-case guard (x==1.0, x=0.5L) collapses
# to `false` under cq-lowering's fp80-union promotion, leaving a partial-constant
# `and i1 false,%hi` residue that ConstantFold cannot finish. Without the residue
# fold the residual select declines "control flow under quantum control"; with it
# the dead special-case collapses to EXACTLY the residue-free lowering (verified
# byte-identical). Deterministic straight-line trace, 1 ry + 1 measure (Rule 5).
add_test(NAME e2e-slice-predmux-selectchain-foldresidue
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_selectchain_foldresidue.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_selectchain_foldresidue.expected.log")

# bd vyqi (W5): the sole-phi fp diamond — the volatile-single-accumulator
# "***CAUTION***" idiom (log10l `z`, distilled) end-to-end. volatile stores
# defeat clang if-conversion, so the diamond reaches the pass as a real branch;
# promoteVolatileScalarLocals mints the sole 2-incoming fp merge phi, the W5
# claim witness flattens it, and the kjd1 controlled-copy merge lowers it (no
# new runtime ABI — this re-proves the kjd1 fp copy symbols resolve for the
# PredMux-flattened diamond).
add_test(NAME e2e-slice-predmux-fp-diamond-volatile
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_fp_diamond_volatile.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_predmux_fp_diamond_volatile.expected.log")

# Phase 4.3 (WI-4, test_C_libtooling-s8yf.5): RSSA swap-routed depth-2
# homogeneous-PHASE NEST. The only layer that LINKS — and so the only proof the
# nested emitter's symbol set resolves and signature-matches across BOTH routing
# levels against the runtime (Rule 2, Rule 16; 4.3 adds no new runtime ABI, so
# this re-proves 4.1's symbols compose at depth 2). The §0 accept shape
# `if (q>5) { q=rz(q,.25); if (q<9) { q=rz(q,.75); } }` SURVIVES -O1 as the
# measured one-content-arm-diamond-inside-one-content-arm-diamond reconverging at
# a single 3-incoming merge phi, and lowers to the §5g routed stream: outer mint
# -> rail1 alloc -> outer route-in -> intervening rz on rail1 -> inner mint FROM
# RAIL1 -> rail2 alloc -> inner route-in -> inner rz -> inner route-back -> free
# rail2 -> STRIP f2 (BEFORE the outer route-back, the load-bearing §12.3 order)
# -> free f2 -> outer route-back -> free rail1 -> STRIP f1 -> free f1 -> measure
# q. EXACTLY FOUR frees (rail2, f2, rail1, f1); ZERO controlled gates, no
# cqrt_toffoli, no surviving `phi i32`, no added measure.
add_test(NAME e2e-slice-control-nested-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_nested_phase.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_nested_phase.expected.log")

# ziov WI-1 (test_C_libtooling-ziov.1): the SHARED-CONDITION-FLAG path. A tainted
# control compare `q>5` reused as DATA (`int f = (q>5)`) lowers to ONE shared flag
# — the route AND the data `zext`/`add` read the same icmp handle, the flag is
# NEITHER stripped (no icmp_inv) NOR freed (its data lineage owns it). The only
# layer that LINKS, so it proves the shared flag's data consumers resolve against
# the runtime. EXACTLY ONE free (the rail); contrast slice_control_phase_diamond
# (no data use → strip + flag free, two frees).
add_test(NAME e2e-slice-control-cond-datause
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_datause.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_datause.expected.log")

# Phase 4.4 (WI-4, test_C_libtooling-polz.4): RSSA tainted-`select` controlled-XOR
# copy merge. The only layer that LINKS — and 4.4 adds a NEW runtime symbol, so
# this golden is the ONLY proof cqrt_copy_<W>_controlled (WI-2) resolves +
# signature-matches against libcq_runtime (Rule 2/16). The canonical §15 shape
# `sel = (q>5) ? q : x` SPECULATES at -O1 into a single `select` (no diamond, no
# phi) and lowers to the §5a merge stream: flag mint -> |0> out rail alloc ->
# cqrt_copy_i32_controlled the TRUE operand (q) on the flag -> X-bracket +
# cqrt_copy_i32_controlled the FALSE operand (x, materialized via cqrt_alloc) on
# ¬flag -> icmp_inv strip -> the ONE cqrt_free (the flag). q / out / the
# materialized scratch are LEFT ALLOCATED (freeing an operand entangled with out
# is a hidden measurement, Rule 6/8); ZERO cqrt_cswap, ZERO controlled rotations,
# no surviving `phi i32`, EXACTLY ONE free (contrast the method-B value diamond's
# two). control_swap_select_qc.ll is the pinned IR contract; IMPLEMENTATION-4.4 §5a.
add_test(NAME e2e-slice-control-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select.expected.log")

# fp-DATA select un-staging (fp-data-select-PRD §8, issue kjd1): the branchless
# fp ternary `(q > 0.5) ? q+1.0 : 0.25` -> `select` over an fcmp-ogt condition,
# the FIRST fcmp-minted merge (cq_template_fcmp_ogt_f64_hl / _inv, not icmp).
# The only layer that LINKS the new frozen-designate cqrt_copy_f64_controlled.
# The golden ALSO asserts the §6 uncompute shape: the copied theta-derived fadd
# chain is deliberately LEAKED (its _controlled user marks the DAG NotClosed) —
# NO `_unc` line, EXACTLY ONE cqrt_free (the flag); out / q / t / the
# materialized 0.25 scratch stay allocated (Rules 6/8).
add_test(NAME e2e-slice-control-select-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_fp.expected.log")

# bd big5 (2026-07-31): the ALIASED-RAIL condition compare -- `%q` and
# `%r = cq_phi(%q,.25)` are SSA-DISTINCT (InstCombine cannot fold them, unlike
# `x==x`) yet lower to ONE rail, because cq_phi (Rz) is an IN-PLACE gate whose
# result RAUWs to its argument's handle. bd 7q3s fenced this for one day on the
# premise that `cq_template_icmp_slt_i32(h0, h0)` is "an ill-formed physical gate
# no backend can realize"; the owner refuted that premise and the fence was
# reverted. Aliased INPUTS of an OUT-OF-PLACE gate with a FRESH |0> output rail
# (CASE A) make it a UNARY function of the shared operand -- realizable, usually
# free, and a Phase-9 backend obligation rather than a compiler defect. What is
# genuinely unrealizable is CASE B, an input aliasing a rail the gate WRITES;
# the golden emits none, and every `_unc` line's written rail is distinct from
# its reads.
# The only layer that LINKS, so the only proof the aliased mint and its void
# out-first `_unc` twin resolve and signature-match the ABI. Stage 2b
# (free_pairing_check.py) verifies all FOUR flag frees at a proven |0>.
# Five lineages in one TU: (A) integer select, (B) f64 select through the kjd1
# fp copy family, (C) the ARITHMETIC Case A `p*p` -- the consistency witness,
# since 118 of 226 committed goldens already ship an aliased-operand template
# call AND WERE GREEN WITH THE FENCE IN (the condition walk never inspects
# arithmetic), so the defect was an inconsistency of principle, not a
# contradiction; (D) the CONSTANT-TRUE `icmp eq(a,a)`, the demanding half of
# Rule 6 -- its flag rail is |1> at the mint, so the `_unc` strip must actually
# return it to |0> before `cqrt_free`, whereas (A)/(B) are FALSE-valued and leave
# it at |0> trivially; and (E) the ENTANGLED-flag f64 case -- `fcmp oge(a,a)` is
# NOT constant TRUE, it is ord(a) == !isnan(a) (no ORDERED fcmp is constant on
# aliased operands), which is a STRICTLY HARDER Rule-6 witness than a constant.
# Two extension traps, both measured: `q <= r` does not survive -O1 as itself
# (canonicalized to `icmp sgt`, arms swapped, Rule 9), and surviving as the same
# PREDICATE is not the same as being constant on aliased operands.
add_test(NAME e2e-slice-select-rail-alias-cond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_select_rail_alias_cond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_select_rail_alias_cond.expected.log")

# bd 9ymx (owner decision 2026-07-03): the tainted fp ternary INSIDE a classical
# bounded loop -- the -O1-natural shape (LICM-hoisted compare in the guard
# block, select in the body). Pins the per-iteration contract: 3 iterations,
# each minting a fresh flag from the unchanged q, fresh |0> out rail + fresh
# materialized (double)i scratch, strip, and EXACTLY ONE free (the flag); q is
# never freed. The gate-2c cross-block relaxation is what admits this shape.
add_test(NAME e2e-slice-control-select-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_loop.expected.log")

# bd hcrg — TWO SEQUENTIAL tainted-condition regions in one function (region 2's
# Pred IS region 1's MergeBB after clang -O1). These lower only because
# `lowerControlRegions` ORDERS the emission: region 2's emitter runs FIRST, while
# all of its blocks are still live. The claim that the emitted GATE STREAM is
# nevertheless in SOURCE order rests on each emitter inserting positionally into
# its own pred block, and these two goldens are the byte-level proof of it — the
# lit fixtures pin the IR, but a plan-order regression would still verify clean
# and still pair every free. Two slices, deliberately: `seq_regions` is the
# minimal adjacent pair on an untouched wire; `seq_grover` is the customer shape,
# with an in-place cqrt_addc sub AND an in-place Ry between the regions (M-C
# 2b lowered the reversible sub in place), i.e. the case
# where a stale flag would surface as a wrong unitary.
add_test(NAME e2e-slice-control-seq-regions
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_seq_regions.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_seq_regions.expected.log")

add_test(NAME e2e-slice-control-seq-grover
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_seq_grover.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_seq_grover.expected.log")

# bd test_C_libtooling-drbq Inc 1 — the CONTROL-IN-PLACE ROTATION arm. The LINK
# layer for the new frozen-designate `cqrt_ry_<W>_controlled` family: these are the
# only tests that prove the symbol the in-place rotation-arm emitter mints resolves
# and signature-matches against libcq_runtime (Rule 2).
#
# A tainted-control Ry has NO swap-route form (`Ry|0> != |0>` leaves the inactive
# work rail dirty and entangled with the flag, Rules 6/8), so this is the MECHANISM
# and not a peephole. The whole stream per arm is `icmp_hl -> ry_controlled ->
# icmp_hl_unc -> free`: no alloc, no cswap, no work rail, no reverse-play, and
# EXACTLY ONE free (the flag) against the phase diamond's two.
#
# STRICT stage 2b (no --allow-unproven): the flag is minted, stripped and freed in
# one straight-line stream and the checker proves that pairing outright. The two
# rotated registers are measured, so Rule 6 leaves them allocated as always.
#
# TWO slices, and the pair is the property: `_negated` is the Rule-9 polarity —
# `!=` canonicalizes to `icmp eq` with SWAPPED successors, so the gate fires on the
# NEGATED flag inside a self-inverse `cqrt_x` bracket. Its golden is what witnesses
# the bracket is a PAIR; a stray single X would leave the flag inverted when the
# strip recomputes `q == 5`, and the free would then reset a rail holding |1>.
add_test(NAME e2e-slice-control-inplace-ry
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-negated
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_negated.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_negated.expected.log")

# THE DERIVED-BASE FREEZE, at the LINK layer (round-1 Rule-13 review of drbq Inc
# 1, lenses L3 §1 / L5 §1). The rotated base is an out-of-place `mul` rail and
# there is a post-region user, so the whole-DAG spine has something to reverse —
# and before the fix it reversed the FROZEN register after `cqrt_free(flag)`, a
# use-after-free followed by a dirty free (stage 2b reported F2 + T3). No slice
# in the tree had a derived base under a rotation arm, which is why the defect
# shipped through a green suite. STRICT stage 2b, deliberately: the checker is
# the gate that sees rail identities the trace cannot.
add_test(NAME e2e-slice-control-inplace-ry-derived-base
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_derived_base.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_derived_base.expected.log")

# ── bd test_C_libtooling-drbq Increment 2b — ANGLE-SELECT BY DIFFERENCE ──────
#
# The plain C `if/else` with a rotation on ONE register in each arm. `clang -O1`
# never hands that to the pass as a diamond: SimplifyCFG merges the two arms into
# ONE call whose ANGLE is a tainted-condition `select`, so the branch CFG is gone
# before the pass runs (Rule 9). Lowered by angle additivity on one axis — an
# unconditional `R(h, B)`, the ordinary flag mint, ONE
# `cqrt_{ry,rz}_<W>_controlled(f, h, A-B)`, the ordinary strip, one free. Exact in
# REAL arithmetic; in IEEE double the realized true-arm angle is `B + fl(A-B)`,
# `|delta| <= 1/2 ulp(A-B)` — 2^-54 rad on these goldens' 0.9/0.3 pair. BOTH ARMS
# MUST BE CONSTANTS, fenced at a placeholder 2^-40 rad; a RUN-TIME arm DECLINES
# `rotation angle under quantum control`, because the synthesized `fsub` carries
# an error UNBOUNDED in absolute radians AND can be `inf`/`NaN` from two FINITE
# arms (measured `inf` in the controlled gate from +/-8.99e307). ALL SEVEN SLICES
# BELOW HAVE CONSTANT ARMS and were unaffected by that narrowing (their goldens
# are byte-unchanged). NOTE THAT THE TWIN GATES BELOW COULD NOT HAVE WITNESSED
# EITHER RESIDUAL: the manual twin is ITSELF by-difference, so both sides would
# carry the identical rounding and the identical infinity (round-1 Rule-13 review
# lens L7-F1/F5; the both-halves wording is the round-2 one's, lens R1 item 1;
# the constant-arms-only narrowing is the CLEARANCE review's, finding F-11 /
# owner option (2)).
#
# THREE SUBJECT/TWIN PAIRS AND THREE `compare_files` GATES, and the gates are the
# increment's CENTRAL WITNESS rather than a convenience. Each `_twin` slice writes
# the SAME circuit by hand in by-difference form (`r = R(r,B); if (c) r = R(r,A-B);`)
# — an ordinary in-place DIAMOND that the PRE-2b binary already lowered, verified
# byte-identical across both binaries. So the twin is an ORACLE, not a second copy
# of the thing under test: if the select form ever drifts into a different (and
# still self-consistent) gate stream, this is what turns red. The folded constant
# is part of it — `clang`'s compile-time `0.9 - 0.3` and the emitter's APFloat
# subtract agree bit for bit, so a last-ULP difference would show as a different
# `%a` hex float. All STRICT stage 2b (no `--allow-unproven`).
add_test(NAME e2e-slice-control-angle-select-ry
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry.expected.log")

add_test(NAME e2e-slice-control-angle-select-ry-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_twin.expected.log")

add_test(NAME e2e-slice-control-angle-select-ry-ne
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_ne.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_ne.expected.log")

add_test(NAME e2e-slice-control-angle-select-ry-ne-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_ne_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_ne_twin.expected.log")

add_test(NAME e2e-slice-control-angle-select-rz
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_rz.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_rz.expected.log")

add_test(NAME e2e-slice-control-angle-select-rz-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_rz_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_rz_twin.expected.log")

# THE DERIVED-BASE FREEZE, in the angle-select form (the Inc-1 finding-L shape
# with the diamond replaced by a select). The rotated base is an out-of-place
# `mul` rail with a post-gate user, so the whole-DAG spine has something to
# reverse — and must not: a register a `cqrt_ry_<W>_controlled` fired on is
# FROZEN (its adjoint would name the flag this stream already freed, and the free
# would reset a condition-entangled rail). 2b adds NO code for that — the freeze
# is asked structurally of the emitted gate — so this slice PROBES the claim
# rather than arguing it. Exactly one `cqrt_free` (the flag). STRICT stage 2b.
# Two M-A `live derived record` WARNINGS are expected (a `DS_Warning`, opt exits
# 0) and the manual by-difference twin emits the identical stream and warnings.
add_test(NAME e2e-slice-control-angle-select-ry-derived-base
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_derived_base.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_derived_base.expected.log")

# THE THREE TWIN GATES. `cmp` over committed goldens — no clang, no opt, no
# plugin, milliseconds. Same construction as the 8h7d.5 rolled-loop twin gates.
add_test(NAME e2e-angle-select-ry-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_twin.expected.log")

add_test(NAME e2e-angle-select-ry-ne-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_ne.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_angle_select_ry_ne_twin.expected.log")

# REMOVED 2026-09-05 (3qlq Inc 1, prep-b2): `e2e-angle-select-rz-twin-identical`.
# It asserted `compare_files` between the Rz angle select and its BY-DIFFERENCE
# manual twin, and under owner decision D2 that assertion is FALSE — not because
# either side is wrong, but because the twin's leading gate is an UNCONTROLLED
# `cq_phi(0.3)`, i.e. a GLOBAL PHASE, which the pass DELETES. MEASURED:
#     subject  cqrt_x(f); rz_i1(f, 0x1.3333333333333p-2);            <- P(0.3) on !f
#              cqrt_x(f); rz_i1(f, 0x1.ccccccccccccdp-1)             <- P(0.9) on  f
#     twin                 rz_i1(f, 0x1.3333333333334p-1)            <- P(fl(0.9-0.3)) on f
# The two are the SAME STATE up to the global factor e^{i0.3} that D2 removes, so
# a byte gate would be asserting that a deleted global phase is observable. Both
# slices KEEP their own registration and their own golden; the RELATION between
# the two goldens is stated in both headers and is checkable by hand (the twin's
# single angle is `fl(A - B)` of the subject's two). The drbq Inc-4 state-prep
# group set the precedent for exactly this: "the two goldens differ by a
# reduction and a `compare_files` gate would assert something FALSE".
# NOTE also (prep-d, OQ-15): NO byte-identity twin exists for this stem at all —
# the obvious candidate `if (q==5) cq_phi(A); if (q!=5) cq_phi(B);` is BYTE-
# IDENTICAL at `-O1` to the if/else itself, so it is the same module and witnesses
# nothing. The audit's substitution (d) is P2's witness for the Rz stem.

# bd test_C_libtooling-lom0 Increment 4 — TWO COMPLETE GROVER ITERATIONS: four
# chained `cq_theta`s and four sequential tainted-condition phase regions, i.e.
# the shape that declined at HEAD b4e329b with "condition predates a
# non-diagonal gate" and nothing else. `seq_grover` above stops at the `+= off`
# half of state preparation; this one has the Ry half too, twice, which is what
# makes it a repeatable iteration rather than a prefix. STRICT stage 2b (no
# `--allow-unproven`): the trace records that every region's flag is stripped and
# freed before the next non-diagonal gate, and the free-pairing checker records
# that the only rail left allocated is the measured register.
add_test(NAME e2e-slice-control-grover-2iter
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_2iter.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_2iter.expected.log")

# bd test_C_libtooling-160a (M-B Increment 6) — bd 6uqc's P0 end to end, WITH the
# S-dagger that used to make it decline. A DERIVED region condition
# (`sqrt(a+3.0) <= 5.0`) mints three template rails the flag strip never touches;
# until clause (d2) they were never uncomputed, and the following non-diagonal
# gate declined with "non-diagonal gate over a live derived record". STRICT
# stage 2b: the trace records the strip firing BEFORE the chain's LIFO discharge
# (it still reads the live sqrt rail) and both before the second cqrt_ry_i32.
add_test(NAME e2e-slice-uncompute-interior-region-derived-cond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_interior_region_derived_cond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_interior_region_derived_cond.expected.log")

# bd test_C_libtooling-160a — ONE COMPLETE GROVER ITERATION WHOSE ORACLE IS A
# COMPUTATION, not a compare against a constant: `((q*5)>>2) == 5`, two template
# rails deep (`ashr` then a QQ `add`) before the flag is minted. The direct-oracle
# twin is slice_control_grover_2iter above; this is the shape that says CQ can
# mark a COMPUTED predicate — and the predicate is SATISFIABLE (it marks q == 4;
# the `((q*37)>>3)==5` it shipped with for one day marks nothing without `nsw`
# overflow — bd 160a Rule-13 finding F2). STRICT stage 2b.
add_test(NAME e2e-slice-control-grover-derived-oracle
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_derived_oracle.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_derived_oracle.expected.log")

# bd test_C_libtooling-160a — the SAME iteration twice. Two derived-condition
# chains with no producer edge between them, i.e. two interior COMPONENTS: this
# is the slice that needs the per-component anchor (bd if1e) as well as clause
# (d2), and that declined with either half alone. FIVE cqrt_ry_i32 gates, and
# every ancilla minted since the previous one discharged before each. STRICT
# stage 2b.
add_test(NAME e2e-slice-control-grover-derived-oracle-2iter
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_derived_oracle_2iter.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_derived_oracle_2iter.expected.log")

# bd test_C_libtooling-x67f (M-C Increment 7a) — the DERIVED oracle AND the
# `+= off` / `-= off` offset trick in ONE program, which is the union of
# slice_control_seq_grover.c (offset, direct oracle) and
# slice_control_grover_derived_oracle.c (derived oracle, no offset) and did not
# compile until the LATE in-place reassignment round: `lowerOps` runs before
# `uncompute`, so the oracle chain's planned discharge was invisible to the M-C
# prior-use fence, the `-= off` minted a fresh rail, and the S-dagger theta
# declined at the M-A guard. Three cqrt_ry_i32 gates, three cqrt_alloc_i32, and
# only h0 allocated at each gate. STRICT stage 2b.
add_test(NAME e2e-slice-control-grover-derived-oracle-offset
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_derived_oracle_offset.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_derived_oracle_offset.expected.log")

# bd test_C_libtooling-lyyf (M-A Increment 7b) — the M-A live-record guard as a
# WARNING, end to end. The canonical NON-LIFTABLE residue (`q = theta; w = q*2;
# c = q*3; w = theta(w)`), whose dead record is q's own SOURCE rail: no adjoint
# can return it to |0> once c is a surviving record of it, so M-B leaves it
# BORROWED forever. Until 7b this DECLINED and `opt` exited non-zero; the ruling
# is that a leftover-record dephasing is the user's circuit, so it now warns and
# lowers. This is the only layer that LINKS the module `opt` hands back after a
# warning. The warning TEXT is pinned at the lit layer (the `WARN` prefix on all
# 25 lowering_reject_live_record_*.ll) — the harness diffs the runtime trace, not
# stage 2's stderr. STRICT stage 2b: 0 frees, everything left allocated.
add_test(NAME e2e-slice-live-record-source-rail-warn
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_live_record_source_rail_warn.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_live_record_source_rail_warn.expected.log")

# bd 3c6m.5: cross-domain int<->long-double casts. Two direction slices — the
# LINK-proof that the 18 new int<->f80 cast symbols resolve + signature-match the
# runtime. A non-integer f80 factor (1.5L) keeps clang -O1 from folding the cast
# away (a ×2.0 round-trip collapses to `shl`, Rule 9).
add_test(NAME e2e-slice-cast-int-to-f80
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_int_to_f80.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_int_to_f80.expected.log")

add_test(NAME e2e-slice-cast-f80-to-int
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_f80_to_int.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_cast_f80_to_int.expected.log")

# bd p119.7: the fp<->int `bitcast` REINTERPRET round-trip (EXTRACT_WORDS /
# INSERT_WORDS — the idiom that opens nearly every injected openlibm body). The
# ONLY layer that LINK-proves cq_template_bitcast_f64_to_i64 + _i64_to_f64 resolve
# + signature-match the runtime; the golden pins the reversible relabel chain
# (theta -> ry -> bitcast f64->i64 -> xor -> bitcast i64->f64 -> measure).
add_test(NAME e2e-slice-bitcast-words
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitcast_words.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitcast_words.expected.log")

# bd 3c6m.7 / p119: the FIRST transcendental compiled by SOURCE INJECTION (Rule 18) —
# a BRANCHLESS soft-exp (select range reduction, no tables/control/scratch) inlined to
# stock reversible opcodes. Load-bearing on BOTH p119 unlocks: p119.6
# (cq_template_fptosi_f64_to_i32 on the kjd1 fp-select merge) AND p119.7
# (cq_template_bitcast_i64_to_f64 for the 2^n INSERT_WORDS scale). The golden pins the
# whole branchless-exp reversible-opcode stream end-to-end.
add_test(NAME e2e-slice-branchless-exp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp.expected.log")

# bd 3c6m.10 / L1: the SECOND source-injected transcendental — a BRANCHLESS soft-log
# (musl's core algorithm, special-case branches removed). Range reduction is the
# canonical boundary-shift bit trick: pure i64 add/ashr/and on the punned bit pattern
# (ZERO selects, zero control flow), round-tripping BOTH p119.7 bitcast directions
# (f64->i64 EXTRACT_WORDS and i64->f64 INSERT_WORDS), then musl's minimax R(z) on
# s=f/(2+f) as straight-line fp arithmetic (fdiv QQ + fmuladd keep-set contraction).
# The golden pins the whole branchless-log reversible-opcode stream end-to-end.
add_test(NAME e2e-slice-branchless-log
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log.expected.log")

# bd 3c6m.10 / L1 (batch cbrt/log1p/expm1): three more source-injected
# transcendentals landed by the branchless-authored body spine. Corpus twins in
# tools/library_coverage/branchless/{cbrt,log1p,expm1}.c — each body kept in sync.

# cbrt: FreeBSD/openlibm's s_cbrt.c, special-case branches removed. ZERO selects —
# the rough seed "divides the exponent by 3" as an integer udiv on the punned high
# word (hx/3 + Kahan B1), the sign rides a bit, the 23-bit round is add+mask on the
# pattern; clang folds the sign-clear to the hardware-kept @llvm.fabs
# (cq_template_fabs_f64). Both p119.7 bitcast directions, twice. <=1 ulp vs host libm.
add_test(NAME e2e-slice-branchless-cbrt
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cbrt.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cbrt.expected.log")

# log1p: openlibm's near-0 range-reduction branch thicket dissolved by an EXACT
# Knuth 2Sum (1+x == u+c) + the branchless soft-log of u + the c/u correction —
# ZERO selects, zero control flow. <=2 ulp vs host libm incl. the near-0 region.
add_test(NAME e2e-slice-branchless-log1p
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log1p.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log1p.expected.log")

# expm1: openlibm's per-k reconstruction thicket replaced by the single
# cancellation-free identity 2^n*(1+expm1(r)) - 1 = scale*Pr + (scale-1), keeping
# openlibm's accurate Q1..Q5 primary. The ONLY control is exp's round-bias fp
# select (the kjd1 controlled-copy merge). <=2 ulp vs host libm incl. near 0.
add_test(NAME e2e-slice-branchless-expm1
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_expm1.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_expm1.expected.log")

# bd 3c6m.21 / L1: atan by SOURCE INJECTION. openlibm's 5-segment |x| branch
# ladder (the L6-nested-ctrl blocker) replaced by Cephes's 3-segment reduction
# rendered branchless: the reduced arg xr = N/D is ONE unconditional division
# with N,D from CONSTANT-operand selects (so clang keeps them selects, not
# branches — a division on a bare select arm would SimplifyCFG-branch-ify into
# tainted control flow), then Cephes's degree-4/5 rational R(z) as straight-line
# fmuladd + fdiv, with the sign on a copysign keep-set leaf. 5 fp-select merges.
# <=1.15 ulp vs host libm (dense breakpoint + tail sweeps).
add_test(NAME e2e-slice-branchless-atan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan.expected.log")

# bd 3c6m.47 / L1: tanh by SOURCE INJECTION. openlibm's 4-range |x| branch (the
# L6-nested-ctrl blocker) replaced by its OWN |x|<1 kernel made valid for all x:
# tanh(|x|) = -t/(t+2), t = expm1(-2|x|). expm1 is inlined (the branchless kernel,
# == branchless/expm1.c). Saturation is branchless via fmin(|x|,20) — which ALSO
# keeps expm1's arg in-domain (load-bearing for correctness, not just speed). The
# only control is expm1's round-bias fp select. <=3.1 ulp vs host libm (worst
# ~3.05 near |x|=0.125, inherited from the branchless expm1 kernel).
add_test(NAME e2e-slice-branchless-tanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanh.expected.log")

# bd 3c6m.37 / 3c6m.35 / L1: log2 and log10 by SOURCE INJECTION. openlibm's
# e_log2.c/e_log10.c are ALREADY branchless in their core — the ONLY control flow
# is the leading special-case ladder (x subnormal / x<=0 / inf / NaN / x==1 —
# src/e_log{2,10}.c:50, the L6-nested-ctrl census blocker). These bodies remove
# exactly those data-dependent branches: the {k,1+f} decomposition is the
# canonical full-64-bit boundary-shift bit trick (== branchless/log.c, ZERO
# selects), then openlibm's VERBATIM extra-precision combining — log(m)=hi+lo
# (SET_LOW_WORD via a bitcast+and+bitcast round-trip) scaled by 1/ln2 resp.
# 1/ln10 and k (resp. k*log10(2)) added by a Dekker two-sum. All straight-line
# fp + both p119.7 bitcast directions, zero control flow. ~1 ulp on finite
# normal x>0; log2 is exact at powers of two (k integer-exact, m==1 => log2 m==0).
add_test(NAME e2e-slice-branchless-log2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log2.expected.log")

add_test(NAME e2e-slice-branchless-log10
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log10.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_log10.expected.log")

# bd 3c6m.23/.18/.20/.22/.45/.26 / L2-closure: the L2-CLOSURE batch — six compound
# transcendentals by SOURCE INJECTION, each a branchless body that CALLS an L1 leaf
# (atanh/acosh/asinh -> log1p; atan2 -> atan; sinh/cosh -> expm1) resolved by the
# census closure-link and inlined (mirrors tanh->expm1). Each slice inlines a static
# twin of BOTH the compound body AND the leaf, kept in sync with the corpus twins in
# tools/library_coverage/branchless/. All overflow-safe + cancellation-free renderings
# (see per-file headers); <=2.33 ulp vs host libm across their finite domains.
add_test(NAME e2e-slice-branchless-atanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atanh.expected.log")

add_test(NAME e2e-slice-branchless-acosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acosh.expected.log")

add_test(NAME e2e-slice-branchless-asinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asinh.expected.log")

add_test(NAME e2e-slice-branchless-atan2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2.expected.log")

# bd 3c6m.48: the OTHER two taint masks of atan2. The census now certifies a
# multi-arg fn's COMPILES only if EVERY tainted-double combination lowers (each mask
# is a distinct unitary), so each accepted combination gets its own linked golden.
# slice_branchless_atan2.c pins (q,c) [y tainted, x const]; these pin (c,q) [y const,
# x tainted — exercises the fdiv_lh literal/handle division + an x-tainted quadrant
# merge] and (q,q) [both tainted, two qubits — handle/handle fdiv + a NESTED
# tainted-condition quadrant select, inner (y<0)?±PI merge feeding the outer (x<0)?
# merge as a copy source]. Both are pure value-embeddings (0 controlled rotations,
# balanced flag frees; the quadrant/off DATA rails left allocated, never dirty-freed).
add_test(NAME e2e-slice-branchless-atan2-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_cq.expected.log")

add_test(NAME e2e-slice-branchless-atan2-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_atan2_qq.expected.log")

add_test(NAME e2e-slice-branchless-sinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinh.expected.log")

add_test(NAME e2e-slice-branchless-cosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosh.expected.log")

# bd 3c6m.27/.28 / L2-closure: erf + erfc — the deepest branchy libm body
# (openlibm s_erf.c: FIVE |x| segments + an exp-based asymptotic). Rendered
# branchless via the atan pattern: CONSTANT-operand fp selects producing 0/1
# regime weights that feed an UNCONDITIONAL weighted sum (so clang -O1 cannot
# branch-ify the expensive exp regime onto one arm), over openlibm's own minimax
# coefficients. The exp asymptotic uses the L2-closure spine — exp(y) via the
# branchless expm1 leaf (exp(y)=2^n*(expm1(r)+1), r near 0). Each slice inlines a
# static twin of BOTH the body AND the leaf, kept in sync with the corpus twins
# tools/library_coverage/branchless/{erf,erfc,expm1}.c. Faithful branchless erf/erfc
# over openlibm's coefficients (spot-checked to a few ulp; runtime is trace-only).
# The ONLY layer that LINKS the whole erf/erfc opcode stream.
add_test(NAME e2e-slice-branchless-erf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erf.expected.log")

add_test(NAME e2e-slice-branchless-erfc
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erfc.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_erfc.expected.log")

# bd 3c6m.44/.25 / L1: sin + cos by SOURCE INJECTION. openlibm's sin/cos reduce
# with Payne–Hanek, storing the split product into a multi-word scratch double[]
# (e_rem_pio2.c:174 — the L5-shadow `tainted value stored to memory` blocker).
# Replaced by a REGISTER-ONLY, BRANCHLESS Cody–Waite reduction (fn=rint(x·2/π),
# 2-term ≈66-bit π/2) + fdlibm k_sin/k_cos kernels, with the quadrant (fn mod 4)
# derived ENTIRELY in fp (floor keep-set, no fptosi) and blended by CONSTANT-
# operand fp selects into an UNCONDITIONAL weighted sum (the atan/erf pattern, the
# kjd1 fp-DATA select controlled-copy merge). cos = sin(x+π/2) reuses the sin
# weights on (fn+1). fmin/fmax clamp the reduced arg so the body is FINITE for
# every double (no in-domain NaN/Inf). Corpus twins:
# tools/library_coverage/branchless/{sin,cos}.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-sin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sin.expected.log")

add_test(NAME e2e-slice-branchless-cos
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cos.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cos.expected.log")

# bd 20xt.8 Inc 1: the ld80 (x86_fp80) branchless-leaf twins of {sin,cos} — the
# Bennett-parity path for the lgammal hybrid slice. Same 2-term Cody–Waite
# reduction + fp-const-select quadrant blend as the f64 bodies, retyped to
# `long double` with the ld80 rem_pio2l constants (39-bit pio2_1 kept `double`,
# NEGATIVE tail) and the grown ld80 k_sinl (S1..S8) / k_cosl (C1..C7) kernels.
# PURE-REGISTER: the rintl/floorl/fminl/fmaxl keep-set leaves lower to
# cq_template_*_f80 (curated intrinsic bodies) and the fp selects to
# cqrt_copy_f80_controlled (kjd1) — no Shadow/i80/memcpy. A DISJOINT
# hybrid/authored-leaf provenance, never quoted with the real-openlibm goldens.
# Corpus twins: tools/library_coverage/branchless/{sinl,cosl}.c — keep in sync.
add_test(NAME e2e-slice-branchless-sinl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_sinl.expected.log")

add_test(NAME e2e-slice-branchless-cosl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_cosl.expected.log")

# bd 20xt.9: the ld80 (x86_fp80) branchless-leaf tan twin — the missing trio leaf
# beside sinl/cosl. Reuses the SAME rem_pio2l reduction + k_sinl/k_cosl kernels;
# tan is π-periodic so only fn mod 2 matters — reconstructed as the RATIO S/C (even)
# or -C/S (odd), NOT openlibm's branchy ld80/k_tanl.c polynomial. The tanl-specific
# op is ONE unconditional QQ division num/den -> cq_template_fdiv_f80; the parity
# blend is a kjd1 const-operand fp select -> cqrt_copy_f80_controlled. PURE-REGISTER,
# DISJOINT hybrid/authored-leaf provenance (census tanl.f80 stays declined, no delta),
# never quoted with the real-openlibm goldens. Corpus twin:
# tools/library_coverage/branchless/tanl.c — keep in sync.
add_test(NAME e2e-slice-branchless-tanl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tanl.expected.log")

# bd 20xt.8 Inc 2: the ld80 (x86_fp80) branchless-leaf natural-log twin — the
# third Bennett-parity leaf for the lgammal hybrid slice. e_logl.c's small-exponent
# path log(1+f)=f−½f²+f³P(f)/Q(f) taken UNCONDITIONALLY (faithful over the whole
# centered mantissa for every exponent — the f64 branchless/log.c single-path move),
# with the ld80 P[7]/Q[6]/C1/C2 coefficients. PURE-REGISTER: the frexp mantissa/
# exponent split is a `union IEEEl2bits` bit-cast that SROA promotes to reversible
# cq_template_{bitcast,lshr,shl,and,or,trunc,zext}_i80/i64/i32 surgery on the f80
# (NO Shadow/qram/alloca — a 10-byte fp80 memcpy is deliberately avoided), the √2/2
# centering is ONE constant-operand fp select → cqrt_copy_f80_controlled (kjd1), and
# k is carried to fp with sitofp i32→f80. A DISJOINT hybrid/authored-leaf provenance,
# never quoted with the real-openlibm goldens. Corpus twin:
# tools/library_coverage/branchless/logl.c — keep in sync.
add_test(NAME e2e-slice-branchless-logl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logl.expected.log")

# bd 20xt.8 Inc 4: the ld80 (x86_fp80) HYBRID lgammal slice — promotes the census
# cell lgammal.f80 COMPILES→VERIFIED. The REAL openlibm ld80/e_lgammal_r.c outer
# ladder (sin_pi reflection helper + the [1.5,2.5] rational / x≥8 asymptotic /
# negative-x reflection branch ladder + every poly coefficient, VERBATIM; the only
# mechanical edits are the GET_LDOUBLE_WORDS union word-read shim, u_int32_t, the
# olm_ entry renames, and the inner sinl/cosl/logl→bsinl/bcosl/blogl +
# floorl/fabsl→__builtin_* renames) wrapped around the THREE AUTHORED branchless
# leaves bsinl/bcosl/blogl (textually identical to slice_branchless_{sinl,cosl,logl}.c;
# always_inline so clang -O1 inlines them into the tainted seed — never spec-cloned,
# the inline-not-cloned lesson). A DISJOINT hybrid/authored-leaf provenance —
# NEVER quoted alongside the real-openlibm goldens; the census cell STAYS declined
# (the ld80 census injects real openlibm sinl/cosl (Payne–Hanek) + logl, none of
# which lowers), so NO census delta. Lowers PURE-REGISTER: opt exit 0, verify-clean,
# 0 qram/Shadow/alloca, 0 spec-clones, 1 ry + 1 measure, deterministic. Corpus twins
# tools/library_coverage/branchless/{sinl,cosl,logl}.c — keep in sync.
add_test(NAME e2e-slice-hybrid-lgammal
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_hybrid_lgammal.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_hybrid_lgammal.expected.log")

# bd 3c6m.46/.30/.19/.17: tan + exp2 + asin + acos by SOURCE INJECTION, all
# single-arg. tan (L1) REUSES the sin/cos Cody–Waite reduction and reconstructs
# tan as a RATIO of the SAME k_sin/k_cos kernels — tan is π-periodic so only the
# PARITY of fn matters (fn even → S/C, fn odd → −C/S), built by ONE constant-operand
# fp select feeding two UNCONDITIONAL weighted sums + ONE division (no k_tan table,
# no Payne–Hanek scratch → sidesteps the L5-shadow blocker). exp2/asin/acos are
# L2-closures: exp2(x)=exp(x·ln2) (dissolves the s_exp2 table, L5-qrom), asin(x)=
# atan(x/√(fmax(1−x²,TINY))) (the fmax clamp kills the |x|→1 NaN — dissolves the
# e_asin nested-if ladder, L6-nested-ctrl), acos(x)=π/2−asin(x). Each slice inlines
# static twins of its leaf(s); corpus twins tools/library_coverage/branchless/
# {tan,exp2,exp,asin,acos,atan}.c — keep textually in sync. All four lower to PURE
# value-embedding traces (0 controlled rotations, balanced flag frees, one measure).
add_test(NAME e2e-slice-branchless-tan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tan.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_tan.expected.log")

add_test(NAME e2e-slice-branchless-exp2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_exp2.expected.log")

add_test(NAME e2e-slice-branchless-asin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_asin.expected.log")

add_test(NAME e2e-slice-branchless-acos
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acos.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_acos.expected.log")

# bd 3c6m Batch A (.38/.16/.43/.42/.32/.41/.33): the EASY branchless injection
# decliners flipped decline→COMPILES (injection scoreboard 23→30). Each is a keep-set
# identity that dissolves openlibm's special-case control flow with ZERO selects:
#   logb  = (double)(((bits>>52)&0x7FF)-1023)         [field extract]
#   fdim  = fmax(x-y, 0)                               [keep-set fmax]
#   scalbn/scalbln = x * bitcast((n+1023)<<52)         [INSERT_WORDS scale, n classical]
#   fmod  = x - trunc(x/y)*y                           [keep-set trunc]
#   remainder = x - rint(x/y)*y                        [keep-set rint]
#   hypot = fmax(|x|,|y|)*sqrt(1+(fmin/fmax)^2)         [overflow-safe, keep-set fmax/fmin/sqrt]
# The four 2-arg fns (fdim/fmod/remainder/hypot) get a golden PER accepted taint mask
# (qc/cq/qq — 3c6m.48: each mask is a distinct unitary). All traces are PURE
# value-embeddings (0 selects → 0 controlled rotations, 0 flags, single measure).
# Corpus twins tools/library_coverage/branchless/{logb,fdim,scalbn,scalbln,fmod,
# remainder,hypot}.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-logb
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logb.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_logb.expected.log")

add_test(NAME e2e-slice-libm-real-scalbn
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbn.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbn.expected.log")

# bd 3c6m.51 Inc 1 — the FIRST long-double libm slice: the real openlibm fdiml
# over x86_fp80, exercising the promoteFp80Union peephole (union bit-pattern
# memory -> bitcast x86_fp80 -> i80 + lshr/trunc/zext, padding modelled as 0) and
# the i80 extraction template surface (bitcast/lshr/trunc/and/icmp i80).
add_test(NAME e2e-slice-libm-real-fdiml
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdiml.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdiml.expected.log")

# bd 3c6m.51 Inc 3 — the long-double RMW slices: the real openlibm scalbnl (+
# its ldexpl strong-reference alias + the scalblnl clamp wrapper) over x86_fp80,
# exercising the MULTI-BLOCK promoteFp80Union (canonicalize + PromoteMemToReg:
# fp80 re-seed in the subnormal arm, two offset-8 field-insert PACK arms, the
# 5-way f80 return merge; bd tkju removed the vendored copysignl/copysign
# bodies and with them their twin unions — copysign is a Rule-18 keep, so the
# overflow arm is now one cq_template_copysign_f80_lh and the traces moved
# 258 -> 250 lines), the §4.1 per-bit
# padding-taint walk (the store-backs KEEP diverged straddle bits that land only
# in the dropped >= 80 padding), the i80 field-insert write surface
# (zext/shl/or i80 + and-clear + bitcast i80->f80), and the PredMux + kjd1
# cqrt_copy_f80_controlled merge downstream. The three traces are byte-identical
# by construction (alias + const-folded clamp) — kept as separate goldens so
# each census cell is independently pinned. cbrtl (below, bd etiq) additionally
# exercises the volatile-const-LOCAL fold (its vd2/vd1 rounding constants), the
# TWO-union promotion (u and v), and the tainted exponent-class + k%3 switches.
add_test(NAME e2e-slice-libm-real-scalbnl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnl.expected.log")

add_test(NAME e2e-slice-libm-real-ldexpl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpl.expected.log")

add_test(NAME e2e-slice-libm-real-scalblnl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnl.expected.log")

add_test(NAME e2e-slice-libm-real-cbrtl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtl.expected.log")

# bd adia (3c6m.55 Lever C) — the FIRST ld80 TRANSCENDENTAL golden: the real
# openlibm coshl closure (e_coshl + e_expl + s_expm1l + __polevll + __isnanl +
# scalbnl-as-ldexpl) at plain -O1. The Lever A+B+C composition of record: every
# union promotes, both polevll Horner loops force-unroll, the coshl exponent
# ladder's select-form short-circuit conditions flatten and mint, and the
# outlined expl specializes under tainted control (PredMux speculates the
# proven-pure body; the Phase-6 clone Bennett-wraps it with the fp80-ABI
# copy-out and lowerCloneControl flattens its internal branch web).
# bd tkju: floorl and copysign{,l} are Rule-18 HARDWARE KEEPS — s_floorl.c /
# s_copysign{,l}.c are NO LONGER vendored, the sites are spelled __builtin_*
# and lower to cq_template_{floor,copysign}_f80 / _f64. Dropping those three
# software ladders took the trace 21426 -> 9036 lines (the floorl body was the
# bulk: its inexact-raise fadd idiom, word RMW and Q+Q compares are gone, and
# @__cq_q_olm_floorl_1{,_unc} is no longer specialized). 9036 trace lines,
# deterministic; exactly ONE ry + ONE measure (Rule 5).
add_test(NAME e2e-slice-libm-real-coshl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshl.expected.log")

# bd 3c6m.53 (20xt data-symbol closure) — the ld80 census cell atanl.f80
# COMPILES->VERIFIED at plain -O1: the real openlibm atanl closure
# (ld80/s_atanl.c + ld80/invtrig.c atanhi/atanlo/aT tables + invtrig.h
# T_even/T_odd + amd64_fpmath.h union). The proof the 20xt data closure
# unblocked: with the coefficient tables LINKED+INITIALIZED the two
# data-indexed reads atanhi[id]/atanlo[id] classify as cqrt_qram_* QROM reads
# (n=4 each) instead of fake-declining on an uninitialized [0 x x86_fp80]; the
# constant-index reads const-fold. 619-line deterministic trace; exactly ONE
# ry + ONE measure (Rule 5); 0 double-frees, all freed handles minted (Rule 6/8).
add_test(NAME e2e-slice-libm-real-atanl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanl.expected.log")

# bd 20xt.6 — the ld80 census cell atan2l.f80 COMPILES(spec-clone)->VERIFIED at
# the plain -O1 ship floor: the real openlibm atan2l closure (src/e_atan2l.c: the
# special-case/quadrant control ladder + m=2*sign(x)+sign(y) route wrapping the
# inner olm_atanl(fabsl(y/x)) call; over the SAME vendored inner-atanl body as
# slice_libm_real_atanl.c — ld80/s_atanl.c + ld80/invtrig.c atanhi[4]/atanlo[4]/
# aT[13]/pi_lo + invtrig.h T_even/T_odd + amd64_fpmath.h union). This is the
# LINK-layer proof (Rule 2) that the 20xt.3/.4/.5.2 inner-atanl clone-control
# machinery emits+resolves end-to-end: at plain -O1 the inner atanl stays
# OUTLINED and lowers to a Phase-6 spec clone @__cq_q_olm_atanl_1 whose internal
# tainted argument-reduction cascade flattens (lowerCloneControl) and whose two
# data-indexed atanhi[id]/atanlo[id] QROM reads coherently escape via the 20xt.5.2
# Bennett-clone bypass (the range-id is the NeedsMask 4294967295-sentinel phi, not
# the deferred fcmp-select). 1712-line deterministic trace; exactly ONE ry + ONE
# measure (Rule 5); 2 cqrt_qram_alloc_f80(4) tables each read+reversed (4 loads);
# 0 double-frees, all 398 freed handles minted (Rule 6/8). Faithfulness-audited:
# both bodies verbatim-equal to the vendored source modulo the declared renames
# (entry rename, __i386__ guard-out, atanl->olm_atanl, fabsl->__builtin_fabsl).
# See bd libm-real-slice-recipe, clone-control-qram-coherent-escape-20xt52.
add_test(NAME e2e-slice-libm-real-atan2l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2l.expected.log")

# bd 20xt — the ld80 census cell exp2l.f80 COMPILES->VERIFIED at the plain -O1
# ship floor: the real openlibm exp2l closure (ld80/s_exp2l.c — the self-
# contained degree-6 minimax table tbl[TBLSIZE*2]=128 hi/lo pairs + P1..P6 +
# redux + the volatile twom10000 + amd64_fpmath.h union; NO inner libm calls,
# the __i386__ exp2() fallback is #ifdef-guarded out). The tainted-index reads
# tbl[i0]/tbl[i0+1] (i0 from x+redux via u.bits.manl) classify as cqrt_qram_*
# QROM reads over cqrt_qram_alloc_f64(256); the fp80 union promotion drives the
# u.xbits/u.bits/v.xbits field extract/insert family. 493-line deterministic
# trace (matches the census hand-verify); exactly ONE ry + ONE measure (Rule 5);
# 0 double-frees, all 100 freed handles minted (Rule 6/8); tables+body
# faithfulness-audited (tbl 130 lines + P1..P6 byte-identical to the vendored
# source; body verbatim modulo the entry rename). See bd libm-real-slice-recipe.
add_test(NAME e2e-slice-libm-real-exp2l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2l.expected.log")

# bd 20xt.1 — the general constant-amount funnel shift fshl(a,b,n), a!=b, both
# data operands quantum handles (the (ix<<16)|(i0>>16) word-extract idiom that
# unblocks erfl/erfcl). This e2e is the LINK-layer proof (Rule 2/Rule 16) that
# the new frozen symbols cq_template_fshl_i32_qql[_unc] RESOLVE + signature-match:
# a measured forward funnel + a dead phase-armed funnel reverse-played through the
# void _unc (recompute-and-XOR from live sources). 19-line deterministic trace;
# 0 double-frees; every rail freed only at |0>. Flagged by the Rule-13 review as
# the missing regression baseline for the funnel symbols.
add_test(NAME e2e-slice-funnel-fshl-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_funnel_fshl_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_funnel_fshl_qq.expected.log")

# bd 20xt.2 — the ld80 census cells erfl.f80 / erfcl.f80 COMPILE->VERIFIED at the
# plain -O1 ship floor, post the 20xt.1 general funnel-shift axis that unblocked
# them: the real openlibm erf-family closure (ld80/s_erfl.c pp/qq/pa/qa/ra/sa/rb/
# sb/rc/sc tables + the inner ld80/e_expl.c expl, called TWICE in the asymptotic
# arm, over its own closure __isnanl / __polevll / ldexpl==scalbnl / floorl+fabsl
# keep-intrinsics). The 20xt.1 payoff is direct: the `ix=(ix<<16)|(i0>>16)` word
# extract fuses to @llvm.fshl.i32 -> cq_template_fshl_i32_qql; every |x| range-band
# select flattens under PredMux + the kjd1 fp-select controlled-copy family; the
# ieee_extended_shape_type GET/SET_LDOUBLE_WORDS fp80 union RMW (the SET_LDOUBLE_
# WORDS low-word truncation is the multi-block 3c6m.51 Shadow store) promotes; the
# const-index coefficient reads all const-fold (NO QROM); and both expl inlines
# force-unroll their __polevll Horner loops + pack their ldexpl exponent-RMW union.
# Deterministic (erfl 2480 / erfcl 2686 trace lines, post bd tkju: copysign{,l}
# are Rule-18 keeps, the vendored s_copysign{,l}.c bodies are gone and the sites
# lower to cq_template_copysign_f80_lh / _f64_lh); exactly ONE ry + ONE measure
# (Rule 5); 0 double-frees, no free of a never-minted or measured handle (Rule 6/8);
# bodies faithfulness-audited normalized-identical to source modulo the declared
# entry/keep-intrinsic renames. See bd libm-real-slice-recipe, ld80-fshl-funnel-erfl-erfcl.
add_test(NAME e2e-slice-libm-real-erfl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfl.expected.log")

add_test(NAME e2e-slice-libm-real-erfcl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcl.expected.log")

# bd szpr (3c6m.51 Inc-3 critic Gap 1) — the i80 field-insert WRITE-surface
# `_unc` adjoints trace-verified: a dead promoted-union RMW on a dedicated rail
# (result-dropped cq_phi keep-alive, the slice_f80.c case-B discipline) makes
# the whole-DAG LIFO uncompute play cq_template_{or,shl,zext,and}_i80*_unc +
# both i80<->f80 bitcast adjoints, each rail freed at proven-|0>. The analytic
# audit of record lives in the slice header.
add_test(NAME e2e-slice-fp80-union-unc
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fp80_union_unc.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_fp80_union_unc.expected.log")

# bd vqlq — an fp80-union RMW inside a Phase-6 SPECIALIZED callee: the
# argument-derived OPPORTUNISTIC union seed (promoteFp80Union rewrites the
# untainted callee to register form pre-detect) + the scanBody value-bitcast
# carve (Rule-14 mirror of castInScope) compose so @__cq_q_qpack_1 clones,
# lowers the i80 write surface, and Bennett-reverse-plays its full `_unc`
# family (szpr's route (a)). The trace audit lives in the caller TU header.
add_test(NAME e2e-spec-fp80-union
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp80_union_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp80_union_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp80_union_caller.expected.log")

# bd 3c6m.54 — the fp-ABI specialization: a Phase-6 clone with an x86_fp80 quantum
# ARG and RETURN. The i32-only FpAbi gate is lifted so a straight-line fp80 helper
# `lpoly` clones with the fp80 arg/return rewritten to i32 handles (Rule 15), the
# fp80 body lowered to `cq_template_f*_f80` producers, the result copied out via
# `cqrt_copy_f80`, and the `_f80_unc` family Bennett-reverse-played. The only layer
# that LINKS: proves the fp-ABI symbols resolve + signature-match (Rule 2/16).
add_test(NAME e2e-spec-fp-arg
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_arg_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_arg_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_arg_caller.expected.log")

# bd 3c6m.14.1 — the pure-callee proof widened to admit an fp80 BIT-PATTERN
# `icmp i80` (one ConstantInt operand ⇒ provably `_hl`). A tainted arm's call to
# such a callee is now speculated by PredMux E4 and the callee specialized into a
# Phase-6 Bennett clone, so `cq_template_icmp_eq_i80_hl` + its void `_unc` (plus
# the `and_i80_hl` / `bitcast_f80_to_i80` twins) must RESOLVE and SIGNATURE-MATCH
# — which only this layer proves (Rule 2/16). MULTI-file deliberately: inlined,
# the compare would be an ordinary arm-resident one (bd 3c6m.61's shipped
# surface) and the slice would prove nothing new. This is also the increment's
# real-body anchor: all 237 registered slices moved zero bytes under the change
# (measured), because hypotl is the only one emitting an i80 compare at all and
# it does so at top level, never through a callee.
add_test(NAME e2e-predmux-purecallee-i80cmp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/predmux_purecallee_i80cmp_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/predmux_purecallee_i80cmp_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/predmux_purecallee_i80cmp_caller.expected.log")

add_test(NAME e2e-slice-libm-real-lround
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lround.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lround.expected.log")

# 3c6m.14 L6 Inc 2 — real openlibm log/cbrt/tanh (tanh = the i1-phi-feeding-a-
# select-condition mechanism cell; expm1 doubly inlined).
add_test(NAME e2e-slice-libm-real-log
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log.expected.log")

add_test(NAME e2e-slice-libm-real-cbrt
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrt.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrt.expected.log")

add_test(NAME e2e-slice-libm-real-tanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanh.expected.log")

# 3c6m.14 L6 Inc 3 — real openlibm exp/atan/erf (volatile-const fold + claimable
# QROM reads under control: provable xsb index (exp), pow2-masked phi-of-constants
# index (atan), composition at scale with two exp inlines (erf)).
add_test(NAME e2e-slice-libm-real-exp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp.expected.log")

add_test(NAME e2e-slice-libm-real-atan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan.expected.log")

add_test(NAME e2e-slice-libm-real-erf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erf.expected.log")

# 3c6m.53 — real-openlibm width-sibling verification (34 cells promoted from
# injection-covered -> VERIFIED post-L6 PredMux). 23 f32 siblings + 11 additional
# f64 (atan2 cosh erfc exp2 expm1 ldexp llround log10 log2 logb modf scalbln sinh).
# NOTE: the log1p family (log1p{,f}, atanh{,f}) is census-O2 injection-covered but
# DECLINES at the -O1 verified floor (nested control exceeds PredMux accept shape),
# so it stays injection-covered, NOT verified (Rule 2). See bd 3c6m.53.

add_test(NAME e2e-slice-libm-real-atan2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2.expected.log")

add_test(NAME e2e-slice-libm-real-cosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cosh.expected.log")

add_test(NAME e2e-slice-libm-real-erfc
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfc.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfc.expected.log")

add_test(NAME e2e-slice-libm-real-exp2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2.expected.log")

add_test(NAME e2e-slice-libm-real-expm1
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1.expected.log")

add_test(NAME e2e-slice-libm-real-ilogb
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ilogb.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ilogb.expected.log")

add_test(NAME e2e-slice-libm-real-ldexp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexp.expected.log")

add_test(NAME e2e-slice-libm-real-llround
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llround.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llround.expected.log")

add_test(NAME e2e-slice-libm-real-log10
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10.expected.log")

add_test(NAME e2e-slice-libm-real-log2
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2.expected.log")

add_test(NAME e2e-slice-libm-real-logb
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logb.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logb.expected.log")

add_test(NAME e2e-slice-libm-real-modf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modf.expected.log")

add_test(NAME e2e-slice-libm-real-scalbln
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbln.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbln.expected.log")

add_test(NAME e2e-slice-libm-real-sinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinh.expected.log")

add_test(NAME e2e-slice-libm-real-atan2f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atan2f.expected.log")

add_test(NAME e2e-slice-libm-real-atanf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanf.expected.log")

add_test(NAME e2e-slice-libm-real-cbrtf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_cbrtf.expected.log")

add_test(NAME e2e-slice-libm-real-coshf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_coshf.expected.log")

add_test(NAME e2e-slice-libm-real-erfcf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erfcf.expected.log")

add_test(NAME e2e-slice-libm-real-erff
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erff.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_erff.expected.log")

add_test(NAME e2e-slice-libm-real-exp2f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_exp2f.expected.log")

add_test(NAME e2e-slice-libm-real-expf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expf.expected.log")

add_test(NAME e2e-slice-libm-real-expm1f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1f.expected.log")

add_test(NAME e2e-slice-libm-real-ilogbf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ilogbf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ilogbf.expected.log")

add_test(NAME e2e-slice-libm-real-ldexpf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_ldexpf.expected.log")

add_test(NAME e2e-slice-libm-real-llroundf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundf.expected.log")

add_test(NAME e2e-slice-libm-real-log10f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10f.expected.log")

add_test(NAME e2e-slice-libm-real-log2f
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2f.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2f.expected.log")

add_test(NAME e2e-slice-libm-real-logbf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logbf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logbf.expected.log")

add_test(NAME e2e-slice-libm-real-logf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logf.expected.log")

add_test(NAME e2e-slice-libm-real-lroundf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundf.expected.log")

add_test(NAME e2e-slice-libm-real-modff
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modff.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modff.expected.log")

add_test(NAME e2e-slice-libm-real-scalblnf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalblnf.expected.log")

add_test(NAME e2e-slice-libm-real-scalbnf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_scalbnf.expected.log")

add_test(NAME e2e-slice-libm-real-sinhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhf.expected.log")

add_test(NAME e2e-slice-libm-real-tanhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhf.expected.log")

add_test(NAME e2e-slice-branchless-scalbn
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbn.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbn.expected.log")

add_test(NAME e2e-slice-branchless-scalbln
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbln.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_scalbln.expected.log")

add_test(NAME e2e-slice-branchless-fdim
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim.expected.log")

add_test(NAME e2e-slice-branchless-fdim-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_cq.expected.log")

add_test(NAME e2e-slice-branchless-fdim-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fdim_qq.expected.log")

add_test(NAME e2e-slice-branchless-fmod
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod.expected.log")

add_test(NAME e2e-slice-branchless-fmod-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_cq.expected.log")

add_test(NAME e2e-slice-branchless-fmod-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_fmod_qq.expected.log")

add_test(NAME e2e-slice-branchless-remainder
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder.expected.log")

add_test(NAME e2e-slice-branchless-remainder-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_cq.expected.log")

add_test(NAME e2e-slice-branchless-remainder-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_remainder_qq.expected.log")

add_test(NAME e2e-slice-branchless-hypot
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot.expected.log")

add_test(NAME e2e-slice-branchless-hypot-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_cq.expected.log")

add_test(NAME e2e-slice-branchless-hypot-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_hypot_qq.expected.log")

# bd 3c6m Batch B (.40): pow by SOURCE INJECTION — the L2-closure pow(x,y) =
# exp2(y·log2(x)) [x>0], dissolving openlibm e_pow.c's sign/parity/overflow ladder +
# table-driven log/exp. BOTH leaves are authored branchless (log2 fully branchless;
# exp2→exp contributes ONE fp round-bias select — the kjd1 accept shape). Golden per
# accepted taint mask (qc/cq/qq — 3c6m.48); each is a PURE value-embedding (0 controlled
# rotations, single balanced flag, one measure). Injection scoreboard 30→31. Corpus twins
# tools/library_coverage/branchless/{pow,log2,exp2,exp}.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-pow
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow.expected.log")

add_test(NAME e2e-slice-branchless-pow-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_cq.expected.log")

add_test(NAME e2e-slice-branchless-pow-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_pow_qq.expected.log")

# bd 3c6m Batch C (.39): nextafter by SOURCE INJECTION — the L5-shadow wildcard. openlibm
# s_nextafter.c is a ladder of data-dependent branches (x==y early-out, x==0 subnormal
# seed, over/underflow flag raises). This body renders the one-ULP bit step FULLY
# ARITHMETIC (dir = (y>x)-(y<x); step = dir*(1-2*sign(x)); bitcast(bits(x)+step)) — the
# comparisons are fcmp->zext, the sign is a bit shift, no selects in the source. Golden per
# accepted taint mask (qc/cq/qq — 3c6m.48): qc/qq are fully arithmetic (0 flags); cq (x
# const) is where clang materializes bits(x)+up as an INTEGER const-select over the tainted
# `up` flag — one balanced cqrt_copy_i64_controlled merge (the base-4.4 integer select
# accept shape). Each a PURE value-embedding (0 controlled rotations, single measure).
# Injection scoreboard 31→32 (COMPLETE injection surface). Corpus twin
# tools/library_coverage/branchless/nextafter.c — keep textually in sync.
add_test(NAME e2e-slice-branchless-nextafter
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter.expected.log")

add_test(NAME e2e-slice-branchless-nextafter-cq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_cq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_cq.expected.log")

add_test(NAME e2e-slice-branchless-nextafter-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_branchless_nextafter_qq.expected.log")

# Phase 7.2 Increment 3 (test_C_libtooling-65wb.3): the controlled abort/exit PARK
# CASCADE (PRD-7.2 §2.8). `if (q > 5) abort();` lowers to flag mint -> graveyard
# cqrt_cswap -> cqrt_tape_write_i1 (the abort marker) -> uncontrolled remainder.
# The ONLY layer that links the park sequence; the golden proves the graveyard +
# flag are KEPT (NO cqrt_free anywhere — the §2-A GraveyardRails do-not-uncompute
# set, subtracted at both spine sites) and the abort call is erased.
add_test(NAME e2e-slice-control-abort
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_abort.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_abort.expected.log")

# test_C_libtooling-5j5: the ONE-REGISTER classical-mux lift. The natural
# `if (classical_c) q = cq_phi(q, a);` survives -O1 as a merge phi over two
# SSA names of one register; the lift RAUWs it away and the CLASSICAL branch
# stays byte-untouched, so the rz fires iff the condition held this shot.
# Goldens BOTH polarities in one run (argc>0 true / argc>100 false): the
# taken diamond's rz appears, the not-taken diamond's does not.
add_test(NAME e2e-slice-classical-if-gate
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_if_gate.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_if_gate.expected.log")

# Phase 7.1 Increment C (test_C_libtooling-sbt1.3): the N-ARY (N>2) one-register
# classical-mux lift. The natural classical N-way `switch` around an in-place
# quantum gate on ONE register survives -O1 as a `switch` with a single merge phi
# whose >2 incomings are distinct SSA names of the one register; the generalized
# lift (the (7a) reachability proof carried against ALL j != i, not just the 2-way
# complement) RAUWs it away and the CLASSICAL switch stays byte-untouched, so each
# case's cqrt_rz fires iff that case ran this shot. DISTINCT per-case gate-chain
# lengths (1/2/1/0) keep clang from merging the cases into one angle-selected
# block, preserving the N>2 phi; the executed case is the 2-gate chain
# (sel=(argc+1)%4=2), goldening the single-block-chain proof (condition (6)) for a
# REAL chain. A second register on the DEFAULT arm goldens the no-case-fires path.
# The only layer that LINKS — it re-proves the lifted N-ary form lowers to the
# phi-less rz-inside-the-case stream the pipeline already accepts (Increment C
# adds NO new symbol).
add_test(NAME e2e-slice-classical-switch-gate
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_switch_gate.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_classical_switch_gate.expected.log")

# Phase 4.5 (WI-6, test_C_libtooling-bkpz.6): the RSSA swap-routed tainted SWITCH,
# one golden per ACCEPT class — the only layer that LINKS, so the only proof every
# symbol the four switch emit paths mint resolves + signature-matches against the
# runtime (Rule 2, Rule 16). PHASE switch (N>=3 cases): per-case eq-flag mint ->
# |0> rail -> cqrt_cswap route -> verbatim cqrt_rz arg-1 -> route back -> rail
# free -> icmp_eq_inv strip + flag free; the N>=3 byte-diff exercises the N-way
# folded-gate scrub + N-way flatten (the §5 const-fold re-anchor BLOCKER's only
# downstream backstop). control_swap_switch_phase.ll is the pinned IR contract.
# REMOVED 2026-09-05 (3qlq Inc 1, OQ-4/OQ-11 / prep-b2): `e2e-slice-control-switch-phase`
# and `slice_control_switch_phase.expected.log`. PRD §6.2 P5 (the homogeneous-phase
# switch) LOWERS — Increment 1b implements it on the IR `switch` and ships 3 accept +
# 7 decline fixtures — but it has NO plain-C customer at the `-O1` ship floor. A phase
# arm's whole content is `call void @cq_phi(double)`, so every arm's suffix is identical
# modulo one operand and SimplifyCFG's common-code sinking ALWAYS applies: dense case
# values become a `[N x double] @switch.table` of ANGLES with ONE shared call, sparse
# ones a cascade joined by `phi double` (Inc 1b measured SEVEN spellings, N-gate arms
# included). The tainted-index table read is then a loud QRAM decline —
# `cq QRAM access: const-global table read under tainted control: index not provably
# in-bounds ...` — on the SUBJECT and on the pre-3qlq ORACLE alike. Both `-O1` outcomes
# are pinned in lit, `control_phase_switch_reject_table_fold.ll` carrying the verbatim
# `-O1` module. `slice_control_switch_phase.c` is KEPT in the tree, unregistered, with
# that record in its header; giving P5 a real e2e customer needs the table-fold
# recognizer, which is an owner decision (OQ-11), not something this increment may take.

# Phase 4.5 (WI-6): VALUE switch (N-way method-B on a shared routed base p != q):
# per-case route-in -> verbatim add chain -> route back, then ONE cqrt_copy_i32
# copy-out + LIFO reverse-play (route-back† · add `_inv` · route-in†) + rail/flag
# frees. control_swap_switch_value.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-switch-value
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_value.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_value.expected.log")

# Phase 4.5 (WI-6): constant DATA-MUX switch (all-ConstantInt merge): preload
# %out = cqrt_alloc(v_d) + per-case XOR-delta cqrt_alloc(v_i^v_d) +
# cqrt_copy_i32_controlled. Non-contiguous cases + pre-init default keep the real
# `switch` (clang -O1 folds the natural contiguous const-mux to a select chain).
# control_swap_switch_datamux.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-switch-datamux
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_datamux.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_datamux.expected.log")

# dugh (Phase 4×6): the SECOND propagation round. A data-mux merge (untainted by
# SSA data-flow) feeds an ONWARD-QUANTUM phase `cq_phi(r, .25)` — an OPAQUE call
# clang -O1 cannot fold into the switch incomings (a stock `r + const` WOULD fold,
# erasing the onward op), so a real onward-quantum op survives to opt.
# `repropagateControlMerges` re-seeds taint from the emitted %out so the onward
# cq_phi lowers IN PLACE to `cqrt_rz_i32(out, .25)` instead of declining. The only
# layer that LINK-proves the re-tainted onward Rz over the control merge.
add_test(NAME e2e-slice-control-cond-onward-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_onward_phase.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cond_onward_phase.expected.log")

# Phase 4.5 (WI-6): the equality-folded `br` diamond (`if (q==7) { phase arm }`) —
# the regression FLOOR for emitRegion-reuse via the additive D1-D7 tryEqFoldArm
# clause (§4D detection-only; re-tests the golden 4.1 diamond path end-to-end).
# control_swap_eqfold_diamond.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-switch-eqfold
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_eqfold.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_switch_eqfold.expected.log")

# Phase 5 (WI-6, test_C_libtooling-p2s2.6): the whole-DAG uncompute spine — the
# FIRST end-to-end proof of the void in-place `_unc` family + `cqrt_free`. The
# only layer that LINKS, so the only proof every `_unc` symbol the emitter mints
# (WI-3/WI-4) resolves AND signature-matches against the generated runtime ABI
# (WI-2) — the ir-pass fixtures assert IR text and never link. This slice caught
# the QQ `_unc` name disagreement (generator `..._qq_unc` vs emitter/bare-forward
# `..._unc`), invisible to FileCheck. TWO dead, unmeasured handles in a
# `noinline` helper (`noinline` is load-bearing: Phase-5 uncompute is gated OFF in
# `main`, and `-O1` would otherwise inline `slice` away so the uncompute never
# runs). `cq_phi` keeps the dead arithmetic alive past `-O1` DCE. Reverses the
# whole DAG ONCE in reverse program order: mul_qq `_unc` (bare, DD-3 slots) +
# two `_hl_unc` + Rz keep-alive undo (negated angle); SIX frees, one per rail,
# each after its last reverse-use; ZERO `_inv`, ZERO added measure, ZERO cswap.
add_test(NAME e2e-slice-uncompute-dead-dag
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_dag.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_dag.expected.log")

# M-B Increment 5a (bd test_C_libtooling-6uqc): the INTERIOR-RAIL uncompute. bd
# 6uqc's P1 end to end -- the first slice in which a rail that is NEITHER a dead
# terminal NOR a measured value is discharged. At HEAD (c36934a) `sitofp`/`fadd`/
# `sqrt`/`fcmp` all survived as allocated, entangled basis records of the wire
# with `opt` rc=0, verify clean and stage 2b silent (bd 1739: the checker does not
# track template-minted rails). This golden witnesses ORDER -- LIFO adjoints, each
# rail freed right after the adjoint that zeroes it, the whole reversal placed
# BEFORE the measurement -- and it witnesses the BORROWED-PARENT frontier by
# ABSENCE: `h0`, the `cqrt_alloc`-minted source wire, gets no negated-angle `ry`
# and no `cqrt_free`, because `Ry` is not a basis permutation and a record of it
# survives (Rule 6). It also LINKS the fp `_unc` grid the interior partition now
# reaches on a live chain (`sitofp_i32_to_f64_unc`, `fadd_f64_hl_unc`,
# `sqrt_f64_unc`, `fcmp_ole_f64_hl_unc`), which no ir-pass fixture can do.
# Strict stage 2b (no --allow-unproven).
add_test(NAME e2e-slice-uncompute-interior-chain
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_interior_chain.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_interior_chain.expected.log")

# M-B Increment 5b (bd test_C_libtooling-6uqc): bd 6uqc's P4 -- the interior
# chain FOLLOWED BY a chained cq_theta on the same wire. At d2828e3 this program
# ACCEPTED with four live entangled records at the second Ry (a silent-
# miscompile-class accept); at b4e329b it DECLINED loudly at the M-A live-record
# guard; it now LOWERS, because 5b's clause-(d) RIGHT disjunct proves the chained
# Ry runs only AFTER the discharge, so the whole LIFO reversal lands between the
# zext and the Ry. The golden is the only shipped gate that can see that ORDER --
# a reversal emitted after the Ry would read a post-Ry basis, which owner ruling
# 2026-08-27 forbids outright. Strict stage 2b.
add_test(NAME e2e-slice-uncompute-interior-chained-theta
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_interior_chained_theta.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_interior_chained_theta.expected.log")

# Phase 5 (WI-7, test_C_libtooling-p2s2.7): the permanent `_unc` LINK-COMPLETENESS
# guard for the shapes slice_uncompute_dead_dag does NOT exercise. WI-6 linked only
# the bare-QQ + `_hl` `_unc` forms; the `_lh`, tainted-cast, and `fneg` `_unc`
# symbols were link-probed ad-hoc during WI-6 but never committed, so a
# generator/emitter name or signature drift in any of those three families would be
# invisible to every test (the .ll fixtures assert IR text and never link — Rule
# 2/16). Three independent dead lineages in a `noinline` helper, each kept alive by
# a `(void) cq_phi`: (A) `100 - a` / `5 << s` -> sub_i32_lh_unc + shl_i32_lh_unc;
# (B) `(long) b` -> sext_i32_to_i64_unc; (C) `-fc` -> fneg_f32_unc. Whole-DAG LIFO
# reversal (chain C, then B, then A): each gate adjointed via its void `_unc` form
# (DD-3 slots: out first, then forward operands in original order), 7 frees (one per
# rail), Rz/Ry undone with negated angles; ZERO `_inv`, ZERO added measure, ZERO
# cqrt_cswap. Together with dead-dag, every `_unc` shape the emitter can mint is now
# permanently link-proven by SOME golden.
add_test(NAME e2e-slice-uncompute-dead-shapes
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_shapes.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_uncompute_dead_shapes.expected.log")

# Phase 7.1 Increment A (test_C_libtooling-sbt1.1): the Q+Q (both-operands-
# tainted) DATA-position compare. The only layer that LINKS, so the only proof
# that BOTH the bare-QQ forward `cq_template_icmp_<pred>_i32(i32, i32)` AND its
# void `_unc` twin `cq_template_icmp_<pred>_i32_unc(out, a, b)` resolve and
# signature-match against the generated runtime ABI (Rule 2, Rule 16; the .ll
# fixtures assert IR text and never link). Increment A adds NO new symbol — the
# QQ compare machinery (fwd/_unc, DagTraversal two-parent recovery, WidthDispatch
# QQ resolver) already existed end-to-end; A only feeds it a width recovered from
# `HandleWidth`, so this golden re-proves the bare-QQ compare grid composes. Two
# independent Q+Q lineages in a `noinline` helper (`noinline` is LOAD-BEARING —
# whole-DAG uncompute is gated OFF in `main`): (A) a MEASURED `xi < yi`
# (icmp_slt QQ -> zext bridge -> measure) proves the forward symbol; (B) a DEAD,
# `cq_phi`-kept-alive `pi == qi` (icmp_eq QQ) proves the `_unc` twin — the spine
# reverses it ONCE (zext_unc -> icmp_eq_unc -> ry undos) and frees each rail,
# with NO added measure, NO `_inv`, NO cqrt_cswap.
add_test(NAME e2e-slice-compare-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_compare_qq.expected.log")

# Phase 7.1 Increment D (FROZEN ABI): the half-precision (f16) e2e link proof.
# The only layer that LINKS, so the only proof that the new frozen f16 symbols
# (cqrt_alloc/ry/rz/measure_f16, cq_template_fadd_f16 + its `_unc` twin) resolve
# and signature-match the hand-written core ABI and the generated template ABI
# at the `half` width. (A) a measured Q+Q fadd proves the forward symbol; (B) a
# dead Q+Q fadd kept alive by a cq_phi proves the `_unc` twin reverses once and
# frees every rail — no cqrt_copy_f16 (an f16 carrier is an angle, never data).
# i128 is deferred (its C ABI shreds __int128 to {i64,i64}); see the follow-up.
add_test(NAME e2e-slice-f16
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f16.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f16.expected.log")

# bd 3c6m.4 (FROZEN ABI): the long-double (f80 / x86_fp80) e2e link proof — the
# width behind the 54 `…l` math.h variants. The only layer that LINKS, so the
# only proof that the new frozen f80 symbols (cqrt_alloc/ry/rz/measure_f80,
# cq_template_fadd_f80 + its `_unc` twin, and the intrinsic-backed
# cq_template_sqrt_f80) resolve and signature-match the hand-written core ABI and
# the generated template ABI at the long-double width. (A) a measured sqrtl over
# a Q+Q fadd proves the forward symbols + the headline `…l` intrinsic shape; (B) a
# dead Q+Q fadd kept alive by a cq_phi proves the fadd_f80 `_unc` twin reverses
# once and frees every rail — no cqrt_copy_f80 (an f80 carrier is an angle, never
# data). On this x86-64 host `long double` == x86_fp80, so CQ.h's _Generic seeds
# the f80 suffix (__LDBL_MANT_DIG__ == 64).
add_test(NAME e2e-slice-f80
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f80.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_f80.expected.log")

# Phase 7.1 Increment E (FROZEN ABI): curated reversible llvm.* idiom intrinsics.
# The only layer that LINKS, so the only proof the SIBLING symbols
# (cq_template_<op>_<W> + their `_unc`/`_inv` twins in cq_intrinsic_templates,
# in libcq_templates.a) resolve and signature-match. bswap = Class-1 involution;
# ctpop = Class-2 non-injective whose golden proves the R-E source stays live
# through its own `_unc` (recompute-from-live-source).
add_test(NAME e2e-slice-intrinsic-bswap
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_bswap.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_bswap.expected.log")

add_test(NAME e2e-slice-intrinsic-ctpop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_ctpop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_ctpop.expected.log")

# bd ww4c Increment 0 (PRD-ww4c-ctlz-idiom.md §9): ctlz = the same Class-2 shape as
# ctpop, but it had ZERO hits across every e2e golden (measured 2026-08-21) while
# ctpop had two and bswap one — proven at the IR layer and unproven at the only
# layer that LINKS. The ww4c recognizer emits this exact call, so it is bought
# FIRST. Its third lineage also MEASURES that the `is_zero_poison` immarg is
# indistinguishable at the linked ABI (Rule 15 drops it); the immarg's real
# consequence is the PredMux cone fence, an IR-layer property no golden can
# witness, pinned by ir-pass/test/lowering_intrinsic_ctlz_i32.ll.
add_test(NAME e2e-slice-intrinsic-ctlz
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_ctlz.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_ctlz.expected.log")

# bd ww4c Increment 1: the shift-count loop -> llvm.ctlz recognizer
# (CtlzIdiomPrepass.cpp), end to end. SYNTHETIC — the two real openlibm cells are
# Increment 2. This is the only layer that LINKS, so the only proof the
# substituted four-op chain resolves and signature-matches, all four void `_unc`
# twins included, and the only place stage 2b can speak for its rails. Written in
# openlibm's `hx > 0; hx <<= 1` spelling, which clang emits NO ctlz for at any -O
# level, so a ctlz in this golden can only be CQ's.
add_test(NAME e2e-slice-ctlz-idiom-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_ctlz_idiom_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_ctlz_idiom_loop.expected.log")

# Phase 7.1 iw81.4.b (FROZEN ABI): the fp-math intrinsic family. The only layer
# that LINKS, so the only proof the new generated fp symbols resolve and
# signature-match: (A) a measured unary @llvm.floor.f64 proves the forward
# cq_template_floor_f64; (B) a dead binary @llvm.minnum.f64 kept alive by a cq_phi
# proves the binary forward cq_template_fmin_f64 AND its void `_unc` twin
# cq_template_fmin_f64_unc(out, c, d) reverse once from the still-live f64 sources
# and free every rail — no cqrt_copy_f64 (an fp carrier is an angle, never data).
add_test(NAME e2e-slice-intrinsic-fpmath
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fpmath.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fpmath.expected.log")

# Phase 7.1 wd2p: the ternary fma family (FIRST 3-operand template). Proves the
# QQQ forward (contracted a*b+c -> @llvm.fmuladd.f64) + the QLQ forward/`_unc`
# twin (a dead __builtin_fma(d,3.0,e)) all LINK and signature-match at f64.
add_test(NAME e2e-slice-intrinsic-fma
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fma.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_intrinsic_fma.expected.log")

# p119: e2e-slice-libm REMOVED — the DIRECT-libm family (cbrt/atan2/ilogb/ldexp) is
# a library-function surface, source-injected not name-recognized (Rule 18). The
# cross-width lrint/llrint survivors are still link-covered by the ir-pass
# lowering_libm_cross_width.ll fixture.

# Phase 7.1 follow-up D5 (test_C_libtooling-m0yi): a non-power-of-2 _BitInt(N)
# INTERMEDIATE round-trips with NO new ABI. clang -O1 rounds the i40 up to i64 and
# emits the i40 wraparound as a stock `and i64 ..., 0xFFFFFFFFFF` (= 2^40-1), so
# the existing cq_template_add_i64 / cq_template_and_i64_hl (+ its _unc) templates
# lower it — the proposed cq_template_mask_<W> frozen family is unnecessary. This
# link-proves the round+mask forward stream AND the and-mask void _unc twin resolve
# and signature-match through the runtime; the golden's lineage (B) (a dead mask
# uncomputed via cq_template_and_i64_hl_unc reading the live source, then freed)
# is the trace contract for the mask's whole-DAG reversal (Rules 2, 16).
add_test(NAME e2e-slice-bitint
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitint.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_bitint.expected.log")

# Phase 7.1 follow-up n0ui (Tier-1): a 128-bit INTERMEDIATE round-trips with NO
# new core ABI. slice_i128_mulhi.c squares a quantum unsigned long and observes
# the high 64 bits of the 128-bit product: clang -O1 keeps the source/sink at i64
# and emits the wide work as single clean i128 ops (zext/mul/lshr/trunc) lowered
# to the FROZEN cq_template_*_i128 producers. This LINK-proves the i128 templates
# (incl. the __int128 _hl literal param) resolve and signature-match through the
# runtime, with NO cqrt_alloc_i128/measure_i128/copy_i128 (source/sink stay i64 —
# the __int128 {i64,i64} source/sink shred is Tier-2, deferred). Rules 2, 16.
add_test(NAME e2e-slice-i128-mulhi
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_i128_mulhi.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_i128_mulhi.expected.log")

# p119: e2e-slice-byref REMOVED — by-ref math (frexp/modf/remquo) is a
# library-function family, source-injected not name-recognized (Rule 18). The
# by-ref out-param INLINER (g7ip, ByRefInline) is a distinct capability and its
# e2e-slice-byref-inline below is UNCHANGED.

# bd g7ip — by-ref out-param on a VISIBLE user function: ByRefInline inlines the
# `noinline` helper's pure store-value producer into the caller (Architecture A),
# so the read-back load lowers to a genuine quantum handle (theta -> add_hl ->
# measure). The link-proof that the inlined stream resolves + signature-matches.
add_test(NAME e2e-slice-byref-inline
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_byref_inline.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_byref_inline.expected.log")

# Phase 6 (DD-6 §7.1, test_C_libtooling-mvna.3): the ZERO-LIB smoke for the new
# multi-file harness. Drives the EXISTING single-TU theta->add->measure slice
# through run_slice_multi.sh with EMPTY LIBSRCS (the "" 7th positional), so the
# llvm-link is over just cq.ll — an identity on the runtime trace. It byte-diffs
# the SAME golden as e2e-slice-theta-add-measure, which makes it a pure harness
# check of EXACTLY the empty-LIBSRCS branch (Stage 1b never runs) and the
# single-module identity-link, plus -include CQ.h on CQSRC, templates-before-
# runtime link order, and -O1. The lib-isolation invariant (no CQ.h on libs) and
# multi-module llvm-link are NOT exercised here — e2e-slice-multi-2file (below)
# guards those. Spec pins a zero-lib path as a fixture (IMPLEMENTATION_PLAN §7.1).
add_test(NAME e2e-slice-multi-zerolib
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.c"
    ""
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_theta_add_measure.expected.log")

# Phase 6 (DD-6 §7.1, test_C_libtooling-mvna.3): the NON-EMPTY-LIBSRCS smoke —
# the permanent ctest guard for the C18 lib-isolation invariant + multi-module
# llvm-link, ahead of the specializer's tainted-arg golden (.7). slice_multi_caller.c
# (a CQ TU whose quantum core matches theta-add-measure, additionally calling a
# CLASSICAL helper) + slice_multi_lib.c (the helper, passed as the single LIBSRCS
# word). This exercises Stage 1b (per-lib clang, NO -include CQ.h) and the
# llvm-link of TWO modules. The helper is called with classical data and used
# only post-measure, so no taint escapes (specializer-independent — a pure harness
# test). slice_multi_lib.c carries a baked-in `#ifdef cq_theta / #error` tripwire:
# if the harness ever force-includes CQ.h into a lib TU, this test fails LOUDLY at
# the lib compile, not silently. lib_bias() returns 0 so the trace matches the
# theta-add-measure golden; the dedicated golden keeps the two slices decoupled.
add_test(NAME e2e-slice-multi-2file
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_multi_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_multi_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_multi.expected.log")

# Phase 6.1 (WI-1.11, test_C_libtooling-mvna.7): the call-graph-specialization
# golden — the FIRST e2e slice where taint genuinely ESCAPES into a separate-TU
# callee body and the specializer fires. specialize_caller.c (a CQ TU whose
# theta-tainted `x` is passed to `helper`) + specialize_lib.c (the pure i32
# `helper`, the single LIBSRCS word, compiled WITHOUT CQ.h). After llvm-link
# merges them, the ONE cq-lowering pass clones `helper` into the reversible
# `__cq_q_helper_1`, lowers its body to templates, Bennett-wraps it (compute ->
# cqrt_copy_i32 -> reverse-play `_unc` -> cqrt_free), and retargets the call.
# This is the ONLY layer that LINK-proves @__cq_q_helper_1 + cqrt_copy_i32 + the
# `_unc` data-template adjoints (cq_template_mul_i32_unc / add_i32_hl_unc) all
# resolve and signature-match through the multi-module pipeline; the golden's
# LIFO reverse order (mul_unc before add_unc, then both frees) is the trace
# contract for the Bennett core every later Phase-6 increment reuses. The
# borrowed quantum input `x` (h0) is preserved and left allocated (a Rule-6 safe
# leak — no caller-side uncompute fires, the lineage reaches the measure sink).
add_test(NAME e2e-slice-specialize-2file
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_caller.expected.log")

# Phase 6 / issue 5po2: a tainted `select` (in-body control) INSIDE a specialized
# clone. spec_select_caller.c routes a theta-tainted `b` through the separate-TU
# classical helper `foo` (spec_select_lib.c), whose body `int a=0; if(b<5) a+=b;
# return a` is `select(icmp slt b,5, b, 0)` at -O1. Pre-5po2 the specializer
# loud-declined (`callee contains tainted control flow under quantum lift`); now
# it lifts `foo` into __cq_q_foo_1, emits the select as a 4.4 controlled-XOR copy
# `out = flag ? b : 0`, and Bennett-wraps it. This LINK-proves the clone +
# cqrt_copy_i32_controlled + the compare `_unc` twin resolve and signature-match
# across llvm-link, and the golden's reverse (the SELF-INVERSE controlled copy
# re-applied to zero the out rail, then the compare `_unc` to unmint the flag,
# then BOTH frees AFTER the complete reverse — no dirty free, Rule 6) is the trace
# contract for a lifted in-body-control select (Rules 2, 6, 13, 16).
add_test(NAME e2e-slice-specialize-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_select_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_select_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_select_caller.expected.log")

# Phase 6 / issue 5po2 I1 (tainted control in a lifted callee — the two-arm
# integer widening beyond increment-1's `select(icmp, param, 0)`). spec_twoarm_lib.c:
# `if(b>5) a=(b<<2)^9; else a=(b+100)*3; return a` -> `clang -O1` if-converts to a
# two-DERIVED-arm `select(icmp sgt b,5, (b<<2)^9, (b+100)*3)`. Handed a tainted arg
# it lifts into __cq_q_helper_1, emitting the full 4.4 two-copy stream (copy_T ·
# ¬flag `cqrt_x` · copy_F · `cqrt_x`) over `cqrt_copy_i32_controlled` + a |0> out
# rail (flag kept LIVE), Bennett-wrapped. LINK-proves @__cq_q_helper_1 +
# cqrt_copy_i32_controlled + the derived-arm producer `_unc` twins resolve and
# signature-match across llvm-link, and the golden's palindromic reverse (both
# `cqrt_x` brackets replay, the flag + every arm producer `_unc`, then ALL frees
# after the complete reverse; the borrowed input `h0`=`b` left allocated, never
# freed dirty) is the trace contract (Rules 2, 6, 13, 16). The same generalized
# `lowerCloneSelect`/`isLiftableSelect` two-arm path also lowers a PredMux-
# flattened value diamond (ir-pass-lit spec_accept_diamond_body.ll — a real
# multi-block merge-phi diamond rarely survives `clang -O1` from C, which
# if-converts it, so the flatten path is pinned by lit, this e2e link-proves the
# shared two-arm emission).
add_test(NAME e2e-slice-specialize-twoarm-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_twoarm_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_twoarm_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_twoarm_caller.expected.log")

# Phase 6 / issue 5po2 I2 (multi-exit controlled-return in a lifted fp80 clone —
# the openlibm `expl`-family shape). spec_multiexit_lib.c `mini_expl`: two
# classical-SENTINEL early returns (`if(x>MAX) return C; if(x<MIN) return C'`)
# guarding a tainted fp80 fall-through reduction. Handed a tainted x86_fp80 arg it
# lifts into __cq_q_mini_expl_1: `normalizeReturnMerge` + the scoped PredMux flatten
# collapse the diamond to a nested select whose inner condition is the COMPOUND
# `¬(x>MAX) ∧ ¬(x<MIN)` (a `cqrt_toffoli` conjunction of two fp80 fcmp leaf flags);
# `lowerCloneSelect` mints that network FORWARD-ONLY, MATERIALIZES the sentinels
# into leaked |const⟩ `cqrt_alloc_f80` rails, and emits the `cqrt_copy_f80_controlled`
# XOR muxes; the Bennett wrap plays the SINGLE LIFO reverse (copy⁻¹, the self-inverse
# toffoli, the fcmp/fmul/fma `_unc`s) and frees every proven-|0⟩ rail. LINK-proves
# @__cq_q_mini_expl_1 + cqrt_copy_f80_controlled + cqrt_toffoli + the fp80 producer
# `_unc` twins resolve and signature-match across llvm-link (Rules 2, 6, 13, 16).
add_test(NAME e2e-slice-specialize-multiexit-fp80
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_multiexit_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_multiexit_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_multiexit_caller.expected.log")

# Phase 6 / issue kmdc (5po2 fp widening): a fabs-shape FP TWO-ARM select in a
# source-injected int->int helper (fp is internal scratch, reduced to i32 via the
# libm producer ilogb). spec_fp_select_lib.c: `double x=(double)n; double a=(x<0)?
# -x:x; return ilogb(a)` -> select(icmp slt n,0, fneg x, x). Lifts into
# __cq_q_mhelper_1 as an fp cqrt_copy_f64_controlled two-arm merge (copy_T, ¬flag
# cqrt_x bracket, copy_F, cqrt_x) + the libm producer, Bennett-wrapped. LINK-proves
# cqrt_copy_f64_controlled / cqrt_alloc_f64 / cq_template_ilogb_f64_to_i32 + all
# their reverses resolve. The golden is the PALINDROMIC trace — the two cqrt_x
# brackets appear in BOTH the forward stream AND the reverse (the SelectXBrackets
# capture; a dropped bracket would dirty-free the fp rail, Rule 6), and all five
# scratch rails free on |0>. First golden to exercise fp-select-merge + libm
# together (Rules 2, 6, 13, 16).
add_test(NAME e2e-slice-specialize-fp-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_caller.expected.log")

# bd 20xt.3 (the materialize-classical-arm widening): a CONST/CONST fp80 select in
# a source-injected int->long-double helper lifted to a reversible clone — the
# atan2l -> inner atanl |x|>=2^64 overflow arm `z = (expsign<0) ? -pi/2 : +pi/2`
# (s_atanl.c block %20; both arms ConstantFP). spec_fp_select_const_lib.c returns
# `(n<0) ? -1.5L : 2.5L` directly, so clang -O1 keeps select(icmp, fp80 const, fp80
# const). Lifts into __cq_q_mhelper_1: EACH ConstantFP arm materialized to its own
# `cqrt_alloc_f80(<const>)` |const> rail (LEAKED, Rule 6), two cqrt_copy_f80_controlled
# merge (copy_T, ¬flag cqrt_x, copy_F, cqrt_x), fp80 result copied out
# (`cqrt_copy_f80`, 3c6m.54), Bennett-wrapped. LINK-proves cqrt_alloc_f80 /
# cqrt_copy_f80_controlled / cqrt_copy_f80 / cq_template_icmp_slt_i32_hl(+_unc)
# resolve. The golden: 1 ry + 1 measure (Rule 5), the two |const> rails NEVER freed
# (Rule 6), the out + flag rails freed on |0> (0 double-frees), palindromic
# forward/reverse copies (Rules 2, 6, 13, 16). atan2l itself still declines at the
# NEXT blocker (the atanhi[id]/atanlo[id] table reads); this synthetic slice is the
# Rule-2 link proof for the const-arm clone widening in isolation.
add_test(NAME e2e-slice-specialize-fp-select-const
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_const_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_const_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_const_caller.expected.log")

# bd tkmn Inc 1 (the fcmp-condition widening): an FCMP-conditioned CONST/VALUE fp
# select in a source-injected helper lifted to a reversible clone — the openlibm
# bsdsrc/b_exp.c:171 `isfinite(x) ? HUGE : x` shape (inlined into tgamma), which
# clang -O1 if-converts to select(fcmp, const, value). Before Inc 1 the
# specialization shape gate admitted only an ICmpInst condition, and that single
# clause was the tgamma lever's first blocker.
#
# THIS SLICE EXISTS BECAUSE OF A RULE-13 COVERAGE FINDING, not to move a cell: the
# new accept path fired in ZERO e2e slices and ZERO census cells, so the only
# artifact exercising it was a lit fixture — and fixtures never LINK. e2e is the
# one layer that proves every emitted symbol resolves and signature-matches
# (Rule 2), so without this the newly reachable cq_template_fcmp_*_hl / _unc mints
# had no standing regression proving they link.
#
# LINK-proves cq_template_fcmp_une_f64_hl(+_unc), cqrt_alloc_f64,
# cqrt_copy_f64_controlled and cq_template_sitofp_i32_to_f64(+_unc) resolve. The
# golden: 1 ry + 1 measure (Rule 5), the flag minted by an FCMP stem, the two
# controlled copies ¬flag cqrt_x-bracketed, a palindromic forward/reverse, the
# compare _unc NAMING the rail freed 3 lines later (the 8txa out-first form), the
# materialized |2.5> const rail NEVER freed (Rule 6) and the four reversed rails
# freed on |0> (0 double-frees). Stage 2b runs STRICT. The helper squares its input
# first: clang -O1 folds a literal isfinite test away entirely and inverts
# `v != 0.0` back into an integer compare, so `w = v*v` is what makes the fcmp
# actually survive to the pass (see the lib TU header).
add_test(NAME e2e-slice-specialize-fp-select-fcmp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_fcmp_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_fcmp_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_fp_select_fcmp_caller.expected.log")

# Phase 7.1-E follow-up (test_C_libtooling-mvjc): a CURATED reversible llvm.* idiom
# intrinsic INSIDE a specialized clone. specialize_intrinsic_caller.c routes a
# theta-tainted `x` through the separate-TU classical helper popcount_helper
# (specialize_intrinsic_lib.c), whose body is `__builtin_popcount(a) + 1` →
# `@llvm.ctpop.i32` + add. Pre-follow-up the specializer loud-declined (the
# intrinsic read as a declaration-only nested call); now it lifts the helper into
# __cq_q_popcount_helper_1, lowers the ctpop to the frozen cq_template_ctpop_i32
# producer, and Bennett-wraps it. This LINK-proves the clone + cq_template_ctpop_i32
# + its void `_unc` twin resolve and signature-match across llvm-link, and the
# golden's LIFO reverse (add_unc before ctpop_unc, the ctpop_unc reading the
# still-live source, then both frees AFTER the complete reverse) is the trace
# contract for a Class-2 intrinsic under quantum specialization (Rules 2, 13, 16).
add_test(NAME e2e-slice-specialize-intrinsic
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_intrinsic_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_intrinsic_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_intrinsic_caller.expected.log")

# bd 20xt.4 Inc 1 — a const-global tainted-index QROM read (`kTable[id]`) INSIDE a
# Phase-6 specialized callee (the atan2l inner-atanl `atanhi[id]`/`atanlo[id]`
# spec-callee capability, in isolation: straight-line — no control, no index-select).
# The `noinline` callee `lookup` stays outlined at -O1, so a tainted-arg call is a
# clone-on-taint candidate; `scanBody` admits the gep+load SHAPE (`qromReadShapeInScope`,
# the same `matchQramAccess` structure the emitter re-proves), the clone's
# `lowerQramReads` (`cloneTaint`, `inBennettClone` — the top-level coherent-return
# fence is vacuous in a wrapped clone) lowers it to `cqrt_qram_alloc_f64` (array-handle
# birth) + `cqrt_qram_load_f64`, and the Bennett wrap CAPTURES the load: reversed via
# `cqrt_qram_load_f64_unc`, then the value rail is freed clean. Golden = the gate
# trace: exactly 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), the array handle `a1` NEVER a
# `cqrt_free` operand (a classical resource token), `h4` (the load rail) reversed
# before free, `h3` (the index) live through the `load_unc`.
add_test(NAME e2e-slice-spec-qram-read
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read.expected.log")

# bd 20xt.4 Inc 2 (blocker c): the spec-callee QROM read called UNDER QUANTUM
# CONTROL. The `noinline` callee `lookup` (its only memory access a const-global
# tainted-index read) is called inside a NESTED tainted diamond (`if(q>5){if(q>10)
# r=lookup(q)}`), so PredMux must prove the callee speculatable to flatten the
# diamond + hoist the call. Inc 2 teaches `isSpeculatableDataflow` to admit the
# QROM read (taint-blind `qromReadShapeInScope`, Rule 14) so `isSpeculatablePure
# CalleeBody` passes; the flatten hoists the call unconditional, the Phase-6 clone
# Bennett-wraps it, and the 4.4 controlled-copy merge selects the result. Golden =
# the gate trace: 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), 1 `cqrt_qram_alloc_f64`
# (the array handle, NEVER freed), the load rail reversed via `cqrt_qram_load_f64
# _unc` before free, and the flattened diamond's controlled-copy / flag-strip
# stream. The straight-line Inc-1 clone case is slice_spec_qram_read.c above.
add_test(NAME e2e-slice-spec-qram-read-under-control
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read_under_control.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qram_read_under_control.expected.log")

# bd 20xt.5.2 (the FINAL atan2l blocker: inner-atanl clone-control): a spec-clone
# with INTERNAL tainted control whose arm reads a const-global table and whose
# merged value ESCAPES to the clone's non-`main` ret with NO measure (the atanl
# `atanhi[id]`->fmuladd->ret shape). The `noinline` callee `reduce` has a tainted
# diamond `if(x>1.0){ base=kTable[id]+x } else { base=x }; return base;`. Pre-fix
# the clone's PredMux ClaimAll flatten LEFT at E4-gep because
# classifyQromReadUnderControl's coherent-escape no-cloning fence blocked the read;
# the inBennettClone bypass (threaded from ClaimAll) makes it claimable and the
# Bennett wrap reverses the whole stream (the read + index) after copying the
# return out. Golden = 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), 1
# `cqrt_qram_alloc_f64` (array handle NEVER freed), the load rail reversed via
# `cqrt_qram_load_f64_unc` before free, the fp arm-merge controlled-copy stream.
add_test(NAME e2e-slice-spec-qrom-read-arm-escape
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qrom_read_arm_escape.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_spec_qrom_read_arm_escape.expected.log")

# p119: e2e-slice-specialize-libm REMOVED — it lifted a DIRECT-libm call (ilogb)
# into a specialized clone, but direct-libm is a library-function surface
# (source-injected, not name-recognized; Rule 18). Specialization-of-a-clone-with-a-
# curated-producer is still covered by e2e-slice-specialize-intrinsic above.

# Phase 6.2 (WI-2.6, test_C_libtooling-mvna.8): signatures / cache / multiplicity.
# specialize_multiarg_caller.c routes ONE theta-tainted `x` through the separate-TU
# helper `combine` (specialize_multiarg_lib.c) at THREE sites with TWO distinct
# taint signatures + one repeat: combine(x,k) [mask 01], combine(k,x) [mask 10],
# combine(x,k) [mask 01 again, CACHE HIT]. The specializer synthesizes exactly two
# DISTINCT clones — __cq_q_combine_01 (arg0 the handle: the reused arg0 lowers the
# second op QQ) and __cq_q_combine_10 (arg1 the handle: the second op lowers HL) —
# and reuses _01 for the third site. This link-proves that BOTH distinct clones and
# the shared one resolve and signature-match through llvm-link; the golden's two
# different gate streams (QQ-mul in _01 vs HL-mul in _10) plus the _01-shaped third
# call are the trace contract for the (callee,mask) cache earning its keep (C7).
add_test(NAME e2e-slice-specialize-multiarg
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_multiarg_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_multiarg_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_multiarg_caller.expected.log")

# Phase 6.3 (WI-3.5, test_C_libtooling-mvna.9): the TRANSITIVE worklist. One
# theta-tainted `x` flows through a TWO-LEVEL classical call chain crossing THREE
# TUs — specialize_transitive_caller.c (CQ) calls `outer`
# (specialize_transitive_outer_lib.c), which calls `inner`
# (specialize_transitive_inner_lib.c). Both libs compile WITHOUT CQ.h (C18). After
# llvm-link, the ONE cq-lowering pass lifts `outer` into @__cq_q_outer_1, then
# re-scans that clone, finds the post-seed-tainted inner call, and lifts `inner`
# into @__cq_q_inner_1 + synthesizes the void uncompute twin @__cq_q_inner_1_unc.
# The outer Bennett wrap's reverse CALLS that twin to zero the entangled inner
# rail (the trace's second `cq_template_mul_i32_hl(h0,7)` + `cqrt_copy(h5,h2)`)
# BEFORE freeing it — so the borrowed quantum input h0 is restored to pristine
# (Rule 6/8), never freed dirty. This is the ONLY layer that LINK-proves the
# nested clones + the uncompute twin all resolve and signature-match across the
# three modules through llvm-link; the twin call's executed body in the trace is
# the contract that the transitive reverse is real, not a verify-clean omission.
add_test(NAME e2e-slice-specialize-transitive
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_outer_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_inner_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/specialize_transitive_caller.expected.log")

# Phase 6.5 (WI-5.7, test_C_libtooling-mvna.11): a PURE CLASSICAL call under
# QUANTUM CONTROL with CLASSICAL inputs (DD-7 / PRD §2.13) — the clone-ORTHOGONAL
# Phase-6 capability (it reuses the cleared swap-route Phase-4 path, NOT clone-on-
# taint). classical_call_under_control_caller.c (a CQ TU whose theta-tainted `q`
# gates `if (q>5) y = ext_f(7);`) + classical_call_under_control_lib.c (the pure
# i32 `ext_f`, the single LIBSRCS word, compiled WITHOUT CQ.h). After llvm-link,
# the ONE cq-lowering pass recognizes the diamond's merge phi [q (tainted),
# ext_f(7) (a direct classical call result)], HOISTS the pure call into the pred
# (inert), and route-merges its i32 result via the 4.4 controlled-XOR copy merge
# over the FLATTENED diamond: flag mint -> |0> out rail -> cqrt_alloc of the call
# result -> cqrt_copy_i32_controlled (the result, on the flag) -> cqrt_x + the
# ¬flag controlled copy of q -> icmp_inv strip -> the ONE cqrt_free (the flag).
# This is the ONLY layer that LINK-proves the hoisted classical call (ext_f, run
# classically — no trace line, its 107 result feeds cqrt_alloc_i32(107)) +
# cqrt_copy_i32_controlled all resolve and signature-match through the multi-file
# pipeline (Rule 2). NO @__cq_q_ clone (clone-orthogonal), NO cqrt_cswap, ZERO
# controlled rotations, no surviving diamond phi, EXACTLY ONE free.
# control_classical_call_arm_accept.ll is the pinned IR contract.
add_test(NAME e2e-slice-classical-call-under-control
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_caller.expected.log")

# bd yn71 (Phase 4×6, the CONTROL case): a 6.5 classical-call arm builds an UNTAINTED
# merge %out (`int y=5; if (q>5) y=ext_f(7)`) that then feeds an ONWARD TAINTED-CONTROL
# phase arm (`if (y>50) y=cq_phi(y, .25)`). The merge is data-untainted at round-1, so
# `if (y>50)` is a CLASSICAL branch then; dugh's `repropagateControlMerges` re-seeds the
# second propagation from %out, tainting `icmp sgt %out, 50`. PRE-yn71
# `declineReClassifiedControl` declined that new tainted-condition branch; yn71 RE-DETECTS
# it (`detectAndLowerOnwardControl`) and `SwapRouteEmit` emits the routed phase arm ON
# %out (flag=icmp(%out,50), cqrt_cswap route in, VERBATIM cqrt_rz(rail,.25), route back,
# rail free, icmp_inv strip, flag free; measure reads %out). The ONLY layer that
# LINK-proves the re-detected onward controlled cqrt_cswap/cqrt_rz stream over the control
# merge resolves + signature-matches (Rule 2/16). Reuses classical_call_under_control_lib.c
# for the visible pure `ext_f` (=107); the downstream `ext_f(7)`/`y>50` are unfoldable at
# the CQ-TU compile (ext_f only declared), so `if (y>50)` survives -O1 as a real diamond.
# control_classical_call_arm_accept_onward_ctl_phase.ll is the pinned IR contract.
add_test(NAME e2e-slice-control-cond-onward-ctl-phase
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/onward_ctl_phase_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/onward_ctl_phase_caller.expected.log")

# p119: e2e-slice-control-byref-frexp REMOVED — it exercised the dugh/0vvq by-ref
# UNFREEZE (an onward frexp on a control-merged %out), but by-ref math is a
# library-function family, source-injected not name-recognized (Rule 18). The
# ONWARD-CONTROL capability (yn71) on a merged %out is still covered by the other
# onward control/switch/select e2e slices; only the by-ref re-run was removed.

# bd 0vvq Increment 2 (the spec-clone RE-PLAN, the D2 core): a 6.5 classical-call
# arm builds an UNTAINTED merge %out (i32) that then feeds a Phase-6 SPECIALIZATION
# candidate qpow(q, %out). At `detectSpecializations` (pre-emit) %out is untainted,
# so the candidate is FROZEN mask 0b01; dugh's `repropagateControlMerges` re-taints
# %out in round 2 and `replanReseedSpecialization` recomputes the mask to 0b11
# BEFORE the step-14 driver clones — so @__cq_q_qpow_11 lowers `mul base,base` +
# `add sq,exp` bare-QQ (the merged register h2 read as a HANDLE, cq_template_add_i32
# NOT _hl — the D2 miscompile fix), Bennett-wrapped. The ONLY layer that LINK-proves
# the re-planned clone + its bare-QQ producers + their _unc twins resolve and
# signature-match through llvm-link (Rule 2/16). Reuses classical_call_under_control_lib.c
# for the visible pure `ext_f`. Pinned by control_classical_call_arm_accept_onward_spec_call.ll.
add_test(NAME e2e-slice-control-spec-replan
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_replan_qpow_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/spec_replan_qpow_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_replan_qpow_caller.expected.log")

# bd 9paa (round-2 spec DETECTION — the detection twin of the 0vvq re-plan): a 6.5
# classical-call arm builds an UNTAINTED merge %out (i32) that feeds a WHOLLY-NEW
# Phase-6 SPECIALIZATION candidate qsq(y) whose SOLE arg is the merge (NO round-1
# theta handle). At `detectSpecializations` (pre-emit) qsq reads NO tainted operand,
# so it never enters `plan6.Pending` and the 0vvq re-plan skips it — dugh/0vvq
# over-declined it `kMsgUnknownCallee`. dugh's `repropagateControlMerges` re-taints
# %out in round 2 and 9paa's round-2 `detectSpecializations` DETECTS qsq(%out), so
# the step-262 driver clones @__cq_q_qsq_1 with `mul v,v` lowering bare-QQ (the merged
# register h2 read as a HANDLE, cq_template_mul_i32 NOT _hl — the D2 miscompile guard),
# Bennett-wrapped. The ONLY layer that LINK-proves the round-2-DETECTED clone + its
# bare-QQ producer + its _unc twin resolve and signature-match through llvm-link (Rule
# 2/16). Reuses classical_call_under_control_lib.c for the visible pure `ext_f`. Pinned
# by control_classical_call_arm_accept_onward_spec_newcand.ll.
add_test(NAME e2e-slice-control-spec-newcand
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_newcand_qsq_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/spec_newcand_qsq_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_newcand_qsq_caller.expected.log")

# bd afmv (the CHAINED onward-control -> spec re-plan; a CRITICAL yn71-introduced silent
# miscompile discovered by the 9paa Rule-13 workflow). Two chained 6.5 classical-call arms:
# region 1 `if(q>5)` -> %out1; region 2 `if(y>50)` (cond reads %out1) is lowered by yn71's
# detectAndLowerOnwardControl in round 2 -> %out2 (a quantum rail). `gg(w,q)` is a ROUND-1
# Phase-6 Pending candidate (reads the theta handle q, mask frozen 0b10). Pre-afmv the reseed
# set was frozen BEFORE the yn71 fixpoint, so gg's stale mask was never re-widened for the
# %out2 arg and the driver cloned @__cq_q_gg_10 with cq_template_mul_i32_hl(q, %out2) reading
# the superposed rail's HANDLE-TAG as an _hl literal (q*7, verify-clean wrong unitary). The
# afmv fix computes reseed AFTER the control fixpoint so %out2 is in it; replanReseedSpecial-
# ization re-widens gg 0b10 -> 0b11 and the driver clones @__cq_q_gg_11 with a bare-QQ
# cq_template_mul_i32 over TWO quantum handles. The golden's `cq_template_mul_i32(h0, h7)`
# (q * %out2, both HANDLES) + its _unc twin is the miscompile-fix contract; the second
# measure(y) keeps region-1's merge live so clang -O1 materializes both rails. The ONLY layer
# that LINK-proves the re-widened clone resolves. Pinned by
# control_classical_call_arm_accept_onward_ctl_spec_replan.ll.
add_test(NAME e2e-slice-control-spec-chained-ctl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_chained_ctl_caller.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/classical_call_under_control_lib.c ${CMAKE_CURRENT_SOURCE_DIR}/spec_chained_ctl_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/spec_chained_ctl_caller.expected.log")

# Phase 7.6 (test_C_libtooling-9x4z.1): the reversible I/O output tape. The only
# layer that LINKS — and 7.6 adds NEW frozen hand-written core symbols, so this
# golden is the ONLY proof cqrt_tape_alloc + cqrt_tape_write_<W> resolve and
# signature-match against libcq_runtime (Rule 2/16; the .ll fixtures assert IR
# text and never link). A theta-tainted `x` is APPENDED to the output tape twice
# (printf + putchar -> ONE cqrt_tape_alloc t0, TWO cqrt_tape_write_i32 appends
# with distinct out-handles h2/h3); x is then dead + UNMEASURED. The kept output
# rails are never freed/reversed, and ZERO measurement is emitted (Rule 5).
# `noinline` is load-bearing (uncompute is gated off in `main`, and -O1 would
# inline `emit`).
#
# The source rail h1 is reverse-played but NEVER FREED (bd 261j(a), owner ruling
# 2026-08-10). This golden carried a final cqrt_free(h1) until that ruling and it
# was a hidden measurement of a rail entangled with the kept tape; the ry adjoint
# above it is unchanged and stays (the freeze suppresses frees, not reversals). See
# slice_io.c's header for the algebra and the honesty bound — the printed answer
# was never wrong, a local reset cannot change the tape's reduced state.
add_test(NAME e2e-slice-io
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io.expected.log")

# bd 261j(a) — CHAINED THETA on a DERIVED rail. The second live instance the
# ruling round found, and the one no shipped slice covered: a `cq_theta` applied to
# an already-derived value puts `cqrt_ry` on a `cq_template_*` producer's rail, not
# on a root. Before the fix this module emitted TWO defective `cqrt_free`s from six
# lines of ordinary C (EXIT=0), and stage 2b certified BOTH — via two DIFFERENT
# proof rules (T1-unc-reversal for the derived rail, A2-reduces-to-identity for its
# ancestor), which is also the correction to bd 261j(b)'s "A2-only" framing.
# Both rails are now frozen: the golden carries the full forward AND adjoint stream
# and simply ends with no cqrt_free.
# Registered here because e2e is the only layer that LINKS, and because it gives
# the shape a STRICT stage-2b run (0 free sites, no --allow-unproven).
add_test(NAME e2e-slice-io-chained-theta
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_chained_theta.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_chained_theta.expected.log")

# Phase 7.6 Increment 2 (test_C_libtooling-9x4z.2): the CONTROLLED Tier-0
# conditional output `if(q)printf` / `if(q)putchar`. The only layer that LINKS —
# and Increment 2 adds the NEW frozen hand-written symbol
# cqrt_tape_write_<W>_controlled, so this golden is the ONLY proof it resolves and
# signature-matches against libcq_runtime (Rule 2/16). `emit_sgt` is the
# un-negated polarity (gate arm = TRUE successor, write fires on the flag);
# `emit_ne` is the negated polarity (clang -O1 -> icmp eq + swapped successors, so
# the write is ¬flag-bracketed by a self-inverse cqrt_x pair, Rule 9). Each lowers
# to ONE cqrt_tape_write_i32_controlled (entry ALWAYS appended, content gated); q
# stays coherent for the user's measure; ZERO compiler-inserted measurement, ZERO
# controlled rotations / cswap (Rule 5).
add_test(NAME e2e-slice-io-controlled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_controlled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_controlled.expected.log")

# Phase 7.2 Increment 2 (test_C_libtooling-65wb.2): BOTH-ARM controlled I/O
# `if (q > 5) printf("%d", q); else putchar(q);`. clang -O1 keeps a br-diamond
# (distinct unspeculatable sinks) with two single-pred sole-sink arms converging on
# one 2-pred no-phi merge. Both polarities ride the ONE flag minted from the ONE
# compare: the TRUE arm (printf) on `flag`, the FALSE arm (putchar) ¬flag-bracketed
# by a self-inverse cqrt_x pair. Both writes append to the SAME tape (one
# cqrt_tape_alloc); tape length is deterministic (exactly 2 entries, only content
# gated). q stays coherent for the user's measure; ZERO compiler-inserted
# measurement, ZERO controlled rotations / cswap (Rule 5).
add_test(NAME e2e-slice-io-both-arm
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_both_arm.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_io_both_arm.expected.log")

# Phase 7.2 Increment 2 (test_C_libtooling-65wb.2): a MIXED value+I/O diamond —
# `if (q > 5) printf("%d", q);` plus a value select `r = (q>5)?q+1:q+2`. clang -O1
# merges both into one br-diamond with a CONSTANT data-mux φ. Both effects ride the
# ONE flag minted from the ONE compare: the I/O → one cqrt_tape_write_i32_controlled
# (TRUE arm, on flag); the value → the 4.4 controlled-XOR copy data-mux (out=|0>;
# const 1 on flag; const 2 on the cqrt_x-bracketed ¬flag) feeding `add q, out` (Q+Q)
# → measure. The constant data-mux is the safe subset (no phase to dephase, Rule 7);
# a computed two-base φ declines (= 65wb.5 exp2). ZERO compiler-inserted measurement,
# ZERO controlled rotations / cswap (Rule 5).
add_test(NAME e2e-slice-mixed-value-io
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_mixed_value_io.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_mixed_value_io.expected.log")

# Phase 7.5 Increment 1: a tainted-index READ of a const-global table (QROM-shaped).
# `tbl[q]` lowers to cqrt_qram_alloc_i32 (array-handle birth) + cqrt_qram_load_i32
# (Toffoli-copy-out); no getelementptr/load survives and NO measurement is inserted
# that the user did not write (Rule 5). The array handle prints `a<N>`.
add_test(NAME e2e-slice-qram-read
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_read.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_read.expected.log")

# Phase 7.5 Increment 2: an alloca-backed tainted-index STORE + LOAD (Shadow-shaped).
# `arr[q]=7; v=arr[p]` lowers to cqrt_qram_alloc_i32 + cqrt_qram_store_i32 (void
# in-place on the array handle) + cqrt_qram_load_i32; the classical store value is
# materialized into a basis-state handle so the (arr,idx,val) trace stays
# all-handles, and NO measurement is inserted that the user did not write (Rule 5).
add_test(NAME e2e-slice-qram-store
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store.expected.log")

# bd 38t2: the fp-as-bitpattern memory cell. `arr[q] = x` where `x = cq_theta(...)` is
# an fp superposition CARRIER and `q` a tainted index, then `v = arr[p]`; lowers to
# cqrt_qram_alloc_f64 + cqrt_qram_store_f64 (of the carrier) + cqrt_qram_load_f64 +
# cqrt_measure_f64. Storing a coherent fp carrier is faithful reversible QRAM (bd
# [38t2-fp-cell-commits-to-basis-sound]); the width only tags the symbol (all i32
# handles). main-resident, so no reversal is emitted.
add_test(NAME e2e-slice-qram-store-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_store_fp.expected.log")

# Phase 7.5 bug sxuk: a LOCAL alloca array built+loaded in a NON-main helper whose
# loaded value is measured INSIDE the helper. Unlike slice_qram_store (main-resident,
# no reversal), the local scratch MUST uncompute: the loaded value is copied out to a
# kept carrier (cqrt_alloc_i32(0) + cqrt_copy_i32) which is measured, then the
# load+store chain reverses (cqrt_qram_load_i32_unc + cqrt_qram_store_i32_unc) and the
# index rails REVERSE-PLAY BUT ARE NOT FREED; the array handle is left clean |0>
# (never freed). Without the fix the stores leak, entangling the measured value with
# dirty scratch.
#
# The index rails used to be freed here, justified by MEASUREMENT IMMUNITY. bd 5pio
# (owner ruling 2026-08-11) made a `cqrt_copy_<W>` destination a kept carrier for the
# 261j record freeze, so the copy source's ANCESTORS — these `cq_theta` index roots,
# whose gate is `cqrt_ry_` and so not a basis permutation — are frozen: fully
# reverse-played, then LEFT ALLOCATED (Rule 6's fallback). The golden was regenerated
# for exactly those lines. What this test still proves is the STORE REVERSAL, which is
# the genuine sxuk fix; the index frees were never what it was pinning.
add_test(NAME e2e-slice-qram-local-uncompute
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute.expected.log")

# bd 38t2 (Rule-13 clearance link-proof): the FP twin of slice-qram-local-uncompute.
# The only layer that LINKS: proves the fp reversal family — the UNCONTROLLED
# cqrt_copy_f64 copy-out (frozen-designate, its live consumer) + cqrt_qram_load_f64_unc
# + cqrt_qram_store_f64_unc — resolves, signature-matches, and traces in faithful
# Bennett LIFO order (store_unc BEFORE the index rails' Ry†) through a real link.
# Byte-parallel to the integer golden with width-tagged symbols. The index rails are
# reverse-played but NOT freed since bd 5pio — see the integer twin above.
add_test(NAME e2e-slice-qram-local-uncompute-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_local_uncompute_fp.expected.log")

# iw81.7: a tainted-index Shadow STORE UNDER tainted control — the guarded store.
# The GUARDED symbol cqrt_qram_store_i32_controlled reverses via _controlled_unc with
# the flag live, THEN the flag strips (pred-lifetime invariant); the array is never
# freed. Exercises the reversal path (non-main helper).
add_test(NAME e2e-slice-qram-guarded-store
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store.expected.log")

# g5gi: guarded store on a SWAPPED (FALSE-successor) branch — `if (q != 3) {...}`
# canonicalizes to `icmp eq; br eq, merge, arm`, so the store fires on `¬(q==3)`.
# g5gi mints the flag with the INVERSE predicate (icmp eq -> icmp ne) — a NEGATED
# MINT, NOT a cqrt_x bracket — so the whole-DAG uncompute reverses it via the same
# `_unc` (cq_template_icmp_ne_i32_hl_unc). The only layer that LINKS: re-proves the
# guarded-store symbol set resolves + signature-matches with the negated flag.
add_test(NAME e2e-slice-qram-guarded-store-swapped
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_swapped.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_swapped.expected.log")

# g5gi: TWO separate guarded-store diamonds sharing a block —
# `if(q<3){arr[i]=7;} if(q<5){arr[j]=8;}`. The first diamond's merge is the second's
# Pred. g5gi exempts a GuardedStoreArm's MergeBB from the cross-region pre-flight
# doomed set (the guarded flatten erases only the Arm, never the merge), so both
# diamonds lower. The whole-DAG uncompute reverses both stores + both flag strips in
# strict reverse program order (store2 before store1); the shared array is never
# freed. The only layer that LINKS: the guarded-store set composes across two
# sequential guarded diamonds.
add_test(NAME e2e-slice-qram-guarded-store-multi
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_multi.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_multi.expected.log")

# bd 38t2 (Rule-13 clearance link-proof): the FP twin of slice-qram-guarded-store.
# The only layer that LINKS: proves the GUARDED fp store family —
# cqrt_qram_store_f64_controlled + _controlled_unc (flag STILL LIVE at the reverse,
# THEN the flag strip: the store-reverse-BEFORE-strip pred-lifetime invariant) plus
# the cqrt_copy_f64 copy-out — resolves, signature-matches, and byte-diffs through a
# real link. Byte-parallel to the integer guarded golden with width-tagged symbols.
add_test(NAME e2e-slice-qram-guarded-store-fp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_fp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_qram_guarded_store_fp.expected.log")

# Phase 7.3 Increment 1 (test_C_libtooling-799w.1): the rolled-in-place Case A
# phase accumulator. A classically-bounded loop over an in-place persistent rail
# `for (i<n) q = cq_phi(q, 0.1)` lowers ROLLED — the loop CFG is preserved, the
# body emits `cqrt_rz_f64` in place over the loop-invariant handle, the
# loop-carried header phi AND the zero-trip/exit merge phi collapse to the single
# rail. The bound is a RUNTIME param (the A2 shape: zero-trip guard + exit phi)
# passed a fixed 3 so the trace is deterministic; the golden (alloc + ry + 3×rz +
# measure) is BYTE-IDENTICAL to the manually-unrolled 3-iteration form — the PRD
# §4 done-criterion. ZERO measurements inserted, ZERO in-body frees (the rail is
# measured after L); the classical induction + loop CFG survive. 7.3 adds no new
# runtime ABI — this re-proves the existing alloc/ry/rz/measure symbols compose
# over a rolled loop.
add_test(NAME e2e-slice-loop-phase-accum
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum.expected.log")

# 3qlq Inc 1, finding F-B2-3 (prep-b2): the HAND-UNROLLED twin of the phase
# accumulator above, and the `cmp` gate over the two committed goldens. The rolled
# slice's header has claimed byte-identity with a manual unroll since Phase 7.3
# Inc 1 and there was no twin in the tree to check it against; there is now.
# `cmp` only — no clang, no opt, no plugin, milliseconds.
add_test(NAME e2e-slice-loop-phase-accum-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum_unrolled.expected.log")

add_test(NAME e2e-loop-phase-accum-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_phase_accum_unrolled.expected.log")

# Issue dtzb (the in-place reversible arithmetic strategy): the VALUE twin of the
# phase accumulator above. A classically-bounded loop over an in-place-mutated
# value rail `q = q ^ 9` lowers ROLLED — `cqrt_xorc_i32(h0, 9)` rolled in place,
# the loop-carried + zero-trip/exit rail phis collapse to the one handle, ZERO
# out-of-place templates, ZERO uncompute/frees. The golden (running the rolled
# loop a FIXED 4 times) is byte-identical to the manually-unrolled 4×cqrt_xorc.
add_test(NAME e2e-slice-loop-value-accum
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_value_accum.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_value_accum.expected.log")

# Phase 7.4 Increment 2 (test_C_libtooling-y05j.2): a classically-bounded,
# data-mutating loop with a SINGLE tainted value-arm `break`, measured after.
# Lowers ROLLED: the rail collapses to one in-place handle, the terminator is
# stripped to the classical bound (full trip count), and the break is realized by
# an index-gated copy-not-move capture + whole-loop reverse-play (forward body ×4,
# capture, copy-out, backward body ×4, balanced R/idx frees, ZERO measurements).
#
# THE FIVE `loop-break` SLICES ARE THE ONLY e2e ENTRIES THAT PASS
# `--allow-unproven` TO run_slice.sh's stage-2b free-pairing check (bd 8txa).
# The reason is structural, not a defect, and is the same in all five: the dtzb
# break spine discharges its rails by a WHOLE-LOOP argument that a straight-line
# structural checker cannot reconstruct. Two shapes, 4 sites per slice:
#   * `%cq.brk.fire` — a Bennett RECOMPUTE-and-cancel ancilla. The forward sets
#     `fire = cond AND [idx==0]` with a toffoli; the uncompute zeroes it with a
#     cnot off a DIFFERENT predicate (`[idx'==0]`) that is provably equal to
#     `fire` only after reasoning about the intervening index arithmetic. It is
#     correct and it is not an adjoint palindrome.
#   * `%cq.brk.R` / `%cq.brk.idx` — allocated before the loop, written inside
#     the body and again in the reverse-play block, freed in the tail; the write
#     history crosses the back-edge, so it is not linearly ordered in any one
#     stream (`U1-cross-stream`).
# Both are the province of the basis-state evaluator that is the OTHER, deferred
# half of bd 8txa. Every VIOLATION-class check still runs on these slices — only
# the UNPROVEN sites are downgraded — and every other e2e slice runs strict. Do
# NOT copy this flag onto a new entry without a written reason of this kind.
add_test(NAME e2e-slice-loop-break
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break.expected.log"
    "--allow-unproven")   # dtzb whole-loop reverse-play; see the note above

# Phase 7.4 coverage lock (test_C_libtooling-x1t1): the Q==Q value-arm break —
# the break condition compares the rail against a SECOND loop-invariant QUBIT
# (`if (q == p) break;`) rather than a CONSTANT (the e2e-slice-loop-break case).
# The only layer that LINKS the bare-QQ `cq_template_icmp_eq_i32(h_rail, h_p)`
# forward + its void `cq_template_icmp_eq_i32_unc(out, h_rail, h_p)` adjoint for
# the BREAK reverse-play path (a DISTINCT code path from the `_hl` form every
# other break slice exercises; slice_compare_qq.c links the QQ grid only for the
# straight-line/uncompute path). The reverse-play clone reads the SAME invariant
# `p` handle, so `fire'` matches `fire` on every branch; `p` is never mutated and
# never freed (left allocated-clean, Rule 6 — the golden shows NO cqrt_free(h0)).
# No new frozen runtime ABI (reuses the bare-QQ compare grid + the break spine).
add_test(NAME e2e-slice-loop-break-qq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq.expected.log"
    "--allow-unproven")   # dtzb whole-loop reverse-play; see e2e-slice-loop-break

# REMOVED 2026-09-05 (3qlq Inc 1, OQ-5 / prep-b2): `e2e-slice-loop-break-qq-phase`
# and `slice_loop_break_qq_phase.{c,expected.log}`. The slice existed to exercise a
# loop-invariant comparand `p` carrying a RELATIVE PHASE (`p = cq_phi(p0, 0.3)`).
# Under owner decision D1 `cq_phi` takes no register, so `p` IS `p0` and the source
# becomes the same program as `slice_loop_break_qq.c` — MEASURED: the two stage-1
# modules differ ONLY by the uncontrolled `call void @cq_phi(double 0.3)` and its
# `declare`, which D2 deletes, so the LOWERED IR is identical. Keeping it would be
# a second copy of `e2e-slice-loop-break-qq` wearing a claim it no longer tests.
# The B3 phase fence it sat beside is unchanged and is pinned in lit.

# Phase 7.4 coverage lock (test_C_libtooling-1784): a Q==Q value-arm break whose
# comparand is a DERIVED (non-mint) loop-invariant tainted value — `p = p0 + 5`
# (producer chain p0 -> p, the deriving cq_template_add_i32_hl strictly PRE-LOOP).
# Same Rule-13 clearance: the construct is permutation-only, so the p0 -> p chain (and
# p0's Ry superposition) rides inert. Both p AND p0 are consumed only as QQ-compare
# operands (+matched _unc), never rotated / copied into out / measured / freed;
# isTerminalHandle is false for both and the spine never enqueues them — the deriving
# add is NEVER reversed and NEITHER is freed dirty. The golden shows
# cq_template_add_i32_hl(h0, 5) with NO _unc and NO cqrt_free(h0)/(h1) (two entangled
# rails left allocated, the Rule-6 safe leak). The symmetric-XOR fold `p = p0 ^ 3`
# with an xor rail is a DIFFERENT shape (E8 kMsgBreakUnemittable decline). No new ABI.
add_test(NAME e2e-slice-loop-break-qq-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_derived.expected.log"
    "--allow-unproven")   # dtzb whole-loop reverse-play; see e2e-slice-loop-break

# Phase 7.4 coverage smoke (test_C_libtooling-rxx8): the i64-RAIL Q==Q value-arm
# break. The only layer that LINKS the i64 break-path capture symbols (cqrt_alloc_i64,
# cqrt_copy_i64[_controlled], cqrt_xorc_i64, cq_template_icmp_eq_i64 + its _unc) — a
# missing one fails LOUDLY at LINK, invisible to the .ll fixtures. Also exercises the
# MIXED-width capture (i64 rail + i32 idx counter). `p` is loop-invariant and never
# freed (left allocated-clean, Rule 6). No new frozen runtime ABI.
add_test(NAME e2e-slice-loop-break-qq-i64
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_i64.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_break_qq_i64.expected.log"
    "--allow-unproven")   # dtzb whole-loop reverse-play; see e2e-slice-loop-break

# Phase 7.3 Increment 2 (test_C_libtooling-799w.2): the per-iteration in-body
# uncompute Case B. Each iteration mints a FRESH rail, derives an iteration-local
# temp (xor_hl), keeps it alive with a dead cq_phi, and drops both. The Phase-5
# spine lifts its two backedge guards for the proven iteration-local DAG and
# places the whole-DAG reversal (rz⁻¹ -> xor `_unc` reading the live mint -> free
# t-rail -> ry⁻¹ -> free q-rail) IN-BODY, once per iteration. The golden (n=3)
# shows THREE balanced compute/uncompute pairs over distinct handle pairs (h0/h1,
# h2/h3, h4/h5) with SIX frees — the per-iteration handle progression proves the
# free runs once per trip, never a function-scope free over a K-times-reallocated
# rail (use-after-free + double-free, the Rule-13 hazard). `noinline` is
# load-bearing (uncompute gated off in main). No new frozen runtime ABI (reuses
# the `_unc` spine).
add_test(NAME e2e-slice-loop-iter-local
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_iter_local.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_iter_local.expected.log")

# NOTE: the Phase-4 controlled-form e2e slices (control-gate / control-merge /
# control-mux-mixed / control-mux-handles) were removed with the old
# controlled-op lowering on the `swap-route-control` branch. The RSSA swap-route
# control emitter re-adds e2e coverage for tainted control flow when it lands.

# Convenience target: build the prerequisites, then run every e2e slice.
add_custom_target(check-e2e
  COMMAND ${CMAKE_CTEST_COMMAND} -R "^e2e-" --output-on-failure
  DEPENDS CQPass cq_runtime cq_templates
  USES_TERMINAL
  COMMENT "Running e2e vertical slices")

# 3c6m.12 (Phase-4.4 L4 widening): compound (`||`/`&&`) conditions on tainted-
# data selects. The fp `||` half exercises the NEW conjunction network — per-
# leaf fcmp flag mints, a cqrt_alloc_i1 ancilla, the input-preserving OR
# (cnot,cnot,toffoli), root-controlled f64 copies, the exact-LIFO inverse
# network + strips (every free provably |0>). The int `&&` half documents the
# -O1 RANGE-FUSE (clang folds `n>5 && n<100` to `add -6; icmp ult 94` — a
# single compare, the pre-existing single-flag path). Links cqrt_cnot /
# cqrt_toffoli / cqrt_alloc_i1 against libcq_runtime — no new frozen ABI (all
# three are hand-written core symbols).
add_test(NAME e2e-slice-control-select-compound
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_compound.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_compound.expected.log")

# bd 3c6m.56 — the long-double round-family KEEP path (Bennett-gated). With
# builtins on, `clang -O1` folds `rintl`/`nearbyintl`/`truncl` to the in-grid IR
# intrinsics `@llvm.{rint,nearbyint,trunc}.f80`, which cq-lowering recognizes
# (IntrinsicLowering.cpp) and lowers to `cq_template_{rint,nearbyint,trunc}_f80` —
# NO openlibm body injected (the asm-level `callq _<fn>l` is intercepted as the
# intrinsic BEFORE codegen: the floor.f80 precedent). These are legitimate keeps
# because Bennett.jl ships the reversible gate sequence — `soft_round`
# (round-to-nearest-even = rint/nearbyint under the default FP env) and
# `soft_trunc` (`src/softfloat/fround.jl`) — so a real Phase-9 backend has a
# Bennett source. Contrast `fmod`→`frem`: an in-grid OPCODE but with NO Bennett
# frem/fmod primitive, so it is NOT a keep and is deliberately absent here (bd
# fmod-frem-keep-2026-07-24 + the frem-inversion follow-up). Each golden is the
# Rule-2 e2e proof (link + run + deterministic trace) promoting the census cell
# from COMPILES-by-recognition to VERIFIED; the census (probe.py keep-set) already
# skips these bases, so the ld80 scoreboard is unchanged.
add_test(NAME e2e-slice-libm-keep-rintl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_rintl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_rintl.expected.log")

add_test(NAME e2e-slice-libm-keep-nearbyintl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_nearbyintl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_nearbyintl.expected.log")

add_test(NAME e2e-slice-libm-keep-truncl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_truncl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_keep_truncl.expected.log")

# ---------------------------------------------------------------------------
# bd 3c6m.58 — the VERIFY-FIRST sweep: real-openlibm e2e goldens for the 15
# cells that were injection-covered (census full_census_O1.json) but had NO
# committed golden. Each promotes its cell from COMPILES (an UPPER BOUND, measured
# under the census's own default<O1> cleanup) to VERIFIED at the true
# `clang -O1 -> cq-lowering -> link -> run` ship floor (Rule 2, Rule 18 source
# injection). All 15 held; verified 53 -> 68, closing the gap to injection-covered.
# Bodies are vendored from the openlibm corpus @82e90ae per bd
# libm-real-slice-recipe (mechanical edits ONLY — no constant, branch or
# expression changed); each was cleared by an independent adversarial
# faithfulness + trace-soundness audit.
# ---------------------------------------------------------------------------


# fdim.f64 — f64 sibling of the verified fdiml.f80: union IEEEd2bits is SROA-promoted
# by clang -O1 to `bitcast double to i64`, so the isnan OR-of-negations lands on the plain
# integer-extraction surface and both merges are controlled-XOR copies.
add_test(NAME e2e-slice-libm-real-fdim
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdim.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdim.expected.log")


# fdimf.f32 — f32 sibling; __isnanf's SINGLE 23-bit mantissa test (not the manl/manh pair).
add_test(NAME e2e-slice-libm-real-fdimf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdimf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_fdimf.expected.log")


# frexp.f64 — BY-REF cell. NOTE the census probe declares the out-param but never READS it, so
# clang -O1 DCEs every *eptr store before cq-lowering runs: this golden verifies the MANTISSA
# half only (zero store/Shadow/QRAM activity). Measured separately: a live-out-param variant
# also compiles clean, so the dead store is a probe-convention artifact, not a capability gap.
add_test(NAME e2e-slice-libm-real-frexp
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexp.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexp.expected.log")


# frexpf.f32 — f32 by-ref sibling; same dead-out-param scope caveat as frexp.f64.
add_test(NAME e2e-slice-libm-real-frexpf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpf.expected.log")


# frexpl.f80 — ld80 by-ref: union IEEEl2bits read AND write-back (u.bits.exp = 0x3ffe field insert)
# under a 3-way switch on the tainted exponent -- the promoteFp80Union RMW (3c6m.51).
add_test(NAME e2e-slice-libm-real-frexpl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_frexpl.expected.log")


# modfl.f80 — ld80 sibling of the verified modf.f64/modff.f32: openbsd GET/SET_LDOUBLE_WORDS RMW
# across a 3-band exponent dispatch. Same dead-out-param scope caveat.
add_test(NAME e2e-slice-libm-real-modfl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modfl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_modfl.expected.log")


# lroundl.f80 — ld80 sibling of the verified lround.f64. The INRANGE macro is vendored VERBATIM and
# clang DEMONSTRATES the compile-time-TRUE fold (LONG_MAX + 0.5 is computed in DOUBLE by the
# usual arithmetic conversions and rounds to 2^63, so dtype_max - LONG_MAX == 1.0 != 0.5):
# feraiseexcept is absent from the lowered IR, exactly as in the census bitcode.
add_test(NAME e2e-slice-libm-real-lroundl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lroundl.expected.log")


# llroundl.f80 — long long instantiation of the same s_lround.c template; trace is byte-identical to
# lroundl (long and long long are both i64 on LP64, so the fptosi is the same).
add_test(NAME e2e-slice-libm-real-llroundl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_llroundl.expected.log")


# nextafter.f64 — VOLATILE-LOCAL cell: `volatile double t; t = x*x;` is fdlibm's underflow-flag-raise
# idiom -- the bd zco4 Inc 1 promoteVolatileScalarLocals shape. Plus the hi/lo
# borrow-propagating +-1 ulp walk.
add_test(NAME e2e-slice-libm-real-nextafter
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafter.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafter.expected.log")


# nextafterf.f32 — f32 sibling: single-word ulp walk, same volatile underflow-raise idiom.
add_test(NAME e2e-slice-libm-real-nextafterf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterf.expected.log")


# ---------------------------------------------------------------------------
# bd 3c6m.67 — THE FOUR XOR-CONDITION CELLS, on the bodies openlibm ACTUALLY
# BUILDS. Read these together with the `slice_libm_ld80_*` block immediately
# below: those vendor the SAME four functions from openlibm's excluded `ld80/`
# directory and must never count, while THESE four are the coverage claim.
#
# All four declined on ONE construct — the ulp-direction test
# `if((x>0.0) ^ (x<y))` at src/s_nextafterl.c:55 / s_nexttoward.c:54 /
# s_nexttowardf.c:45 — an `xor i1` of two tainted compares in branch-condition
# position, which neither condition-tree recogniser admitted. The `ld80/` bodies
# use an integer word ladder instead, which is why they always lowered and why
# the src/ld80 corpus collision hid the gap for the whole campaign. Admitting the
# xor node (bd 3c6m.67) clears all four; measured payoff +4 injection cells.
# ---------------------------------------------------------------------------

# nextafterl.f80 — the fp80 `union IEEEl2bits` ulp walk under the xor-condition
# region, plus the explicit-integer-bit (LDBL_NBIT) mantissa fixups.
add_test(NAME e2e-slice-libm-real-nextafterl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nextafterl.expected.log")


# nexttowardl.f80 — IS nextafterl: `openlibm_strong_reference(nextafterl,
# nexttowardl)` at src/s_nextafterl.c:80, one body under two declared names. The
# golden is byte-identical to nextafterl's by construction (verified, not
# assumed); the cell is separate because `math.h` declares the spelling.
add_test(NAME e2e-slice-libm-real-nexttowardl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttowardl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttowardl.expected.log")


# nexttoward.f64 — the MIXED-WIDTH cell: f64 argument read through the
# EXTRACT_WORDS memcpy idiom, f80 argument through `union IEEEl2bits`, so one
# body exercises both word-access conventions. Its xor mixes an icmp leaf (on the
# extracted word) with an fcmp leaf — the node operates on i1 flag rails, so the
# leaf kinds are irrelevant to it.
add_test(NAME e2e-slice-libm-real-nexttoward
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttoward.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttoward.expected.log")


# nexttowardf.f32 — the cell that declined FLAT rather than nested, purely
# because its xor diamond is the OUTERMOST region (PredMux never invoked, 0
# leaves). Same construct as its three siblings; the different bucket was an
# artifact of position. NB this is ALSO the cell whose bd k710 `+1` was retracted:
# the write-only `volatile` fenv idiom lives in the ld80 body, and the shipped
# body below READS its scalar. It re-earns the cell on the xor, not on fenv.
add_test(NAME e2e-slice-libm-real-nexttowardf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttowardf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_nexttowardf.expected.log")


# ===========================================================================
# THE `slice_libm_ld80_*` FAMILY — REAL openlibm source, but NOT a coverage claim
# ===========================================================================
# bd `test_C_libtooling-3c6m.63` (2026-08-23). These three slices vendor openlibm's
# `ld80/` variant of a function, and openlibm's own build EXCLUDES all three on
# every target: `ld80/Make.files:8-9` comments `s_nextafterl.c` out and never
# mentions `s_nexttoward.c` / `s_nexttowardf.c`, while `CMakeLists.txt:174/297/309`
# name `src/` for each. On the body that DOES ship, all three census cells DECLINE
# (`nextafterl.f80` / `nexttoward.f64` at `src/s_nextafterl.c:42:29` and
# `src/s_nexttoward.c:44:22`, nested control; `nexttowardf.f32` at
# `src/s_nexttowardf.c:45:5`, flat control).
#
# WHY THEY ARE STILL HERE. They are real BSD-licensed openlibm C, they lower, link,
# run and byte-match, and each proves something nothing else in the suite does (see
# per-slice notes). What they must NOT do is COUNT: `probe.py`'s
# `_full_surface_scoreboard()` computes the published `verified` number as the glob
# count of `slice_libm_real_*.expected.log`, so leaving them under that prefix would
# publish `97 injection-covered, 100 verified` — verified > covered, which probe.py's
# own docstring names as an incoherent result. Renaming is what separates "CQ can
# lower this body" (true, and worth a regression test) from "a user's `nextafterl()`
# call is covered" (false).
#
# `tools/slice_census_sync_check.py` (ctest `e2e-census-slice-sync`) enforces the
# split mechanically, because the ticket recorded this desync as a trap that turns
# NO test red.
# ===========================================================================

# nextafterl (ld80 variant) — the hardest of the family: a THREE-word (esx/hx/lx) borrow-carry chain
# with the explicit-integer-bit `(hx +- 1) | (hx & 0x80000000)` fixups, and block-scoped volatile
# locals. NOT the shipped body (see the block above); census cell nextafterl.f80 declines.
add_test(NAME e2e-slice-libm-ld80-nextafterl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_ld80_nextafterl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_ld80_nextafterl.expected.log")


# nexttoward (ld80 variant) — the only MIXED-WIDTH body in the suite (C11 7.12.11 fixes arg 2 at long
# double): drives BOTH the f64 memcpy word shim and the ld80 union in one function, plus the
# hand-aligned f64->fp80 field comparison ladder. It is also the ONLY slice whose lowered module
# contains a real LLVM `undef` (clang -O1's own select on the x==y/NaN early exit) — the
# golden-fragility witness documented in its header. NOT the shipped body; nexttoward.f64 declines.
add_test(NAME e2e-slice-libm-ld80-nexttoward
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_ld80_nexttoward.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_ld80_nexttoward.expected.log")

# nexttowardf (ld80 variant) — bd k710, and the ONLY e2e LINK-LAYER PROOF for the fenv ruling (owner
# 2026-08-10) and the `eraseDeadVolatileScalarStores` stage it licensed. Structurally unique: its
# final underflow raise is a WRITE-ONLY `volatile float u = x*x;` (ld80/s_nexttowardf.c:63), where
# every compiling sibling READS its volatile scalar and is claimed by the zco4 promotion instead.
# Before the ruling this body died on `cq taint escape: tainted value stored to memory`.
#
# THE GOLDEN'S JOB — and the previous wording here was WRONG, contradicting both this slice's own
# header and CLAUDE.md: the trace contains ZERO `cq_template_fmul_f32`. Once the unobservable store
# is gone the multiply is trivially dead and PredMuxFlatten's
# `RecursivelyDeleteTriviallyDeadInstructions` takes it. That is sound and is what the owner
# re-affirmed the ruling on (CLAUDE.md, "fenv is OUT"); the comfortable "we only delete the store"
# reading is true of the STAGE and false of the PIPELINE. What the golden pins is the whole gate
# stream under that reading — if a later change resurrects the multiply, or drops something else,
# this trace moves and that is the alarm.
#
# *** ITS CENSUS CREDIT IS RETRACTED (bd 3c6m.63). *** k710's +1 (97->98) was measured on THIS body;
# the shipped `src/s_nexttowardf.c` reads its volatile scalar `t`, so the fenv path is never reached
# there and the cell declines earlier, on control. The RULING and the STAGE are unaffected and keep
# their own lit coverage (`ir-pass/test/lowering_volatile_scalar_deadstore.ll`); only the coverage
# credit is withdrawn. This slice is now the stage's e2e witness WITHOUT being a coverage claim,
# which is exactly why it was renamed rather than deleted.
add_test(NAME e2e-slice-libm-ld80-nexttowardf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_ld80_nexttowardf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_ld80_nexttowardf.expected.log")


# expm1l.f80 — ld80 exp kernel in Cephes rational form: Cody-Waite reduction via @llvm.floor.f80,
# a P4/Q4 rational core, and 2^k reassembly through ldexpl==scalbnl -- one of the cells bd
# vuy6's module-asm .set alias resolution unmasked.
add_test(NAME e2e-slice-libm-real-expm1l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expm1l.expected.log")


# tanhl.f80 — four-band |x| dispatch over the inner expm1l; fp80 selects ride the kjd1
# cqrt_copy_f80_controlled family.
add_test(NAME e2e-slice-libm-real-tanhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_tanhl.expected.log")


# sinhl.f80 — four-band dispatch over BOTH inner kernels (expm1l and expl). Census status is
# `exit0-spec:['expl']` (expl stays outlined as a Phase-6 spec clone under the census harness);
# at the plain -O1 ship floor the recipe's force-inline convention collapses the closure to one
# straight-line body instead. Both routes reach opt exit 0; this golden pins the ship-floor one.
add_test(NAME e2e-slice-libm-real-sinhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_sinhl.expected.log")

# --- bd 3c6m.60: the 11 cells unblocked by the census hardware-keep-set harness fix.
# Each vendors the REAL openlibm body and spells its inner keep-set calls `__builtin_<keep>` —
# the SAME `@llvm.<fn>.f<W>` construct plain `clang -O1` emits for the named call at the ship
# floor (Rule 18), which is exactly what the corpus's blanket `-fno-builtin` used to defeat.
# hypotl.f80 WAS deliberately absent (parked at slice_libm_real_hypotl.c.DECLINED) as the one
# census-pipeline-only cell: census-COMPILES, ship-floor-DECLINES. bd 3c6m.61 closed it and it is
# wired below with the other ld80 cells. The blocker was NOT the control shape the park header
# blamed — PredMux's root region passed E1/E2/E3 on the 5-way funnel all along; the single
# E4-dataflow leave was the arm-resident `icmp eq i80` of the Inf/NaN mantissa test. See the
# slice header for the full diagnosis.

# acos.f64 — the classification cascade over the tainted exponent word (|x|>=1 / |x|<0.5 /
# x<-0.5 / x>0.5) flattened through PredMux; the pS/qS Horner polynomials; the `pio2_lo`
# volatile-scalar fold. Inner `sqrt` is a Rule-18 hardware KEEP -> cq_template_sqrt_f64.
add_test(NAME e2e-slice-libm-real-acos
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acos.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acos.expected.log")

# acosf.f32 — f32 sibling of acos: same cascade over GET_FLOAT_WORD, sqrtf -> cq_template_sqrt_f32.
add_test(NAME e2e-slice-libm-real-acosf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosf.expected.log")

# acosl.f80 — ld80 sibling: the invtrig P/Q Horner tables + union IEEEl2bits mantissa mask as an
# i80 register RMW (no Shadow/QRAM), sqrtl -> cq_template_sqrt_f80.
add_test(NAME e2e-slice-libm-real-acosl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosl.expected.log")

# asin.f64 — the |x|>=1 / |x|<0.5 / else cascade with the SET_LOW_WORD half-precision split;
# fabs + sqrt are keeps.
add_test(NAME e2e-slice-libm-real-asin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asin.expected.log")

# asinf.f32 — f32 sibling of asin.
add_test(NAME e2e-slice-libm-real-asinf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinf.expected.log")

# asinl.f80 — ld80 sibling of asin over the invtrig tables.
add_test(NAME e2e-slice-libm-real-asinl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinl.expected.log")

# hypot.f64 — the widest of the acos/asin family (1098 trace lines, 145 allocs): the exponent-difference
# ladder, the two SET_HIGH_WORD rescalings, and the sqrt correction step.
add_test(NAME e2e-slice-libm-real-hypot
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypot.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypot.expected.log")

# pow.f64 — NB the census cell convention pins arg1 to the classical literal 0.5, which is pow's
# `y == 0.5` fast path -- clang -O1 proves the log/exp core UNREACHABLE, so this golden verifies
# pow's tainted classification prologue + the sqrt route, NOT its numeric core (bd 3c6m.62).
add_test(NAME e2e-slice-libm-real-pow
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_pow.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_pow.expected.log")

# powf.f32 — same arg1=0.5f fast-path caveat as pow.f64 (bd 3c6m.62); verifies the classification
# prologue, the nan_mix f80 leg, and the sqrtf/fabsf keep routes.
add_test(NAME e2e-slice-libm-real-powf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_powf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_powf.expected.log")

# lgamma.f64 — the largest slice in the suite (14003 trace lines): e_lgamma_r's band ladder + the
# sin_pi reflection over the real __kernel_sin/__kernel_cos and the real e_log body; floor/fabs are
# keeps. Census bucket is COMPILES (spec-clone); this golden pins the plain -O1 force-inlined route
# (sinhl precedent).
add_test(NAME e2e-slice-libm-real-lgamma
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgamma.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgamma.expected.log")

# lgammaf.f32 — f32 sibling of lgamma over __kernel_sindf/__kernel_cosdf + the real e_logf body.
add_test(NAME e2e-slice-libm-real-lgammaf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgammaf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_lgammaf.expected.log")

# ── bd q2wk (3c6m.14 L6 increment 5): the 12 cells unblocked by the PredMux E6
# path-predicated-branch widening (an i1 phi as a branch condition + a condition the
# flatten itself taints). All are REAL openlibm bodies at the plain clang -O1 ship
# floor — census-COMPILES is only an upper bound until the golden exists (Rule 2).

# log1p.f64 — THE MECHANISM CELL for bd q2wk (PredMux L6 inc 5). s_log1p.c's
# `if(hx>0||hx<=(int32_t)0xbfd2bec4)` short-circuit survives plain clang -O1 as an i1 PHI over
# CONSTANTS feeding a conditional branch; before inc 5 that tripped E6-classicalbr and the whole
# fdlibm classification chain declined.
add_test(NAME e2e-slice-libm-real-log1p
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1p.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1p.expected.log")

# log1pf.f32 — float sibling of log1p over the real s_log1pf.c body (same i1-phi branch).
add_test(NAME e2e-slice-libm-real-log1pf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1pf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1pf.expected.log")

# atanh.f64 — e_atanh.c over the real vendored s_log1p.c (log1p is a library fn, injected as
# source per Rule 18); fabs is a hardware keep.
add_test(NAME e2e-slice-libm-real-atanh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanh.expected.log")

# atanhf.f32 — f32 sibling: e_atanhf.c + the real s_log1pf.c body.
add_test(NAME e2e-slice-libm-real-atanhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhf.expected.log")

# acosh.f64 — e_acosh.c over BOTH the real e_log.c and s_log1p.c bodies; sqrt is a hardware keep
# (never openlibm's software e_sqrt.c — that misrepresentation is the bd 3c6m.60 census bug).
add_test(NAME e2e-slice-libm-real-acosh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acosh.expected.log")

# acoshf.f32 — f32 sibling: e_acoshf.c + the real e_logf.c and s_log1pf.c bodies.
add_test(NAME e2e-slice-libm-real-acoshf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshf.expected.log")

# asinh.f64 — s_asinh.c over the real e_log.c and s_log1p.c bodies; sqrt/fabs are hardware keeps.
add_test(NAME e2e-slice-libm-real-asinh
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinh.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinh.expected.log")

# asinhf.f32 — f32 sibling: s_asinhf.c + the real e_logf.c and s_log1pf.c bodies.
add_test(NAME e2e-slice-libm-real-asinhf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhf.expected.log")

# hypotl.f80 — bd 3c6m.61, the last census-pipeline-only cell. The E4 i80-COMPARE EMISSION
# witness (precisely: it pins that the compares lower, link, signature-match, strip and free —
# NOT that the mux routes the right value; for this cell's arguments the source-level Inf/NaN
# branch is not the taken path, and the runtime is trace-only. Value routing is pinned at the
# ir-pass level by control_predmux_accept_i80_cmp_arm.ll, whose CHECKs are mutation-validated
# against arm-swap and mask-drop. See the slice header). Its sole blocker was the Inf/NaN arm's
# `manh == LDBL_NBIT && manl == 0`, which clang -O1 +
# promoteFp80Union fuse into `icmp eq i80 (and i80 %bits, ~0u64), 0x8000000000000000` feeding an
# f80 select. Now lowered on the frozen §6.0 grid (cq_template_icmp_eq_i80_hl + its void `_unc`),
# one of the two under a cqrt_toffoli AND with the `hb >= ESW(MAX_EXP)` i32 flag. Its three
# SET_LDBL_EXPSIGN RMWs survive -O1 as alloca/gep/store/load and are consumed by promoteFp80Union
# — they do NOT reach the Shadow store model (the lowered module has zero cqrt_qram_* and zero
# memory ops; an earlier draft of this comment claimed otherwise). fabsl (x3) / sqrtl (x2) are
# Rule-18 hardware KEEPS.
add_test(NAME e2e-slice-libm-real-hypotl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypotl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypotl.expected.log")

# hypotf.f32 — the E6 SUB-RULE (B) witness: its blocker was `icmp eq i32 %k, 0` over an UNTAINTED
# phi-merged scale accumulator, admitted now by valueWillTaintAfterFlatten. sqrtf/fabsf are keeps.
add_test(NAME e2e-slice-libm-real-hypotf
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypotf.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_hypotf.expected.log")

# acoshl.f80 — ld80 cell over the real ld80/e_logl.c + ld80/s_log1pl.c bodies with union IEEEl2bits
# kept verbatim. Pins that the __polevll Horner loops fully unroll IN THE PIPELINE at the plain -O1
# ship floor — measured: `clang -O1` leaves them as REAL loops (12 in @slice here, 4 in each log
# sibling), and the pass's own static-K force-unroll prepass (LoopUnrollPrepass.cpp, bd 3c6m.55
# Inc 2 / lf8s, trip <= kMaxUnrollTrip=8) unrolls them between the PredMux fixpoints, before
# lowerLoops. (TWICE-CORRECTED by bd oudq: this comment used to attribute the unroll to clang -O1
# — a future agent debugging a loop-shaped decline would look at stage-1 IR, see 4 live loops and
# conclude the pin was broken — and it used to say the standalone log1pl/log2l/logl siblings did
# NOT unroll and were honest E2-cycle/bd 8h7d declines. They unroll exactly like this cell; their
# ship-floor decline was the __isnanl entry-phi CONTROL shape W6 now claims, and all three are
# committed slices below.)
add_test(NAME e2e-slice-libm-real-acoshl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_acoshl.expected.log")

# asinhl.f80 — ld80 cell: s_asinhl.c over the real ld80/e_logl.c + ld80/s_log1pl.c bodies,
# union IEEEl2bits verbatim (the pass's promoteFp80Union owns it); sqrtl/fabsl are keeps.
add_test(NAME e2e-slice-libm-real-asinhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_asinhl.expected.log")

# atanhl.f80 — ld80 cell: e_atanhl.c over the real ld80/s_log1pl.c body.
add_test(NAME e2e-slice-libm-real-atanhl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_atanhl.expected.log")

# ── bd oudq (PredMux L6 Inc 6, the W6 stranded-merge claim witness) ─────────────
# log1pl.f80 / logl.f80 / log2l.f80 — the three ld80 cells whose ONLY ship-floor
# blocker was the fdlibm __isnanl early-exit: a sole 2-incoming i1 merge phi
# (s_isnan.c:63) OR-ed into that same merge block's own tainted branch. Before W6
# both claims were lost — the downstream region at `E6-condtree` (an ENTRY phi is
# never converted, q2wk rule (A) condition 2), the upstream diamond that DEFINES
# the phi at `W-witness` — and all three declined `nested control flow under
# quantum control` at the plain -O1 floor (measured on the pre-oudq plugin).
# Their __polevll Horner loops survive `clang -O1` as real loops (4 each) and are
# force-unrolled INSIDE cq-lowering by LoopUnrollPrepass, exactly as in the
# acoshl / asinhl / atanhl siblings that inline these same bodies — so the loops
# were never these cells' blocker.
add_test(NAME e2e-slice-libm-real-log1pl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1pl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log1pl.expected.log")

add_test(NAME e2e-slice-libm-real-logl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_logl.expected.log")

# log2l additionally pins the bd zco4 volatile scalar-local promotion: e_log2l.c
# declares `volatile long double z` (the Moshier ***CAUTION*** anti-reassociation
# idiom) and the slice keeps it verbatim.
add_test(NAME e2e-slice-libm-real-log2l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log2l.expected.log")

# ── bd 0rwu (PredMux W7, the CONST-FALLTHROUGH integer sole-phi diamond) ────────
# expl.f80 / log10l.f80 — the last two cells blocked by the SAME fdlibm __isnanl
# early-exit as the W6 trio above, but through the OTHER consumer shape, and that
# contrast is the point. In log1pl/logl/log2l the isnan merge phi is an i1 OR-ed
# into its own block's tainted branch, so it STRANDS a downstream cond tree and W6
# claims it. Here `if (isnan(x)) return x;` stands ALONE (log10l's `x <= 0` domain
# test is a separate downstream block), so nothing is stranded, W6 correctly does
# not fire, and at the f80 ship floor the phi is the INTEGER
# `phi i32 [ 0, %entry ], [ %zext, %arm ]` — a sole 2-incoming integer merge with a
# ConstantInt fall-through, which W5 left to the 4.2 value emitter and which that
# emitter cannot take either (`Routed = StraightThrough` = the folded `0`, and no
# accept path matches a ConstantInt). Both declined `value-arm swap-route under
# quantum control` at ArmClassify.cpp:1171, instruction-for-instruction, with no
# owner anywhere.
#
# HOW THE BLAST RADIUS WAS MEASURED, stated carefully because an earlier draft of
# this comment drew it from the wrong population (Rule-13 round). It is NOT
# "2 cells decline-anchor at 1171, therefore the radius is 2": W7's predicate says
# nothing about a decline ANCHOR, so the 1171-anchor population does not bound it —
# a W7-shaped diamond declining at `non-routable value multiplexer` or `control
# flow` would move too and would not be in that count. The radius was measured
# DIRECTLY instead, by re-running the full 123-cell injection census under both
# plugins and diffing cell by cell: EXACTLY 2 cells changed status
# (expl.f80 decline -> COMPILES, log10l.f80 decline -> exit0-spec) and ZERO
# regressed. Independently, all 932 ir-pass fixtures were swept under both plugins
# comparing exit code AND emitted IR: the only differences are the 4 intended
# decline -> accept flips. Note the census bounds the CENSUS and nothing else —
# three committed e2e goldens (erfl/erfcl/sinhl) also moved, by claim-order churn,
# and only the e2e layer surfaced that.
# Both slices run stage 2b STRICT (no --allow-unproven).
add_test(NAME e2e-slice-libm-real-expl
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expl.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_expl.expected.log")

# log10l additionally pins the bd zco4 volatile scalar-local promotion: e_log10l.c
# declares `volatile long double z` (the Moshier ***CAUTION*** anti-reassociation
# idiom) and the slice keeps it verbatim, exactly as its log2l sibling does.
add_test(NAME e2e-slice-libm-real-log10l
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10l.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_libm_real_log10l.expected.log")

# ---------------------------------------------------------------------------
# bd test_C_libtooling-8txa — the Rule-6 free-pairing checker's OWN gate.
#
# tools/free_pairing_check.py runs as stage 2b of run_slice.sh on every slice
# above, so it is now load-bearing: a checker that quietly stopped flagging
# anything would make 232 e2e entries look green while witnessing nothing. This
# entry is the mutant validation that keeps it honest — positive fixtures that
# are verbatim lowered IR from the slices above and MUST verify clean, the named
# defects bd 8txa says the golden trace cannot see (a deleted uncompute toffoli,
# an `_inv` re-pointed to the wrong rail, a free whose uncompute never ran, each
# with the exact finding code it must produce), and a proof-targeted sweep that
# blanks every line a verified proof consumes and requires the verdict to flip.
# It is pure Python over embedded fixtures: no clang, no opt, no plugin.
add_test(NAME e2e-free-pairing-selftest
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/free_pairing_check_test.py")

# bd test_C_libtooling-261j(a) — the record-freeze fixtures' OWN gate, and the same
# argument as the entry above one level up: a negative nobody has tried to defeat
# is a negative nobody should trust.
#
# The 261j freeze (never `cqrt_free` a rail RECORDED onto a kept output tape) is
# INVISIBLE to every other gate in this suite: `opt -verify` is clean either way,
# the golden byte-diff cannot witness "freed at |0>" at any ABI, and
# free_pairing_check.py CERTIFIED the original defective frees through four
# different proof paths. The ONLY regression protection is the `NOFREE*` FileCheck
# negatives in ir-pass/test/lowering_io_tape_*.ll — and a FileCheck CHECK-NOT is
# bounded by the next positive directive of its own prefix, so those negatives are
# one careless anchor away from never executing while their fixture still passes.
# That defect shipped TWICE in this family (the original CHECK-NOT placement, then
# the repair that moved them into a shared prefix). This entry injects, per guard,
# the exact `cqrt_free` the pre-261j compiler emitted and requires FileCheck to
# fail; a guard that survives is reported DEAD. Auto-discovers prefixes, so new
# fixtures are covered without editing it. Needs the built plugin (it lowers each
# fixture), so it lives here rather than in ir-pass-lit.
# bd test_C_libtooling-drbq Inc 3, round-1 review (lens L7) — THE QUARANTINE'S OWN
# MUTANT VALIDATION, and the same argument as the two entries above one level up.
# `tools/loop_twin_matrix.py`'s pinned-signature quarantine is the ONLY mechanism
# in the tree that lets a KNOWN rolled-vs-flat trace divergence pass a gate whose
# entire purpose is to fail on trace divergence. If its semantics silently
# degenerate to "skip these 15 cells", the gate reports green while witnessing
# nothing about them — and the green looks identical either way. This entry
# asserts the four claims the quarantine makes (signature changed -> FAIL; cell
# stopped diverging -> FAIL; un-quarantined divergence -> FAIL; cell in both files
# -> FAIL) plus an unknown-cell entry and a moved boundary control, against a
# passing control. It stubs the cell results, so it runs no clang, no opt and no
# plugin and costs well under a second.
add_test(NAME e2e-loop-twin-quarantine-selftest
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/loop_twin_matrix_quarantine_test.py")

add_test(NAME e2e-fixture-guard-liveness
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/fixture_guard_liveness.py")

# bd tkju prevention gate (Rule 18): no e2e slice may vendor openlibm's SOFTWARE
# body for a function the pass curates as a HARDWARE KEEP. Such a body models a
# program the ship floor never compiles — a FAITHFULNESS defect (it over-tests a
# bit-twiddle ladder under quantum control while under-testing the keep route),
# which is how the copysign block propagated by copy-paste across 52 slices. The
# keep-set is DERIVED from IntrinsicLowering.cpp::isCuratedFpIntrinsic, never
# duplicated, so gate and compiler cannot drift. Pure Python over the .c sources:
# no clang, no opt, no plugin.
add_test(NAME e2e-keepset-vendor-check
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/keepset_vendor_check.py"
          --root "${CMAKE_SOURCE_DIR}")

# bd 3c6m.63 prevention gate — the same argument as the keepset gate above, one
# axis over. The published libm scoreboard prints `verified` (the glob count of
# `slice_libm_real_*.expected.log`) beside `injection-covered` (read off
# `full_census_O1.json`); two mechanisms, one claim, and they can desynchronize.
# When the corpus fix of 3c6m.63 flipped three cells COMPILES -> decline, their
# three goldens — which vendor the ld80 bodies openlibm does not build — kept
# passing and NOTHING turned red. This asserts the only direction that can go
# wrong silently: no `slice_libm_real_<s>` may exist for a spelling whose census
# cell is not injection-covered. It deliberately does NOT require the converse
# (covered and verified are measured apart on purpose). Pure Python over the
# committed census json and the slice filenames: no clang, no opt, no plugin.
add_test(NAME e2e-census-slice-sync
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/slice_census_sync_check.py"
          --root "${CMAKE_SOURCE_DIR}")

# ===========================================================================
# bd test_C_libtooling-8h7d.5 (Phase 7.3 Increment 3) — TAINTED CONTROL FLOW
# INSIDE A CLASSICALLY-BOUNDED LOOP, lowered ROLLED.
#
# Five entries: two ROLLED slices, their two HAND-UNROLLED TWINS, and a
# dynamic-bound slice — plus, below them, the two `cmp`s that are the point of
# the whole group.
#
# WHY THE TWINS ARE TESTS AND NOT A COMMENT. This project has no simulator
# (Rule 2, owner decision 2026-06-10), so "the rolled loop computes the right
# unitary" cannot be checked directly. What CAN be checked is that it emits the
# SAME GATE STREAM — gate for gate, handle for handle — as a straight-line
# program that already passed an adversarial Rule-13 round (bd lom0 Inc 4 for
# the direct oracle, bd 160a Inc 6 for the derived one). Byte-identity is that
# check, and a `cmp` in ctest is the only version of it that cannot rot. The
# handles line up because the runtime's allocator is a monotonic counter with no
# recycling, so the Nth `cqrt_alloc` in the trace gets the same number either way.
#
# The two source files of each pair deliberately do NOT share a header: their
# whole value is that they reach the pass through DIFFERENT `clang -O1` output —
# a rotated loop with two header phis and in-body diamonds on one side,
# straight-line code with four diamonds on the other — and converge.
#
# All five run STRICT stage 2b (no `--allow-unproven`): every ancilla is minted,
# stripped and freed inside its own iteration, so the free-pairing checker sees a
# matched free for each and the only rail left allocated is the measured register.
# ===========================================================================

add_test(NAME e2e-slice-control-grover-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop.expected.log")

add_test(NAME e2e-slice-control-grover-loop-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_unrolled.expected.log")

# The CUSTOMER program (example/grover/grover_oracle_uncompute.c). The derived
# oracle brings the uncompute spine into the twin claim: three template rails per
# trip that must be reversed and freed IN-BODY, between the flag strip and the
# flag free. Before this increment the rolled form leaked all three per trip and
# its trace differed from the twin's by exactly the six missing discharge lines.
add_test(NAME e2e-slice-control-grover-loop-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_derived.expected.log")

add_test(NAME e2e-slice-control-grover-loop-derived-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_derived_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_derived_unrolled.expected.log")

# The ROLLED property itself. The trip count is a `volatile` global, so no unroll
# is possible even in principle and the emitted IR must hold exactly ONE copy of
# the stream. MEASURED 2026-08-29: the lowered IR is 87 lines at `cq_n = 3` and
# 87 lines at `cq_n = 1000` — byte-identical apart from the initializer — while
# the trace goes 57 -> 18003 lines. `cq_n` stays 3 here so the golden is readable.
add_test(NAME e2e-slice-control-grover-loop-dynamic
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_dynamic.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_dynamic.expected.log")

# THE ONE THAT FOUND A BUG. A rolled loop whose REGISTER is mutated in place
# (`q += off`) on BOTH sides of the back edge: the pre-header chain and the latch
# chain. The first draft of `collapseFlattenedLoopRails` collapsed the rail phi
# WITHOUT marking the `add` into `taint.InPlaceRailOps`, so `lowerOps` emitted it
# out of place into a fresh rail nothing read and the whole loop computed on `q`
# instead of `q + off`. `opt` exit 0, verify-clean, STRICT stage 2b CLEAN — the
# only outward sign was one M-A warning. This slice and
# ir-pass/test/control_swap_inloop_railop_inplace.ll are what make it loud.
add_test(NAME e2e-slice-control-grover-loop-offset
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_offset.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_offset.expected.log")

add_test(NAME e2e-slice-control-grover-loop-offset-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_offset_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_offset_unrolled.expected.log")

# THE TWIN GATES. `cmp` over the two committed goldens — no clang, no opt, no
# plugin, milliseconds. If either side is ever regenerated alone, this is what
# turns red; without it a rolled loop could quietly drift into a different (and
# still self-consistent) gate stream and every other gate in the suite would stay
# green, which is the failure mode this project keeps rediscovering.
add_test(NAME e2e-grover-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_unrolled.expected.log")

add_test(NAME e2e-grover-loop-derived-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_derived.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_derived_unrolled.expected.log")

add_test(NAME e2e-grover-loop-offset-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_offset.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_offset_unrolled.expected.log")

# bd test_C_libtooling-8h7d.5, Rule-13 round 1 (finding OD1) — TWO INDEPENDENT
# REGISTERS, each with its own tainted `if`, in ONE loop. This DID NOT COMPILE at
# ba35c1f: `phiTracksWire`'s staleness test was wire-BLIND, so each register's
# rotations refused the other's record-refresh barrier and neither header phi
# could be claimed. The decline text ("condition predates a non-diagonal gate")
# named a register the walk was not even reasoning about, and the disposition
# turned on which mint clang emitted first. The test is per WIRE now, and this is
# the end-to-end witness: two rails, two routed regions, four rotations per trip,
# every ancilla freed in its own iteration, STRICT stage 2b.
add_test(NAME e2e-slice-control-grover-loop-two-regs
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_two_regs.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_two_regs.expected.log")

add_test(NAME e2e-slice-control-grover-loop-two-regs-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_two_regs_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_two_regs_unrolled.expected.log")

add_test(NAME e2e-grover-loop-two-regs-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_two_regs.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_two_regs_unrolled.expected.log")

# bd test_C_libtooling-8h7d.5, Rule-13 ROUND 4 — TWO CELLS THE SHIPPED SLICES DID
# NOT COVER, and the reason the whole matrix is now a gate of its own
# (e2e-loop-twin-matrix). Every loop slice above puts the tainted region FIRST in
# the body; that is one cell, and both findings hide in the others.
#
#   * LEADING GATE (finding F-4): one `cq_theta` moved to the FRONT of the body
#     and the uncompute spine stopped discharging the oracle's ancilla chain. The
#     rolled trace was SHORTER than the twin's by the two discharge lines per
#     trip, with `opt` exit 0, strict stage 2b clean and NOT ONE WARNING — the
#     leaked rail is TEMPLATE-minted, which stage 2b does not count.
#   * RANGE ORACLE (finding OD-A): `if (a > 5 && a < 20)` in the body DECLINED
#     `kMsgRailFanout` while its hand-unrolled twin compiled — `clang -O1`'s
#     `add %a, -6; icmp ult %t, 14` canonicalization made a derived-condition temp
#     wear the in-place rail shape.
add_test(NAME e2e-slice-control-grover-loop-leading-gate
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_leading_gate.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_leading_gate.expected.log")

add_test(NAME e2e-slice-control-grover-loop-leading-gate-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_leading_gate_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_leading_gate_unrolled.expected.log")

add_test(NAME e2e-grover-loop-leading-gate-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_leading_gate.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_leading_gate_unrolled.expected.log")

add_test(NAME e2e-slice-control-grover-loop-range-oracle
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_range_oracle.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_range_oracle.expected.log")

add_test(NAME e2e-slice-control-grover-loop-range-oracle-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_range_oracle_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_range_oracle_unrolled.expected.log")

add_test(NAME e2e-grover-loop-range-oracle-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_range_oracle.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_grover_loop_range_oracle_unrolled.expected.log")

# bd test_C_libtooling-8h7d.5, Rule-13 ROUND 4 — THE ROLLED-EQUALS-UNROLLED
# MATRIX. Phase 7.3 Increment 3's whole claim is "the rolled loop emits the same
# gate stream its hand-unrolled twin does", and until this entry existed it was
# witnessed by the four hand-picked slice pairs above — every one of which puts
# the tainted region FIRST in the body. That is ONE CELL, and it is the cell the
# round-4 finding is invisible in: with a `cq_theta` moved to the FRONT of the
# body the uncompute spine leaked the oracle's ancilla chain once per trip, with
# `opt` exit 0, `opt -verify` clean, STRICT stage 2b clean (the leaked rails are
# TEMPLATE-minted, which the checker does not count) and, in five of the eleven
# affected cells, no diagnostic at all.
#
# 156 cells, each compiled AND RUN on both sides and byte-diffed: the 120-cell
# prefix x region x suffix product over one loop body, PLUS 36 RECORD-axis cells
# (bd drbq Inc 2a round-1 review, L1 §3.8). Verdicts are pinned in the committed
# table tools/loop_twin_matrix.expected.txt, so a cell that CHANGES DISPOSITION is
# a red rather than a silent drift (Rule 12) — regenerate deliberately, never by
# reflex.
#
# THE RECORD AXIS is the fourth, and it closed a hole in the instrument itself:
# until it was added there was no `int mark = a;` in ANY of the 120 cells, while
# 8h7d.5's F-1 and F-3 — two of the three CONFIRMED silent miscompiles that
# machinery produced — were ENTIRELY about rail records. Three shapes (`premark`,
# `postmark`, `bodyread`) crossed with a declared 12-cell sub-grid rather than
# with the whole product, because a full 5x6x4x4 = 480 would quadruple the entry's
# cost for cells with little discriminating power. 18 of the 36 are
# ACCEPT-IDENTICAL (rolled trace byte-identical to its twin's WITH a live record
# present, which is new coverage); the other 18 are UNROLLED-ONLY, the 8h7d.5
# rail-record fence firing on the rolled side — see the expected table's header
# for the written reason, including the pre-existing straight-line behaviour it
# exposes on the unrolled side.
#
# The sixth REGION — `range`, `if (a > 5 && a < 20)` — was added by the round-5
# cleanup (bd 8h7d.5). It is the OD-A oracle: `clang -O1` folds the two-sided test
# to `%t = add %q, -6; icmp ult %t, 14`, so the condition temp wears the dtzb
# in-place SHAPE on the rail. That is the shape round 4 FIXED, and it was not
# among the 100 shipped cells — 11 of its 20 cells were divergent at round 3 and
# all 20 are clean at HEAD. Its verdicts: 19 ACCEPT-IDENTICAL + `m_xor_range_none`
# ROLLED-ONLY, which is the THIRD member of the pre-existing `xor`/`none`
# unrolled-spelling artifact family (see the table's own header), not new.
#
# COST, RE-MEASURED 2026-08-30 on a quiet box at 120 cells: 112s wall / 279s CPU
# at --jobs 6 (240 compile+link+run pairs); it was 88s/219s at 100. At 156 cells
# (312 pairs) it measured 133s wall / 385s CPU at --jobs 4 on a box carrying
# another agent session — NOT comparable to the quiet-box figures above, and
# quoted only so the +30% cell count has a number beside it. It is the
# second-longest entry after ir-pass-lit, so it is registered EARLY enough for
# ctest's scheduler to overlap it with the slice layer. It uses `cq-opt` and the
# bd dgn5 link wrapper for the same reasons the slices do; without them it is ~2x
# slower and still correct.
#
# ⚠ `--phi-surface void` IS NOT OPTIONAL AND IS NOT A TUNING KNOB (bd
# test_C_libtooling-3qlq Increment 1, round-1 review finding F-L5-7(a)). Every
# REGION cell generates the `cq_phi` call, and Increment 1 replaced the 15-width
# `a = cq_phi(a, T)` family with the register-free `void cq_phi(double)`. Without
# this flag the generator emits the RETIRED spelling, `include/CQ.h` rejects it
# with `too many arguments to function call`, and the run reports 175
# HARNESS-ERROR + 172 "verdict changed" — a wall of STAGE-1 failures that reads
# exactly like a wall of lowering declines. It fails loud, which is the safe
# direction, but it measures NOTHING while it does so, and this is the only
# instrument in the tree that can see a leaked TEMPLATE-minted rail. The tool's
# header guard now refuses the mismatch in one line instead, in both directions.
add_test(NAME e2e-loop-twin-matrix
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/loop_twin_matrix.py"
    --clang "${_E2E_CLANG}" --opt "${_E2E_OPT}" --plugin "$<TARGET_FILE:CQPass>"
    --include "${CMAKE_SOURCE_DIR}/include"
    --runtime "$<TARGET_FILE:cq_runtime>" --templates "$<TARGET_FILE:cq_templates>"
    --phi-surface void
    --jobs 6)

# ── bd test_C_libtooling-drbq Increment 3 — THE CONTROL-IN-PLACE Ry ARM IN A
#    ROLLED LOOP (control-in-place-PRD §13). Ten slices, five hand-unrolled
#    twins, five `cmp` gates. ───────────────────────────────────────────────
#
# WHY EVERY ONE OF THESE HAS A TWIN. There is no simulator (Rule 2), so the
# strongest available statement about a ROLLED loop is that it emits the SAME
# gate stream as the same body written out flat — a stream that shipped in
# Increment 1 and was cleared by an adversarial round. All five pairs are
# byte-identical today; the `cmp` entries below are milliseconds and are what
# turns red if either side is ever regenerated alone.
#
# ⚠ THE ORACLE'S BLIND SPOT, QUOTED WHERE IT LIVES: the unrolled side IS the
# Increment-1 flat lowering, so a defect the two paths SHARE (a wrong controlled
# rotation polarity, a missed R4 aliasing, a freeze that should have fired on
# both) is byte-identical on both and these gates report success. The flat side's
# own witnesses are the Inc-1 lit family and tests/e2e/slice_control_inplace_ry.c.
#
# ⚠ AND THE GROVER PAIR IS NOT LIKE THE 8h7d.5 PAIRS: its UNROLLED twin is ALSO
# new capability. It has no loop in it and it DECLINES on the pre-Increment-3
# binary, at `ArmClassify`'s P1 fence (`SawRotationArm` was not in the
# disjunction). Part 3b compiles the twin; part 3a makes the rolled form agree
# with it. So for that one pair the oracle is not a pre-cleared stream, and the
# lit red-green pair control_inplace_ry_post_region_theta_cond.ll /
# control_inplace_ry_reject_post_region_theta_stalecond.ll is what stands behind
# the flat side instead.
#
# All ten run STRICT stage 2b (no `--allow-unproven`): each region's flag is
# minted, stripped and freed inside its own iteration, so nothing dirty crosses
# the back edge. The rotated registers are left ALLOCATED — Increment 1's
# structural freeze keeps the whole-DAG spine off a rail carrying a controlled
# rotation, which is Rule 6's sanctioned fallback and is identical in the twin.
#
# K-INDEPENDENCE IS A MEASUREMENT, NOT A GATE HERE, following the 8h7d.5
# precedent exactly (that increment measured `slice_control_grover_loop_dynamic`
# and registered no ctest entry for it). MEASURED 2026-09-04 on
# slice_control_inplace_ry_loop_grover.c: **74 lines of lowered IR at -DCQ_K=3 and
# 74 at -DCQ_K=1000**, the two modules differing only in the trip constant, while
# the trace goes 36 -> 10006 lines. A line count that grew with K would mean the
# loop was unrolled and the increment's central claim is false.
add_test(NAME e2e-slice-control-inplace-ry-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_unrolled.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-leading-gate
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_leading_gate.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_leading_gate.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-leading-gate-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_leading_gate_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_leading_gate_unrolled.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-two-regs
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_two_regs.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_two_regs.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-two-regs-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_two_regs_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_two_regs_unrolled.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_derived.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-derived-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_derived_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_derived_unrolled.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-grover
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_grover.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_grover.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-grover-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_grover_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_grover_unrolled.expected.log")

# ── bd drbq Inc 3, round-1 lens L3 Q1 — THE O(K) FREEZE LEAK, MEASURED RATHER
#    THAN ARGUED. PRD §13.5's "K rails at run time" had no witness in this tree
#    until this pair: no other slice reads the ROTATED register inside the body,
#    because the obvious spellings are refused (a read AFTER the region is
#    `operand predates a non-diagonal gate`; a read in a SECOND loop is a
#    classical-condition mux). Reading it BEFORE the region works, and the golden
#    then shows 2 TEMPLATE-minted rails per activation — `mul` + `tape_write` —
#    that nothing ever frees: 4 at K=2 here, 6 at K=3 (L3 measured both).
#
#    RULE-6 CORRECT (all left allocated, none freed dirty) and INVISIBLE TO
#    STRICT STAGE 2B, which counts `cqrt_alloc` mints only — which is precisely
#    why it needs a golden. The twin gate below is the load-bearing half: the
#    flat form strands the same rails for the same reason, so the cost belongs to
#    the FREEZE, not to the ROLL.
#
#    ⚠ BOTH SIDES EMIT M-A's `non-diagonal gate over a live derived record`
#    warning, and the counts are NOT symmetric: 1 rolled vs 2 flat, because the
#    warning is PER STATIC GATE while the hazard occurs K times at run time. That
#    asymmetry is expected here and is written up in the notes; do not "fix" it
#    by regenerating one side.
# ── UNREGISTERED 2026-09-18 — bd `test_C_libtooling-6n1s` F-1, the coordinator's
#    blast-radius item. THE THREE ENTRIES THAT STOOD HERE PINNED A Rule-8 WRONG
#    UNITARY AS EXPECTED OUTPUT, and their own headers called it "RULE-6 CORRECT".
#
#    `e2e-slice-control-inplace-ry-loop-leak`,
#    `e2e-slice-control-inplace-ry-loop-leak-unrolled` and
#    `e2e-inplace-ry-loop-leak-twin-identical` are removed; BOTH goldens are
#    DELETED rather than regenerated, and both `.c` files are KEPT unregistered
#    with a conversion header — the 2026-09-14 stale-reader precedent, which is
#    itself the `slice_control_switch_phase.c` precedent of 2026-09-05.
#
#    WHY, read straight off the deleted goldens (identical in both halves):
#      cq_template_mul_i32_hl(h2, 7) -> h3      <- a COHERENT copy of h2
#      cqrt_tape_write_i32(t0, h3) -> h4        <- a COPY into the tape; h3 is
#                                                  NOT collapsed and stays
#                                                  entangled with h2
#      cqrt_ry_i32_controlled(h5, h2, 0.9)      <- NON-DIAGONAL, on h2
#      ...                                         (and again for h6)
#      cqrt_measure_i32(h2)                     <- h2 IS the observable
#    `h3`/`h6` are never `_unc`'d and never freed, so a which-path record of `h2`
#    stands at a non-diagonal gate on `h2`. That is `CLAUDE.md` Rule 8 verbatim and
#    §5's Q-R1-1 correction in its own words. ⚠ Only the tape-write RESULT (`h4`,
#    `h7`) is an `OutputRails` member; its OPERAND `h3` is an ordinary interior
#    template rail, so "it is the program's own output" does NOT excuse it.
#
#    ⚠ ONLY THE ROLLED HALF IS CAUGHT BY A FENCE, and that asymmetry is the whole
#    filing. `declineUndischargedMarkedBodyRails` is LOOP-SCOPED, so it refuses the
#    rolled slice and CANNOT reach the unrolled one, which still compiles the same
#    hazard at exit 0. The unrolled half is therefore a NEW P1 (bd text in
#    `trackT2/BD_TEXT.md`), not something this increment closed.
#
#    ⚠ L8 RETIREMENT TRIGGER: the day the arm-minted / straight-line which-path
#    leak gains a real placement, BOTH `.c` files become ACCEPTs again and the
#    twin-identical gate can be restored — re-derive both streams then against the
#    hand-unrolled twin's MULTISET (owner ruling S3), and do NOT restore these
#    goldens, which pin the leaking stream.
#
#    Net coverage: the ROLLED decline is pinned by
#    `ir-pass/test/loop_leak_dephase_reject_inplace_ry_loop_leak_slice.ll`
#    (the slice's own stage-1 module, validated non-vacuous by binary mutation).
#    The UNROLLED hazard is pinned by NOTHING and that is the bead.

# THE TWIN GATES — `cmp` over the two committed goldens, no clang, no opt, no
# plugin, milliseconds each.
add_test(NAME e2e-inplace-ry-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_unrolled.expected.log")

add_test(NAME e2e-inplace-ry-loop-leading-gate-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_leading_gate.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_leading_gate_unrolled.expected.log")

add_test(NAME e2e-inplace-ry-loop-two-regs-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_two_regs.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_two_regs_unrolled.expected.log")

add_test(NAME e2e-inplace-ry-loop-derived-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_derived.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_derived_unrolled.expected.log")

add_test(NAME e2e-inplace-ry-loop-grover-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_grover.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_grover_unrolled.expected.log")

# (`e2e-inplace-ry-loop-leak-twin-identical` unregistered 2026-09-18 — see the
#  banner above; both goldens are deleted, so there is nothing to compare.)

# ---------------------------------------------------------------------------
# bd test_C_libtooling-drbq Increment 4 — CONTROLLED STATE PREP (PRD §14).
#
# A flat diamond whose single content arm is one `cq_theta` with a CLASSICAL
# CONSTANT arg-0: the theta MINTS a rail rather than rotating a live one, so
# `lowerRotations` emits `cqrt_alloc_<W>(SEED)` at the HOISTED position and then
# `cqrt_ry_<W>_controlled(f, h, θ)`. All three run stage 2b STRICT.
#
# ⚠ THERE IS DELIBERATELY NO `compare_files` TWIN GATE HERE, and the omission is
# the honest choice rather than a gap. The witness for this increment is byte
# identity between the SUBJECT golden and a REDUCTION of the TWIN golden (delete
# the `Ry(0)`, move the fresh-rail alloc, renumber — PRD §14.8), and the two
# files therefore differ by a reduction, not by identity: a `compare_files` gate
# would assert something false. The twin is committed as a slice in its own right
# so a reviewer can re-derive the reduction BY HAND from two files in the tree
# rather than from a script nobody re-runs. (`inc4-records/reduce_twin.py`
# implements the three rewrites and could become a fourth entry; recorded, not
# proposed — that is an owner cost decision, the same one the Inc-1 and Inc-2b
# instruments were given.)
add_test(NAME e2e-slice-control-inplace-ry-stateprep
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-stateprep-negated
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_negated.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_negated.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-stateprep-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_twin.expected.log")

# ----------------------------------------------------------------------------
# bd `drbq.14` — F2's `CondWire` NARROWING (owner ruling 2026-09-11).
#
# THREE SLICES, NO `compare_files` TWIN GATE, and the omission is deliberate for
# the same reason the Inc-4 group above records: there is no byte-identical twin
# to compare against. The witness here is a STATED, RE-DERIVABLE RELATION between
# goldens that are all committed, so a reviewer checks it with `diff` on two
# files in the tree:
#   * `..._seed_eq_k` vs the Inc-4 `..._stateprep` golden differ by EXACTLY ONE
#     LINE (`cqrt_alloc_i32(0)` -> `cqrt_alloc_i32(5)`) — i.e. the whole of the
#     ruling's effect at `i32` is "the alloc literal may equal the compare
#     literal";
#   * `..._bool_negated` vs `..._bool` differ by EXACTLY TWO LINES, the paired
#     `cqrt_x(h1)` bracket that controls on `!flag` (Rule 9 polarity).
# All three run STRICT stage 2b (`0 violation(s), 0 unproven`). ⚠ Stage 2b does
# NOT witness the SEED — it classifies `cqrt_alloc_<W>` by symbol name and never
# reads the argument — so the seed is pinned by these goldens and by F1, and a
# green 2b must not be quoted as evidence for it.
add_test(NAME e2e-slice-control-inplace-ry-stateprep-bool
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_bool.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_bool.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-stateprep-bool-negated
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_bool_negated.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_bool_negated.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-stateprep-seed-eq-k
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_seed_eq_k.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_stateprep_seed_eq_k.expected.log")


# ============================================================================
# bd test_C_libtooling-l4x4, sub-increment l4x4.b — THE IN-PLACE CONTROLLED-Ry
# ARM AND THE CONTROLLED STATE PREP ON A BARE `_Bool` (RAIL-ROOT) CONDITION,
# INCLUDING THE NEGATED CONDITION.
#
# `clang -O1` hands the pass `br i1 %b` with NO COMPARE from every natural `bool`
# spelling, and until this increment every such region declined `bare i1 register
# condition` at `classifyArms`' first gate. The register IS the flag: the §13.3
# rail ladder is run on it (tainted · not measured before the branch · the wire
# question) and `emitInPlaceRotationRegion` sets `Flag = Cond`. NOTHING IS
# MINTED, NOTHING IS STRIPPED, AND THE REGISTER IS NEVER FREED — after
# `Ry(θ)|0⟩` it is not `|0⟩`, so a free would be a hidden measurement (Rule 6);
# it is LEFT ALLOCATED, the same Rule-6-safe leak the COMPARE form already gives
# its own condition register. NO NEW RUNTIME SYMBOL (owner D3): every width this
# path can reach already has a declared and defined `cqrt_ry_<W>_controlled`.
#
# FIVE SLICES + ONE `cmp` TWIN GATE, all STRICT stage 2b.
#
# ⚠ FOUR OF THE FIVE HAVE **NO** `compare_files` GATE, DELIBERATELY, AND THE
# REASON IS THE drbq Inc-4 PRECEDENT: their COMPARE twins are already committed
# (`slice_control_inplace_ry{,_negated,_stateprep}.expected.log`) and this
# family's goldens are those files MINUS THREE LINES (the mint, the strip, the
# flag's `cqrt_free`) with the flag handle renamed to the condition register's.
# The two goldens differ by a REDUCTION, so a byte-identity gate would assert
# something FALSE. Each slice header states its own reduction so a reviewer can
# re-derive it from two files in the tree — 10 trace lines become 7.
#
# THE ONE REAL `compare_files` GATE IS THE NEGATED PAIR, and it is available only
# because of HOW negation is spelled. A `cqrt_x` bracket on the flag — the
# compare form's answer — is forbidden on a USER REGISTER (bd `3qlq.4`), and
# unlike the phase path there is no diagonal identity to fall back on. So the arm
# is fired UNCONDITIONALLY and CANCELLED under the register:
#     cqrt_ry_<W>(h_r, θ) ; cqrt_ry_<W>_controlled(h_b, h_r, −θ)
# `−θ` is an IEEE sign flip, never an `fsub`, so the Inc-2b by-difference
# rounding fence has no subject. That makes the compiler's output directly
# comparable to a HAND-WRITTEN twin of the same circuit
# (`r = cq_theta(r, 0.9); if (b) r = cq_theta(r, -0.9);`), which is the gate.
# ⚠ IT IS AN INTERNAL-CONSISTENCY GATE, NOT AN ORACLE GATE: both halves need
# l4x4.b to lower at all, and both decline `bare i1 register condition` on `main`
# 0c7380c. Labelled as such here and in both slice headers.
add_test(NAME e2e-slice-control-inplace-ry-bool-diamond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_diamond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_diamond.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-negated
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_negated.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_negated.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-negated-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_negated_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_negated_twin.expected.log")

# THE GATE: the compiler's anti-control == the programmer's own cancellation,
# byte for byte. Internal-consistency (both halves need l4x4.b), not an oracle.
add_test(NAME e2e-inplace-ry-bool-negated-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_negated.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_negated_twin.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-stateprep
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_stateprep.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_stateprep.expected.log")

# THE OWNER'S OWN SECOND REGION, in isolation: a controlled STATE PREP of a
# `_Bool` under a NEGATED bare-rail condition — the shape bd `b6ap`'s multi-phi
# peel will hand to this code. ⚠ HISTORY, dated: that sentence used to read "the
# owner's FILE still declines `control flow` on this branch (two merge phis, bd
# `b6ap`)". b6ap LANDED on `main` 3a3a2b9 and this branch is merged with it, so
# the owner's FILE COMPILES now (19 trace lines; `MERGE_l4x4_2.md` §4). This
# slice remains the REGION in isolation.
add_test(NAME e2e-slice-control-inplace-ry-bool-stateprep-negated
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_stateprep_negated.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_stateprep_negated.expected.log")

# bd test_C_libtooling-rb9x, increment R-1 (2026-09-13) — a `_Bool` controlled
# STATE PREP under an `int` COMPARE condition, in a diamond `clang -O1` FUSED so
# that the merge carries TWO phis. Two shipped features collided: bd `b6ap`'s
# multi-phi peel manufactures a CLONE of the region's compare, and F2
# (`f2SeedPinnedByLiveRegister`) read that clone as a live `i1` pinned to the
# seed and declined `state prep seed is proven equal to the condition register`.
# MEASURED on the session ORACLE `fbbe0820ef4b176a`: DECLINE. Here: ACCEPT, 22
# trace lines, STRICT stage 2b `0 violation(s), 0 unproven`. R-1's repair is a
# RECORD (`TaintSet::PeelClones`) consulted at F2's equality TEST, on the ground
# that a value the pass MANUFACTURES has no source preimage. The `int b1` twin
# (`trackR/probes/b_C_intb0_intb1.c`) already compiled on the ORACLE and this
# golden is its stream with `i1` widths on the b1 rail — the stated reduction
# that says the WIDTH was the over-decline, not the circuit.
add_test(NAME e2e-slice-control-stateprep-bool-under-int-compare-fused
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_under_int_compare_fused.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_under_int_compare_fused.expected.log")


# ============================================================================
# bd `boi6` sub-increment D-B / Track M (2026-09-13) — THE REGION-MERGE-phi RAIL
# LEAF AT THE 4.4 DATA SELECT.  THE OWNER'S OWN FILE, COMPILING.
#
# `if (b1) a -= 3;` where `b1` is the merge phi of an already-accepted controlled
# STATE PREP.  Before this increment that declined `control flow` at the select
# while `if (b1) a -= 1;` COMPILED on the same binary — InstCombine folds a +-1
# delta to `add(a, sext b1)` and leaves a `select` for every other delta, so the
# phi was already consumed as a quantum register and only the `select` consumer
# was refused.  The widening is ONE analysis gate (`collectCondTree`'s
# `AllowRailPhi`, proved by CALLING the region's own committed `InPlaceRotation`
# verdict in `plan.Regions`); the EMITTED STREAM is the Rule-13-cleared r9e5
# rail-root CNOT-copy merge, unchanged.
#
# ⚠ THE FOUR ENTRIES BELOW ARE ONE ARGUMENT, not four samples, and the two
# `-identical` gates are where it is actually made:
#   * `...two_bools`        the owner's file            29 lines  (NEW capability)
#   * `..._base`            the same minus line 99      19 lines  (must NOT move)
#   * `..._uncond`          the prep made unconditional 28 lines  (the frozen
#                           ORACLE already lowered this, via the SAME emitter)
#   * `..._int`             the `int b1` workaround     28 lines  (the spelling
#                           the owner refused; pinned so the widening cannot
#                           change it)
add_test(NAME e2e-slice-control-cascade-two-bools
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools.expected.log")

add_test(NAME e2e-slice-control-cascade-two-bools-base
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_base.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_base.expected.log")

add_test(NAME e2e-slice-control-cascade-two-bools-uncond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_uncond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_uncond.expected.log")

add_test(NAME e2e-slice-control-cascade-two-bools-int
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_int.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_int.expected.log")

# bd `om35` (owner-ruled 2026-09-14) — THE OWNER'S FILE AT N=3. The two-bools
# slice above is this program with the third region commented out; uncommenting
# it declined `state prep seed is proven equal to the condition register` until
# F2 learned that a value in the transitive USER closure of the region's own
# merge phi is not a collider (availability: it is at neither slot the question
# is about). 35 lines; read the slice header for the line-by-line.
add_test(NAME e2e-slice-control-cascade-three-bools
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_three_bools.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_three_bools.expected.log")

# GATE 1 — "an ACCEPT, not a STREAM", the PREFIX half.  The base slice is the
# flagship minus its last `if`, so the flagship's golden must START with the
# base's first 16 lines byte for byte: adding a consumer of `b1` changed nothing
# about how `b0`, `b1` and the `a`-mux are emitted.  A plain `compare_files` will
# not do (the base's tail is its own three measurements), so this compares the
# 16-line prefix.
add_test(NAME e2e-cascade-two-bools-base-prefix-identical
  COMMAND "${CMAKE_COMMAND}"
    "-DA=${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools.expected.log"
    "-DB=${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_base.expected.log"
    -DN=16
    -P "${CMAKE_CURRENT_SOURCE_DIR}/compare_prefix.cmake")

# GATE 2 — "an ACCEPT, not a STREAM", the SELECT half, and this is the real twin
# gate.  `..._uncond` is the SAME select lowered from a condition that is already
# a `cq_theta_i1` CALL — a shape the FROZEN ORACLE accepts with no Track M change
# at all.  The two select halves must be identical once the two rails are renamed
# (the flagship's extra cancelling prep gate shifts the handle numbering):
# flagship lines 17-26 vs uncond lines 16-25, with the prep rail h1<->h5 and the
# a-mux out rail h3<->h2.  MEASURED IDENTICAL 2026-09-13.
add_test(NAME e2e-cascade-two-bools-twin-identical
  COMMAND "${CMAKE_COMMAND}"
    "-DA=${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools.expected.log"
    "-DB=${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools_uncond.expected.log"
    -DAFROM=17 -DATO=26 -DBFROM=16 -DBTO=25
    "-DAREN=h1=hPREP;h3=hAMUX" "-DBREN=h5=hPREP;h2=hAMUX"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/compare_twin_half.cmake")

# bd `boi6` D-B / Track M, round-1 finding F-M6 — a 4.4 DATA SELECT **INSIDE** a
# bounded loop whose condition is the merge phi of a prep region **OUTSIDE** it.
# It moved DECLINE -> ACCEPT with this increment and had no instrument at all.
#
# ⚠ It is a DIFFERENT CELL from `m30`, which is the LOOP-CARRIED phi and is
# declined one layer earlier by the loop lowering itself
# (`loop-carried tainted value crosses iterations`, unchanged on both binaries).
# Here the phi is defined outside the loop and is loop-INVARIANT.
#
# The loop stays ROLLED: the lowered IR is K-independent at 78 lines / 19 gate
# calls for both `i < 3` and `i < 1000` (measured, `clang -O1` without `-g`).
add_test(NAME e2e-slice-control-cascade-select-in-loop-outside-prep
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_select_in_loop_outside_prep.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_select_in_loop_outside_prep.expected.log")

add_test(NAME e2e-slice-control-cascade-select-in-loop-unrolled-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_select_in_loop_outside_prep_unrolled_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_select_in_loop_outside_prep_unrolled_twin.expected.log")

# THE GATE: the compiler's ROLLED loop == the programmer's own three copies, byte
# for byte.  The rolled form emits the body ONCE and runs it three times; the
# unrolled form emits three copies run once each.  A per-iteration mint that
# should have been hoisted, a gate dropped on the back edge, or an ancilla reused
# across trips all show up here and nowhere else — the loop twin matrix has no
# `_Bool` axis, so this pair is the ONLY instrument for this cell.
# ⚠ INTERNAL-CONSISTENCY, NOT AN ORACLE GATE: both halves need bd `boi6` D-B to
# lower at all (the frozen ORACLE declines both).
add_test(NAME e2e-cascade-select-in-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_select_in_loop_outside_prep.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_select_in_loop_outside_prep_unrolled_twin.expected.log")


# ============================================================================
# bd test_C_libtooling-3qlq Increment 1 — REGISTER-FREE `cq_phi` (PRD S6.5).
#
# THIRTEEN LIVE ENTRIES (ten slices + three `cmp` twin gates). prep-b registered
# FOURTEEN as `DISABLED TRUE` because the lowering did not exist yet and no
# `.expected.log` did either; prep-b2 generated every golden on the Increment-1
# binary through the full pipeline (stage 1 -> 2 -> STRICT 2b -> 3 -> 4), audited
# them with `tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764`, and
# DELETED the `set_tests_properties(... DISABLED TRUE)` call. One of the fourteen,
# `e2e-slice-control-phase-nest-deep`, was REMOVED instead of enabled: it is a
# MIXED nest and declines `impure phase arm` on BOTH binaries (OQ-7; the note is
# at that registration's old site).
#
# Every one of these programs DECLINED on the pre-3qlq oracle; the measured exit
# code and diagnostic string for each is in
# docs/prd/phase-04-swap-route-control/inc1-records/PRE_DISPOSITIONS.md, and the
# post-increment disposition of all 71 migrated + new slices is in
# .../inc1-records/GOLDEN_REGEN.md.
# ============================================================================

# --- the correct Grover oracle (PRD S1: every PRE-3qlq grover golden is the
# --- identity on q, because `cqrt_rz_<W>` is TENSORED). Flat, and the rolled /
# --- hand-unrolled twin pair.
add_test(NAME e2e-slice-control-phase-grover
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover.expected.log")

add_test(NAME e2e-slice-control-phase-grover-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover_loop.expected.log")

add_test(NAME e2e-slice-control-phase-grover-loop-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover_loop_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover_loop_unrolled.expected.log")

# --- D4's per-bit idiom: the REPLACEMENT for the deleted multi-bit `cqrt_rz_<W>`.
# --- K=4 rolled + its hand-unrolled twin, and K=32 rolled ONLY (the
# --- K-independence witness; a 32-times hand expansion would prove nothing more).
add_test(NAME e2e-slice-control-phase-perbit-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop.expected.log")

add_test(NAME e2e-slice-control-phase-perbit-loop-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_unrolled.expected.log")

add_test(NAME e2e-slice-control-phase-perbit-loop-k32
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_k32.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_k32.expected.log")

# --- THE MIXED LOOP (bd 3qlq Inc 1, the Rule-13 CLEARANCE finding C-1, the BLOCK).
# --- D4's per-bit idiom on a loop-INVARIANT register in a loop that ALSO CARRIES
# --- one. At 542d588 the rolled form leaked all three bit rails (3 mints, 0 `_unc`)
# --- while this pair's twin discharged them — the two goldens were 31 vs 37 lines.
# --- The `cmp` gate below is the witness; the rolled slice alone cannot be one.
add_test(NAME e2e-slice-control-phase-perbit-loop-mixed
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed.expected.log")

add_test(NAME e2e-slice-control-phase-perbit-loop-mixed-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_unrolled.expected.log")

# --- THE MIXED LOOP WITH A PREHEADER IN-PLACE `add` (bd 3qlq Inc 1, the SECOND
# --- C-1 review round, finding F-C1-1). One line more than the pair above, and
# --- it put the leak back: `invariantRegisterRoots` peels only through ops whose
# --- DISPOSITION is `InPlace`, and a preheader `add` is `Unproven` at that stage
# --- even though M-C lowers it in place (`cqrt_addc_i32(h0, 7)` is line 5 of the
# --- golden). 3 mints / 0 `_unc` on 542d588 AND on the round-1 C-1 fix (32 lines
# --- vs the twin's 38). The `cmp` gate below is the witness.
add_test(NAME e2e-slice-control-phase-perbit-loop-mixed-preadd
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_preadd.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_preadd.expected.log")

add_test(NAME e2e-slice-control-phase-perbit-loop-mixed-preadd-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_preadd_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_preadd_unrolled.expected.log")

# --- THE MERGE-OUT-RAIL ROOT WITH A PREHEADER IN-PLACE `add` (bd 3qlq Inc 1,
# --- the FOURTH C-1 round, finding F-I2-1). The PRODUCT of the two axes above
# --- and `..._inloop_merge_rail`: the invariant register the per-bit condition
# --- reads is a Phase-4 CONTROL-OWNED MERGE OUT-RAIL (the 4.4 select merge's
# --- `%out`), and the preheader `+7` lands IN PLACE on it. A merge out-rail
# --- structurally cannot satisfy `P->hasOneUse()` — the emitters WRITE it before
# --- anything reads it — so `commitOutOfLoopInPlaceOps` refused and the rails
# --- leaked: 4 mints / 0 `_unc` on `main` a3c1513 (44 lines vs the twin's 52),
# --- 32 / 0 at K=32. The `cmp` gate below is the witness.
add_test(NAME e2e-slice-control-phase-perbit-loop-merge-preadd
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_merge_preadd.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_merge_preadd.expected.log")

add_test(NAME e2e-slice-control-phase-perbit-loop-merge-preadd-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_merge_preadd_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_merge_preadd_unrolled.expected.log")

# --- THE SAME AXIS ON THE **INC-2 VALUE-ARM** MERGE OUT-RAIL (bd 3qlq, the
# --- FOURTH C-1 round REBASED onto the landed Increment 2, 258d974). Round 4
# --- fixed the leak for the THREE producers of a merge out-rail that existed on
# --- a3c1513; Inc 2 then landed a FOURTH — the controlled-copy VALUE merge,
# --- which writes `%out` with two `cqrt_copy_i32_controlled` before any reader —
# --- and the round could only ARGUE that its fix serves it ("CANNOT be measured
# --- until the orchestrator rebases this branch onto the landed Inc 2"). This
# --- pair is that measurement: on `main` 258d974 the rolled slice is 4 mints /
# --- 0 `_unc` at 52 lines against this twin's 4/4 at 60 (`cmp` DIVERGE 8), at
# --- `opt` exit 0, verify-clean and STRICT 2b `0 violation(s), 0 unproven`;
# --- here it is 60 = 60 and the rolled trace is byte-identical to `main`'s OWN
# --- unrolled twin. The `cmp` gate below is the witness.
add_test(NAME e2e-slice-control-phase-perbit-loop-value-merge-preadd
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_value_merge_preadd.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_value_merge_preadd.expected.log")

add_test(NAME e2e-slice-control-phase-perbit-loop-value-merge-preadd-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_value_merge_preadd_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_value_merge_preadd_unrolled.expected.log")

# --- THE MIXED **ONWARD** LOOP (bd 3qlq Inc 1, the SECOND C-1 review round,
# --- finding F-C1-2(2a)). The invariant register is a 6.5 classical-call-arm
# --- `%out` rail, so the loop's control is CLASSICAL at round 1 and ROUND-1
# --- `tryCaseA` collapses the carried rail itself — leaving the round-2 pass with
# --- an empty local carried set and clause (iii) refusing on the carried root's
# --- in-body `cq_theta`. 3 mints / 0 `_unc` on 542d588 AND on the round-1 C-1 fix
# --- (41 lines vs the twin's 47). TWO TUs: the classical callee must be visible
# --- and un-inlined for the 6.5 arm to exist at all.
add_test(NAME e2e-slice-control-phase-onward-perbit-loop-mixed
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_onward_perbit_loop_mixed.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/onward_perbit_mixed_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_onward_perbit_loop_mixed.expected.log")

add_test(NAME e2e-slice-control-phase-onward-perbit-loop-mixed-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice_multi.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "${_E2E_LLVM_LINK}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_onward_perbit_loop_mixed_unrolled.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/onward_perbit_mixed_lib.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_onward_perbit_loop_mixed_unrolled.expected.log")

# --- nest vs `&&`: byte-identical BY CONSTRUCTION (`clang -O1` folds both to one
# --- branch on `select i1 %a, i1 %b, false` — MEASURED 2026-09-05, the two
# --- `@slice` bodies are character-for-character equal), plus a genuine depth-2
# --- nest that survives SimplifyCFG's fold threshold.
add_test(NAME e2e-slice-control-phase-nest
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_nest.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_nest.expected.log")

add_test(NAME e2e-slice-control-phase-andcond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_andcond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_andcond.expected.log")

# REMOVED 2026-09-05 (3qlq Inc 1, OQ-7 / prep-b2): `e2e-slice-control-phase-nest-deep`
# and `slice_control_phase_nest_deep.c`. Its inner block carries a `cq_theta` on a
# third register, which makes it a MIXED nest (an Ry in the outer arm, a phase in
# the inner) — PRD §6.3's mixed-arm DECLINE row, not P4. MEASURED on the Increment-1
# SUBJECT and on the pre-3qlq ORACLE alike: exit 1,
# `cq controlled lowering: impure phase arm under quantum control`. A declining
# program has no e2e form; the decline is pinned in lit. The HOMOGENEOUS genuine
# depth-2 nest (P4) keeps its e2e customer in `slice_control_nested_phase.c`.

# --- the angle select. CONSTANT arms and RUN-TIME arms: the Rz kickback computes
# --- NOTHING from the angles (no `fl(A-B)`), so run-time arms are admissible for
# --- this stem where the Ry stem declines them (2b clearance blocker F-11).
add_test(NAME e2e-slice-control-phase-angle-select
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_angle_select.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_angle_select.expected.log")

add_test(NAME e2e-slice-control-phase-angle-select-runtime-arms
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_angle_select_runtime_arms.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_angle_select_runtime_arms.expected.log")

# --- THE THREE TWIN GATES. `cmp` over committed goldens — no clang, no opt, no
# --- plugin, milliseconds. Same construction as the 8h7d.5 rolled-loop and the
# --- drbq 2b angle-select twin gates.
add_test(NAME e2e-phase-grover-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover_loop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_grover_loop_unrolled.expected.log")

add_test(NAME e2e-phase-perbit-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_unrolled.expected.log")

add_test(NAME e2e-phase-perbit-loop-mixed-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_unrolled.expected.log")

# --- bd test_C_libtooling-3qlq.4 (Inc 1b) — the BARE `_Bool` CONDITION: a
# --- `cq_theta_i1` result as a branch/select condition is its own flag (no mint,
# --- no strip, no free; a `¬rail` gate is the diagonal `rz(−θ)`, never a cqrt_x
# --- on a user register). Nine slices — the owner's program (diamond), its `int`
# --- reduction twin, the folded if/else (angle select), `&&` and `==` trees, the
# --- depth-2 nest, the rolled/unrolled invariant-register loop pair, and the flat
# --- one-qubit Grover — plus ONE `cmp` twin gate (rolled == unrolled). ALL STRICT
# --- stage 2b. There is deliberately NO cmp gate between the bool diamond and its
# --- int twin: the witness is a stated three-line REDUCTION (the Inc-4 state-prep
# --- precedent), and a compare_files gate would assert something false.
add_test(NAME e2e-slice-control-phase-bool-diamond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_diamond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_diamond.expected.log")

add_test(NAME e2e-slice-control-phase-bool-int-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_int_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_int_twin.expected.log")

add_test(NAME e2e-slice-control-phase-bool-ifelse
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_ifelse.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_ifelse.expected.log")

add_test(NAME e2e-slice-control-phase-bool-and
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_and.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_and.expected.log")

add_test(NAME e2e-slice-control-phase-bool-eq
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_eq.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_eq.expected.log")

add_test(NAME e2e-slice-control-phase-bool-nest
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_nest.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_nest.expected.log")

add_test(NAME e2e-slice-control-phase-bool-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop.expected.log")

add_test(NAME e2e-slice-control-phase-bool-loop-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_unrolled.expected.log")

add_test(NAME e2e-slice-control-phase-bool-grover
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_grover.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_grover.expected.log")

add_test(NAME e2e-phase-bool-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_unrolled.expected.log")

# ── Track L, bd boi6 H-10 — the two pins for the SHIPPED in-loop carried-_Bool
# ── kickback whose region condition is the IN-BODY chained theta (boi6 p2/p9).
# ── Append to tests/e2e/CMakeLists.txt immediately AFTER the
# ── e2e-phase-bool-loop-twin-identical block (2026-09-13: line 5181), so the
# ── carried-rail pins sit beside the invariant-rail ones they discriminate from.
# ── The two .ll fixtures need NO CMake edit (ir-pass/test/*.ll is globbed).

add_test(NAME e2e-slice-control-phase-bool-carried-theta-first
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_carried_theta_first.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_carried_theta_first.expected.log")

add_test(NAME e2e-slice-control-phase-bool-carried-theta-first-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_carried_theta_first_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_carried_theta_first_unrolled.expected.log")

add_test(NAME e2e-phase-bool-carried-theta-first-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_carried_theta_first.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_carried_theta_first_unrolled.expected.log")

# --- bd test_C_libtooling-r9e5 (Inc 1b-B.1) — the 4.4 DATA SELECT on a bare
# --- `_Bool` (rail-root) condition. `if (b) a -= 3;` is `select i1 %b, …` with
# --- the register itself as the condition; the §5a controlled-XOR copy merge is
# --- unchanged instruction for instruction, and only the FLAG changes: a fresh
# --- |0> i1 ancilla CNOT-copied from the register (never a `cqrt_x` on a user
# --- register — bd memory [diagonal-only-on-user-registers-3qlq4]), un-copied
# --- and freed by the LIFO strip. SEVEN slices — the owner's own `main()`, its
# --- `int` reduction twin, the quantum-operand shape, the S† (the DT prong),
# --- select + kickback on one register, and the rolled/unrolled invariant-rail
# --- loop pair — plus ONE `cmp` twin gate (rolled == unrolled). ALL STRICT
# --- stage 2b. There is deliberately NO cmp gate between the bool slice and its
# --- int twin: the witness is a stated REDUCTION (the Inc-4 state-prep
# --- precedent), and a compare_files gate would assert something false.
add_test(NAME e2e-slice-control-select-bool
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool.expected.log")

# ── bd test_C_libtooling-b6ap — THE MULTI-PHI MERGE PEEL ────────────────────
# Two consecutive source `if`s whose conditions `clang -O1` proves equivalent
# FUSE into one diamond whose merge holds SEVERAL phi; `soleMergePhi` refuses >1
# and the whole program declined `control flow` for a bookkeeping reason.
# `peelIndependentMergePhis` turns each phi the region does not define into a
# tainted-condition `select` on a CLONE of the region's compare (or, for a bare
# rail, on the rail itself). Both slices decline on `main` 0c7380c. STRICT 2b.
add_test(NAME e2e-slice-control-fused-regions-int
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_fused_regions_int.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_fused_regions_int.expected.log")

add_test(NAME e2e-slice-control-fused-regions-phase-bool
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_fused_regions_phase_bool.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_fused_regions_phase_bool.expected.log")

add_test(NAME e2e-slice-control-select-bool-int-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_int_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_int_twin.expected.log")

add_test(NAME e2e-slice-control-select-bool-quantum-arm
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_quantum_arm.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_quantum_arm.expected.log")

add_test(NAME e2e-slice-control-select-bool-sdagger
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_sdagger.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_sdagger.expected.log")

add_test(NAME e2e-slice-control-select-bool-two-regions
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_two_regions.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_two_regions.expected.log")

add_test(NAME e2e-slice-control-select-bool-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_loop.expected.log")

add_test(NAME e2e-slice-control-select-bool-loop-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_loop_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_loop_unrolled.expected.log")

add_test(NAME e2e-select-bool-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_loop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_loop_unrolled.expected.log")

# --- ⚠ REMOVED 2026-09-14 (bd test_C_libtooling-3d8q, OWNER RULING 2026-09-14 —
# --- the stale-reader fence), at the merge gate of that date. The registration
# --- that stood here, `e2e-slice-control-select-bool-round2-window`, is gone and
# --- `slice_control_select_bool_round2_window.expected.log` was DELETED. The
# --- `.c` and its `_lib.c` are KEPT in the tree, unregistered, with the full
# --- record in their headers — the same disposition
# --- `slice_control_switch_phase.c` took on 2026-09-05.
# ---
# --- WHY: the program ends `b = cq_theta(x,.25); …merge…; b3 = cq_theta(x,.9);`
# --- — two SIBLING rotations reading the name `x`, so `b3` names `Ry(0.9)|x>`
# --- while the register holds `Ry(0.9)Ry(0.25)|x>`. That is the P1 stale-reader
# --- class (`docs/frontend.md` §3.2: a rotation consumes the old name), and it
# --- now declines `cq opcode lowering: rotation/measure operand predates a
# --- non-diagonal gate`. The prose kept below argued ORDER, and its argument is
# --- true of the MERGE's read of `b` and silent about `b3`'s own read.
# ---
# --- NO GOLDEN WAS REGENERATED AND NONE COULD BE — see the neutered prose below,
# --- which states the reason itself: a program whose `opt` exits non-zero cannot
# --- be a passing slice in this file. The deleted golden recorded the ORACLE's
# --- circuit for a program the compiler now calls a miscompile.
# ---
# --- THE DECLINE IS PINNED at the layer that can hold it:
# --- `ir-pass/test/control_swap_reject_select_rail_round2_window.ll` carries the
# --- VERBATIM linked stage-1 module of this slice with the diagnostic mirrored
# --- character-for-character, and was validated NON-VACUOUS by binary mutation
# --- (RED on the ORACLE `f7b65d8c`, GREEN on the merged binary). Its cmp twin,
# --- `control_swap_select_cmp_round2_window_accept.ll`, Track D inverted in the
# --- same landing. Converting this slice cost ZERO coverage.
# ---
# --- RETIREMENT TRIGGER (L8): if the open question in that cmp fixture — whether
# --- the CHAINED rewrite is a separate over-decline — resolves as an
# --- over-decline and the chained spelling lowers, RE-REGISTER this slice with a
# --- FRESHLY DERIVED golden. Never restore the deleted one.
# ---
# --- THE ORIGINAL REGISTRATION PROSE, KEPT VERBATIM, EVERY DIRECTIVE NEUTERED:
# --- (was) bd test_C_libtooling-r9e5 (Inc 1b-B.1), Rule-13 ROUND-2 finding
# --- (was) F-B1R2-1 — the TWO ACCEPTS that make `reverifyRailCondReads` a
# --- (was) RE-VERIFICATION rather than a refusal of the round-2 taint window.
# --- (was) The DECLINE half of the pair has no e2e home and is pinned in lit
# --- (was) instead: `run_slice_multi.sh` runs under `set -euo pipefail` and
# --- (was) byte-diffs a golden, so a program whose `opt` exits non-zero cannot
# --- (was) be a passing slice at all (there is no WILL_FAIL and no decline
# --- (was) runner in this file) — the reproducer is committed as its linked
# --- (was) stage-1 module, `ir-pass/test/
# --- (was) control_swap_reject_select_rail_round2_plainc_twotu.ll`.
# --- (was)
# --- (was) The WINDOW slice is TWO TUs, and that is structural: the window needs
# --- (was) a 6.5 classical-call arm, i.e. a callee `clang -O1` cannot inline.
# --- (was) Its sibling theta runs AFTER the merge, so the register the copies
# --- (was) read really is the one the select's condition names, and the DT prong
# --- (was) proves it — the same program with the sibling BEFORE the select is
# --- (was) the confirmed miscompile.
# --- (was) add_test(NAME e2e-slice-control-select-bool-round2-window ... )

add_test(NAME e2e-slice-control-select-bool-round2-opaque-seed
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_round2_opaque_seed.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_bool_round2_opaque_seed.expected.log")

# --- Track A.1 (bd test_C_libtooling-r10v / -9pum / -r903 item (b)) — the
# --- COMPARE-LEAF parity of the two rungs above. Both are ACCEPTS, and both are
# --- DISCRIMINATORS: the increment's whole content is three new DECLINES, so
# --- what the e2e layer has to witness is that the neighbouring correct programs
# --- still lower, byte for byte. The DECLINE half again has no e2e home —
# --- `run_slice*.sh` runs under `set -euo pipefail` and byte-diffs a golden, so
# --- a program whose `opt` exits non-zero cannot be a passing slice — and is
# --- pinned in lit instead (`control_swap_reject_select_cmp_measured_before.ll`,
# --- `..._cmp_inloop_measure_after.ll`, `..._cmp_round2_plainc_twotu.ll`).
# ---
# --- MEASURE-AFTER: the mint must PRECEDE the `cqrt_measure_i32` in the trace.
# --- Move the measure one line up in the source and the program is bd `r903`
# --- item (b) at the select, which ACCEPTED on `main` 0c7380c.
add_test(NAME e2e-slice-control-select-cmp-measure-after
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_cmp_measure_after.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_select_cmp_measure_after.expected.log")

# --- ⚠ REMOVED 2026-09-14 (bd test_C_libtooling-3d8q, OWNER RULING 2026-09-14 —
# --- the stale-reader fence), at the merge gate of that date, for exactly the
# --- reason its bool sibling above was removed: the same two-sibling-rotations
# --- program, the same P1 stale-reader class, the same loud decline
# --- (`cq opcode lowering: rotation/measure operand predates a non-diagonal
# --- gate`). `e2e-slice-control-select-cmp-round2-window` is gone and
# --- `slice_control_select_cmp_round2_window.expected.log` was DELETED; the `.c`
# --- and its `_lib.c` are KEPT, unregistered, with the record in their headers.
# ---
# --- THE DECLINE WAS ALREADY PINNED before this removal: Track D inverted
# --- `ir-pass/test/control_swap_select_cmp_round2_window_accept.ll` — verified at
# --- the merge gate to be the BYTE-IDENTICAL linked stage-1 module of this very
# --- slice — from ACCEPT to DECLINE in the same landing. So this removal is the
# --- second half of that conversion, not a new verdict, and it costs ZERO
# --- coverage. Its RETIREMENT TRIGGER lives in that fixture: if the CHAINED
# --- rewrite proves to be a separate over-decline and is made to lower, this
# --- slice becomes registrable again with a FRESHLY DERIVED golden. Never
# --- restore the deleted one.
# ---
# --- THE ORIGINAL REGISTRATION PROSE, KEPT VERBATIM, EVERY DIRECTIVE NEUTERED:
# --- (was) ROUND-2 WINDOW, COMPARE LEAF: TWO TUs, structurally — the window
# --- (was) needs a 6.5 classical-call arm, i.e. a callee `clang -O1` cannot
# --- (was) inline. The sibling theta runs AFTER the merge, so the register the
# --- (was) copies control on really is the one the compare names, and the DT
# --- (was) prong proves it; the same program with the sibling BEFORE the select
# --- (was) is bd `9pum`, the confirmed miscompile.
# --- (was) add_test(NAME e2e-slice-control-select-cmp-round2-window ... )

# --- Track A.1, Rule-13 ROUND-1 finding F-A1-2 — the ITERATION-LOCAL RAIL pair,
# --- and the ONE ACCEPT-DIRECTION movement in the increment. `main` 0c7380c
# --- DECLINES both of these programs `condition measured before the control
# --- route`; the per-activation barrier in `railMeasuredBeforeReadPoint` lowers
# --- them. The accept is right and the TRACE is the proof: three DISTINCT
# --- handles, one alloc+ry+rz+measure group per trip, so each measurement owns
# --- the register its own trip minted. The twin gate below is what makes that a
# --- measurement rather than an assertion — rolled == hand-unrolled, 12 = 12.
add_test(NAME e2e-slice-control-phase-bool-loop-iterlocal
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_iterlocal.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_iterlocal.expected.log")

add_test(NAME e2e-slice-control-phase-bool-loop-iterlocal-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_iterlocal_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_iterlocal_unrolled.expected.log")

add_test(NAME e2e-phase-bool-loop-iterlocal-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_iterlocal.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_bool_loop_iterlocal_unrolled.expected.log")



# bd 3qlq Inc 1, the SECOND C-1 review round. Each was a rolled != unrolled
# DIVERGENCE on 542d588 AND on the round-1 C-1 fix (32 vs 38, and 41 vs 47).
add_test(NAME e2e-phase-perbit-loop-mixed-preadd-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_preadd.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_mixed_preadd_unrolled.expected.log")

# bd 3qlq Inc 1, the FOURTH C-1 round (F-I2-1): 44 vs 52 on `main` a3c1513.
add_test(NAME e2e-phase-perbit-loop-merge-preadd-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_merge_preadd.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_merge_preadd_unrolled.expected.log")

# bd 3qlq, the FOURTH C-1 round REBASED onto the landed Increment 2: the same
# axis on the Inc-2 controlled-copy VALUE merge's `%out` rail — 52 vs 60 on
# `main` 258d974, 60 = 60 here. This is the row round 4 could only argue.
add_test(NAME e2e-phase-perbit-loop-value-merge-preadd-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_value_merge_preadd.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_perbit_loop_value_merge_preadd_unrolled.expected.log")

add_test(NAME e2e-phase-onward-perbit-loop-mixed-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_onward_perbit_loop_mixed.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_onward_perbit_loop_mixed_unrolled.expected.log")

add_test(NAME e2e-phase-nest-andcond-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_nest.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_andcond.expected.log")

# ENABLED 2026-09-05 (3qlq Inc 1, prep-b2): the `set_tests_properties(... DISABLED
# TRUE)` call that stood here is DELETED. All THIRTEEN goldens now exist and were
# generated on the Increment-1 binary through the full pipeline (stage 1 -> 2 ->
# STRICT 2b -> 3 -> 4) and audited with
# `python3 tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764`.
# (Fourteen entries were registered by prep-b; `e2e-slice-control-phase-nest-deep`
# was REMOVED — see the OQ-7 note above — leaving thirteen.)

# --- bd test_C_libtooling-21mg — `cq_measure` of a value that never became
# --- quantum lowers to the CLASSICAL VALUE (no gate, no rail, no trace line).
# ---
# --- THE SUBJECT is the owner's 2026-09-11 22:18 file (`bool b1 = 0;` never
# --- assigned, then measured), which `main` e96f89c refused outright with
# --- `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle`.
# ---
# --- THE WITNESS IS THE TWIN DIFF, not the golden on its own. A rail minted for
# --- `b1` (the f64/angle miscompile family) or a stray `cqrt_measure_i1` on a
# --- fresh |0> rail would leave a trace that is still self-consistent, still
# --- verify-clean and still STRICT-2b clean — `free_pairing_check.py` witnesses
# --- rail PAIRING, and an extra left-allocated rail is not a pairing violation.
# --- `e2e-measure-classical-bool-twin-identical` byte-diffs the subject's golden
# --- against the golden of the SAME program with `cq_measure(b1)` DELETED, and
# --- that twin golden was independently reproduced byte-for-byte by the ORACLE
# --- binary (2026-09-13), so the identity is measured against the previous
# --- compiler's stream rather than against one this change invented. 15 = 15.
# ---
# --- `slice_measure_classical_only` is the purely-classical corner and the only
# --- slice in this directory with an EMPTY golden: no `cq_theta` anywhere, four
# --- classical measures (constant / derived i32 / f64 `fmul` / `select`), ZERO
# --- `cqrt_*` calls emitted. It is what proves the classical path needs NO new
# --- runtime symbol — it links both archives and references nothing in either.
add_test(NAME e2e-slice-measure-classical-bool
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_bool.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_bool.expected.log")

add_test(NAME e2e-slice-measure-classical-bool-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_bool_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_bool_twin.expected.log")

add_test(NAME e2e-measure-classical-bool-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_bool.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_bool_twin.expected.log")

add_test(NAME e2e-slice-measure-classical-only
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_only.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_measure_classical_only.expected.log")

# --- bd z9t1 (owner ruling 2026-09-14) — THE UNDEF SEED IS A ZERO AT THE
# --- ALLOCATION. Two slices, one per ruled spelling, and the e2e layer is where
# --- the rule is actually WITNESSED rather than inferred:
# ---
# ---   * `slice_undef_seed_uncontrolled` (customer C2a, `bool b; b =
# ---     cq_theta(b,.5);`) already compiled on the 2026-09-13 oracle — SILENTLY,
# ---     handing `i1 undef` to `cqrt_alloc_i1`. The oracle's own trace for that
# ---     program opens `cqrt_alloc_i1(1) -> h0`, a value the program never wrote
# ---     and which the golden byte-diff would then pin as if it were the meaning.
# ---     The golden here opens `cqrt_alloc_i1(0) -> h0`. NO LIT FIXTURE CAN SEE
# ---     THIS: the IR-level check can only say the operand is a constant; only
# ---     the linked run says WHICH value the `-O0` stage 3 materialised.
# ---
# ---   * `slice_undef_seed_in_region` (customer C2b, `bool b; if (c) b =
# ---     cq_theta(b,.5);`) was a LOUD DECLINE on that oracle — F1's `state prep
# ---     seed does not match the merge incoming` — and is the reason the rule is
# ---     stated over the OBJECT: `clang -O1` spells the uninitialized `b1` as
# ---     `undef` twice (the seed AND the merge phi's straight-through incoming),
# ---     and normalizing only the seed leaves F1 comparing `i1 false` against
# ---     `undef`. 19 lines, the same stream the owner's grover file gets for
# ---     `bool b1 = 0;` with only the seed line moved.
# ---
# --- Both run STRICT stage 2b (no `--allow-unproven`): 2 free site(s), 2
# --- verified, 0 violations, 0 unproven — the prepared rails are LEFT ALLOCATED
# --- because `Ry(θ)|0> != |0>` (Rule 6), which is not a pairing violation.
add_test(NAME e2e-slice-undef-seed-uncontrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_undef_seed_uncontrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_undef_seed_uncontrolled.expected.log")

# --- The THIRD entry is the one that turns the rule from a claim into a
# --- measurement. `slice_undef_seed_cascade_twin.c` is
# --- `slice_control_cascade_two_bools.c` — the owner's cascade, landed
# --- 2026-09-13 — with ONE TOKEN changed (`_Bool b1 = 0;` -> `_Bool b1;`), and
# --- `e2e-undef-seed-cascade-twin-identical` byte-diffs its golden against that
# --- shipped one: 29 = 29. A golden of its own could only record whatever this
# --- compiler emits; the TWIN says the uninitialized spelling gets the circuit
# --- the INITIALIZED program already had — the reviewed, Rule-13-cleared,
# --- shipped one — so the rule adds an ACCEPT and not a stream. Same argument as
# --- `e2e-measure-classical-bool-twin-identical`. On the 2026-09-13 oracle that
# --- one deleted `= 0` was the difference between 29 trace lines and a loud F1
# --- decline.
add_test(NAME e2e-slice-undef-seed-cascade-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_undef_seed_cascade_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_undef_seed_cascade_twin.expected.log")

add_test(NAME e2e-undef-seed-cascade-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_undef_seed_cascade_twin.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_cascade_two_bools.expected.log")

add_test(NAME e2e-slice-undef-seed-in-region
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_undef_seed_in_region.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_undef_seed_in_region.expected.log")
# ── bd `3qps` + bd `4aiu` (Track P) — THE REGION-MERGE-φ AS A *PHASE* LEAF ────
# `if (b1) cq_phi(θ)` where `b1` is a preceding controlled state PREP's merge φ,
# plus the interior-leaf form `if (b1 && q > 3) cq_phi(θ)`.
#
#   * `..._mergephi`        the 3qps customer          20 lines  (NEW capability;
#                           lines 7-17 are `slice_control_cascade_two_bools`'s
#                           lines 6-16 BYTE FOR BYTE — the value path did not move)
#   * `..._mergephi_int`    the `int b1` workaround    25 lines  (the spelling the
#                           owner refused; it ALREADY lowered on the frozen ORACLE,
#                           which is what proved 3qps was a LEAF-GRAMMAR
#                           over-decline and not a wire wall — pinned so the
#                           widening cannot change it)
#   * `..._mergephi_tree`   the 4aiu interior leaf     17 lines  (NEW capability)
#   * `..._mergephi_ifelse` both arm polarities         9 lines  (the Rule-7
#                           non-negotiable at the LINK layer: the ¬-arm is the
#                           DIAGONAL `cqrt_rz_i1(h, −θ)`, ZERO `cqrt_x`)
add_test(NAME e2e-slice-control-phase-mergephi
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi.expected.log")

add_test(NAME e2e-slice-control-phase-mergephi-int
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi_int.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi_int.expected.log")

add_test(NAME e2e-slice-control-phase-mergephi-tree
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi_tree.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi_tree.expected.log")

add_test(NAME e2e-slice-control-phase-mergephi-ifelse
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi_ifelse.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_phase_mergephi_ifelse.expected.log")
# ---------------------------------------------------------------------------
# bd `test_C_libtooling-wx8g` (l4x4.c) — THE IN-LOOP BARE-`_Bool` CONTROLLED-Ry
# ARM AND THE ITERATION-LOCAL ROLLED RAIL.
#
# Five pairs, each a ROLLED loop and its HAND-UNROLLED TWIN at CQ_K = 2, with a
# `compare_files` gate over the two committed goldens. The byte-diff is the
# witness this increment turns on: `free_pairing_check.py` counts `cqrt_alloc`
# SITES, so a rolled per-trip alloc reads as ONE rail where the circuit mints K,
# and it is structurally blind to a leaked TEMPLATE-minted rail entirely (its own
# header says so). All ten run STRICT stage 2b regardless.
#
# ⚠ THE ORACLE'S BLIND SPOT, quoted where it lives (the drbq Inc-3 wording,
# unchanged): the unrolled side IS l4x4.b's FLAT lowering, so a defect the two
# paths SHARE is byte-identical on both and these gates report success. The flat
# side's own witness is the l4x4.b lit family.
#
# ⚠ AND THE DERIVED PAIR IS THE ONE THAT CAN SEE THE INCREMENT'S REAL HAZARD.
# The four `_Bool` pairs mint NOTHING for their condition (the register IS the
# flag), so no spine discharge can go missing in them. Only
# `slice_control_inplace_ry_loop_iterlocal_derived` mints template rails in the
# body, and only it can show them being discharged per trip — the decline
# counterpart, with the per-trip register read after the loop instead of inside
# it, is ir-pass/test/control_inplace_ry_reject_inloop_iterlocal_escape.ll, whose
# header carries the measured 19-vs-27 divergence.
#
# K-INDEPENDENCE IS A MEASUREMENT, NOT A GATE, following the 8h7d.5 and drbq
# Inc-3 precedents exactly. MEASURED 2026-09-14, lowered IR WITHOUT `-g` (a `-g`
# line count is not comparable — SCOPE_loop.md §3):
#   see $SES/trackW/IMPL_W.md for the per-slice numbers at -DCQ_K=3 vs 1000.
add_test(NAME e2e-slice-control-inplace-ry-bool-loop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-loop-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_unrolled.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-loop-grover
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_grover.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_grover.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-loop-grover-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_grover_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_grover_unrolled.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-loop-iterlocal
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_iterlocal.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_iterlocal.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-bool-loop-iterlocal-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_iterlocal_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_iterlocal_unrolled.expected.log")

add_test(NAME e2e-slice-control-stateprep-bool-loop-iterlocal
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_loop_iterlocal.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_loop_iterlocal.expected.log")

add_test(NAME e2e-slice-control-stateprep-bool-loop-iterlocal-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_loop_iterlocal_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_loop_iterlocal_unrolled.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-iterlocal-derived
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_iterlocal_derived.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_iterlocal_derived.expected.log")

add_test(NAME e2e-slice-control-inplace-ry-loop-iterlocal-derived-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_iterlocal_derived_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_iterlocal_derived_unrolled.expected.log")

# THE TWIN GATES — `cmp` over the two committed goldens, no clang, no opt, no
# plugin, milliseconds each. These are what turn red if either side of a pair is
# ever regenerated alone.
add_test(NAME e2e-inplace-ry-bool-loop-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_unrolled.expected.log")

add_test(NAME e2e-inplace-ry-bool-loop-grover-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_grover.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_grover_unrolled.expected.log")

add_test(NAME e2e-inplace-ry-bool-loop-iterlocal-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_iterlocal.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_bool_loop_iterlocal_unrolled.expected.log")

add_test(NAME e2e-stateprep-bool-loop-iterlocal-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_loop_iterlocal.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_stateprep_bool_loop_iterlocal_unrolled.expected.log")

add_test(NAME e2e-inplace-ry-loop-iterlocal-derived-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_iterlocal_derived.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_loop_iterlocal_derived_unrolled.expected.log")

# ── bd `test_C_libtooling-tu9q` (2026-09-15) — THE IN-LOOP PAIRING ────────────
# The rolled body now emits the per-trip `_unc` + `cqrt_free` that the FLAT form
# already emitted. These three slices are the only layer that LINKS, so they are
# what proves every emitted `cq_template_*_unc` symbol resolves and
# signature-matches; the twin-identical gate below is the only instrument in the
# tree that can SEE this class at all, because STRICT stage 2b counts `cqrt_alloc`
# SITES and every rail here is TEMPLATE-minted (2b reported `0 violation(s)` on the
# leaking form too — never cite it as clearance for this class).
add_test(NAME e2e-slice-loop-pairing-rootmint
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_rootmint.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_rootmint.expected.log")

add_test(NAME e2e-slice-loop-pairing-rootmint-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_rootmint_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_rootmint_unrolled.expected.log")

# clause (ii-c), the MEASURE-OWNED hoisted invariant rail. NO twin gate: `-O1`
# hoists `y & 1` in the rolled spelling and CSEs it mid-function in the unrolled
# one, so the two streams differ in the POSITION of one gate before the pass runs.
# The gate symbol multiset is identical and the two orderings commute (disjoint
# rails); the slice's own golden is the link + stream witness.
add_test(NAME e2e-slice-loop-pairing-measure-owned
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_measure_owned.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_measure_owned.expected.log")

add_test(NAME e2e-loop-pairing-rootmint-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_rootmint.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_pairing_rootmint_unrolled.expected.log")
# bd test_C_libtooling-jdec — THE VACUITY CHECKER'S OWN GATE, and the same
# argument as e2e-free-pairing-selftest and e2e-loop-twin-quarantine-selftest
# one instrument over. `tools/negative_vacuity_check.py` replaces five divergent
# copies of a throwaway script that PRINTED `checked 0` AND EXITED 0 on a batch
# of 29 real negatives — a result indistinguishable at a glance from "29
# checked, 0 vacuous" — and whose hard-coded `REPO` names worktrees that no
# longer exist. A checker whose failure mode is SILENCE needs a gate whose
# largest layer is "does it refuse to claim a pass when it evaluated nothing":
# five hole cases (no arguments, a batch matching no directive, an empty
# module, a missing compiler, a universe that lowered to nothing) must each
# EXIT 2, four healthy fixtures must come back clean, and each planted vacuity
# must be reported under its own code.
#
# ⚠ THIS IS THE SELFTEST, NOT A CORPUS SWEEP. Running the checker over all of
# `ir-pass/test/*.ll` costs ~1994 `cq-opt` spawns; it is an on-demand
# instrument (like the twin matrices), invoked per accept-fixture BATCH by the
# session protocol, not a per-commit gate. It needs the built plugin, so it
# lives here rather than in ir-pass-lit.
add_test(NAME e2e-negative-vacuity-selftest
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/negative_vacuity_check_test.py")
# ── bd `xdu2` / L-1a Increment W1, THE SECOND HALF (Track B, 2026-09-15) ─────
# The rail BANK: a bounded local array whose cells each hold one quantum rail.
# Until this increment every one of these programs declined `cq taint escape:
# tainted value stored to memory` at every N.
#
# ⚠ EVERY ENTRY RUNS STRICT STAGE 2B (no `--allow-unproven`), and stage 2b counts
# `cqrt_alloc` SITES rather than dynamic mints, so a ROLLED per-trip allocation
# reads as ONE rail per site.  Each slice header carries its own measured 2b line.
#
# ⚠ THE THREE `cqrt_measure_i1` LINES IN THESE GOLDENS ARE THE POINT.  With the
# type rewrite and the D5 allow-list but WITHOUT the taint rule these programs
# give `opt` exit 0, STRICT 2b clean and a plausible SIX-line trace with the
# user's three measurements emitting NOTHING — a golden byte-diff cannot see a
# measurement that was never emitted, so the pieces are one commit.
add_test(NAME e2e-slice-railbank-bool-prep-measureloop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_measureloop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_measureloop.expected.log")

add_test(NAME e2e-slice-railbank-bool-prep-measureloop-zeroinit
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_measureloop_zeroinit.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_measureloop_zeroinit.expected.log")

add_test(NAME e2e-slice-railbank-bool-prep-constidx-measures
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_constidx_measures.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_constidx_measures.expected.log")

add_test(NAME e2e-slice-railbank-int-cells-measureloop
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_int_cells_measureloop.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_int_cells_measureloop.expected.log")

add_test(NAME e2e-slice-railbank-nonmain
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_nonmain.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_nonmain.expected.log")

add_test(NAME e2e-slice-railbank-flat-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_flat_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_flat_twin.expected.log")

# GATE — R2 / owner ruling D1.  The UNINITIALISED bank (`bool b0[3];`) is
# admitted by C6 TOTALITY alone; it does NOT inherit bd `z9t1`'s justification,
# because `normalizeUndefRotationSeed` does not reach a MEMORY seed.  The claim
# that the two spellings denote one program is therefore owed a MEASUREMENT, and
# this is it.  ⚠ It compares TRACES and not IR on purpose: the zero-init twin
# carries an extra `llvm.memset` that an IR diff would report and that no
# emitted gate can see.  MEASURED 2026-09-15: byte-identical, equal sha256
# `0eaaad13…`, 0 divergences.  ⚠ ANY DIVERGENCE HERE RETURNS D1 TO THE OWNER —
# it is a ruling, not an implementation detail.
add_test(NAME e2e-railbank-uninit-zeroinit-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_measureloop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_measureloop_zeroinit.expected.log")

# GATE — the BYTE-IDENTITY WITNESS `SCOPE_L1a.md` §5 asked the capability to
# carry.  The bank's stream must equal the FLAT twin's: three scalar `_Bool`s,
# three preps, three measures, no array anywhere.  Every trip is identical by
# construction in both programs, which is the property that makes the comparison
# meaningful rather than coincidental.  ⚠ What it witnesses is the emitted
# STREAM, not the unitary (Rule 2) and not rail identity (that is stage 2b's,
# and the two programs differ there by construction).
add_test(NAME e2e-railbank-flat-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_bool_prep_measureloop.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_railbank_flat_twin.expected.log")

# ⚠ `slice_railbank_owner_cascade.c` IS DELIBERATELY NOT REGISTERED AND HAS NO
# GOLDEN.  It is the owner's canonical customer program committed as the RECORD
# (owner ruling E4, bd `zwtm`), and it still DECLINES — `cq controlled lowering:
# control flow inside a loop body under quantum control`, wall 3 of four, which
# is `iterationLocalRollable`'s conjunct (c3) / bd `8h7d.11` and is
# BANK-INDEPENDENT.  The e2e layer has no decline shape (`run_slice*.sh` runs
# under `set -euo pipefail` and byte-diffs a golden), so the file follows the
# `slice_control_switch_phase.c` (2026-09-05) and bd-`3d8q` (2026-09-14)
# precedent: KEPT, unregistered, with a conversion header and an L8 retirement
# trigger.  The decline is pinned in the lit layer.  bd `zwtm` closes when
# (c3) + W3 land and this file is registered — NOT when it is committed.

# ── bd `xdu2` / L-1a W1, Rule-13 review F-1 — THE REGISTER-TWIN DECLINE GATE ──
#
# The instrument that sees the class the corpus sweep structurally cannot. That
# sweep's headline safety property is `0 A->D` over a corpus written BEFORE the
# rail-bank capability existed, and F-1 was a `D->A`: a program the REGISTER
# spelling loudly refuses compiled silently through a memory cell, with `opt`
# exit 0, empty stderr, STRICT stage 2b `0 violation(s)` and a plausible
# seven-line trace. `ir-pass-lit`, the 8 e2e railbank entries and every
# twin-IDENTITY gate here were green on it, because none of them contained a
# program of that shape.
#
# This extends the shipped twin discipline (`e2e-railbank-flat-twin-identical`:
# *does the bank MATCH the register spelling when both accept?*) in the
# direction that catches an over-accept:
#   P1  the bank DECLINES whenever the register spelling DECLINES   (a VIOLATION fails)
#   P2  when BOTH accept, the emitted traces are BYTE-IDENTICAL     (a MISMATCH fails)
# The converse — the bank declining where the register spelling accepts — is an
# OVER-DECLINE: counted and printed, never failed on (owner ruling 2026-09-11).
#
# It compiles and runs its own pairs, so it needs the build tree; what it does
# NOT witness is in `tools/railbank_twin_pairs/PAIRS.md`, stated so absence is
# not read as clearance.
add_test(NAME e2e-railbank-register-twin-decline
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/railbank_register_twin_gate.py"
    --build "${CMAKE_BINARY_DIR}"
    --pairs "${CMAKE_SOURCE_DIR}/tools/railbank_twin_pairs"
    --include "${CMAKE_SOURCE_DIR}/include")

# Its MUTANT VALIDATION (CLAUDE.md L10 — "an instrument's failure mode is to
# REPORT A PASS, so the only instrument worth citing is one that has been made
# to FAIL ON PURPOSE"; nine instrument self-failures were measured in the
# 2026-09-14/-15 sessions alone). 20 mutants across two layers: the pure verdict
# table, and the whole driver's EXIT CODE on deliberately broken corpora (empty,
# fabricated violation, fabricated trace mismatch, vacuous half, missing twin).
add_test(NAME e2e-railbank-register-twin-selftest
  COMMAND "${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/railbank_register_twin_gate_test.py"
    --build "${CMAKE_BINARY_DIR}")

# bd `test_C_libtooling-drbq.12` (2026-09-17) - THE LICM-HOISTED LOOP-INVARIANT
# CONDITION. The customer's simplest C spelling, `for (...) { if (q == 5) r =
# cq_theta(r, .9); }` with `r` disjoint from `q`: `q` is loop-invariant, `clang
# -O1` hoists the compare out of the region's `Pred`, and until this bead
# `condWireDisposition`'s P4 precondition refused it before the arm was looked at
# (PRD 13.2 row W, 13.11 worry 7). Registered here because e2e is the only layer
# that LINKS: it proves the newly-admitted program's stream resolves and
# signature-matches, and stage 2b proves its rails pair.
add_test(NAME e2e-slice-control-inplace-ry-inloop-hoisted-cond
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_inloop_hoisted_cond.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_inloop_hoisted_cond.expected.log")

# The HAND-UNROLLED twin of the same source. It is a customer of the SAME fence for
# a DIFFERENT reason - no loop at all, but `-O1` CSEs its two compares into one in
# the entry block, so the SECOND region's `Pred` is the FIRST region's merge. Half
# of row W's sixteen twin-matrix cells are this acyclic shape.
add_test(NAME e2e-slice-control-inplace-ry-inloop-hoisted-cond-twin
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_inloop_hoisted_cond_twin.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_inloop_hoisted_cond_twin.expected.log")

# The witness: `cmp` over the two committed goldens - no clang, no opt, no plugin.
# ROLLED == HAND-UNROLLED, byte for byte. Read it for what it is (owner ruling S3,
# 2026-09-17): identity says the two spellings emit the same gate sequence, NOT that
# either is the right unitary. What it uniquely catches is a rolled/flat DIVERGENCE
# - one source compiling to two different circuits - which no single golden can see.
add_test(NAME e2e-inloop-hoisted-cond-twin-identical
  COMMAND "${CMAKE_COMMAND}" -E compare_files
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_inloop_hoisted_cond.expected.log"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_control_inplace_ry_inloop_hoisted_cond_twin.expected.log")

# Pin the interpreter run_slice.sh / run_slice_multi.sh use for stage 2b to the
# one CMake resolved, so the gate cannot silently fall back to a different (or
# missing) `python3` on PATH. Applied to every test registered in this directory
# — it must stay the LAST statement in this file for that sweep to be complete.
# ── bd `test_C_libtooling-tu9q` piece P2 / bd `test_C_libtooling-1m5p` ────────
# THE HOISTED-CHAIN LOOP-EXIT DISCHARGE, and the program it closes was a LIVE,
# SHIPPING, VERIFY-CLEAN Rule-8 OVER-ACCEPT: on the 2026-09-18 ORACLE
# `9bd01598d574b344` the rolled form compiled at `opt` exit 0 with the LICM-hoisted
# `sqrt((double)a + 3.0)` rail left allocated and ENTANGLED across a non-diagonal
# `cq_theta(a, 0.7)` on the register it copies, which is then measured — 26 trace
# lines against the twin's 28, `cq_template_sqrt_f64_unc` 0 against 1.
#
# ⚠ **NO `*-twin-identical` GATE FOR THIS PAIR, AND THAT IS A DECISION.** The two
# goldens are MULTISET-IDENTICAL and ORDER-DIVERGENT by construction — the rolled
# form discharges the chain at the LOOP EXIT, the twin at function scope after the
# last copy — so a `compare_files` gate would be RED, and a gate expected to be red
# is a gate people stop reading (CLAUDE.md L10). The claim the pair carries is
# COUNT + MULTISET + a commutation argument (everything between the two positions
# READS the chain's members and writes only its own ancillas — disjoint support),
# written out in both slice headers. Owner ruling S3 (2026-09-17): byte identity is
# an INSTRUMENT, not the target.
#
# ⚠ THE ROLLED HALF USED TO RUN WITH `--allow-unproven`, AND IT NO LONGER DOES
# (2026-09-18, Track C's (T4) loop-exit discharge rule). The exception was never a
# concession — it was the INSTRUMENT's reach: `free_pairing_check.py` analysed per
# straight-line STREAM, so a discharge placed at a LOOP EXIT was `U3-extern-rail`
# UNPROVEN *by construction*. (T4) proves that shape instead of excusing it, so the
# slice now runs STRICT like every other one. MEASURED, both at the gate:
#
#   BEFORE (cq-opt 96d74fe6…, pre-(T4) checker):
#     1 verified, 0 violation(s), 3 unproven   [3x U3-extern-rail: %h_intr by
#     cq_template_sqrt_f64, %h_op by …fadd_f64_hl, %h_cast by …sitofp_i32_to_f64]
#   AFTER  (cq-opt 07d93784…, (T4) checker):
#     4 verified, 0 violation(s), 0 unproven   — STRICT rc=0
#
# The rail identities remain pinned POSITIONALLY by
# `ir-pass/test/loop_pairing_accept_hoisted_chain_exit_discharge.ll` as well; that
# pin is belt-and-braces now rather than the only witness.
add_test(NAME e2e-slice-loop-hoisted-chain-exit-discharge
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_hoisted_chain_exit_discharge.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_hoisted_chain_exit_discharge.expected.log")

add_test(NAME e2e-slice-loop-hoisted-chain-exit-discharge-unrolled
  COMMAND bash "${CMAKE_CURRENT_SOURCE_DIR}/run_slice.sh"
    "${_E2E_CLANG}" "${_E2E_OPT}" "$<TARGET_FILE:CQPass>"
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_hoisted_chain_exit_discharge_unrolled.c"
    "$<TARGET_FILE:cq_runtime>" "$<TARGET_FILE:cq_templates>"
    "${CMAKE_CURRENT_SOURCE_DIR}/slice_loop_hoisted_chain_exit_discharge_unrolled.expected.log")

get_property(_E2E_ALL_TESTS DIRECTORY PROPERTY TESTS)
set_tests_properties(${_E2E_ALL_TESTS} PROPERTIES
  ENVIRONMENT "CQ_PYTHON=${_E2E_PYTHON};CQ_LD=${_E2E_LINK_WRAPPER};CQ_S1CACHE=${_E2E_S1_CACHE};CQ_S1_BASE=${_E2E_S1_BASE}")
