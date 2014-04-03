#https://developer.gnome.org/gtk2/stable/NumericEntry.html

#GtkEntry — A single line text entry field
#GtkEntryBuffer — Text buffer for GtkEntry
#GtkEntryCompletion — Completion functionality for GtkEntry
#GtkHScale — A horizontal slider widget for selecting a value from a range
#GtkVScale — A vertical slider widget for selecting a value from a range
#GtkSpinButton — Retrieve an integer or floating-point number from the user
#GtkEditable — Interface for text-editing widgets

@gtktype GtkEntry
GtkEntry_new() = GtkEntry_new(ccall((:gtk_entry_new,libgtk),Ptr{GObject},()))

@gtktype GtkEntryCompletion 
GtkEntryCompletion_new() = GtkEntryCompletion_new(ccall((:gtk_entry_completion_new,libgtk),Ptr{GObject},()))

complete(completion::GtkEntryCompletion) = 
    ccall((:gtk_entry_completion_complete,libgtk),Void,(Ptr{GObject},),completion)

@gtktype GtkRange
@gtktype GtkScale
if gtk_version == 3
    GtkScale_new(vertical::Bool,min,max,step) = GtkScale_new(ccall((:gtk_scale_new_with_range,libgtk),Ptr{GObject},
            (Cint,Cdouble,Cdouble,Cdouble),vertical,min,max,step))
else
    GtkScale_new(vertical::Bool,min,max,step) = GtkScale_new(
        if vertical
            ccall((:gtk_vscale_new_with_range,libgtk),Ptr{GObject},
                (Cdouble,Cdouble,Cdouble),min,max,step)
        else
            ccall((:gtk_hscale_new_with_range,libgtk),Ptr{GObject},
                (Cdouble,Cdouble,Cdouble),min,max,step)
        end)
end
GtkScale_new(vertical::Bool,scale::Ranges) = GtkScale_new(vertical,minimum(scale),maximum(scale),step(scale))
function push!(scale::GtkScale, value, position::Symbol, markup::String)
    ccall((:gtk_scale_add_mark,libgtk),Void,
        (Ptr{GObject},Cdouble,Enum,Ptr{Uint8}),
        scale,value,GtkPositionType.(position),bytestring(markup))
    scale
end
function push!(scale::GtkScale, value, position::Symbol)
    ccall((:gtk_scale_add_mark,libgtk),Void,
        (Ptr{GObject},Cdouble,Enum,Ptr{Uint8}),
        scale,value,GtkPositionType.(position),C_NULL)
    scale
end
empty!(scale::GtkScale) = ccall((:gtk_scale_clear_marks,libgtk),Void,(Ptr{GObject},),scale)

@gtktype GtkAdjustment
GtkAdjustment_new(value,lower,upper,step_increment,page_increment,page_size) =
    GtkAdjustment_new(ccall((:gtk_adjustment_new,libgtk), Ptr{GObject},
          (Float64,Float64,Float64,Float64,Float64,Float64),
          value,lower,upper,step_increment,page_increment,page_size))

GtkAdjustment_new(scale::GtkScale) = convert(GtkAdjustment_new,
    ccall((:gtk_range_get_adjustment,libgtk),Ptr{GObject},(Ptr{GObject},), scale))

@gtktype GtkSpinButton
GtkSpinButton_new(min,max,step) = GtkSpinButton_new(
    ccall((:gtk_spin_button_new_with_range,libgtk),Ptr{GObject},(Cdouble,Cdouble,Cdouble),min,max,step))
GtkSpinButton_new(scale::Ranges) = GtkSpinButton_new(minimum(scale),maximum(scale),step(scale))

GtkAdjustment_new(spinButton::GtkSpinButton) = convert(GtkAdjustment_new,
    ccall((:gtk_spin_button_get_adjustment,libgtk),Ptr{GObject},(Ptr{GObject},), spinButton))
    
@Giface GtkEditable Gtk.libgtk gtk_editable

