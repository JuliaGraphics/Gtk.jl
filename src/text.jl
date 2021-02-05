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

"""
    GtkTextIter(text::GtkTextBuffer, char_offset::Integer)

Creates a `GtkTextIter` with offset `char_offset` (one-based index).
"""
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

function getproperty(obj::TI, field::Symbol)
    isdefined(obj,field) && return getfield(obj,field)
    FieldRef(obj, field)
end

show(io::IO, iter::GtkTextIter) = println("GtkTextIter($( get_gtk_property(iter,:offset,Int) ))")


"""
    buffer(iter::Union{Mutable{GtkTextIter}, GtkTextIter})

Returns the buffer associated with `iter`.
"""
buffer(iter::TI) = convert(GtkTextBuffer,
    ccall((:gtk_text_iter_get_buffer, libgtk),Ptr{GtkTextBuffer},(Ref{GtkTextIter},),iter)
)

"""
    char_offset(iter::Union{Mutable{GtkTextIter}, GtkTextIter})

Returns the offset of `iter` (one-based index).
"""
char_offset(iter::TI) = get_gtk_property(iter, :offset)+1

Base.cconvert(::Type{Ref{GtkTextIter}}, it::GtkTextIter) = Ref(it)
Base.cconvert(::Type{Ref{GtkTextIter}}, it::Gtk.Mutable{GtkTextIter}) = Ref(it[])
Base.convert(::Type{GtkTextIter}, it::Mutable{GtkTextIter}) = GtkTextIter(buffer(it), char_offset(it))#there's a -1 in the constructor

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

"""
    skip(iter::Mutable{GtkTextIter}, count::Integer)

Moves `iter` `count` characters. Returns a Bool indicating if the move was
successful.
"""
Base.skip(iter::Mutable{GtkTextIter}, count::Integer) =
    Bool(ccall((:gtk_text_iter_forward_chars, libgtk), Cint,
        (Ptr{GtkTextIter}, Cint), iter, count))

"""
    skip(iter::Mutable{GtkTextIter}, what::Symbol)

Moves `iter` according to the operation specified by `what`.
Operations are :

* :forward_line (gtk_text_iter_forward_line)
* :backward_line (gtk_text_iter_backward_line)
* :forward_to_line_end (gtk_text_iter_forward_to_line_end)
* :backward_word_start (gtk_text_iter_forward_word_end)
* :forward_word_end (gtk_text_iter_backward_word_start)
* :backward_sentence_start (gtk_text_iter_backward_sentence_start)
* :forward_sentence_end (gtk_text_iter_forward_sentence_end)
"""
function Base.skip(iter::Mutable{GtkTextIter}, what::Symbol)
    if     what === :backward_line
        Bool(ccall((:gtk_text_iter_backward_line, libgtk), Cint,
            (Ptr{GtkTextIter},), iter))
    elseif what === :forward_line
        Bool(ccall((:gtk_text_iter_forward_line, libgtk), Cint,
            (Ptr{GtkTextIter},), iter))
    elseif what === :forward_to_line_end
        Bool(ccall((:gtk_text_iter_forward_to_line_end, libgtk), Cint,
            (Ptr{GtkTextIter},), iter))
    elseif what === :forward_word_end
        Bool(ccall((:gtk_text_iter_forward_word_end, libgtk), Cint,
            (Ptr{GtkTextIter},), iter))
    elseif what === :backward_word_start
        Bool(ccall((:gtk_text_iter_backward_word_start, libgtk), Cint,
            (Ptr{GtkTextIter},), iter))
    elseif what === :backward_sentence_start
        Bool(ccall((:gtk_text_iter_backward_sentence_start, libgtk), Cint,
            (Ptr{GtkTextIter},), iter))
    elseif what === :forward_sentence_end
        Bool(ccall((:gtk_text_iter_forward_sentence_end, libgtk), Cint,
            (Ptr{GtkTextIter},), iter))
    else
        @warn "GtkTextIter doesn't have iterator of type $what"
        false
    end::Bool

end

