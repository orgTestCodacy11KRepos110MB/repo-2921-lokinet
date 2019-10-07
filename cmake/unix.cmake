if(NOT UNIX)
  return()
endif()

include(CheckCXXSourceCompiles)
include(CheckLibraryExists)

add_definitions(-DUNIX)
add_definitions(-DPOSIX)
list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix.c)

if (STATIC_LINK_RUNTIME OR STATIC_LINK)
  set(LIBUV_USE_STATIC ON)
endif()

if(LIBUV_ROOT)
  add_subdirectory(${LIBUV_ROOT})
  set(LIBUV_INCLUDE_DIRS ${LIBUV_ROOT}/include)
  set(LIBUV_LIBRARY uv_a)
  add_definitions(-D_LARGEFILE_SOURCE)
  add_definitions(-D_FILE_OFFSET_BITS=64)
elseif(NOT LIBUV_IN_SOURCE)
  find_package(LibUV 1.28.0 REQUIRED)
endif()

include_directories(${LIBUV_INCLUDE_DIRS})

if(EMBEDDED_CFG OR ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  link_libatomic()
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  set(FS_LIB stdc++fs)
  list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix-linux.c)
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Android")
  find_library(FS_LIB NAMES c++fs c++experimental stdc++fs)
  if(FS_LIB STREQUAL FS_LIB-NOTFOUND)
    include_directories("${CMAKE_CURRENT_LIST_DIR}/../vendor/cppbackport-master/lib")
    add_definitions(-DLOKINET_USE_CPPBACKPORT)
    set(FS_LIB cppbackport)
  endif()
  list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix-linux.c)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "OpenBSD")
  list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix-openbsd.c ${TT_ROOT}/tuntap-unix-bsd.c)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "NetBSD")
  list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix-netbsd.c ${TT_ROOT}/tuntap-unix-bsd.c)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD" OR ${CMAKE_SYSTEM_NAME} MATCHES "DragonFly")
  find_library(FS_LIB NAMES c++experimental)
  list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix-freebsd.c ${TT_ROOT}/tuntap-unix-bsd.c)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin" OR ${CMAKE_SYSTEM_NAME} MATCHES "iOS")
  find_library(FS_LIB NAMES c++fs c++experimental stdc++fs)
  if(FS_LIB STREQUAL FS_LIB-NOTFOUND)
    include_directories("${CMAKE_CURRENT_LIST_DIR}/../vendor/cppbackport-master/lib")
    add_definitions(-DLOKINET_USE_CPPBACKPORT)
    set(FS_LIB cppbackport)
  endif()
  list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix-darwin.c ${TT_ROOT}/tuntap-unix-bsd.c)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
  list(APPEND LIBTUNTAP_SRC ${TT_ROOT}/tuntap-unix-sunos.c)
  # Apple C++ screws up name decorations in stdc++fs, causing link to fail
  # Samsung does not build c++experimental or c++fs in their Apple libc++ pkgsrc build
  if (LIBUV_USE_STATIC)
    link_libraries(-lkstat -lsendfile)
  endif()
  if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    include_directories("${CMAKE_CURRENT_LIST_DIR}/../vendor/cppbackport-master/lib")
    add_definitions(-DLOKINET_USE_CPPBACKPORT)
    set(FS_LIB cppbackport)
  else()
    set(FS_LIB stdc++fs)
  endif()
else()
  message(FATAL_ERROR "Your operating system - ${CMAKE_SYSTEM_NAME} is not supported yet")
endif()


set(EXE_LIBS ${STATIC_LIB})

if(RELEASE_MOTTO)
  add_definitions(-DLLARP_RELEASE_MOTTO="${RELEASE_MOTTO}")
endif()
