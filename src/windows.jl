type GtkWindow <: GtkBinI
    handle::Ptr{GObject}
    function GtkWindow(title, w=-1, h=-1, resizable=true, toplevel=true)
        hnd = ccall((:gtk_window_new,libgtk),Ptr{GObject},(Enum,),
            toplevel?GtkWindowType.TOPLEVEL:GtkWindowType.POPUP)
        ccall((:gtk_window_set_title,libgtk),Void,(Ptr{GObject},Ptr{Uint8}),hnd,title)
        if resizable
            ccall((:gtk_window_set_default_size,libgtk),Void,(Ptr{GObject},Int32,Int32),hnd,w,h)
        else
            ccall((:gtk_window_set_resizable,libgtk),Void,(Ptr{GObject},Bool),hnd,false)
            ccall((:gtk_widget_set_size_request,libgtk),Void,(Ptr{GObject},Int32,Int32),hnd,w,h)
        end
        widget = gc_ref(new(hnd))
        gtk_doevent()
        show(widget)
        widget
    end
end

#GtkScrolledWindow
#GtkSeparator — A separator widget
