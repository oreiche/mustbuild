#include "greet/greet.hpp"

#include <sstream>

std::string greet(std::string const &name) {
  auto greeting = "Hello";

  std::ostringstream out{};
  out << greeting;
  out << " ";
  out << name;
  out << "!";

  return out.str();
}
