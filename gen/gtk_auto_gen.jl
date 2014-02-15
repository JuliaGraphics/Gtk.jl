#!/usr/bin/env julia

import Clang.cindex
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

#    mfile = tempname()*".h"
#    println(mfile)
#    open(mfile,"w") do h
#        mdecls = cindex.search(gtk_h, cindex.MacroDefinition)
#        for mdecl in mdecls
#            seek(h,0)
#            truncate(h,0)
#            name = cindex.spelling(mdecl)
#            if ismatch(r"^G\w*[A-Za-z]$", name)
#                println(h, "#include <gtk/gtk.h>")
#                println(h, name)
#                flush(h)
#                cd(JULIA_HOME) do
#                    gtk_macro_h = cindex.parse_header(mfile, diagnostics=true, args=args, flags=0x40)
#                end
#            end
#        end
#    end

    gboxpath = "gbox$(gtk_version)"
    gconstspath = "gconsts$(gtk_version)"
    cachepath = "gtk$(gtk_version)"

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
    push!(toplevels,gbox)
    push!(toplevels,gconsts)
end
toplevels

