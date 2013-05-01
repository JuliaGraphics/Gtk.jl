type Window <: GTKWidget
    handle::GtkWidget
    all::GdkRectangle
    resizable::Bool
    function Window(title, w=-1, h=-1, resizable=true, toplevel=true)
        hnd = ccall((:gtk_window_new,libgtk),GtkWidget,(Enum,),
            toplevel?GtkWindowType.GTK_WINDOW_TOPLEVEL:GtkWindowType.GTK_WINDOW_POPUP)
        ccall((:gtk_window_set_title,libgtk),Void,(GtkWidget,Ptr{Uint8}),hnd,title)
        if resizable
            ccall((:gtk_window_set_default_size,libgtk),Void,(GtkWidget,Int32,Int32),hnd,w,h)
        else
            ccall((:gtk_window_set_resizable,libgtk),Void,(GtkWidget,Bool),hnd,false)
            ccall((:gtk_widget_set_size_request,libgtk),Void,(GtkWidget,Int32,Int32),hnd,w,h)
        end
        ccall((:gtk_widget_show_all,libgtk),Void,(GtkWidget,),hnd)
        widget = new(hnd, GdkRectangle(0,0,w,h))
        on_signal_resize(widget, notify_resize, widget)
        gtk_doevent()
        gc_ref(widget)
    end
end
const TopLevel = Window


