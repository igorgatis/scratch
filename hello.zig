pub extern "c" fn printf(format: [*:0]const u8, ...) i32;

export fn main(argc: i32, argv: [*]const [*]const u8) i32 {
    _ = argc;
    _ = argv;
    _ = printf("Hello, world!\n");
    return 0;
}
