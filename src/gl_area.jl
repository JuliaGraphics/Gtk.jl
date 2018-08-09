if libgtk_version >= v"3.16.0"
	#TODO: gtk_gl_area_get_context
	make_current(w::GtkGLArea) = (ccall((:gtk_gl_area_make_current, libgtk), Nothing, (Ptr{GObject},), w); w)
	queue_render(w::GtkGLArea) = (ccall((:gtk_gl_area_queue_render, libgtk), Nothing, (Ptr{GObject},), w); w)
	attach_buffers(w::GtkGLArea) = (ccall((:gtk_gl_area_attach_buffers, libgtk), Nothing, (Ptr{GObject},), w); w)
	#TODO: gtk_gl_area_set_error
	#TODO: gtk_gl_area_get_error
	alpha(w::GtkGLArea, value::Bool) =
		(ccall((:gtk_gl_area_set_has_alpha, libgtk), Nothing, (Ptr{GObject}, Cint), w, value); w)
	alpha(w::GtkGLArea) =
		Bool(ccall((:gtk_gl_area_set_has_alpha, libgtk), Cint, (Ptr{GObject},), w))
	depth_buffer(w::GtkGLArea, value::Bool) =
		Bool(ccall((:gtk_gl_area_get_has_depth_buffer, libgtk), Cint, (Ptr{GObject},), w))
	stencil_buffer(w::GtkGLArea, value::Bool) =
		(ccall((:gtk_gl_area_set_has_stencil_buffer, libgtk), Nothing, (Ptr{GObject}, Cint), w, value); w)
	stencil_buffer(w::GtkGLArea) =
		Bool(ccall((:gtk_gl_area_get_has_stencil_buffer, libgtk), Cint, (Ptr{GObject},), w))
	auto_render(w::GtkGLArea, value::Bool) =
		(ccall((:gtk_gl_area_set_auto_render, libgtk), Nothing, (Ptr{GObject}, Cint), w, value); w)
	auto_render(w::GtkGLArea) =
		Bool(ccall((:gtk_gl_area_get_auto_render, libgtk), Cint, (Ptr{GObject},), w))


	#TODO: gtk_gl_area_get_required_version
    gl_area_set_required_version(w::GtkGLArea, major::Integer, minor::Integer) =
        ccall((:gtk_gl_area_set_required_version, libgtk), Nothing, (Ptr{GObject}, Cint, Cint), w, major, minor)
else
	#TODO: gtk_gl_area_get_context
	gl_area_func_not_available() = error("GtkGLArea is not available until Gtk3.16.0")
	make_current(w::GtkGLArea) = gl_area_func_not_available()
	queue_render(w::GtkGLArea) = gl_area_func_not_available()
	attach_buffers(w::GtkGLArea) = gl_area_func_not_available()
	#TODO: gtk_gl_area_set_error
	#TODO: gtk_gl_area_get_error
	alpha(w::GtkGLArea, value::Bool) = gl_area_func_not_available()
	depth_buffer(w::GtkGLArea, value::Bool) = gl_area_func_not_available()
	alpha(w::GtkGLArea) = gl_area_func_not_available() = gl_area_func_not_available()
	stencil_buffer(w::GtkGLArea, value::Bool) = gl_area_func_not_available()
	stencil_buffer(w::GtkGLArea) = gl_area_func_not_available()
	auto_render(w::GtkGLArea, value::Bool) = gl_area_func_not_available()
	#TODO: gtk_gl_area_get_required_version

end
