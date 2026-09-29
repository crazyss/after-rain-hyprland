hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11")
-- Let native Wayland toolkits use the compositor input method by default.
-- Empty values also override IBus module settings inherited from im-config.
hl.env("GTK_IM_MODULE", "")
hl.env("QT_IM_MODULE", "")
hl.env("QT_IM_MODULES", "wayland;ibus")
hl.env("XMODIFIERS", "@im=ibus")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
