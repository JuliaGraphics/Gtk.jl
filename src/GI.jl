module GI
    using GLib
    using GLib.MutableTypes
    import Base: convert, show, showcompact, length, getindex, setindex!

    # gimport interface (not final in any way)
    export @gimport

    include(joinpath("..","deps","ext.jl"))
    include("girepo.jl")
    include("giimport.jl")
end
