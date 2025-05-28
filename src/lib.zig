const std = @import("std");
const Allocator = std.mem.Allocator;

// SQLite result codes
const SQLITE_OK = 0;
const SQLITE_ROW = 100;
const SQLITE_DONE = 101;

// Opaque C types
pub const sqlite3 = extern struct {};
pub const sqlite3_stmt = extern struct {};
const c_void = extern struct {};

// C function bindings
pub extern "c" fn sqlite3_open(
    filename: [*:0]const u8,
    pp_db: *?*sqlite3,
) c_int;

pub extern "c" fn sqlite3_close(
    db: *sqlite3,
) c_int;

pub extern "c" fn sqlite3_exec(
    db: *sqlite3,
    sql: [*:0]const u8,
    callback: ?*const c_void,
    callback_arg: ?*const c_void,
    errmsg: *?[*:0]u8,
) c_int;

pub extern "c" fn sqlite3_prepare_v2(
    db: *sqlite3,
    sql: [*:0]const u8,
    sql_len: c_int,
    pp_stmt: *?*sqlite3_stmt,
    pz_tail: ?[*:0]const u8,
) c_int;

pub extern "c" fn sqlite3_step(
    stmt: *sqlite3_stmt,
) c_int;

pub extern "c" fn sqlite3_column_text(
    stmt: *sqlite3_stmt,
    col_index: c_int,
) [*:0]const u8;

pub extern "c" fn sqlite3_finalize(
    stmt: *sqlite3_stmt,
) c_int;

pub const SqliteError = error{
    OpenFailed,
    ExecFailed,
    PrepareFailed,
    StepFailed,
    FinalizeFailed,
};

pub const Database = struct {
    db: *sqlite3,
    allocator: Allocator,

    pub fn open(allocator: Allocator, filename: []const u8) !Database {
        var db_ptr: ?*sqlite3 = null;

        // Ensure null-terminated string for C API
        const c_filename = try allocator.dupeZ(u8, filename);
        defer allocator.free(c_filename);

        const result = sqlite3_open(c_filename.ptr, &db_ptr);
        if (result != SQLITE_OK) {
            return SqliteError.OpenFailed;
        }

        return Database{
            .db = db_ptr.?,
            .allocator = allocator,
        };
    }

    pub fn close(self: *Database) void {
        _ = sqlite3_close(self.db);
    }

    pub fn exec(self: *Database, sql: []const u8) !void {
        // Ensure null-terminated string for C API
        const c_sql = try self.allocator.dupeZ(u8, sql);
        defer self.allocator.free(c_sql);

        var err_msg: ?[*:0]u8 = null;
        const result = sqlite3_exec(self.db, c_sql.ptr, null, null, &err_msg);

        if (result != SQLITE_OK) {
            return SqliteError.ExecFailed;
        }
    }
};

pub fn query(db: *Database, sql: []const u8, allocator: Allocator) ![][]const u8 {
    // Ensure null-terminated string for C API
    const c_sql = try allocator.dupeZ(u8, sql);
    defer allocator.free(c_sql);

    var stmt_ptr: ?*sqlite3_stmt = null;
    const prepare_result = sqlite3_prepare_v2(db.db, c_sql.ptr, @intCast(c_sql.len), &stmt_ptr, null);

    if (prepare_result != SQLITE_OK) {
        return SqliteError.PrepareFailed;
    }

    const stmt = stmt_ptr.?;
    defer _ = sqlite3_finalize(stmt);

    var rows = std.ArrayList([]const u8).init(allocator);
    defer {
        // In case of error, free any allocated strings
        for (rows.items) |row| {
            allocator.free(row);
        }
    }

    while (true) {
        const step_result = sqlite3_step(stmt);

        if (step_result == SQLITE_ROW) {
            const text_ptr = sqlite3_column_text(stmt, 0);
            const text = try allocator.dupe(u8, std.mem.span(text_ptr));
            try rows.append(text);
        } else if (step_result == SQLITE_DONE) {
            break;
        } else {
            return SqliteError.StepFailed;
        }
    }

    // Transfer ownership to caller
    const result = try rows.toOwnedSlice();
    return result;
}
