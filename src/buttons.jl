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

type GtkButton <: GtkContainerLike
    handle::Ptr{GtkWidget}
    function GtkButton()
        gc_ref(new(ccall((:gtk_button_new,libgtk),Ptr{GtkWidget},())))
    end
    function GtkButton(title::String)
        gc_ref(new(ccall((:gtk_button_new_with_mnemonic,libgtk),Ptr{GtkWidget},
            (Ptr{Uint8},), bytestring(title))))
    end
end


type GtkCheckButton <: GtkContainerLike
    handle::Ptr{GtkWidget}
    function GtkCheckButton()
        gc_ref(new(ccall((:gtk_check_button_new,libgtk),Ptr{GtkWidget},())))
    end
    function GtkCheckButton(title::String)
        gc_ref(new(ccall((:gtk_check_button_new_with_mnemonic,libgtk),Ptr{GtkWidget},
            (Ptr{Uint8},), bytestring(title))))
    end
end

type GtkToggleButton <: GtkContainerLike
    handle::Ptr{GtkWidget}
    function GtkToggleButton()
        b=gc_ref(new(ccall((:gtk_toggle_button_new,libgtk),Ptr{GtkWidget},())))
        if active
            ccall((:gtk_toggle_button_set_active,libgtk),Void,(Ptr{GtkWidget},Cint),b,true)
        end
        b
    end
    function GtkToggleButton(title::String)
        b=gc_ref(new(ccall((:gtk_toggle_button_new_with_mnemonic,libgtk),Ptr{GtkWidget},
            (Ptr{Uint8},), bytestring(title))))
        if active
            ccall((:gtk_toggle_button_set_active,libgtk),Void,(Ptr{GtkWidget},Cint),b,true)
        end
        b
    end
end

if gtk_version == 3
type GtkSwitch <: GtkWidget
    handle::Ptr{GtkWidget}
    function GtkSwitch()
        gc_ref(new(ccall((:gtk_switch_new,libgtk),Ptr{GtkWidget},())))
    end
end
function GtkSwitch(active::Bool)
    b = GtkSwitch()
    ccall((:gtk_switch_set_active,libgtk),Void,(Ptr{GtkWidget},Cint),b,active)
    b
end
else
const GtkSwitch = GtkToggleButton
end

type GtkRadioButton <: GtkContainerLike
    handle::Ptr{GtkWidget}
    GtkRadioButton(group=Ptr{Void}) =
        gc_ref(new(ccall((:gtk_radio_button_new,libgtk),Ptr{GtkWidget},
            (Ptr{Void},),group)))
    GtkRadioButton(group::Ptr{Void},label::String) =
        gc_ref(new(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GtkWidget},
            (Ptr{Void},Ptr{Uint8}),group,bytestring(label))))
    GtkRadioButton(label::String) =
        gc_ref(new(ccall((:gtk_radio_button_new_with_mnemonic,libgtk),Ptr{GtkWidget},
            (Ptr{Void},Ptr{Uint8}),C_NULL,bytestring(label))))
    GtkRadioButton(group::GtkRadioButton) =
        gc_ref(new(ccall((:gtk_radio_button_new_from_widget,libgtk),Ptr{GtkWidget},
            (Ptr{GtkWidget},),group)))
    GtkRadioButton(group::GtkRadioButton,label::String) =
        gc_ref(new(ccall((:gtk_radio_button_new_with_mnemonic_from_widget,libgtk),Ptr{GtkWidget},
            (Ptr{GtkWidget},Ptr{Uint8}),group,bytestring(label))))
end

function gtk_toggle_button_set_active(b::GtkWidget, active::Bool)
    ccall((:gtk_toggle_button_set_active,libgtk),Void,(Ptr{GtkWidget},Cint),b,active)
end # Users are encouraged to use the syntax `b[:active] = true`. This is not a public function.
for btn in (:GtkCheckButton, :GtkToggleButton, :GtkRadioButton)
    @eval begin
        $btn(active::Bool) = gtk_toggle_button_set_active($btn(),active)
        $btn(a,active::Bool) = gtk_toggle_button_set_active($btn(a),active)
        $btn(a::GtkWidget,active::Bool) = gtk_toggle_button_set_active($btn(a),active)
        $btn(a,b,active::Bool) = gtk_toggle_button_set_active($btn(a,b),active)
        $btn(a,b,c,active::Bool) = gtk_toggle_button_set_active($btn(a,b,c),active)
    end
end

type GtkLinkButton <: GtkContainerLike
    handle::Ptr{GtkWidget}
    GtkLinkButton(uri::String) =
        gc_ref(new(ccall((:gtk_switch_new,libgtk),Ptr{GtkWidget},
            (Ptr{Uint8},),bytestring(uri))))
    GtkLinkButton(uri::String,label::String) =
        gc_ref(new(ccall((:gtk_link_button_new_with_label,libgtk),Ptr{GtkWidget},
            (Ptr{Uint8},Ptr{Uint8}),bytestring(uri),bytestring(label))))
end
function GtkLinkButton(uri::String,label::String,visited::Bool)
    b = GtkLinkButton(uri,label)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GtkWidget},Cint),b,visited)
    b
end
function GtkLinkButton(uri::String,visited::Bool)
    b = GtkLinkButton(uri)
    ccall((:gtk_link_button_set_visited,libgtk),Void,(Ptr{GtkWidget},Cint),b,visited)
    b
end

#TODO: GtkScaleButton

type GtkVolumeButton <: GtkContainerLike
    handle::Ptr{GtkWidget}
    GtkLinkButton() =
        gc_ref(new(ccall((:gtk_volume_button_new,libgtk),Ptr{GtkWidget},())))
end
function GtkVolumeButton(value::Real) # 0<=value<=1
    b = GtkVolumeButton()
    ccall((:gtk_scale_button_set_value,libgtk),Void,(Ptr{Uint8},Cdouble),b,value)
    b
end
