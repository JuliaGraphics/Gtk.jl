#https://developer.gnome.org/gtk2/stable/ButtonWidgets.html

#GtkButton — A widget that creates a signal when clicked on
#GtkCheckButton — Create widgets with a discrete toggle button
#GtkRadioButton — A choice from multiple check buttons
#GtkToggleButton — Create buttons which retain their state
#GtkLinkButton — Create buttons bound to a URL
#GtkScaleButton — A button which pops up a scale
#GtkVolumeButton — A button which pops up a volume control

# Introduced in Gtk3
#GtkMenuButton — A widget that shows a menu when clicked on
#GtkSwitch — A "light switch" style toggle
#GtkLockButton — A widget to unlock or lock privileged operations

GtkButtonLeaf() = GtkButtonLeaf(ccall((:gtk_button_new, libgtk), Ptr{GObject}, ()))
GtkButtonLeaf(title::AbstractString) =
    GtkButtonLeaf(ccall((:gtk_button_new_with_mnemonic, libgtk), Ptr{GObject},
        (Ptr{UInt8},), bytestring(title)))

GtkCheckButtonLeaf() = GtkCheckButtonLeaf(ccall((:gtk_check_button_new, libgtk), Ptr{GObject}, ()))
GtkCheckButtonLeaf(title::AbstractString) =
    GtkCheckButtonLeaf(ccall((:gtk_check_button_new_with_mnemonic, libgtk), Ptr{GObject},
        (Ptr{UInt8},), bytestring(title)))

GtkToggleButtonLeaf() = GtkToggleButtonLeaf(ccall((:gtk_toggle_button_new, libgtk), Ptr{GObject}, ()))
GtkToggleButtonLeaf(title::AbstractString) =
    GtkToggleButtonLeaf(ccall((:gtk_toggle_button_new_with_mnemonic, libgtk), Ptr{GObject},
        (Ptr{UInt8},), bytestring(title)))

GtkSwitchLeaf() = GtkSwitchLeaf(ccall((:gtk_switch_new, libgtk), Ptr{GObject}, ()))
function GtkSwitchLeaf(active::Bool)
    b = GtkSwitchLeaf()
    ccall((:gtk_switch_set_active, libgtk), Nothing, (Ptr{GObject}, Cint), b, active)
    b
end

GtkRadioButtonLeaf(group::Ptr{Nothing} = C_NULL) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new, libgtk), Ptr{GObject},
        (Ptr{Nothing},), group))
GtkRadioButtonLeaf(group::Ptr{Nothing}, label::AbstractString) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_with_mnemonic, libgtk), Ptr{GObject},
        (Ptr{Nothing}, Ptr{UInt8}), group, bytestring(label)))
GtkRadioButtonLeaf(label::AbstractString) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_with_mnemonic, libgtk), Ptr{GObject},
        (Ptr{Nothing}, Ptr{UInt8}), C_NULL, bytestring(label)))
GtkRadioButtonLeaf(group::GtkRadioButton) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_from_widget, libgtk), Ptr{GObject},
        (Ptr{GObject},), group))
GtkRadioButtonLeaf(group::GtkRadioButton, label::AbstractString) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_with_mnemonic_from_widget, libgtk), Ptr{GObject},
        (Ptr{GObject}, Ptr{UInt8}), group, bytestring(label)))
GtkRadioButtonLeaf(group::GtkRadioButton, child::GtkWidget, vargs...) =
    push!(GtkRadioButtonLeaf(group, vargs...), child)

mutable struct GtkRadioButtonGroup <: GtkContainer # NOT a native @gtktype
    # when iterating/indexing elements will be in reverse / * random * order

    # the behavior is specified as undefined if the first
    # element is moved to a new group
    # do not rely on the current behavior, since it may change
    handle::GtkContainer
    anchor::GtkRadioButton
    GtkRadioButtonGroup(layout::GtkContainer) = new(layout)
end
const GtkRadioButtonGroupLeaf = GtkRadioButtonGroup
macro GtkRadioButtonGroup(args...)
    :( GtkRadioButtonGroup($(map(esc, args)...)) )
end
GtkRadioButtonGroup() = GtkRadioButtonGroup(GtkBoxLeaf(true))
function GtkRadioButtonGroup(elem::Vector, active::Int = 1)
    grp = GtkRadioButtonGroup()
    for (i, e) in enumerate(elem)
        push!(grp, e, i == active)
    end
    grp
