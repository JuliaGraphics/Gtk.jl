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
new(::Type{GtkButton}) = new(GtkButton, ccall((:gtk_button_new,libgtk),Ptr{GObject},()))
new(::Type{GtkButton}, title::String) =
    new(GtkButton, ccall((:gtk_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@gtktype GtkCheckButton
new(::Type{GtkCheckButton}) = new(GtkCheckButton, ccall((:gtk_check_button_new,libgtk),Ptr{GObject},()))
new(::Type{GtkCheckButton}, title::String) =
    new(GtkCheckButton, ccall((:gtk_check_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

@gtktype GtkToggleButton
new(::Type{GtkToggleButton}) = new(GtkToggleButton, ccall((:gtk_toggle_button_new,libgtk),Ptr{GObject},()))
new(::Type{GtkToggleButton}, title::String) =
    new(GtkToggleButton, ccall((:gtk_toggle_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

if gtk_version >= 3
    @gtktype GtkSwitch
    new(::Type{GtkSwitch}) = new(GtkSwitch, ccall((:gtk_switch_new,libgtk),Ptr{GObject},()))
    function new(::Type{GtkSwitch}, active::Bool)
        b = new(GtkSwitch)
        ccall((:gtk_switch_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
        b
    end
else
    const GtkSwitch = GtkToggleButton
end

@gtktype GtkRadioButton
new(::Type{GtkRadioButton}, group::Ptr{Void}=C_NULL) =
    new(GtkRadioButton,ccall((:gtk_radio_button_new,libgtk),Ptr{GObject},
        (Ptr{Void},),group))
new(::Type{GtkRadioButton}, group::Ptr{Void},label::String) =
    new(GtkRadioButton,ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),group,bytestring(label)))
new(::Type{GtkRadioButton}, label::String) =
    new(GtkRadioButton,ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GObject},
        (Ptr{Void},Ptr{Uint8}),C_NULL,bytestring(label)))
new(::Type{GtkRadioButton}, group::GtkRadioButton) =
    new(GtkRadioButton,ccall((:gtk_radio_button_new_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},),group))
new(::Type{GtkRadioButton}, group::GtkRadioButton,label::String) =
    new(GtkRadioButton,ccall((:gtk_radio_button_new_with_mnemonic_from_widget,libgtk),Ptr{GObject},
        (Ptr{GObject},Ptr{Uint8}),group,bytestring(label)))
new(::Type{GtkRadioButton}, group::GtkRadioButton,child::GtkWidget,vargs...) =
    push!(new(GtkRadioButton,group,vargs...), child)

type GtkRadioButtonGroup <: GtkContainer # NOT a native @gtktype
    # when iterating/indexing elements will be in reverse / *random* order

    # the behavior is specified as undefined if the first
    # element is moved to a new group
    # do not rely on the current behavior, since it may change
    handle::GtkContainer
    anchor::GtkRadioButton
    Gtk.new(::Type{GtkRadioButtonGroup},layout::GtkContainer) = new(layout)
end
new(::Type{GtkRadioButtonGroup}) = new(GtkRadioButtonGroup, new(GtkBox,true))
function new(::Type{GtkRadioButtonGroup}, elem::Vector, active::Int=1)
    grp = new(GtkRadioButtonGroup)
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
        setproperty!(e,:group,grp.anchor)
    else
        grp.anchor = e
    end
    push!(grp.handle, e)
    grp
end
function push!(grp::GtkRadioButtonGroup,label,active::Union(Bool,Nothing)=nothing)
    if isdefined(grp,:anchor)
        e = new(GtkRadioButton, grp.anchor, label)
    else
        grp.anchor = e = new(GtkRadioButton,label)
    end
    if isa(active,Bool)
        gtk_toggle_button_set_active(e,active::Bool)
    end
    push!(grp.handle, e)
    grp
end
function start(grp::GtkRadioButtonGroup)
    if isempty(grp)
        list = convert(Ptr{_GList{GtkRadioButton}},C_NULL)
    else
        list = ccall((:gtk_radio_button_get_group,libgtk), Ptr{_GList{GtkRadioButton}},
            (Ptr{GObject},), grp.anchor)
    end
    list
end
next(w::GtkRadioButtonGroup,s) = next(s,s)
done(w::GtkRadioButtonGroup,s) = done(s,s)
length(w::GtkRadioButtonGroup) = length(start(w))
getindex!(w::GtkRadioButtonGroup, i::Integer) = convert(GtkRadioButton,start(w)[i])
isempty(grp::GtkRadioButtonGroup) = !isdefined(grp,:anchor)
function getproperty(grp::GtkRadioButtonGroup,name::Union(Symbol,ByteString))
    k = symbol(name)
    if k == :active
        for b in grp
            if getproperty(b,:active,Bool)
                return b
            end
        end
        error("no active elements in GtkRadioGroup")
    end
    error("GtkRadioButtonGroup has no property $name")
end

function gtk_toggle_button_set_active(b::GtkWidget, active::Bool)
    # Users are encouraged to use the syntax `setproperty!(b,:active,true)`. This is not a public function.
    ccall((:gtk_toggle_button_set_active,libgtk),Void,(Ptr{GObject},Cint),b,active)
    b
end
# Append a named argument, active::Bool, to the various constructors
#TODO: deprecate these in favor of kw syntax
new{T<:GtkToggleButton}(::Type{T}, active::Bool) = gtk_toggle_button_set_active(new(T), active)
new{T<:GtkToggleButton}(::Type{T}, a, active::Bool) = gtk_toggle_button_set_active(new(T,a),active)
new{T<:GtkToggleButton}(::Type{T}, a, b, active::Bool) = gtk_toggle_button_set_active(new(T,a,b),active)
new{T<:GtkToggleButton}(::Type{T}, a, b, c, active::Bool) = gtk_toggle_button_set_active(new(T,a,b,c),active)


@gtktype GtkLinkButton
new(::Type{GtkLinkButton}, uri::String) =
    new(GtkLinkButton,ccall((:gtk_link_button_new,libgtk),Ptr{GObject},
        (Ptr{Uint8},),bytestring(uri)))
new(::Type{GtkLinkButton}, uri::String,label::String) =
    new(GtkLinkButton,ccall((:gtk_link_button_new_with_label,libgtk),Ptr{GObject},
        (Ptr{Uint8},Ptr{Uint8}),bytestring(uri),bytestring(label)))
function new(::Type{GtkLinkButton}, uri::String,label::String,visited::Bool)
    b = new(GtkLinkButton,uri,label)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end
function new(::Type{GtkLinkButton}, uri::String,visited::Bool)
    b = new(GtkLinkButton,uri)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GObject},Cint),b,visited)
    b
end

#TODO: @gtktype GtkScaleButton

@gtktype GtkVolumeButton
new(::Type{GtkVolumeButton}) = new(GtkVolumeButton,ccall((:gtk_volume_button_new,libgtk),Ptr{GObject},()))
function new(::Type{GtkVolumeButton}, value::Real) # 0<=value<=1
    b = new(GtkVolumeButton)
    ccall((:gtk_scale_button_set_value,libgtk),Void,(Ptr{GObject},Cdouble),b,value)
    b
end

@gtktype GtkFontButton
new(::Type{GtkFontButton}) = new(GtkFontButton,ccall((:gtk_font_button_new,libgtk),Ptr{GObject},()))

typealias GtkFontChooser Union(GtkFontButton)
