@testset "eventloop" begin
    # make sure all shown widgets have been destroyed, otherwise the eventloop
    # won't stop automatically
    @test length(Gtk.shown_widgets) == 0

    @testset "control" begin
        before = Gtk.auto_idle[]

        @testset "basics" begin
            Gtk.auto_idle[] = true
            Gtk.enable_eventloop(false)
            @test !Gtk.is_eventloop_running()
            Gtk.enable_eventloop(true)
            @test Gtk.is_eventloop_running()
            Gtk.enable_eventloop(false)
            @test !Gtk.is_eventloop_running()
        end

        @testset "pause_eventloop" begin

            @testset "pauses then restarts" begin
                Gtk.enable_eventloop(true)
                @test Gtk.is_eventloop_running()
                Gtk.pause_eventloop() do
                    @test !Gtk.is_eventloop_running()
                end
                @test Gtk.is_eventloop_running()
            end

            @testset "doesn't restart a stopping eventloop" begin
                Gtk.enable_eventloop(false)
                c = GtkCanvas()
                win = GtkWindow(c)
                showall(win)
                sleep(1)
                @test Gtk.is_eventloop_running()
                destroy(win)
                # the eventloop is likely still stopping here
                Gtk.pause_eventloop() do
                    @test !Gtk.is_eventloop_running()
                end
                @test !Gtk.is_eventloop_running()
            end

            @testset "observes auto_idle = false" begin
                Gtk.auto_idle[] = false
                Gtk.enable_eventloop(true)
                Gtk.pause_eventloop() do
                    @test Gtk.is_eventloop_running()
                end
                @test Gtk.is_eventloop_running()
            end

            @testset "observes force = true" begin
                Gtk.auto_idle[] = false
                Gtk.enable_eventloop(true)
                Gtk.pause_eventloop(force = true) do
                    @test !Gtk.is_eventloop_running()
                end
                @test Gtk.is_eventloop_running()
            end

            # Note: Test disabled because this isn't true. The event loop takes some time to stop.
            # TODO: Figure out how to wait in the handle_auto_idle callbacks

            # @testset "eventloop is stopped immediately after a destroy(win) completes" begin
            #     c = GtkCanvas()
            #     win = GtkWindow(c)
            #     showall(win)
            #     @test Gtk.is_eventloop_running()
            #     destroy(win)
            #     @test !Gtk.is_eventloop_running()
            # end
        end

        Gtk.auto_idle[] = before
    end

    @testset "Multithreading" begin
        @testset "no blocking when eventloop is paused" begin
            Gtk.auto_idle[] = true
            Threads.nthreads() < 1 && @warn "Threads.nthreads() == 1. Multithread blocking tests are not effective"

            function multifoo()
                Threads.@threads for _ in 1:Threads.nthreads()
                    sleep(0.1)
                end
            end

            Gtk.enable_eventloop(false)
            win = Gtk.Window("Multithread test", 400, 300)
            showall(win)
            @test Gtk.is_eventloop_running()
            for i in 1:10
                Gtk.pause_eventloop() do
                    @test !Gtk.is_eventloop_running()
                    t = @elapsed multifoo() # should take slightly more than 0.1 seconds
                    @test t < 4.5 # given the Glib uv_prepare timeout is 5000 ms
                end
            end
            @test Gtk.is_eventloop_running()
            destroy(win)
        end
    end
end