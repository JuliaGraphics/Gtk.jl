using BinDeps

@BinDeps.setup

group = library_group("gtk")

glib = library_dependency("glib", aliases = ["libglib-2.0", "libglib-2.0-0"], group = group)
gobject = library_dependency("gobject", aliases = ["libgobject-2.0", "libgobject-2.0-0"], group = group)
gtk = library_dependency("gtk", aliases = ["libgtk-3", "libgtk-3-0"], group = group)
gdk = library_dependency("gdk", aliases = ["libgdk-3", "libgdk-3-0"], group = group)
# for gtk2 use these two lines instead of the previous two
#gtk = library_dependency("gtk", aliases = ["libgtk-quartz-2.0", "libgtk-win32-2.0-0", "libgtk-x11-2.0"], group = group)
#gdk = library_dependency("gdk", aliases = ["libgdk-quartz-2.0", "libgdk-win32-2.0-0", "libgdk-x11-2.0"], group = group)
gdk_pixbuf = library_dependency("gdk_pixbuf", aliases = ["libgdk_pixbuf-2.0", "libgdk_pixbuf-2.0-0"], group = group)
gio = library_dependency("gio", aliases = ["libgio-2.0", "libgio-2.0-0"], group = group)

deps = [glib, gobject, gtk, gdk, gdk_pixbuf, gio]

if Sys.islinux()
    provides(AptGet, "libgtk-3-dev", deps)
    provides(Yum, "gtk3", deps)
end

if Sys.iswindows()
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
    libdir = joinpath(dirname(pathof(WinRPM)), "..", "deps","usr","$(Sys.ARCH)-w64-mingw32","sys-root","mingw","bin")
    run(`$libdir/glib-compile-schemas $libdir/../share/glib-2.0/schemas`)
end

if Sys.isapple()
    using Homebrew
    provides(Homebrew.HB, "gtk+3", [gtk, gdk, gobject], os = :Darwin, onload =
        """
        function __init__bindeps__()
            if "XDG_DATA_DIRS" in keys(ENV)
                ENV["XDG_DATA_DIRS"] *= ":" * joinpath("$(Homebrew.brew_prefix)", "share")
            else
                ENV["XDG_DATA_DIRS"] = joinpath("$(Homebrew.brew_prefix)", "share")
            end
        ENV["GDK_PIXBUF_MODULEDIR"] = joinpath("$(Homebrew.brew_prefix)", "lib/gdk-pixbuf-2.0/2.10.0/loaders")
        ENV["GDK_PIXBUF_MODULE_FILE"] = joinpath("$(Homebrew.brew_prefix)", "lib/gdk-pixbuf-2.0/2.10.0/loaders.cache")
        run(`$(joinpath("$(Homebrew.brew_prefix)", "bin/gdk-pixbuf-query-loaders")) --update-cache`)
        end
        """)
    provides(Homebrew.HB, "glib", [glib, gio], os = :Darwin)
    provides(Homebrew.HB, "gdk-pixbuf", gdk_pixbuf, os = :Darwin)
    Homebrew.add("adwaita-icon-theme")
end

@BinDeps.install Dict([
    (:glib, :libglib),
    (:gobject, :libgobject),
    (:gtk, :libgtk),
    (:gdk, :libgdk),
    (:gdk_pixbuf, :libgdk_pixbuf),
    (:gio, :libgio),
])
