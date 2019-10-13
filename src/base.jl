unsafe_convert(::Type{Ptr{GObject}}, w::AbstractStringLike) = unsafe_convert(Ptr{GObject}, GtkLabelLeaf(w))

destroy(w::GtkWidget) = @sigatom ccall((:gtk_widget_destroy, libgtk), Nothing, (Ptr{GObject},), w)
parent(w::GtkWidget) = convert(GtkWidget, ccall((:gtk_widget_get_parent, libgtk), Ptr{GObject}, (Ptr{GObject},), w))
hasparent(w::GtkWidget) = ccall((:gtk_widget_get_parent, libgtk), Ptr{Nothing}, (Ptr{GObject},), w) != C_NULL
function toplevel(w::GtkWidget)
    p = unsafe_convert(Ptr{GObject}, w)
    pp = p
    while pp != C_NULL
        p = pp
        pp = ccall((:gtk_widget_get_parent, libgtk), Ptr{GObject}, (Ptr{GObject},), p)
    end
    convert(GtkWidget, p)
end
function allocation(widget::Gtk.GtkWidget)
    allocation_ = Array(GdkRectangle)
    ccall((:gtk_widget_get_allocation, libgtk), Nothing, (Ptr{GObject}, Ptr{GdkRectangle}), widget, allocation_)
    return allocation_[1]
end
width(w::GtkWidget) = ccall((:gtk_widget_get_allocated_width, libgtk), Cint, (Ptr{GObject},), w)
height(w::GtkWidget) = ccall((:gtk_widget_get_allocated_height, libgtk), Cint, (Ptr{GObject},), w)
size(w::GtkWidget) = (width(w), height(w))

gdk_window(w::GtkWidget) = ccall((:gtk_widget_get_window, libgtk), Ptr{Nothing}, (Ptr{GObject},), w)
screen_size(w::GtkWindowLeaf) = screen_size(Gtk.GAccessor.screen(w))

### Functions and methods common to all GtkWidget objects
visible(w::GtkWidget) = Bool(ccall((:gtk_widget_get_visible, libgtk), Cint, (Ptr{GObject},), w))
visible(w::GtkWidget, state::Bool) = @sigatom ccall((:gtk_widget_set_visible, libgtk), Nothing, (Ptr{GObject}, Cint), w, state)
show(w::GtkWidget) = (@sigatom ccall((:gtk_widget_show, libgtk), Nothing, (Ptr{GObject},), w); w)
showall(w::GtkWidget) = (@sigatom ccall((:gtk_widget_show_all, libgtk), Nothing, (Ptr{GObject},), w); w)
hide(w::GtkWidget) = (@sigatom ccall((:gtk_widget_hide , libgtk),Cvoid,(Ptr{GObject},),w); w)
grab_focus(w::GtkWidget) = (@sigatom ccall((:gtk_widget_grab_focus , libgtk), Cvoid, (Ptr{GObject},), w); w)

# TODO Use Pango type PangoFontDescription once it is wrapped
modifyfont(w::GtkWidget, font_desc::Ptr{Nothing}) =
   ccall((:gtk_widget_modify_font, libgtk), Nothing, (Ptr{GObject}, Ptr{Nothing}), w, font_desc)


function get_gtk_property(w::GtkContainer, name::AbstractStringLike, child::GtkWidget, ::Type{T}) where T
    v = gvalue(T)
    ccall((:gtk_container_child_get_property, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, child, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset, libgobject), Nothing, (Ptr{GValue},), v)
    return val
end

#property(w::GtkContainer, value, child::GtkWidget, ::Type{T}) = error("missing Gtk property-name to set")
set_gtk_property!(w::GtkContainer, name::AbstractStringLike, child::GtkWidget, ::Type{T}, value) where {T} = set_gtk_property!(w, name, child, convert(T, value))
function set_gtk_property!(w::GtkContainer, name::AbstractStringLike, child::GtkWidget, value)
    ccall((:gtk_container_child_set_property, libgtk), Nothing,
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
    if ex.head == :do && length(ex.args) >= 2 && ex.args[2].head == :->
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
        (ex.head == :(=) && isa(ex.args[1], Expr) && ex.args[1].head == :call) ||
        ex.head == :function
    ) || error("@guarded requires an expression defining a function")
    quote
        begin
            try
                $(ex.args[2])
            catch err
                @warn("Error in @guarded callback")
                Base.display_error(err, catch_backtrace())
                $retval
            end
        end
    end
end




@deprecate getindex(w::GtkContainer, child::GtkWidget, name::AbstractStringLike, T::Type) get_gtk_property(w, name, child, T)
@deprecate setindex!(w::GtkContainer, value, child::GtkWidget, name::AbstractStringLike, T::Type) set_gtk_property!(w, name, child, T, value)
@deprecate setindex!(w::GtkContainer, value, child::GtkWidget, name::AbstractStringLike) set_gtk_property!(w, name, child, value)

GtkAccelGroupLeaf() = GtkAccelGroupLeaf(
    ccall((:gtk_accel_group_new, libgtk), Ptr{GObject}, ()))

function push!(w::GtkWidget, accel_signal::AbstractStringLike, accel_group::GtkAccelGroup,
               accel_key::Integer, accel_mods::Integer, accel_flags::Integer)
    ccall((:gtk_widget_add_accelerator, libgtk), Nothing,
         (Ptr{GObject}, Ptr{UInt8}, Ptr{GObject}, Cuint, Cint, Cint),
          w, bytestring(accel_signal), accel_group, accel_key, accel_mods, accel_flags)
    w
end
