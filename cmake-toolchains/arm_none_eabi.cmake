set(CMAKE_SYSTEM_NAME "Generic")
set(CMAKE_SYSTEM_PROCESSOR ARM)

if(MINGW OR CYGWIN OR WIN32)
    set(UTIL_SEARCH_CMD where)
elseif(UNIX OR APPLE)
    set(UTIL_SEARCH_CMD which)
endif()

set(CIRCLEHOME $ENV{CIRCLEHOME})
if(NOT CIRCLEHOME)
    set(CIRCLEHOME /home/meesokim/circle)
endif()

set(TOOLCHAIN_PREFIX arm-none-eabi-)
set(__circle__ 1)
set(FIPS_RASPBERRYPI 1)

if(NOT AARCH)
    set(AARCH 32)
endif()

if(NOT RASPPI)
    set(RASPPI 1)
endif()

set(STDLIB_SUPPORT $ENV{STDLIB_SUPPORT})
#message("STDLIB_SUPPORT=${STDLIB_SUPPORT}")

if(NOT STDLIB_SUPPORT)
    set(STDLIB_SUPPORT 1)
endif()

if(NOT FLOAT_ABI)
    set(FLOAT_ABI "hard")
endif()

if(${AARCH} EQUAL "32")
if(${RASPPI} EQUAL "1")
    set(ARCH "-DAARCH=32 -mfloat-abi=${FLOAT_ABI} -marm -mfpu=vfp -march=armv6k -mtune=arm1176jzf-s ")
    set(MARCH "-march=armv6k")
    set(MTUNE "-mtune=arm1176jzf-s")
    set(CPU "arm1176jzf-s")
    set(MFPU "vfp")
    set(TARGET "kernel")
elseif(${RASPPI} EQUAL "2")
    set(ARCH "-DAARCH=32 -march=armv7-a -marm -mfpu=neon-vfpv4 -mfloat-abi=${FLOAT_ABI}")
    set(MARCH "-march=armv7-a")
    set(MTUNE "-marm")
    set(MFPU "neon-vfpv4")
    set(TARGET "kernel7")
elseif(${RASPPI} EQUAL "3")
    set(ARCH "-DAARCH=32 -march=armv8-a -mtune=cortex-a53 -marm -mfpu=neon-fp-armv8 -mfloat-abi=${FLOAT_ABI}")
    set(MARCH "-march=armv8-a")
    set(MTUNE "-mtune=cortex-a53")
    set(MFPU "neon-vfpv4")
    set(TARGET "kernel8-32")
elseif(${RASPPI} EQUAL "4")
    set(ARCH "-DAARCH=32 -march=armv8-a -mtune=cortex-a72 -marm -mfpu=neon-fp-armv8 -mfloat-abi=${FLOAT_ABI}")
    set(MARCH "-march=armv8-a")
    set(MTUNE "-mtune=cortex-a72")
    set(MFPU "neon-vfpv4")
    set(TARGET "kernel7l")
endif()
set(LOADADDR "0x8000")
elseif(${AARCH} EQUAL "64")
if(${RASPPI} EQUAL "3")
    set(ARCH "-DAARCH=64 -march=armv8-a -mtune=cortex-a53 -mlittle-endian -mcmodel=small")
    set(TARGET "kernel8")
elseif(${RASPPI} EQUAL "4")
    set(ARCH "-DAARCH=64 -march=armv8-a -mtune=cortex-a72 -mlittle-endian -mcmodel=small")
    set(TARGET "kernel8-rpi4")
endif()
endif()

