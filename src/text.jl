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

#TODO: GtkAccel manager objects

@gtktype GtkLabel
GtkLabel(title) = GtkLabel(
    ccall((:gtk_label_new,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(title)))

@gtktype GtkTextBuffer
GtkTextBuffer() = GtkTextBuffer(
    ccall((:gtk_text_buffer_new,libgtk),Ptr{GObject},(Ptr{GObject},),C_NULL))

@gtktype GtkTextView
GtkTextView(buffer=GtkTextBuffer()) = GtkTextView(
    ccall((:gtk_text_view_new_with_buffer,libgtk),Ptr{GObject},(Ptr{GObject},),buffer))

@gtktype GtkTextMark
GtkTextMark(left_gravity::Bool=false) = GtkTextMark(
    ccall((:gtk_text_mark_new,libgtk),Ptr{GObject},(Ptr{Uint8},Cint),C_NULL,left_gravity))

@gtktype GtkTextTag
GtkTextTag() = GtkTextTag(
    ccall((:gtk_text_tag_new,libgtk),Ptr{GObject},(Ptr{Uint8},),C_NULL))
GtkTextTag(name::String) = GtkTextTag(
    ccall((:gtk_text_tag_new,libgtk),Ptr{GObject},(Ptr{Uint8},),bytestring(name)))

type GtkTextIter
    handle::Ptr{Void}
    reverse::Bool
    function _GtkTextIter(text::GtkTextBuffer,reverse::Bool)
        iter = new(ccall((:gtk_text_iter_copy,libgtk),Ptr{Void},
            (Ptr{GObject},),text),reverse)
        finalizer(iter, (x::GtkTextIter)->ccall((:gtk_text_iter_free,libgtk),Void,
            (Ptr{Void},),x.handle))
        iter
    end
    function Base.copy(iter::GtkTextIter)
        iter = new(ccall((:gtk_text_iter_copy,libgtk),Ptr{Void},(Ptr{Void},),iter),iter.reverse)
        finalizer(iter, (x::GtkTextIter)->ccall((:gtk_text_iter_free,libgtk),Void,
            (Ptr{Void},),x.handle))
        iter
    end
    function GtkTextIter(text::GtkTextBuffer,char_offset::Integer,reverse::Bool=false)
        iter = _GtkTextIter(text,reverse)
        ccall((:gtk_text_buffer_get_iter_at_offset,libgtk),Void,
            (Ptr{GObject},Ptr{Void},Cint),text,iter.handle,char_offset-1)
        iter
    end
    function GtkTextIter(text::GtkTextBuffer,line::Integer,char_offset::Integer,reverse::Bool=false)
        iter = _GtkTextIter(text,reverse)
        ccall((:gtk_text_buffer_get_iter_at_line_offset,libgtk),Void,
            (Ptr{GObject},Ptr{Void},Cint,Cint),text,iter.handle,line-1,char_offset-1)
        iter
    end
    function GtkTextIter(text::GtkTextBuffer,reverse::Bool=false)
        iter = _GtkTextIter(text,reverse)
        ccall((:gtk_text_buffer_get_start_iter,libgtk),Void,
            (Ptr{GObject},Ptr{Void}),text,iter.handle)
        iter
    end
    function GtkTextIter(text::GtkTextBuffer,mark::GtkTextMark,reverse::Bool=false)
        iter = _GtkTextIter(text,reverse)
        ccall((:gtk_text_buffer_get_iter_at_mark,libgtk),Void,
            (Ptr{GObject},Ptr{Void},Ptr{GObject}),text,iter.handle,mark)
        iter
    end
end

immutable GtkTextRange <: Ranges
    a::GtkTextIter
    b::GtkTextIter
end

#type GtkClipboard
#TODO
#end


#####  GtkTextIter  #####
#TODO: search

convert(::Type{Ptr{Void}},iter::GtkTextIter) = iter.handle
getproperty(text::GtkTextIter, key::String, outtype::Type=Any) = getproperty(text, symbol(key), outtype)
function getproperty(text::GtkTextIter, key::Symbol, outtype::Type=Any)
    return convert(outtype,
    if     key === :offset
        ccall((:gtk_text_iter_get_offset,libgtk),Cint,(Ptr{Void},),text)
    elseif key === :line
        ccall((:gtk_text_iter_get_line,libgtk),Cint,(Ptr{Void},),text)
    elseif key === :line_offset
        ccall((:gtk_text_iter_get_line_offset,libgtk),Cint,(Ptr{Void},),text)
    elseif key === :line_index
        ccall((:gtk_text_iter_get_line_index,libgtk),Cint,(Ptr{Void},),text)
    elseif key === :visible_line_index
        ccall((:gtk_text_iter_get_visible_line_index,libgtk),Cint,(Ptr{Void},),text)
    elseif key === :visible_line_offset
        ccall((:gtk_text_iter_get_visible_line_offset,libgtk),Cint,(Ptr{Void},),text)
    elseif key === :marks
        gslist(ccall((:gtk_text_iter_get_marks,libgtk),Ptr{GSList{GtkTextMark}},(Ptr{Void},),text),false) # GtkTextMark iter
    elseif key === :toggled_on_tags
        gslist(ccall((:gtk_text_iter_get_toggled_tags,libgtk),Ptr{GSList{GtkTextTag}},(Ptr{Void},Cint),text,true),false) # GtkTextTag iter
    elseif key === :toggled_off_tags
        gslist(ccall((:gtk_text_iter_get_toggled_tags,libgtk),Ptr{GSList{GtkTextTag}},(Ptr{Void},Cint),text,false),false) # GtkTextTag iter
#    elseif key === :child_anchor
#        convert(GtkTextChildAnchor,ccall((:gtk_text_iter_get_child_anchor,libgtk),Ptr{GtkTextChildAnchor},(Ptr{Void},Cint),text,false))
    elseif key === :can_insert
        bool(ccall((:gtk_text_iter_can_insert,libgtk),Cint,(Ptr{Void},Cint),text,true))
    elseif key === :starts_word
        bool(ccall((:gtk_text_iter_starts_word,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :ends_word
        bool(ccall((:gtk_text_iter_ends_word,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :inside_word
        bool(ccall((:gtk_text_iter_inside_word,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :starts_line
        bool(ccall((:gtk_text_iter_starts_line,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :ends_line
        bool(ccall((:gtk_text_iter_ends_line,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :starts_sentence
        bool(ccall((:gtk_text_iter_starts_sentence,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :ends_sentence
        bool(ccall((:gtk_text_iter_ends_sentence,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :inside_sentence
        bool(ccall((:gtk_text_iter_inside_sentence,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :is_cursor_position
        bool(ccall((:gtk_text_iter_is_cursor_position,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :chars_in_line
        ccall((:gtk_text_iter_chars_in_line,libgtk),Cint,(Ptr{Void},),text)
    elseif key === :bytes_in_line
        ccall((:gtk_text_iter_bytes_in_line,libgtk),Cint,(Ptr{Void},),text)
#    elseif key === :attributes
#        view = text[:view]::GtkTextView
#        attrs = view[:default_attributes]::GtkTextAttributes
#        ccall((:gtk_text_iter_get_attributes,libgtk),Cint,(Ptr{Void},Ptr{GtkTextAttributes}),text,&attrs)
#        attrs
#    elseif key === :language
#        ccall((:gtk_text_iter_get_language,libgtk),Ptr{PangoLanguage},(Ptr{Void},Ptr{GtkTextAttributes}),text)
    elseif key === :is_end
        bool(ccall((:gtk_text_iter_is_end,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :is_start
        bool(ccall((:gtk_text_iter_is_start,libgtk),Cint,(Ptr{Void},),text))
    elseif key === :char
        convert(Char,ccall((:gtk_text_iter_get_char,libgtk),Uint32,(Ptr{Void},),text))
#    elseif key === :pixbuf
#        convert(GdkPixbuf,ccall((:gtk_text_iter_get_char,libgtk),Ptr{GdkPixbuf},(Ptr{Void},),text))
    else
        warn("GtkTextIter doesn't have attribute with key $key")
        false
    end)::outtype
end
setproperty!(text::GtkTextIter,key::String,value) = setproperty!(text,symbol(key),value)
function setproperty!(text::GtkTextIter,key::Symbol,value)
    if     key === :offset
        ccall((:gtk_text_iter_set_offset,libgtk),Cint,(Ptr{Void},Cint),text,value)
    elseif key === :line
        ccall((:gtk_text_iter_set_line,libgtk),Cint,(Ptr{Void},Cint),text,value)
    elseif key === :line_offset
        ccall((:gtk_text_iter_set_line_offset,libgtk),Cint,(Ptr{Void},Cint),text,value)
    elseif key === :line_index
        ccall((:gtk_text_iter_set_line_index,libgtk),Cint,(Ptr{Void},Cint),text,value)
    elseif key === :visible_line_index
        ccall((:gtk_text_iter_set_visible_line_index,libgtk),Cint,(Ptr{Void},Cint),text,value)
    elseif key === :visible_line_offset
        ccall((:gtk_text_iter_set_visible_line_offset,libgtk),Cint,(Ptr{Void},Cint),text,value)
    else
        warn("GtkTextIter doesn't have attribute with key $key")
        false
    end
    return text
end
Base.(:(==))(lhs::GtkTextIter,rhs::GtkTextIter) = bool(ccall((:gtk_text_iter_equal,libgtk),
    Cint,(Ptr{Void},Ptr{Void}),lhs,rhs))
Base.(:(!=))(lhs::GtkTextIter,rhs::GtkTextIter) = !(lhs == rhs)
Base.(:(<))(lhs::GtkTextIter,rhs::GtkTextIter) = ccall((:gtk_text_iter_compare,libgtk),Cint,
    (Ptr{Void},Ptr{Void}),lhs,rhs) < 0
Base.(:(<=))(lhs::GtkTextIter,rhs::GtkTextIter) = ccall((:gtk_text_iter_compare,libgtk),Cint,
    (Ptr{Void},Ptr{Void}),lhs,rhs) <= 0
Base.(:(>))(lhs::GtkTextIter,rhs::GtkTextIter) = ccall((:gtk_text_iter_compare,libgtk),Cint,
    (Ptr{Void},Ptr{Void}),lhs,rhs) > 0
Base.(:(>=))(lhs::GtkTextIter,rhs::GtkTextIter) = ccall((:gtk_text_iter_compare,libgtk),Cint,
    (Ptr{Void},Ptr{Void}),lhs,rhs) >= 0
start(iter::GtkTextIter) = iter
function next(iter::GtkTextIter,state)
    c = iter[:char]::Char
    skip(iter,1)
    (c,iter)
end
done(iter::GtkTextIter,state) = (iter.reverse ? iter[:is_start] : iter[:is_end])::Bool
Base.(:+)(iter::GtkTextIter, count::Integer) = (iter = copy(iter); skip(iter, count); iter)
Base.(:-)(iter::GtkTextIter, count::Integer) = (iter = copy(iter); skip(iter, -count); iter)
Base.skip(iter::GtkTextIter, count::Integer) =
    bool(ccall((:gtk_text_iter_forward_chars,libgtk),Cint,
        (Ptr{Void},Cint), iter, count*(iter.reverse ? -1 : 1) ))
function Base.skip(iter::GtkTextIter, count::Integer, what::Symbol)
    count *= (iter.reverse ? -1 : 1)
    if     what === :char || what === :chars
        bool(ccall((:gtk_text_iter_forward_chars,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :line || what === :lines
        bool(ccall((:gtk_text_iter_forward_lines,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :word || what === :words
        bool(ccall((:gtk_text_iter_forward_word_ends,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :word_cursor_position || what === :word_cursor_positions
        bool(ccall((:gtk_text_iter_forward_cursor_positions,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :sentence || what === :sentences
        bool(ccall((:gtk_text_iter_forward_sentence_ends,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :visible_word || what === :visible_words
        bool(ccall((:gtk_text_iter_forward_visible_word_ends,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :visible_cursor_position || what === :visible_cursor_positions
        bool(ccall((:gtk_text_iter_forward_visible_cursor_positions,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :visible_line || what === :visible_lines
        bool(ccall((:gtk_text_iter_forward_visible_lines,libgtk),Cint,
            (Ptr{Void},Cint), iter, count))
    elseif what === :line_end || what === :line_ends
        @assert(count >= 0, "GtkTextIter cannot iterate line_ends backwards")
        for i = 1:count
            if !bool(ccall((:gtk_text_iter_forward_visible_lines,libgtk),Cint,
                    (Ptr{Void},Cint), iter, count))
                return false
            end
        end
        true
#    elseif what === :end
#        if iter.reverse
#            ccall((:gtk_text_iter_set_offset,libgtk),Void,(Ptr{Void},Cint), iter, 0)
#        else
#            ccall((:gtk_text_iter_forward_to_end,libgtk),Void,(Ptr{Void},), iter)
#        end
#        false
    else
        warn("GtkTextIter doesn't have iterator of type $what")
        false
    end
end
#    gtk_text_iter_forward_to_tag_toggle
#    gtk_text_iter_forward_find_char
#    gtk_text_iter_forward_search


#####  GtkTextRange  #####

colon(a::GtkTextIter,b::GtkTextIter) = GtkTextRange(a,b)
first(r::GtkTextRange) = r.a
last(r::GtkTextRange) = r.b
start(r::GtkTextRange) = start(copy(first(r)))
next(r::GtkTextRange,i::GtkTextIter) = next(i,i)
done(r::GtkTextRange,i::GtkTextIter) = (i==last(r))
getproperty(text::GtkTextRange, key::String, outtype::Type=Any) = getproperty(text, symbol(key), outtype)
function getproperty(text::GtkTextRange, key::Symbol, outtype::Type=Any)
    starttext = first(text)
    endtext = last(text)
    return convert(outtype,
    if     key === :slice
        bytestring(ccall((:gtk_text_iter_get_slice,libgtk),Ptr{Uint8},
            (Ptr{Void},Ptr{Void}),starttext,endtext),true)
    elseif key === :visible_slice
        bytestring(ccall((:gtk_text_iter_get_visible_slice,libgtk),Ptr{Uint8},
            (Ptr{Void},Ptr{Void}),starttext,endtext),true)
    elseif key === :text
        bytestring(ccall((:gtk_text_iter_get_text,libgtk),Ptr{Uint8},
            (Ptr{Void},Ptr{Void}),starttext,endtext),true)
    elseif key === :visible_text
        bytestring(ccall((:gtk_text_iter_get_visible_text,libgtk),Ptr{Uint8},
            (Ptr{Void},Ptr{Void}),starttext,endtext),true)
    end)::outtype
end
function splice!(text::GtkTextBuffer,index::GtkTextRange)
    ccall((:gtk_text_buffer_delete,libgtk),Void,
        (Ptr{GObject},Ptr{Void},Ptr{Void}),text,first(index),last(index))
    text
end
in(x::GtkTextIter, r::GtkTextRange) = bool(ccall((:gtk_text_iter_in_range,libgtk),Cint,
    (Ptr{Void},Ptr{Void},Ptr{Void}),x,first(r),last(r)))


#####  GtkTextBuffer  #####
#TODO: tags, marks
#TODO: clipboard, selection/cursor, user_action_groups

start(text::GtkTextBuffer) = start(GtkTextIter(text))
next(text::GtkTextBuffer, iter::GtkTextIter) = next(iter,iter)
done(text::GtkTextBuffer, iter::GtkTextIter) = done(iter,iter)
length(text::GtkTextBuffer) = ccall((:gtk_text_buffer_get_char_count,libgtk),Cint,
    (Ptr{GObject},),text)
#get_line_count(text::GtkTextBuffer) = ccall((:gtk_text_buffer_get_line_count,libgtk),Cint,(Ptr{GObject},),text)
function insert!(text::GtkTextBuffer,index::GtkTextIter,str::String)
    ccall((:gtk_text_buffer_insert,libgtk),Void,
        (Ptr{GObject},Ptr{Void},Ptr{Uint8},Cint),text,index,bytestring(str),sizeof(str))
    text
end
function insert!(text::GtkTextBuffer,str::String)
    ccall((:gtk_text_buffer_insert_at_cursor,libgtk),Void,
        (Ptr{GObject},Ptr{Uint8},Cint),text,bytestring(str),sizeof(str))
    text
end
function splice!(text::GtkTextBuffer,index::GtkTextIter)
    ccall((:gtk_text_buffer_backspace,libgtk),Void,
        (Ptr{GObject},Ptr{Void},Cint,Cint),text,index,false,true)
    text
end
function splice!(text::GtkTextBuffer)
    ccall((:gtk_text_buffer_delete_selection,libgtk),Cint,
        (Ptr{GObject},Cint,Cint),text,false,true)
    text
end


#####  GtkTextView  #####
#TODO: scrolling/views, child overlays

function gtk_text_view_get_buffer(text::GtkTextView)
    # This is an internal function. Users should use text[:buffer,GtkTextBuffer] to retrieve the buffer object
    ccall((:gtk_text_view_get_buffer,libgtk),Ptr{GObject},(Ptr{GObject},),text)
end
function gtk_text_view_get_editable(text::GtkTextView)
    # This is an internal function. Users should use text[:editable,Bool] instead
    bool(ccall((:gtk_text_view_get_editable,libgtk),Cint,(Ptr{GObject},),text))
end
function insert!(text::GtkTextView,index::GtkTextIter,child::GtkWidgetI)
    anchor = ccall((:gtk_text_buffer_create_child_anchor,libgtk),Ptr{Void},
        (Ptr{GObject},Ptr{Void}),gtk_text_view_get_buffer(text),index)
    ccall((:gtk_text_view_add_child_at_anchor,libgtk),Void,
        (Ptr{GObject},Ptr{GObject},Ptr{Void}),text,index,anchor)
    text
end

function insert!(text::GtkTextView,index::GtkTextIter,str::String)
    bool(ccall((:gtk_text_buffer_insert_interactive,libgtk),Cint,
        (Ptr{GObject},Ptr{Void},Ptr{Uint8},Cint,Cint),
        gtk_text_view_get_buffer(text),index,bytestring(str),sizeof(str),gtk_text_view_get_editable(text)))
    text
end
function insert!(text::GtkTextView,str::String)
    bool(ccall((:gtk_text_buffer_insert_interactive_at_cursor,libgtk),Cint,
        (Ptr{GObject},Ptr{Uint8},Cint,Cint),
        gtk_text_view_get_buffer(text),bytestring(str),sizeof(str),gtk_text_view_get_editable(text)))
    text
end
function splice!(text::GtkTextView,index::GtkTextIter)
    ccall((:gtk_text_buffer_backspace,libgtk),Void,
        (Ptr{GObject},Ptr{Void},Cint,Cint),
        gtk_text_view_get_buffer(text),index,true,gtk_text_view_get_editable(text))
    text
end
function splice!(text::GtkTextView)
    ccall((:gtk_text_buffer_delete_selection,libgtk),Cint,
        (Ptr{GObject},Cint,Cint),
        gtk_text_view_get_buffer(text),true,gtk_text_view_get_editable(text))
    text
end


####  GtkTextMark  ####

visible(w::GtkTextMark) =
    bool(ccall((:gtk_text_mark_get_visible,libgtk),Cint,(Ptr{GObject},),w))
visible(w::GtkTextMark, state::Bool) =
    ccall((:gtk_text_mark_set_visible,libgtk),Void,(Ptr{GObject},Cint),w,state)
show(w::GtkTextMark) = visible(w,true)

@deprecate getindex(text::GtkTextIter, key::String, outtype::Type=Any) getproperty(text, key, outtype)
@deprecate getindex(text::GtkTextIter, key::Symbol, outtype::Type=Any) getproperty(text, key, outtype)
@deprecate setindex!(text::GtkTextIter, value, key::Union(Symbol,String)) setproperty!(text, key, value)
@deprecate getindex(text::GtkTextRange, key::Union(Symbol,String), outtype::Type=Any) getproperty(text, key, outtype)
