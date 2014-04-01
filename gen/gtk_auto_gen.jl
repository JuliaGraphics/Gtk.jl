#!/usr/bin/env julia

import Clang, Clang.cindex
include("gtk_list_gen.jl")
include("gtk_get_set_gen.jl")
include("gtk_consts_gen.jl")

gtk_libdir = "/opt/local/lib"

toplevels = {}
cppargs = []
for gtk_version = (2, 3)
    header = joinpath(gtk_libdir,"..","include","gtk-$gtk_version.0","gtk","gtk.h")
    args = ASCIIString[split(readall(`$(joinpath(gtk_libdir,"..","bin","pkg-config")) --cflags gtk+-$gtk_version.0`),' ')...,cppargs...]
    global gtk_h, gtk_macro_h
    cd(JULIA_HOME) do
        gtk_h = cindex.parse_header(header, diagnostics=true, args=args, flags=0x41)
    end
    gboxpath = "gbox$(gtk_version)"
    gconstspath = "gconsts$(gtk_version)"
    cachepath = "gtk$(gtk_version)"

    g_types = gen_g_type_lists(gtk_h)

    body = Expr(:block,
        Expr(:import, :., :., :Gtk),
        Expr(:import, :., :., :Gtk, :GObject),
    )
    gbox = Expr(:toplevel,Expr(:module, true, :GAccessor, body))
    count_fcns = gen_get_set(body, gtk_h)
    println("Generated $gboxpath with $count_fcns function definitions")

    body = Expr(:block)
    gconsts = Expr(:toplevel,Expr(:module, true, :GConstants, body))
    count_consts = gen_consts(body, gtk_h)
    println("Generated $gconstspath with $count_consts constants")

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
    open(joinpath(splitdir(@__FILE__)[1], "$(cachepath)_julia$(VERSION.major)_$(VERSION.minor)"), "w") do cache
        serialize(cache, gbox)
        serialize(cache, gconsts)
    end
    push!(toplevels,(gbox,gconsts,g_types,gtk_h))
end
toplevels

