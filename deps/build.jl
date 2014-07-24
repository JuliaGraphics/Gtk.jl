using BinDeps

@BinDeps.setup

deps = [
    gtk = library_dependency("gtk", aliases = ["libgtk-3-0"])
    gdk = library_dependency("gdk", aliases = ["libgdk-3-0"])
    gdk_pixbuf = library_dependency("gdk_pixbuf", aliases = ["libgdk_pixbuf-2.0-0"])
    glib = library_dependency("glib", aliases = ["libglib-2.0-0"], os = :Windows)
    gobject = library_dependency("gobject", aliases = ["libgobject-2.0-0", "libgobject-2.0", "libgobject-2_0-0"], os = :Windows)
    gio = library_dependency("gio", aliases = ["libgio-2.0-0"])
]

@linux_only begin
    provides(AptGet, "libgtk-3-0", gtk)
    provides(Yum, "gtk3", gtk)
end

@windows_only begin
    using WinRPM
    provides(WinRPM.RPM,"gtk3", [gtk,gdk,gdk_pixbuf,glib,gio], os = :Windows)
    provides(WinRPM.RPM,"libgobject-2_0-0", [gobject], os = :Windows)
end

@BinDeps.install @windows_only [
    :gtk => :libgtk,
    :gdk => :libgdk,
    :gdk_pixbuf => :libgdk_pixbuf,
    :gio => :libgio,
    :gobject => :libgobject,
    :glib => :libglib
]
