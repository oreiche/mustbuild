#include <iostream>
#include <string>

#include <greet/greet.hpp>

int test(std::string const &output, std::string const &expect) {
  if (output != expect) {
    std::cout << "Mismatch: '" << output << "' != '" << expect << "'\n";
    return 1;
  }
  return 0;
}

int main() {
  int failed{};
  failed += test(greet("World"), "Hello World!");
  failed += test(greet("Galaxy"), "Hello Galaxy!");
  failed += test(greet("Universe"), "Hello Universe!");

  if (failed > 0) {
    std::cout << failed << " tests failed.\n";
    return 1;
  }

  std::cout << "All tests passed.\n";
  return 0;
}
