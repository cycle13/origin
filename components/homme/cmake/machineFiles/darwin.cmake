# CMake initial cache file for Mac OSX 10.8
# tested with gcc/gfortran & openmpi from HOMEBREW
# 
# openmp is supported by GNU gcc, but not supported by Apple LLVM gcc
#
SET (ENABLE_OPENMP FALSE CACHE FILEPATH "")

SET (CMAKE_Fortran_COMPILER mpif90 CACHE FILEPATH "")
SET (CMAKE_C_COMPILER mpicc CACHE FILEPATH "")
SET (CMAKE_CXX_COMPILER mpicc CACHE FILEPATH "")

SET (WITH_PNETCDF FALSE CACHE FILEPATH "")
SET (NETCDF_DIR /usr/local CACHE FILEPATH "")
SET (HDF5_DIR /usr/local/ CACHE FILEPATH "")

SET (USE_QUEUING FALSE CACHE BOOL "")
SET (HOMME_FIND_BLASLAPACK TRUE CACHE BOOL "")

# see ../../README.cmake for options regarding cprnc
# For non-CIME supported systems, assume cprnc is already built:
SET (CPRNC_DIR /usr/local/bin CACHE FILEPATH "")