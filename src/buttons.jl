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

@GType GtkButton <: GtkBin
GtkButton() = GtkButton(ccall((:gtk_button_new,libgtk),Ptr{GObject},()))
GtkButton(title::String) =
    GtkButton(ccall((:gtk_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@GType GtkCheckButton <: GtkBin
GtkCheckButton() = GtkCheckButton(ccall((:gtk_check_button_new,libgtk),Ptr{GObject},()))
GtkCheckButton(title::String) =
    GtkCheckButton(ccall((:gtk_check_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@GType GtkToggleButton <: GtkBin
GtkToggleButton() = GtkToggleButton(ccall((:gtk_toggle_button_new,libgtk),Ptr{GObject},()))
GtkToggleButton(title::String) =
    GtkToggleButton(ccall((:gtk_toggle_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

if gtk_version >= 3
@GType GtkSwitch <: GtkWidget
    GtkSwitch() = GtkSwitch(ccall((:gtk_switch_new,libgtk),Ptr{GObject},()))
    function GtkSwitch(active::Bool)
        b = GtkSwitch()
        ccall((:gtk_switch_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
        b
    end
else
    const GtkSwitch = GtkToggleButton
end

@GType GtkRadioButton <: GtkBin
GtkRadioButton(group::Ptr{Void}=C_NULL) =
    GtkRadioButton(ccall((:gtk_radio_button_new,libgtk),Ptr{GObject},
        (Ptr{Void},),group))
GtkRadioButton(group::Ptr{Void},label::String) =
    GtkRadioButton(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),group,bytestring(label)))
GtkRadioButton(label::String) =
    GtkRadioButton(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),C_NULL,bytestring(label)))
GtkRadioButton(group::GtkRadioButton) =
    GtkRadioButton(ccall((:gtk_radio_button_new_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},),group))
GtkRadioButton(group::GtkRadioButton,label::String) =
    GtkRadioButton(ccall((:gtk_radio_button_new_with_mnemonic_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},Ptr{Uint8}),group,bytestring(label)))
GtkRadioButton(group::GtkRadioButton,child::GtkWidgetI,vargs...) =
    push!(GtkRadioButton(group,vargs...), child)

type GtkRadioButtonGroup <: GtkContainerI # NOT an @GType
    # when iterating/indexing elements will be in reverse / *random* order

    # the behavior is specified as undefined if the first
    # element is moved to a new group
    # do not rely on the current behavior, since it may change
    handle::GtkContainerI
    anchor::GtkRadioButton
    GtkRadioButtonGroup(layout::GtkContainerI) = new(layout)
end
GtkRadioButtonGroup() = GtkRadioButtonGroup(GtkBox(true))
function GtkRadioButtonGroup(elem::Vector, active::Int=1)
    grp = GtkRadioButtonGroup()
    for (i,e) in enumerate(elem)
        push!(grp, e, i==active)
    end
    grp
end
convert(::Type{Ptr{GObject}},grp::GtkRadioButtonGroup) = convert(Ptr{GObject},grp.handle)
show(io::IO,::GtkRadioButtonGroup) = print(io,"GtkRadioButtonGroup()")
function push!(grp::GtkRadioButtonGroup,e::GtkRadioButton,active::Bool)
    push!(grp, e)
    gtk_toggle_button_set_active(e, active)
    grp
end
function push!(grp::GtkRadioButtonGroup,e::GtkRadioButton)
    if isdefined(grp,:anchor)
        e[:group] = grp.anchor
    else
        grp.anchor = e
    end
    push!(grp.handle, e)
    grp
end
function push!(grp::GtkRadioButtonGroup,label,active::Union(Bool,Nothing)=nothing)
    if isdefined(grp,:anchor)
        e = GtkRadioButton(grp.anchor, label)
    else
        grp.anchor = e = GtkRadioButton(label)
    end
    if isa(active,Bool)
        gtk_toggle_button_set_active(e,active::Bool)
    end
    push!(grp.handle, e)
    grp
end
function start(grp::GtkRadioButtonGroup)
    if isempty(grp)
        list = ()
    else
        list = gslist(ccall((:gtk_radio_button_get_group,libgtk), Ptr{GSList{GtkRadioButton}},
            (Ptr{GObject},), grp.anchor), false)
    end
    list
end
next(w::GtkRadioButtonGroup,s) = next(s,s)
done(w::GtkRadioButtonGroup,s) = done(s,s) 
length(w::GtkRadioButtonGroup) = length(start(w))
getindex(w::GtkRadioButtonGroup, i::Integer) = convert(GtkRadioButton,start(w)[i])
isempty(grp::GtkRadioButtonGroup) = !isdefined(grp,:anchor)
function getindex(grp::GtkRadioButtonGroup,name::Union(Symbol,ByteString))
    k = symbol(name)
    if k == :active
        for b in grp
            if b[:active,Bool]
                return b
            end
        end
        error("no active elements in GtkRadioGroup")
    end
    error("GtkRadioButtonGroup has no property $name")
end


function gtk_toggle_button_set_active(b::GtkWidgetI, active::Bool)
    # Users are encouraged to use the syntax `b[:active] = true`. This is not a public function.
    ccall((:gtk_toggle_button_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
    b
end
# Append a named argument, active::Bool, to the various constructors
# but first, resolve some conflicts
GtkRadioButton(a::GtkRadioButton,active::Bool) = gtk_toggle_button_set_active(GtkRadioButton(a),active)
GtkRadioButton(a::GtkRadioButton,b::GtkWidgetI,active::Bool) = gtk_toggle_button_set_active(GtkRadioButton(a,b),active)
GtkRadioButton(a::GtkRadioButton,b,active::Bool) = gtk_toggle_button_set_active(GtkRadioButton(a,b),active)
for btn in (:GtkCheckButton, :GtkToggleButton, :GtkRadioButton)
    @eval begin
        $btn(active::Bool) = gtk_toggle_button_set_active($btn(),active)
        $btn(a,active::Bool) = gtk_toggle_button_set_active($btn(a),active)
        $btn(a::GtkWidgetI,active::Bool) = gtk_toggle_button_set_active($btn(a),active)
        $btn(a,b,active::Bool) = gtk_toggle_button_set_active($btn(a,b),active)
        $btn(a,b,c,active::Bool) = gtk_toggle_button_set_active($btn(a,b,c),active)
    end
end


@GType GtkLinkButton <: GtkBin
GtkLinkButton(uri::String) =
    GtkLinkButton(ccall((:gtk_switch_new,libgtk),Ptr{GObject},
        (Ptr{Uint8},),bytestring(uri)))
GtkLinkButton(uri::String,label::String) =
    GtkLinkButton(ccall((:gtk_link_button_new_with_label,libgtk),Ptr{GObject},
        (Ptr{Uint8},Ptr{Uint8}),bytestring(uri),bytestring(label)))
function GtkLinkButton(uri::String,label::String,visited::Bool)
    b = GtkLinkButton(uri,label)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end
function GtkLinkButton(uri::String,visited::Bool)
    b = GtkLinkButton(uri)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end

#TODO: @GType GtkScaleButton

@GType GtkVolumeButton <: GtkBin
GtkLinkButton() = GtkLinkButton(ccall((:gtk_volume_button_new,libgtk),Ptr{GObject},()))
function GtkVolumeButton(value::Real) # 0<=value<=1
    b = GtkVolumeButton()
    ccall((:gtk_scale_button_set_value,libgtk),Void,(Ptr{Uint8},Cdouble),b,value)
    b
end
