#include <string>

#include <greet/greet.hpp>
#include <gtest/gtest.h>

TEST(GreetTest, output) {
  EXPECT_STREQ(greet("World").c_str(), "Hello World!");
  EXPECT_STREQ(greet("Galaxy").c_str(), "Hello Galaxy!");
  EXPECT_STREQ(greet("Universe").c_str(), "Hello Universe!");
}
