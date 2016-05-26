module TestGuarded

using Gtk

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

@assert foo1(3,5) == 8
@assert bar1(3,5) == nothing
@assert foo2(3,5) == 8
@assert bar2(3,5) == nothing
@assert foo3(3,5) == 8
@assert bar3(3,5) == nothing
@assert bar4(3,5) == unhandled

# Do-block syntax
c = @GtkCanvas()
win = @GtkWindow(c)
showall(win)
@guarded draw(c) do widget
    error("oops")
end
destroy(win)

@assert isa(Gtk.GdkEventKey(), Gtk.GdkEventKey)

end
