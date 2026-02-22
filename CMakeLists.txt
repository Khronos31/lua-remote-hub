cmake_minimum_required(VERSION 3.10)
project(lua-remote-hub VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 11)

# 依存関係
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)
find_package(Lua 5.4 REQUIRED)

include_directories(src ${LIBUSB_INCLUDE_DIRS} ${LUA_INCLUDE_DIR})

# Luaモジュールビルド (usbir.so)
add_library(usbir SHARED src/usbir.cpp src/lua_modules.cpp)
target_link_libraries(usbir ${LIBUSB_LIBRARIES} ${LUA_LIBRARIES})
set_target_properties(usbir PROPERTIES PREFIX "")

# --- インストール定義 (dpkgが担当する配置) ---

# 1. バイナリ・ライブラリ
install(TARGETS usbir DESTINATION lib/lua/5.4)

# 2. Luaスクリプト
# 設定ファイルとリモコン定義（サンプル）を /etc に配置
install(FILES 
    lua/config/config.lua 
    lua/config/C-RT1.lua 
    DESTINATION /etc/lua-remote-hub
)

# システム本体のスクリプトは /usr/share に配置
install(FILES 
    lua/main.lua 
    lua/remapper.lua 
    DESTINATION share/lua-remote-hub/lua
)

# 3. Pythonスクリプト & データ
install(DIRECTORY scripts/ DESTINATION share/lua-remote-hub/scripts)

# 4. システム設定ファイル
install(FILES packaging/dbus/com.khronos31.btkbservice.conf 
        DESTINATION /etc/dbus-1/system.d)
install(FILES packaging/udev/99-bit-trade-one.rules 
        DESTINATION lib/udev/rules.d)
install(FILES packaging/systemd/btk-server.service 
              packaging/systemd/ir-daemon.service 
        DESTINATION lib/systemd/system)
install(FILES packaging/systemd/bluetooth-override.conf 
        DESTINATION /etc/systemd/system/bluetooth.service.d
        RENAME override.conf)

# --- CPack 設定 ---

set(CPACK_PACKAGE_NAME "lua-remote-hub")
set(CPACK_PACKAGE_VENDOR "Khronos31")
set(CPACK_PACKAGE_CONTACT "39792509+Khronos31@users.noreply.github.com")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "lua5.4, libusb-1.0-0, python3-dbus, python3-gi, bluez")
set(CPACK_GENERATOR "DEB;RPM;TGZ")

# メンテナスクリプトの登録
set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA 
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/postinst"
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/prerm"
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/postrm"
    "${CMAKE_CURRENT_SOURCE_DIR}/packaging/preinst"
)

include(CPack)
