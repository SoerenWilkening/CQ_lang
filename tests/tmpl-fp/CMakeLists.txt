# cq-w0-tmpl-fp: differential test of checker/rt/tmpl_fp.c against native.ll compiled by
# clang-19 -O1 for the corpus triple. Links the family file directly (the test defines the two
# cqe.h functions it calls), so it does not depend on the evaluator core.
set(TMPL_FP_NATIVE_O "${CMAKE_CURRENT_BINARY_DIR}/tmpl_fp_native.o")
add_custom_command(
  OUTPUT "${TMPL_FP_NATIVE_O}"
  COMMAND ${CQ_CLANG} -O1 --target=x86_64-apple-macosx -c "${CMAKE_CURRENT_SOURCE_DIR}/native.ll" -o "${TMPL_FP_NATIVE_O}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/native.ll"
  COMMENT "cq: tmpl-fp native reference (clang-19 -O1)")
add_executable(test_tmpl_fp
  "${CMAKE_CURRENT_SOURCE_DIR}/test_tmpl_fp.c"
  "${CMAKE_SOURCE_DIR}/checker/rt/tmpl_fp.c"
  "${TMPL_FP_NATIVE_O}")
target_include_directories(test_tmpl_fp PRIVATE "${CMAKE_SOURCE_DIR}/checker/rt")
set_target_properties(test_tmpl_fp PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON)
target_compile_options(test_tmpl_fp PRIVATE -O1 -Wall -Wextra)
add_test(NAME tmpl-fp COMMAND test_tmpl_fp)
set_tests_properties(tmpl-fp PROPERTIES TIMEOUT 300)
