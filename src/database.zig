const std = @import("std");
const managed = @import("managed.zig");
const inputHandler = @import("inputHandler.zig");

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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const optional_dbInstance = try GetDatabaseInstance(allocator, dbName);
    if (optional_dbInstance) |dbInstance| {
        try stdout.print("\ndb connected", .{});

        while (true) {
            try stdout.print("\nput command: \n", .{});
            const fullCommand = try inputHandler.GetInput(allocator);
            defer allocator.free(fullCommand);

            if (std.mem.eql(u8, fullCommand, "q")) {
                break;
            }

            if (std.mem.containsAtLeast(u8, fullCommand, 1, "CREATE TABLE")) {
                const trimmedCommand = std.mem.trimLeft(u8, fullCommand, "CREATE TABLE ");
                try optional_dbInstance.?.AddTable(trimmedCommand);
            }
        }

        try dbInstance.JustTestingSavingMoreTextToDbFile();
        return;
    }

    try stdout.print("Db does not exist with name {s}", .{dbName});
}

pub fn GetDatabaseInstance(alloc: std.mem.Allocator, databaseName: []const u8) !?*DatabaseInstance {
    const databaseFileName = try ConcatStrings(databaseName, ".zigdatabasefile", alloc);

    const workingDirectoryPath = try std.fs.getAppDataDir(alloc, "zigdatabase");
    const dir = try GetOrCreateDirectory(workingDirectoryPath);

    const String = []const u8;
    const paths = [_]String{ workingDirectoryPath, databaseFileName };
    const filePath = try std.fs.path.join(alloc, &paths);

    const fileExist = try isFileRWExist(dir, databaseFileName);

    if (fileExist == false) {
        return null;
    }

    return DatabaseInstance.init(alloc, filePath);
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

    pub fn AddTable(self: *DatabaseInstance, command: []const u8) !void {
        _ = try Table.Create(self.alloc, command);
        const stdout = std.io.getStdOut().writer();
        try stdout.print("Creating table did not crash, so that's progress", .{});

        const file = try std.fs.openFileAbsolute(self.databaseFilePath, .{ .mode = std.fs.File.OpenMode.read_write });
        defer file.close();

        //TODO here write my json schema of database, so basically get everything what there is if table exist fail if it doesn't add it
    }
};

pub const Table = struct {
    tableName: []const u8,
    columnDetails: []ColumnDetails,
    alloc: std.mem.Allocator,

    //TODO, can do check so columns does not have spaces, commas, seperators etc.
    pub fn Create(alloc: std.mem.Allocator, values: []const u8) !Table {
        //ok here I have command like "table_name (column datatype null, column datatype)"
        //null if datatype is nullable
        //I already removed "CREATE TABLE" from the start the name the moment I identified the type of command
        var commandIterator = std.mem.splitSequence(u8, values, " ");
        const tableName = commandIterator.next();

        if (!std.mem.containsAtLeast(u8, commandIterator.next().?, 1, "(")) {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("Given table name in command contains space", .{});
            //TODO error or something
        }

        var columnsIterator = std.mem.splitSequence(u8, values, "(");
        _ = columnsIterator.next();
        const columnValues = std.mem.trimRight(u8, columnsIterator.next().?, ")");

        var splittedColumns = std.mem.splitSequence(u8, columnValues, ",");
        var createdColumns = std.ArrayList(ColumnDetails).init(alloc);
        while (splittedColumns.next()) |columnValue| {
            const column = ColumnDetails.Create(columnValue);
            if (column != null) {
                try createdColumns.append(column.?);
            }
        }

        return Table{ .alloc = alloc, .columnDetails = try createdColumns.toOwnedSlice(), .tableName = tableName.? };
    }
};

pub const ColumnDetails = struct {
    name: []const u8,
    type: []const u8,
    typeSize: ?u8,
    nullable: bool,

    pub fn Create(values: []const u8) ?ColumnDetails {
        //we're getting "column datatype null"
        var trimmedValues = std.mem.trimRight(u8, values, " ");
        trimmedValues = std.mem.trimLeft(u8, trimmedValues, " ");
        var iterator = std.mem.splitSequence(u8, trimmedValues, " ");
        const columnName = iterator.next();
        var dataType = iterator.next();
        const nullable = std.mem.eql(u8, iterator.next().?, "null");
        var typeSize: ?u8 = null;

        var constainsTypeSizeIterator = std.mem.splitSequence(u8, dataType.?, "(");
        const correctDataType = constainsTypeSizeIterator.next();
        const potentialTypeSize = constainsTypeSizeIterator.next();

        if (potentialTypeSize != null and std.mem.containsAtLeast(u8, potentialTypeSize.?, 1, ")")) {
            const typeSizeSlice = potentialTypeSize.?[0 .. potentialTypeSize.?.len - 1];
            typeSize = std.fmt.parseInt(u8, typeSizeSlice, 10) catch unreachable;
            dataType = correctDataType;
        }

        if (!(std.mem.eql(u8, dataType.?, "bool") or std.mem.eql(u8, dataType.?, "varchar") or std.mem.eql(u8, dataType.?, "int"))) {
            return null;
        }

        return ColumnDetails{
            .name = columnName.?,
            .nullable = nullable,
            .typeSize = typeSize,
            .type = dataType.?,
        };

        //syntax of datatype is
    }
};
