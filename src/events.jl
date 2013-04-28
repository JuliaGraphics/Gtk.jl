
gtk_doevent(::Int32) = gtk_doevent()
function gtk_doevent()
    try
        while (ccall((:gtk_events_pending,libgtk), Bool, ()))
            quit = ccall((:gtk_main_iteration,libgtk), Bool, ())
            if quit
                #TODO: emit_event("gtk quit")
                break
            end
        end
    catch err
        Base.display_error(err, catch_backtrace())
        println()
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

function signal_connect(w::GTKWidget,sig::ASCIIString,cb::Ptr{Void},gconnectflags)
    ccall((:g_signal_connect_data,libgtk), Culong,
        (GtkWidget, Ptr{Uint8}, Ptr{Void}, Any, Ptr{Void}, Enum),
        w, sig, cb, w, C_NULL, gconnectflags)
end
# Signals API for the cb pointer
# GTK 2
#   https://developer.gnome.org/gtk2/stable/GtkObject.html#GtkObject-destroy
#   https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed
# GTK 3
#   https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed

function signal_disconnect(w::GTKWidget, handler_id::Culong)
    ccall(:g_signal_handler_disconnect, Void, (GtkWidget, Culong), w, handler_id)
end

function on_signal_resize{T<:GTKWidget}(widget::T, resize_cb::Function)
    signal_connect(widget, "size-allocate",
        cfunction(resize_cb, Void, (GtkWidget, Ptr{GdkRectangle}, T)), 0)
end
function notify_resize(::GtkWidget, size::Ptr{GdkRectangle}, widget::GTKWidget)
    widget.all = unsafe_load(size)
    nothing
end

function on_signal_destroy{T<:GTKWidget}(widget::T, destroy_cb::Function)
    signal_connect(widget, "destroy",
        cfunction(destroy_cb, Void, (GtkWidget, T)), 0)
end

function reveal(c::GTKWidget)
    region = ccall((:gdk_region_rectangle,libgtk),Ptr{Void},(Ptr{GdkRectangle},),&c.all)
    ccall((:gdk_window_invalidate_region,libgtk),Void,(Ptr{Void},Ptr{Void},Bool),
        gdk_window(c), region, true)
end

