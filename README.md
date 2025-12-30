# SwiftPlatform

This component provides the build integration and C interoperability shims required to compile and link Swift code for ESP-IDF targets.

This component provide required CMake macro to build Swift code and export main ESP-IDF components to swift.

It also provide Swift Helpers for some ESP-IDF API.

## Status

This is an initial implementation of SwiftPlatform. It provides basic functionality and will be extended with additional features in future updates.

## How to use it

in `main/CMakeLists.txt` registering the Swift sources and add `swift_configure_component()`

```
idf_component_register(
	SRCS
		Main.swift
	INCLUDE_DIRS
		.
)

swift_configure_component()
```

## Including C code: module.modulemap and module names

If your component includes C headers or C sources you want to import from Swift, expose them via a Clang module using a `module.modulemap`. Place the `module.modulemap` file in the component directory (the same directory as the component `CMakeLists.txt`) so `swift_configure_component()` can pick it up automatically.

Minimal `module.modulemap` example (file: `components/MyComponent/module.modulemap`):

```
module My_C_Module [system] {
		umbrella header "my_header.h"
		export *
}
```

Notes:
- `My_C_Module` is the module name that you will `import` from Swift (`import My_C_Module`).
- The `umbrella header` should include (or `#include`) the public C headers you want visible to Swift.
- Use `[system]` if the headers are system-style or to avoid implicit header search behavior; omit it for a normal module.

Exposing C symbols and attributes:
- Annotate C functions or types in headers if you want nicer Swift names using `__attribute__((swift_name("...")))`.
- For Swift to call C functions that are implemented in C, declare them in headers included by the module map.

Then you can write `main/CMakeLists.txt`:

```
import Platform
@_cdecl("app_main")
func main() {
}
```

## Details on the provided Swift helpers

This component ships a small set of Swift helper:

- `Logger.swift`:
	- Lightweight Swift wrapper around ESP-IDF logging.
	- Provides a `Logger` struct you instantiate with a tag, and methods `v`, `d`, `i`, `w`, `e` for verbose/debug/info/warn/error logging.
	- Each method uses compile-time flags (exported from the component CMake) such as `LOG_INFO_ENABLED` to avoid evaluating message closures when that log level is disabled.
	- Example:

```
let log = Logger(tag: "MyTag")
log.i("Started")
```

- `Task.swift`:
	- A small class that wraps creating FreeRTOS tasks from Swift using `xTaskCreate`.
	- The `run(name:stackSize:priority:entry:)` method retains the Swift `Task` instance and provides a C-compatible entry that converts the opaque pointer back to the Swift instance and runs the closure. The FreeRTOS task deletes itself after the closure returns.
	- Example:

```
let t = Task()
t.run(name: "worker", stackSize: 4096, priority: 5) {
		// background work
}
```

- `TickType+Extensions.swift`:
	- Adds a convenience initializer to `TickType_t` to construct RTOS tick counts from an optional millisecond value.
	- `TickType_t(ms: 100)` converts to `pdMS_TO_TICKS(100)`. Passing `nil` yields `portMAX_DELAY`.
	- Use this when adapting Swift APIs that accept optional timeouts.

- `EventGroup.swift`:
	- A Swift wrapper around FreeRTOS event groups.
	- Provides a generic `EventGroup` class that works with `OptionSet` types for event bits.
	- Methods for waiting on event bits with optional timeouts, setting event bits, and creating ISR handlers for setting bits from interrupts.
	- Example:

```
enum MyEvents: UInt32, OptionSet {
    case event1 = 1
    case event2 = 2
}

guard let eg = EventGroup<MyEvents>() else { fatalError() }
eg.set(.event1)
let bits = eg.wait(.event1, timeoutMs: 1000)
```

- `IsrHandler.swift`:
	- A utility class for managing ISR (Interrupt Service Routine) handlers.
	- Wraps a C-compatible handler function and its arguments, handling memory allocation and deallocation.
	- Used internally by `EventGroup` for ISR-based event setting.

- `Platform.swift`:
	- Exports the `ESP_Platform` C module for use in Swift code.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
