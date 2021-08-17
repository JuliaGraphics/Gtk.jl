# Gtk.jl

*Julia Bindings for Gtk.*

## Introduction

Gtk.jl is a is a Julia package providing bindings for the Gtk library: [https://www.gtk.org/](https://www.gtk.org/)

Complete Gtk documentation is available at [https://developer.gnome.org/gtk/stable](https://developer.gnome.org/gtk/stable)

## Installation

Install Gtk.jl within Julia using

```julia
using Pkg
Pkg.add("Gtk")
```

!!! tip
    On some platforms, you may see messages like

    > Gtk-Message: 20:15:48.288: Failed to load module "canberra-gtk-module"

    These are harmless. If you want to suppress them, on Unix platforms you can add something like

    ```bash
    export GTK_PATH=$GTK_PATH:/usr/lib/x86_64-linux-gnu/gtk-3.0
    ```

    to your `.bashrc` file. (You may need to customize the path for your system; it should have a `modules` directory containing `libcanberra`.)

## Precompilation

Gtk is precompilable by normal mechanisms. Julia 1.6 or higher is recommended as having much shorter load times than earlier Julia versions.

On very old Julia versions, you can use [PackageCompiler](https://github.com/JuliaLang/PackageCompiler.jl). Be aware that this has [downsides](https://julialang.github.io/PackageCompiler.jl/dev/sysimages/#Drawbacks-to-custom-sysimages-1) and should not be necessary on modern versions of Julia.

## Usage

  * See [Getting Started](@ref) for an introduction to using the package

## Attribution

Gtk logo is made by Andreas Nilsson [[GFDL](https://www.gnu.org/copyleft/fdl.html) or [CC-BY-SA-3.0](https://creativecommons.org/licenses/by-sa/3.0/)], via Wikimedia Commons
