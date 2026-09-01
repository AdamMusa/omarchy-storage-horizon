cmake_minimum_required(VERSION 3.21)

project(OmarchyUICompiledBundle LANGUAGES CXX)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_library(omarchy_ui_bundle_bf99be4fb7f1c6b7c992b SHARED)
qt_add_qml_module(omarchy_ui_bundle_bf99be4fb7f1c6b7c992b
  URI OmarchyUI.Bundles.Bf99be4fb7f1c6b7c992b
  VERSION 1.0
  OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/OmarchyUI/Bundles/Bf99be4fb7f1c6b7c992b"
  QML_FILES
    "App.qml"
    "BarWidget.qml"
    "Components/Builtins/ActionButton.qml"
    "Components/Builtins/Column.qml"
    "Components/Builtins/Container.qml"
    "Components/Builtins/Icon.qml"
    "Components/Builtins/Progress.qml"
    "Components/Builtins/Row.qml"
    "Components/Builtins/Scroll.qml"
    "Components/Builtins/Separator.qml"
    "Components/Builtins/Text.qml"
    "ControlNode.qml"
    "Controls/BarIconButton.qml"
    "Controls/BarIndicator.qml"
    "Controls/BorderOverlay.qml"
    "Controls/BorderSurface.qml"
    "Controls/Button.qml"
    "Controls/ButtonGroup.qml"
    "Controls/ConfirmDialog.qml"
    "Controls/CursorSurface.qml"
    "Controls/Dropdown.qml"
    "Controls/MultiSelect.qml"
    "Controls/NumberField.qml"
    "Controls/OpticalGlyph.qml"
    "Controls/PanelActionButton.qml"
    "Controls/PanelHero.qml"
    "Controls/PanelKeyCatcher.qml"
    "Controls/PanelSectionHeader.qml"
    "Controls/PanelSeparator.qml"
    "Controls/PanelSlider.qml"
    "Controls/PanelToolTip.qml"
    "Controls/SearchableDropdown.qml"
    "Controls/TextField.qml"
    "Controls/Toggle.qml"
    "Controls/ToggleSwitch.qml"
    "Controls/WidgetButton.qml"
    "Panel.qml"
    "Service.qml"
    "Theme/Border.qml"
    "Theme/Color.qml"
    "Theme/Fonts.qml"
    "Theme/Style.qml"
    "Theme/Util.qml"
  RESOURCES
    "Controls/qmldir"
    "Fonts/FontAwesome-Brands.otf"
    "Fonts/FontAwesome-Solid.otf"
    "Fonts/LICENSE-FontAwesome.txt"
    "Fonts/LICENSE-RobotoMono.txt"
    "Fonts/RobotoMono-Bold.otf"
    "Fonts/RobotoMono-Regular.otf"
    "Theme/qmldir"
  DISCARD_QML_CONTENTS
  NO_LINT
)

set(module_output "${CMAKE_BINARY_DIR}/OmarchyUI/Bundles/Bf99be4fb7f1c6b7c992b")
set_target_properties(
  omarchy_ui_bundle_bf99be4fb7f1c6b7c992b
  omarchy_ui_bundle_bf99be4fb7f1c6b7c992bplugin
  PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${module_output}"
    BUILD_RPATH "\$ORIGIN"
    BUILD_WITH_INSTALL_RPATH TRUE
    INSTALL_RPATH "\$ORIGIN"
)

target_compile_options(
  omarchy_ui_bundle_bf99be4fb7f1c6b7c992b
  PRIVATE
    "-ffile-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}=."
    "-ffile-prefix-map=${CMAKE_CURRENT_BINARY_DIR}=."
)
target_compile_options(
  omarchy_ui_bundle_bf99be4fb7f1c6b7c992bplugin
  PRIVATE
    "-ffile-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}=."
    "-ffile-prefix-map=${CMAKE_CURRENT_BINARY_DIR}=."
)
target_link_options(omarchy_ui_bundle_bf99be4fb7f1c6b7c992b PRIVATE "-Wl,--build-id=none")
target_link_options(omarchy_ui_bundle_bf99be4fb7f1c6b7c992bplugin PRIVATE "-Wl,--build-id=none")
target_link_libraries(
  omarchy_ui_bundle_bf99be4fb7f1c6b7c992b
  PRIVATE Qt6::Core Qt6::Qml Qt6::Quick Qt6::QuickControls2
)

file(WRITE "${CMAKE_BINARY_DIR}/qt-version.txt" "${Qt6Core_VERSION}
")
