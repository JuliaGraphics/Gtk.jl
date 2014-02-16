
@Gtype GApplication libgio g_application

run(app::GApplicationI) = 
    ccall((:g_application_run,libgio),Cint, (Ptr{GObject},Cint, Ptr{Ptr{Uint8}}), app, 0, C_NULL)

function register(app::GApplicationI)
   GError() do error_check
      ret = bool(ccall((:g_application_register,libgio), Cint, 
         (Ptr{GObject},Ptr{Void}, Ptr{Ptr{GError}}), app, C_NULL, error_check))
      return ret
   end
end

activate(app::GApplicationI) = 
    ccall((:g_application_activate,libgio),Void, (Ptr{GObject},), app)

#void                g_application_open                  (GApplication *application,
#                                                         GFile **files,
#                                                         gint n_files,
#                                                         const gchar *hint);

#g_application_register() then g_application_activate() or g_application_open(), then exit if g_application_is_remote()