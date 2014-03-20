# GtkCanvas is the plain Gtk drawing canvas built on Cairo.
@gtktype GtkDrawingArea
type GtkCanvas <: GtkDrawingArea # NOT an @GType
    handle::Ptr{GObject}
    has_allocation::Bool
    mouse::MouseHandler
    resize::Union(Function,Nothing)
    draw::Union(Function,Nothing)
    back::CairoSurface   # backing store
    backcc::CairoContext

    function GtkCanvas(w=-1, h=-1)
        da = ccall((:gtk_drawing_area_new,libgtk),Ptr{GObject},())
        ccall((:gtk_widget_set_size_request,libgtk),Void,(Ptr{GObject},Int32,Int32), da, w, h)
        widget = new(da, false, MouseHandler(), nothing, nothing)
        widget.mouse.widget = widget
        on_signal_resize(notify_resize, widget)
        if gtk_version == 3
            signal_connect(canvas_on_draw_event,widget,"draw",Cint,(Ptr{Void},))
        else
            signal_connect(canvas_on_expose_event,widget,"expose-event",Void,(Ptr{Void},))
        end
        on_signal_button_press(mousedown_cb, widget, false, widget.mouse)
        on_signal_button_release(mouseup_cb, widget, false, widget.mouse)
        on_signal_motion(mousemove_cb, widget, 0, 0, false, widget.mouse)
        gc_ref(widget)
    end
end

function notify_resize(::Ptr{GObject}, size::Ptr{GdkRectangle}, widget::GtkCanvas)
    widget.has_allocation = true
    widget.back = cairo_surface_for(widget)
    widget.backcc = CairoContext(widget.back)
    if isa(widget.resize,Function)
        widget.resize(widget)
    end
    draw(widget,false)
    nothing
end

function resize(config::Function, widget::GtkCanvas)
    widget.resize = config
    if widget.has_allocation
        if isa(widget.resize, Function)
            widget.resize(widget)
        end
        draw(widget, false)
    end
end

function draw(redraw::Function, widget::GtkCanvas)
    widget.draw = redraw
    draw(widget, false)
end

function draw(widget::GtkCanvas, immediate::Bool=true)
    if widget.has_allocation
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
        (Ptr{Void}, Enum, Int32, Int32),
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
    nothing
end

getgc(c::GtkCanvas) = c.backcc
cairo_surface(c::GtkCanvas) = c.back

