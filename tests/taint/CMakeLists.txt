# Module taint (cq-w0-taint). cq_taint_dump prints TaintInfo::print for one module; check_taint.py
# compares it with every example's reference (the bead's acceptance).
add_executable(cq_taint_dump taint_dump.cpp)
target_link_libraries(cq_taint_dump PRIVATE cq_pass_objs LLVM)
add_test(NAME taint
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_taint.py
          --dump $<TARGET_FILE:cq_taint_dump> --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
# cq-0ia: lookups of unmarked classical values answer 'classical'; a value created after taint errors.
cq_add_unit_test(taint_lookup taint_lookup.cpp)
# cq-pu8b: rule 23's environment state point-wise (blocks, loops, calls, fenv_t objects).
cq_add_unit_test(taint_fenv taint_fenv.cpp)
# cq-820w: an edge into a dead end does not restrict its siblings (control dependence, rule 16).
cq_add_unit_test(taint_deadend taint_deadend.cpp)
target_compile_definitions(taint_deadend PRIVATE CQ_SPEC_DIR="${CQ_SPEC_DIR}")
# cq-1v3i: a loop's exit value (rule 14, quantum exit) is quantum in every reader after the loop.
cq_add_unit_test(taint_exitread taint_exitread.cpp)
# cq-41y3: rule 2, a read of a measured value its measurement dominates is classical (the outcome).
cq_add_unit_test(taint_measured taint_measured.cpp)
# cq-cvwx: a known library function writing only through its pointer arguments (frexp, modf) with a
# quantum argument is a declared clone (rule 27), not a host effect (rule 16); its pointee holds a handle.
cq_add_unit_test(taint_libwriter taint_libwriter.cpp)
# cq-bxc4: a phi at a join that depends on a tainted terminator is chosen by it when the incoming edge
# still depends on it given the join (shared/fallthrough case blocks, if/else-if joins).
cq_add_unit_test(taint_joinchoice taint_joinchoice.cpp)
target_compile_definitions(taint_joinchoice PRIVATE CQ_SPEC_DIR="${CQ_SPEC_DIR}")
# cq-wxch: a loop exit through select c, t, true / select c, false, f / xor x, true keeps its
# classical disjunct (rule 14 case 3).
cq_add_unit_test(taint_exitselect taint_exitselect.cpp)
