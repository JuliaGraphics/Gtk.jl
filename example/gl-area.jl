using Gtk
using Gtk.GConstants

function resize_event(widget::Gtk.GtkGLArea, width::Int32, height::Int32)
	println("resize_event: ", "w=", width, " h=", height)
end

function scroll_event(widget::Gtk.GtkGLArea, event::Gtk.GdkEventScroll)
	println("scroll_event")
	return true
end

function motion_notify_event(widget::Gtk.GtkGLArea, event::Gtk.GdkEventMotion)
	println("motion_notify_event")
	return true
end

function button_press_event(widget::Gtk.GtkGLArea, event::Gtk.GdkEventButton)
	println("button_press_event")
	return true
end

function button_release_event(widget::Gtk.GtkGLArea, event::Gtk.GdkEventButton)
	println("button_release_event")
	return true
end

area = Gtk.GLArea()
add_events(area,
			GConstants.GdkEventMask.SCROLL |
			GConstants.GdkEventMask.BUTTON_PRESS |
			GConstants.GdkEventMask.BUTTON_RELEASE |
			GConstants.GdkEventMask.BUTTON1_MOTION |
			GConstants.GdkEventMask.BUTTON3_MOTION)
signal_connect(resize_event, area, "resize")
signal_connect(scroll_event, area, "scroll-event")
signal_connect(motion_notify_event, area, "motion-notify-event")
signal_connect(button_press_event, area, "button-press-event")
signal_connect(button_release_event, area, "button-release-event")

win = Gtk.Window("Hello Gtk.jl")
push!(win, area)
showall(win)

# https://stackoverflow.com/a/33571506/1500988
signal_connect(win, :destroy) do widget
    Gtk.gtk_quit()
end
Gtk.gtk_main()
