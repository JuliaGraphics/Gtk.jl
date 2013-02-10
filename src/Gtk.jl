#TODO: generic events handlers
#TODO: layouts
#TODO: other GtkWidgets
#TODO: separate types into a new file

#include(joinpath(Pkg.dir(),"GTK","deps","ext.jl"))
require("Cairo")

module GTK
using Cairo
import Base.convert

export Window, GTKCanvas, Canvas,
    cairo_surface_for, width, height, reveal, cairo_context, cairo_surface,
    gtk_doevent

    
if OS_NAME == :Darwin
    const libgtk = "libgtk-quartz-2.0"
elseif OS_NAME == :Windows
    const libgtk = "libgtk-win32-2.0-0"
else
    const libgtk = "libgtk-x11-2.0"
end

abstract GTKWidget
typealias GtkWidget Ptr{Void}
typealias Enum Int32

type GdkRectangle
    x::Int32
    y::Int32
    width::Int32
    height::Int32
    GdkRectangle(x,y,w,h) = new(x,y,w,h)
end
type GdkPoint
    x::Int32
    y::Int32
    GdkPoint(x,y) = new(x,y)
end

baremodule GtkWindowType
    const GTK_WINDOW_TOPLEVEL = 0
    const GTK_WINDOW_POPUP = 1
end
baremodule GConnectFlags
    const G_CONNECT_AFTER = 1
    const G_CONNECT_SWAPPED = 2
end

gtk_doevent(::Int32) = gtk_doevent()
function gtk_doevent()
    while (ccall((:gtk_events_pending,libgtk), Bool, ()))
        quit = ccall((:gtk_main_iteration,libgtk), Bool, ())
        if quit
            #TODO: emit_event("gtk quit")
            break
        end
    end
end
function init()
    if !ccall((:gtk_init_check,libgtk), Bool, (Ptr{Void}, Ptr{Void}), C_NULL, C_NULL)
        error( "Failed to initialize GTK" )
    end
    global timeout
    timeout = Base.TimeoutAsyncWork(gtk_doevent)
    Base.start_timer(timeout,int64(20),int64(20))
end

convert(::Type{GtkWidget},w::GTKWidget) = w.handle
gdk_window(w::GTKWidget) = ccall((:gtk_widget_get_window,libgtk),Ptr{Void},(GtkWidget,),w)

function g_signal_connect_data(w::GTKWidget,sig::ASCIIString,cb::Ptr{Function},gconnectflags)
    ccall((:g_signal_connect_data,libgtk),Uint,(Ptr{Void},Ptr{Uint8},Ptr{Function},
        Int,Ptr{Function},Enum),w,sig,cb,w.index,C_NULL,gconnectflags)
end

width(w::GTKWidget) = w.all.width #int(ccall((:gtk_widget_get_allocated_width,libgtk),Int32,(GtkWidget,),w))
height(w::GTKWidget) = w.all.height #int(ccall((:gtk_widget_get_allocated_height,libgtk),Int32,(GtkWidget,),w))

function cairo_surface_for(w::GTKWidget)
    CairoSurface(ccall((:gdk_window_create_similar_surface,libgtk),Ptr{Void},(Ptr{Void},Enum,Int32,Int32), 
        gdk_window(w), CAIRO_CONTENT_COLOR_ALPHA, width(w), height(w)),
    width(w), height(w))
end

type Window <: GTKWidget
    handle::GtkWidget
    index::Int
    destroyed::Bool
    all::GdkRectangle
    function Window(title, w, h)
        global windows
        hnd = ccall((:gtk_window_new,libgtk),GtkWidget,(Enum,),GtkWindowType.GTK_WINDOW_TOPLEVEL)
        ccall((:gtk_window_set_title,libgtk),Void,(GtkWidget,Ptr{Uint8}),hnd,title)
        ccall((:gtk_window_set_resizable,libgtk),Void,(GtkWidget,Bool),hnd,false)
        ccall((:gtk_widget_set_size_request,libgtk),Void,(GtkWidget,Int32,Int32),hnd,w,h)
        ccall((:gtk_widget_show_all,libgtk),Void,(GtkWidget,),hnd)
        widget = new(hnd, length(windows)+1, false, GdkRectangle(0,0,w,h))
        push!(windows, widget)
        g_signal_connect_data(widget,"destroy",
            pointer(Function,uint(cfunction(window_on_destroy,Bool,(GtkWidget,Int)))),0)
        gtk_doevent()
        widget
    end
end
Window(title) = Window(title, 200, 200)
const windows = Window[]

function window_on_destroy(w::GtkWidget,index::Int)
    widget = windows[index]
    widget.destroyed = true
end

# GTKCanvas is the plain GTK window. This one is double-buffered
# and built on Cairo.
type Canvas <: GTKWidget
    handle::GtkWidget
    index::Int
    destroyed::Bool
    c::GTKWidget
    all::GdkRectangle
    back::CairoSurface   # backing store
    backcc::CairoContext

    function Canvas(parent, w, h)
        global canvases
        da = ccall((:gtk_drawing_area_new,libgtk),GtkWidget,())
        ccall((:gtk_widget_set_size_request,libgtk),Void,(GtkWidget,Int32,Int32), da, w, h);
        ccall((:gtk_container_add,libgtk),Void,(GtkWidget,GtkWidget), parent, da);
        if w < 0 w = width(parent) end
        if h < 0 h = height(parent) end
        widget = new(da, length(canvases)+1, false, parent, GdkRectangle(0,0,w,h))
        widget.back = cairo_surface_for(widget)
        widget.backcc = CairoContext(widget.back)
        push!(canvases, widget)
        #g_signal_connect_data(widget,"draw",cfunction(canvas_on_draw_event,Bool,(GtkWidget,Ptr{Void},Int)),0)
        g_signal_connect_data(widget,"expose-event",
            pointer(Function,uint(cfunction(canvas_on_expose_event,Bool,(GtkWidget,Ptr{Void},Int)))),0)
        g_signal_connect_data(widget,"destroy",
            pointer(Function,uint(cfunction(canvas_on_destroy,Bool,(GtkWidget,Int)))),0)
        ccall((:gtk_widget_show,libgtk),Void,(GtkWidget,),widget)
        widget
    end
end
Canvas(parent) = Canvas(parent, -1, -1)
const canvases = Canvas[]

function canvas_on_draw_event(w::GtkWidget,e::Ptr{Void},index::Int)
    widget = canvases[index]
    cc = CairoContext(e)
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    false
end

function canvas_on_expose_event(w::GtkWidget,e::Ptr{Void},index::Int)
    widget = canvases[index]
    cc = ccall((:gdk_cairo_create,libgtk),Ptr{Void},(Ptr{Void},),gdk_window(widget))
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    ccall((:cairo_destroy,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    false
end

function canvas_on_destroy(w::GtkWidget,index::Int)
    widget = canvases[index]
    widget.destroyed = true
end
    

reveal(c::Canvas) = repaint(c)
function repaint(c::Canvas)
    region = ccall((:gdk_region_rectangle,libgtk),Ptr{Void},(Ptr{GdkRectangle},),&c.all)
    ccall((:gdk_window_invalidate_region,libgtk),Void,(Ptr{Void},Ptr{Void},Bool),
        gdk_window(c),region,true)
end

cairo_context(c::Canvas) = c.backcc
cairo_surface(c::Canvas) = c.back

init()
end
