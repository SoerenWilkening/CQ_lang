# tmpl-int differential test (cq-w0-tmpl-int): checker/rt/tmpl_int.c against the same LLVM IR
# operations compiled by clang-19 -O1 and run on the host.
set(TI_GEN "${CMAKE_CURRENT_BINARY_DIR}/gen")
add_custom_command(
  OUTPUT "${TI_GEN}/native.ll" "${TI_GEN}/cases.inc"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${TI_GEN}"
  COMMAND ${Python3_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py"
          --ll "${TI_GEN}/native.ll" --inc "${TI_GEN}/cases.inc"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/gen_native.py"
  COMMENT "tmpl-int: generating native reference IR")
add_custom_command(
  OUTPUT "${TI_GEN}/native.o"
  COMMAND ${CQ_CLANG} -O1 -target x86_64-apple-macosx -Wno-override-module -c "${TI_GEN}/native.ll" -o "${TI_GEN}/native.o"
  DEPENDS "${TI_GEN}/native.ll"
  COMMENT "tmpl-int: clang-19 -O1 native.ll")

add_executable(tmpl_int_diff
  harness.c fake_cqe.c
  "${CMAKE_SOURCE_DIR}/checker/rt/tmpl_int.c"
  "${TI_GEN}/native.o" "${TI_GEN}/cases.inc")
set_source_files_properties("${TI_GEN}/native.o" PROPERTIES EXTERNAL_OBJECT TRUE GENERATED TRUE)
target_include_directories(tmpl_int_diff PRIVATE "${CMAKE_SOURCE_DIR}/checker/rt" "${CMAKE_CURRENT_SOURCE_DIR}" "${TI_GEN}")
set_target_properties(tmpl_int_diff PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON)
target_compile_options(tmpl_int_diff PRIVATE -Wall -Wextra -O1)
add_test(NAME tmpl-int COMMAND tmpl_int_diff)
