# Sanitizers catch what the type system and the warnings cannot: use-after-free,
# undefined behaviour, data races. They are off by default because they slow the
# build and the binary down; nightly-sanitizer.yml turns them on.
#
# Usage:
#   include(Sanitizers)
#   cppbp_set_sanitizers(mylib PRIVATE)

function(cppbp_set_sanitizers target visibility)
    if(MSVC)
        if(CPPBP_SANITIZE_ADDRESS)
            target_compile_options(${target} ${visibility} /fsanitize=address)
        endif()
        return()
    endif()

    set(enabled "")
    if(CPPBP_SANITIZE_ADDRESS)
        list(APPEND enabled address)
    endif()
    if(CPPBP_SANITIZE_UNDEFINED)
        list(APPEND enabled undefined)
    endif()
    if(CPPBP_SANITIZE_THREAD)
        list(APPEND enabled thread)
    endif()
    if(CPPBP_SANITIZE_MEMORY)
        list(APPEND enabled memory)
    endif()

    if(NOT enabled)
        return()
    endif()

    # address and thread cannot be combined; fail loudly instead of producing a
    # binary that silently checks less than the author thinks it does.
    if("address" IN_LIST enabled AND "thread" IN_LIST enabled)
        message(FATAL_ERROR "AddressSanitizer and ThreadSanitizer cannot be enabled together")
    endif()
    if("memory" IN_LIST enabled AND ("address" IN_LIST enabled OR "thread" IN_LIST enabled))
        message(FATAL_ERROR "MemorySanitizer cannot be combined with AddressSanitizer or ThreadSanitizer")
    endif()

    list(JOIN enabled "," joined)
    target_compile_options(${target} ${visibility} -fsanitize=${joined} -fno-omit-frame-pointer)
    target_link_options(${target} ${visibility} -fsanitize=${joined})
endfunction()
