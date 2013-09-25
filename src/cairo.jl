# Canvas is the plain Gtk drawing canvas built on Cairo.
type Canvas <: GtkWidget
    handle::Ptr{GtkWidget}
    all::GdkRectangle
    mouse::MouseHandler
    resize::Union(Function,Nothing)
    draw::Union(Function,Nothing)
    back::CairoSurface   # backing store
    backcc::CairoContext

    function Canvas(w, h)
        da = ccall((:gtk_drawing_area_new,libgtk),Ptr{GtkWidget},())
        ccall((:gtk_widget_set_double_buffered,libgtk),Void,(Ptr{GtkWidget},Int32), da, false)
        ccall((:gtk_widget_set_size_request,libgtk),Void,(Ptr{GtkWidget},Int32,Int32), da, w, h)
        widget = new(da, GdkRectangle(0,0,w,h), MouseHandler(), nothing, nothing)
        widget.mouse.widget = widget
        on_signal_resize(widget, notify_resize, widget)
        if gtk_version == 3
            signal_connect(widget,"draw",widget,
                cfunction(canvas_on_draw_event,Cint,(Ptr{GtkWidget},Ptr{Void},Canvas)),0)
        else
            signal_connect(widget,"expose-event",widget,
                cfunction(canvas_on_expose_event,Void,(Ptr{GtkWidget},Ptr{Void},Canvas)),0)
        end
        on_signal_button_press(widget, mousedown_cb, widget.mouse)
        on_signal_button_release(widget, mouseup_cb, widget.mouse)
        on_signal_motion(widget, mousemove_cb, widget.mouse, 0, 0)
        gc_ref(widget)
    end
end
Canvas(w, h) = Canvas(false, w, h)
Canvas() = Canvas(-1,-1)

function notify_resize(::Ptr{GtkWidget}, size::Ptr{GdkRectangle}, widget::Canvas)
    widget.all = unsafe_load(size)
    widget.back = cairo_surface_for(widget)
    widget.backcc = CairoContext(widget.back)
    if isa(widget.resize,Function)
        widget.resize(widget)
    end
    draw(widget,false)
    nothing
end

function resize(config::Function, widget::Canvas)
    widget.resize = config
    if widget.all.width > 0 && widget.all.height > 0
        if isa(widget.resize, Function)
            widget.resize(widget)
        end
        draw(widget, false)
    end
end

function draw(redraw::Function, widget::Canvas)
    widget.draw = redraw
    draw(widget, false)
end

function draw(widget::Canvas, immediate::Bool=true)
    if widget.all.width > 0 && widget.all.height > 0
        if isa(widget.draw,Function)
            widget.draw(widget)
        end
        reveal(widget, immediate)
    end
end

function cairo_surface_for(widget::Canvas)
    w, h = width(widget), height(widget)
    CairoSurface(
        ccall((:gdk_window_create_similar_surface,libgdk), Ptr{Void},
        (Ptr{Void}, Enum, Int32, Int32), 
        gdk_window(widget), Cairo.CONTENT_COLOR_ALPHA, w, h),
    w, h)
end

function canvas_on_draw_event(::Ptr{GtkWidget},cc::Ptr{Void},widget::Canvas) # cc is a Cairo context
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    int32(false) # propagate the event further
end

function canvas_on_expose_event(::Ptr{GtkWidget},e::Ptr{Void},widget::Canvas) # e is a GdkEventExpose
    cc = ccall((:gdk_cairo_create,libgdk),Ptr{Void},(Ptr{Void},),gdk_window(widget))
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    ccall((:cairo_destroy,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    nothing
end

getgc(c::Canvas) = c.backcc
cairo_surface(c::Canvas) = c.back

