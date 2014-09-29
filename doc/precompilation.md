# Precompilation

For this to work, you need to be building Julia from source, and you need to be using
at least Julia version 0.3.

In your Julia `base/` directory, create (or append to) a file called `userimg.jl` the line

    require("Gtk")

Then build Julia as you normally would; the Gtk module will be available when julia starts.

In some cases, it might be necessary to add the path to the folder containing the Gtk shared libraries, for example:

    push!(DL_LOAD_PATH, "/usr/lib/x86_64-linux_gnu")
    require("Gtk")
    pop!(DL_LOAD_PATH)

The `"/usr/lib/x86_64-linux_gnu"` needs to be replaced with the location of the GTK libraries on your system.
However, when the library is in a standard location -- such as `/usr/lib`, `/usr/local/lib`, or `/usr/lib/x86_64-linux_gnu` (on some systems) -- this step can be skipped.