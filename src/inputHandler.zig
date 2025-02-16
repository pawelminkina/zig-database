const std = @import("std");
const builtin = @import("builtin");

const MAX_QUERY_LENGTH = 65536;

pub fn GetInput(allocator: std.mem.Allocator) ![]u8 {
    const stdin = std.io.getStdIn().reader();
    var lineBuf: [MAX_QUERY_LENGTH]u8 = undefined;

    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    if (try stdin.readUntilDelimiterOrEof(&lineBuf, '\n')) |line| { //try to catch and handle error when query length longer than possible
        var command = line;
        if (builtin.os.tag == .windows) {
            // In Windows lines are terminated by \r\n.
            // We need to strip out the \r
            command = @constCast(std.mem.trimRight(u8, command, "\r"));
        }

        try lines.append(command);
    }

    const fullCommand = std.mem.join(allocator, " ", try lines.toOwnedSlice()) catch |err| {
        return err;
    };

    return fullCommand;
}