"""
    skip(iter::Mutable{GtkTextIter}, count::Integer, what::Symbol)

Moves `iter` according to the operation specified by `what` and
`count`.
Operations are :

* :chars (gtk_text_iter_forward_chars)
* :lines (gtk_text_iter_forward_lines)
* :words (gtk_text_iter_forward_word_ends)
* :word_cursor_positions (gtk_text_iter_forward_cursor_positions)
* :sentences (gtk_text_iter_forward_sentence_ends)
* :visible_words (gtk_text_iter_forward_visible_word_ends)
* :visible_cursor_positions (gtk_text_iter_forward_visible_cursor_positions)
* :visible_lines (gtk_text_iter_forward_visible_lines)
* :line_ends (gtk_text_iter_forward_visible_lines)
"""
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


"""
    forward_search(iter::Mutable{GtkTextIter},
        str::AbstractString, start::Mutable{GtkTextIter},
        stop::Mutable{GtkTextIter}, limit::Mutable{GtkTextIter}, flag::Int32)

    Implements `gtk_text_iter_forward_search`.
"""
function forward_search(iter::Mutable{GtkTextIter},
    str::AbstractString, start::Mutable{GtkTextIter},
    stop::Mutable{GtkTextIter}, limit::Mutable{GtkTextIter}, flag::Int32)

    Bool(ccall((:gtk_text_iter_forward_search, libgtk),
        Cint,
        (Ptr{GtkTextIter}, Ptr{UInt8}, Cint, Ptr{GtkTextIter}, Ptr{GtkTextIter}, Ptr{GtkTextIter}),
        iter, string(str), flag, start, stop, limit
    ))
end

"""
    backward_search(iter::Mutable{GtkTextIter},
        str::AbstractString, start::Mutable{GtkTextIter},
        stop::Mutable{GtkTextIter}, limit::Mutable{GtkTextIter}, flag::Int32)

    Implements `gtk_text_iter_backward_search`.
"""
function backward_search(iter::Mutable{GtkTextIter},
    str::AbstractString, start::Mutable{GtkTextIter},
    stop::Mutable{GtkTextIter}, limit::Mutable{GtkTextIter}, flag::Int32)

    Bool(ccall((:gtk_text_iter_backward_search, libgtk),
        Cint,
        (Ptr{GtkTextIter}, Ptr{UInt8}, Cint, Ptr{GtkTextIter}, Ptr{GtkTextIter}, Ptr{GtkTextIter}),
        iter, string(str), flag, start, stop, limit
    ))
end

"""
    search(buffer::GtkTextBuffer, str::AbstractString, direction = :forward,
        flag = GtkTextSearchFlags.GTK_TEXT_SEARCH_TEXT_ONLY)

Search text `str` in buffer in `direction` :forward or :backward starting from
the cursor position in the buffer.

Returns a tuple `(found, start, stop)` where `found` indicates whether the search
was successful and `start` and `stop` are GtkTextIters containing the location of the match.
"""
function search(buffer::GtkTextBuffer, str::AbstractString, direction = :forward,
    flag = GtkTextSearchFlags.GTK_TEXT_SEARCH_TEXT_ONLY)

    start = mutable(GtkTextIter(buffer))
    stop  = mutable(GtkTextIter(buffer))
    iter  = mutable(GtkTextIter(buffer, buffer.cursor_position[Int]))

    if direction == :forward
        limit = mutable(GtkTextIter(buffer, length(buffer)+1))
        found = forward_search( iter, str, start, stop, limit, flag)
    elseif direction == :backward
        limit = mutable(GtkTextIter(buffer, 1))
        found = backward_search(iter, str, start, stop, limit, flag)
    else
        error("Search direction must be :forward or :backward.")
    end

    return (found, start, stop)
end

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
    if key === :slice
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

setindex!(buffer::GtkTextBuffer, content::String, ::Type{String}) =
    ccall((:gtk_text_buffer_set_text, Gtk.libgtk), Nothing, (Ptr{Gtk.GObject}, Ptr{UInt8}, Cint), buffer, content, -1)

