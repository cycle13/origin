
PROJECT(HOMME C Fortran)

ENABLE_LANGUAGE(Fortran) 
INCLUDE(FortranCInterface)

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.5)

# CTest For Nightly/Experimental Builds
OPTION(HOMME_USE_CTEST "Use CTest Dashboard" FALSE)
IF (${HOMME_USE_CTEST})
  INCLUDE(CTest)
ENDIF ()

# For testing
ENABLE_TESTING()

# Add the cmake/CMakeLists.txt file
SET (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# need to get the cmake_fortran_c_interface.h header
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
FortranCInterface_HEADER(cmake_fortran_c_interface.h
                         MACRO_NAMESPACE  "FCI_")

# Prefer shared libraries (Yellowstone etc.) 
OPTION(PREFER_SHARED "Prefer linking with shared libraries." FALSE)

# need to tell the source to use this capability
ADD_DEFINITIONS(-DINCLUDE_CMAKE_FCI)

# Set up some directories to facilitate finding netcdf and pnetcdf
INCLUDE(SetHostPaths)
INCLUDE(HommeMacros)

# Debug statement, please leave here
#MESSAGE(STATUS "CMAKE_IMP_LIBS=${CMAKE_Fortran_IMPLICIT_LINK_LIBRARIES}")

OPTION(IS_BIG_ENDIAN "Whether the machine is big endian" FALSE)
#TRY_RUN(IS_BIG_ENDIAN BIG_ENDIAN_COMPILED
#  ${CMAKE_BINARY_DIR}/tests/compilerTests/
#  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/compilerTests/isBigEndian.c)

# Default use quad precision
OPTION(HOMME_QUAD_PREC "Default to try to use quadruple precision" TRUE)

IF (${HOMME_QUAD_PREC}) 
  testQuadPrec(HOMME_QUAD_SUPPORTED)
  IF (NOT ${HOMME_QUAD_SUPPORTED})
    SET(HOMME_QUAD_PREC FALSE)
    MESSAGE(STATUS "Quadruple-precision requested but unavailable on this
                    system with this compiler")
  ENDIF()
ENDIF ()

# Some options for conditional builds
OPTION(BUILD_HOMME_SWEQX "Shallow water equations FEM" ON)
OPTION(BUILD_HOMME_PREQX "Primitive equations FEM" ON)
OPTION(BUILD_HOMME_PREQX_ACC "Primitive equations FEM with OpenACC" ON)
OPTION(BUILD_HOMME_SWIM  "Shallow water equations implicit" OFF)
OPTION(BUILD_HOMME_PRIM  "Primitive equations implicit" OFF)

# Cristoph's "standalone" executables
OPTION(BUILD_HOMME_FVM  "Standalone FVM tracers" OFF)

# swim and prim executables require C++ compiler
IF(${BUILD_HOMME_SWIM} OR ${BUILD_HOMME_PRIM})
  SET (HOMME_USE_CXX TRUE)
  SET (HOMME_USE_TRILINOS TRUE)
ELSE ()
  SET(HOMME_USE_CXX FALSE)
ENDIF ()

IF (${HOMME_USE_TRILINOS}) 
  SET (HOMME_USE_CXX TRUE)
ENDIF()


IF (${HOMME_USE_CXX})
  MESSAGE(STATUS "This configuration of HOMME requires a C++ compiler")
  ENABLE_LANGUAGE(CXX)
ENDIF ()

##############################################################################
# Compiler options set in cmake/SetCompiler.cmake
##############################################################################
INCLUDE(SetCompilerFlags)


OPTION(ENABLE_PERSISTENT_MPI "Enable persistent MPI" OFF)
IF (${ENABLE_PERSISTENT_MPI})
  SET(MPI_PERSISTENT TRUE)
ENDIF ()

OPTION(HOMME_USE_MKL "Whether to use Intel's MKL instead of blas/lapack" FALSE)
IF(${HOMME_USE_MKL})
  MESSAGE(STATUS "HOMME_USE_MKL=${HOMME_USE_MKL}, adding -mkl")
  SET(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -mkl")
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mkl")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mkl")
  SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -mkl")
ELSE()
  OPTION(HOMME_FIND_BLASLAPACK "Whether to use system blas/lapack" FALSE)
  MESSAGE(STATUS "HOMME_FIND_BLASLAPACK=${HOMME_FIND_BLASLAPACK}")

  IF(${HOMME_FIND_BLASLAPACK})
    FIND_PACKAGE(BLAS REQUIRED)
    FIND_PACKAGE(LAPACK REQUIRED)
  ELSE()
    SET(HOMME_FIND_BLASLAPACK FALSE)
    # Build the blas and lapack provided with homme
    ADD_SUBDIRECTORY(libs/blas)
    ADD_SUBDIRECTORY(libs/lapack)
  ENDIF()
ENDIF()

IF (${HOMME_USE_TRILINOS})
  MESSAGE(STATUS "This configuration of requires Trilinos")
  FIND_PACKAGE(Trilinos REQUIRED)
  SET(HAVE_TRILINOS TRUE)
  IF("${Trilinos_PACKAGE_LIST}"  MATCHES ".*Zoltan2*.")
    MESSAGE(STATUS "Trilinos is compiled with Zoltan2 Trilinos_PACKAGE_LIST:${Trilinos_PACKAGE_LIST}")
    MESSAGE(STATUS "ENABLING ZOLTAN2")
    SET(TRILINOS_HAVE_ZOLTAN2 TRUE)
  ENDIF ()
  add_definitions(${Trilinos_CXX_COMPILER_FLAGS})
  include_directories(${Trilinos_TPL_INCLUDE_DIRS})
  include_directories(${Trilinos_INCLUDE_DIRS})
  link_directories(${Trilinos_LIBRARY_DIRS})
  link_directories(${Trilinos_TPL_LIBRARY_DIRS})
ENDIF ()

# Print the compiler flags to be used
MESSAGE(STATUS "\nFortran Flags = ${CMAKE_Fortran_FLAGS}")
MESSAGE(STATUS "C Flags = ${CMAKE_C_FLAGS}")
MESSAGE(STATUS "CXX Flags = ${CMAKE_CXX_FLAGS}")
MESSAGE(STATUS "Linker Flags = ${CMAKE_EXE_LINKER_FLAGS} \n")
##############################################################################


# Zoltan partitioning library
IF (DEFINED ZOLTAN_DIR)
  MESSAGE(STATUS "Building with Zoltan")
  FIND_PACKAGE(Zoltan REQUIRED)
  SET(HAVE_ZOLTAN TRUE)
ENDIF ()

IF (DEFINED EXTRAE_DIR)
  MESSAGE(STATUS "Building with Extrae")
  FIND_PACKAGE(Extrae REQUIRED)
  SET(HAVE_EXTRAE TRUE)
ENDIF ()

###########################################
# Definitions for timing library
###########################################
# This is required in timing to set HAVE_MPI
ADD_DEFINITIONS(-DSPMD)
OPTION(ENABLE_NANOTIMERS "Use nano timers in timing library" FALSE)
OPTION(USE_BIT64 "Set BIT64 (for 64 bit arch) in timing library when ENABLE_NANOTIME" FALSE)
IF (${ENABLE_NANOTIMERS})
  ADD_DEFINITIONS(-DHAVE_NANOTIME)
  IF (${USE_BIT64})
    ADD_DEFINITIONS(-DBIT64)
  ENDIF ()
ENDIF ()
ADD_SUBDIRECTORY(utils/cime/src/share/timing)


# Use CIME's FindNETCDF path
# CMAKE_CURRENT_SOURCE_DIR == homme
SET (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})
SET (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/utils/cime/src/externals/CMake" ${CMAKE_MODULE_PATH})
SET (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/utils/cime/src/externals/pio2/cmake" ${CMAKE_MODULE_PATH})


#
# Bug in PIO: PIO1 calls TARGET_LINK_LIBRARIES uses all caps variables, 
# instead of the mixed case variables computed by PIO's findNetCDF.  
# 2017/6 PR submitted to pio1
# workaround until this makes it back into ACME:
#
SET(NetCDF_PATH ${NETCDF_DIR})
SET(PnetCDF_PATH ${PNETCDF_DIR})
FIND_PACKAGE(NetCDF "4.3.3" COMPONENTS C Fortran)
FIND_PACKAGE(PnetCDF COMPONENTS C Fortran)
set(NETCDF_LIBRARIES ${NetCDF_Fortran_LIBRARIES})
set(PNETCDF_LIBRARY ${PnetCDF_Fortran_FOUND})
set(PNETCDF_LIBRARIES ${PnetCDF_Fortran_LIBRARIES})
# needed to build cprnc:
set(NETCDF_INCLUDE_DIR ${NetCDF_Fortran_INCLUDE_DIRS})



#
# PIO
#
#set search paths for PIO's findNetCDF
SET(NetCDF_PATH ${NETCDF_DIR})
SET(PnetCDF_PATH ${PNETCDF_DIR})
# pio needs cime/externals/genf90/genf90.pl
SET(GENF90_PATH ${CMAKE_CURRENT_SOURCE_DIR}/utils/cime/src/externals/genf90)
ADD_SUBDIRECTORY(utils/cime/src/externals/pio1)



# CPRNC locations
IF (CPRNC_DIR)
  # user specifed CPRNC binary - dont build
  ADD_EXECUTABLE( cprnc IMPORTED)
  find_program(CPRNC_BINARY cprnc ${CPRNC_DIR})
  IF ( CPRNC_BINARY )
     message("-- CPRNC_BINARY = ${CPRNC_BINARY}")
  ELSE()
     message(WARNING "cprnc not found - cannot check regression test output")
  ENDIF ()
ELSE ()
  # compile CPRNC from CIME source code. Requires CIME support for machine
  SET (CPRNC_INSTALL_DIR ${CMAKE_BINARY_DIR}/utils/cime/tools/cprnc)
  SET (CPRNC_BINARY ${CMAKE_BINARY_DIR}/utils/cime/tools/cprnc/cprnc)
  ADD_SUBDIRECTORY(utils/cime/tools/cprnc)
ENDIF ()


SET(EXEC_LIST ""  CACHE INTERNAL "List of configured executables")
IF(${BUILD_HOMME_SWEQX})
  ADD_SUBDIRECTORY(src/sweqx)
ENDIF()

IF(${BUILD_HOMME_PREQX})
  ADD_SUBDIRECTORY(src/preqx)
ENDIF()

IF(${BUILD_HOMME_PREQX_ACC})
  ADD_SUBDIRECTORY(src/preqx_acc)
ENDIF()

IF(${BUILD_HOMME_FVM})
  ADD_SUBDIRECTORY(src/fvm)
ENDIF()

IF(${BUILD_HOMME_SWIM})
  ADD_SUBDIRECTORY(src/swim)
ENDIF()

IF(${BUILD_HOMME_PRIM})
  ADD_SUBDIRECTORY(src/prim)
ENDIF()

ADD_SUBDIRECTORY(test_execs)

# Create a "make clean-all" target to delete CMake cache and the cprnc build
ADD_CUSTOM_TARGET(clean-all
   COMMAND ${CMAKE_BUILD_TOOL} clean
   COMMAND ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/clean-cmake-files.cmake"
)

ADD_SUBDIRECTORY(dcmip_tests)
