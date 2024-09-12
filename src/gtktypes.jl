function _gtksubtype_constructors(name::Symbol, cm::Module)
    ename = Symbol(string(name, getfield(cm, :suffix)))
    typ = getfield(cm, ename)
    if GLib.g_isa(typ, GtkOrientable)
        @eval $ename(orientation::Symbol, vargs...) = $ename(
            (orientation == :v ? true :
            (orientation == :h ? false :
            error("invalid $($ename) orientation $orientation"))), vargs...)
    end
    if isdefined(Gtk, :GtkContainer) && GLib.g_isa(typ, GtkContainer)
        @eval $ename(child::GtkWidget, vargs...) = push!($ename(vargs...), child)
    end
end

macro gtktype_custom_symname_and_lib(name, symname, lib)
    esc(quote
        @Gtype $name $lib $symname
        _gtksubtype_constructors($(QuoteNode(name)), $__module__)
    end)
end

macro gtktype_custom_symname(name, symname)
    esc(quote
        @gtktype_custom_symname_and_lib $(name) $(symname) libgtk
    end)
end

macro gtktype(name)
    groups = split(string(name), r"(?=[A-Z])")
    symname = Symbol(join([lowercase(s) for s in groups], "_"))
    esc(quote
        @gtktype_custom_symname $name $symname
    end)
end
@gtktype GtkWidget
@gtktype GtkContainer
@gtktype GtkBin
@gtktype GtkDialog
@gtktype GtkMenuShell

@gtktype GtkAccelGroup
@gtktype GtkBuilder
@gtktype GtkButton
@gtktype GtkCheckButton
@gtktype GtkToggleButton
@gtktype GtkRadioButton
@gtktype GtkLinkButton
@gtktype GtkVolumeButton
@gtktype GtkFontButton
@gtktype GtkDrawingArea
@gtktype GtkImage
@gtktype GtkProgressBar
@gtktype GtkSpinner
@gtktype GtkStatusbar
@gtktype GtkStatusIcon
#TODO: @gtktype GtkInfoBar
@gtktype GtkEntry
@gtktype GtkEntryCompletion
@gtktype GtkRange
@gtktype GtkScale
@gtktype GtkAdjustment
@gtktype GtkSpinButton
@gtktype GtkTable
@gtktype GtkAlignment
@gtktype GtkFrame
@gtktype GtkAspectFrame
@gtktype GtkBox
@gtktype GtkButtonBox
@gtktype GtkPaned
@gtktype GtkLayout
@gtktype GtkExpander
@gtktype GtkNotebook
@gtktype GtkComboBoxText
@gtktype GtkListStore
@gtktype GtkTreeStore
@gtktype GtkTreeModelFilter
@gtktype GtkCellRenderer
@gtktype GtkCellRendererAccel
@gtktype GtkCellRendererCombo
@gtktype GtkCellRendererPixbuf
@gtktype GtkCellRendererProgress
@gtktype GtkCellRendererSpin
@gtktype GtkCellRendererText
@gtktype GtkCellRendererToggle
@gtktype GtkCellRendererSpinner
@gtktype GtkTreeViewColumn
@gtktype GtkTreeSelection
@gtktype GtkTreeView
@gtktype GtkTreeModelSort
@gtktype GtkCellView
@gtktype GtkIconView
@gtktype GtkMenuItem
@gtktype GtkRadioMenuItem
@gtktype GtkImageMenuItem
@gtktype GtkCheckMenuItem
@gtktype GtkSeparatorMenuItem
@gtktype GtkMenu
@gtktype GtkMenuBar
@gtktype GtkFileChooserDialog
@gtktype GtkFileFilter
@gtktype GtkLabel
@gtktype GtkTextBuffer
@gtktype GtkTextView
@gtktype GtkTextMark
@gtktype GtkTextTag
@gtktype GtkToolbar
@gtktype GtkToolItem
@gtktype GtkToolButton
@gtktype GtkToggleToolButton
@gtktype GtkMenuToolButton
@gtktype GtkSeparatorToolItem
@gtktype GtkWindow
@gtktype GtkScrolledWindow
@gtktype GtkAboutDialog
@gtktype GtkMessageDialog
@gtktype GtkColorChooserDialog
@gtktype GtkColorButton
@Gtype GApplication libgio g_application
@Gtype GdkPixbuf libgdkpixbuf gdk_pixbuf
#TODO: @gtktype GtkScaleButton

@gtktype GtkApplication
@gtktype GtkApplicationWindow
@gtktype GtkSwitch
@gtktype GtkGrid
@gtktype GtkOverlay # this is a GtkBin, although it behaves more like a container
@gtktype GtkCellArea
@gtktype GtkCellAreaBox
@gtktype GtkCellAreaContext
@gtktype GtkCssProvider
@gtktype GtkStyleContext

struct GtkRequisition
    width::Int32
    height::Int32
    GtkRequisition(width, height) = new(width, height)
end

if libgtk_version >= v"3.16.0"
@gtktype_custom_symname GtkGLArea gtk_gl_area
else
mutable struct GtkGLArea end
    GtkGLAreaLeaf(x...) = error("GtkGLArea is not fully available until Gtk3.16.0 (though available as separate library)")
    macro GtkGLArea(args...)
        :( GtkGLAreaLeaf($(args...)) )
    end
end

if libgtk_version >= v"3.20.0"
    @gtktype GtkNativeDialog
    @gtktype GtkFileChooserNative
else
    mutable struct GtkNativeDialog end
    GtkNativeDialogLeaf(x...) = error("GtkNativeDialog is not available until Gtk3.20")
    macro GtkNativeDialog(args...)
        :( GtkNativeDialogLeaf($(args...)) )
    end

    mutable struct GtkFileChooserNative end
    GtkFileChooserNativeLeaf(x...) = error("GtkFileChooserNative is not available until Gtk3.20")
    macro GtkFileChooserNative(args...)
        :( GtkFileChooserNativeLeaf($(args...)) )
    end
end
