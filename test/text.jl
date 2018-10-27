using Test, Gtk

@testset "text" begin

@testset "GtkTextIter" begin
import Gtk: GtkTextIter, mutable

w = GtkWindow()
b = GtkTextBuffer()
b.text[String] = "test"
v = GtkTextView(b)

push!(w,v)
showall(w)

its = GtkTextIter(b,1)
ite = GtkTextIter(b,2)

@test buffer(its) == b
@test get_gtk_property(its:ite,:text,String) == "t"
@test (its:ite).text[String] == "t"

splice!(b,its:ite)
@test b.text[String] == "est" 

insert!(b,GtkTextIter(b,1),"t")
@test b.text[String] == "test"

it = GtkTextIter(b)
@test get_gtk_property(it,:line) == 0
@test get_gtk_property(it,:starts_line) == true

b.text[String] = "line1\nline2"
it = mutable(GtkTextIter(b))
set_gtk_property!(it,:line,1)
@test get_gtk_property(it,:line) == 1

it1 = GtkTextIter(b,1)
it2 = GtkTextIter(b,1)
@test it1 == it2
it2 = GtkTextIter(b,2)
@test (it1 == it2) == false
@test it1 < it2
it2 -= 1
@test mutable(it1) == it2
skip(it2,1,:line)
@test get_gtk_property(it,:line) == 1

destroy(w)
end

end