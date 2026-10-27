# The pass (scaffold). Every module's sources are globbed: adding a .cpp inside a module directory
# (pass/lib/<module>/) never touches this file.
file(GLOB_RECURSE CQ_MODULE_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/lib/*.cpp")
list(REMOVE_ITEM CQ_MODULE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/lib/Plugin.cpp")

# Every module, Plugin.cpp excepted: linked into the plugin and into unit tests.
add_library(cq_pass_objs OBJECT ${CQ_MODULE_SOURCES})
target_include_directories(cq_pass_objs PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(cq_pass_objs SYSTEM PUBLIC ${LLVM_INCLUDE_DIRS})
separate_arguments(CQ_LLVM_DEFS NATIVE_COMMAND "${LLVM_DEFINITIONS}")
target_compile_definitions(cq_pass_objs PUBLIC ${CQ_LLVM_DEFS})
target_compile_options(cq_pass_objs PUBLIC -Wall -Wextra -Wno-unused-parameter -fvisibility-inlines-hidden)
if(NOT LLVM_ENABLE_RTTI)
  target_compile_options(cq_pass_objs PUBLIC -fno-rtti)
endif()
set_target_properties(cq_pass_objs PROPERTIES POSITION_INDEPENDENT_CODE ON)

# build/pass/libCQLower.so. LLVM symbols resolve against the opt that loads it (libLLVM.dylib);
# linking LLVM in as well would register every cl::opt twice.
add_library(CQLower MODULE lib/Plugin.cpp)
target_link_libraries(CQLower PRIVATE cq_pass_objs)
set_target_properties(CQLower PROPERTIES
  PREFIX "lib" SUFFIX ".so"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/pass")
if(APPLE)
  target_link_options(CQLower PRIVATE -undefined dynamic_lookup)
endif()
