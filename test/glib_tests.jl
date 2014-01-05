using GLib;
include("../deps/ext.jl")

ccall((:gtk_init, libgtk), Void,(Ptr{Void},Ptr{Void}),C_NULL,C_NULL)

hnd = ccall((:gtk_window_new, libgtk),Ptr{GObject},(Cint,),0)

wrap = convert(GObject, hnd)
#detect type and create wrapper (if neccessary) at runtime
@assert string(typeof(wrap)) == "GtkWindow"

wrap2 = convert(GObject, hnd)
@assert wrap == wrap2

print(wrap,'\n') #should display properties
