include("../src/Interfaces.jl")
using .Interfaces
using Base.Test

abstract IFACE1 <: Interface
@implements Int <: IFACE1
abstract IFACE2 <: Interface
@implements Real <: IFACE2
abstract IFACE3 <: Interface
@implements Int <: IFACE3

@multi testfn(x::IFACE1) = "hello"
@multi testfn(x::IFACE2) = "world"

@test testfn(1) == "hello"
@test testfn(1.0) == "world"

@multi testfn(x::IFACE3) = "burn it down"
@test_throws testfn2(1)
