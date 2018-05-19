#![feature(lang_items)]
#![no_std]

extern crate volatile;

mod vga_buffer;

#[lang = "eh_personality"]
extern fn eh_personality() {}

#[lang = "panic_fmt"]
extern fn rust_begin_panic() -> ! {
    loop {}
}

#[no_mangle]
pub extern fn kmain() -> ! {
    vga_buffer::write("Hello World!");

    loop {}
}
