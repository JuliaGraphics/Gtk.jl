if libgtk_version >= v"3"

    function GtkCssProviderLeaf(; data = nothing, filename = nothing)
        source_count = (data !== nothing) + (filename !== nothing)
        @assert(source_count <= 1,
            "GtkCssProvider must have at most one data or filename argument")
        provider = GtkCssProviderLeaf(ccall((:gtk_css_provider_get_default, libgtk), Ptr{GObject}, ()))
        if data !== nothing
            GError() do error_check
              ccall((:gtk_css_provider_load_from_data, libgtk), Bool,
                (Ptr{GObject}, Ptr{UInt8}, Clong, Ptr{Ptr{GError}}),
                provider, bytestring(data), -1, error_check)
            end
        elseif filename !== nothing
            GError() do error_check
              ccall((:gtk_css_provider_load_from_path, libgtk), Bool,
                (Ptr{GObject}, Ptr{UInt8}, Ptr{Ptr{GError}}),
                provider, bytestring(filename), error_check)
            end
        end
        return provider
    end

    GtkStyleContextLeaf() = GtkStyleContextLeaf(ccall((:gtk_style_context_new, libgtk), Ptr{GObject}, ()))

    push!(context::GtkStyleContext, provider::GObject, priority::Integer) =
      ccall((:gtk_style_context_add_provider, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}, Cuint),
             context, provider, priority)
end
