using Gtk.GLib
using Gtk
using Gtk.ShortNames
using Test

@testset "glist" begin

@testset "pointers" begin

w1 = Window("Window", 400, 300)
nb = Notebook()
w2 = push!(Window("Notebook"),nb)
l = ccall((:gtk_container_get_children,Gtk.libgtk),Ptr{Gtk._GList{Gtk.GtkWidget}},(Ptr{Gtk.GObject},),w2)

@test eltype(l)==Gtk.GtkWidget

@test !isempty(l)
@test length(l)==1
@test l[1]==nb

for item in l
    @test item==nb
end

destroy(w1)
destroy(w2)

end

@testset "string" begin

g = GList(String)

@test ndims(g)==1

@test isempty(g)

for i=1:10
    push!(g,string(i))
end

@test !isempty(g)

@test g[1]==string(1)
@test g[2]==string(2)

@test length(g)==10
@test g[end]==string(10)

for (i,item) = enumerate(g)
    @test string(i)==item
end

g2=copy(g)

for (i,item) = enumerate(g2)
    @test string(i)==item
end

@test popfirst!(g2)==string(1)
@test length(g2)==9
@test pop!(g2)==string(10)
@test length(g2)==8

@test length(g)==10

insert!(g,8,string(25))
@test length(g)==11
@test g[8]==string(25)
@test g[9]==string(8)

pushfirst!(g,string(24))
@test length(g)==12
@test g[1]==string(24)
@test g[9]==string(25)

g[8]="hello"
@test g[8]=="hello"
@test g[9]==string(25)

reverse!(g)
@test g[end]==string(24)

g[2]="test"
@test g[2]=="test"

g3=copy(g)

append!(g2,g3)
@test length(g2)==20

empty!(g)
@test isempty(g)

# repeat above for GSList
g = GSList(String)

@test ndims(g)==1

@test isempty(g)

for i=1:10
    push!(g,string(i))
end

@test !isempty(g)

@test g[1]==string(1)
@test g[2]==string(2)

@test length(g)==10
@test g[end]==string(10)

for (i,item) = enumerate(g)
    @test string(i)==item
end

g2=copy(g)

for (i,item) = enumerate(g2)
    @test string(i)==item
end

@test popfirst!(g2)==string(1)
@test length(g2)==9
@test pop!(g2)==string(10)
@test length(g2)==8

@test length(g)==10

insert!(g,8,string(25))
@test length(g)==11
@test g[8]==string(25)
@test g[9]==string(8)

pushfirst!(g,string(24))
@test length(g)==12
@test g[1]==string(24)
@test g[9]==string(25)

g[8]="hello"
@test g[8]=="hello"
@test g[9]==string(25)

reverse!(g)
@test g[end]==string(24)

g[2]="test"
@test g[2]=="test"

g3=copy(g)

append!(g2,g3)
@test length(g2)==20

empty!(g)
@test isempty(g)

end

@testset "numbers" begin

g = GList(Int64)

@test ndims(g)==1

@test isempty(g)

for i=1:10
    push!(g,i)
end

@test !isempty(g)

@test g[1]==1
@test g[2]==2

@test length(g)==10
@test g[end]==10

for (i,item) = enumerate(g)
    @test i==item
end

g2=copy(g)

for (i,item) = enumerate(g2)
    @test i==item
end

empty!(g)
@test isempty(g)

# repeat above for SList
g = GSList(Int64)

@test ndims(g)==1

@test isempty(g)

for i=1:10
    push!(g,i)
end

@test !isempty(g)

@test g[1]==1
@test g[2]==2

@test length(g)==10
@test g[end]==10

for (i,item) = enumerate(g)
    @test i==item
end

g2=copy(g)

for (i,item) = enumerate(g2)
    @test i==item
end

empty!(g)
@test isempty(g)

end

GC.gc()

end
