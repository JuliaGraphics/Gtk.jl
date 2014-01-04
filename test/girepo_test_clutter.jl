using GI
@gimport Clutter init, Actor
Clutter.init(0, C_NULL)
actor = Clutter.Actor_new()
display(actor)
@assert isa(actor,GI.GObject)
@assert isa(actor,Actor)

