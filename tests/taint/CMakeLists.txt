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
