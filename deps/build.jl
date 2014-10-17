using BinDeps

@BinDeps.setup

group = library_group("gtk")

deps = [
    glib = library_dependency("glib", aliases = ["libglib-2.0", "libglib-2.0-0"], group = group)
    gobject = library_dependency("gobject", aliases = ["libgobject-2.0", "libgobject-2.0-0"], group = group)
    gtk = library_dependency("gtk", aliases = ["libgtk-3", "libgtk-3-0"], group = group)
    gdk = library_dependency("gdk", aliases = ["libgdk-3", "libgdk-3-0"], group = group)
    gdk_pixbuf = library_dependency("gdk_pixbuf", aliases = ["libgdk_pixbuf-2.0", "libgdk_pixbuf-2.0-0"], group = group)
    gio = library_dependency("gio", aliases = ["libgio-2.0", "libgio-2.0-0"], group = group)
]

@linux_only begin
    provides(AptGet, "libgtk-3-0", deps)
    provides(Yum, "gtk3", deps)
end

@windows_only begin
    using WinRPM
    provides(WinRPM.RPM,"libgtk-3-0", [gtk,gdk,gdk_pixbuf,glib,gio], os = :Windows)
    provides(WinRPM.RPM,"libgobject-2_0-0", [gobject], os = :Windows)

    # install some other quasi-required packages
    WinRPM.install([
        "glib2-tools","gtk3-tools","gtk2-tools",
        "pango-tools","gdk-pixbuf-query-loaders",
        "hicolor-icon-theme","tango-icon-theme",
        "gnome-icon-theme","gnome-icon-theme-extras",
        "gnome-icon-theme-symbolic",];
        yes = !isinteractive()) # don't prompt for unattended installs

    # compile the schemas
    libdir = Pkg.dir("WinRPM","deps","usr","$(Sys.ARCH)-w64-mingw32","sys-root","mingw","bin")
    run(`$libdir/glib-compile-schemas $libdir/../share/glib-2.0/schemas`)
end

@osx_only begin
    using Homebrew
    provides(Homebrew.HB, "gtk+3", [gtk, gdk, gobject], os = :Darwin, onload =
        """
        function __init__bindeps__()
            if "XDG_DATA_DIRS" in ENV
                ENV["XDG_DATA_DIRS"] *= ":" * joinpath("$(Homebrew.brew_prefix)", "share")
            else
                ENV["XDG_DATA_DIRS"] = joinpath("$(Homebrew.brew_prefix)", "share")
            end
        end
        """)
    provides(Homebrew.HB, "glib", [glib, gio], os = :Darwin)
    provides(Homebrew.HB, "gdk-pixbuf", gdk_pixbuf, os = :Darwin)
end

@BinDeps.install [
    :glib => :libglib,
    :gobject => :libgobject,
    :gtk => :libgtk,
    :gdk => :libgdk,
    :gdk_pixbuf => :libgdk_pixbuf,
    :gio => :libgio,
]
