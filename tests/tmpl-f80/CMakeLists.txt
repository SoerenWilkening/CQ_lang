# cq-w0-tmpl-f80: differential test of checker/rt/tmpl_f80.c against native x86-64 code (the same
# LLVM IR operations compiled by clang-19 -O1 for the corpus CPU penryn), CR §2 rows that differ
# from native checked against the table. The harness links tmpl_f80.c with its own core shim.
set(F80_GEN "${CMAKE_CURRENT_BINARY_DIR}/gen")
add_custom_command(
  OUTPUT "${F80_GEN}/native.ll" "${F80_GEN}/cases.inc"
  COMMAND ${Python3_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py" "${F80_GEN}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py"
  COMMENT "tmpl-f80: native reference IR")
add_custom_command(
  OUTPUT "${F80_GEN}/native.o"
  COMMAND ${CQ_CLANG} -O1 -march=penryn -target x86_64-apple-macosx -Wno-override-module
          -c "${F80_GEN}/native.ll" -o "${F80_GEN}/native.o"
  DEPENDS "${F80_GEN}/native.ll"
  COMMENT "tmpl-f80: clang -O1 native reference")
set_source_files_properties("${F80_GEN}/native.o" PROPERTIES EXTERNAL_OBJECT TRUE GENERATED TRUE)
add_executable(tmpl_f80_diff
  "${CMAKE_CURRENT_SOURCE_DIR}/harness.c"
  "${CMAKE_SOURCE_DIR}/checker/rt/tmpl_f80.c"
  "${F80_GEN}/native.o"
  "${F80_GEN}/cases.inc")
target_include_directories(tmpl_f80_diff PRIVATE "${F80_GEN}" "${CMAKE_SOURCE_DIR}/checker/rt")
set_target_properties(tmpl_f80_diff PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON)
target_compile_options(tmpl_f80_diff PRIVATE -march=penryn)
add_test(NAME tmpl-f80-diff COMMAND tmpl_f80_diff 3000)
