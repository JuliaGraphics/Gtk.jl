include("../src/Interfaces.jl")
using .Interfaces
using Base.Test

@interface IFACE1
@interface IFACE2
@interface IFACE3
@implements Int <: IFACE1
@implements Real <: IFACE2
@implements Int <: IFACE3

@multi testfn(x::IFACE1) = "hello"
@multi testfn(x::IFACE2) = "world"

@test testfn(1) == "hello"
@test testfn(1.0) == "world"

@multi testfn(x::IFACE3) = "burn it down"
@test_throws testfn2(1)
