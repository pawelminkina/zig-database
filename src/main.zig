const std = @import("std");
const builtin = @import("builtin");
const database = @import("database.zig");

const Normalizer = @import("ziglyph").Normalizer;
const MAX_QUERY_LENGTH = 65536;

pub fn main() !void {
    //What I actually want to achive? This is very good questions, let's make a list of things what I actually want to have in my code
    //
    //I want to have ability to store data in tables devided by columns, like in relational database
    //I want to be able to create those tables with a command, using kind of sql query language, at first the moment table is created only way to change is by deleting
    //At first version I want to be able to retrieve all data from 1 table using command like select * from tablename
    //
    //So in other words the most basic version would contain
    //0. Using command create database DbNameHere it will create database and put it to user data
    //1. Create table with columns having particular data type using command like "Create table tableName (column: int32, columnUber2: string)" (easy databa type at first)
    //2. Add value to table using command insert into tableName (column, column) values (val1, val2) or tableName values (val1, val2) assuming all columns provided
    //3. Get all values from particular table

    //That's where I start, but I aim to introduce keys, indexes, data types contains byte content like string for 5 characters, select certiain properties, relationships with joins (at least inner and left)
    //
    //Ok so first thing first. Ability to create table with command like create table tablename (column: int32) and allowing to write data to it.
    //So effectively create a file with extension .zigdatabasefile containing schema for all files (later relationships maybe)
    //And create another file with same exstension containing some simple data. How to seperate data? Let's start with something simple and see what are the issues. Let's use seperator like csv so ',' but when
    //text has ',' then just put it in "". If text contains "" put it in double """"

    //Now I need a code to read commands execute them and allow to read another command. Interesting
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var lineBuf: [MAX_QUERY_LENGTH]u8 = undefined;

    try stdout.print("Please enter a command: ", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

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
    defer allocator.free(fullCommand);

    var norm = try Normalizer.init(allocator);
    defer norm.deinit();

    const createDatabaseLen = database.CREATE_DATABASE_COMMAND.len;
    if (fullCommand.len > createDatabaseLen) {
        const isEql = try norm.eqlCaseless(allocator, fullCommand[0..createDatabaseLen], database.CREATE_DATABASE_COMMAND);
        if (isEql) {
            try database.CreateDatabase(fullCommand);
        }
    }

    try stdout.print("\nNoice", .{});
}
