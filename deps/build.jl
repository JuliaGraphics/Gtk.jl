using BinDeps

@BinDeps.setup

group = library_group("gtk")

deps = [
    gtk = library_dependency("gtk", aliases = ["libgtk-3", "libgtk-3-0"], group = group)
    glib = library_dependency("glib", aliases = ["libglib-2.0", "libglib-2.0-0"], group = group)
    gdk = library_dependency("gdk", aliases = ["libgdk-3-0", "libgdk-3.0"], group = group)
    gdk_pixbuf = library_dependency("gdk_pixbuf", aliases = ["libgdk_pixbuf-2.0-0", "libgdk_pixbuf-2.0.0"], group = group)
    gio = library_dependency("gio", aliases = ["libgio-2.0-0","libgio-2.0.0"], group = group)
    gobject = library_dependency("gobject", aliases = ["libgobject-2.0.0", "libgobject-2.0-0", "libgobject-2.0", "libgobject-2_0-0"], group = group)
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
    :gtk => :libgtk,
    :gdk => :libgdk,
    :gdk_pixbuf => :libgdk_pixbuf,
    :gio => :libgio,
    :gobject => :libgobject,
    :glib => :libglib
]
