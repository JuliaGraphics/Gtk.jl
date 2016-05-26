using Gtk

@testset "misc" begin

const unhandled = convert(Cint, false)

foo1 = @guarded (x,y) -> x+y
bar1 = @guarded (x,y) -> x+y+k
@guarded foo2(x,y) = x+y
@guarded bar2(x,y) = x+y+k
@guarded function foo3(x,y)
    x+y
end
@guarded function bar3(x,y)
    x+y+k
end
@guarded unhandled function bar4(x,y)
    x+y+k
end

print_with_color(:green, """
The following messages:
   WARNING: Error in @guarded callback
are expected and a sign of normal operation.
""")

@test foo1(3,5) == 8
@test bar1(3,5) == nothing
@test foo2(3,5) == 8
@test bar2(3,5) == nothing
@test foo3(3,5) == 8
@test bar3(3,5) == nothing
@test bar4(3,5) == unhandled

# Do-block syntax
c = GtkCanvas()
win = GtkWindow(c)
showall(win)
@guarded draw(c) do widget
    error("oops")
end
destroy(win)

@test isa(Gtk.GdkEventKey(), Gtk.GdkEventKey)

end
