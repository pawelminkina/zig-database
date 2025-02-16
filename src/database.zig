const std = @import("std");
const managed = @import("managed.zig");

pub const CREATE_DATABASE_COMMAND = "CREATE DATABASE";
pub const CREATE_TABLE_COMMAND = "CREATE TABLE";
pub const CONNECT_DATABASE = "CONNECT DATABASE";

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

pub fn ConnectDatabase(command: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    const dbName = std.mem.trim(u8, command[CONNECT_DATABASE.len..command.len], " ");

    if (std.mem.containsAtLeast(u8, dbName, 1, " ")) {
        try stdout.print("Given database name has space inside, TODO fail the command", .{});
        return;
    }

    const optional_dbInstance = try GetDatabaseInstance(dbName);
    if (optional_dbInstance) |dbInstance| {
        try dbInstance.JustTestingSavingMoreTextToDbFile();
        return;
    }

    try stdout.print("Db does not exist with name {s}", .{dbName});

    //   while (true){
    //       //this is my way to go, I'll recieve various commands here
    //   }
}

pub fn GetDatabaseInstance(databaseName: []const u8) !?*DatabaseInstance {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const databaseFileName = try ConcatStrings(databaseName, ".zigdatabasefile", allocator);

    const workingDirectoryPath = try std.fs.getAppDataDir(allocator, "zigdatabase");
    const dir = try GetOrCreateDirectory(workingDirectoryPath);

    const String = []const u8;
    const paths = [_]String{ workingDirectoryPath, databaseFileName };
    const filePath = try std.fs.path.join(allocator, &paths);

    const fileExist = try isFileRWExist(dir, databaseFileName);

    if (fileExist == false) {
        return null;
    }

    return DatabaseInstance.init(allocator, filePath);
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

pub fn isFileRWExist(fn_dir: std.fs.Dir, fn_file_name: []const u8) !bool {
    fn_dir.access(fn_file_name, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => return false,
        error.PermissionDenied => return false,
        else => {
            // (snip)
            return err;
        },
    };

    return true;
}

pub const DatabaseInstance = struct {
    alloc: std.mem.Allocator,
    databaseFilePath: []const u8,

    pub fn init(alloc: std.mem.Allocator, filePath: []const u8) !*DatabaseInstance {
        const instancePtr = try alloc.create(DatabaseInstance);
        instancePtr.* = DatabaseInstance{
            .alloc = alloc,
            .databaseFilePath = filePath,
        };
        return instancePtr;
    }

    pub fn JustTestingSavingMoreTextToDbFile(self: *DatabaseInstance) !void {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("/nFilepath: {s}/n", .{self.databaseFilePath});
        const file = try std.fs.openFileAbsolute(self.databaseFilePath, .{ .mode = std.fs.File.OpenMode.read_write });
        defer file.close();
        const stat = try file.stat();
        try file.seekTo(stat.size);

        _ = try file.writer().write("\njust some random text here\n");
    }

    pub fn AddTable(self: *DatabaseInstance, command: []const u8) void {
        const createdTable = Table.Create(command);

        

        //parse a file to object
        //add my table to list of tables in that object and save
    }
};

pub const DatabaseObject = struct {
    tables: []Table,

    pub fn GetFromFile(filePath: []const u8){
        const file = try std.fs.openFileAbsolute(self.databaseFilePath, .{ .mode = std.fs.File.OpenMode.read_write });
        defer file.close();

        //get parser from json and save json file, that's fucking it


    }
}

pub const Table = struct {
    tableName: []const u8,
    columnDetails: []ColumnDetails,

    pub fn Create(values: []const u8) Table {
        //what do we expect, what values?
        //create table
        //TODO somehow parse it, use fucking json for it
    }
};

pub const ColumnDetails = struct { name: []const u8, type: ColumnType, typeSize: ?u8 };

pub const ColumnType = enum { bool, nchar, int };