execute_process(
  COMMAND ${UTIL_SEARCH_CMD} ${TOOLCHAIN_PREFIX}gcc
  OUTPUT_VARIABLE BINUTILS_PATH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

get_filename_component(ARM_TOOLCHAIN_DIR ${BINUTILS_PATH} DIRECTORY)
# Without that flag CMake is not able to pass test compilation check
if (${CMAKE_VERSION} VERSION_EQUAL "3.6.0" OR ${CMAKE_VERSION} VERSION_GREATER "3.6")
    set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
    #set(CMAKE_EXE_LINKER_FLAGS_INIT "-specs=nosys.specs ")
else()
    set(CMAKE_EXE_LINKER_FLAGS_INIT "-specs=nosys.specs")
endif()

#set(TOOLCHAIN_DIR "/opt/bin")
find_program(GNU_ARM_C arm-none-eabi-gcc ${TOOLCHAIN_DIR})
find_program(GNU_ARM_CXX arm-none-eabi-g++ ${TOOLCHAIN_DIR})
find_program(GNU_ARM_OBJCOPY arm-none-eabi-objcopy ${TOOLCHAIN_DIR})
find_program(GNU_ARM_LINK arm-none-eabi-ld ${TOOLCHAIN_DIR})
find_program(GNU_ARM_SIZE_TOOL arm-none-eabi-size ${TOOLCHAIN_DIR})
#set(CMAKE_C_COMPILER ${GNU_ARM_C})
#set(CMAKE_CXX_COMPILER ${GNU_ARM_CXX})
#set(CMAKE_ASM_COMPILER ${GNU_ARM_C})
#set(CMAKE_EXE_LINKER ${GNU_ARM_LINK})

set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_PREFIX}as)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}g++)
set(CMAKE_EXE_LINKER ${TOOLCHAIN_PREFIX}ld)
set(CMAKE_OBJCOPY ${TOOLCHAIN_PREFIX}objcopy CACHE INTERNAL "objcopy tool") 
set(CMAKE_SIZE_UTIL ${TOOLCHAIN_PREFIX}size CACHE INTERNAL "size tool")

#set(CMAKE_OBJCOPY ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}objcopy CACHE INTERNAL "objcopy tool")
#set(CMAKE_SIZE_UTIL ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}size CACHE INTERNAL "size tool")
#set(CMAKE_LOCATION "${CMAKE_CXX_COMPILER} ${ARCH} -print-file-name=")

