# julia Gtk interface
module Gtk

const suffix = :Leaf
include("GLib/GLib.jl")
using .GLib
using .GLib.MutableTypes
import .GLib: set_gtk_property!, get_gtk_property, getproperty, FieldRef
import .GLib:
    signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock,
    signal_emit, unsafe_convert,
    AbstractStringLike, bytestring

import Base: convert, show, run, size, resize!, length, getindex, setindex!,
             insert!, push!, append!, pushfirst!, pop!, splice!, delete!, deleteat!,
             parent, isempty, empty!, first, last, in, popfirst!,
             eltype, copy, isvalid, string, sigatomic_begin, sigatomic_end, (:), iterate

if VERSION < v"1.0"
  import Base: showall, select!, start
else
  export showall, select!, start
end

using Reexport
@reexport using Graphics
import .Graphics: width, height, getgc

using Cairo
import Cairo: destroy
using Serialization

const Index{I<:Integer} = Union{I, AbstractVector{I}}

export GAccessor
include("basic_exports.jl")
include("long_exports.jl")
include("long_leaf_exports.jl")
include(joinpath("..", "deps", "ext.jl"))

global const libgtk_version = VersionNumber(
      ccall((:gtk_get_major_version, libgtk), Cint, ()),
      ccall((:gtk_get_minor_version, libgtk), Cint, ()),
      ccall((:gtk_get_micro_version, libgtk), Cint, ()))

include("gdk.jl")
include("interfaces.jl")
include("boxes.jl")
include("gtktypes.jl")
include("base.jl")
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

const ser_version = Serialization.ser_version
let cachedir = joinpath(splitdir(@__FILE__)[1], "..", "gen")
    fastgtkcache = joinpath(cachedir, "gtk$(libgtk_version.major)_julia_ser$(ser_version)")
    if isfile(fastgtkcache) && true
        open(fastgtkcache) do cache
            while !eof(cache)
                Core.eval(deserialize(cache))
            end
        end
    else
        gboxcache = joinpath(cachedir, "gbox$(libgtk_version.major)")
        map(eval, include(gboxcache).args)
        constcache = joinpath(cachedir, "gconsts$(libgtk_version.major)")
        map(eval, include(constcache).args)
    end
end
const _ = GAccessor
using .GConstants

include("windows.jl")
include("gl_area.jl")

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
end
