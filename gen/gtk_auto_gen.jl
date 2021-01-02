using Clang
using GTK3_jll
import Serialization

include("gtk_list_gen.jl")
include("gtk_get_set_gen.jl")
include("gtk_consts_gen.jl")

function without_linenums!(ex::Expr)
    linenums_filter(x,ex) = true
    linenums_filter(x::LineNumberNode,ex) = false
    linenums_filter(x::Expr,ex) = x.head !== :line
    linenums_filter(x::Nothing,ex) = ex.head !== :block
    filter!((x)->linenums_filter(x,ex), ex.args)
    for arg in ex.args
        if isa(arg,Expr)
            without_linenums!(arg)
        end
    end
    ex
end

# If there is an error about missing some std headers, e.g. fatal error: 'time.h' file not found,
# set this to `stdlib/include/on/your/specific/platform` (see https://github.com/JuliaInterop/Clang.jl)
const STD_INCLUDE = ""

const LIBGTK3_INCLUDE = joinpath(GTK3_jll.artifact_dir, "include", "gtk-3.0", "gtk")
const SOURCES = vcat(GTK3_jll.PATH_list, GTK3_jll.LIBPATH_list)
const DEPENDENCIES = vcat([readdir(dep; join=true) for dep in joinpath.(SOURCES, "..", "include") if isdir(dep)]...) .|> normpath
# glibconfig.h
const ADDITIONAL = vcat([joinpath.(readdir(dep; join=true), "include") for dep in joinpath.(SOURCES, "..", "lib") if isdir(dep)]...) .|> normpath
const gtk_h = joinpath(LIBGTK3_INCLUDE, "gtk.h")

toplevels = Any[]
let gtk_version = 3
    global trans_unit, root_cursor
    # parse headers
    cd(Sys.BINDIR) do
        global trans_unit = parse_header(gtk_h,
        args=["-I", joinpath(LIBGTK3_INCLUDE, ".."), "-I$(STD_INCLUDE)"],
        includes=vcat(LIBGTK3_INCLUDE, CLANG_INCLUDE, DEPENDENCIES, ADDITIONAL),
        flags=0x41)
    end
    
    root_cursor = getcursor(trans_unit)
    
    gboxpath = "gbox$(gtk_version)"
    gconstspath = "gconsts$(gtk_version)"
    cachepath = "gtk$(gtk_version)"
    
    g_types = gen_g_type_lists(root_cursor)
    for z in g_types
        for (s, ex) in z
            without_linenums!(ex)
        end
    end
    
    body = Expr(:block,
        Meta.parse("import ..Gtk"),
        Meta.parse("import ..Gtk.GObject"),
    )
    
    gbox = Expr(:toplevel,Expr(:module, true, :GAccessor, body))
    count_fcns = gen_get_set(body, root_cursor)
    println("Generated $gboxpath with $count_fcns function definitions")
    without_linenums!(gbox)
    
    body = Expr(:block)
    gconsts = Expr(:toplevel,Expr(:module, true, :GConstants, body))
    count_consts = gen_consts(body, root_cursor)
    println("Generated $gconstspath with $count_consts constants")
    without_linenums!(gconsts)
    
    open(joinpath(@__DIR__, gboxpath), "w") do cache
        Base.println(cache,"quote")
        Base.show_unquoted(cache, gbox)
        println(cache)
        Base.println(cache,"end")
    end
    open(joinpath(@__DIR__, gconstspath), "w") do cache
        Base.println(cache,"quote")
        Base.show_unquoted(cache, gconsts)
        println(cache)
        Base.println(cache,"end")
    end
    ser_version = Serialization.ser_version
    open(joinpath(@__DIR__, "$(cachepath)_julia_ser$(ser_version)"), "w") do cache
        Serialization.serialize(cache, gbox)
        Serialization.serialize(cache, gconsts)
    end
    push!(toplevels, (gbox, gconsts, g_types, gtk_h))
end
toplevels
