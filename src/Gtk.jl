# julia Gtk interface

module Gtk

include("GLib/GLib.jl")
using .GLib
using .GLib.MutableTypes
using Cairo

import .GLib: new, setproperty!, getproperty, StringLike, bytestring
import Base: convert, show, showall, run, size, resize!, length, getindex, setindex!,
             insert!, push!, unshift!, shift!, pop!, splice!, delete!,
             start, next, done, parent, isempty, empty!, first, last, in,
             eltype, copy, isvalid, string
import Base.Graphics: width, height, getgc
import Cairo: destroy

typealias Index Union(Integer,AbstractVector{TypeVar(:I,Integer)})

include("basic_exports.jl")
include("long_exports.jl")
include(joinpath("..","deps","ext.jl"))

include("gtktypes.jl")
include("gdk.jl")
include("events.jl")
include("container.jl")
include("windows.jl")
include("layout.jl")
include("displays.jl")
include("lists.jl")
include("buttons.jl")
include("input.jl")
include("text.jl")
include("menus.jl")
include("selectors.jl")
include("misc.jl")
include("cairo.jl")
include("builder.jl")
include("toolbar.jl")
include("theme.jl")
include("gio.jl")
include("application.jl")

new{T<:Union(GtkBox,GtkPaned,GtkScale)}(::Type{T}, orientation::Symbol, args...) = new(T,
        (orientation==:v ? true :
        (orientation==:h ? false :
        error("invalid $T orientation $orientation"))),
    args...)

export GAccessor
let cachedir = joinpath(splitdir(@__FILE__)[1], "..", "gen")
    fastgtkcache = joinpath(cachedir,"gtk$(gtk_version)_julia$(VERSION.major)_$(VERSION.minor)")
    if isfile(fastgtkcache) && true
        open(fastgtkcache) do cache
            while !eof(cache)
                eval(deserialize(cache))
            end
        end
    else
        gboxcache = joinpath(cachedir,"gbox$(gtk_version)")
        map(eval, include(gboxcache).args)
        constcache = joinpath(cachedir,"gconsts$(gtk_version)")
        map(eval,include(constcache).args)
    end
end
const _ = GAccessor
using .GConstants

# Alternative Interface (`using Gtk.ShortNames`)
module ShortNames
    using ..Gtk
    export Gtk
    include("basic_exports.jl")
    include("short_exports.jl")
end
using .ShortNames

end
