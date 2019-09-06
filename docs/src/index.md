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

If this produces errors, please see [installation troubleshooting](doc/installation.md).

## Precompilation

Gtk is precompilable by normal mechanisms. For further reduction of startup time for applications that use Gtk, one can even [build it into your local installation of julia](doc/precompilation.md).

## Usage

  * See [Getting Started](@ref) for an introduction to using the package

## Attribution

Gtk logo is made by Andreas Nilsson [[GFDL](https://www.gnu.org/copyleft/fdl.html) or [CC-BY-SA-3.0](https://creativecommons.org/licenses/by-sa/3.0/)], via Wikimedia Commons

## Common Issues

If you are running Gtk on MacOS Mojave, it's likely that when you try one of te examples, a blank window will render. In order to fix this, you can run the following commands which will downgrade your version of `glib` to the compatible version for `Gtk.jl`

Command to run: 
```julia
using Homebrew
Homebrew.brew(`unlink glib`)
Homebrew.brew(`install https://raw.githubusercontent.com/Homebrew/homebrew-core/b27a055812fe620e0d3dbe67f2a424ed3a846ecf/Formula/glib.rb`)
```
