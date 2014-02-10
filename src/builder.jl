@gtktype GtkBuilder

function GtkBuilder(;buffer=nothing,filename=nothing,resource=nothing)
    builder = GtkBuilder( ccall((:gtk_builder_new,libgtk), Ptr{GObjectI}, () ) )
    push!(builder,buffer=buffer,filename=filename,resource=resource)
    builder
end

function push!(builder::GtkBuilder;buffer=nothing,filename=nothing,resource=nothing)
    source_count = (buffer!==nothing) + (filename!==nothing) + (resource!==nothing)
    @assert(source_count == 1,
        "push!(GtkBuilder) must have exactly one buffer, filename, or resource argument")
    if buffer !== nothing
        GError() do error_check
          ret = ccall((:gtk_builder_add_from_string ,libgtk), Cuint,
            (Ptr{GObjectI}, Ptr{Uint8}, Culong, Ptr{Ptr{GError}}),
            builder, bytestring(buffer), -1, error_check)
          return ret != 0
        end
    elseif filename !== nothing
        GError() do error_check    
          ret = ccall((:gtk_builder_add_from_file ,libgtk), Cuint,
            (Ptr{GObjectI}, Ptr{Uint8}, Ptr{Ptr{GError}}),
            builder, bytestring(filename), error_check)
          return ret != 0  
        end            
    elseif resource !== nothing    
        GError() do error_check    
          ret = ccall((:gtk_builder_add_from_resource ,libgtk), Cuint,
            (Ptr{GObjectI}, Ptr{Uint8}, Ptr{Ptr{GError}}),
            builder, bytestring(resource), error_check)
          return ret != 0
        end          
    end
    return builder
end

start(builder::GtkBuilder) = gslist2(ccall((:gtk_builder_get_objects,libgtk), Ptr{GSList{GObject}}, (Ptr{GObject},), builder))
next(builder::GtkBuilder, list) = next(list[1],list)
done(builder::GtkBuilder, list) = done(list[1],list)
length(builder::GtkBuilder) = length(start(builder)[1])
getindex(builder::GtkBuilder, i::Integer) = convert(GtkWidgetI,start(builder)[2][i])::GtkWidgetI
