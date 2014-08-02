using Gtk, Gtk.ShortNames, Gtk.GConstants

app = @GtkApplication("org.julia.example", GApplicationFlags.FLAGS_NONE)

const builderstr =  
    """<interface>
       <menu id="menubar">
          <submenu>
          <attribute name="label">File</attribute>
             <item>
                <attribute name="label">Quit</attribute>
                <attribute name="action">app.quit</attribute>
             </item>
          </submenu>
          <submenu>
          <attribute name="label">Help</attribute>
        </submenu> 
      </menu>
      <menu id="appmenu">
        <section>
          <item>
            <attribute name="label">New</attribute>
            <attribute name="action">app.new</attribute>
          </item>
          <item>
            <attribute name="label">Quit</attribute>
            <attribute name="action">app.quit</attribute>
          </item>
        </section>
      </menu>
     </interface>"""

signal_connect(app,"activate") do a, args...
  w = Gtk.@GtkApplicationWindow(a)
  G_.title(w, "GtkApplication Test App" )
  G_.default_size(w, 400,400)
  builder = @GtkBuilder(buffer=builderstr)

  menubar = G_.object(builder,"menubar")
  appmenu = G_.object(builder,"appmenu")

  Gtk.set_menubar(app, menubar)
  Gtk.set_app_menu(app, appmenu)
  
  #quitIt = G_.object(builder, "menu_item_quit")
  #signal_connect(quitIt, :activate) do widget
  #   exit()
  #end

  showall(w)
end

Gtk.run(app) # enters main loop

