
function GtkCssProviderLeaf(; data = nothing, filename = nothing)
    source_count = (data !== nothing) + (filename !== nothing)
    @assert(source_count <= 1,
        "GtkCssProvider must have at most one data or filename argument")
    provider = GtkCssProviderLeaf(ccall((:gtk_css_provider_new, libgtk), Ptr{GObject}, ()))
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

push!(context::GtkStyleContext, provider::GObject, priority::Integer) = ccall(
    (:gtk_style_context_add_provider, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}, Cuint),
    context, provider, priority
)

icon_theme_get_default() = ccall((:gtk_icon_theme_get_default, Gtk.libgtk), Ptr{GObject}, ())

icon_theme_append_search_path(icon_theme, path::AbstractString) = ccall(
    (:gtk_icon_theme_append_search_path, libgtk), Cvoid, (Ptr{GObject}, Ptr{UInt8}),
    icon_theme, path
)

function icon_theme_load_icon_for_scale(icon_theme, icon_name::AbstractString, size::Integer, scale::Integer, flags::Integer)
    local pixbuf::Ptr{GObject}
    Gtk.GError() do error_check
        pixbuf = ccall(
            (:gtk_icon_theme_load_icon_for_scale, libgtk),
            Ptr{GObject},
            (Ptr{GObject}, Ptr{UInt8}, Cint, Cint, Cint, Ptr{Ptr{GError}}),
            icon_theme, bytestring(icon_name), size, scale, flags, error_check
        )
        return pixbuf !== C_NULL
    end
    return convert(GdkPixbuf, pixbuf)
end