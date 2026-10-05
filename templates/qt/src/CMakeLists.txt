# What the program knows. One directory per module, and this file is the whole
# of what each one may use.
#
# A module is a directory, a static library, and the header named after it. Its
# include path is its own directory plus the directories of the modules named in
# its target_link_libraries, so reaching for one that is not named there does not
# compile:
#
#   fatal error: presentation.hpp: No such file or directory
#
# That is what the extra targets buy. One library over the whole of src/ puts
# every header on every file's include path, and the dependencies between the
# pieces become whatever the code happens to do rather than something anybody
# decided.
#
# Qt is declared the same way, and that is the line this template is built
# around: catalogue and presentation do not name it, so a QString in either one
# is a compile error rather than a review comment, and their tests run with no
# QGuiApplication.
#
# The QML module and the executable are not here. They are what Qt generates
# around this code, and the directory they are defined in is the one the
# sanitizer and clang-tidy exclusions up there are written against.
#
# One hole is left: an include can name a path rather than a name -
# "../presentation/presentation.hpp" - and reach a header this include path
# never offered, since all of these end up in the same program. Which paths are
# refused, and why each one, is in scripts/check-module-includes.sh.

# What every module is, so that a module is a name and not six lines to keep in
# step with the others. A module that leaves out cppbp_enable_clang_tidy would
# be unchecked and nothing would say so; here it cannot.
#
# CMAKE_CURRENT_SOURCE_DIR rather than CMAKE_CURRENT_LIST_DIR: inside a function
# the latter is the file being processed when the function is called.
#
# A module with a second source file adds it after the call with
# target_sources. One with no source file at all is not this function's shape:
# an INTERFACE library is, and it is three lines written out.
function(myapp_add_module name)
    add_library(myapp_${name} STATIC ${name}/${name}.cpp)
    target_include_directories(myapp_${name} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${name}")
    # Raise this to cxx_std_26 and the CI matrix will tell you what breaks. Every
    # module says it, because the standard a module is compiled with is part of
    # what it hands to whatever links it.
    target_compile_features(myapp_${name} PUBLIC cxx_std_23)
    cppbp_set_warnings(myapp_${name} PRIVATE)
    cppbp_set_sanitizers(myapp_${name} PUBLIC)
    cppbp_enable_clang_tidy(myapp_${name})
endfunction()

# What each module may use is below, and it is the whole of the graph.
myapp_add_module(catalogue)

myapp_add_module(presentation)
target_link_libraries(myapp_presentation PUBLIC myapp_catalogue)

# The class QML binds to. Qt is PUBLIC because the header derives from
# QAbstractListModel and carries Q_OBJECT; presentation is PRIVATE because the
# model asks it how to render a row and says so in no header.
#
# AUTOMOC for the two modules that link Qt, and only those: moc is what turns a
# Q_OBJECT into something that links, and nothing in the other two can have one.
myapp_add_module(filtered_entries)
set_target_properties(myapp_filtered_entries PROPERTIES AUTOMOC ON)
target_link_libraries(myapp_filtered_entries
    PUBLIC myapp_catalogue Qt6::Quick
    PRIVATE myapp_presentation)

# Builds what the program is made of and runs it, which is why Qt is PRIVATE
# here: startup.hpp names an int and two arguments, so nothing that calls it
# needs Qt to compile. It names no other module - the QML it loads reaches it as
# a resource, from the module the executable links.
myapp_add_module(startup)
set_target_properties(myapp_startup PROPERTIES AUTOMOC ON)
target_include_directories(myapp_startup
    # <myapp/version.hpp>, which --version prints. PRIVATE, like Qt below: it is
    # read by the implementation and named in no header.
    PRIVATE "${MYAPP_GENERATED_DIR}")
target_link_libraries(myapp_startup PRIVATE Qt6::Quick)
