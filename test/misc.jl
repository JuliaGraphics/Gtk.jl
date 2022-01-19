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

end
