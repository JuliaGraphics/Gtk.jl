immutable GdkRectangle
    x::Int32
    y::Int32
    width::Int32
    height::Int32
    GdkRectangle(x,y,w,h) = new(x,y,w,h)
end
immutable GdkPoint
    x::Int32
    y::Int32
    GdkPoint(x,y) = new(x,y)
end
gdk_window(w::GtkWidget) = ccall((:gtk_widget_get_window,libgtk),Ptr{Void},(Ptr{GtkObject},),w)

baremodule GdkEventMask
    import Base.<<
    const GDK_EXPOSURE_MASK		    = 1 << 1
    const GDK_POINTER_MOTION_MASK   = 1 << 2
    const GDK_POINTER_MOTION_HINT_MASK = 1 << 3
    const GDK_BUTTON_MOTION_MASK    = 1 << 4
    const GDK_BUTTON1_MOTION_MASK   = 1 << 5
    const GDK_BUTTON2_MOTION_MASK   = 1 << 6
    const GDK_BUTTON3_MOTION_MASK   = 1 << 7
    const GDK_BUTTON_PRESS_MASK		= 1 << 8
    const GDK_BUTTON_RELEASE_MASK   = 1 << 9
    const GDK_KEY_PRESS_MASK		= 1 << 10
    const GDK_KEY_RELEASE_MASK		= 1 << 11
    const GDK_ENTER_NOTIFY_MASK		= 1 << 12
    const GDK_LEAVE_NOTIFY_MASK		= 1 << 13
    const GDK_FOCUS_CHANGE_MASK		= 1 << 14
    const GDK_STRUCTURE_MASK		= 1 << 15
    const GDK_PROPERTY_CHANGE_MASK  = 1 << 16
    const GDK_VISIBILITY_NOTIFY_MASK = 1 << 17
    const GDK_PROXIMITY_IN_MASK	 	= 1 << 18
    const GDK_PROXIMITY_OUT_MASK    = 1 << 19
    const GDK_SUBSTRUCTURE_MASK		= 1 << 20
    const GDK_SCROLL_MASK           = 1 << 21
    const GDK_ALL_EVENTS_MASK		= 0x3FFFFE
end

baremodule GdkModifierType
    import Base: <<, |
    const GDK_SHIFT_MASK    = 1 << 0
    const GDK_LOCK_MASK     = 1 << 1
    const GDK_CONTROL_MASK  = 1 << 2
    const GDK_MOD1_MASK     = 1 << 3
    const GDK_MOD2_MASK     = 1 << 4
    const GDK_MOD3_MASK     = 1 << 5
    const GDK_MOD4_MASK     = 1 << 6
    const GDK_MOD5_MASK     = 1 << 7
    const GDK_BUTTON1_MASK  = 1 << 8
    const GDK_BUTTON2_MASK  = 1 << 9
    const GDK_BUTTON3_MASK  = 1 << 10
    const GDK_BUTTON4_MASK  = 1 << 11
    const GDK_BUTTON5_MASK  = 1 << 12
    const GDK_BUTTONS_MASK  =
            GdkModifierType.GDK_BUTTON1_MASK |
            GdkModifierType.GDK_BUTTON2_MASK |
            GdkModifierType.GDK_BUTTON3_MASK |
            GdkModifierType.GDK_BUTTON4_MASK |
            GdkModifierType.GDK_BUTTON5_MASK

    const GDK_MODIFIER_RESERVED_13_MASK  = 1 << 13
    const GDK_MODIFIER_RESERVED_14_MASK  = 1 << 14
    const GDK_MODIFIER_RESERVED_15_MASK  = 1 << 15
    const GDK_MODIFIER_RESERVED_16_MASK  = 1 << 16
    const GDK_MODIFIER_RESERVED_17_MASK  = 1 << 17
    const GDK_MODIFIER_RESERVED_18_MASK  = 1 << 18
    const GDK_MODIFIER_RESERVED_19_MASK  = 1 << 19
    const GDK_MODIFIER_RESERVED_20_MASK  = 1 << 20
    const GDK_MODIFIER_RESERVED_21_MASK  = 1 << 21
    const GDK_MODIFIER_RESERVED_22_MASK  = 1 << 22
    const GDK_MODIFIER_RESERVED_23_MASK  = 1 << 23
    const GDK_MODIFIER_RESERVED_24_MASK  = 1 << 24
    const GDK_MODIFIER_RESERVED_25_MASK  = 1 << 25

    # The next few modifiers are used by XKB, so we skip to the end.
    # Bits 15 - 25 are currently unused. Bit 29 is used internally.

    const GDK_SUPER_MASK    = 1 << 26
    const GDK_HYPER_MASK    = 1 << 27
    const GDK_META_MASK     = 1 << 28

    const GDK_MODIFIER_RESERVED_29_MASK  = 1 << 29

    const GDK_RELEASE_MASK  = 1 << 30

    # Combination of GDK_SHIFT_MASK..GDK_BUTTON5_MASK + GDK_SUPER_MASK
    # + GDK_HYPER_MASK + GDK_META_MASK + GDK_RELEASE_MASK */
    const GDK_MODIFIER_MASK = 0x5c001fff
end

immutable GdkEventButton
    event_type::Enum
    gdk_window::Ptr{Void}
    send_event::Int8
    time::Uint32
    x::Float64
    y::Float64
    axes::Ptr{Float64}
    state::Uint32
    button::Uint32
    gdk_device::Ptr{Void}
    x_root::Float64
    y_root::Float64
end

immutable GdkEventMotion
  event_type::Enum
  gdk_window::Ptr{Void}
  send_event::Int8
  time::Uint32
  x::Float64
  y::Float64
  axes::Ptr{Float64}
  state::Uint32
  is_hint::Int16
  gdk_device::Ptr{Void}
  x_root::Float64
  y_root::Float64
end
    
