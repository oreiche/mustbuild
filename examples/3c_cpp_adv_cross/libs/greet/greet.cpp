#include "greet/greet.hpp"

#ifdef USE_FMTLIB
#include <fmt/format.h>
#else
#include <sstream>
#endif

std::string greet(std::string const &name) {
  auto greeting = "Hello";

#ifdef USE_FMTLIB
  return fmt::format("{} {}!", greeting, name);
#else
  std::ostringstream out{};
  out << greeting;
  out << " ";
  out << name;
  out << "!";
  return out.str();
#endif
}
