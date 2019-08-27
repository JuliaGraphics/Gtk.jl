using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

# These are the two binary objects we care about
products = Product[
    LibraryProduct(prefix, ["libglib"], :glib),
    LibraryProduct(prefix, ["libgobject"], :gobject),
    LibraryProduct(prefix, ["libgtk"], :gtk),
    LibraryProduct(prefix, ["libgdk"], :gdk),
    LibraryProduct(prefix, ["libgdk_pixbuf"], :gdk_pixbuf),
    LibraryProduct(prefix, ["libgio"], :gio)
]

dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Glib-v2.59.0%2B0/build_Glib.v2.59.0.jl",

]


for dependency in dependencies
    file = joinpath(@__DIR__, basename(dependency))
    isfile(file) || download(dependency, file)
    # it's a bit faster to run the build in an anonymous module instead of
    # starting a new julia process

    # Build the dependencies
    Mod = @eval module Anon end
    Mod.include(file)
end

# Finally, write out a deps.jl file
write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
