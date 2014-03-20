if gtk_version == 3
@gtktype GtkCssProvider
GtkCssProviderLeaf() = GtkCssProviderLeaf(ccall((:gtk_css_provider_get_default,libgtk),Ptr{GObject},()))

function GtkCssProviderLeaf(;data=nothing,filename=nothing)
    source_count = (data!==nothing) + (filename!==nothing)
    @assert(source_count <= 1,
        "GtkCssProvider must have at most one data or filename argument")
    provider = GtkCssProviderLeaf(ccall((:gtk_css_provider_get_default,libgtk),Ptr{GObject},()))
    if data !== nothing
        GError() do error_check
          ccall((:gtk_css_provider_load_from_data,libgtk), Bool,
            (Ptr{GObject}, Ptr{Uint8}, Clong, Ptr{Ptr{GError}}),
            provider, bytestring(data), -1, error_check)
        end
    elseif filename !== nothing
        GError() do error_check
          ccall((:gtk_css_provider_load_from_path,libgtk), Bool,
            (Ptr{GObject}, Ptr{Uint8}, Clong, Ptr{Ptr{GError}}),
            provider, bytestring(filename), error_check)
        end
    end
    return provider
end

typealias GtkStyleProvider Union(GtkCssProvider)

@gtktype GtkStyleContext
GtkStyleContextLeaf() = GtkStyleContextLeaf(ccall((:gtk_style_context_new,libgtk),Ptr{GObject},()))

push!(context::GtkStyleContext, provider::GtkStyleProvider, priority::Integer) =
  ccall((:gtk_style_context_add_provider,libgtk),Void,(Ptr{GObject},Ptr{GObject},Cuint), 
         context,provider,priority)
else
    type GtkCssProvider end
    type GtkStyleContext end
    GtkCssProviderLeaf(x...) = error("GtkStyleContext is not available until Gtk3.0")
    GtkStyleContextLeaf(x...) = error("GtkStyleContext is not available until Gtk3.0")
end
