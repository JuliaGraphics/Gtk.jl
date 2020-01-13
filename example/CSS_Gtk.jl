using Gtk.ShortNames
style_file = joinpath(dirname(@__FILE__), "style_test2.css")
provider = CssProviderLeaf(filename = style_file)

b1 = Button("Blue")
set_gtk_property!(b1, :name, "b1")

b2 = Button("Red")
set_gtk_property!(b2, :name, "b2")

g = Grid()
set_gtk_property!(g, :column_homogeneous, true)
set_gtk_property!(g, :raw_homogeneous, true)

g[1, 1] = b1
g[1, 2] = b2
w = Window(g)

Gtk.showall(w)

sc = Gtk.GAccessor.style_context(b1)
push!(sc, StyleProvider(provider), 600)

sc = Gtk.GAccessor.style_context(b2)
push!(sc, StyleProvider(provider), 600)
