#https://developer.gnome.org/gtk2/stable/NumericEntry.html

#GtkEntry — A single line text entry field
#GtkEntryBuffer — Text buffer for GtkEntry
#GtkEntryCompletion — Completion functionality for GtkEntry
#GtkHScale — A horizontal slider widget for selecting a value from a range
#GtkVScale — A vertical slider widget for selecting a value from a range
#GtkSpinButton — Retrieve an integer or floating-point number from the user
#GtkEditable — Interface for text-editing widgets

@gtktype GtkEntry
new(::Type{GtkEntry}) = new(GtkEntry,ccall((:gtk_entry_new,libgtk),Ptr{GObject},()))

@gtktype GtkEntryCompletion 
new(::Type{GtkEntryCompletion}) = new(GtkEntryCompletion,ccall((:gtk_entry_completion_new,libgtk),Ptr{GObject},()))

complete(completion::GtkEntryCompletion) = 
    ccall((:gtk_entry_completion_complete,libgtk),Void,(Ptr{GObject},),completion)

@gtktype GtkScale
if gtk_version == 3
    new(::Type{GtkScale}, vertical::Bool,min,max,step) = new(GtkScale,ccall((:gtk_scale_new_with_range,libgtk),Ptr{GObject},
            (Cint,Cdouble,Cdouble,Cdouble),vertical,min,max,step))
else
    new(::Type{GtkScale}, vertical::Bool,min,max,step) = new(GtkScale,
        if vertical
            ccall((:gtk_vscale_new_with_range,libgtk),Ptr{GObject},
                (Cdouble,Cdouble,Cdouble),min,max,step)
        else
            ccall((:gtk_hscale_new_with_range,libgtk),Ptr{GObject},
                (Cdouble,Cdouble,Cdouble),min,max,step)
        end)
end
new(::Type{GtkScale}, vertical::Bool,scale::Ranges) = new(GtkScale,vertical,minimum(scale),maximum(scale),step(scale))
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
new(::Type{GtkAdjustment}, value,lower,upper,step_increment,page_increment,page_size) =
    new(GtkAdjustment,ccall((:gtk_adjustment_new,libgtk), Ptr{GObject},
          (Float64,Float64,Float64,Float64,Float64,Float64),
          value,lower,upper,step_increment,page_increment,page_size))

new(::Type{GtkAdjustment}, scale::GtkScale) = convert(GtkAdjustmentLeaf,
    ccall((:gtk_range_get_adjustment,libgtk),Ptr{GObject},(Ptr{GObject},), scale))

@gtktype GtkSpinButton
new(::Type{GtkSpinButton}, min,max,step) = new(GtkSpinButton,
    ccall((:gtk_spin_button_new_with_range,libgtk),Ptr{GObject},(Cdouble,Cdouble,Cdouble),min,max,step))
new(::Type{GtkSpinButton}, scale::Ranges) = new(GtkSpinButton,minimum(scale),maximum(scale),step(scale))

new(::Type{GtkAdjustment}, spinButton::GtkSpinButton) = convert(GtkAdjustmentLeaf,
    ccall((:gtk_spin_button_get_adjustment,libgtk),Ptr{GObject},(Ptr{GObject},), spinButton))
    
typealias GtkEditable Union(GtkEntry)
