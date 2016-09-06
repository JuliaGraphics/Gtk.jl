module GtkTestModule

if VERSION >= v"0.5.0-dev+7720"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

include("gui.jl")
include("glib.jl")
include("misc.jl")

end
