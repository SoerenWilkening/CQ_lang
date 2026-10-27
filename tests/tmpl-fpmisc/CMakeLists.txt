# Differential test of checker/rt/tmpl_fpmisc.c (cq-w0-tmpl-fpmisc) against native x86-64 code:
# gen_native.py writes the IR operations (native.ll) and the case table (cases.inc); clang-19 -O1
# compiles native.ll; diff.c links it with tmpl_fpmisc.c and its own registry (no checker core).
set(FPMISC_GEN ${CMAKE_CURRENT_BINARY_DIR}/gen)
add_custom_command(
  OUTPUT ${FPMISC_GEN}/native.ll ${FPMISC_GEN}/cases.inc
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py ${FPMISC_GEN}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py
  COMMENT "tmpl-fpmisc: generating native reference IR")
add_custom_command(
  OUTPUT ${FPMISC_GEN}/native.o
  COMMAND ${CQ_CLANG} -O1 -Wno-override-module -c ${FPMISC_GEN}/native.ll -o ${FPMISC_GEN}/native.o
  DEPENDS ${FPMISC_GEN}/native.ll
  COMMENT "tmpl-fpmisc: compiling native reference with clang-19 -O1")
set_source_files_properties(${FPMISC_GEN}/native.o PROPERTIES EXTERNAL_OBJECT TRUE GENERATED TRUE)
set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/diff.c PROPERTIES OBJECT_DEPENDS ${FPMISC_GEN}/cases.inc)
add_executable(tmpl_fpmisc_diff ${CMAKE_CURRENT_SOURCE_DIR}/diff.c
               ${CMAKE_SOURCE_DIR}/checker/rt/tmpl_fpmisc.c ${FPMISC_GEN}/native.o)
target_include_directories(tmpl_fpmisc_diff PRIVATE ${CMAKE_SOURCE_DIR}/checker/rt ${FPMISC_GEN})
set_target_properties(tmpl_fpmisc_diff PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON)
target_compile_options(tmpl_fpmisc_diff PRIVATE -O1 -Wall -Wextra)
add_test(NAME tmpl-fpmisc-diff COMMAND tmpl_fpmisc_diff)
