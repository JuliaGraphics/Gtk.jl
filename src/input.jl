#https://developer.gnome.org/gtk2/stable/NumericEntry.html

#GtkEntry — A single line text entry field
#GtkEntryBuffer — Text buffer for GtkEntry
#GtkEntryCompletion — Completion functionality for GtkEntry
#GtkHScale — A horizontal slider widget for selecting a value from a range
#GtkVScale — A vertical slider widget for selecting a value from a range
#GtkSpinButton — Retrieve an integer or floating-point number from the user
#GtkEditable — Interface for text-editing widgets

type GtkEntry <: GtkWidget
    handle::Ptr{GtkWidget}
    GtkEntry() = gc_ref(new(ccall((:gtk_entry_new,libgtk),Ptr{GtkWidget},())))
end


type GtkScale <: GtkWidget
    handle::Ptr{GtkWidget}
    if gtk_version == 3
        GtkScale(vertical::Bool) = gc_ref(new(ccall((:gtk_scale_new_with_range,libgtk),Ptr{GtkWidget},
                (Cint,Cdouble,Cdouble,Cdouble),vertical,min,max,step)))
    else
        GtkScale(vertical::Bool,min,max,step) = gc_ref(new(
            if vertical
                ccall((:gtk_vscale_new_with_range,libgtk),Ptr{GtkWidget},
                    (Cdouble,Cdouble,Cdouble),min,max,step)
            else
                ccall((:gtk_hscale_new_with_range,libgtk),Ptr{GtkWidget},
                    (Cdouble,Cdouble,Cdouble),min,max,step)
            end))
    end
end
GtkScale(vertical::Bool,scale::Ranges) = GtkScale(vertical,min(scale),max(scale),step(scale))
function push!(scale::GtkScale, value, position::Symbol, markup::String)
    ccall((:gtk_scale_add_mark,libgtk),Void,
        (Ptr{GtkWidget},Cdouble,Enum,Ptr{Uint8}),
        scale,value,GtkPositionType.get(position),bytestring(markup))
    scale
end
function push!(scale::GtkScale, value, position::Symbol)
    ccall((:gtk_scale_add_mark,libgtk),Void,
        (Ptr{GtkWidget},Cdouble,Enum,Ptr{Uint8}),
        scale,value,GtkPositionType.get(position),C_NULL)
    scale
end
empty!(scale::GtkScale) = ccall((:gtk_scale_clear_marks,libgtk),Void,(Ptr{GtkWidget},),scale)


type GtkSpinButton <: GtkWidget
    handle::Ptr{GtkWidget}
    GtkSpinButton(min,max,step) = gc_ref(new(ccall((:gtk_spin_button_new_with_range,libgtk),Ptr{GtkWidget},
        (Cdouble,Cdouble,Cdouble),min,max,step)))
end
GtkSpinButton(scale::Ranges) = GtkSpinButton(min(scale),max(scale),step(scale))

