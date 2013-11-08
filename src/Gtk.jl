# julia Gtk interface

module Gtk
using Cairo

import Base: convert, show, showall, size, length, getindex, setindex!,
             insert!, push!, unshift!, shift!, pop!, splice!, delete!,
             start, next, done, parent, isempty, empty!, first, last, in,
             eltype, copy
import Base.Graphics: width, height, getgc
import Cairo: destroy

# generic interface:
export width, height, size, #minsize, maxsize
    reveal, configure, draw, cairo_context,
    length, add!, delete!, splice!, visible, destroy

    #property, margin, padding, align
    #raise, focus, destroy, enabled

# Gtk objects
export GtkWindow, GtkCanvas, GtkBox, GtkButtonBox, GtkPaned, GtkLayout, GtkNotebook,
    GtkExpander, GtkOverlay, GtkFrame, GtkAspectFrame,
    GtkLabel, GtkButton, GtkCheckButton, GtkRadioButton, GtkRadioButtonGroup,
    GtkToggleButton, GtkLinkButton, GtkVolumeButton,
    GtkEntry, GtkScale, GtkSpinButton, GtkComboBoxText

# Gtk3 objects
export GtkGrid

# Gtk2 objects
export GtkTable, GtkAlignment

# Gtk-specific event handling
export gtk_doevent, GdkEventMask, GdkModifierType,
    signal_connect, signal_disconnect,
    on_signal_destroy, on_signal_button_press,
    on_signal_button_release, on_signal_motion


# Tk-compatibility (missing):
#export Frame, Labelframe, Notebook, Panedwindow
#export Button
#export Checkbutton, Radio, Combobox
#export Slider, Spinbox
#export Entry, set_validation, Text
#export Treeview, selected_nodes, node_insert, node_move, node_delete, node_open
#export tree_headers, tree_column_widths, tree_key_header, tree_key_width
#export Sizegrip, Separator, Progressbar, Image, Scrollbar
#export Menu, menu_add
#export GetOpenFile, GetSaveFile, ChooseDirectory, Messagebox
#export scrollbars_add
#export get_value, set_value,
#       get_items, set_items,
#       get_editable, set_editable,
#       set_position


const gtk_version = 2 # This is the only configuration option

if gtk_version == 3
    const libgtk = "libgtk-3"
    const libgdk = "libgdk-3"
elseif gtk_version == 2
    if OS_NAME == :Darwin
        const libgtk = "libgtk-quartz-2.0"
        const libgdk = "libgdk-quartz-2.0"
    elseif OS_NAME == :Windows
        const libgtk = "libgtk-win32-2.0-0"
        const libgdk = "libgdk-win32-2.0-0"
    else
        const libgtk = "libgtk-x11-2.0"
        const libgdk = "libgdk-x11-2.0"
    end
else
    error("Unsupported Gtk version $gtk_version")
end
if OS_NAME == :Windows
    const libgobject = "libgobject-2.0-0"
    const libglib = "libglib-2.0-0"
else
    const libgobject = "libgobject-2.0"
    const libglib = "libglib-2.0"
end

# local copy, handles Symbol and easier UTF8-strings
bytestring(s) = Base.bytestring(s)
bytestring(s::Symbol) = s
bytestring(s::Ptr{Uint8},own::Bool) = UTF8String(pointer_to_array(s,ccall(:strlen,Csize_t,(Ptr{Uint8},),s)),own)
typealias Index Union(Integer,Ranges{TypeVar(:I,Integer)},AbstractVector{TypeVar(:I,Integer)})

include("gslist.jl")
include("gerror.jl")
include("gtktypes.jl")
include("gvalues.jl")
include("gdk.jl")
include("events.jl")
include("container.jl")
include("windows.jl")
include("layout.jl")
include("displays.jl")
include("lists.jl")
include("buttons.jl")
include("input.jl")
include("text.jl")
include("menus.jl")
include("selectors.jl")
include("misc.jl")
include("cairo.jl")


function Base.subtypes(T::DataType, b::Bool)
    if b == false
        return subtypes(T)
    elseif T.abstract
        queue = DataType[T,]
        subt = DataType[]
        while !isempty(queue)
            for x in subtypes(pop!(queue))
                if isa(x,DataType)
                    if x.abstract
                        push!(queue, x)
                    else
                        push!(subt, x)
                    end
                end
            end
        end
        return subt
    else
        return DataType[]
    end
end
for container in subtypes(GtkContainer,true)
    @eval $(symbol(string(container)))(child::GtkWidget,vargs...) = push!($container(vargs...),child)
end
for orientable in (:GtkPaned, :GtkButtonBox, :GtkBox, :GtkScale)
    @eval $orientable(orientation::Symbol,vargs...) = $orientable(
            (orientation==:v ? true :
            (orientation==:h ? false :
            error("invalid $($orientable) orientation $orientation"))),vargs...)
end

# Alternative Names
module ShortNames
    using Gtk

    # Gtk-specific event handling
    export width, height, size, #minsize, maxsize
        reveal, configure, draw, cairo_context,
        length, add!, delete!, splice!, visible, destroy

    # Gtk objects
    const Window = GtkWindow
    const Canvas = GtkCanvas
    const BoxLayout = GtkBox
    const ButtonBox = GtkButtonBox
    const Paned = GtkPaned
    const Layout = GtkLayout
    const Notebook = GtkNotebook
    const Expander = GtkExpander
    const Overlay = GtkOverlay
    const Frame = GtkFrame
    const AspectFrame = GtkAspectFrame
    const Label = GtkLabel
    const Button = GtkButton
    const CheckButton = GtkCheckButton
    const RadioButton = GtkRadioButton
    const RadioButtonGroup = GtkRadioButtonGroup
    const ToggleButton = GtkToggleButton
    const LinkButton = GtkLinkButton
    const VolumeButton = GtkVolumeButton
    const Entry = GtkEntry
    const Scale = GtkScale
    const SpinButton = GtkSpinButton
    const ComboBoxText = GtkComboBoxText
    export Window, Canvas, BoxLayout, ButtonBox, Paned, Layout, Notebook,
        Expander, Overlay, Frame, AspectFrame,
        Label, Button, CheckButton, RadioButton, RadioButtonGroup,
        ToggleButton, LinkButton, VolumeButton,
        Entry, Scale, SpinButton, ComboBoxText

    # Gtk 3
    if Gtk.gtk_version == 3
        const Grid = GtkGrid
    end
    export Grid

    # Gtk 2
    const Table = GtkTable
    const Alignment = GtkAlignment
    export Table, Aligment
end
using .ShortNames
export Canvas, Window

init()
end
