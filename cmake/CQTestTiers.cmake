# cmake/CQTestTiers.cmake — the TWO-TIER ctest suite (owner ruling 2026-09-29,
# bd test_C_libtooling-2dfk; bd memory owner-ruling-batch-gate-two-tier-2026-09-29).
#
#   FAST tier  : ctest --test-dir build -LE heavy -j6   (intermediate merges)
#   FULL suite : ctest --test-dir build -j6             (the BATCH gate on main)
#
# The FULL suite has NO label filter, so it runs every entry whatever this file
# says — a pattern here can only ever move an entry OUT OF THE FAST TIER, never
# out of the gate. That asymmetry is the whole safety argument: a wrong or stale
# pattern costs fast-tier coverage (the batch gate still runs the entry) and can
# never make the batch gate skip anything.
#
# WHAT IS HEAVY. The matrices and the instrument self-tests: entries that
# re-derive a whole DISPOSITION TABLE by compiling many generated programs, as
# opposed to one slice / one fixture. Measured at this session's three merge gates
# (load 40-65 on 12 threads, 2026-09-29), the ten entries below are the ten
# slowest non-`ir-pass-lit` entries of the 570 (64-2040 s each; 3 829 s of the
# 13 858 s summed test time at the cepm gate). `ir-pass-lit` is slow too and is
# deliberately FAST tier: it is the one layer every change must witness.
#
# THE LABEL IS APPLIED BY PATTERN, NOT BY EDITING EACH add_test. Tests are
# registered by several parallel tracks at once (the e2e CMakeLists is the
# hottest file in the tree), and a label written at the call site is a label the
# next track forgets. `^taintset-scrub-guard-selftest` deliberately matches both
# today's single entry and a sharded `-selftest-<n>` spelling.
#
# Requires CMake >= 3.28 (set_property/get_property on another directory's
# tests). On an older CMake no label is applied and the FAST tier degrades to the
# FULL suite — slower, never weaker — and configure says so.
set(CQ_HEAVY_TEST_PATTERNS
  "^e2e-loop-twin-matrix$"
  "^e2e-railbank-[a-z-]+-matrix$"
  "^e2e-condtree-classical-leaf-matrix$"
  "^e2e-railbank-register-twin-(decline|selftest)$"
  "^taintset-scrub-guard-selftest"
)

# Label every test registered under DIR (recursively) whose name matches a
# CQ_HEAVY_TEST_PATTERNS entry. Call ONCE, at the END of the top-level
# CMakeLists.txt, after every add_subdirectory — a test registered after the
# call is not seen.
function(cq_apply_test_tiers dir)
  if(CMAKE_VERSION VERSION_LESS 3.28)
    message(WARNING "cq: CMake ${CMAKE_VERSION} < 3.28 — the `heavy` ctest label "
                    "is not applied, so `ctest -LE heavy` runs the FULL suite.")
    return()
  endif()
  set(_stack "${dir}")
  set(_matched "")
  set(_nheavy 0)
  while(_stack)
    list(POP_FRONT _stack _d)
    get_property(_subs DIRECTORY "${_d}" PROPERTY SUBDIRECTORIES)
    list(APPEND _stack ${_subs})
    get_property(_tests DIRECTORY "${_d}" PROPERTY TESTS)
    foreach(_t IN LISTS _tests)
      foreach(_p IN LISTS CQ_HEAVY_TEST_PATTERNS)
        if(_t MATCHES "${_p}")
          set_property(TEST "${_t}" DIRECTORY "${_d}" APPEND PROPERTY LABELS heavy)
          list(APPEND _matched "${_p}")
          math(EXPR _nheavy "${_nheavy} + 1")
          break()
        endif()
      endforeach()
    endforeach()
  endwhile()
  # A pattern that matches nothing is a RENAMED or DELETED heavy entry that is
  # now silently in the fast tier. Not an error (the full suite still runs it),
  # but say so, loudly enough to be fixed.
  foreach(_p IN LISTS CQ_HEAVY_TEST_PATTERNS)
    if(NOT _p IN_LIST _matched)
      message(WARNING "cq test tiers: heavy pattern `${_p}` matches no test — "
                      "update cmake/CQTestTiers.cmake")
    endif()
  endforeach()
  message(STATUS "cq test tiers: ${_nheavy} entr(y/ies) labelled `heavy` "
                 "(fast tier: ctest -LE heavy)")
endfunction()
