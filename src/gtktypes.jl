macro gtktype(name)
    groups = split(string(name), r"(?=[A-Z])")
    symname = symbol(join([lowercase(s) for s in groups],"_"))
    :( @Gtype $(esc(name)) libgtk $(esc(symname)))
end
@gtktype GtkWidget
@gtktype GtkContainer
@gtktype GtkBin
@gtktype GtkDialog
@gtktype GtkMenuShell

convert(::Type{Ptr{GObject}},w::StringLike) = convert(Ptr{GObject},GtkLabelLeaf(w))

destroy(w::GtkWidget) = ccall((:gtk_widget_destroy,libgtk), Void, (Ptr{GObject},), w)
parent(w::GtkWidget) = convert(GtkWidget, ccall((:gtk_widget_get_parent,libgtk), Ptr{GObject}, (Ptr{GObject},), w))
hasparent(w::GtkWidget) = ccall((:gtk_widget_get_parent,libgtk), Ptr{Void}, (Ptr{GObject},), w) != C_NULL
function toplevel(w::GtkWidget)
    p = convert(Ptr{GObject}, w)
    pp = p
    while pp != C_NULL
        p = pp
        pp = ccall((:gtk_widget_get_parent,libgtk), Ptr{GObject}, (Ptr{GObject},), p)
    end
    convert(GtkWidget, p)
end
function allocation(widget::Gtk.GtkWidget)
    allocation_ = Array(GdkRectangle)
    ccall((:gtk_widget_get_allocation,libgtk), Void, (Ptr{GObject},Ptr{GdkRectangle}), widget, allocation_)
    return allocation_[1]
end
if gtk_version > 3
    width(w::GtkWidget) = ccall((:gtk_widget_get_allocated_width,libgtk),Cint,(Ptr{GObject},),w)
    height(w::GtkWidget) = ccall((:gtk_widget_get_allocated_height,libgtk),Cint,(Ptr{GObject},),w)
    size(w::GtkWidget) = (width(w),height(w))
else
    width(w::GtkWidget) = allocation(w).width
    height(w::GtkWidget) = allocation(w).height
    size(w::GtkWidget) = (a=allocation(w);(a.width,a.height))
end

### Functions and methods common to all GtkWidget objects
visible(w::GtkWidget) = bool(ccall((:gtk_widget_get_visible,libgtk),Cint,(Ptr{GObject},),w))
visible(w::GtkWidget, state::Bool) = ccall((:gtk_widget_set_visible,libgtk),Void,(Ptr{GObject},Cint),w,state)
show(w::GtkWidget) = ccall((:gtk_widget_show,libgtk),Void,(Ptr{GObject},),w)
showall(w::GtkWidget) = ccall((:gtk_widget_show_all,libgtk),Void,(Ptr{GObject},),w)

# TODO Use Pango type PangoFontDescription once it is wrapped
modifyfont(w::GtkWidget, font_desc::Ptr{Void}) = 
   ccall((:gtk_widget_modify_font,libgtk),Void,(Ptr{GObject},Ptr{Void}),w,font_desc)

function getproperty{T}(w::GtkContainer, name::StringLike, child::GtkWidget, ::Type{T})
    v = gvalue(T)
    ccall((:gtk_container_child_get_property,libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, child, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end

#property(w::GtkContainer, value, child::GtkWidget, ::Type{T}) = error("missing Gtk property-name to set")
setproperty!{T}(w::GtkContainer, name::StringLike, child::GtkWidget, ::Type{T}, value) = setproperty!(w, name, child, convert(T,value))
function setproperty!(w::GtkContainer, name::StringLike, child::GtkWidget, value)
    ccall((:gtk_container_child_set_property,libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, child, bytestring(name), gvalue(value))
    w
end

@deprecate getindex(w::GtkContainer, child::GtkWidget, name::StringLike, T::Type) getproperty(w,name,child,T)
@deprecate setindex!(w::GtkContainer, value, child::GtkWidget, name::StringLike, T::Type) setproperty!(w,name,child,T,value)
@deprecate setindex!(w::GtkContainer, value, child::GtkWidget, name::StringLike) setproperty!(w,name,child,value)

@gtktype GtkAccelGroup
GtkAccelGroupLeaf() = GtkAccelGroupLeaf(
    ccall((:gtk_accel_group_new,libgtk),Ptr{GObject},()))

function push!(w::GtkWidget, accel_signal::StringLike, accel_group::GtkAccelGroup,
               accel_key::Integer, accel_mods::Integer, accel_flags::Integer)
    ccall((:gtk_widget_add_accelerator,libgtk), Void,
         (Ptr{GObject}, Ptr{Uint8}, Ptr{GObject}, Cuint, Cint, Cint), 
          w, bytestring(accel_signal), accel_group, accel_key, accel_mods, accel_flags)
    w
end  

