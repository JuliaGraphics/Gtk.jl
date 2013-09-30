type GtkWindow <: GtkBin
    handle::Ptr{GtkWidget}
    all::GdkRectangle
    function GtkWindow(title, w=-1, h=-1, resizable=true, toplevel=true)
        hnd = ccall((:gtk_window_new,libgtk),Ptr{GtkWidget},(Enum,),
            toplevel?GtkWindowType.TOPLEVEL:GtkWindowType.POPUP)
        ccall((:gtk_window_set_title,libgtk),Void,(Ptr{GtkWidget},Ptr{Uint8}),hnd,title)
        if resizable
            ccall((:gtk_window_set_default_size,libgtk),Void,(Ptr{GtkWidget},Int32,Int32),hnd,w,h)
        else
            ccall((:gtk_window_set_resizable,libgtk),Void,(Ptr{GtkWidget},Bool),hnd,false)
            ccall((:gtk_widget_set_size_request,libgtk),Void,(Ptr{GtkWidget},Int32,Int32),hnd,w,h)
        end
        widget = new(hnd, GdkRectangle(0,0,w,h))
        on_signal_resize(widget, notify_resize, widget)
        gtk_doevent()
        gc_ref(widget)
    end
end
const Window = GtkWindow
const TopLevel = Window # deprecated

#GtkScrolledWindow
#GtkSeparator — A separator widget
