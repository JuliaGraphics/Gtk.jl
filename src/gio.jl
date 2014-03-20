
@Gtype GApplication libgio g_application

run(app::GApplication) = 
    ccall((:g_application_run,libgio),Cint, (Ptr{GObject},Cint, Ptr{Ptr{Uint8}}), app, 0, C_NULL)

function register(app::GApplication)
   GError() do error_check
      ret = bool(ccall((:g_application_register,libgio), Cint, 
         (Ptr{GObject},Ptr{Void}, Ptr{Ptr{GError}}), app, C_NULL, error_check))
      return ret
   end
end

activate(app::GApplication) = 
    ccall((:g_application_activate,libgio),Void, (Ptr{GObject},), app)
