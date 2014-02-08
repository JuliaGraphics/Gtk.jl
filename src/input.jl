#https://developer.gnome.org/gtk2/stable/NumericEntry.html

#GtkEntry — A single line text entry field
#GtkEntryBuffer — Text buffer for GtkEntry
#GtkEntryCompletion — Completion functionality for GtkEntry
#GtkHScale — A horizontal slider widget for selecting a value from a range
#GtkVScale — A vertical slider widget for selecting a value from a range
#GtkSpinButton — Retrieve an integer or floating-point number from the user
#GtkEditable — Interface for text-editing widgets

@gtktype GtkEntry
GtkEntry() = GtkEntry(ccall((:gtk_entry_new,libgtk),Ptr{GObject},()))

@gtktype GtkEntryCompletion 
GtkEntryCompletion() = GtkEntryCompletion(ccall((:gtk_entry_completion_new,libgtk),Ptr{GObject},()))

complete(completion::GtkEntryCompletion) = 
    ccall((:gtk_entry_completion_complete,libgtk),Void,(Ptr{GObject},),completion)

@gtktype GtkScale
if gtk_version == 3
    GtkScale(vertical::Bool,min,max,step) = GtkScale(ccall((:gtk_scale_new_with_range,libgtk),Ptr{GObject},
            (Cint,Cdouble,Cdouble,Cdouble),vertical,min,max,step))
else
    GtkScale(vertical::Bool,min,max,step) = GtkScale(
        if vertical
            ccall((:gtk_vscale_new_with_range,libgtk),Ptr{GObject},
                (Cdouble,Cdouble,Cdouble),min,max,step)
        else
            ccall((:gtk_hscale_new_with_range,libgtk),Ptr{GObject},
                (Cdouble,Cdouble,Cdouble),min,max,step)
        end)
end
GtkScale(vertical::Bool,scale::Ranges) = GtkScale(vertical,minimum(scale),maximum(scale),step(scale))
function push!(scale::GtkScale, value, position::Symbol, markup::String)
    ccall((:gtk_scale_add_mark,libgtk),Void,
        (Ptr{GObject},Cdouble,Enum,Ptr{Uint8}),
        scale,value,GtkPositionType.get(position),bytestring(markup))
    scale
end
function push!(scale::GtkScale, value, position::Symbol)
    ccall((:gtk_scale_add_mark,libgtk),Void,
        (Ptr{GObject},Cdouble,Enum,Ptr{Uint8}),
        scale,value,GtkPositionType.get(position),C_NULL)
    scale
end
empty!(scale::GtkScale) = ccall((:gtk_scale_clear_marks,libgtk),Void,(Ptr{GObject},),scale)

@gtktype GtkAdjustment
GtkAdjustment(value,lower,upper,step_increment,page_increment,page_size) =
    GtkAdjustment(ccall((:gtk_adjustment_new,libgtk), Ptr{GObject},
          (Float64,Float64,Float64,Float64,Float64,Float64),
          value,lower,upper,step_increment,page_increment,page_size))

GtkAdjustment(scale::GtkScale) = convert(GtkAdjustment,
    ccall((:gtk_range_get_adjustment,libgtk),Ptr{GObject},(Ptr{GObject},), scale))

@gtktype GtkSpinButton
GtkSpinButton(min,max,step) = GtkSpinButton(ccall((:gtk_spin_button_new_with_range,libgtk),Ptr{GObject},
    (Cdouble,Cdouble,Cdouble),min,max,step))
GtkSpinButton(scale::Ranges) = GtkSpinButton(minimum(scale),maximum(scale),step(scale))

GtkAdjustment(spinButton::GtkSpinButton) = convert(GtkAdjustment,
    ccall((:gtk_spin_button_get_adjustment,libgtk),Ptr{GObject},(Ptr{GObject},), spinButton))
    
typealias GtkEditableI Union(GtkEntry)
