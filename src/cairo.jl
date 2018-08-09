import Cairo._jl_libcairo

# GtkCanvas is the plain Gtk drawing canvas built on Cairo.
mutable struct GtkCanvas <: GtkDrawingArea # NOT an @GType
    handle::Ptr{GObject}
    is_realized::Bool
    is_sized::Bool
    mouse::MouseHandler
    resize::Union{Function, Nothing}
    draw::Union{Function, Nothing}
    back::CairoSurface   # backing store
    backcc::CairoContext

    function GtkCanvas(w = -1, h = -1)
        da = ccall((:gtk_drawing_area_new, libgtk), Ptr{GObject}, ())
        ccall((:gtk_widget_set_size_request, libgtk), Nothing, (Ptr{GObject}, Int32, Int32), da, w, h)
        ids = Vector{Culong}(undef, 0)
        widget = new(da, false, false, MouseHandler(ids), nothing, nothing)
        widget.mouse.widget = widget
        signal_connect(notify_realize, widget, "realize", Nothing, ())
        signal_connect(notify_unrealize, widget, "unrealize", Nothing, ())
        on_signal_resize(notify_resize, widget)
        if libgtk_version >= v"3"
            signal_connect(canvas_on_draw_event, widget, "draw", Cint, (Ptr{Nothing},))
        else
            signal_connect(canvas_on_expose_event, widget, "expose-event", Cint, (Ptr{Nothing},))
        end
        push!(ids, on_signal_button_press(mousedown_cb, widget, false, widget.mouse))
        push!(ids, on_signal_button_release(mouseup_cb, widget, false, widget.mouse))
        push!(ids, on_signal_motion(mousemove_cb, widget, 0, 0, false, widget.mouse))
        push!(ids, on_signal_scroll(mousescroll_cb, widget, false, widget.mouse))
        return gobject_ref(widget)
    end
end
const GtkCanvasLeaf = GtkCanvas
macro GtkCanvas(args...)
    :( GtkCanvas($(map(esc, args)...)) )
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
        if isa(widget.resize, Function)
            widget.resize(widget)
        end
        draw(widget, false)
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

function draw(widget::GtkCanvas, immediate::Bool = true)
    if widget.is_realized && widget.is_sized
        if isa(widget.draw, Function)
            widget.draw(widget)
        end
        reveal(widget, immediate)
    end
end

function cairo_surface_for(widget::GtkCanvas)
    w, h = width(widget), height(widget)
    CairoSurface(
        ccall((:gdk_window_create_similar_surface, libgdk), Ptr{Nothing},
        (Ptr{Nothing}, GEnum, Int32, Int32),
        gdk_window(widget), Cairo.CONTENT_COLOR_ALPHA, w, h),
    w, h)
end

function canvas_on_draw_event(::Ptr{GObject}, cc::Ptr{Nothing}, widget::GtkCanvas) # cc is a Cairo context
    ccall((:cairo_set_source_surface, _jl_libcairo), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}, Float64, Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint, _jl_libcairo), Nothing, (Ptr{Nothing},), cc)
    Int32(false) # propagate the event further
end

function canvas_on_expose_event(::Ptr{GObject}, e::Ptr{Nothing}, widget::GtkCanvas) # e is a GdkEventExpose
    cc = ccall((:gdk_cairo_create, libgdk), Ptr{Nothing}, (Ptr{Nothing},), gdk_window(widget))
    ccall((:cairo_set_source_surface, _jl_libcairo), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}, Float64, Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint, _jl_libcairo), Nothing, (Ptr{Nothing},), cc)
    ccall((:cairo_destroy, _jl_libcairo), Nothing, (Ptr{Nothing},), cc)
    Int32(false) # propagate the event further
end

getgc(c::GtkCanvas) = c.backcc
cairo_surface(c::GtkCanvas) = c.back
