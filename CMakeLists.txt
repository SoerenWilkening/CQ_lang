# CQ_lang build (scaffold). Toolchain: brew llvm@19 (19.1.7), never Apple clang.
#   cmake -S . -B build -G Ninja && cmake --build build && ctest --test-dir build
cmake_minimum_required(VERSION 3.20)

set(CQ_LLVM_PREFIX "/usr/local/opt/llvm@19" CACHE PATH "brew llvm@19 prefix")
if(NOT CMAKE_C_COMPILER)
  set(CMAKE_C_COMPILER "${CQ_LLVM_PREFIX}/bin/clang")
endif()
if(NOT CMAKE_CXX_COMPILER)
  set(CMAKE_CXX_COMPILER "${CQ_LLVM_PREFIX}/bin/clang++")
endif()

project(CQ_lang LANGUAGES C CXX)

foreach(lang C CXX)
  if(NOT CMAKE_${lang}_COMPILER_ID STREQUAL "Clang" OR NOT CMAKE_${lang}_COMPILER_VERSION VERSION_EQUAL 19.1.7)
    message(FATAL_ERROR "cq: ${lang} compiler must be brew llvm@19 clang 19.1.7, got "
                        "${CMAKE_${lang}_COMPILER_ID} ${CMAKE_${lang}_COMPILER_VERSION} (${CMAKE_${lang}_COMPILER})")
  endif()
endforeach()

find_package(LLVM 19.1.7 EXACT REQUIRED CONFIG HINTS "${CQ_LLVM_PREFIX}/lib/cmake/llvm" NO_DEFAULT_PATH)
message(STATUS "cq: LLVM ${LLVM_PACKAGE_VERSION} at ${LLVM_DIR}")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

find_package(Python3 REQUIRED COMPONENTS Interpreter)
set(CQ_OPT "${CQ_LLVM_PREFIX}/bin/opt")
set(CQ_CLANG "${CQ_LLVM_PREFIX}/bin/clang")
set(CQ_SPEC_DIR "${CMAKE_SOURCE_DIR}/spec" CACHE PATH "pinned CQ_spec checkout (read-only)")

enable_testing()

add_subdirectory(pass)
add_subdirectory(checker)

# cq_add_unit_test(<name> <sources...>): a C++ test linked with every pass module and libLLVM.
# A bead calls it from tests/<module>/CMakeLists.txt; no shared file changes.
function(cq_add_unit_test name)
  add_executable(${name} ${ARGN})
  target_link_libraries(${name} PRIVATE cq_pass_objs LLVM)
  add_test(NAME ${name} COMMAND ${name})
endfunction()

# cq_add_python_unit_classes(<prefix> <script> <workdir> <env>): one test <prefix>-<Class> per
# unittest.TestCase class of <script>, each under heavy.sh's cap on its own (cq-fbii, owner
# 2026-11-01: a suite that only passes per class is registered per class). New classes register on
# the next configure.
function(cq_add_python_unit_classes prefix script workdir env)
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${script}")
  file(STRINGS "${script}" lines REGEX "^class [A-Za-z0-9_]+\\(unittest\\.TestCase\\)")
  if(NOT lines)
    message(FATAL_ERROR "cq: no unittest.TestCase class in ${script}")
  endif()
  foreach(l ${lines})
    string(REGEX REPLACE "^class ([A-Za-z0-9_]+).*" "\\1" cls "${l}")
    add_test(NAME ${prefix}-${cls}
      COMMAND ${Python3_EXECUTABLE} ${script} -v ${cls}
      WORKING_DIRECTORY ${workdir})
    set_tests_properties(${prefix}-${cls} PROPERTIES ENVIRONMENT "${env}" TIMEOUT 600)
  endforeach()
endfunction()

file(GLOB CQ_TEST_CMAKE CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/tests/*/CMakeLists.txt")
foreach(f ${CQ_TEST_CMAKE})
  get_filename_component(d "${f}" DIRECTORY)
  add_subdirectory("${d}")
endforeach()

add_custom_target(check-spec
  COMMAND ${Python3_EXECUTABLE} tools/spec_lock.py
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "cq: spec.lock against ${CQ_SPEC_DIR}"
  USES_TERMINAL)
add_test(NAME spec-lock COMMAND ${Python3_EXECUTABLE} tools/spec_lock.py WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
