# GtkCanvas is the plain Gtk drawing canvas built on Cairo.
type GtkCanvas <: GtkDrawingArea # NOT an @GType
    handle::Ptr{GObject}
    is_realized::Bool
    is_sized::Bool
    mouse::MouseHandler
    resize::Union{Function,Void}
    draw::Union{Function,Void}
    back::CairoSurface   # backing store
    backcc::CairoContext

    function GtkCanvas(w=-1, h=-1)
        da = ccall((:gtk_drawing_area_new,libgtk),Ptr{GObject},())
        ccall((:gtk_widget_set_size_request,libgtk),Void,(Ptr{GObject},Int32,Int32), da, w, h)
        widget = new(da, false, false, MouseHandler(), nothing, nothing)
        widget.mouse.widget = widget
        signal_connect(notify_realize,widget,"realize",Void,())
        signal_connect(notify_unrealize,widget,"unrealize",Void,())
        on_signal_resize(notify_resize, widget)
        if gtk_version == 3
            signal_connect(canvas_on_draw_event,widget,"draw",Cint,(Ptr{Void},))
        else
            signal_connect(canvas_on_expose_event,widget,"expose-event",Cint,(Ptr{Void},))
        end
        on_signal_button_press(mousedown_cb, widget, false, widget.mouse)
        on_signal_button_release(mouseup_cb, widget, false, widget.mouse)
        on_signal_motion(mousemove_cb, widget, 0, 0, false, widget.mouse)
        on_signal_scroll(mousescroll_cb, widget, false, widget.mouse)
        return gobject_ref(widget)
    end
end
const GtkCanvasLeaf = GtkCanvas
macro GtkCanvas(args...)
    :( GtkCanvas($(map(esc,args)...)) )
end

function notify_realize(::Ptr{GObject}, widget::GtkCanvas)
    widget.is_realized = true
    widget.is_sized && notify_resize(
        convert(Ptr{GObject}, C_NULL),
        convert(Ptr{GdkRectangle}, C_NULL),
        widget)
    nothing
end

function notify_unrealize(::Ptr{GObject}, widget::GtkCanvas)
    widget.is_realized = false
    widget.is_sized = false
    nothing
end

function notify_resize(::Ptr{GObject}, size::Ptr{GdkRectangle}, widget::GtkCanvas)
    widget.is_sized = true
    if widget.is_realized
        widget.back = cairo_surface_for(widget)
        widget.backcc = CairoContext(widget.back)
        if isa(widget.resize,Function)
            widget.resize(widget)
        end
        draw(widget,false)
    end
    nothing
end

function resize(config::Function, widget::GtkCanvas)
    widget.resize = config
    if widget.is_realized && widget.is_sized
        widget.resize(widget)
        draw(widget, false)
    end
    nothing
end

function draw(redraw::Function, widget::GtkCanvas)
    widget.draw = redraw
    draw(widget, false)
    nothing
end

function draw(widget::GtkCanvas, immediate::Bool=true)
    if widget.is_realized && widget.is_sized
        if isa(widget.draw,Function)
            widget.draw(widget)
        end
        reveal(widget, immediate)
    end
end

function cairo_surface_for(widget::GtkCanvas)
    w, h = width(widget), height(widget)
    CairoSurface(
        ccall((:gdk_window_create_similar_surface,libgdk), Ptr{Void},
        (Ptr{Void}, GEnum, Int32, Int32),
        gdk_window(widget), Cairo.CONTENT_COLOR_ALPHA, w, h),
    w, h)
end

function canvas_on_draw_event(::Ptr{GObject},cc::Ptr{Void},widget::GtkCanvas) # cc is a Cairo context
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    int32(false) # propagate the event further
end

function canvas_on_expose_event(::Ptr{GObject},e::Ptr{Void},widget::GtkCanvas) # e is a GdkEventExpose
    cc = ccall((:gdk_cairo_create,libgdk),Ptr{Void},(Ptr{Void},),gdk_window(widget))
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    ccall((:cairo_destroy,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    int32(false) # propagate the event further
end

getgc(c::GtkCanvas) = c.backcc
cairo_surface(c::GtkCanvas) = c.back
