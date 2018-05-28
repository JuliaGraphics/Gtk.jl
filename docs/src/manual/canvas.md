# Drawing on Canvas

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

![canvas](doc/figures/canvas.png)

See Julia's standard-library documentation for more information on graphics.

Errors in the `draw` function can corrupt Gtk's internal state; if
this happens, you have to quit julia and start a fresh session. To
avoid this problem, the `@guarded` macro wraps your code in a
`try/catch` block and prevents the corruption. It is especially useful
when initially writing and debugging code. See [further
discussion](doc/more_signals.md) about when `@guarded` is relevant.

Finally, `Canvas`es have a field called `mouse` that allows you to
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

