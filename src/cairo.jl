# Canvas is the plain GTK drawing canvas built on Cairo.
type Canvas <: GTKWidget
    handle::GtkWidget
    parent::GTKWidget
    all::GdkRectangle
    mouse::MouseHandler
    resize::Union(Function,Nothing)
    draw::Union(Function,Nothing)
    back::CairoSurface   # backing store
    backcc::CairoContext

    function Canvas(parent::GTKWidget, w, h)
        da = ccall((:gtk_drawing_area_new,libgtk),GtkWidget,())
        ccall((:gtk_widget_set_double_buffered,libgtk),Void,(GtkWidget,Int32), da, false)
        ccall((:gtk_widget_set_size_request,libgtk),Void,(GtkWidget,Int32,Int32), da, w, h)
        ccall((:gtk_container_add,libgtk),Void,(GtkWidget,GtkWidget), parent, da)
        widget = new(da, parent, GdkRectangle(0,0,w,h), MouseHandler(), nothing, nothing)
        widget.mouse.widget = widget
        on_signal_resize(widget, notify_resize, widget)
        if gtk_version == 3
            signal_connect(widget,"draw",widget,
                cfunction(canvas_on_draw_event,Cint,(GtkWidget,Ptr{Void},Canvas)),0)
        else
            signal_connect(widget,"expose-event",widget,
                cfunction(canvas_on_expose_event,Void,(GtkWidget,Ptr{Void},Canvas)),0)
        end
        on_signal_button_press(widget, mousedown_cb, widget.mouse)
        on_signal_button_release(widget, mouseup_cb, widget.mouse)
        on_signal_motion(widget, mousemove_cb, widget.mouse, 0, 0)
        ccall((:gtk_widget_show,libgtk),Void,(GtkWidget,),widget)
        gc_ref(widget)
    end
end
Canvas(parent::GTKWidget) = Canvas(parent, -1, -1)

width(c::Canvas) = c.all.width
height(c::Canvas) = c.all.height

function notify_resize(::GtkWidget, size::Ptr{GdkRectangle}, widget::Canvas)
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
        gdk_window(widget), CAIRO_CONTENT_COLOR_ALPHA, w, h),
    w, h)
end

function canvas_on_draw_event(::GtkWidget,cc::Ptr{Void},widget::Canvas) # cc is a Cairo context
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    int32(false) # propagate the event further
end

function canvas_on_expose_event(::GtkWidget,e::Ptr{Void},widget::Canvas) # e is a GdkEventExpose
    cc = ccall((:gdk_cairo_create,libgdk),Ptr{Void},(Ptr{Void},),gdk_window(widget))
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    ccall((:cairo_destroy,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    nothing
end

getgc(c::Canvas) = c.backcc
cairo_surface(c::Canvas) = c.back

