#-------------------------------------------------------------------------------
#   emscripten.toolchain.cmake
#   Fips cmake toolchain file for cross-compiling to emscripten.
#
#   The following cmake defines must be passed on the command line:
#
#   EMSCRIPTEN_EMSDK:   absolute path to the emsdk directory
#   EMSCRIPTEN_ROOT:    absolute path to the directory with emcc and system/includes
#-------------------------------------------------------------------------------

set(FIPS_PLATFORM EMSCRIPTEN)
set(FIPS_PLATFORM_NAME "emsc")
set(FIPS_EMSCRIPTEN 1)
set(FIPS_POSIX 1)

find_package(Java COMPONENTS Runtime)

# tweakable options 
option(FIPS_EMSCRIPTEN_USE_FS "enable FS module" OFF)
option(FIPS_EMSCRIPTEN_USE_DFE "enable Duplicate Function Elimination" OFF)
option(FIPS_EMSCRIPTEN_USE_WASM "enable WebAssembly" ON)
option(FIPS_EMSCRIPTEN_USE_SAFE_HEAP "enable SAFE_HEAP checks" OFF)
option(FIPS_EMSCRIPTEN_USE_CPU_PROFILER "enable the built-in CPU profiler" OFF)
option(FIPS_EMSCRIPTEN_USE_MEMORY_PROFILER "enable the built-in memory profiler" OFF)
option(FIPS_EMSCRIPTEN_USE_WEBGL2 "use WebGL2" OFF)
option(FIPS_EMSCRIPTEN_USE_CLOSURE "run closure compiler on JS code" OFF)
option(FIPS_EMSCRIPTEN_USE_EMMALLOC "use emmalloc allocator" OFF)
option(FIPS_EMSCRIPTEN_USE_EMBIND "use embind" OFF)
option(FIPS_EMSCRIPTEN_ALLOW_MEMORY_GROWTH "allow memory growth" ON)
option(FIPS_EMSCRIPTEN_USE_WASM_TRAP_MODE_CLAMP "use trap-mode clamp for wasm" OFF)
option(FIPS_EMSCRIPTEN_DEMANGLE "compile with libcxxabi-provided demangling support" OFF)
option(FIPS_EMSCRIPTEN_USE_FETCH "use fetch API" OFF)
option(FIPS_EMSCRIPTEN_USE_MINIMAL_RUNTIME "use the minimal JS runtime" OFF)
set(FIPS_EMSCRIPTEN_TOTAL_MEMORY 280494080 CACHE STRING "initial heap size in bytes")
set(FIPS_EMSCRIPTEN_LTO_LEVEL 1 CACHE STRING "link-time-optimization level (0..3)")
set(FIPS_EMSCRIPTEN_MEM_INIT_METHOD 1 CACHE STRING "how to represent initial memory content (0..2)")
set(FIPS_EMSCRIPTEN_SHELL_HTML "shell.html" CACHE STRING "path to shell html file")

if (FIPS_EMSCRIPTEN_RELATIVE_SHELL_HTML)
    set(FIPS_EMSCRIPTEN_SHELL_HTML "${CMAKE_SOURCE_DIR}/${FIPS_EMSCRIPTEN_RELATIVE_SHELL_HTML}")
endif()

set(EMSC_COMMON_FLAGS)
set(EMSC_CXX_FLAGS)
set(EMSC_LINKER_FLAGS)
set(EMSC_LINKER_FLAGS_RELEASE)
set(EMSC_EXE_LINKER_FLAGS)
set(EMSC_AR_FLAGS)

set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} --memory-init-file ${FIPS_EMSCRIPTEN_MEM_INIT_METHOD}")
set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s TOTAL_MEMORY=${FIPS_EMSCRIPTEN_TOTAL_MEMORY}")
set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s ERROR_ON_UNDEFINED_SYMBOLS=1")
set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s NO_EXIT_RUNTIME=1")

if (FIPS_EMSCRIPTEN_ALLOW_MEMORY_GROWTH)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s ALLOW_MEMORY_GROWTH=1")
endif()

