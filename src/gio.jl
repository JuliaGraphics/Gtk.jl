if gtk_version == 3
run(app::GApplication) = GLib.g_sigatom() do
    ccall((:g_application_run,libgio),Cint, (Ptr{GObject},Cint, Ptr{Ptr{UInt8}}), app, 0, C_NULL)
end

function register(app::GApplication)
   GError() do error_check
      ret = bool(ccall((:g_application_register,libgio), Cint,
         (Ptr{GObject},Ptr{Void}, Ptr{Ptr{GError}}), app, C_NULL, error_check))
      return ret
   end
end

activate(app::GApplication) =
    ccall((:g_application_activate,libgio),Void, (Ptr{GObject},), app)
end
