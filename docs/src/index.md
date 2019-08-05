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
