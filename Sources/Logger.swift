// Copyright (c) 2026 Nicolas Christe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// Lightweight wrapper around ESP-IDF logging for Swift.
///
/// Create a `Logger` with a tag and call the level methods to emit
/// logs. Each method is a no-op unless the corresponding compile-time
/// `LOG_<LEVEL>_ENABLED` flag is set in the component build.
public struct Logger {
    /// The logging tag used for ESP logs.
    let tag: String

    /// Initialize a logger for a specific tag.
    /// - Parameter tag: Short identifier (C string) used by ESP logging.
    public init(tag: String) {
        self.tag = tag
    }

    /// Set the runtime log level for this tag.
    /// - Parameter level: `esp_log_level_t` value to apply.
    public func setLogLevel(_ level: esp_log_level_t) {
        esp_log_level_set(tag, level)
    }

    /// Verbose log. Evaluates `message` only when the verbose flag is enabled.
    @inline(__always) public func v(_ message: @autoclosure () -> String) {
        #if LOG_VERBOSE_ENABLED
        ESP_LOGV(tag, message())
        #endif
    }

    /// Debug log. Evaluates `message` only when the debug flag is enabled.
    @inline(__always) public func d(_ message: @autoclosure () -> String) {
        #if LOG_DEBUG_ENABLED
        ESP_LOGD(tag, message())
        #endif
    }

    /// Info log. Evaluates `message` only when the info flag is enabled.
    @inline(__always) public func i(_ message: @autoclosure () -> String) {
        #if LOG_INFO_ENABLED
        ESP_LOGI(tag, message())
        #endif
    }

    /// Warning log. Evaluates `message` only when the warn flag is enabled.
    @inline(__always) public func w(_ message: @autoclosure () -> String) {
        #if LOG_WARN_ENABLED
        ESP_LOGW(tag, message())
        #endif
    }

    /// Error log. Evaluates `message` only when the error flag is enabled.
    @inline(__always) public func e(_ message: @autoclosure () -> String) {
        #if LOG_ERROR_ENABLED
        ESP_LOGE(tag, message())
        #endif
    }
}