module GtkTestModule
require(abspath(@__FILE__, "../../src/Gtk.jl"))
include("gui.jl")
include("glib.jl")
end
