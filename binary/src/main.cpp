#include "cdll_client_int.h"

#include "GarrysMod/Lua/LuaShared.h"
#include "GarrysMod/Lua/Interface.h"

#include "shader_inject.h"

using namespace GarrysMod::Lua;

static const char* SIMPLE_WOUND_VERSION = "2.0.1";

LUA_FUNCTION(SimpleWoundGetVersion) {
	LUA->PushString(SIMPLE_WOUND_VERSION);
	return 1;
}

GMOD_MODULE_OPEN() {
	Msg("=====================================\n");
	Msg("[Simple Wound]: Injecting shaders\n");
	if (!inject_shaders())
		LUA->ThrowError("[SimpWound Internal Error]: C++ Shadersystem failed to load!");

	LUA->PushSpecial(SPECIAL_GLOB);
	LUA->PushCFunction(SimpleWoundGetVersion);
	LUA->SetField(-2, "SimpleWoundGetVersion");
	LUA->Pop();

	Msg("[Simple Wound]: VERSION %s\n", SIMPLE_WOUND_VERSION);
	Msg("=====================================\n");
	return 0;
}


GMOD_MODULE_CLOSE() {

	// Defined in 'shader_inject.h'
	eject_shaders();

	return 0;
}
