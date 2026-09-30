PROJECT_GENERATOR_VERSION = 2

newoption({
    trigger = "gmcommon",
    description = "Sets the path to the garrysmod_common (https://github.com/danielga/garrysmod_common) directory",
    value = "./garrysmod_common",
    default = "./garrysmod_common"
})


local gmcommon = assert(_OPTIONS.gmcommon or os.getenv("GARRYSMOD_COMMON"),
    "you didn't provide a path to your garrysmod_common (https://github.com/danielga/garrysmod_common) directory")
include(gmcommon)



CreateWorkspace({
    name = 'simple_wound',
    path = 'solution', 
    abi_compatible = true,
})
    CreateProject({
        serverside = false,
        source_path = 'src' -- 源码路径
    })
        -- IncludeHelpersExtended() -- uses this repo path
        -- IncludeLuaShared() -- uses this repo path
        -- IncludeDetouring() -- uses this repo detouring submodule
        -- IncludeScanning() -- uses this repo scanning submodule

        IncludeSDKCommon()
        IncludeSDKTier0()
        IncludeSDKTier1()
        -- IncludeSDKTier2()
        -- IncludeSDKTier3()
        IncludeSDKMathlib()
        -- IncludeSDKRaytrace()
        -- IncludeSteamAPI()

        -- 主分支
        defines {
            "GMOD_MAIN"
        }

        includedirs {
			"src/sourceengine",
		}

		files {
			"src/sourceengine/*",
			"src/shaders/*"
		}
