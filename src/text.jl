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

GtkLabelLeaf(title) = GtkLabelLeaf(
    ccall((:gtk_label_new, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(title)))

GtkTextBufferLeaf() = GtkTextBufferLeaf(
    ccall((:gtk_text_buffer_new, libgtk), Ptr{GObject}, (Ptr{GObject},), C_NULL))

GtkTextViewLeaf(buffer::GtkTextBuffer = GtkTextBuffer()) = GtkTextViewLeaf(
    ccall((:gtk_text_view_new_with_buffer, libgtk), Ptr{GObject}, (Ptr{GObject},), buffer))

GtkTextMarkLeaf(left_gravity::Bool = false) = GtkTextMarkLeaf(
    ccall((:gtk_text_mark_new, libgtk), Ptr{GObject}, (Ptr{UInt8}, Cint), C_NULL, left_gravity))

GtkTextTagLeaf() = GtkTextTagLeaf(
    ccall((:gtk_text_tag_new, libgtk), Ptr{GObject}, (Ptr{UInt8},), C_NULL))
GtkTextTagLeaf(name::AbstractString) = GtkTextTagLeaf(
    ccall((:gtk_text_tag_new, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(name)))

struct GtkTextIter
  dummy1::Ptr{Nothing}
  dummy2::Ptr{Nothing}
  dummy3::Cint
  dummy4::Cint
  dummy5::Cint
  dummy6::Cint
  dummy7::Cint
  dummy8::Cint
  dummy9::Ptr{Nothing}
  dummy10::Ptr{Nothing}
  dummy11::Cint
  dummy12::Cint
  dummy13::Cint
  dummy14::Ptr{Nothing}
  GtkTextIter() = new(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
end
const TI = Union{Mutable{GtkTextIter}, GtkTextIter}
zero(::Type{GtkTextIter}) = GtkTextIter()
copy(ti::GtkTextIter) = ti
copy(ti::Mutable{GtkTextIter}) = mutable(ti[])
function GtkTextIter(text::GtkTextBuffer, char_offset::Integer)
    iter = mutable(GtkTextIter)
    ccall((:gtk_text_buffer_get_iter_at_offset, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GtkTextIter}, Cint), text, iter, char_offset - 1)
    iter[]
end
function GtkTextIter(text::GtkTextBuffer, line::Integer, char_offset::Integer)
    iter = mutable(GtkTextIter)
    ccall((:gtk_text_buffer_get_iter_at_line_offset, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GtkTextIter}, Cint, Cint), text, iter, line - 1, char_offset - 1)
    iter[]
end
function GtkTextIter(text::GtkTextBuffer)
    iter = mutable(GtkTextIter)
    ccall((:gtk_text_buffer_get_start_iter, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GtkTextIter}), text, iter)
    iter[]
end
function GtkTextIter(text::GtkTextBuffer, mark::GtkTextMark)
    iter = mutable(GtkTextIter)
    ccall((:gtk_text_buffer_get_iter_at_mark, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GtkTextIter}, Ptr{GObject}), text, iter, mark)
    iter[]
end

show(io::IO, iter::GtkTextIter) = println("GtkTextIter($( get_gtk_property(iter,:offset,Int) ))")

Base.cconvert(::Type{Ref{GtkTextIter}},x::GtkTextIter) = Ref(x)
Base.cconvert(::Type{Ref{GtkTextIter}},x::Gtk.Mutable{GtkTextIter}) = Ref(x[])

struct GtkTextRange <: AbstractRange{Char}
    a::MutableTypes.MutableX{GtkTextIter}
    b::MutableTypes.MutableX{GtkTextIter}
    GtkTextRange(a, b) = new(mutable(copy(a)), mutable(copy(b)))
end

#type GtkClipboard
#TODO
#end

