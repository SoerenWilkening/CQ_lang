# tests/mem-slots (cq-w1-mem-slots): rule 20 probes and the owned examples through the real cq-lower plugin.
add_test(NAME mem-slots
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/run_mem_slots.py
          --plugin $<TARGET_FILE:CQLower> --opt ${CQ_OPT} --spec ${CQ_SPEC_DIR}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

# M1 (cq-arch 2026-11-01): mem::slotCellsBeforeCall / slotCellsAfterCall. Linked with every pass module
# except calls/Calls.cpp, whose lowerLifted the test supplies (a test double doing what M1 asks of calls);
# the cells the clone writes come from mem-slots' seam (pass/lib/mem/slots/SlotsTest.h) while T2 is a stub.
add_executable(mem_slots_slot_cells slot_cells.cpp
  $<FILTER:$<TARGET_OBJECTS:cq_pass_objs>,EXCLUDE,/calls/Calls\.cpp\.o$>)
target_include_directories(mem_slots_slot_cells PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(mem_slots_slot_cells PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_DEFINITIONS>)
target_compile_options(mem_slots_slot_cells PRIVATE $<TARGET_PROPERTY:cq_pass_objs,INTERFACE_COMPILE_OPTIONS>)
add_dependencies(mem_slots_slot_cells cq_pass_objs)
target_link_libraries(mem_slots_slot_cells PRIVATE LLVM)
add_test(NAME mem_slots_slot_cells COMMAND mem_slots_slot_cells)
