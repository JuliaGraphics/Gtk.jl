# julia Gtk interface
module Gtk

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

# Import binary definitions
using GTK3_jll, Glib_jll, Xorg_xkeyboard_config_jll, gdk_pixbuf_jll, adwaita_icon_theme_jll, hicolor_icon_theme_jll
using Librsvg_jll
using JLLWrappers
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
    Sys.iswindows() && (ENV["GTK_CSD"] = 0)
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
    loaders_dir_name = "gdk-pixbuf-loaders-dir"
    loaders_dir_hash = artifact_hash(loaders_dir_name, mutable_artifacts_toml)

    if loaders_cache_hash === nothing
        if Librsvg_jll.is_available()
            # Copy loaders into a directory
            loaders_dir_hash = create_artifact() do art_dir
                loaders_dir = mkdir(joinpath(art_dir,"loaders_dir"))
                pixbuf_loaders = joinpath.(gdk_pixbuf_loaders_dir, readdir(gdk_pixbuf_loaders_dir))
                push!(pixbuf_loaders, Librsvg_jll.libpixbufloader_svg)
                cp.(pixbuf_loaders, joinpath.(loaders_dir, basename.(pixbuf_loaders)))
            end

            loaders_dir = joinpath(artifact_path(loaders_dir_hash), "loaders_dir")
            # Pkg removes "execute" permissions on Windows
            Sys.iswindows() && chmod(artifact_path(loaders_dir_hash), 0o755; recursive=true)
            # Run gdk-pixbuf-query-loaders, capture output
            loader_cache_contents = gdk_pixbuf_query_loaders() do gpql
                withenv("GDK_PIXBUF_MODULEDIR"=>loaders_dir, JLLWrappers.LIBPATH_env=>Librsvg_jll.LIBPATH[]) do
                    return String(readchomp(`$gpql`))
                end
            end

            bind_artifact!(mutable_artifacts_toml,
                loaders_dir_name,
                loaders_dir_hash;
                force=true
            )
        else  # just use the gdk_pixbuf directory
            loader_cache_contents = gdk_pixbuf_query_loaders() do gpql
                withenv("GDK_PIXBUF_MODULEDIR" => gdk_pixbuf_loaders_dir) do
                    return String(read(`$gpql`))
                end
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
    ENV["GDK_PIXBUF_MODULEDIR"] = Librsvg_jll.is_available() && loaders_dir_hash !== nothing ?
                                    joinpath(artifact_path(loaders_dir_hash), "loaders_dir") :
                                    gdk_pixbuf_loaders_dir

    if Sys.islinux() || Sys.isfreebsd()
        # Needed by xkbcommon:
        # https://xkbcommon.org/doc/current/group__include-path.html.  Related
        # to issue https://github.com/JuliaGraphics/Gtk.jl/issues/469
        ENV["XKB_CONFIG_ROOT"] = joinpath(Xorg_xkeyboard_config_jll.artifact_dir::String,
                                          "share", "X11", "xkb")
    end

    GError() do error_check
        ccall((:gtk_init_with_args, libgtk), Bool,
            (Ptr{Nothing}, Ptr{Nothing}, Ptr{UInt8}, Ptr{Nothing}, Ptr{UInt8}, Ptr{Ptr{GError}}),
            C_NULL, C_NULL, "Julia Gtk Bindings", C_NULL, C_NULL, error_check)
    end

    # if g_main_depth > 0, a glib main-loop is already running.
    # unfortunately this call does not reliably reflect the state after the
    # loop has been stopped or restarted, so only use it once at the start
    gtk_main_running[] = ccall((:g_main_depth, GLib.libglib), Cint, ()) > 0

    # Given GLib provides `g_idle_add` to specify what happens during idle, this allows
    # that call to also start the eventloop
    GLib.gtk_eventloop_f[] = enable_eventloop

    auto_idle[] = get(ENV, "GTK_AUTO_IDLE", "false") == "true"

    # by default, defer starting the event loop until either `show`, `showall`, or `g_idle_add` is called
    enable_eventloop(!auto_idle[])
end

"""
    Gtk.iteration(may_block)

Run a single interation of the Gtk event loop. If `may_block` is true, this
function will wait until events are ready to be processed. Otherwise, it will
return immediately if no events need to be processed. Returns `true` if events
were processed.
"""
function iteration(may_block::Bool)
    while events_pending()
        ccall((:g_main_context_iteration, libglib), Cint, (Ptr{Cvoid}, Cint), C_NULL, may_block)
    end
end

const pause_loop = Ref{Bool}(false)

iterate(timer) = pause_loop[] || iteration(false)

"""
    Gtk.events_pending()

Check whether events need processing by the Gtk's event loop. This function can
be used in conjuction with `iterate` to refresh the GUI during long operations
or in cases where widgets must be realized before proceeding.
"""
events_pending() = ccall((:gtk_events_pending, libgtk), Cint, ()) != 0

const mainloop_timer = Ref{Timer}()

function glib_main_simple()
    mainloop_timer[]=Timer(iterate,0.01;interval=0.005)
    wait(mainloop_timer[])
end

const auto_idle = Ref{Bool}(true) # control default via ENV["GTK_AUTO_IDLE"]
const gtk_main_running = Ref{Bool}(false)
const quit_task = Ref{Task}()
const enable_eventloop_lock = Base.ReentrantLock()
"""
    Gtk.enable_eventloop(b::Bool = true)

Set whether Gtk's event loop is running.
"""
function enable_eventloop(b::Bool = true; wait_stopped::Bool = false)
    if GLib.simple_loop[]
        if b
            auto_idle[] = false
            global glib_main_task = schedule(Task(glib_main_simple))
            return
        else
            close(mainloop_timer[])
            return
        end
    end
    lock(enable_eventloop_lock) do # handle widgets that are being shown/destroyed from different threads
        isassigned(quit_task) && wait(quit_task[]) # prevents starting while the async is still stopping
        if b
            if !is_eventloop_running()
                global gtk_main_task = schedule(Task(gtk_main))
                gtk_main_running[] = true
            end
        else
            if is_eventloop_running()
                # @async and short sleep is needer on MacOS at least, otherwise
                # the window doesn't always finish closing before the eventloop stops.
                quit_task[] = @async begin
                    sleep(0.2)
                    gtk_quit()
                    gtk_main_running[] = false
                end
                wait_stopped && wait(quit_task[])
            end
        end
    end
end

"""
    Gtk.pause_eventloop(f; force = false)

Pauses the eventloop around a function. Restores the state of the eventloop after
pausing. If GLib.simple_loop[] is disabled, respects whether Gtk.jl is configured
to allow auto-stopping of the eventloop, unless `force = true`.
"""
function pause_eventloop(f; force = false)
    if GLib.simple_loop[]
        pause_loop[] = true
        try
            f()
        finally
            pause_loop[] = false
        end
    else
        was_running = is_eventloop_running()
        (force || auto_idle[]) && enable_eventloop(false, wait_stopped = true)
        try
            f()
        finally
            (force || auto_idle[]) && enable_eventloop(was_running)
        end
    end
end

"""
    Gtk.is_eventloop_running()::Bool

Check whether Gtk's event loop is running.
"""
is_eventloop_running() = GLib.simple_loop[] ? !pause_loop[] : gtk_main_running[]

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
