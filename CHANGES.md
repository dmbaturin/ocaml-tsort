# Changelog

## 2.1.0

Allow the same dependency to be specified more than once.
This allows correct handling of inputs like this:

```
Tsort.sort_strongly_connected_components @@
  [(1, [2]); (2, [1]); (1, [3])]
```

Tsort no longer depends on the containers library.

# 2.0.0

API overhaul, support for cyclic graphs (thanks to Martin Jambon).
