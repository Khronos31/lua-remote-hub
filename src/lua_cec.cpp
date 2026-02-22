#include <lua.hpp>

#include <iostream>
#include <vector>
#include <string>
#include <cstring>
#include <chrono>
#include <thread>
#include <iomanip>

#include <libcec/cec.h>
#include <libcec/cecloader.h>

using namespace std;
using namespace CEC;

// CEC用グローバルインスタンス
// 複数の場所から呼ばれてもいいように静的変数で保持
static ICECAdapter* g_cec_adapter = nullptr;

/**
 * ユーティリティ: 論理アドレスのパース
 */
static cec_logical_address get_addr(lua_State *L, int index, cec_logical_address default_addr) {
    if (lua_isnoneornil(L, index)) return default_addr;
    return (cec_logical_address)luaL_checkinteger(L, index);
}

/**
 * Lua: cec.init(port_name)
 * 引数: port_name (任意) - "/dev/ttyACM0" 等。省略時は自動検出。
 * 戻り値: boolean (成功/失敗), string (エラーメッセージ)
 */
static int l_cec_init(lua_State *L) {
    if (g_cec_adapter) {
        lua_pushboolean(L, true);
        return 1;
    }

    // 1. 設定
    libcec_configuration config;
    config.Clear();
    snprintf(config.strDeviceName, sizeof(config.strDeviceName), "LuaRemoteHub");
    config.clientVersion = LIBCEC_VERSION_CURRENT;
    config.bActivateSource = 0;

    static ICECCallbacks callbacks;
    callbacks.Clear();
    config.callbacks = &callbacks;

    // 2. 初期化
    g_cec_adapter = LibCecInitialise(&config);
    if (!g_cec_adapter) {
        lua_pushboolean(L, false);
        lua_pushstring(L, "Failed to load libCEC via loader");
        return 2;
    }

    g_cec_adapter->InitVideoStandalone();

    const char* port_req = luaL_optstring(L, 1, NULL);
    string strPort;

    if (port_req == NULL) {
        cec_adapter_descriptor devices[10];
        int8_t iFound = g_cec_adapter->DetectAdapters(devices, 10, NULL, true);
        if (iFound <= 0) {
            UnloadLibCec(g_cec_adapter);
            g_cec_adapter = nullptr;
            lua_pushboolean(L, false);
            lua_pushstring(L, "No CEC adapter found");
            return 2;
        }
        strPort = devices[0].strComName;
    } else {
        strPort = port_req;
    }

    // 4. オープン処理 
    bool bOpened = false;
    for (int i = 0; i < 3; i++) {
        // 第2引数のタイムアウトを明示的に指定 (10000ms = 10秒)
        bool res = g_cec_adapter->Open(strPort.c_str(), 10000);
        
        // Openの結果が false でも、PingAdapterが成功すれば「繋がっている」とみなす
        if (res || g_cec_adapter->PingAdapter()) {
            bOpened = true;
            break;
        }

        if (i < 2) {
            std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        }
    }

    if (!bOpened) {
        // 失敗時は確実にインスタンスを破棄してnullptrに戻す
        UnloadLibCec(g_cec_adapter);
        g_cec_adapter = nullptr;
        lua_pushboolean(L, false);
        lua_pushstring(L, "Could not open CEC adapter after retries");
        return 2;
    }

    // 最後にデバイスをスキャン
    g_cec_adapter->RescanActiveDevices();

    lua_pushboolean(L, true);
    return 1;
}

/**
 * Lua: cec.close()
 */
static int l_cec_close(lua_State *L) {
    if (g_cec_adapter) {
        // cecloader.h の関数を使って安全に解放
        UnloadLibCec(g_cec_adapter);
        g_cec_adapter = nullptr;
    }
    return 0;
}

/**
 * Lua: cec.power_on(logical_address)
 * 引数: logical_address (任意) - 0:TV, 4:Playback1等。デフォルトは 0 (TV)。
 */
static int l_cec_power_on(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized. Call init() first.");
    cec_logical_address addr = (cec_logical_address)luaL_optinteger(L, 1, CECDEVICE_TV);
    
    bool res = g_cec_adapter->PowerOnDevices(addr);
    lua_pushboolean(L, res);
    return 1;
}

/**
 * Lua: cec.standby(logical_address)
 * 引数: logical_address (任意) - デフォルトは 15 (Broadcast)。
 */
static int l_cec_standby(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized. Call init() first.");
    cec_logical_address addr = (cec_logical_address)luaL_optinteger(L, 1, CECDEVICE_BROADCAST);
    
    bool res = g_cec_adapter->StandbyDevices(addr);
    lua_pushboolean(L, res);
    return 1;
}

/**
 * Lua: cec.transmit(command_string)
 * 引数: string - "1F:82:10:00" や "1f 82 10 00" 形式の文字列
 * 戻り値: boolean (送信成功・失敗)
 */
static int l_cec_transmit(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized. Call init() first.");
    
    // Lua から文字列を取得
    const char* cmd_str = luaL_checkstring(L, 1);

    // libCEC 標準の関数で文字列からコマンド構造体を生成
    cec_command cmd = g_cec_adapter->CommandFromString(cmd_str);
    
    // 送信
    bool res = g_cec_adapter->Transmit(cmd);
    
    lua_pushboolean(L, res);
    return 1;
}

/**
 * Lua: cec.set_active_source() -- cec-client: "as"
 */
static int l_cec_set_active_source(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized");
    bool res = g_cec_adapter->SetActiveSource();
    lua_pushboolean(L, res);
    return 1;
}

/**
 * Lua: cec.volume_up() -- cec-client: "volup"
 */
static int l_cec_volume_up(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized");
    uint8_t status = g_cec_adapter->VolumeUp();
    lua_pushinteger(L, status);
    return 1;
}

/**
 * Lua: cec.volume_down() -- cec-client: "voldown"
 */
static int l_cec_volume_down(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized");
    uint8_t status = g_cec_adapter->VolumeDown();
    lua_pushinteger(L, status);
    return 1;
}

/**
 * Lua: cec.mute() -- cec-client: "mute"
 */
static int l_cec_mute(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized");
    uint8_t status = g_cec_adapter->AudioToggleMute();
    lua_pushinteger(L, status);
    return 1;
}

/**
 * Lua: cec.get_power_status(addr) -- cec-client: "pow"
 */
static int l_cec_get_power_status(lua_State *L) {
    if (!g_cec_adapter) return luaL_error(L, "CEC not initialized");
    cec_power_status status = g_cec_adapter->GetDevicePowerStatus(get_addr(L, 1, CECDEVICE_TV));
    lua_pushinteger(L, (int)status);
    lua_pushstring(L, g_cec_adapter->ToString(status));
    return 2;
}

// モジュール関数テーブル
static const struct luaL_Reg ceclib [] = {
    {"init",              l_cec_init},
    {"close",             l_cec_close},
    {"transmit",          l_cec_transmit},
    {"power_on",          l_cec_power_on},
    {"standby",           l_cec_standby},
    {"set_active_source", l_cec_set_active_source},
    {"volume_up",         l_cec_volume_up},
    {"volume_down",       l_cec_volume_down},
    {"mute",              l_cec_mute},
    {"get_power_status",  l_cec_get_power_status},
    {NULL, NULL}
};

// モジュール初期化関数
extern "C" int luaopen_cec(lua_State *L) {
    luaL_newlib(L, ceclib);
    return 1;
}
