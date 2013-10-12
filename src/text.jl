#https://developer.gnome.org/gtk2/stable/TextWidgetObjects.html

#GtkAccelLabel — A label which displays an accelerator key on the right of the text
#GtkLabel — A widget that displays a small to medium amount of text

#Text Widget Overview — Overview of GtkTextBuffer, GtkTextView, and friends
#GtkTextIter — Text buffer iterator
#GtkTextMark — A position in the buffer preserved across buffer modifications
#GtkTextBuffer — Stores attributed text for display in a GtkTextView
#GtkTextTag — A tag that can be applied to text in a GtkTextBuffer
#GtkTextTagTable — Collection of tags that can be used together
#GtkTextView — Widget that displays a GtkTextBuffer

#TODO: GtkTextBuffer and GtkTextTag manager objects, needed for GtkTextView
#TODO: GtkAccel manager objects

type GtkLabel <: GtkWidget
    handle::Ptr{GtkObject}
    function GtkLabel(title)
        gc_ref(new(ccall((:gtk_label_new,libgtk),Ptr{GtkObject},
            (Ptr{Uint8},), bytestring(title))))
    end
end


#type GtkTextView <: GtkWidget
#    handle::Ptr{GtkObject}
#    function GtkTextView()
#        gc_ref(new(ccall((:gtk_text_view_new_with_buffer,libgtk),Ptr{GtkObject},
#            (Ptr{Void},),C_NULL)))
#    end
#end
