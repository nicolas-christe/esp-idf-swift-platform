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

/// Utilities for working with RTOS tick counts.
///
/// The initializer below converts an optional millisecond value into a
/// `TickType_t` (RTOS ticks). Passing `nil` yields `portMAX_DELAY`.
extension TickType_t {
    /// Create a `TickType_t` from an optional millisecond duration.
    ///
    /// - Parameter ms: Milliseconds to convert. Use `nil` for an indefinite delay.
    /// - Note: Conversion uses `pdMS_TO_TICKS(ms)`. `nil` maps to `portMAX_DELAY`.
    public init(ms: UInt32?) {
        if let ms {
            self = pdMS_TO_TICKS(ms)
        } else {
            self = portMAX_DELAY
        }
    }
}
