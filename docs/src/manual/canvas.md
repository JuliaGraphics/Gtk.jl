# Drawing on Canvas & Animation

Generic drawing is done on a `Canvas`. You control what appears on this canvas by defining a `draw` function:

```julia
using Gtk, Graphics
c = @GtkCanvas()
win = GtkWindow(c, "Canvas")
@guarded draw(c) do widget
    ctx = getgc(c)
    h = height(c)
    w = width(c)
    # Paint red rectangle
    rectangle(ctx, 0, 0, w, h/2)
    set_source_rgb(ctx, 1, 0, 0)
    fill(ctx)
    # Paint blue rectangle
    rectangle(ctx, 0, 3h/4, w, h/4)
    set_source_rgb(ctx, 0, 0, 1)
    fill(ctx)
end
show(c)
```
This `draw` function will get called each time the window gets resized or otherwise needs to refresh its display.

![canvas](../doc/figures/canvas.png)

Errors in the `draw` function can corrupt Gtk's internal state; if
this happens, you have to quit julia and start a fresh session. To
avoid this problem, the `@guarded` macro wraps your code in a
`try/catch` block and prevents the corruption. It is especially useful
when initially writing and debugging code. See [further
discussion](../doc/more_signals.md) about when `@guarded` is relevant.

`Canvas`es have a field called `mouse` that allows you to
easily write callbacks for mouse events:

```julia
c.mouse.button1press = @guarded (widget, event) -> begin
    ctx = getgc(widget)
    set_source_rgb(ctx, 0, 1, 0)
    arc(ctx, event.x, event.y, 5, 0, 2pi)
    stroke(ctx)
    reveal(widget)
end
```

This will draw a green circle on the canvas at every mouse click.
Resizing the window will make them go away; they were drawn on the
canvas, but they weren't added to the `draw` function.

Note the use of the `@guarded` macro here, too.

Finally, we can put this all together to make an interactive animation.

```julia
using Gtk, Graphics

# Physics
position = 100rand(3)
velocity = 100randn(3)
t = time()
function update_ball!(bounds)
    global t, bounce_time
    dt = time()-t
    t += dt
    for i in eachindex(position, velocity, bounds)
        position[i] += velocity[i]*dt
        lo, hi = bounds[i]
        position[i] = mod(position[i]-lo, 2(hi-lo))+lo
        if position[i] > hi
            position[i] = 2hi - position[i]
            velocity[i] = -velocity[i]
        end
    end
end

# Initialization
c = @GtkCanvas()
win = GtkWindow(c, "3D-Animation")

# Rendering
@guarded draw(c) do widget
    ctx = getgc(c)
    h = height(c)
    w = width(c)

    # Paint background
    rectangle(ctx, 0, 0, w, h)
    set_source_rgb(ctx, 0, 0, 0)
    fill(ctx)
    set_source_rgb(ctx, .4, .4, .4) # color and path can appear in either order
    rectangle(ctx, w/4, h/4, w/2, h/2)
    fill(ctx)

    # Compute physics
    r = 20
    depth = hypot(w,h)/sqrt(2)
    update_ball!([(r, w-r), (r, h-r), (0, depth-r)])

    # Paint ball
    set_source_rgb(ctx, .6, .5, 1)
    x,y,z = position
    z = z/depth + 1
    arc(ctx, (x-w/2)/z+w/2, (y-h/2)/z+h/2, r/z, 0, 2pi)
    fill(ctx)
end

# Event handling
c.mouse.button1press = @guarded (widget, event) -> begin
    # Move toward the mouse position
    velocity[1] = event.x - position[1]
    velocity[2] = event.y - position[2]
    velocity[3] = 0       - position[3]
end

running = Ref(true)
signal_connect(win, :destroy) do widget
    running[] = false
end

# Initialization part 2
show(c)
while !c.is_sized
    sleep(.0001) # Wait for the canvas to initialize before we can call getgc(c)
end

# Main loop
while running[]
    c.draw(true) # Manually repaint the scene (this does not automatically clear the background)
    reveal(c) # Tell Gtk that the canvas needs to be re-drawn
    sleep(.0001) # Hand control back to Gtk to display the redrawn window and handle events.
end
```
