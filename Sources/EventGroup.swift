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

/// A Swift wrapper around FreeRTOS event groups.
/// 
/// This class provides a type-safe interface to FreeRTOS event groups, allowing you to wait for and set event bits
/// using Swift `OptionSet` types. Event groups are useful for synchronizing tasks and handling asynchronous events.
/// 
/// Example usage:
/// ```swift
/// enum MyEvents: UInt32, OptionSet {
///     case event1 = 1
///     case event2 = 2
/// }
/// 
/// guard let eg = EventGroup<MyEvents>() else { fatalError("Failed to create event group") }
/// eg.set(.event1)
/// let bits = eg.wait(.event1, timeoutMs: 1000)
/// ```
public final class EventGroup<EventBits> where EventBits: OptionSet, EventBits.RawValue == UInt32 {
    /// The underlying FreeRTOS event group handle
    private let eventGroup: EventGroupHandle_t

    /// Creates a new event group.
    /// 
    /// - Returns: An `EventGroup` instance if creation succeeds, `nil` if memory allocation fails.
    public init?() {
        guard let eventGroup = xEventGroupCreate() else {
            return nil
        }
        self.eventGroup = eventGroup
    }

    deinit {
        vEventGroupDelete(eventGroup)
    }

    /// Waits for the specified event bits to be set.
    /// 
    /// This method blocks the current task until all specified event bits are set or the timeout expires.
    /// The event bits are automatically cleared after being read.
    /// 
    /// - Parameters:
    ///   - events: The event bits to wait for. All bits must be set for the wait to succeed.
    ///   - timeoutMs: The maximum time to wait in milliseconds. If `nil`, waits indefinitely.
    /// - Returns: The event bits that were set at the time of return.
    public func wait(_ events: EventBits..., timeoutMs: UInt32? = nil) -> EventBits {
        EventBits(
            rawValue: xEventGroupWaitBits(
                eventGroup, EventBits_t(events), 1, 0, TickType_t(ms: timeoutMs)))
    }

    /// Sets the specified event bits.
    /// 
    /// This method can be called from tasks or ISRs to set event bits, potentially unblocking waiting tasks.
    /// 
    /// - Parameter events: The event bits to set.
    public func set(_ events: EventBits...) {
        xEventGroupSetBits(eventGroup, EventBits_t(events))
    }

    /// Creates an ISR handler that sets the specified event bits when called from an interrupt.
    /// 
    /// Use this method to create a handler that can be installed in an ISR to set event bits without
    /// the restrictions of ISR-safe functions.
    /// 
    /// - Parameter events: The event bits to set when the handler is called.
    /// - Returns: An `IsrHandler` instance that can be used to set the event bits from an ISR.
    public func isrHandler(setting events: EventBits...) -> IsrHandler {
        IsrHandler(
            handler: eventGroupIsrHandler,
            args: eventGroupIrsArgsAllocate(eventGroup, EventBits_t(events)))
    }
}

extension EventBits_t {
    fileprivate init<EventBits>(_ eventBits: [EventBits]) where EventBits: OptionSet, EventBits.RawValue == UInt32 {
        self = EventBits_t(eventBits.reduce(0) { $0 | $1.rawValue })
    }
}
