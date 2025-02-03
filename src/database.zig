const std = @import("std");

pub const CREATE_DATABASE_COMMAND = "CREATE DATABASE";

pub fn CreateDatabase(command: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    const databaseCreationValues = std.mem.trim(u8, command[CREATE_DATABASE_COMMAND.len..command.len], " ");

    try stdout.print("{s}", .{databaseCreationValues});
}
