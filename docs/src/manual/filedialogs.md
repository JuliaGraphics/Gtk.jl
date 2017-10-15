# File Dialogs

Gtk.jl supports the `GtkFileChooserDialog`.
It also provides two functions, `open_dialog` and `save_dialog`, making this functionality easier to use.
The syntax of these two functions are as follows:

```julia
open_dialog(title, GtkNullContainer(), String[])
save_dialog(title, GtkNullContainer(), String[])
```

If you are using these functions in the context of a GUI, you should set the parent to be the top-level window.
Otherwise, for standalone usage in scripts, do not set the parent.

The main flexibility comes from the filters, which can be specified as a Tuple or Vector.
A filter can be specified as a string, in which case it specifies a globbing pattern, for example `"*.png"`.
You can specify multiple match types for a single filter by separating the patterns with a comma, for example `"*.png,*.jpg"`.
You can alternatively specify MIME types, or if no specification is provided it defaults to types supported by `GdkPixbuf`.
The generic specification of a filter is
```julia
FileFilter(; name = nothing, pattern = "", mimetype = "")
```

If on the other hand you want to choose a folder instead of a file, set the `action` to `GtkFileChooserAction.SELECT_FOLDER`:
```julia
dir = open_dialog("Select Dataset Folder", action=GtkFileChooserAction.SELECT_FOLDER)
if isdir(dir)
   # do something with dir
end
```

Here are some examples:
```julia
open_dialog("Pick a file")
open_dialog("Pick some files", select_multiple=true)
open_dialog("Pick a file", Null(), ("*.jl",))
open_dialog("Pick some text files", GtkNullContainer(), ("*.txt,*.csv",), select_multiple=true)
open_dialog("Pick a file", Null(), (FileFilter(mimetype="text/csv"),))
open_dialog("Pick an image file", GtkNullContainer(), ("*.png", "*.jpg", FileFilter("*.png,*.jpg", name="All supported formats")))
open_dialog("Pick an image file", GtkNullContainer(), (FileFilter(name="Supported image formats"),))

save_dialog("Save as...", Null(), (FileFilter("*.png,*.jpg", name="All supported formats"), "*.png", "*.jpg"))
```
