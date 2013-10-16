#https://developer.gnome.org/gtk2/stable/DisplayWidgets.html

#GtkImage — A widget displaying an image
#GtkProgressBar — A widget which indicates progress visually
#GtkStatusbar — Report messages of minor importance to the user
#GtkInfoBar — Report important messages to the user
#GtkStatusIcon — Display an icon in the system tray
#GtkSpinner — Show a spinner animation

type GdkPixbuf <: GtkObject
end


#type GtkImage <: GtkWidget
#    handle::Ptr{GtkObject}
#    GtkImage(filename) = gc_ref(new(ccall((:gtk_image_new_from_file,libgtk),Ptr{GtkObject},(Ptr{Uint8},),bytestring(filename))))
#    GtkImage(pixbuf) = gc_ref(new(ccall((:gtk_image_new_from_pixbuf,libgtk),Ptr{GtkObject},(Ptr{GdkPixbuf},),f(pixbuf))))
#end
