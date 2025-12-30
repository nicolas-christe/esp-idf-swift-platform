/*
 * Copyright (c) 2026 Nicolas Christe
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#pragma once

// ----------------------------------------------------------------------------
// ESP_COMMON 
// ----------------------------------------------------------------------------
#include <esp_err.h>              // Error codes and checking macros
#include <esp_attr.h>             // Compiler attributes (IRAM_ATTR, etc.)
#include <esp_bit_defs.h>         // Bit manipulation macros (BIT, etc.)
#include <esp_compiler.h>         // Compiler-specific definitions
#include <esp_assert.h>           // Assertion macros
#include <esp_check.h>            // Error checking macros (ESP_RETURN_ON_ERROR, etc.)
#include <esp_types.h>            // ESP standard types
#include <esp_idf_version.h>      // IDF version macros

// ----------------------------------------------------------------------------
// LOG 
// ----------------------------------------------------------------------------
#include <esp_log.h>              // Logging functions (ESP_LOGI, ESP_LOGE, etc.)

// ----------------------------------------------------------------------------
// HEAP 
// ----------------------------------------------------------------------------
#include <esp_heap_caps.h>        // Heap memory allocation with capabilities
#include <esp_heap_trace.h>       // Heap tracing for debugging

// ----------------------------------------------------------------------------
// FREERTOS 
// ----------------------------------------------------------------------------
#include <freertos/FreeRTOS.h>    // FreeRTOS core (must be included first)
#include <freertos/task.h>        // Task creation and management
#include <freertos/queue.h>       // Queue management
#include <freertos/semphr.h>      // Semaphores and mutexes
#include <freertos/timers.h>      // Software timers
#include <freertos/event_groups.h> // Event groups (flags)
#include <freertos/stream_buffer.h> // Stream buffers
#include <freertos/message_buffer.h> // Message buffers
#include <freertos/portmacro.h>   // Port-specific macros

// ----------------------------------------------------------------------------
// NEWLIB - Standard C Library (Always available)
// ----------------------------------------------------------------------------
#include <stdio.h>                // Standard I/O
#include <stdlib.h>               // Standard library
#include <string.h>               // String operations
#include <stdint.h>               // Standard integer types
#include <stdbool.h>              // Boolean type
#include <stddef.h>               // Standard definitions (NULL, size_t, etc.)
#include <inttypes.h>             // Integer type format macros
#include <time.h>                 // Time functions
#include <sys/time.h>             // System time
#include <sys/types.h>            // System types
#include <errno.h>                // Error numbers

// ----------------------------------------------------------------------------
// ESP_SYSTEM 
// ----------------------------------------------------------------------------
#include <esp_system.h>           // System functions (restart, MAC address, etc.)
#include <esp_task.h>             // Task utilities
#include <esp_task_wdt.h>         // Task watchdog timer
#include <esp_freertos_hooks.h>   // FreeRTOS idle/tick hooks
#include <esp_interface.h>        // Network interface types
#include <esp_chip_info.h>        // Chip information
#include <esp_cpu.h>              // CPU utilities
#include <esp_mac.h>              // MAC address functions
#include <esp_random.h>           // Random number generation

// ----------------------------------------------------------------------------
// ESP_HW_SUPPORT 
// ----------------------------------------------------------------------------
#include <esp_intr_alloc.h>       // Interrupt allocation
#include <esp_sleep.h>            // Sleep modes
#include <esp_clk_tree.h>         // Clock tree management

// ----------------------------------------------------------------------------
// SOC - SoC-specific (chip-dependent)
// ----------------------------------------------------------------------------
#include <soc/soc.h>              // SoC definitions
#include <soc/soc_caps.h>         // SoC capabilities
#include <soc/gpio_reg.h>         // GPIO register definitions
#include <soc/rtc.h>              // RTC definitions

// ----------------------------------------------------------------------------
// Usefull func macro that are not available in Swift 
// ----------------------------------------------------------------------------

__attribute__((swift_name("pdMS_TO_TICKS(_:)")))
uint32_t _pdMS_TO_TICKS(uint32_t xTimeInMs);

__attribute__((swift_name("ESP_ERROR_CHECK(_:)")))
void _esp_error_check(esp_err_t result);

// ----------------------------------------------------------------------------
// Logging functions 
// ----------------------------------------------------------------------------

__attribute__((swift_name("ESP_LOGE(_:_:)")))
void loge(const char *tag, const char *message);


__attribute__((swift_name("ESP_LOGW(_:_:)")))
void logw(const char *tag, const char *message);

__attribute__((swift_name("ESP_LOGI(_:_:)")))
void logi(const char *tag, const char *message);

__attribute__((swift_name("ESP_LOGD(_:_:)")))
void logd(const char *tag, const char *message);

__attribute__((swift_name("ESP_LOGV(_:_:)")))
void logv(const char *tag, const char *message);

// ----------------------------------------------------------------------------
// Event Group
// ----------------------------------------------------------------------------
void *eventGroupIrsArgsAllocate(EventGroupHandle_t eventGroup, uint32_t bitsToSet);
void eventGroupIsrHandler(void *arg);

// ----------------------------------------------------------------------------
// Task Notification
// ----------------------------------------------------------------------------
void *taskNotifyIrsArgsAllocate(TaskHandle_t taskHandle, uint32_t value, eNotifyAction action);
void taskNotifyIsrHandler(void *arg);