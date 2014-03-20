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

@gtktype GtkButton
GtkButtonLeaf() = GtkButtonLeaf(ccall((:gtk_button_new,libgtk),Ptr{GObject},()))
GtkButtonLeaf(title::String) =
    GtkButtonLeaf(ccall((:gtk_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@gtktype GtkCheckButton
GtkCheckButtonLeaf() = GtkCheckButtonLeaf(ccall((:gtk_check_button_new,libgtk),Ptr{GObject},()))
GtkCheckButtonLeaf(title::String) =
    GtkCheckButtonLeaf(ccall((:gtk_check_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@gtktype GtkToggleButton
GtkToggleButtonLeaf() = GtkToggleButtonLeaf(ccall((:gtk_toggle_button_new,libgtk),Ptr{GObject},()))
GtkToggleButtonLeaf(title::String) =
    GtkToggleButtonLeaf(ccall((:gtk_toggle_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

if gtk_version >= 3
    @gtktype GtkSwitch
    GtkSwitchLeaf() = GtkSwitchLeaf(ccall((:gtk_switch_new,libgtk),Ptr{GObject},()))
    function GtkSwitchLeaf(active::Bool)
        b = GtkSwitchLeaf()
        ccall((:gtk_switch_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
        b
    end
else
    const GtkSwitch = GtkToggleButton
end

@gtktype GtkRadioButton
GtkRadioButtonLeaf(group::Ptr{Void}=C_NULL) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new,libgtk),Ptr{GObject},
        (Ptr{Void},),group))
GtkRadioButtonLeaf(group::Ptr{Void},label::String) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),group,bytestring(label)))
GtkRadioButtonLeaf(label::String) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),C_NULL,bytestring(label)))
GtkRadioButtonLeaf(group::GtkRadioButton) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},),group))
GtkRadioButtonLeaf(group::GtkRadioButton,label::String) =
    GtkRadioButtonLeaf(ccall((:gtk_radio_button_new_with_mnemonic_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},Ptr{Uint8}),group,bytestring(label)))
GtkRadioButtonLeaf(group::GtkRadioButton,child::GtkWidget,vargs...) =
    push!(GtkRadioButtonLeaf(group,vargs...), child)

type GtkRadioButtonGroupLeaf <: GtkContainer # NOT a native @gtktype
    # when iterating/indexing elements will be in reverse / *random* order

    # the behavior is specified as undefined if the first
    # element is moved to a new group
    # do not rely on the current behavior, since it may change
    handle::GtkContainer
    anchor::GtkRadioButton
    GtkRadioButtonGroupLeaf(layout::GtkContainer) = new(layout)
end
GtkRadioButtonGroupLeaf() = GtkRadioButtonGroupLeaf(GtkBoxLeaf(true))
function GtkRadioButtonGroupLeaf(elem::Vector, active::Int=1)
    grp = GtkRadioButtonGroupLeaf()
    for (i,e) in enumerate(elem)
        push!(grp, e, i==active)
    end
    grp
end
convert(::Type{Ptr{GObject}},grp::GtkRadioButtonGroupLeaf) = convert(Ptr{GObject},grp.handle)
show(io::IO,::GtkRadioButtonGroupLeaf) = print(io,"GtkRadioButtonGroupLeaf()")
function push!(grp::GtkRadioButtonGroupLeaf,e::GtkRadioButton,active::Bool)
    push!(grp, e)
    gtk_toggle_button_set_active(e, active)
    grp
end
function push!(grp::GtkRadioButtonGroupLeaf,e::GtkRadioButton)
    if isdefined(grp,:anchor)
        setproperty!(e,:group,grp.anchor)
    else
        grp.anchor = e
    end
    push!(grp.handle, e)
    grp
end
function push!(grp::GtkRadioButtonGroupLeaf,label,active::Union(Bool,Nothing)=nothing)
    if isdefined(grp,:anchor)
        e = GtkRadioButtonLeaf(grp.anchor, label)
    else
        grp.anchor = e = GtkRadioButtonLeaf(label)
    end
    if isa(active,Bool)
        gtk_toggle_button_set_active(e,active::Bool)
    end
    push!(grp.handle, e)
    grp
end
function start(grp::GtkRadioButtonGroupLeaf)
    if isempty(grp)
        list = convert(Ptr{_GList{GtkRadioButton}},C_NULL)
    else
        list = ccall((:gtk_radio_button_get_group,libgtk), Ptr{_GList{GtkRadioButton}},
            (Ptr{GObject},), grp.anchor)
    end
    list
end
next(w::GtkRadioButtonGroupLeaf,s) = next(s,s)
done(w::GtkRadioButtonGroupLeaf,s) = done(s,s)
length(w::GtkRadioButtonGroupLeaf) = length(start(w))
getindex!(w::GtkRadioButtonGroupLeaf, i::Integer) = convert(GtkRadioButton,start(w)[i])
isempty(grp::GtkRadioButtonGroupLeaf) = !isdefined(grp,:anchor)
function getproperty(grp::GtkRadioButtonGroupLeaf,name::Union(Symbol,ByteString))
    k = symbol(name)
    if k == :active
        for b in grp
            if getproperty(b,:active,Bool)
                return b
            end
        end
        error("no active elements in GtkRadioGroup")
    end
    error("GtkRadioButtonGroupLeaf has no property $name")
end

function gtk_toggle_button_set_active(b::GtkWidget, active::Bool)
    # Users are encouraged to use the syntax `setproperty!(b,:active,true)`. This is not a public function.
    ccall((:gtk_toggle_button_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
    b
end

@gtktype GtkLinkButton
GtkLinkButtonLeaf(uri::String) =
    GtkLinkButtonLeaf(ccall((:gtk_link_button_new,libgtk),Ptr{GObject},
        (Ptr{Uint8},),bytestring(uri)))
GtkLinkButtonLeaf(uri::String,label::String) =
    GtkLinkButtonLeaf(ccall((:gtk_link_button_new_with_label,libgtk),Ptr{GObject},
        (Ptr{Uint8},Ptr{Uint8}),bytestring(uri),bytestring(label)))
function GtkLinkButtonLeaf(uri::String,label::String,visited::Bool)
    b = GtkLinkButtonLeaf(uri,label)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end
function GtkLinkButtonLeaf(uri::String,visited::Bool)
    b = GtkLinkButtonLeaf(uri)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end

#TODO: @gtktype GtkScaleButton

@gtktype GtkVolumeButton
GtkVolumeButtonLeaf() = GtkVolumeButtonLeaf(ccall((:gtk_volume_button_new,libgtk),Ptr{GObject},()))
function GtkVolumeButtonLeaf(value::Real) # 0<=value<=1
    b = GtkVolumeButtonLeaf()
    ccall((:gtk_scale_button_set_value,libgtk),Void,(Ptr{GObject},Cdouble),b,value)
    b
end

@gtktype GtkFontButton
GtkFontButtonLeaf() = GtkFontButtonLeaf(ccall((:gtk_font_button_new,libgtk),Ptr{GObject},()))

typealias GtkFontChooser Union(GtkFontButton)
