using Gtk

@testset "misc" begin

unhandled = convert(Cint, false)

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

@test foo1(3,5) == 8
@test @test_logs (:warn, "Error in @guarded callback") bar1(3,5) == nothing
@test foo2(3,5) == 8
@test @test_logs (:warn, "Error in @guarded callback") bar2(3,5) == nothing
@test foo3(3,5) == 8
@test @test_logs (:warn, "Error in @guarded callback") bar3(3,5) == nothing
@test @test_logs (:warn, "Error in @guarded callback") bar4(3,5) == unhandled

# Do-block syntax
c = GtkCanvas()
win = GtkWindow(c)
showall(win)
@guarded draw(c) do widget
    error("oops")
end
@test !isempty(c.mouse.ids)  # check storage of signal-handler ids (see GtkReactive)
destroy(win)

@test isa(Gtk.GdkEventKey(), Gtk.GdkEventKey)

# Shortcuts

@test Shortcut("c").keyval == keyval("c")
@test Shortcut("c",GConstants.GdkModifierType.CONTROL).state == GConstants.GdkModifierType.CONTROL

win = GtkWindow()
event = Gtk.GdkEventKey(GdkEventType.KEY_PRESS, Gtk.gdk_window(win),
            Int8(0), UInt32(0), UInt32(0), Gtk.GdkKeySyms.Return, UInt32(0),
            convert(Ptr{UInt8},C_NULL), UInt16(13), UInt8(0), UInt32(0) )

@test doing(Shortcut(Gtk.GdkKeySyms.Return),event) == true
@test doing(Shortcut(Gtk.GdkKeySyms.Return,Gtk.PrimaryModifier),event) == false
destroy(win)

end
