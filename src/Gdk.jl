type GdkRectangle
    x::Int32
    y::Int32
    width::Int32
    height::Int32
    GdkRectangle(x,y,w,h) = new(x,y,w,h)
end
type GdkPoint
    x::Int32
    y::Int32
    GdkPoint(x,y) = new(x,y)
end
gdk_window(w::GTKWidget) = ccall((:gtk_widget_get_window,libgtk),Ptr{Void},(GtkWidget,),w)

