unsafe_convert(::Type{Ptr{GObject}},w::AbstractStringLike) = unsafe_convert(Ptr{GObject},GtkLabelLeaf(w))

destroy(w::GtkWidget) = @sigatom ccall((:gtk_widget_destroy,libgtk), Void, (Ptr{GObject},), w)
parent(w::GtkWidget) = convert(GtkWidget, ccall((:gtk_widget_get_parent,libgtk), Ptr{GObject}, (Ptr{GObject},), w))
hasparent(w::GtkWidget) = ccall((:gtk_widget_get_parent,libgtk), Ptr{Void}, (Ptr{GObject},), w) != C_NULL
function toplevel(w::GtkWidget)
    p = unsafe_convert(Ptr{GObject}, w)
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
if libgtk_version >= v"3"
    width(w::GtkWidget) = ccall((:gtk_widget_get_allocated_width,libgtk),Cint,(Ptr{GObject},),w)
    height(w::GtkWidget) = ccall((:gtk_widget_get_allocated_height,libgtk),Cint,(Ptr{GObject},),w)
    size(w::GtkWidget) = (width(w),height(w))
else
    width(w::GtkWidget) = allocation(w).width
    height(w::GtkWidget) = allocation(w).height
    size(w::GtkWidget) = (a=allocation(w);(a.width,a.height))
end

### Functions and methods common to all GtkWidget objects
visible(w::GtkWidget) = Bool(ccall((:gtk_widget_get_visible,libgtk),Cint,(Ptr{GObject},),w))
visible(w::GtkWidget, state::Bool) = @sigatom ccall((:gtk_widget_set_visible,libgtk),Void,(Ptr{GObject},Cint),w,state)
show(w::GtkWidget) = (@sigatom ccall((:gtk_widget_show,libgtk),Void,(Ptr{GObject},),w); w)
showall(w::GtkWidget) = (@sigatom ccall((:gtk_widget_show_all,libgtk),Void,(Ptr{GObject},),w); w)

# TODO Use Pango type PangoFontDescription once it is wrapped
modifyfont(w::GtkWidget, font_desc::Ptr{Void}) =
   ccall((:gtk_widget_modify_font,libgtk),Void,(Ptr{GObject},Ptr{Void}),w,font_desc)

function getproperty{T}(w::GtkContainer, name::AbstractStringLike, child::GtkWidget, ::Type{T})
    v = gvalue(T)
    ccall((:gtk_container_child_get_property,libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, child, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end

#property(w::GtkContainer, value, child::GtkWidget, ::Type{T}) = error("missing Gtk property-name to set")
setproperty!{T}(w::GtkContainer, name::AbstractStringLike, child::GtkWidget, ::Type{T}, value) = setproperty!(w, name, child, convert(T,value))
function setproperty!(w::GtkContainer, name::AbstractStringLike, child::GtkWidget, value)
    ccall((:gtk_container_child_set_property,libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, child, bytestring(name), gvalue(value))
    w
end

# Shortcut for creating callbacks that don't corrupt Gtk state if
# there's an error
macro guarded(ex...)
    retval = nothing
    if length(ex) == 2
        retval = ex[1]
        ex = ex[2]
    else
        length(ex) == 1 || error("@guarded requires 1 or 2 arguments")
        ex = ex[1]
    end
    # do-block syntax
    if ex.head == :call && length(ex.args) >= 2 && ex.args[2].head == :->
        newbody = _guarded(ex.args[2], retval)
        ret = deepcopy(ex)
        ret.args[2] = Expr(ret.args[2].head, ret.args[2].args[1], newbody)
        return esc(ret)
    end
    newbody = _guarded(ex, retval)
    esc(Expr(ex.head, ex.args[1], newbody))
end

function _guarded(ex, retval)
    isa(ex, Expr) && (
        ex.head == :-> ||
        (ex.head == :(=) && isa(ex.args[1],Expr) && ex.args[1].head == :call) ||
        ex.head == :function
    ) || error("@guarded requires an expression defining a function")
    quote
        begin
            try
                $(ex.args[2])
            catch err
                warn("Error in @guarded callback")
                Base.display_error(err, catch_backtrace())
                $retval
            end
        end
    end
end


@deprecate getindex(w::GtkContainer, child::GtkWidget, name::AbstractStringLike, T::Type) getproperty(w,name,child,T)
@deprecate setindex!(w::GtkContainer, value, child::GtkWidget, name::AbstractStringLike, T::Type) setproperty!(w,name,child,T,value)
@deprecate setindex!(w::GtkContainer, value, child::GtkWidget, name::AbstractStringLike) setproperty!(w,name,child,value)

GtkAccelGroupLeaf() = GtkAccelGroupLeaf(
    ccall((:gtk_accel_group_new,libgtk),Ptr{GObject},()))

function push!(w::GtkWidget, accel_signal::AbstractStringLike, accel_group::GtkAccelGroup,
               accel_key::Integer, accel_mods::Integer, accel_flags::Integer)
    ccall((:gtk_widget_add_accelerator,libgtk), Void,
         (Ptr{GObject}, Ptr{UInt8}, Ptr{GObject}, Cuint, Cint, Cint),
          w, bytestring(accel_signal), accel_group, accel_key, accel_mods, accel_flags)
    w
end
