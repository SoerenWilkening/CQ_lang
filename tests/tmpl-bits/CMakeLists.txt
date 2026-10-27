# cq-w0-tmpl-bits: differential test of checker/rt/tmpl_bits.c against native x86-64 code.
# gen_native.py writes the LLVM IR operations (native.ll) and the harness table (native.h);
# clang-19 -O1 compiles native.ll for the host. The family source is compiled into the test
# directly (the harness stands in for the two cqe.h functions it calls), so the test does not
# depend on the evaluator core.
set(TB_GEN "${CMAKE_CURRENT_BINARY_DIR}/native")
add_custom_command(
  OUTPUT "${TB_GEN}.ll" "${TB_GEN}.h"
  COMMAND ${Python3_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py" "${TB_GEN}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py"
  COMMENT "tmpl-bits: native reference IR")
add_custom_command(
  OUTPUT "${TB_GEN}.o"
  COMMAND ${CQ_CLANG} -O1 -Wno-override-module -c "${TB_GEN}.ll" -o "${TB_GEN}.o"
  DEPENDS "${TB_GEN}.ll"
  COMMENT "tmpl-bits: clang-19 -O1 native reference")
add_executable(test_tmpl_bits
  "${CMAKE_CURRENT_SOURCE_DIR}/test_tmpl_bits.c"
  "${CMAKE_SOURCE_DIR}/checker/rt/tmpl_bits.c"
  "${TB_GEN}.o" "${TB_GEN}.h")
set_source_files_properties("${TB_GEN}.o" PROPERTIES EXTERNAL_OBJECT TRUE GENERATED TRUE)
target_include_directories(test_tmpl_bits PRIVATE "${CMAKE_SOURCE_DIR}/checker/rt" "${CMAKE_CURRENT_BINARY_DIR}")
set_target_properties(test_tmpl_bits PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON)
target_compile_options(test_tmpl_bits PRIVATE -Wall -Wextra)
add_test(NAME tmpl-bits COMMAND test_tmpl_bits)
# Permanent mutants: the harness must reject every mutated family source (mutants.py).
add_test(NAME tmpl-bits-mutants
  COMMAND ${Python3_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/mutants.py" --clang ${CQ_CLANG}
          --src "${CMAKE_SOURCE_DIR}/checker/rt/tmpl_bits.c" --harness "${CMAKE_CURRENT_SOURCE_DIR}/test_tmpl_bits.c"
          --gen "${CMAKE_CURRENT_BINARY_DIR}" --rt "${CMAKE_SOURCE_DIR}/checker/rt")
