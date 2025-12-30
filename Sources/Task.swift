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

public final class Task {
    private var entry: (() -> Void)?

    /// The FreeRTOS task handle, set after calling `run()`
    private var handle: TaskHandle_t?

    public init() {
    }

    public func run(name: String, stackSize: UInt32, priority: UInt32, entry: @escaping () -> Void) -> BaseType_t {
        self.entry = entry
        return xTaskCreate(
            {
                // Convert the raw pointer to a managed Swift reference and
                // ensure it is released before deleting the FreeRTOS task.
                do {
                    let task = Unmanaged<Task>.fromOpaque($0!).takeRetainedValue()
                    task.entry?()
                    task.handle = nil
                }
                // Drop to here so `task` is released by ARC, then delete the RTOS task.
                vTaskDelete(nil)
            }, name, stackSize, Unmanaged.passRetained(self).toOpaque(), priority, &handle)
    }

    public func notify() {
        notify(0)
    }

    public struct Notifier {
        private let task: Task
        public init(task: Task) {
            self.task = task
        }
        public func callAsFunction() {
            task.notify()
        }
    }

    public func notifier() -> Notifier {
        Notifier(task: self)
    }

    public func notify<NotificationBits>(_ notificationBits: [NotificationBits])
    where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
        notify(notificationBits.reduce(0) { $0 | $1.rawValue })
    }

    public func notify<NotificationBits>(_ notificationBits: NotificationBits...)
    where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
        notify(notificationBits)
    }

    public struct EventsNotifier {
        private let task: Task
        private let notificationBits: UInt32

        public init<NotificationBits>(task: Task, notificationBits: [NotificationBits])
        where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
            self.task = task
            self.notificationBits = notificationBits.reduce(0) { $0 | $1.rawValue }
        }

        public func callAsFunction() {
            task.notify(notificationBits)
        }
    }

    public func notifier<NotificationBits>(_ notificationBits: [NotificationBits]) -> EventsNotifier
    where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
        return EventsNotifier(task: self, notificationBits: notificationBits)
    }

    public func notifier<NotificationBits>(_ notificationBits: NotificationBits...) -> EventsNotifier
    where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
        return notifier(notificationBits)
    }

    public static func waitNotification(timeoutMs: UInt32? = nil) -> UInt32 {
        ulTaskGenericNotifyTake(0, 1, TickType_t(ms: timeoutMs))
    }

    public static func waitNotification<NotificationBits>() -> NotificationBits
    where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
        var notifyValue: UInt32 = 0
        xTaskGenericNotifyWait(0, 0, 0xFFFF_FFFF, &notifyValue, portMAX_DELAY)
        return NotificationBits(rawValue: notifyValue)
    }

    /// Internal notification implementation that sends raw event bits.
    ///
    /// - Parameter events: The raw UInt32 notification bits to set using bitwise OR
    private func notify(_ events: UInt32) {
        xTaskGenericNotify(handle, 0, events, eSetBits, nil)
    }

    func notifyIsrHandler<NotificationBits>(_ notificationBits: [NotificationBits]) -> IsrHandler
    where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
        guard let handle = handle else {
            fatalError("Task must be run before calling notifyIsrHandler")
        }
        return IsrHandler(
            handler: taskNotifyIsrHandler,
            args: taskNotifyIrsArgsAllocate(handle, notificationBits.reduce(0) { $0 | $1.rawValue }, eSetBits))
    }

    func notifyIsrHandler<NotificationBits>(_ notificationBits: NotificationBits...) -> IsrHandler
    where NotificationBits: OptionSet, NotificationBits.RawValue == UInt32 {
        notifyIsrHandler(notificationBits)
    }
}
