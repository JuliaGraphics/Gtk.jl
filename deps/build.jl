using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

# These are the two binary objects we care about
products = Product[
    LibraryProduct(prefix, ["libz"], :libz),
    LibraryProduct(prefix, ["libglib"], :libglib),
    LibraryProduct(prefix, ["libgobject"], :gobject),
    LibraryProduct(prefix, ["libgio"], :gio),
    # Gets to here!
    LibraryProduct(prefix, ["libgtk"], :gtk),
    LibraryProduct(prefix, ["libgdk"], :gdk),
    LibraryProduct(prefix, ["libgdk_pixbuf"], :gdk_pixbuf),

]

dependencies = [
    # We need zlib
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    # We need libffi
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libffi-v3.2.1-0/build_Libffi.v3.2.1.jl",
    # We need gettext
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Gettext-v0.19.8-0/build_Gettext.v0.19.8.jl",
    # We need pcre
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/PCRE-v8.42-2/build_PCRE.v8.42.0.jl",
    # We need iconv
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libiconv-v1.15-0/build_Libiconv.v1.15.0.jl",
    # We need Glib
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
