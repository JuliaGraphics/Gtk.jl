using BinDeps

@BinDeps.setup

@linux_only begin
    gtk = library_dependency("libgtk-3")
    provides(AptGet, "libgtk-3-0", gtk)
    provides(Yum, "gtk3", gtk)
end

@BinDeps.install
