# numsim_googletest() -- GTest::gtest / GTest::gtest_main, installed or fetched.
macro(numsim_googletest)
    numsim_dependency(GTest
        TARGET GTest::gtest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        v1.15.2
        OPTIONS INSTALL_GTEST=OFF gtest_force_shared_crt=ON)
endmacro()
