# Installation troubleshooting

Installation should be automatic on all platforms supported by Julia.
However, in case of trouble, these notes may help you diagnose or fix the problem.

Prior to using this library, you must install a semi-recent version of `libgtk` on your computer.
While this interface currently defaults to using `Gtk+-3`, it can be configured by editing `Gtk/deps/ext.jl` and changing the integer valued `gtk_version` variable to `2`.

### Windows

The necessary libraries will be downloaded and installed automatically when you run `Pkg.add("Gtk")`.


In case you run into some problem with the automatic installation, you can install manually 
using `WinRPM.jl`:

     Pkg.add("WinRPM")
     using WinRPM
     WinRPM.install(["gtk2","gtk3",
          "hicolor-icon-theme",
          "tango-icon-theme",
          "glib2-tools",
          "glib2-devel",
          "gnome-icon-theme",
          "gnome-icon-theme-extras",
          "gnome-icon-theme-symbolic",
          "gtk3-devel",
          "gtk2-devel",
          "gtk3-tools",
          "gtk2-tools",
          "pango-tools",
          "gdk-pixbuf-query-loaders",
          "gtk2-lang",
          "gtk3-lang"])
     RPMbindir = Pkg.dir("WinRPM","deps","usr","$(Sys.ARCH)-w64-mingw32","sys-root","mingw","bin")
     ENV["PATH"]=ENV["PATH"]*";"*RPMbindir

You may need to repeat the last two steps every time you restart julia, or put these two lines in your `$HOME/.juliarc.jl` file

### OS X

I use MacPorts:

1. `port install gtk2 +quartz gtk3 +quartz` (this may require that you first remove Cairo and Pango via `sudo port deactivate active` for example, I like to put this in my `/opt/local/etc/macports/variants.conf` file as `+quartz` before installing anything, to minimize conflicts and maximize usage of the native Quartz)
2. `push!(DL_LOAD_PATH,"/opt/local/lib")` You will need to repeat this step every time you restart julia, or put this line in your `~/.juliarc.jl` file.

If you want to use Homebrew, the built-in formula is deficient (it does not support the Quartz backend). See [Homebrew#27](https://github.com/JuliaLang/Homebrew.jl/issues/27) for possible eventual workarounds.

If you see a warning such as `(<unknown>:950): Gtk-WARNING **: Error loading theme icon 'go-next' for stock`, then chances are that you have to install the icon theme manually using `brew install gnome-icon-theme` (or `Homebrew.add("gnome-icon-theme")`).

### Linux

Try any of the following lines until something is successful:

     aptitude install libgtk2.0-0 libgtk-3-0
     apt-get install libgtk2.0-0 libgtk-3-0
     yum install gtk2 gtk3
     pkg install gtk2 gtk3

On some distributions you can also install a `devhelp` package to have a local copy of the Gtk documentation.