if (FIPS_EMSCRIPTEN_USE_WASM_TRAP_MODE_CLAMP)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s \"BINARYEN_TRAP_MODE='clamp'\"")
endif()
if (FIPS_PROFILING)
    set(EMSC_TRACING 1)
    set(EMSC_COMMON_FLAGS "${EMSC_COMMON_FLAGS} --tracing")
else()
    set(EMSC_TRACING 0)
endif()
if (FIPS_EMSCRIPTEN_USE_SAFE_HEAP)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s SAFE_HEAP=1")
endif()
if (FIPS_EMSCRIPTEN_USE_WEBGL2)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s USE_WEBGL2=1")
endif()
if (FIPS_EMSCRIPTEN_USE_EMMALLOC)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s \"MALLOC='emmalloc'\"")
endif()
if (FIPS_EMSCRIPTEN_USE_EMBIND)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} --bind")
endif()
if (FIPS_EMSCRIPTEN_USE_FS)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s NO_FILESYSTEM=0")    
else()
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s NO_FILESYSTEM=1")
endif()
if (FIPS_EMSCRIPTEN_USE_DFE)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s ELIMINATE_DUPLICATE_FUNCTIONS=1")
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s ELIMINATE_DUPLICATE_FUNCTIONS_DUMP_EQUIVALENT_FUNCTIONS=1")
endif()
if (FIPS_COMPILE_VERBOSE)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s VERBOSE=1")
endif()
if (FIPS_EMSCRIPTEN_USE_CPU_PROFILER)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} --cpuprofiler")
endif()
if (FIPS_EMSCRIPTEN_USE_MEMORY_PROFILER)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} --memoryprofiler")
endif()
set(EMSCRIPTEN_OPT "-O3")
if (FIPS_EXCEPTIONS)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s DISABLE_EXCEPTION_CATCHING=0")
else()
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s DISABLE_EXCEPTION_CATCHING=1")
    set(EMSC_CXX_FLAGS "${EMSC_CXX_FLAGS} -fno-exceptions")
endif()
if (NOT FIPS_RTTI)
    set(EMSC_CXX_FLAGS "${EMSC_CXX_FLAGS} -fno-rtti")
endif()
set(EMSC_LINKER_FLAGS_RELEASE "${EMSC_LINKER_FLAGS_RELEASE} --llvm-lto ${FIPS_EMSCRIPTEN_LTO_LEVEL}")
if (FIPS_EMSCRIPTEN_USE_WASM)    
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s WASM=1")
else()
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s WASM=0")
    set(EMSC_LINKER_FLAGS_RELEASE "${EMSC_LINKER_FLAGS_RELEASE}")
endif()
if (FIPS_EMSCRIPTEN_USE_CLOSURE)
    if (Java_FOUND)
        set(EMSC_LINKER_FLAGS_RELEASE "${EMSC_LINKER_FLAGS_RELEASE} --closure 1")
    else()
        message(WARNING "skipping emscripten closure pass because no Java runtime found")
    endif()
endif()
if (FIPS_EMSCRIPTEN_DEMANGLE)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s DEMANGLE_SUPPORT=1")
endif()
set(EMSC_LINKER_FLAGS_RELEASE "${EMSC_LINKER_FLAGS_RELEASE} -s ASSERTIONS=0")
if (FIPS_EMSCRIPTEN_USE_FETCH)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s FETCH=1")
endif()
if (FIPS_EMSCRIPTEN_USE_MINIMAL_RUNTIME)
    set(EMSC_LINKER_FLAGS "${EMSC_LINKER_FLAGS} -s MINIMAL_RUNTIME=2 -s ENVIRONMENT=web")
endif()

set(EMSC_EXE_LINKER_FLAGS "${EMSC_EXE_LINKER_FLAGS} --shell-file ${FIPS_EMSCRIPTEN_SHELL_HTML}")

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_VERSION 1)
set(COMPILING ON)
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_SYSTEM_PROCESSOR x86)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)

# Find the .emscripten file and cache, this is either setup locally in the
# emscripten SDK (this is the preferred way and used by 'fips setup emscripten',
# but it's a brand new feature: https://github.com/juj/emsdk/issues/24)
# If an SDK-local .emscripten is not found, fall back to ~/.emscripten
get_filename_component(EMSCRIPTEN_DOT_FILE "${EMSCRIPTEN_EMSDK}/.emscripten" ABSOLUTE)
if (EMSCRIPTEN_TRACING)
    # set a separate .emscripten_cache when tracing since this will use an 
    # instrumented dlmalloc.c
    get_filename_component(EMSCRIPTEN_CACHE "${EMSCRIPTEN_EMSDK}/.emscripten_cache_tracing" ABSOLUTE)
