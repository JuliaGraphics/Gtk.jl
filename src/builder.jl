export GtkBuilder, getObject

type GtkBuilder
  handle::Ptr{Void}
end

function GtkBuilder(filename::String)
    handle = ccall((:gtk_builder_new,libgtk), Ptr{Void}, () )
	error_check::Ptr{Void} = 0
        ccall((:gtk_builder_add_from_file ,libgtk), Int32,
            (Ptr{Void}, Ptr{Uint8}, Ptr{GError}),
            handle, bytestring(filename), error_check)

	GtkBuilder(handle)
end

function getObject{T}(builder::GtkBuilder, widgetId::String, ::Type{T})
    ptr = ccall((:gtk_builder_get_object ,libgtk), Ptr{GObjectI},
        (Ptr{Void}, Ptr{Uint8}),
         builder.handle, bytestring(widgetId))
    T(ptr)
end
