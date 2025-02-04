const std = @import("std");

pub const CREATE_DATABASE_COMMAND = "CREATE DATABASE";

pub fn CreateDatabase(command: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    const databaseCreationValues = std.mem.trim(u8, command[CREATE_DATABASE_COMMAND.len..command.len], " ");
    try stdout.print("{s}\n", .{databaseCreationValues});

    const workingDirectoryPath = try std.fs.getAppDataDir(allocator, "zigdatabase");
    defer allocator.free(workingDirectoryPath);

    try stdout.print("{s}\n", .{workingDirectoryPath});

    const dir = try GetOrCreateDirectory(workingDirectoryPath);

    if (std.mem.containsAtLeast(u8, databaseCreationValues, 1, " ")) {
        try stdout.print("Given database name has space inside, TODO fail the command", .{});
        return;
    }

    const databaseFileName = try ConcatStrings(databaseCreationValues, ".zigdatabasefile", allocator);
    defer allocator.free(databaseFileName);

    const file = try dir.createFile(databaseFileName, .{ .read = true });
    defer file.close();

    try file.writeAll(databaseCreationValues);
}

fn GetOrCreateDirectory(path: []const u8) !std.fs.Dir {
    const dir = std.fs.cwd().openDir(path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            try std.fs.cwd().makeDir(path);
            return try std.fs.cwd().openDir(path, .{});
        } else {
            return err;
        }
    };
    return dir;
}

fn ConcatStrings(a: []const u8, b: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var string = std.ArrayList(u8).init(alloc);
    try string.appendSlice(a);
    try string.appendSlice(b);

    const result = try alloc.dupe(u8, string.items);

    string.deinit();

    return result;
}
