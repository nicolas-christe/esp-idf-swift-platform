idf_component_register(
    SRCS
        Sources/Platform.swift
        Sources/TickType+Extensions.swift
        Sources/Logger.swift
        Sources/Task.swift
        Sources/IsrHandler.swift
        Sources/EventGroup.swift
        platform.c
    INCLUDE_DIRS "."
    REQUIRES
)

swift_configure_component("Platform")

# Export Swift-accessible logging defines derived from sdkconfig's
# CONFIG_LOG_MAXIMUM_LEVEL. We export per-level Swift compile-time
# flags (mapping: ERROR=1, WARN=2, INFO=3, DEBUG=4, VERBOSE=5) as
# `LOG_<LEVEL>_ENABLED` defines usable from Swift with
# `#if LOG_INFO_ENABLED` or similar.
if(DEFINED CONFIG_LOG_MAXIMUM_LEVEL)
    # Per-level boolean defines (mapping: ERROR=1, WARN=2, INFO=3, DEBUG=4, VERBOSE=5)
    if(CONFIG_LOG_MAXIMUM_LEVEL GREATER_EQUAL 1)
        target_compile_options(${COMPONENT_LIB} PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:-DLOG_ERROR_ENABLED>")
    endif()
    if(CONFIG_LOG_MAXIMUM_LEVEL GREATER_EQUAL 2)
        target_compile_options(${COMPONENT_LIB} PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:-DLOG_WARN_ENABLED>")
    endif()
    if(CONFIG_LOG_MAXIMUM_LEVEL GREATER_EQUAL 3)
        target_compile_options(${COMPONENT_LIB} PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:-DLOG_INFO_ENABLED>")
    endif()
    if(CONFIG_LOG_MAXIMUM_LEVEL GREATER_EQUAL 4)
        target_compile_options(${COMPONENT_LIB} PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:-DLOG_DEBUG_ENABLED>")
    endif()
    if(CONFIG_LOG_MAXIMUM_LEVEL GREATER_EQUAL 5)
        target_compile_options(${COMPONENT_LIB} PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:-DLOG_VERBOSE_ENABLED>")
    endif()
endif()
