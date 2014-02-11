@gtktype GtkBuilder

function GtkBuilder(filename::String)
    handle = ccall((:gtk_builder_new,libgtk), Ptr{GObjectI}, () )
	error_check::Ptr{Void} = 0
        ccall((:gtk_builder_add_from_file ,libgtk), Int32,
            (Ptr{GObjectI}, Ptr{Uint8}, Ptr{GError}),
            handle, bytestring(filename), error_check)

	GtkBuilder(handle)
end

start(builder::GtkBuilder) = glist_iter(ccall((:gtk_builder_get_objects,libgtk), Ptr{_GSList{GObject}}, (Ptr{GObject},), builder))
next(w::GtkBuilder, list) = next(list[1],list)
done(w::GtkBuilder, list) = done(list[1],list)
length(builder::GtkBuilder) = length(start(builder)[1])
getindex(builder::GtkBuilder, i::Integer) = convert(GtkWidgetI,start(builder)[1][i])::GtkWidgetI
