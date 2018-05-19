#![feature(lang_items)]
#![feature(ptr_internals)]
#![no_std]

extern crate volatile;
extern crate spin;

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
