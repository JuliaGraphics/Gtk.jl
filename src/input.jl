#GtkEntry — A single line text entry field
#GtkEntryBuffer — Text buffer for GtkEntry
#GtkEntryCompletion — Completion functionality for GtkEntry
#GtkHScale — A horizontal slider widget for selecting a value from a range
#GtkVScale — A vertical slider widget for selecting a value from a range
#GtkSpinButton — Retrieve an integer or floating-point number from the user
#GtkEditable — Interface for text-editing widgets

GtkEntryLeaf() = GtkEntryLeaf(ccall((:gtk_entry_new, libgtk), Ptr{GObject}, ()))

GtkEntryCompletionLeaf() = GtkEntryCompletionLeaf(ccall((:gtk_entry_completion_new, libgtk), Ptr{GObject}, ()))

complete(completion::GtkEntryCompletion) =
    ccall((:gtk_entry_completion_complete, libgtk), Nothing, (Ptr{GObject},), completion)

GtkScaleLeaf(vertical::Bool, min, max, step) = GtkScaleLeaf(ccall((:gtk_scale_new_with_range, libgtk), Ptr{GObject},
        (Cint, Cdouble, Cdouble, Cdouble), vertical, min, max, step))

GtkScaleLeaf(vertical::Bool, scale::AbstractRange) = GtkScaleLeaf(vertical, minimum(scale), maximum(scale), step(scale))
function push!(scale::GtkScale, value, position::Symbol, markup::AbstractString)
    ccall((:gtk_scale_add_mark, libgtk), Nothing,
        (Ptr{GObject}, Cdouble, GEnum, Ptr{UInt8}),
        scale, value, GtkPositionType.(position), bytestring(markup))
    scale
end
function push!(scale::GtkScale, value, position::Symbol)
    ccall((:gtk_scale_add_mark, libgtk), Nothing,
        (Ptr{GObject}, Cdouble, GEnum, Ptr{UInt8}),
        scale, value, GtkPositionType.(position), C_NULL)
    scale
end
empty!(scale::GtkScale) = ccall((:gtk_scale_clear_marks, libgtk), Nothing, (Ptr{GObject},), scale)

GtkAdjustmentLeaf(value, lower, upper, step_increment, page_increment, page_size) =
    GtkAdjustmentLeaf(ccall((:gtk_adjustment_new, libgtk), Ptr{GObject},
          (Float64, Float64, Float64, Float64, Float64, Float64),
          value, lower, upper, step_increment, page_increment, page_size))

GtkAdjustmentLeaf(scale::GtkScale) = convert(GtkAdjustmentLeaf,
    ccall((:gtk_range_get_adjustment, libgtk), Ptr{GObject}, (Ptr{GObject},), scale))

"""
    configure!(adj::GtkAdjustment; value = nothing, lower = nothing, upper = nothing, step_increment = nothing, page_increment = nothing, page_size = nothing)

Sets all properties of an adjustment, while only resulting in one emission of
the `changed` signal. If an argument is `nothing`, it is not changed.
"""
function configure!(adj::GtkAdjustment; value = nothing, lower = nothing, upper = nothing, step_increment = nothing, page_increment = nothing, page_size = nothing)
    if value === nothing
        value = G_.value(adj)
    end
    if lower === nothing
        lower = G_.lower(adj)
    end
    if upper === nothing
        upper = G_.upper(adj)
    end
    if step_increment === nothing
        step_increment = G_.step_increment(adj)
    end
    if page_increment === nothing
        page_increment = G_.page_increment(adj)
    end
    if page_size === nothing
        page_size = G_.page_size(adj)
    end
    ccall((:gtk_adjustment_configure, libgtk), Nothing,
                      (Ptr{GObject}, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble, Cdouble),
                      adj, value, lower, upper, step_increment, page_increment, page_size)
end

GtkSpinButtonLeaf(min, max, step) = GtkSpinButtonLeaf(
    ccall((:gtk_spin_button_new_with_range, libgtk), Ptr{GObject}, (Cdouble, Cdouble, Cdouble), min, max, step))
GtkSpinButtonLeaf(scale::AbstractRange) = GtkSpinButtonLeaf(minimum(scale), maximum(scale), step(scale))

GtkAdjustmentLeaf(spinButton::GtkSpinButton) = convert(GtkAdjustmentLeaf,
    ccall((:gtk_spin_button_get_adjustment, libgtk), Ptr{GObject}, (Ptr{GObject},), spinButton))

"""
    configure!(sb::GtkSpinButton; adj = nothing, climb_rate = nothing, digits = nothing)

Sets the adjustment `adj`, the `climb_rate`, and the number of `digits` of
a `GtkSpinButton` with only one emission of its `changed` signal. If an argument is
`nothing`, it is not changed.
"""
function configure!(sb::GtkSpinButton; adj = nothing, climb_rate = nothing, digits = nothing)
    if adj === nothing
        adj = C_NULL
    end
    if climb_rate === nothing
        climb_rate = get_gtk_property(sb, :climb_rate, Float64)
    end
    if digits === nothing
        digits = G_.digits(sb)
    end
    ccall((:gtk_spin_button_configure, libgtk), Nothing,
                (Ptr{GObject}, Ptr{GObject}, Cdouble, Cuint), sb, adj, climb_rate, digits)
end