else()
    get_filename_component(EMSCRIPTEN_CACHE "${EMSCRIPTEN_EMSDK}/.emscripten_cache" ABSOLUTE)
endif()
if (EXISTS "${EMSCRIPTEN_DOT_FILE}")
    set(EMSC_COMMON_FLAGS "${EMSC_COMMON_FLAGS} --em-config ${EMSCRIPTEN_DOT_FILE} --cache ${EMSCRIPTEN_CACHE}")
    set(EMSC_AR_FLAGS "${EMSC_AR_FLAGS} --em-config ${EMSCRIPTEN_DOT_FILE}")
else()
    # no sdk-embedded config found, use the default (~/.emscripten and ~/.emscripten_cache)
    # message(WARNING "Using global emscripten config and cache in '~'!")
endif()

# tool suffic (.bat on windows)
if (CMAKE_HOST_WIN32)
    set(EMCC_SUFFIX ".bat")
else()
    set(EMCC_SUFFIX "")
endif()

# define configurations
set(CMAKE_CONFIGURATION_TYPES Debug Release Profiling)

# specify cross-compilers
set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT}/emcc${EMCC_SUFFIX}" CACHE PATH "gcc" FORCE)
set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT}/em++${EMCC_SUFFIX}" CACHE PATH "g++" FORCE)
set(CMAKE_AR "${EMSCRIPTEN_ROOT}/emar${EMCC_SUFFIX}" CACHE PATH "archive" FORCE)
set(CMAKE_LINKER "${EMSCRIPTEN_ROOT}/emcc${EMCC_SUFFIX}" CACHE PATH "linker" FORCE)
set(CMAKE_RANLIB "${EMSCRIPTEN_ROOT}/emranlib${EMCC_SUFFIX}" CACHE PATH "ranlib" FORCE)

# override cmake modules with emscripten cmake modules
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${EMSCRIPTEN_ROOT}/cmake/Modules")

# only search for libraries and includes in the toolchain
set(CMAKE_FIND_ROOT_PATH ${EMSCRIPTEN_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_SYSTEM_INCLUDE_PATH "${EMSCRIPTEN_ROOT}/system/include")

set(CMAKE_C_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_LIBRARIES 1)
set(CMAKE_C_USE_RESPONSE_FILE_FOR_OBJECTS 1)
set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_OBJECTS 1)
set(CMAKE_C_USE_RESPONSE_FILE_FOR_INCLUDES 1)
set(CMAKE_CXX_USE_RESPONSE_FILE_FOR_INCLUDES 1)

set(CMAKE_C_RESPONSE_FILE_LINK_FLAG "@")
set(CMAKE_CXX_RESPONSE_FILE_LINK_FLAG "@")