"""
    selection_bounds(buffer::GtkTextBuffer)

Returns a tuple `(selected, start, stop)` indicating if text is selected
in the `buffer`, and if so sets the GtkTextIter `start` and `stop` to point to
the selected text.

Implements `gtk_text_buffer_get_selection_bounds`.
"""
function selection_bounds(buffer::GtkTextBuffer)
    start = mutable(GtkTextIter(buffer))
    stop  = mutable(GtkTextIter(buffer))
    selected = Bool(ccall((:gtk_text_buffer_get_selection_bounds,libgtk), Cint,
        (Ptr{GObject}, Ptr{GtkTextIter}, Ptr{GtkTextIter}), buffer, start, stop))
    return (selected, start, stop)
end

"""
    select_range(buffer::GtkTextBuffer, ins::TI, bound::TI)
    select_range(buffer::GtkTextBuffer, range::GtkTextRange)

Select the text in `buffer` accorind to GtkTextIter `ins` and `bound`.

Implements `gtk_text_buffer_select_range`.
"""
function select_range(buffer::GtkTextBuffer, ins::TI, bound::TI)
    ccall((:gtk_text_buffer_select_range, libgtk), Cvoid, (Ptr{GObject}, Ref{GtkTextIter}, Ref{GtkTextIter}), buffer, ins, bound)
end
select_range(buffer::GtkTextBuffer, range::GtkTextRange) = select_range(buffer, range.a, range.b)

"""
    place_cursor(buffer::GtkTextBuffer, it::GtkTextIter)
    place_cursor(buffer::GtkTextBuffer, pos::Int)

Place the cursor at indicated position.
"""
place_cursor(buffer::GtkTextBuffer, it::GtkTextIter)  =
    ccall((:gtk_text_buffer_place_cursor, libgtk), Cvoid, (Ptr{GObject}, Ref{GtkTextIter}), buffer, it)
place_cursor(buffer::GtkTextBuffer, pos::Int) = place_cursor(buffer, GtkTextIter(buffer, pos))
place_cursor(buffer::GtkTextBuffer, it::Mutable{GtkTextIter}) = place_cursor(buffer, convert(GtkTextIter,it))

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

"""
    create_mark(buffer::GtkTextBuffer, mark_name, it::TI, left_gravity::Bool)
    create_mark(buffer::GtkTextBuffer, it::TI)

Impements `gtk_text_buffer_create_mark`.
"""
create_mark(buffer::GtkTextBuffer, mark_name, it::TI, left_gravity::Bool)  =
    GtkTextMarkLeaf(ccall((:gtk_text_buffer_create_mark, libgtk), Ptr{GObject},
    (Ptr{Gtk.GObject}, Ptr{UInt8}, Ref{GtkTextIter}, Cint), buffer, mark_name, it, left_gravity))

create_mark(buffer::GtkTextBuffer, it::TI)  = create_mark(buffer, C_NULL, it, false)

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

function getindex(text::GtkTextView, sym::Symbol, ::Type{GtkTextBuffer})
    sym === :buffer || error("must supply :buffer, got ", sym)
    return convert(GtkTextBuffer, gtk_text_view_get_buffer(text))::GtkTextBuffer
end
function getindex(text::GtkTextView, sym::Symbol, ::Type{Bool})
    sym === :editable || error("must supply :editable, got ", sym)
    return convert(Bool, gtk_text_view_get_editable(text))::Bool
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

"""
    scroll_to(view::GtkTextView, mark::GtkTextMark, within_margin::Real,
                   use_align::Bool, xalign::Real, yalign::Real)

    scroll_to(view::GtkTextView, iter::TI, within_margin::Real,
              use_align::Bool, xalign::Real, yalign::Real)

Implements `gtk_text_view_scroll_to_mark` and `gtk_text_view_scroll_to_iter`.
"""
function scroll_to(view::GtkTextView, mark::GtkTextMark, within_margin::Real,
                   use_align::Bool, xalign::Real, yalign::Real)

    ccall((:gtk_text_view_scroll_to_mark, libgtk), Nothing,
    (Ptr{GObject}, Ptr{GObject}, Cdouble, Cint, Cdouble, Cdouble),
    view, mark, within_margin, use_align, xalign, yalign)
