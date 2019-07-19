using Gtk

@testset "list" begin

@testset "v3 populate with push!" begin
    if Gtk.libgtk_version >= v"3"
        cbstr = GtkComboBoxText()
        push!(cbstr, "1", "abc")
        push!(cbstr, "2", "xyz")

        set_gtk_property!(cbstr, :active, 0)
        @test get_gtk_property(cbstr, "active-id", String) == "1"

        set_gtk_property!(cbstr, :active, 1)
        @test get_gtk_property(cbstr, "active-id", String) == "2"

        cbsym = GtkComboBoxText()
        push!(cbsym, :a, "abc")
        push!(cbsym, :b, "xyz")

        set_gtk_property!(cbsym, :active, 0)
        @test get_gtk_property(cbsym, "active-id", String) == "a"

        set_gtk_property!(cbsym, :active, 1)
        @test get_gtk_property(cbsym, "active-id", String) == "b"
    end
end

@testset "v3 populate with pushfirst!" begin
    if Gtk.libgtk_version >= v"3"
        cbstr = GtkComboBoxText()
        pushfirst!(cbstr, "1", "abc")
        pushfirst!(cbstr, "2", "xyz")

        set_gtk_property!(cbstr, :active, 0)
        @test get_gtk_property(cbstr, "active-id", String) == "2"

        set_gtk_property!(cbstr, :active, 1)
        @test get_gtk_property(cbstr, "active-id", String) == "1"

        cbsym = GtkComboBoxText()
        pushfirst!(cbsym, :a, "abc")
        pushfirst!(cbsym, :b, "xyz")

        set_gtk_property!(cbsym, :active, 0)
        @test get_gtk_property(cbsym, "active-id", String) == "b"

        set_gtk_property!(cbsym, :active, 1)
        @test get_gtk_property(cbsym, "active-id", String) == "a"
    end
end

@testset "v3 populate with insert!" begin
    if Gtk.libgtk_version >= v"3"
        cbstr = GtkComboBoxText()
        push!(cbstr, "1", "abc")
        push!(cbstr, "3", "mno")
        insert!(cbstr, 2, "2", "xyz")

        set_gtk_property!(cbstr, :active, 0)
        @test get_gtk_property(cbstr, "active-id", String) == "1"

        set_gtk_property!(cbstr, :active, 1)
        @test get_gtk_property(cbstr, "active-id", String) == "2"

        set_gtk_property!(cbstr, :active, 2)
        @test get_gtk_property(cbstr, "active-id", String) == "3"

        cbsym = GtkComboBoxText()
        push!(cbsym, :a, "abc")
        push!(cbsym, :c, "mno")
        insert!(cbsym, 2, :b, "xyz")

        set_gtk_property!(cbsym, :active, 0)
        @test get_gtk_property(cbsym, "active-id", String) == "a"

        set_gtk_property!(cbsym, :active, 1)
        @test get_gtk_property(cbsym, "active-id", String) == "b"

        set_gtk_property!(cbsym, :active, 2)
        @test get_gtk_property(cbsym, "active-id", String) == "c"
    end
end


end