set(CMAKE_C_CREATE_STATIC_LIBRARY "<CMAKE_AR> rc <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY "<CMAKE_AR> rc <TARGET> <LINK_FLAGS> <OBJECTS>")

set(CMAKE_SKIP_COMPATIBILITY_TESTS 1)
set(CMAKE_SIZEOF_CHAR 1)
set(CMAKE_SIZEOF_UNSIGNED_SHORT 2)
set(CMAKE_SIZEOF_SHORT 2)
set(CMAKE_SIZEOF_INT 4)
set(CMAKE_SIZEOF_UNSIGNED_LONG 4)
set(CMAKE_SIZEOF_UNSIGNED_INT 4)
set(CMAKE_SIZEOF_LONG 4)
set(CMAKE_SIZEOF_VOID_P 4)
set(CMAKE_SIZEOF_FLOAT 4)
set(CMAKE_SIZEOF_DOUBLE 8)
set(CMAKE_C_SIZEOF_DATA_PTR 4)
set(CMAKE_CXX_SIZEOF_DATA_PTR 4)
set(CMAKE_HAVE_LIMITS_H 1)
set(CMAKE_HAVE_UNISTD_H 1)
set(CMAKE_HAVE_PTHREAD_H 1)
set(CMAKE_HAVE_SYS_PRCTL_H 1)
set(CMAKE_WORDS_BIGENDIAN 0)
set(CMAKE_DL_LIBS)

# c++ compiler flags
set(CMAKE_CXX_FLAGS "${EMSC_COMMON_FLAGS} ${EMSC_CXX_FLAGS} -std=c++11 -fstrict-aliasing -Wall -Wno-multichar -Wextra -Wno-unused-parameter -Wno-unknown-pragmas -Wno-ignored-qualifiers -Wno-long-long -Wno-overloaded-virtual -Wno-deprecated-writable-strings -Wno-unused-volatile-lvalue -Wno-inconsistent-missing-override -Wno-warn-absolute-paths -Wno-expansion-to-defined")
set(CMAKE_CXX_FLAGS_RELEASE "${EMSCRIPTEN_OPT} -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g -D_DEBUG_ -D_DEBUG -DFIPS_DEBUG=1")
set(CMAKE_CXX_FLAGS_PROFILING "${EMSCRIPTEN_OPT} -DNDEBUG --profiling")

# c compiler flags
set(CMAKE_C_FLAGS "${EMSC_COMMON_FLAGS} -fstrict-aliasing -Wall -Wextra -Wno-multichar -Wno-unused-parameter -Wno-unknown-pragmas -Wno-ignored-qualifiers -Wno-long-long -Wno-overloaded-virtual -Wno-deprecated-writable-strings -Wno-unused-volatile-lvalue -Wno-warn-absolute-paths -Wno-expansion-to-defined")
set(CMAKE_C_FLAGS_RELEASE "${EMSCRIPTEN_OPT} -DNDEBUG")
set(CMAKE_C_FLAGS_DEBUG "-O0 -g -D_DEBUG_ -D_DEBUG -DFIPS_DEBUG=1")
set(CMAKE_C_FLAGS_PROFILING "${EMSCRIPTEN_OPT} -DNDEBUG --profiling")

# linker flags
set(CMAKE_EXE_LINKER_FLAGS "${EMSC_COMMON_FLAGS} ${EMSC_LINKER_FLAGS} ${EMSC_EXE_LINKER_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${EMSCRIPTEN_OPT} ${EMSC_LINKER_FLAGS_RELEASE}")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "-O0 -g")
set(CMAKE_EXE_LINKER_FLAGS_PROFILING "--profiling ${EMSCRIPTEN_OPT} ${EMSC_LINKER_FLAGS_RELEASE}")

# static library flags (for CMAKE_AR)
set(CMAKE_STATIC_LINKER_FLAGS "${EMSC_AR_FLAGS}")

# dynamic lib linker flags
set(CMAKE_SHARED_LINKER_FLAGS "-shared ${EMSC_COMMON_FLAGS} ${EMSC_LINKER_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${EMSCRIPTEN_OPT} ${EMSC_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${EMSCRIPTEN_OPT} -g")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILING "--profiling ${EMSCRIPTEN_OPT} ${EMSC_LINKER_FLAGS_RELEASE}")

# update cache variables for cmake gui
set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIGURATION_TYPES}" CACHE STRING "Config Type" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" CACHE STRING "Generic C++ Compiler Flags" FORCE)
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}" CACHE STRING "C++ Debug Compiler Flags" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}" CACHE STRING "C++ Release Compiler Flags" FORCE)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "Generic C Compiler Flags" FORCE)
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}" CACHE STRING "C Debug Compiler Flags" FORCE)
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}" CACHE STRING "C Release Compiler Flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}" CACHE STRING "Generic Linker Flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG}" CACHE STRING "Debug Linker Flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}" CACHE STRING "Release Linker Flags" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}" CACHE STRING "Generic Shared Linker Flags" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${CMAKE_SHARED_LINKER_FLAGS_DEBUG}" CACHE STRING "Debug Shared Linker Flags" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}" CACHE STRING "Release Shared Linker Flags" FORCE)
set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS}" CACHE STRING "Static Lib Flags" FORCE)

# set the build type to use
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Compile Type" FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release Profiling)

