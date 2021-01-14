# julia Gtk interface
module Gtk

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

# Import binary definitions
using GTK3_jll, Glib_jll, Xorg_xkeyboard_config_jll, gdk_pixbuf_jll, adwaita_icon_theme_jll, hicolor_icon_theme_jll
using Pkg.Artifacts
const libgdk = libgdk3
const libgtk = libgtk3
const libgdk_pixbuf = libgdkpixbuf


const suffix = :Leaf
include("GLib/GLib.jl")
using .GLib
using .GLib.MutableTypes
import .GLib: set_gtk_property!, get_gtk_property, getproperty, FieldRef
import .GLib:
    signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock, signal_handler_is_connected,
    signal_emit, unsafe_convert,
    AbstractStringLike, bytestring

import Base: convert, show, run, size, resize!, length, getindex, setindex!,
             insert!, push!, append!, pushfirst!, pop!, splice!, delete!, deleteat!,
             parent, isempty, empty!, first, last, in, popfirst!,
             eltype, copy, isvalid, string, sigatomic_begin, sigatomic_end, (:), iterate

export showall, select!, start

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

function __init__()
    # Set XDG_DATA_DIRS so that Gtk can find its icons and schemas
    ENV["XDG_DATA_DIRS"] = join(filter(x -> x !== nothing, [
        dirname(adwaita_icons_dir),
        dirname(hicolor_icons_dir),
        joinpath(dirname(GTK3_jll.libgdk3_path::String), "..", "share"),
        get(ENV, "XDG_DATA_DIRS", nothing)::Union{String,Nothing},
    ]), Sys.iswindows() ? ";" : ":")

    # Next, ensure that gdk-pixbuf has its loaders.cache file; we generate a
    # MutableArtifacts.toml file that maps in a loaders.cache we dynamically
    # generate by running `gdk-pixbuf-query-loaders:`
    mutable_artifacts_toml = joinpath(dirname(@__DIR__), "MutableArtifacts.toml")
    loaders_cache_name = "gdk-pixbuf-loaders-cache"
    loaders_cache_hash = artifact_hash(loaders_cache_name, mutable_artifacts_toml)
    if loaders_cache_hash === nothing
        # Run gdk-pixbuf-query-loaders, capture output,
        loader_cache_contents = gdk_pixbuf_query_loaders() do gpql
            withenv("GDK_PIXBUF_MODULEDIR" => gdk_pixbuf_loaders_dir) do
                return String(read(`$gpql`))
            end
        end

        # Write cache out to file in new artifact
        loaders_cache_hash = create_artifact() do art_dir
            open(joinpath(art_dir, "loaders.cache"), "w") do io
                write(io, loader_cache_contents)
            end
        end
        bind_artifact!(mutable_artifacts_toml,
            loaders_cache_name,
            loaders_cache_hash;
            force=true
        )
    end

    # Point gdk to our cached loaders
    ENV["GDK_PIXBUF_MODULE_FILE"] = joinpath(artifact_path(loaders_cache_hash), "loaders.cache")
    ENV["GDK_PIXBUF_MODULEDIR"] = gdk_pixbuf_loaders_dir

    if Sys.islinux() || Sys.isfreebsd()
        # Needed by xkbcommon:
        # https://xkbcommon.org/doc/current/group__include-path.html.  Related
        # to issue https://github.com/JuliaGraphics/Gtk.jl/issues/469
        ENV["XKB_CONFIG_ROOT"] = joinpath(Xorg_xkeyboard_config_jll.artifact_dir::String,
                                          "share", "X11", "xkb")
    end

    GError() do error_check
        ccall((:gtk_init_with_args, libgtk), Bool,
            (Ptr{Nothing}, Ptr{Nothing}, Ptr{UInt8}, Ptr{Nothing}, Ptr{UInt8}, Ptr{GError}),
            C_NULL, C_NULL, "Julia Gtk Bindings", C_NULL, C_NULL, error_check)
    end

    # if g_main_depth > 0, a glib main-loop is already running,
    # so we don't need to start a new one
    if ccall((:g_main_depth, GLib.libglib), Cint, ()) == 0
        global gtk_main_task = schedule(Task(gtk_main))
    end
end

const ser_version = Serialization.ser_version
let cachedir = joinpath(splitdir(@__FILE__)[1], "..", "gen")
    fastgtkcache = joinpath(cachedir, "gtk$(libgtk_version.major)_julia_ser$(ser_version)")
    if isfile(fastgtkcache) && true
        open(fastgtkcache) do cache
            while !eof(cache)
                Core.eval(Gtk, deserialize(cache))
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

if Base.VERSION >= v"1.4.2"
    include("precompile.jl")
    _precompile_()
end

# Alternative Interface (`using Gtk.ShortNames`)
module ShortNames
    using ..Gtk
    import ..GLib:
        signal_connect, signal_handler_disconnect,
        signal_handler_block, signal_handler_unblock, signal_handler_is_connected,
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
