using GI
@gimport Clutter Actor
actor = Clutter.Actor_new()
display(actor)
@assert isa(actor,GI.GObject)
@assert isa(actor,Actor)