end

function scroll_to(view::GtkTextView, iter::TI, within_margin::Real,
                   use_align::Bool, xalign::Real, yalign::Real)

    ccall((:gtk_text_view_scroll_to_iter, libgtk), Nothing,
    (Ptr{GObject}, Ptr{GtkTextIter}, Cdouble, Cint, Cdouble, Cdouble),
    view, iter, within_margin, use_align, xalign, yalign)
end


"""
    buffer_to_window_coords(view::GtkTextView, buffer_x::Integer, buffer_y::Integer, wintype::Integer = 0)

Implements `gtk_text_view_buffer_to_window_coords`.
"""
function buffer_to_window_coords(view::GtkTextView, buffer_x::Integer, buffer_y::Integer, wintype::Integer = 0)
	window_x, window_y = Gtk.mutable(Cint), Gtk.mutable(Cint)
	ccall(
        (:gtk_text_view_buffer_to_window_coords, libgtk), Cvoid,
        (Ptr{Gtk.GObject}, Cint, Cint, Cint, Ptr{Cint}, Ptr{Cint}), 
        view, Int32(wintype), buffer_x, buffer_y, window_x, window_y
    )
	return (window_x[], window_y[])
end

"""
    window_to_buffer_coords(view::Gtk.GtkTextView, window_x::Integer, window_y::Integer, wintype::Integer = 2)

Implements `gtk_text_view_window_to_buffer_coords`.
"""
function window_to_buffer_coords(view::GtkTextView, window_x::Integer, window_y::Integer, wintype::Integer = 2)
    buffer_x, buffer_y = Gtk.mutable(Cint), Gtk.mutable(Cint)
    ccall(
        (:gtk_text_view_window_to_buffer_coords, libgtk), Cvoid,
        (Ptr{GObject}, Cint, Cint, Cint, Ptr{Cint}, Ptr{Cint}), 
        view, Int32(wintype), window_x, window_y, buffer_x, buffer_y
    )
    return (buffer_x[],buffer_y[])
end

"""
    text_iter_at_position(view::GtkTextView, x::Integer, y::Integer)

Implements `gtk_text_view_get_iter_at_position`.
"""
function text_iter_at_position(view::GtkTextView, x::Integer, y::Integer)
    buffer = view.buffer[GtkTextBuffer]
    iter = mutable(GtkTextIter(buffer))
    text_iter_at_position(view, iter, C_NULL, Int32(x), Int32(y))
    return GtkTextIter(buffer, char_offset(iter))
end

text_iter_at_position(view::GtkTextView, iter::Mutable{GtkTextIter}, trailing, x::Int32, y::Int32) = ccall(
    (:gtk_text_view_get_iter_at_position, libgtk), Cvoid,
    (Ptr{GObject}, Ptr{GtkTextIter}, Ptr{Cint}, Cint, Cint),
    view, iter, trailing, x, y
)

function cursor_locations(view::GtkTextView)
    weak = Gtk.mutable(GdkRectangle)
    strong = Gtk.mutable(GdkRectangle)
    buffer = view.buffer[GtkTextBuffer]
    iter = mutable(GtkTextIter(buffer, buffer.cursor_position[Int])) 

    ccall(
        (:gtk_text_view_get_cursor_locations, libgtk), Cvoid,
        (Ptr{GObject}, Ptr{GtkTextIter}, Ptr{Gtk.GdkRectangle}, Ptr{GdkRectangle}),
        view, iter, strong, weak
    )
    return (iter, strong[], weak[])
end

####  GtkTextMark  ####

visible(w::GtkTextMark) =
    Bool(ccall((:gtk_text_mark_get_visible, libgtk), Cint, (Ptr{GObject},), w))
visible(w::GtkTextMark, state::Bool) =
    ccall((:gtk_text_mark_set_visible, libgtk), Nothing, (Ptr{GObject}, Cint), w, state)
show(w::GtkTextMark) = visible(w, true)
