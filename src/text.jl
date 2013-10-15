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

type GtkTextMark <: GtkObject
    handle::Ptr{GtkObject}
    GtkTextMark(left_gravity::Bool=false) =
        gc_ref(new(ccall((:gtk_text_mark_new,libgtk),Ptr{GtkObject},(Ptr{Uint8},Cint),C_NULL,left_gravity)))
end
visible(w::GtkTextMark) =
    bool(ccall((:gtk_text_mark_get_visible,libgtk),Cint,(Ptr{GtkObject},),w))
visible(w::GtkTextMark, state::Bool) =
    ccall((:gtk_text_mark_set_visible,libgtk),Void,(Ptr{GtkObject},Cint),w,state)
show(w::GtkTextMark) = visible(w,true)

type GtkTextTag <: GtkObject
    handle::Ptr{GtkObject}
    GtkTextTag() =
        gc_ref(new(ccall((:gtk_text_tag_new,libgtk),Ptr{GtkObject},(Ptr{Uint8},),C_NULL)))
    GtkTextTag(name::String) =
        gc_ref(new(ccall((:gtk_text_tag_new,libgtk),Ptr{GtkObject},(Ptr{Uint8},),bytestring(name))))
end

type GtkTextBuffer <: GtkObject
    handle::Ptr{GtkObject}
    GtkTextBuffer() = gc_ref(new(ccall((:gtk_text_buffer_new,libgtk),Ptr{GtkObject},
        (Ptr{GtkObject},),C_NULL)))
end
#TODO: iterators, tags, text, child widgets, clipboard

type GtkTextView <: GtkWidget
    handle::Ptr{GtkObject}
    function GtkTextView(buffer=GtkTextBuffer())
        gc_ref(new(ccall((:gtk_text_view_new_with_buffer,libgtk),Ptr{GtkObject},
            (Ptr{GtkObject},),buffer)))
    end
end
#TODO: scrolling, views
