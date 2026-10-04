# What the program knows. One directory per module, and this file is the whole
# of what each one may use.
#
# A module is a directory, a static library, and the header named after it. Its
# include path is its own directory plus the directories of the modules named in
# its target_link_libraries, so reaching for one that is not named there does not
# compile:
#
#   fatal error: 'presentation.hpp' file not found
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
# One hole is left, because the preprocessor resolves a quoted include relative
# to the file that writes it before it consults any include path at all:
# "../presentation/presentation.hpp" would reach past everything above and still
# link, since all of these end up in the same program.
# scripts/check-module-includes.sh is what closes it.

add_library(myapp_catalogue STATIC catalogue/catalogue.cpp)
target_include_directories(myapp_catalogue PUBLIC "${CMAKE_CURRENT_LIST_DIR}/catalogue")
# Raise this to cxx_std_26 and the CI matrix will tell you what breaks. Every
# module says it, because the standard a module is compiled with is part of what
# it hands to whatever links it.
target_compile_features(myapp_catalogue PUBLIC cxx_std_23)
cppbp_set_warnings(myapp_catalogue PRIVATE)
cppbp_set_sanitizers(myapp_catalogue PUBLIC)
cppbp_enable_clang_tidy(myapp_catalogue)

add_library(myapp_presentation STATIC presentation/presentation.cpp)
target_include_directories(myapp_presentation PUBLIC "${CMAKE_CURRENT_LIST_DIR}/presentation")
target_compile_features(myapp_presentation PUBLIC cxx_std_23)
target_link_libraries(myapp_presentation PUBLIC myapp_catalogue)
cppbp_set_warnings(myapp_presentation PRIVATE)
cppbp_set_sanitizers(myapp_presentation PUBLIC)
cppbp_enable_clang_tidy(myapp_presentation)

# The class QML binds to. Qt is PUBLIC because the header derives from
# QAbstractListModel and carries Q_OBJECT; presentation is PRIVATE because the
# model asks it how to render a row and says so in no header.
#
# AUTOMOC for the two modules that link Qt, and only those: moc is what turns a
# Q_OBJECT into something that links, and nothing in the other two can have one.
add_library(myapp_filtered_entries STATIC filtered_entries/filtered_entries.cpp)
set_target_properties(myapp_filtered_entries PROPERTIES AUTOMOC ON)
target_include_directories(myapp_filtered_entries
    PUBLIC "${CMAKE_CURRENT_LIST_DIR}/filtered_entries")
target_compile_features(myapp_filtered_entries PUBLIC cxx_std_23)
target_link_libraries(myapp_filtered_entries
    PUBLIC myapp_catalogue Qt6::Quick
    PRIVATE myapp_presentation)
cppbp_set_warnings(myapp_filtered_entries PRIVATE)
cppbp_set_sanitizers(myapp_filtered_entries PUBLIC)
cppbp_enable_clang_tidy(myapp_filtered_entries)

# Builds what the program is made of and runs it, which is why Qt is PRIVATE
# here: startup.hpp names an int and two arguments, so nothing that calls it
# needs Qt to compile. It names no other module - the QML it loads reaches it as
# a resource, from the module the executable links.
add_library(myapp_startup STATIC startup/startup.cpp)
set_target_properties(myapp_startup PROPERTIES AUTOMOC ON)
target_include_directories(myapp_startup
    PUBLIC "${CMAKE_CURRENT_LIST_DIR}/startup"
    # <myapp/version.hpp>, which --version prints. PRIVATE, like Qt below: it is
    # read by the implementation and named in no header.
    PRIVATE "${MYAPP_GENERATED_DIR}")
target_compile_features(myapp_startup PUBLIC cxx_std_23)
target_link_libraries(myapp_startup PRIVATE Qt6::Quick)
cppbp_set_warnings(myapp_startup PRIVATE)
cppbp_set_sanitizers(myapp_startup PUBLIC)
cppbp_enable_clang_tidy(myapp_startup)