if(${STDLIB_SUPPORT} EQUAL "3")
   # message("STDLIB_SUPPORT=${STDLIB_SUPPORT} ${CMAKE_CXX_COMPILER} ${ARCH} -print-file-name=libstdc++.a")  
    #set(LIBSTDCPP "${CMAKE_CXX_COMPILER} ${ARCH} -print-file-name=libstdc++.a")
    execute_process(
      COMMAND ${CMAKE_CXX_COMPILER} -DAARCH=${AARCH} ${MARCH} ${MTUNE} -mfpu=${MFPU} -mfloat-abi=${FLOAT_ABI} -print-file-name=libstdc++.a
      OUTPUT_VARIABLE LIBSTDCPP
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(EXTRALIBS "${EXTRALIBS} ${LIBSTDCPP}")
    #message("EXTRALIBS=${LIBSTDCPP}")   
    #set(LIBGCC_EH "${CMAKE_CXX_COMPILER} ${ARCH} -print-file-name=libgcc_eh.a")
    execute_process(
      COMMAND ${CMAKE_CXX_COMPILER} -DAARCH=${AARCH} ${MARCH} ${MTUNE} -mfpu=${MFPU} -mfloat-abi=${FLOAT_ABI}  -print-file-name=libgcc_eh.a
      OUTPUT_VARIABLE LIBGCC_EH
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(IS_ABSOLUTE ${LIBGCC_EH})
        set(EXTRALIBS "${EXTRALIBS} ${LIBGCC_EH}")
    endif()
    #message(${LIBGCC_EH})
endif()
if (NOT STDLIB_SUPPORT)
    set(CFLAGS "-nostdinc")
else()
    #set(LIBGCC "${CMAKE_CXX_COMPILER} ${ARCH} -print-file-name=libgcc.a")
    execute_process(
      COMMAND ${CMAKE_CXX_COMPILER} -DAARCH=${AARCH} ${MARCH}  ${MTUNE} -mfpu=${MFPU} -mfloat-abi=${FLOAT_ABI} -print-file-name=libgcc.a
      OUTPUT_VARIABLE LIBGCC
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(EXTRALIBS "${EXTRALIBS} ${LIBGCC}")
    
    execute_process(
      COMMAND ${CMAKE_CXX_COMPILER} -DAARCH=${AARCH} ${MARCH}  ${MTUNE} -mfpu=${MFPU} -mfloat-abi=${FLOAT_ABI} -print-file-name=libc.a
      OUTPUT_VARIABLE LIBGCC
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(EXTRALIBS "${EXTRALIBS} ${LIBGCC}")    
endif()
if (${STDLIB_SUPPORT} GREATER "1")
    #set(LIBM "${CMAKE_CXX_COMPILER} ${ARCH} -print-file-name=libm.a")
    set(LIBLOC arm-none-eabi-gcc ${ARCH} "-print-file-name=libm.a")
    execute_process(
      COMMAND ${CMAKE_C_COMPILER} -DAARCH=${AARCH} ${MARCH}  ${MTUNE} -mfpu=${MFPU} -mfloat-abi=${FLOAT_ABI} -print-file-name=libm.a 
      OUTPUT_VARIABLE LIBM
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    set(EXTRALIBS "${EXTRALIBS} ${LIBM}")
endif()

#message(${EXTRALIBS})
#message("FIPS_PROJECT_DEPLOY_DIR: ${FIPS_PROJECT_DEPLOY_DIR}")

if(${AARCH} EQUAL "64")
    #set(CRTBEGIN "${CMAKE_CXX_COMPILER} ${ARCH}  -print-file-name=crtbegin.o")
    execute_process( 
      COMMAND ${CMAKE_CXX_COMPILER} -DAARCH=${AARCH} ${MARCH}  ${MTUNE} -mfpu=${MFPU} -mfloat-abi=${FLOAT_ABI}  -print-file-name=crtbegin.o
      OUTPUT_VARIABLE CRTBEGIN
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )    
    #set(CRTEND "${CMAKE_CXX_COMPILER} ${ARCH}  -print-file-name=crtend.o")
    execute_process(
      COMMAND ${CMAKE_CXX_COMPILER}-DAARCH=${AARCH} ${MARCH}  ${MTUNE} -mfpu=${MFPU} -mfloat-abi=${FLOAT_ABI}  -print-file-name=crtend.o
      OUTPUT_VARIABLE CRTEND
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )        
else()
    set(CPPFLAG "-fno-exceptions -fno-rtti -nostdinc++ ")
endif()

set(CMAKE_SYSROOT ${ARM_TOOLCHAIN_DIR}/../arm-none-eabi)
set(CMAKE_FIND_ROOT_PATH ${BINUTILS_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
add_compile_options(-mcpu=${CPU})
add_compile_options(${MARCH})
add_compile_options(${MTUNE})
add_compile_options(-mfpu=${MFPU})
add_compile_options(-mfloat-abi=${FLOAT_ABI})
add_definitions("-DFIPS_RASPBERRYPI")
add_definitions("-DSOKOL_GLES2")
add_definitions("-D__circle__")
file(GLOB_RECURSE LINKER_SCRIPT ${CIRCLEHOME}/circle.ld)
set(CMAKE_CXX_FLAGS "${CPPFLAG} ${ARCH} -Wall -fsigned-char -ffreestanding  -fno-threadsafe-statics -I${CIRCLEHOME}/addon -I${CIRCLEHOME}/addon/vc4/interface/khronos/include -I${CIRCLEHOME}/include -std=c++14")
set(CMAKE_C_FLAGS "${ARCH} -Wall -fsigned-char -ffreestanding  -D__circle__ -DFIPS_RASPBERRYPI -DSOKOL_GLES2 -I${CIRCLEHOME}/addon -I${CIRCLEHOME}/addon/vc4/interface/khronos/include -I${CIRCLEHOME}/include -std=gnu99")
set(CMAKE_INCLUDE_PATH ${CIRCLEHOME}/addon/vc4/interface/khronos)
set(CMAKE_FIND_LIBRARY_PREFIXES lib)
set(CMAKE_FIND_LIBRARY_SUFFIXES .so;.a)
#set(CMAKE_STATIC_LINKER_FLAGS " -lkhrn_client")
#set(CMAKE_PREFIX_PATH ${CIRCLEHOME}/addon/vc4/interface/khronos ${CIRCLEHOME}/addon/vc4/interface/vmcs_host/ ${CIRCLEHOME}/addon/vc4/interface/vcos/ ${CIRCLEHOME}/addon/vc4/vchiq/)
#message("prefix: ${CMAKE_FIND_LIBRARY_PREFIXES}")
#message("suffix: ${CMAKE_FIND_LIBRARY_SUFFIXES}")
#set(CMAKE_LIBRARY_PATH ${CIRCLEHOME}/addon/vc4/interface/khronos)
link_directories(lib/arm/v5te/hard/ ${CIRCLEHOME}/addon/vc4/interface/khronos)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/addon/vc4/interface/vmcs_host/")
link_directories(${CIRCLEHOME}/addon/vc4/interface/vmcs_host/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/addon/vc4/vchiq/")
link_directories(${CIRCLEHOME}/addon/vc4/vchiq/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/addon/vc4/interface/vcos/")
link_directories(${CIRCLEHOME}/addon/vc4/interface/vcos/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/addon/vc4/interface/bcm_host")
link_directories(${CIRCLEHOME}/addon/vc4/interface/bcm_host)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/addon/linux/")
link_directories(${CIRCLEHOME}/addon/linux/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/lib/sched/")
link_directories(${CIRCLEHOME}/lib/sched/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/lib/usb/")
link_directories(${CIRCLEHOME}/lib/usb/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/lib/input/")
link_directories(${CIRCLEHOME}/lib/input/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/lib/fs/")
link_directories(${CIRCLEHOME}/lib/fs/)
set(CMAKE_LIBRARY_PATH "${CMAKE_LIBRARY_PATH} -L${CIRCLEHOME}/lib")
link_directories(${CIRCLEHOME}/lib)
#set_target_properties(${TARGET} PROPERTIES SUFFIX ".elf")
set(CMAKE_EXECUTABLE_SUFFIX .elf)
#link_libraries(-llinuxemu -lkhrn_client -lbcm_host -lvcos -lvmcs_host -lvchiq -lsched -linput -lfs -lcircle -lusb -lm -lc -lstdc++ -lgcc)
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "-Map kernel.map --section-start=.init=${LOADADDR}") 
set(CMAKE_CXX_LINK_EXECUTABLE 
"${CMAKE_EXE_LINKER} -o ${TARGET}.elf -Map kernel.map --section-start=.init=${LOADADDR} -T ${CIRCLEHOME}/circle.ld --start-group <LINK_LIBRARIES> ${CRTBEGIN} <OBJECTS> -L${CMAKE_LIBRARY_PATH} -llinuxemu -lkhrn_client -lbcm_host -lvcos -lvmcs_host -lvchiq -lsched -linput -lfs -lcircle -lusb ${EXTRALIBS} --end-group ${CRTEND} "
"${TOOLCHAIN_PREFIX}objdump -d ${TARGET}.elf  | ${TOOLCHAIN_PREFIX}c++filt > ${TARGET}.lst"
"${TOOLCHAIN_PREFIX}objcopy ${TARGET}.elf -O binary ${TARGET}.img"
#"echo ${FIPS_PROJECT_DEPLOY_DIR}/${TARGET}.img"
)
function(make_bin exe elf bin)
  #message("hello i will now turn ${elf} into ${bin}")
  add_custom_command(OUTPUT ${bin}
                     COMMAND arm-none-eabi-objcopy -O binary ${elf} ${bin}
                     DEPENDS ${elf}
                     COMMENT "creating ${bin}")
  add_custom_target(${exe}_bin ALL DEPENDS ${bin})

  add_custom_command(OUTPUT ${elf}.objdump
                     COMMAND arm-none-eabi-objdump -S -d ${elf} > ${elf}.objdump
                     DEPENDS ${elf}
                     COMMENT "disassembling ${elf}")
  add_custom_target(${exe}_objdump ALL DEPENDS ${elf}.objdump)
endfunction()
set(ELF_FILE ${PROJECT_BINARY_DIR}/${TARGET})
#add_custom_command(
#    TARGET ${ELF_FILE} 
#    DEPENDS ${ELF_FILE}
#    POST_BUILD COMMENT "DUMP ${TARGET}.elf"
#    COMMAND ${TOOLCHAIN_PREFIX}objdump ARGS -d${TARGET} | ${TOOLCHAIN_PREFIX}c++filt > ${TARGET}.lst 
#)
#message(${CMAKE_CXX_LINK_EXECUTABLE})
#link_directories(${CMAKE_LIBRARY_PATH})
#add_library(khrn_client STATIC IMPORTED)
#target_link_libraries(${MAKE_PROJECT_NAME} khrn_client)
#set(${MAKE_PROJECT_NAME}_EXTERNAL_OBJECTS khrn_client)
#message("Looking for ${name} in ${CMAKE_LIBRARY_PATH}.")
#if(NOT MY_LIB)
#  message(FATAL_ERROR ${MY_LIB} " "  ${CMAKE_LIBRARY_PATH} " library not found")
