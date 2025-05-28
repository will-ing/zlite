# zlite

A lightweight SQLite wrapper for the Zig programming language that provides a simple, memory-safe interface to SQLite operations.

## Features

- Simple SQLite database operations
- Memory-safe wrapper around the SQLite C API
- Support for basic SQL operations (open, exec, query)
- Built-in error handling with Zig's error system
- Minimal API surface for ease of use
- Allocator-aware design

## Prerequisites

- [Zig compiler](https://ziglang.org/download/) (tested with the latest version)
- SQLite3 development libraries
  - On Arch Linux: `pacman -S sqlite`
  - On Ubuntu/Debian: `apt install libsqlite3-dev`
  - On macOS: `brew install sqlite`
- C compiler (for linking with SQLite)

## Installation

### As a dependency in your Zig project

1. Add zlite to your `build.zig.zon` file:

```zig
.{
    .name = "your-project",
    .version = "0.1.0",
    .dependencies = .{
        .zlite = .{
            .url = "https://github.com/yourusername/zlite/archive/refs/tags/v0.1.0.tar.gz",
            // Add hash after first successful build
        },
    },
}
```

2. Update your `build.zig` to include zlite:

```zig
const zlite_dep = b.dependency("zlite", .{
    .target = target,
    .optimize = optimize,
});

const zlite_module = zlite_dep.module("zlite");
exe.addModule("zlite", zlite_module);
exe.linkLibC();
exe.linkSystemLibrary("sqlite3");
```

### Manual Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/zlite.git
cd zlite
```

## Usage

Here's a basic example demonstrating how to use zlite:

```zig
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
```

## Build Instructions

### Building the Library

To build the static library:

```bash
zig build
```

This will create a static library in `zig-out/lib/libzlite.a`.

### Running the Example

To build and run the example:

```bash
zig build run
```

This will:
1. Build the zlite library
2. Build the example executable
3. Run the example, which creates a SQLite database, adds data, and queries it

### Available Build Commands

- `zig build` - Build the library and example
- `zig build run` - Build and run the example

## Project Structure

```
zlite/
├── build.zig         # Zig build script
├── build.zig.zon     # Zig package manifest
├── src/
│   ├── lib.zig       # The main library code with SQLite bindings
│   └── main.zig      # Example usage
└── README.md         # This file
```

### Library Design

- `lib.zig` - Contains the core SQLite wrapper functionality:
  - Foreign function declarations for SQLite C API
  - Error type definitions
  - Database struct with open/close/exec methods
  - Query function for retrieving data

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

