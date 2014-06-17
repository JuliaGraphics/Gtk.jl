# GLists

GTK functions that return a `GList` can be used in Julia's iteration syntax in the following way:

```
for obj in GLib.GList(ccall((:gtk_function_that_returns_a_GList,libgtk), Ptr{_GSList{T}}, types, args...))
    # do something with obj
end
```
Here `obj` will be a `Ptr{T}`, where for `T` you pick the expected element type.

# Utility functions

#### `GLib.bytestring(ptr, own::Bool)`

This variant of `bytestring` allows you to specify whether Julia "owns" the memory pointed to by `ptr`.
This is useful for `GList` iteration when wishing to return strings created by a GTK object.
