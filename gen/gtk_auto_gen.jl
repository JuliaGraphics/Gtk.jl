#!/usr/bin/env julia

using Clang
using GTK3_jll, GTK3_jll.Glib_jll, GTK3_jll.gdk_pixbuf_jll
using Serialization

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


const LIBGTK3_INCLUDE = joinpath(dirname(GTK3_jll.libgtk3_path), "..", "include", "gtk-3.0", "gtk") |> normpath
const DEPENDENCIES = vcat([readdir(joinpath(dep, "..", "include");join=true) for dep in vcat(GTK3_jll.PATH_list, dirname(Glib_jll.libglib_path))]...) .|> normpath
const gtk_h = joinpath(LIBGTK3_INCLUDE, "gtk.h")

toplevels = Any[]
let gtk_version = 3
    global trans_unit, root_cursor
	# parse headers
	cd(Sys.BINDIR) do
		global trans_unit = parse_header(gtk_h,
			args=["-I", joinpath(LIBGTK3_INCLUDE, "..")],
			includes=vcat(LIBGTK3_INCLUDE, CLANG_INCLUDE, DEPENDENCIES),
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
		Expr(:import, :., :., :Gtk),
		Expr(:import, :., :., :Gtk, :GObject),
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
    
	open(joinpath(splitdir(@__FILE__)[1], gboxpath), "w") do cache
		Base.println(cache,"quote")
		Base.show_unquoted(cache, gbox)
		println(cache)
		Base.println(cache,"end")
    end
	open(joinpath(splitdir(@__FILE__)[1], gconstspath), "w") do cache
		Base.println(cache,"quote")
		Base.show_unquoted(cache, gconsts)
		println(cache)
		Base.println(cache,"end")
    end
	ser_version = Serialization.ser_version
	open(joinpath(splitdir(@__FILE__)[1], "$(cachepath)_julia_ser$(ser_version)"), "w") do cache
		serialize(cache, gbox)
		serialize(cache, gconsts)
	end
	push!(toplevels, (gbox, gconsts, g_types, gtk_h))
end
toplevels