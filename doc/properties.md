# Gtk object properties

Any child object inherits the properties of its parent(s).
Not all of these are implemented as objects in this package, but you can still access the properties.

*   [Widgets](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget.properties)
    *   [Containers](https://developer.gnome.org/gtk3/stable/GtkContainer.html#GtkContainer.properties)
        *   Multi-object containers:
            *   [Box](https://developer.gnome.org/gtk3/stable/GtkBox.html#GtkBox.properties), a vertical or horizontal container
            *   [Grid](https://developer.gnome.org/gtk3/stable/GtkGrid.html#GtkGrid.properties) (Gtk3 only), a 2d container
            *   [Table](https://developer.gnome.org/gtk3/stable/GtkTable.html#GtkTable.properties), a 2d container
            *   [Notebook](https://developer.gnome.org/gtk3/stable/GtkNotebook.html#GtkNotebook.properties), a tabbed container
            *   [Paned](https://developer.gnome.org/gtk3/stable/GtkPaned.html#GtkPaned.properties), a container for resizing rectangular portions of a GUI
            *   [ButtonBox](https://developer.gnome.org/gtk3/stable/GtkButtonBox.html#GtkButtonBox.properties), layout of buttons
            *   [MenuShell](https://developer.gnome.org/gtk3/stable/GtkMenuShell.html#GtkMenuShell.properties), abstract type for menu containers
                *   [MenuBar](https://developer.gnome.org/gtk3/stable/GtkMenuBar.html#GtkMenuBar.properties)
                *   [Menu](https://developer.gnome.org/gtk3/stable/GtkMenu.html#GtkMenu.properties)
        *   Single-object containers:
            *   [Window](https://developer.gnome.org/gtk3/stable/GtkWindow.html#GtkWindow.properties)
            *   [Frame](https://developer.gnome.org/gtk3/stable/GtkFrame.html#GtkFrame.properties), to offset a region (optionally with label)
            *   [AspectFrame](https://developer.gnome.org/gtk3/stable/GtkAspectFrame.html#GtkAspectFrame.properties), a frame with fixed aspect ratio
            *   [Expander](https://developer.gnome.org/gtk3/stable/GtkExpander.html#GtkExpander.properties), a container that hides/reveals another widget
            *   [Overlay](https://developer.gnome.org/gtk3/stable/GtkOverlay.html#GtkOverlay.properties) (Gtk3 only)
        *   Single-object "containers" with specific GUI function
            *   [Button](https://developer.gnome.org/gtk3/stable/GtkButton.html#GtkButton.properties)
                *   [ToggleButton](https://developer.gnome.org/gtk3/stable/GtkToggleButton.html#GtkToggleButton.properties)
                    *   [CheckButton](https://developer.gnome.org/gtk3/stable/GtkCheckButton.html#GtkCheckButton.properties)
                        *   [RadioButton](https://developer.gnome.org/gtk3/stable/GtkRadioButton.html#GtkRadioButton.properties)
                *   [LinkButton](https://developer.gnome.org/gtk3/stable/GtkLinkButton.html#GtkLinkButton.properties), link to a URL
                *   [ScaleButton](https://developer.gnome.org/gtk3/stable/GtkScaleButton.html#GtkScaleButton.properties)
                    *   [VolumeButton](https://developer.gnome.org/gtk3/stable/GtkVolumeButton.html#GtkVolumeButton.properties), specialized for audio applications
            *   [ComboBox](https://developer.gnome.org/gtk3/stable/GtkComboBox.html#GtkComboBox.properties), select among dropdown options
                *   [ComboBoxText](https://developer.gnome.org/gtk3/stable/GtkComboBoxText.html#GtkComboBoxText.properties)
            *   [MenuItem](https://developer.gnome.org/gtk3/stable/GtkMenuItem.html#GtkMenuItem.properties)
                *   [SeparatorMenuItem](https://developer.gnome.org/gtk3/stable/GtkSeparatorMenuItem.html#GtkSeparatorMenuItem.properties), to insert a separator between menu items
            *   [Statusbar](https://developer.gnome.org/gtk3/stable/GtkStatusbar.html#GtkStatusbar.properties), queue messages and display to user
        *   [Entry](https://developer.gnome.org/gtk3/stable/GtkEntry.html#GtkEntry.properties), type short text in a box
            *   [SpinButton](https://developer.gnome.org/gtk3/stable/GtkSpinButton.html#GtkSpinButton.properties), increment/decrement or type a value
        *   [Range](https://developer.gnome.org/gtk3/stable/GtkRange.html#GtkRange.properties), abstract type for visualizing an `Adjustment`
            *   [Scale](https://developer.gnome.org/gtk3/stable/GtkScale.html#GtkScale.properties), slider for setting a value (see also `Adjustment`)
        *   [ProgressBar](https://developer.gnome.org/gtk3/stable/GtkProgressBar.html#GtkProgressBar.properties), progress on task of known duration
        *   [Spinner](https://developer.gnome.org/gtk3/stable/GtkSpinner.html#GtkSpinner.properties), progress on task of unknown duration
        *   [Miscellaneous](https://developer.gnome.org/gtk3/stable/GtkMisc.html#GtkMisc.properties)
            *   [Label](https://developer.gnome.org/gtk3/stable/GtkLabel.html#GtkLabel.properties), a text label
            *   [Image](https://developer.gnome.org/gtk3/stable/GtkImage.html#GtkImage.properties), an image

Other:

*   [Adjustment](https://developer.gnome.org/gtk3/stable/GtkAdjustment.html#GtkAdjustment.properties), stores value and range properties

Dialogs:

*   [FileChooser](https://developer.gnome.org/gtk3/stable/GtkFileChooser.html#GtkFileChooser.properties)

