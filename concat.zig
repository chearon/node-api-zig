const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        print("Usage: {s} <input_file1> [input_file2 ...] <output_file>\n", .{args[0]});
        print("Minimum 2 arguments required: 1 input file and 1 output file\n", .{});
        std.process.exit(1);
    }

    const output_path = args[args.len - 1];
    const input_files = args[1 .. args.len - 1];
    var buffer: [4096]u8 = undefined;

    const output_file = try std.fs.cwd().createFile(output_path, .{.truncate = true});
    defer output_file.close();

    for (input_files) |input_path| {
        const input_file = try std.fs.cwd().openFile(input_path, .{});
        defer input_file.close();
        while (true) {
            const bytes_read = try input_file.read(&buffer);
            if (bytes_read == 0) break;

            var bytes_written: usize = 0;
            while (bytes_written < bytes_read) {
                bytes_written += try output_file.write(buffer[bytes_written..bytes_read]);
            }
        }
    }
}