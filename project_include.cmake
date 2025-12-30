# Only enable Swift once
if(NOT DEFINED CMAKE_Swift_COMPILER)
    set(CMAKE_Swift_COMPILER_WORKS YES)
    set(CMAKE_Swift_COMPILATION_MODE_DEFAULT wholemodule)
    set(CMAKE_Swift_COMPILATION_MODE wholemodule)
        
    enable_language(Swift)

    # Override the linker command to use the C++ compiler (g++) instead of swiftc.
    # This avoids issues where swiftc rejects flags like -Wl,--cref which are passed by ESP-IDF.
    # It also ensures proper linking of C++ components (Matter).
    set(CMAKE_Swift_LINK_EXECUTABLE "${CMAKE_CXX_COMPILER} <FLAGS> <CMAKE_Swift_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
endif()

macro(swift_configure_component)
    # Optional first argument: swift module name. If empty, fall back to COMPONENT_NAME.
    set(module_name "${ARGN}")
    if("${module_name}" STREQUAL "")
        set(module_name "${COMPONENT_NAME}")
    endif()

    # Default module map filename
    set(module_map "module.modulemap")

    # Disable attribute warnings use to name swift functions in C/C++ headers
    target_compile_options(${COMPONENT_LIB} PRIVATE -Wno-attributes)

    # Clear default COMPILE_OPTIONS which include a lot of C/C++ specific compiler flags that the Swift compiler will not accept
    # However, we must preserve them for C/C++ sources if this is a mixed component.
    get_target_property(existing_options ${COMPONENT_LIB} COMPILE_OPTIONS)
    if(existing_options)
        set_target_properties(${COMPONENT_LIB} PROPERTIES COMPILE_OPTIONS "")
        target_compile_options(${COMPONENT_LIB} PRIVATE "$<$<COMPILE_LANGUAGE:C,CXX>:${existing_options}>")
    endif()

    # Collect -D defines from existing COMPILE_OPTIONS and COMPILE_DEFINITIONS
    # and forward them to swiftc as `-Xcc -D...` so Swift sees the same macros
    set(SWIFT_DEFINES_LIST)
    set(SWIFT_INCLUDES_LIST)
    
    # Extract -D flags from compile options
    foreach(opt IN LISTS existing_options)
        if(opt MATCHES "^-D")
            list(APPEND SWIFT_DEFINES_LIST "-Xcc" "${opt}")
        endif()
    endforeach()

    # Extract compile definitions from target property
    get_target_property(existing_defs ${COMPONENT_LIB} COMPILE_DEFINITIONS)
    if(existing_defs AND NOT existing_defs STREQUAL "existing_defs-NOTFOUND")
        foreach(def IN LISTS existing_defs)
            # def may be NAME or NAME=VALUE; pass as -DNAME or -DNAME=VALUE
            list(APPEND SWIFT_DEFINES_LIST "-Xcc" "-D${def}")
        endforeach()
    endif()

    # Forward include dirs from this target and linked targets
    get_target_property(this_includes ${COMPONENT_LIB} INCLUDE_DIRECTORIES)
    if(this_includes AND NOT this_includes STREQUAL "this_includes-NOTFOUND")
        foreach(d IN LISTS this_includes)
            list(APPEND SWIFT_INCLUDES_LIST "-Xcc" "-I${d}")
        endforeach()
    endif()
    
    get_target_property(this_iface_includes ${COMPONENT_LIB} INTERFACE_INCLUDE_DIRECTORIES)
    if(this_iface_includes AND NOT this_iface_includes STREQUAL "this_iface_includes-NOTFOUND")
        foreach(d IN LISTS this_iface_includes)
            list(APPEND SWIFT_INCLUDES_LIST "-Xcc" "-I${d}")
        endforeach()
    endif()
    
    # Collect transitive defines from linked targets
    get_target_property(linked_libs ${COMPONENT_LIB} LINK_LIBRARIES)
    if(linked_libs AND NOT linked_libs STREQUAL "linked_libs-NOTFOUND")
        foreach(lib IN LISTS linked_libs)
            if(TARGET ${lib})
                # Interface compile definitions
                get_target_property(lib_iface_defs ${lib} INTERFACE_COMPILE_DEFINITIONS)
                if(lib_iface_defs AND NOT lib_iface_defs STREQUAL "lib_iface_defs-NOTFOUND")
                    foreach(d IN LISTS lib_iface_defs)
                        list(APPEND SWIFT_DEFINES_LIST "-Xcc" "-D${d}")
                    endforeach()
                endif()
    
                # Interface include dirs from the linked target
                get_target_property(lib_iface_includes ${lib} INTERFACE_INCLUDE_DIRECTORIES)
                if(lib_iface_includes AND NOT lib_iface_includes STREQUAL "lib_iface_includes-NOTFOUND")
                    foreach(d IN LISTS lib_iface_includes)
                        list(APPEND SWIFT_INCLUDES_LIST "-Xcc" "-I${d}")
                    endforeach()
                endif()
            endif()
        endforeach()
    endif()
    # Join all defines into a single string
    list(JOIN SWIFT_DEFINES_LIST " " SWIFT_DEFINES)

    # Compute -Xcc flags to set up the C and C++ header search paths for Swift (for modulemap).
    # We append implicit directories to the existing list of includes.
    foreach(dir ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES} ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
        list(APPEND SWIFT_INCLUDES_LIST "-Xcc" "-I${dir}")
    endforeach()
    list(JOIN SWIFT_INCLUDES_LIST " " SWIFT_INCLUDES)

    # Only add module map flag if the module map file actually exists
    set(MODULE_MAP_FLAG "")
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${module_map}")
        set(MODULE_MAP_FLAG "-Xcc -fmodule-map-file=${CMAKE_CURRENT_LIST_DIR}/${module_map}")
    endif()

    # Extract the -march flag from CMAKE_C_FLAGS and remove any vendor-specific extensions (_x*)
    # This ensures we match the target architecture (e.g. rv32imc vs rv32imac) automatically.
    string(REGEX MATCH "-march=[^ ]+" march_flag "${CMAKE_C_FLAGS}")
    string(REGEX REPLACE "_x[^ ]*" "" march_flag "${march_flag}")

    # Extract the -mabi flag or set a default value if not present
    string(REGEX MATCH "-mabi=[^ ]+" mabi_flag "${CMAKE_C_FLAGS}")
    if("${mabi_flag}" STREQUAL "")
        set(mabi_flag "-mabi=ilp32")
    endif()

    # Swift compiler flags to build in Embedded Swift mode, optimize for size, choose the right ISA, ABI, C++ language standard, etc.
    target_compile_options(${COMPONENT_LIB} PRIVATE "$<$<COMPILE_LANGUAGE:Swift>:SHELL:
        -target riscv32-none-none-eabi
        -Xfrontend -function-sections -enable-experimental-feature Embedded -wmo -parse-as-library -Osize
        -color-diagnostics
        -Xcc ${march_flag}
        -Xcc ${mabi_flag}
        -Xcc -fno-pic
        -Xllvm -relocation-model=static
        -pch-output-dir /tmp
        -Xfrontend -enable-single-module-llvm-emission
        ${SWIFT_INCLUDES}
        ${MODULE_MAP_FLAG}
        ${SWIFT_DEFINES}
        -module-name ${module_name}
        -emit-module
        -emit-module-path ${CMAKE_CURRENT_BINARY_DIR}/${module_name}.swiftmodule
    >")

    # remove the .swift_modhash section from the final binary to save space. This is only useful for the main component 
    add_custom_command(
        TARGET ${COMPONENT_LIB}
        POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash
                $<TARGET_FILE:${COMPONENT_LIB}> $<TARGET_FILE:${COMPONENT_LIB}>
    )
endmacro()