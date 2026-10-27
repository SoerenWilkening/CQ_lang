# The checker runtime (scaffold): every checker/rt/*.c, C17, one static library linked with the
# program under test. Adding a family file (checker/rt/tmpl_*.c, rt_*.c) never touches this file.
file(GLOB CQE_RT_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/rt/*.c")
add_library(cqe_rt STATIC ${CQE_RT_SOURCES})
target_include_directories(cqe_rt PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/rt")
set_target_properties(cqe_rt PROPERTIES C_STANDARD 17 C_STANDARD_REQUIRED ON POSITION_INDEPENDENT_CODE ON)
target_compile_options(cqe_rt PRIVATE -Wall -Wextra)
