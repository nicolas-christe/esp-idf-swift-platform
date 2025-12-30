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

#include "platform.h"

// ----------------------------------------------------------------------------
// Usefull func macro that are not available in Swift 
// ----------------------------------------------------------------------------

uint32_t _pdMS_TO_TICKS(uint32_t xTimeInMs)
{
    return pdMS_TO_TICKS(xTimeInMs);
}

void _esp_error_check(esp_err_t result)
{
    ESP_ERROR_CHECK(result);
}

// ----------------------------------------------------------------------------
// Logging functions 
// ----------------------------------------------------------------------------

void loge(const char *tag, const char *message)
{
    ESP_LOGE(tag, "%s", message);
}

void logw(const char *tag, const char *message)
{
    ESP_LOGW(tag, "%s", message);
}

void logi(const char *tag, const char *message)
{
    ESP_LOGI(tag, "%s", message);
}

void logd(const char *tag, const char *message)
{
    ESP_LOGD(tag, "%s", message);
}

void logv(const char *tag, const char *message)
{
    ESP_LOGV(tag, "%s", message);
}

// ----------------------------------------------------------------------------
// Event Group
// ----------------------------------------------------------------------------
typedef struct EventGroupIsrArg_t
{
    EventGroupHandle_t eventGroup;
    EventBits_t bitsToSet;
} EventGroupIsrArg_t;

void *eventGroupIrsArgsAllocate(EventGroupHandle_t eventGroup, uint32_t bitsToSet)
{
    EventGroupIsrArg_t *args = (EventGroupIsrArg_t *)heap_caps_malloc(sizeof(EventGroupIsrArg_t), MALLOC_CAP_INTERNAL);
    if (args == NULL)
    {
        return NULL;
    }
    args->eventGroup = eventGroup;
    args->bitsToSet = bitsToSet;
    return args;
}

void IRAM_ATTR eventGroupIsrHandler(void *arg)
{
    EventGroupIsrArg_t *eventGroup = (EventGroupIsrArg_t *)arg;
    BaseType_t xHigherPriorityTaskWoken, xResult;
    xHigherPriorityTaskWoken = pdFALSE;
    xResult = xEventGroupSetBitsFromISR(eventGroup->eventGroup, eventGroup->bitsToSet, &xHigherPriorityTaskWoken);
    if (xResult != pdFAIL)
    {
        portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
    }
}

// ----------------------------------------------------------------------------
// Task Notification
// ----------------------------------------------------------------------------
typedef struct NotifyIsrArg_t
{
    TaskHandle_t taskHandle; /*!< Handle of the task to notify */
    uint32_t value;          /*!< Value to notify */
    eNotifyAction action;    /*!< Action to perform on the task notification */
} NotifyIsrArg_t;

void *taskNotifyIrsArgsAllocate(TaskHandle_t taskHandle, uint32_t value, eNotifyAction action)
{
    NotifyIsrArg_t *args = (NotifyIsrArg_t *)heap_caps_malloc(sizeof(NotifyIsrArg_t), MALLOC_CAP_INTERNAL);
    if (args == NULL)
    {
        return NULL;
    }
    args->taskHandle = taskHandle;
    args->value = value;
    args->action = action;
    return args;
}

void IRAM_ATTR taskNotifyIsrHandler(void *arg)
{
    NotifyIsrArg_t *notification = (NotifyIsrArg_t *)arg;
    BaseType_t xHigherPriorityTaskWoken, xResult;
    xResult = xTaskNotifyFromISR(notification->taskHandle, notification->value, notification->action, &xHigherPriorityTaskWoken);
    if (xResult != pdFAIL)
    {
        portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
    }
}