end
unsafe_convert(::Type{Ptr{GObject}}, grp::GtkRadioButtonGroup) = unsafe_convert(Ptr{GObject}, grp.handle)
show(io::IO, ::GtkRadioButtonGroup) = print(io, "GtkRadioButtonGroup()")
function push!(grp::GtkRadioButtonGroup, e::GtkRadioButton, active::Bool)
    push!(grp, e)
    gtk_toggle_button_set_active(e, active)
    grp
end
function push!(grp::GtkRadioButtonGroup, e::GtkRadioButton)
    if isdefined(grp, :anchor)
        set_gtk_property!(e, :group, grp.anchor)
    else
        grp.anchor = e
    end
    push!(grp.handle, e)
    grp
end
function push!(grp::GtkRadioButtonGroup, label, active::Union{Bool, Nothing} = nothing)
    if isdefined(grp, :anchor)
        e = GtkRadioButtonLeaf(grp.anchor, label)
    else
        grp.anchor = e = GtkRadioButtonLeaf(label)
    end
    if isa(active, Bool)
        gtk_toggle_button_set_active(e, active::Bool)
    end
    push!(grp.handle, e)
    grp
end
function start_(grp::GtkRadioButtonGroup)
    if isempty(grp)
        list = convert(Ptr{_GSList{GtkRadioButton}}, C_NULL)
    else
        list = ccall((:gtk_radio_button_get_group, libgtk), Ptr{_GSList{GtkRadioButton}},
            (Ptr{GObject},), grp.anchor)
    end
    list
end
iterate(w::GtkRadioButtonGroup, s=start_(w)) = iterate(s, s)
length(w::GtkRadioButtonGroup) = length(start_(w))
getindex!(w::GtkRadioButtonGroup, i::Integer) = convert(GtkRadioButton, start_(w)[i])
isempty(grp::GtkRadioButtonGroup) = !isdefined(grp, :anchor)

get_gtk_property(grp::GtkRadioButtonGroup, name::AbstractString) =  get_gtk_property(grp, Symbol(name))
set_gtk_property!(grp::GtkRadioButtonGroup, name::Symbol, x) =  Base.setfield!(grp, name, x)

function get_gtk_property(grp::GtkRadioButtonGroup, name::Symbol)
    if name == :active
        for b in grp
            if get_gtk_property(b, :active, Bool)
                return b
            end
        end
        error("no active elements in GtkRadioGroup")
    end
    Base.getfield(grp, name)
end

function gtk_toggle_button_set_active(b::GtkWidget, active::Bool)
    # Users are encouraged to use the syntax `set_gtk_property!(b, :active, true)`. This is not a public function.
    ccall((:gtk_toggle_button_set_active, libgtk), Nothing, (Ptr{GObject}, Cint), b, active)
    b
end

GtkLinkButtonLeaf(uri::AbstractString) =
    GtkLinkButtonLeaf(ccall((:gtk_link_button_new, libgtk), Ptr{GObject},
        (Ptr{UInt8},), bytestring(uri)))
GtkLinkButtonLeaf(uri::AbstractString, label::AbstractString) =
    GtkLinkButtonLeaf(ccall((:gtk_link_button_new_with_label, libgtk), Ptr{GObject},
        (Ptr{UInt8}, Ptr{UInt8}), bytestring(uri), bytestring(label)))
function GtkLinkButtonLeaf(uri::AbstractString, label::AbstractString, visited::Bool)
    b = GtkLinkButtonLeaf(uri, label)
    ccall((:gtk_link_button_set_visited, libgtk), Nothing, (Ptr{GObject}, Cint), b, visited)
    b
end
function GtkLinkButtonLeaf(uri::AbstractString, visited::Bool)
    b = GtkLinkButtonLeaf(uri)
    ccall((:gtk_link_button_set_visited, libgtk), Nothing, (Ptr{GObject}, Cint), b, visited)
    b
end

GtkVolumeButtonLeaf() = GtkVolumeButtonLeaf(ccall((:gtk_volume_button_new, libgtk), Ptr{GObject}, ()))
function GtkVolumeButtonLeaf(value::Real) # 0 <= value <= 1
    b = GtkVolumeButtonLeaf()
    ccall((:gtk_scale_button_set_value, libgtk), Nothing, (Ptr{GObject}, Cdouble), b, value)
    b
end

GtkFontButtonLeaf() = GtkFontButtonLeaf(ccall((:gtk_font_button_new, libgtk), Ptr{GObject}, ()))
