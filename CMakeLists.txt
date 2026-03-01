cmake_minimum_required(VERSION 3.10)
project(lua-remote-hub VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 11)

# 依存関係
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)
pkg_check_modules(LIBCEC REQUIRED libcec)
find_package(Lua 5.4 REQUIRED)

include_directories(
    src 
    ${LIBUSB_INCLUDE_DIRS} 
    ${LUA_INCLUDE_DIR} 
    ${LIBCEC_INCLUDE_DIRS}
)

# Luaモジュールビルド (usbir.so)
add_library(usbir SHARED src/usbir.cpp src/lua_usbir.cpp)
target_link_libraries(usbir ${LIBUSB_LIBRARIES} ${LUA_LIBRARIES})
set_target_properties(usbir PROPERTIES PREFIX "")

# Luaモジュールビルド (cec.so)
add_library(lua_cec_lib SHARED src/lua_cec.cpp)
target_link_libraries(lua_cec_lib ${LIBCEC_LIBRARIES} ${LUA_LIBRARIES})
set_target_properties(lua_cec_lib PROPERTIES 
    PREFIX "" 
    OUTPUT_NAME "cec"
)

# --- インストール定義 (dpkgが担当する配置) ---

# 1. バイナリ・ライブラリ
install(TARGETS usbir lua_cec_lib DESTINATION lib/lua/5.4)

# 2. Luaスクリプト
# システム本体のスクリプトは /usr/share に配置
install(FILES  
    gateways/gateway_rx.lua
    gateways/gateway_tx.lua
    ha-addon/remapper.lua
    DESTINATION share/lua-remote-hub/lua
)

# 3. Pythonスクリプト & データ
install(DIRECTORY scripts/ DESTINATION share/lua-remote-hub/scripts)

# 4. システム設定ファイル
install(FILES packaging/dbus/com.khronos31.btkbservice.conf 
    DESTINATION /etc/dbus-1/system.d)
install(FILES packaging/udev/99-bit-trade-one.rules 
    DESTINATION lib/udev/rules.d)
install(FILES
    packaging/systemd/btk-server.service 
    packaging/systemd/ir-daemon.service 
    packaging/systemd/ha_gateway_rx.service 
    packaging/systemd/ha_gateway_tx.service 
    DESTINATION lib/systemd/system)
install(FILES packaging/systemd/bluetooth-override.conf 
    DESTINATION /etc/systemd/system/bluetooth.service.d
    RENAME override.conf)

# --- CPack 設定 ---

set(CPACK_PACKAGE_NAME "lua-remote-hub")
set(CPACK_PACKAGE_VENDOR "Khronos31")
set(CPACK_PACKAGE_CONTACT "39792509+Khronos31@users.noreply.github.com")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "lua5.4, libusb-1.0-0, python3-dbus, python3-gi, bluez")
set(CPACK_GENERATOR "DEB")

# メンテナスクリプトの登録
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA 
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/postinst"
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/prerm"
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/postrm"
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/preinst"
)

include(CPack)
