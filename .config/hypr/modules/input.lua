-- Ported from conf/keyboard.conf

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        numlock_by_default = true,

        follow_mouse  = 1,
        mouse_refocus = false,
        sensitivity   = 0, -- -1.0 .. 1.0, 0 = no modification

        touchpad = {
            natural_scroll       = false,
            scroll_factor        = 1.0,
            disable_while_typing = false,
        },
    },
})
