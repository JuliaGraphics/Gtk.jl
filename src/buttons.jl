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
GtkButton_new() = GtkButton_new(ccall((:gtk_button_new,libgtk),Ptr{GObject},()))
GtkButton_new(title::String) =
    GtkButton_new(ccall((:gtk_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@gtktype GtkCheckButton
GtkCheckButton_new() = GtkCheckButton_new(ccall((:gtk_check_button_new,libgtk),Ptr{GObject},()))
GtkCheckButton_new(title::String) =
    GtkCheckButton_new(ccall((:gtk_check_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@gtktype GtkToggleButton
GtkToggleButton_new() = GtkToggleButton_new(ccall((:gtk_toggle_button_new,libgtk),Ptr{GObject},()))
GtkToggleButton_new(title::String) =
    GtkToggleButton_new(ccall((:gtk_toggle_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

if gtk_version >= 3
    @gtktype GtkSwitch
    GtkSwitch_new() = GtkSwitch_new(ccall((:gtk_switch_new,libgtk),Ptr{GObject},()))
    function GtkSwitch_new(active::Bool)
        b = GtkSwitch_new()
        ccall((:gtk_switch_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
        b
    end
else
    const GtkSwitch = GtkToggleButton
end

@gtktype GtkRadioButton
GtkRadioButton_new(group::Ptr{Void}=C_NULL) =
    GtkRadioButton_new(ccall((:gtk_radio_button_new,libgtk),Ptr{GObject},
        (Ptr{Void},),group))
GtkRadioButton_new(group::Ptr{Void},label::String) =
    GtkRadioButton_new(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),group,bytestring(label)))
GtkRadioButton_new(label::String) =
    GtkRadioButton_new(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),C_NULL,bytestring(label)))
GtkRadioButton_new(group::GtkRadioButton) =
    GtkRadioButton_new(ccall((:gtk_radio_button_new_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},),group))
GtkRadioButton_new(group::GtkRadioButton,label::String) =
    GtkRadioButton_new(ccall((:gtk_radio_button_new_with_mnemonic_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},Ptr{Uint8}),group,bytestring(label)))
GtkRadioButton_new(group::GtkRadioButton,child::GtkWidget,vargs...) =
    push!(GtkRadioButton_new(group,vargs...), child)

type GtkRadioButtonGroupLeaf <: GtkContainer # NOT a native @gtktype
    # when iterating/indexing elements will be in reverse / *random* order

    # the behavior is specified as undefined if the first
    # element is moved to a new group
    # do not rely on the current behavior, since it may change
    handle::GtkContainer
    anchor::GtkRadioButton
    GtkRadioButtonGroupLeaf(layout::GtkContainer) = new(layout)
end
const GtkRadioButtonGroup_new = GtkRadioButtonGroupLeaf
GtkRadioButtonGroup_new() = GtkRadioButtonGroup_new(GtkBox_new(true))
function GtkRadioButtonGroup_new(elem::Vector, active::Int=1)
    grp = GtkRadioButtonGroup_new()
    for (i,e) in enumerate(elem)
        push!(grp, e, i==active)
    end
    grp
end
convert(::Type{Ptr{GObject}},grp::GtkRadioButtonGroup_new) = convert(Ptr{GObject},grp.handle)
show(io::IO,::GtkRadioButtonGroup_new) = print(io,"GtkRadioButtonGroup_new()")
function push!(grp::GtkRadioButtonGroup_new,e::GtkRadioButton,active::Bool)
    push!(grp, e)
    gtk_toggle_button_set_active(e, active)
    grp
end
function push!(grp::GtkRadioButtonGroup_new,e::GtkRadioButton)
    if isdefined(grp,:anchor)
        setproperty!(e,:group,grp.anchor)
    else
        grp.anchor = e
    end
    push!(grp.handle, e)
    grp
end
function push!(grp::GtkRadioButtonGroup_new,label,active::Union(Bool,Nothing)=nothing)
    if isdefined(grp,:anchor)
        e = GtkRadioButton_new(grp.anchor, label)
    else
        grp.anchor = e = GtkRadioButton_new(label)
    end
    if isa(active,Bool)
        gtk_toggle_button_set_active(e,active::Bool)
    end
    push!(grp.handle, e)
    grp
end
function start(grp::GtkRadioButtonGroup_new)
    if isempty(grp)
        list = convert(Ptr{_GList{GtkRadioButton}},C_NULL)
    else
        list = ccall((:gtk_radio_button_get_group,libgtk), Ptr{_GList{GtkRadioButton}},
            (Ptr{GObject},), grp.anchor)
    end
    list
end
next(w::GtkRadioButtonGroup_new,s) = next(s,s)
done(w::GtkRadioButtonGroup_new,s) = done(s,s)
length(w::GtkRadioButtonGroup_new) = length(start(w))
getindex!(w::GtkRadioButtonGroup_new, i::Integer) = convert(GtkRadioButton,start(w)[i])
isempty(grp::GtkRadioButtonGroup_new) = !isdefined(grp,:anchor)
function getproperty(grp::GtkRadioButtonGroup_new,name::StringLike)
    k = symbol(name)
    if k == :active
        for b in grp
            if getproperty(b,:active,Bool)
                return b
            end
        end
        error("no active elements in GtkRadioGroup")
    end
    error("GtkRadioButtonGroup_new has no property $name")
end

function gtk_toggle_button_set_active(b::GtkWidget, active::Bool)
    # Users are encouraged to use the syntax `setproperty!(b,:active,true)`. This is not a public function.
    ccall((:gtk_toggle_button_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
    b
end

@gtktype GtkLinkButton
GtkLinkButton_new(uri::String) =
    GtkLinkButton_new(ccall((:gtk_link_button_new,libgtk),Ptr{GObject},
        (Ptr{Uint8},),bytestring(uri)))
GtkLinkButton_new(uri::String,label::String) =
    GtkLinkButton_new(ccall((:gtk_link_button_new_with_label,libgtk),Ptr{GObject},
        (Ptr{Uint8},Ptr{Uint8}),bytestring(uri),bytestring(label)))
function GtkLinkButton_new(uri::String,label::String,visited::Bool)
    b = GtkLinkButton_new(uri,label)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end
function GtkLinkButton_new(uri::String,visited::Bool)
    b = GtkLinkButton_new(uri)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end

#TODO: @gtktype GtkScaleButton

@gtktype GtkVolumeButton
GtkVolumeButton_new() = GtkVolumeButton_new(ccall((:gtk_volume_button_new,libgtk),Ptr{GObject},()))
function GtkVolumeButton_new(value::Real) # 0<=value<=1
    b = GtkVolumeButton_new()
    ccall((:gtk_scale_button_set_value,libgtk),Void,(Ptr{GObject},Cdouble),b,value)
    b
end

@gtktype GtkFontButton
GtkFontButton_new() = GtkFontButton_new(ccall((:gtk_font_button_new,libgtk),Ptr{GObject},()))

@Giface GtkFileChooser Gtk.libgtk gtk_file_chooser

