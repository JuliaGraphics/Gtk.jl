# Gtk objects
const AboutDialog_new = GtkAboutDialog_new
const AccelGroup_new = GtkAccelGroup_new
const Adjustment_new = GtkAdjustment_new
const Application_new = GtkApplication_new
const AspectFrame_new = GtkAspectFrame_new
const Box_new = GtkBox_new
const Builder_new = GtkBuilder_new
const Button_new = GtkButton_new
const ButtonBox_new = GtkButtonBox_new
const Canvas_new = GtkCanvas_new
const CellRendererAccel_new = GtkCellRendererAccel_new
const CellRendererCombo_new = GtkCellRendererCombo_new
const CellRendererPixbuf_new = GtkCellRendererPixbuf_new
const CellRendererProgress_new = GtkCellRendererProgress_new
const CellRendererSpin_new = GtkCellRendererSpin_new
const CellRendererSpinner_new = GtkCellRendererSpinner_new
const CellRendererText_new = GtkCellRendererText_new
const CellRendererToggle_new = GtkCellRendererToggle_new
const CheckButton_new = GtkCheckButton_new
const ComboBoxText_new = GtkComboBoxText_new
const CssProvider_new = GtkCssProvider_new
const Dialog_new = GtkDialog_new
const Entry_new = GtkEntry_new
const EntryCompletion_new = GtkEntryCompletion_new
const Expander_new = GtkExpander_new
const FileChooserDialog_new = GtkFileChooserDialog_new
const FontButton_new = GtkFontButton_new
const Frame_new = GtkFrame_new
const Image_new = GtkImage_new
const Label_new = GtkLabel_new
const Layout_new = GtkLayout_new
const LinkButton_new = GtkLinkButton_new
const ListStore_new = GtkListStore_new
const Menu_new = GtkMenu_new
const MenuBar_new = GtkMenuBar_new
const MenuItem_new = GtkMenuItem_new
const MenuToolButton_new = GtkMenuToolButton_new
const MessageDialog_new = GtkMessageDialog_new
const Notebook_new = GtkNotebook_new
const Null_new = GtkNullContainer_new
const Overlay_new = GtkOverlay_new
const Paned_new = GtkPaned_new
const Pixbuf_new = GdkPixbuf_new
const ProgressBar_new = GtkProgressBar_new
const RadioButton_new = GtkRadioButton_new
const RadioButtonGroup_new = GtkRadioButtonGroup_new
const Scale_new = GtkScale_new
const ScrolledWindow_new = GtkScrolledWindow_new
const SeparatorMenuItem_new = GtkSeparatorMenuItem_new
const SeparatorToolItem_new = GtkSeparatorToolItem_new
const SpinButton_new = GtkSpinButton_new
const Spinner_new = GtkSpinner_new
const StatusIcon_new = GtkStatusIcon_new
const Statusbar_new = GtkStatusbar_new
const StyleContext_new = GtkStyleContext_new
const Text_new = GtkTextView_new
const TextBuffer_new = GtkTextBuffer_new
const TextMark_new = GtkTextMark_new
const TextTag_new = GtkTextTag_new
const TextView_new = GtkTextView_new
const ToggleButton_new = GtkToggleButton_new
const ToggleToolButton_new = GtkToggleToolButton_new
const ToolButton_new = GtkToolButton_new
const ToolItem_new = GtkToolItem_new
const Toolbar_new = GtkToolbar_new
const TreeModelFilter_new = GtkTreeModelFilter_new
const TreeSelection_new = GtkTreeSelection_new
const TreeStore_new = GtkTreeStore_new
const TreeView_new = GtkTreeView_new
const TreeViewColumn_new = GtkTreeViewColumn_new
const VolumeButton_new = GtkVolumeButton_new
const Window_new = GtkWindow_new

export G__new,
    AboutDialog_new,
    AccelGroup_new,
    Adjustment_new,
    Application_new,
    AspectFrame_new,
    Box_new,
    Builder_new,
    Button_new,
    ButtonBox_new,
    Canvas_new,
    CellRendererAccel_new,
    CellRendererCombo_new,
    CellRendererPixbuf_new,
    CellRendererProgress_new,
    CellRendererSpin_new,
    CellRendererSpinner_new,
    CellRendererText_new,
    CellRendererToggle_new,
    CheckButton_new,
    ComboBoxText_new,
    CssProvider_new,
    Dialog_new,
    Entry_new,
    EntryCompletion_new,
    Expander_new,
    FileChooserDialog_new,
    FontButton_new,
    Frame_new,
    Image_new,
    Label_new,
    Layout_new,
    LinkButton_new,
    ListStore_new,
    Menu_new,
    MenuBar_new,
    MenuItem_new,
    MenuToolButton_new,
    MessageDialog_new,
    Notebook_new,
    Null_new,
    Overlay_new,
    Paned_new,
    Pixbuf_new,
    ProgressBar_new,
    RadioButton_new,
    RadioButtonGroup_new,
    Scale_new,
    ScrolledWindow_new,
    SeparatorMenuItem_new,
    SeparatorToolItem_new,
    SpinButton_new,
    Spinner_new,
    StatusIcon_new,
    Statusbar_new,
    StyleContext_new,
    TextBuffer_new,
    TextMark_new,
    TextTag_new,
    TextView_new,
    ToggleButton_new,
    ToggleToolButton_new,
    ToolButton_new,
    ToolItem_new,
    Toolbar_new,
    TreeModelFilter_new,
    TreeSelection_new,
    TreeStore_new,
    TreeView_new,
    TreeViewColumn_new,
    VolumeButton_new,
    Window_new

# Gtk 3
if Gtk.gtk_version >= 3
    const Grid_new = GtkGrid_new
    export Grid_new
end

# Gtk 2
if Gtk.gtk_version >= 2
    const Table_new = GtkTable_new
    const Alignment_new = GtkAlignment_new
    export Table_new, Aligment_new
end
