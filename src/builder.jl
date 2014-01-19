@Gtype GtkBuilder libgtk gtk_builder

function GtkBuilder(filename::String)
    handle = ccall((:gtk_builder_new,libgtk), Ptr{GObjectI}, () )
	error_check::Ptr{Void} = 0
        ccall((:gtk_builder_add_from_file ,libgtk), Int32,
            (Ptr{GObjectI}, Ptr{Uint8}, Ptr{GError}),
            handle, bytestring(filename), error_check)

	GtkBuilder(handle)
end

function getindex(builder::GtkBuilder, widgetId::String)
    convert(GtkWidgetI, ccall((:gtk_builder_get_object ,libgtk), Ptr{GObjectI},
        (Ptr{GObjectI}, Ptr{Uint8}), builder, bytestring(widgetId)))
end

start(builder::GtkBuilder) = gslist2(ccall((:gtk_builder_get_objects,libgtk), Ptr{GSList{GObject}}, (Ptr{GObject},), builder))
next(builder::GtkBuilder, list) = next(list[1],list)
done(builder::GtkBuilder, list) = done(list[1],list)
length(builder::GtkBuilder) = length(start(builder)[2])
getindex(builder::GtkBuilder, i::Integer) = convert(GtkWidgetI,start(builder)[2][i])::GtkWidgetI