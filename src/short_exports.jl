# Gtk objects
const G_ = GAccessor
const AboutDialog = GtkAboutDialog
const AccelGroup = GtkAccelGroup
const Adjustment = GtkAdjustment
const Application = GtkApplication
const AspectFrame = GtkAspectFrame
const Box = GtkBox
const Builder = GtkBuilder
const Button = GtkButton
const ButtonBox = GtkButtonBox
const Canvas = GtkCanvas
const CellRendererAccel = GtkCellRendererAccel
const CellRendererCombo = GtkCellRendererCombo
const CellRendererPixbuf = GtkCellRendererPixbuf
const CellRendererProgress = GtkCellRendererProgress
const CellRendererSpin = GtkCellRendererSpin
const CellRendererSpinner = GtkCellRendererSpinner
const CellRendererText = GtkCellRendererText
const CellRendererToggle = GtkCellRendererToggle
const CheckButton = GtkCheckButton
const ComboBoxText = GtkComboBoxText
const CssProvider = GtkCssProvider
const Dialog = GtkDialog    
const Entry = GtkEntry
const EntryCompletion = GtkEntryCompletion
const Expander = GtkExpander
const FileChooserDialog = GtkFileChooserDialog
const FontButton = GtkFontButton
const Frame = GtkFrame
const Image = GtkImage
const Label = GtkLabel
const Layout = GtkLayout
const LinkButton = GtkLinkButton
const ListStore = GtkListStore
const Menu = GtkMenu
const MenuBar = GtkMenuBar
const MenuItem = GtkMenuItem
const MenuToolButton = GtkMenuToolButton
const MessageDialog = GtkMessageDialog
const Notebook = GtkNotebook
const Overlay = GtkOverlay
const Paned = GtkPaned
const Pixbuf = GdkPixbuf
const ProgressBar = GtkProgressBar
const RadioButton = GtkRadioButton
const Scale = GtkScale
const ScrolledWindow = GtkScrolledWindow
const SeparatorMenuItem = GtkSeparatorMenuItem
const SeparatorToolItem = GtkSeparatorToolItem
const SpinButton = GtkSpinButton
const Spinner = GtkSpinner
const StatusIcon = GtkStatusIcon
const Statusbar = GtkStatusbar
const StyleContext = GtkStyleContext
const Text = GtkTextView
const TextBuffer = GtkTextBuffer
const TextMark = GtkTextMark
const TextTag = GtkTextTag
const TextView = GtkTextView
const ToggleButton = GtkToggleButton
const ToggleToolButton = GtkToggleToolButton
const ToolButton = GtkToolButton
const ToolItem = GtkToolItem
const Toolbar = GtkToolbar
const TreeIter = GtkTreeIter
const TreeModelFilter = GtkTreeModelFilter
const TreeSelection = GtkTreeSelection
const TreeStore = GtkTreeStore
const TreeView = GtkTreeView
const TreeViewColumn = GtkTreeViewColumn
const VolumeButton = GtkVolumeButton
const Window = GtkWindow

export G_, GObject,
    AboutDialog,
    AccelGroup,
    Adjustment,
    Application,
    AspectFrame,
    Box,
    Builder,
    Button,
    ButtonBox,
    Canvas,
    CellRendererAccel,
    CellRendererCombo,
    CellRendererPixbuf,
    CellRendererProgress,
    CellRendererSpin,
    CellRendererSpinner,
    CellRendererText,
    CellRendererToggle,
    CheckButton,
    ComboBoxText,
    CssProvider,
    Dialog,
    Entry,
    EntryCompletion,
    Expander,
    FileChooserDialog,
    FontButton,
    Frame,
    Image,
    Label,
    Layout,
    LinkButton,
    ListStore,
    Menu,
    MenuBar,
    MenuItem,
    MenuToolButton,
    MessageDialog,
    Notebook,
    Overlay,
    Paned,
    Pixbuf,
    ProgressBar,
    RadioButton,
    Scale,
    ScrolledWindow,
    SeparatorMenuItem,
    SeparatorToolItem,
    SpinButton,
    Spinner,
    StatusIcon,
    Statusbar,
    StyleContext,
    TextBuffer,
    TextMark,
    TextTag,
    TextView,
    ToggleButton,
    ToggleToolButton,
    ToolButton,
    ToolItem,
    Toolbar,
    TreeIter,
    TreeModelFilter,
    TreeSelection,
    TreeStore,
    TreeView,
    TreeViewColumn,
    VolumeButton,
    Window

# Gtk 3
if Gtk.gtk_version >= 3
    const Grid = GtkGrid
    export Grid
end

# Gtk 2
if Gtk.gtk_version >= 2
    const Table = GtkTable
    const Alignment = GtkAlignment
    export Table, Aligment
end
