const std = @import("std");
const zig_sqlite = @import("zlite");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 1) Open DB
    var db = try zig_sqlite.Database.open(allocator, "test.db");
    defer db.close();

    // 2) Create a table
    try db.exec("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT);");

    // 3) Insert a row
    try db.exec("INSERT INTO users (name) VALUES ('alice');");

    // 4) Query names
    const rows = try zig_sqlite.query(&db, "SELECT name FROM users;", allocator);
    for (rows) |name| {
        std.debug.print("user: {s}\n", .{name});
    }
}
