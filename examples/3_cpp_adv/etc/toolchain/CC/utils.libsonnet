// User-defined utility functions
{
  // Helper function for key lookup from map
  get(key, map_var, default):: lookup(key, var(map_var, map()), default),
}
