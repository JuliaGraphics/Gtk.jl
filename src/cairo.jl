# GTKCanvas is the plain GTK window. This one is double-buffered
# and built on Cairo.
type Canvas <: GTKWidget
    handle::GtkWidget
    parent::GTKWidget
    all::GdkRectangle
    redraw::Union(Function,Nothing)
    redrawp::Ptr{Void} # function Void(GTKWidget, CairoSurface)
    back::CairoSurface   # backing store
    backcc::CairoContext

    function Canvas(parent::GTKWidget, w, h, redraw::Union(Function,Nothing))
        da = ccall((:gtk_drawing_area_new,libgtk),GtkWidget,())
        ccall((:gtk_widget_set_size_request,libgtk),Void,(GtkWidget,Int32,Int32), da, w, h);
        ccall((:gtk_container_add,libgtk),Void,(GtkWidget,GtkWidget), parent, da);
        widget = new(da, parent, GdkRectangle(0,0,w,h))
        on_signal_redraw(widget, redraw)
        on_signal_resize(widget, notify_resize)
        if gtk_version == 3
            signal_connect(widget,"draw",
                cfunction(canvas_on_draw_event,Bool,(GtkWidget,Ptr{Void},Canvas)),0)
        else
            signal_connect(widget,"expose-event",
                cfunction(canvas_on_expose_event,Void,(GtkWidget,Ptr{Void},Canvas)),0)
        end
        ccall((:gtk_widget_show,libgtk),Void,(GtkWidget,),widget)
        gc_preserve(widget)
    end
end
Canvas(parent::GTKWidget, redraw=nothing) = Canvas(parent, -1, -1, redraw)

width(c::Canvas) = c.all.width
height(c::Canvas) = c.all.height

function on_signal_redraw(widget::Canvas, resize_cb::Union(Function,Nothing))
    widget.redraw = resize_cb
    widget.redrawp = try
            cfunction(redraw, Void, (Canvas, CairoSurface))
        catch err
            C_NULL
        end
    if widget.all.width > 0 && widget.all.height > 0
        if widget.redrawp != C_NULL
            ccall(widget.redrawp, Void, (Any, Any), widget, widget.back)
        elseif isa(widget.redraw, Function)
            widget.redraw(widget, widget.back)
        end
    end
    nothing
end

function notify_resize(::GtkWidget, size::Ptr{GdkRectangle}, widget::Canvas)
    widget.all = unsafe_load(size)
    widget.back = cairo_surface_for(widget)
    widget.backcc = CairoContext(widget.back)
    if widget.redrawp != C_NULL
        ccall(widget.resizep, Void, (Any, Any), widget, widget.back)
    elseif isa(widget.redraw, Function)
        widget.redraw(widget, widget.back)
    end
    nothing
end

function cairo_surface_for(widget::Canvas)
    w, h = width(widget), height(widget)
    CairoSurface(
        ccall((:gdk_window_create_similar_surface,libgtk), Ptr{Void},
        (Ptr{Void}, Enum, Int32, Int32), 
        gdk_window(widget), CAIRO_CONTENT_COLOR_ALPHA, w, h),
    w, h)
end

function canvas_on_draw_event(::GtkWidget,cc::Ptr{Void},widget::Canvas) # cc is a Cairo context
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    false # propagate the event further
end

function canvas_on_expose_event(::GtkWidget,e::Ptr{Void},widget::Canvas) # e is a GdkEventExpose
    cc = ccall((:gdk_cairo_create,libgtk),Ptr{Void},(Ptr{Void},),gdk_window(widget))
    ccall((:cairo_set_source_surface,Cairo._jl_libcairo), Void,
        (Ptr{Void},Ptr{Void},Float64,Float64), cc, widget.back.ptr, 0, 0)
    ccall((:cairo_paint,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    ccall((:cairo_destroy,Cairo._jl_libcairo),Void, (Ptr{Void},), cc)
    nothing
end

getgc(c::Canvas) = c.backcc
cairo_surface(c::Canvas) = c.back
