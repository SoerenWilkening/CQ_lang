# CTest schedules (routine gate revised after the 2026-09-30 runtime audit).
#
#   Fast:        ctest --test-dir build -LE heavy -j6
#   Batch:       ctest --test-dir build -LE maintenance -j6
#   Maintenance: ctest --test-dir build -L maintenance -j6
#   Full:        ctest --test-dir build -j6
#
# Heavy matrices exercise compiler behavior and remain in the batch gate.
# Maintenance validates the scrub checker's own mutant corpus. Run it when
# that checker, its tracked types, scrub selftest or compiler configuration
# changes; see CLAUDE.md R15. Three shards historically took 1042-1159 s each.
# The ordinary taintset-scrub-guard and executable scrub tests remain in both
# the fast and batch schedules.
#
# Apply labels by name after every test has been registered. CMake < 3.28
# cannot label tests across directories, so filtered schedules run everything
# there and configure emits a warning.
set(CQ_MAINTENANCE_TEST_PATTERN "^taintset-scrub-guard-selftest")
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
    message(WARNING "cq: CMake ${CMAKE_VERSION} < 3.28 — test labels are not applied; "
                    "filtered schedules run the full suite.")
    return()
  endif()
  set(_stack "${dir}")
  set(_matched "")
  set(_nheavy 0)
  set(_nmaintenance 0)
  while(_stack)
    list(POP_FRONT _stack _d)
    get_property(_subs DIRECTORY "${_d}" PROPERTY SUBDIRECTORIES)
    list(APPEND _stack ${_subs})
    get_property(_tests DIRECTORY "${_d}" PROPERTY TESTS)
    foreach(_t IN LISTS _tests)
      if(_t MATCHES "${CQ_MAINTENANCE_TEST_PATTERN}")
        set_property(TEST "${_t}" DIRECTORY "${_d}" APPEND PROPERTY LABELS maintenance)
        math(EXPR _nmaintenance "${_nmaintenance} + 1")
      endif()
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
  if(_nmaintenance EQUAL 0)
    message(WARNING "cq test tiers: no scrub-guard maintenance tests found")
  endif()
  message(STATUS "cq test tiers: ${_nmaintenance} maintenance entr(y/ies) "
                 "(batch gate: ctest -LE maintenance)")
  message(STATUS "cq test tiers: ${_nheavy} entr(y/ies) labelled `heavy` "
                 "(fast tier: ctest -LE heavy)")
endfunction()
