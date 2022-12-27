using Test, Gtk

@testset "text" begin

@testset "GtkTextIter" begin
import Gtk: GtkTextIter, mutable

w = GtkWindow()
b = GtkTextBuffer()
b.text[String] = "test"
v = GtkTextView(b)
@test v[:buffer, GtkTextBuffer] == b

push!(w, v)
showall(w)

its = GtkTextIter(b, 1)
ite = GtkTextIter(b, 2)

@test buffer(its) == b
@test get_gtk_property(its:ite, :text, String) == "t"
@test (its:ite).text[String] == "t"

splice!(b, its:ite)
@test b.text[String] == "est"

insert!(b, GtkTextIter(b, 1), "t")
@test b.text[String] == "test"

it = GtkTextIter(b)
@test get_gtk_property(it, :line) == 0 #lines are 0-based
@test get_gtk_property(it, :starts_line) == true

b.text[String] = "line1\nline2"
it = mutable(GtkTextIter(b))
set_gtk_property!(it, :line, 1)
@test get_gtk_property(it, :line) == 1

it1 = GtkTextIter(b, 1)
it2 = GtkTextIter(b, 1)
@test it1 == it2
it2 = GtkTextIter(b, 2)
@test (it1 == it2) == false
@test it1 < it2
it2 -= 1
@test mutable(it1) == it2

# tags
Gtk.create_tag(b, "big"; size_points = 24)
Gtk.create_tag(b, "red"; foreground = "red")
f(buffer)=Gtk.apply_tag(buffer, "big", GtkTextIter(b, 1), GtkTextIter(b, 6))
user_action(f, b)
Gtk.apply_tag(b, "red", GtkTextIter(b, 1), GtkTextIter(b, 6))
Gtk.remove_tag(b, "red", GtkTextIter(b, 1), GtkTextIter(b, 3))
Gtk.remove_all_tags(b, GtkTextIter(b, 4), GtkTextIter(b, 6))

# getproperty
@test it1.offset[Int] == 0 #Gtk indices are zero based
@test it2.offset[Int] == 0

it1 = mutable(it1)
it1.offset[Int] = 1
@test it1.offset[Int] == 1

mark = create_mark(b, it)
scroll_to(v, mark, 0, true, 0.0, 0.15)
scroll_to(v, it, 0, true, 0.0, 0.15)

# skip
skip(it2, 1, :line)
@test get_gtk_property(it2, :line) == 1
skip(it2, :backward_line)
@test get_gtk_property(it2, :line) == 0
skip(it2, :forward_line)
@test get_gtk_property(it2, :line) == 1
skip(it2, :forward_to_line_end)
it1 = GtkTextIter(b, get_gtk_property(it2, :offset)-1)
(it1:it2).text[String] == "2"

itc = convert(GtkTextIter, it2)
@test get_gtk_property(it2, :offset) == get_gtk_property(itc, :offset)

whats = [:forward_word_end, :backward_word_start, :backward_sentence_start, :forward_sentence_end]
for what in whats
    skip(mutable(it1), what)
end
whats = [:char,:line,:word,:word_cursor_position,:sentence,:visible_word,:visible_cursor_position,:visible_line,:line_end]
for what in whats
    skip(mutable(it1), 0, what)
end

# place_cursor
place_cursor(b, it2)
iter, strong, weak = Gtk.cursor_locations(v)
@test get_gtk_property(it2, :is_cursor_position) == true
@test b.cursor_position[Int] == get_gtk_property(it2, :offset)

# search
(found, its, ite) = Gtk.search(b, "line1", :backward)
@test found == true
@test (its:ite).text[String] == "line1"

place_cursor(b, ite)
(found, its, ite) = Gtk.search(b, "line2", :forward)
@test found == true
@test (its:ite).text[String] == "line2"

# GtkTextRange
range=its:ite
@test_broken eachindex(range) == 1:5
@test range[1] == 'l'
@test range[5] == '2'
@test_throws BoundsError range[10]

# selection
select_range(b, its, ite)
(selected, start, stop) = selection_bounds(b)
@test selected == true
@test (start:stop).text[String] == "line2"

insert!(v, start, "inserted text")

# coords
wx, wy = Gtk.buffer_to_window_coords(v, 3, 2, 2)
bx, by = Gtk.window_to_buffer_coords(v, wx, wy)
@test bx == 3 && by == 2

iter = Gtk.text_iter_at_position(v, 3, 2)

destroy(w)
end

end
