# julia Gtk interface

module Gtk

const suffix = :Leaf
include("GLib/GLib.jl")
using .GLib
using .GLib.MutableTypes
importall .GLib.Compat
import .GLib: setproperty!, getproperty, StringLike, bytestring
import .GLib:
    signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock,
    signal_emit

import Base: convert, show, showall, run, size, resize!, length, getindex, setindex!,
             insert!, push!, append!, unshift!, shift!, pop!, splice!, delete!, deleteat!,
             select!, start, next, done, parent, isempty, empty!, first, last, in,
             eltype, copy, isvalid, string, sigatomic_begin, sigatomic_end

if VERSION < v"0.4.0-dev+3275"
    import Base.Graphics: width, height, getgc
else
    import Graphics: width, height, getgc
end

using Cairo
import Cairo: destroy

typealias Index Union(Integer,AbstractVector{TypeVar(:I,Integer)})

export GAccessor
include("basic_exports.jl")
include("long_exports.jl")
include("long_leaf_exports.jl")
include(joinpath("..","deps","ext.jl"))

include("interfaces.jl")
include("boxes.jl")
include("gtktypes.jl")
include("base.jl")
include("gdk.jl")
include("events.jl")
include("container.jl")
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

const ser_version = VERSION >= v"0.4-" ? Base.Serializer.ser_version : Base.ser_version
let cachedir = joinpath(splitdir(@__FILE__)[1], "..", "gen")
    fastgtkcache = joinpath(cachedir,"gtk$(gtk_version)_julia_ser$(ser_version)")
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

include("windows.jl")

# Alternative Interface (`using Gtk.ShortNames`)
module ShortNames
    using ..Gtk
    import ..GLib:
        signal_connect, signal_handler_disconnect,
        signal_handler_block, signal_handler_unblock,
        signal_emit
    import ..GLib.@g_type_delegate
    import ..Gtk: suffix
    export Gtk
    include("basic_exports.jl")
    include("short_exports.jl")
    include("short_leaf_exports.jl")
end
using .ShortNames
if VERSION < v"0.3-"
  GLib.__init__()
  Gtk.__init__()
end
end
