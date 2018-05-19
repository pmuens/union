use volatile::Volatile;

pub fn write(string: &str) {
    let mut writer = Writer {
        column_position: 0,
        buffer: unsafe { &mut *(0xb8000 as *mut Buffer) },
    };
    writer.write_string(string);
}

#[derive(Debug, Copy, Clone)]
#[repr(C)]
struct ScreenChar {
    ascii_character: u8,
    color_code: u8
}

impl ScreenChar {
    fn new(byte: u8) -> ScreenChar {
        ScreenChar {
            ascii_character: byte,
            color_code: 15 // white foreground, black background
        }
    }
}

const BUFFER_HEIGHT: usize = 25;
const BUFFER_WIDTH: usize = 80;

struct Buffer {
    chars: [[Volatile<ScreenChar>; BUFFER_WIDTH]; BUFFER_HEIGHT],
}

struct Writer {
    column_position: usize,
    buffer: &'static mut Buffer,
}

impl Writer {
    fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.new_line(),
            byte => {
                if self.column_position >= BUFFER_WIDTH {
                    self.new_line();
                }

                let row = BUFFER_HEIGHT - 1;
                let col = self.column_position;

                let character = ScreenChar::new(byte);
                self.buffer.chars[row][col].write(character);
                self.column_position += 1;
            }
        }
    }

    fn write_string(&mut self, s: &str) {
        for byte in s.bytes() {
            match byte {
                0x20...0x7e | b'\n' => self.write_byte(byte),
                _ => self.write_byte(0xfe),
            }
        }
    }

    fn new_line(&mut self) {
        for row in 1..BUFFER_HEIGHT {
            for col in 0..BUFFER_WIDTH {
                let character = self.buffer.chars[row][col].read();
                self.buffer.chars[row - 1][col].write(character);
            }
        }
        self.clear_row(BUFFER_HEIGHT - 1);
        self.column_position = 0;
    }

    fn clear_row(&mut self, row: usize) {
        let blank = ScreenChar::new(b' ');
        for col in 0..BUFFER_WIDTH {
            self.buffer.chars[row][col].write(blank);
        }
    }
}
