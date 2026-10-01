# numsim-cmake

Shared CMake modules of the NumSim libraries (numsim-core, numsim-materials,
numsim-fft, numsim-fft-homogenization). One convention for dependencies,
tests and warnings instead of a copy per repository.

## Use

Copy [`bootstrap.cmake`](bootstrap.cmake) into your project as
`cmake/numsim_bootstrap.cmake`, then:

```cmake
include(cmake/numsim_bootstrap.cmake)   # after project()
include(NumSimDependency)
include(NumSimWarnings)

numsim_dependency(tmech
    TARGET tmech::tmech
    GIT_REPOSITORY https://github.com/petlenz/tmech.git
    GIT_TAG        v1.2.0
    SIBLING        tmech
    FIND_PACKAGE_ARGS CONFIG
    OPTIONS TMECH_BUILD_TESTS=OFF TMECH_BUILD_EXAMPLES=OFF)
target_link_libraries(mylib INTERFACE tmech::tmech)

if(MYLIB_BUILD_TESTS)
    include(NumSimGoogleTest)
    numsim_googletest()
    include(NumSimTesting)
    numsim_add_test(mylib_test SOURCES test.cpp LINK mylib::mylib)
endif()
```

The bootstrap takes the modules from a sibling checkout `../numsim-cmake`
when present, otherwise from the pinned tag (`NUMSIM_CMAKE_TAG`).

## Modules

| Module | Provides |
|---|---|
| `NumSimDependency` | `numsim_dependency(name TARGET … GIT_REPOSITORY … GIT_TAG … [SIBLING dir] [FIND_PACKAGE_ARGS …] [NO_FIND_PACKAGE] [OPTIONS VAR=val …])`. Resolution order: existing target → `FETCHCONTENT_SOURCE_DIR_<NAME>` → sibling checkout under `NUMSIM_DEVEL_DIR` (default `..`, `NUMSIM_PREFER_SIBLINGS`) → `find_package` → FetchContent at the pinned tag. Subprojects are `SYSTEM`; `OPTIONS` are cache variables set without `FORCE` and only for subprojects. |
| `NumSimGoogleTest` | `numsim_googletest()`: `GTest::gtest`, installed or fetched (v1.15.2). |
| `NumSimTesting` | `numsim_add_test(name SOURCES … LINK … [MPI_PROCS n…] [NO_MAIN] [NO_SANITIZERS] [TSAN] [INCLUDE_DIRS …])`: the executable plus `<name>_asan` (ASan+UBSan) and optionally `<name>_tsan`, all registered with ctest (`NUMSIM_SANITIZER_TESTS`, default ON). Handles `mpiexec --oversubscribe` detection and the libtsan/ASLR workaround. |
| `NumSimWarnings` | `numsim_target_warnings(target [WERROR])`: `-Wall -Wextra -Wpedantic -Wconversion`. |

## Conventions these modules encode

- Every dependency is pinned to a tag (or commit); `main`/`master` are never fetched.
- Options are prefixed per project (`NUMSIM_CORE_…`, `NUMSIM_MATERIALS_…`, `NUMSIM_FFT_…`) and never set with `FORCE` from outside.
- Toolchain baseline: C++23 with `std::expected` (GCC ≥ 13, Clang ≥ 19); tmech is C++17.

## Tests

`cmake -S . -B build && ctest --test-dir build` configures a fixture
consumer against a sibling checkout, an explicit override and a pinned
fetch from a local git repository.