#####  GtkTextIter  #####
#TODO: search
get_gtk_property(text::TI, key::AbstractString, outtype::Type = Any) = get_gtk_property(text, Symbol(key), outtype)
function get_gtk_property(text::TI, key::Symbol, outtype::Type = Any)
    text = mutable(text)
    return convert(outtype,
    if     key === :offset
        ccall((:gtk_text_iter_get_offset, libgtk), Cint, (Ptr{GtkTextIter},), text)
    elseif key === :line
        ccall((:gtk_text_iter_get_line, libgtk), Cint, (Ptr{GtkTextIter},), text)
    elseif key === :line_offset
        ccall((:gtk_text_iter_get_line_offset, libgtk), Cint, (Ptr{GtkTextIter},), text)
    elseif key === :line_index
        ccall((:gtk_text_iter_get_line_index, libgtk), Cint, (Ptr{GtkTextIter},), text)
    elseif key === :visible_line_index
        ccall((:gtk_text_iter_get_visible_line_index, libgtk), Cint, (Ptr{GtkTextIter},), text)
    elseif key === :visible_line_offset
        ccall((:gtk_text_iter_get_visible_line_offset, libgtk), Cint, (Ptr{GtkTextIter},), text)
    elseif key === :marks
        ccall((:gtk_text_iter_get_marks, libgtk), Ptr{_GSList{GtkTextMark}}, (Ptr{GtkTextIter},), text) # GtkTextMark iter
    elseif key === :toggled_on_tags
        ccall((:gtk_text_iter_get_toggled_tags, libgtk), Ptr{_GSList{GtkTextTag}}, (Ptr{GtkTextIter}, Cint), text, true) # GtkTextTag iter
    elseif key === :toggled_off_tags
        ccall((:gtk_text_iter_get_toggled_tags, libgtk), Ptr{_GSList{GtkTextTag}}, (Ptr{GtkTextIter}, Cint), text, false) # GtkTextTag iter
#    elseif key === :child_anchor
#        convert(GtkTextChildAnchor, ccall((:gtk_text_iter_get_child_anchor, libgtk), Ptr{GtkTextChildAnchor}, (Ptr{GtkTextIter}, Cint), text, false))
    elseif key === :can_insert
        Bool(ccall((:gtk_text_iter_can_insert, libgtk), Cint, (Ptr{GtkTextIter}, Cint), text, true))
    elseif key === :starts_word
        Bool(ccall((:gtk_text_iter_starts_word, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :ends_word
        Bool(ccall((:gtk_text_iter_ends_word, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :inside_word
        Bool(ccall((:gtk_text_iter_inside_word, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :starts_line
        Bool(ccall((:gtk_text_iter_starts_line, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :ends_line
        Bool(ccall((:gtk_text_iter_ends_line, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :starts_sentence
        Bool(ccall((:gtk_text_iter_starts_sentence, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :ends_sentence
        Bool(ccall((:gtk_text_iter_ends_sentence, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :inside_sentence
        Bool(ccall((:gtk_text_iter_inside_sentence, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :is_cursor_position
        Bool(ccall((:gtk_text_iter_is_cursor_position, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :chars_in_line
        ccall((:gtk_text_iter_get_chars_in_line, libgtk), Cint, (Ptr{GtkTextIter},), text)
    elseif key === :bytes_in_line
        ccall((:gtk_text_iter_get_bytes_in_line, libgtk), Cint, (Ptr{GtkTextIter},), text)
#    elseif key === :attributes
#        view = get_gtk_property(text, :view)::GtkTextView
#        attrs = get_gtk_property(view, :default_attributes)::GtkTextAttributes
#        ccall((:gtk_text_iter_get_attributes, libgtk), Cint, (Ptr{GtkTextIter}, Ptr{GtkTextAttributes}), text, &attrs)
#        attrs
#    elseif key === :language
#        ccall((:gtk_text_iter_get_language, libgtk), Ptr{PangoLanguage}, (Ptr{GtkTextIter}, Ptr{GtkTextAttributes}), text)
    elseif key === :is_end
        Bool(ccall((:gtk_text_iter_is_end, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :is_start
        Bool(ccall((:gtk_text_iter_is_start, libgtk), Cint, (Ptr{GtkTextIter},), text))
    elseif key === :char
        convert(Char, ccall((:gtk_text_iter_get_char, libgtk), UInt32, (Ptr{GtkTextIter},), text))
    elseif key === :pixbuf
        convert(GdkPixbuf, ccall((:gtk_text_iter_get_char, libgtk), Ptr{GdkPixbuf}, (Ptr{GtkTextIter},), text))
    else
        warn("GtkTextIter doesn't have attribute with key $key")
        false
    end)::outtype
end

set_gtk_property!(text::Mutable{GtkTextIter}, key::AbstractString, value) = set_gtk_property!(text, Symbol(key), value)
function set_gtk_property!(text::Mutable{GtkTextIter}, key::Symbol, value)
    if     key === :offset
        ccall((:gtk_text_iter_set_offset, libgtk), Cint, (Ptr{GtkTextIter}, Cint), text, value)
    elseif key === :line
        ccall((:gtk_text_iter_set_line, libgtk), Cint, (Ptr{GtkTextIter}, Cint), text, value)
    elseif key === :line_offset
        ccall((:gtk_text_iter_set_line_offset, libgtk), Cint, (Ptr{GtkTextIter}, Cint), text, value)
    elseif key === :line_index
        ccall((:gtk_text_iter_set_line_index, libgtk), Cint, (Ptr{GtkTextIter}, Cint), text, value)
    elseif key === :visible_line_index
        ccall((:gtk_text_iter_set_visible_line_index, libgtk), Cint, (Ptr{GtkTextIter}, Cint), text, value)
    elseif key === :visible_line_offset
        ccall((:gtk_text_iter_set_visible_line_offset, libgtk), Cint, (Ptr{GtkTextIter}, Cint), text, value)
    else
        warn("GtkTextIter doesn't have attribute with key $key")
        false
    end
    return text
end

Base.:(==)(lhs::TI, rhs::TI) = Bool(ccall((:gtk_text_iter_equal, libgtk),
    Cint, (Ref{GtkTextIter}, Ref{GtkTextIter}), lhs, rhs))
Base.:(!=)(lhs::TI, rhs::TI) = !(lhs == rhs)
Base.:(<)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk), Cint,
    (Ref{GtkTextIter}, Ref{GtkTextIter}), lhs, rhs) < 0
Base.:(<=)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk), Cint,
    (Ref{GtkTextIter}, Ref{GtkTextIter}), lhs, rhs) <= 0
Base.:(>)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk), Cint,
    (Ref{GtkTextIter}, Ref{GtkTextIter}), lhs, rhs) > 0
Base.:(>=)(lhs::TI, rhs::TI) = ccall((:gtk_text_iter_compare, libgtk), Cint,
    (Ref{GtkTextIter}, Ref{GtkTextIter}), lhs, rhs) >= 0

start_(iter::TI) = mutable(iter)
iterate(::TI, iter=start_(iter)) =
   get_gtk_property(iter, :is_end, Bool) ? nothing : (get_gtk_property(iter, :char)::Char, iter + 1)

Base.:+(iter::TI, count::Integer) = (iter = mutable(copy(iter)); skip(iter, count); iter)
Base.:-(iter::TI, count::Integer) = (iter = mutable(copy(iter)); skip(iter, -count); iter)

Base.skip(iter::Mutable{GtkTextIter}, count::Integer) =
    Bool(ccall((:gtk_text_iter_forward_chars, libgtk), Cint,
        (Ptr{GtkTextIter}, Cint), iter, count))
function Base.skip(iter::Mutable{GtkTextIter}, count::Integer, what::Symbol)
    if     what === :char || what === :chars
        Bool(ccall((:gtk_text_iter_forward_chars, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :line || what === :lines
        Bool(ccall((:gtk_text_iter_forward_lines, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :word || what === :words
        Bool(ccall((:gtk_text_iter_forward_word_ends, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :word_cursor_position || what === :word_cursor_positions
        Bool(ccall((:gtk_text_iter_forward_cursor_positions, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :sentence || what === :sentences
        Bool(ccall((:gtk_text_iter_forward_sentence_ends, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :visible_word || what === :visible_words
        Bool(ccall((:gtk_text_iter_forward_visible_word_ends, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :visible_cursor_position || what === :visible_cursor_positions
        Bool(ccall((:gtk_text_iter_forward_visible_cursor_positions, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :visible_line || what === :visible_lines
        Bool(ccall((:gtk_text_iter_forward_visible_lines, libgtk), Cint,
            (Ptr{GtkTextIter}, Cint), iter, count))
    elseif what === :line_end || what === :line_ends
        count >= 0 || error("GtkTextIter cannot iterate line_ends backwards")
        for i = 1:count
            if !Bool(ccall((:gtk_text_iter_forward_visible_lines, libgtk), Cint,
                    (Ptr{GtkTextIter}, Cint), iter, count))
                return false
            end
        end
        true
#    elseif what === :end
#        ccall((:gtk_text_iter_forward_to_end, libgtk), Nothing, (Ptr{Nothing},), iter)
#        true
#    elseif what === :begin
#        ccall((:gtk_text_iter_set_offset, libgtk), Nothing, (Ptr{Nothing}, Cint), iter, 0)
#        true
    else
        warn("GtkTextIter doesn't have iterator of type $what")
        false
    end::Bool
end
#    gtk_text_iter_forward_to_tag_toggle
#    gtk_text_iter_forward_find_char
#    gtk_text_iter_forward_search

buffer(iter::TI) = convert(GtkTextBuffer,
    ccall((:gtk_text_iter_get_buffer, libgtk),Ptr{GtkTextBuffer},(Ref{GtkTextIter},),iter)
)

#####  GtkTextRange  #####

(:)(a::TI, b::TI) = GtkTextRange(a, b)
function getindex(r::GtkTextRange, b::Int)
    a = mutable(copy(first(r)))
    b -= 1
    if b < 0 || (b > 0 && !skip(a, b)) || a >= last(r)
        throw(BoundsError())
    end
    get_gtk_property(a, :char)::Char
end
function length(r::GtkTextRange)
    a = mutable(copy(first(r)))
    b = last(r)
    cnt = 0
    while a < b
        if !skip(a, 1)
            break
        end
        cnt += 1
    end
    cnt
end
show(io::IO, r::GtkTextRange) = print("GtkTextRange(\"", get_gtk_property(r, :text), "\")")
first(r::GtkTextRange) = r.a
last(r::GtkTextRange) = r.b
start_(r::GtkTextRange) = start(first(r))
next_(r::GtkTextRange, i) = next(i, i)
done_(r::GtkTextRange, i) = (i == last(r) || done(i, i))
iterate(r::GtkTextRange, i=start_(r)) = done_(r, i) ? nothing : next_(r, i)

# this enable the (its:ite).text[String] syntax
function getproperty(obj::GtkTextRange, field::Symbol) 
    isdefined(obj,field) && return getfield(obj,field)
    FieldRef(obj, field)
end

get_gtk_property(text::GtkTextRange, key::AbstractString, outtype::Type = Any) = get_gtk_property(text, Symbol(key), outtype)
function get_gtk_property(text::GtkTextRange, key::Symbol, outtype::Type = Any)
    starttext = first(text)
    endtext = last(text)
    return convert(outtype,
    if     key === :slice
        bytestring(ccall((:gtk_text_iter_get_slice, libgtk), Ptr{UInt8},
            (Ptr{GtkTextIter}, Ptr{GtkTextIter}), starttext, endtext))
    elseif key === :visible_slice
        bytestring(ccall((:gtk_text_iter_get_visible_slice, libgtk), Ptr{UInt8},
            (Ptr{GtkTextIter}, Ptr{GtkTextIter}), starttext, endtext))
    elseif key === :text
        bytestring(ccall((:gtk_text_iter_get_text, libgtk), Ptr{UInt8},
            (Ptr{GtkTextIter}, Ptr{GtkTextIter}), starttext, endtext))
    elseif key === :visible_text
        bytestring(ccall((:gtk_text_iter_get_visible_text, libgtk), Ptr{UInt8},
            (Ptr{GtkTextIter}, Ptr{GtkTextIter}), starttext, endtext))
    end)::outtype
end
function splice!(text::GtkTextBuffer, index::GtkTextRange)
    ccall((:gtk_text_buffer_delete, libgtk), Nothing,
        (Ptr{GObject}, Ref{GtkTextIter}, Ref{GtkTextIter}), text, first(index), last(index))
    text
end
in(x::TI, r::GtkTextRange) = Bool(ccall((:gtk_text_iter_in_range, libgtk), Cint,
    (Ptr{GtkTextIter}, Ptr{GtkTextIter}, Ptr{GtkTextIter}), mutable(x), first(r), last(r)))


#####  GtkTextBuffer  #####
#TODO: tags, marks
#TODO: clipboard, selection/cursor, user_action_groups

iterate(text::GtkTextBuffer, iter=start_(GtkTextIter(text))) = iterate(iter, iter)
length(text::GtkTextBuffer) = ccall((:gtk_text_buffer_get_char_count, libgtk), Cint,
    (Ptr{GObject},), text)
#get_line_count(text::GtkTextBuffer) = ccall((:gtk_text_buffer_get_line_count, libgtk), Cint, (Ptr{GObject},), text)
function insert!(text::GtkTextBuffer, index::TI, str::AbstractString)
    ccall((:gtk_text_buffer_insert, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GtkTextIter}, Ptr{UInt8}, Cint), text, mutable(index), bytestring(str), sizeof(str))
    text
end
function insert!(text::GtkTextBuffer, str::AbstractString)
    ccall((:gtk_text_buffer_insert_at_cursor, libgtk), Nothing,
        (Ptr{GObject}, Ptr{UInt8}, Cint), text, bytestring(str), sizeof(str))
    text
end
function splice!(text::GtkTextBuffer, index::TI)
    ccall((:gtk_text_buffer_backspace, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GtkTextIter}, Cint, Cint), text, mutable(index), false, true)
    text
end
function splice!(text::GtkTextBuffer)
    ccall((:gtk_text_buffer_delete_selection, libgtk), Cint,
        (Ptr{GObject}, Cint, Cint), text, false, true)
    text
end

begin_user_action(buffer::GtkTextBuffer) =
  ccall((:gtk_text_buffer_begin_user_action, libgtk), Nothing, (Ptr{GObject},), buffer)

end_user_action(buffer::GtkTextBuffer) =
  ccall((:gtk_text_buffer_end_user_action, libgtk), Nothing, (Ptr{GObject},), buffer)

function user_action(f::Function, buffer::GtkTextBuffer)
    begin_user_action(buffer)
    try
      f(buffer)
    finally
      end_user_action(buffer)
    end
end

function create_tag(buffer::GtkTextBuffer, tag_name::AbstractString; properties...)
    tag = GtkTextTag(ccall((:gtk_text_buffer_create_tag, libgtk), Ptr{GObject},
                (Ptr{GObject}, Ptr{UInt8}, Ptr{Nothing}),
                buffer, bytestring(tag_name), C_NULL))
    for (k, v) in properties
        set_gtk_property!(tag, k, v)
    end
    tag
end

function apply_tag(buffer::GtkTextBuffer, name::AbstractString, itstart::TI, itend::TI)
    ccall((:gtk_text_buffer_apply_tag_by_name, libgtk), Nothing,
         (Ptr{GObject}, Ptr{UInt8}, Ref{GtkTextIter}, Ref{GtkTextIter}),
         buffer, bytestring(name), itstart, itend)
end

function remove_tag(buffer::GtkTextBuffer, name::AbstractString, itstart::TI, itend::TI)
    ccall((:gtk_text_buffer_remove_tag_by_name, libgtk), Nothing,
         (Ptr{GObject}, Ptr{UInt8}, Ref{GtkTextIter}, Ref{GtkTextIter}),
         buffer, bytestring(name), itstart, itend)
end

function remove_all_tags(buffer::GtkTextBuffer, itstart::TI, itend::TI)
    ccall((:gtk_text_buffer_remove_all_tags, libgtk), Nothing,
         (Ptr{GObject}, Ref{GtkTextIter}, Ref{GtkTextIter}),
         buffer, itstart, itend)
end

#####  GtkTextView  #####
#TODO: scrolling/views, child overlays

function gtk_text_view_get_buffer(text::GtkTextView)
    # This is an internal function. Users should use text[:buffer, GtkTextBuffer] to retrieve the buffer object
    ccall((:gtk_text_view_get_buffer, libgtk), Ptr{GObject}, (Ptr{GObject},), text)
end
function gtk_text_view_get_editable(text::GtkTextView)
    # This is an internal function. Users should use text[:editable, Bool] instead
    Bool(ccall((:gtk_text_view_get_editable, libgtk), Cint, (Ptr{GObject},), text))
end
function insert!(text::GtkTextView, index::TI, child::GtkWidget)
    index = mutable(index)
    anchor = ccall((:gtk_text_buffer_create_child_anchor, libgtk), Ptr{Nothing},
        (Ptr{GObject}, Ptr{GtkTextIter}), gtk_text_view_get_buffer(text), index)
    ccall((:gtk_text_view_add_child_at_anchor, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GObject}, Ptr{GtkTextIter}), text, index, anchor)
    text
end

function insert!(text::GtkTextView, index::TI, str::AbstractString)
    Bool(ccall((:gtk_text_buffer_insert_interactive, libgtk), Cint,
        (Ptr{GObject}, Ptr{GtkTextIter}, Ptr{UInt8}, Cint, Cint),
        gtk_text_view_get_buffer(text), mutable(index), bytestring(str), sizeof(str), gtk_text_view_get_editable(text)))
    text
end
function insert!(text::GtkTextView, str::AbstractString)
    Bool(ccall((:gtk_text_buffer_insert_interactive_at_cursor, libgtk), Cint,
        (Ptr{GObject}, Ptr{UInt8}, Cint, Cint),
        gtk_text_view_get_buffer(text), bytestring(str), sizeof(str), gtk_text_view_get_editable(text)))
    text
end
function splice!(text::GtkTextView, index::TI)
    ccall((:gtk_text_buffer_backspace, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GtkTextIter}, Cint, Cint),
        gtk_text_view_get_buffer(text), mutable(index), true, gtk_text_view_get_editable(text))
    text
end
function splice!(text::GtkTextView)
    ccall((:gtk_text_buffer_delete_selection, libgtk), Cint,
        (Ptr{GObject}, Cint, Cint),
        gtk_text_view_get_buffer(text), true, gtk_text_view_get_editable(text))
    text
end


####  GtkTextMark  ####

visible(w::GtkTextMark) =
    Bool(ccall((:gtk_text_mark_get_visible, libgtk), Cint, (Ptr{GObject},), w))
visible(w::GtkTextMark, state::Bool) =
    ccall((:gtk_text_mark_set_visible, libgtk), Nothing, (Ptr{GObject}, Cint), w, state)
show(w::GtkTextMark) = visible(w, true)
