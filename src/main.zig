const std = @import("std");

pub fn main() !void {
    //What I actually want to achive? This is very good questions, let's make a list of things what I actually want to have in my code
    //
    //I want to have ability to store data in tables devided by columns, like in relational database
    //I want to be able to create those tables with a command, using kind of sql query language, at first the moment table is created only way to change is by deleting
    //At first version I want to be able to retrieve all data from 1 table using command like select * from tablename
    //
    //So in other words the most basic version would contain
    //1. Create table with columns having particular data type using command like "Create table tableName (column: int32, columnUber2: string)" (easy databa type at first)
    //2. Add value to table using command insert into tableName (column, column) values (val1, val2) or tableName values (val1, val2) assuming all columns provided
    //3. Get all values from particular table

    //That's where I start, but I aim to introduce keys, indexes, data types contains byte content like string for 5 characters, select certiain properties, relationships with joins (at least inner and left)
}
