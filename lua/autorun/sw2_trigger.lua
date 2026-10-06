AddCSLuaFile()

SimpleWoundTrigger = SimpleWoundTrigger or {}

SimpleWoundTrigger.WoundScaleTable = SimpleWoundTrigger.WoundScaleTable or {
	[HITGROUP_GENERIC] = {
		[DMG_BULLET] = Vector(5, 3, 3),        -- 子弹伤
		[DMG_SLASH] = Vector(5, 3, 3),       -- 刀伤
		[DMG_BLAST] = Vector(5, 3, 3),         -- 爆炸伤
		[DMG_CLUB] = Vector(5, 3, 3),          -- 钝器伤
		[DMG_PLASMA] = Vector(5, 3, 3),        -- 等离子伤
		[DMG_BLAST_SURFACE] = Vector(5, 3, 3), -- 表面爆炸伤

		[DMG_AIRBOAT] = Vector(5, 3, 3),       -- 气垫船枪伤
		[bit.bor(DMG_AIRBOAT, DMG_BULLET)] = Vector(5, 3, 3),

		[DMG_BUCKSHOT] = Vector(5, 3, 3),      -- 霰弹伤
		[bit.bor(DMG_BUCKSHOT, DMG_BULLET)] = Vector(5, 3, 3),
		    
		[DMG_SNIPER] = Vector(5, 3, 3),        -- 狙击伤
		[bit.bor(DMG_SNIPER, DMG_BULLET)] = Vector(5, 3, 3),


		[DMG_MISSILEDEFENSE] = Vector(5, 3, 3) -- 导弹类伤害	
	},
	[HITGROUP_HEAD] = {
		[DMG_BULLET] = Vector(5, 3, 3),        -- 子弹伤
		[DMG_SLASH] = Vector(5, 5, 1.5),       -- 刀伤
		[DMG_BLAST] = Vector(5, 3, 3),         -- 爆炸伤
		[DMG_CLUB] = Vector(5, 3, 3),          -- 钝器伤
		[DMG_PLASMA] = Vector(5, 3, 3),        -- 等离子伤
		[DMG_BLAST_SURFACE] = Vector(5, 3, 3), -- 表面爆炸伤

		[DMG_AIRBOAT] = Vector(5, 3, 3),       -- 气垫船枪伤
		[bit.bor(DMG_AIRBOAT, DMG_BULLET)] = Vector(5, 3, 3),

		[DMG_BUCKSHOT] = Vector(5, 3, 3),      -- 霰弹伤
		[bit.bor(DMG_BUCKSHOT, DMG_BULLET)] = Vector(5, 3, 3),
		    
		[DMG_SNIPER] = Vector(5, 3, 3),        -- 狙击伤
		[bit.bor(DMG_SNIPER, DMG_BULLET)] = Vector(5, 3, 3),


		[DMG_MISSILEDEFENSE] = Vector(5, 3, 3) -- 导弹类伤害
	},
	[HITGROUP_CHEST] = {
		[DMG_BULLET] = Vector(5, 3, 3),
		[DMG_SLASH] = Vector(5, 8, 1.5),
		[DMG_BLAST] = Vector(5, 7, 7), 
		[DMG_CLUB] = Vector(5, 3, 3),  
		[DMG_PLASMA] = Vector(5, 5, 5),  
		[DMG_BLAST_SURFACE] = Vector(5, 7, 7),

		[DMG_AIRBOAT] = Vector(5, 6, 6),
		[bit.bor(DMG_AIRBOAT, DMG_BULLET)] = Vector(5, 6, 6),

		[DMG_BUCKSHOT] = Vector(5, 6, 6),
		[bit.bor(DMG_BUCKSHOT, DMG_BULLET)] = Vector(5, 6, 6),

		[DMG_SNIPER] = Vector(8, 3, 3),
		[bit.bor(DMG_SNIPER, DMG_BULLET)] = Vector(8, 3, 3),

		[DMG_MISSILEDEFENSE] = Vector(5, 7, 7)
	},
	[HITGROUP_STOMACH] = nil,
	[HITGROUP_LEFTARM] = nil,
	[HITGROUP_RIGHTARM] = nil,
	[HITGROUP_LEFTLEG] = nil,
	[HITGROUP_RIGHTLEG] = nil
}

SimpleWoundTrigger.WoundScaleTable[HITGROUP_STOMACH] = SimpleWoundTrigger.WoundScaleTable[HITGROUP_CHEST]
SimpleWoundTrigger.WoundScaleTable[HITGROUP_LEFTARM] = SimpleWoundTrigger.WoundScaleTable[HITGROUP_HEAD]
SimpleWoundTrigger.WoundScaleTable[HITGROUP_RIGHTARM] = SimpleWoundTrigger.WoundScaleTable[HITGROUP_HEAD]
SimpleWoundTrigger.WoundScaleTable[HITGROUP_LEFTLEG] = SimpleWoundTrigger.WoundScaleTable[HITGROUP_HEAD]
SimpleWoundTrigger.WoundScaleTable[HITGROUP_RIGHTLEG] = SimpleWoundTrigger.WoundScaleTable[HITGROUP_HEAD]


local HITGROUP_BONE_MAP = {
	[HITGROUP_HEAD] = 'ValveBiped.Bip01_Head1',
	[HITGROUP_CHEST] = 'ValveBiped.Bip01_Spine2',
	[HITGROUP_STOMACH] = 'ValveBiped.Bip01_Pelvis',
	[HITGROUP_LEFTARM] = 'ValveBiped.Bip01_L_UpperArm',
	[HITGROUP_RIGHTARM] = 'ValveBiped.Bip01_R_UpperArm',
	[HITGROUP_LEFTLEG] = 'ValveBiped.Bip01_L_Thigh',
	[HITGROUP_RIGHTLEG] = 'ValveBiped.Bip01_R_Thigh',
}

local BONE_HITGROUP_MAP = {}
for hitgroup, bonename in pairs(HITGROUP_BONE_MAP) do
	BONE_HITGROUP_MAP[bonename] = hitgroup
end

local IsSinglePlayer = game.SinglePlayer()


SimpleWoundTrigger.GetBoneIdByHitgroup = function(ent, hitgroup)
	local bonename = HITGROUP_BONE_MAP[hitgroup] or 'ValveBiped.Bip01_Pelvis'
	return ent:LookupBone(bonename) or 0
end

SimpleWoundTrigger.GetHitGroupByPosition = function(ent, pos)
	local bestHitgroup = HITGROUP_CHEST
	local bestDistance = math.huge

	for bonename, hitgroup in pairs(BONE_HITGROUP_MAP) do
		local boneid = ent:LookupBone(bonename)
		if boneid then
			local bonepos = ent:GetBonePosition(boneid)
			if bonepos then
				local distance = bonepos:DistToSqr(pos)
				if distance < bestDistance then
					bestDistance = distance
					bestHitgroup = hitgroup
				end
			end
		end
	end

	return bestHitgroup
end

SimpleWoundTrigger.GetWoundScale = function(ent, hitgroup, dmgtype)
	-- print("获取伤口缩放: 实体=", ent, "命中部位=", hitgroup, "伤害类型=", dmgtype)
	local dmgtypefiltered = bit.band(dmgtype, bit.bnot(bit.bor(DMG_ALWAYSGIB, DMG_NEVERGIB)))
	local groupTable = SimpleWoundTrigger.WoundScaleTable[hitgroup]
	if not groupTable then
		return nil
	else
		return groupTable[dmgtypefiltered]
	end
end





-- ====================== SWModelWoundParams 结构 ======================
if CLIENT then
	SWModelWoundParams = {}
	SWModelWoundParams.__index = SWModelWoundParams


	function SWModelWoundParams.new(
		deform_texture, project_texture, 
		coordinate,
		blood_scale,
		litegore_compatibility,
		disabled
	)
		local self = {}

		self.deform_texture = deform_texture or 'models/flesh'
		self.project_texture = project_texture or 'models/flesh'
		self.coordinate = coordinate

		self.blood_scale = blood_scale or 0.7
		self.litegore_compatibility = litegore_compatibility
		self.disabled = disabled or false

		return self
	end

	function SWModelWoundParams.Disabled()
		local self = SWModelWoundParams.new()
		self.disabled = true
		return self
	end


	SimpleWoundTrigger.ModelWoundParams = SimpleWoundTrigger.ModelWoundParams or {
		["models/vortigaunt_slave.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),
		["models/headcrabclassic.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),

		["models/lamarr.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),

		["models/headcrabblack.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),

		["models/headcrab.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh",
			"norm"
		),

		["models/antlion_guard.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh",
			"norm"
		),
		["models/vortigaunt.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),
		["models/antlion.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),
		["models/vortigaunt_doctor.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),
		["models/manhack.mdl"] = SWModelWoundParams.Disabled(),

		["models/dog.mdl"] = SWModelWoundParams.Disabled(),

		["models/stalker.mdl"] = SWModelWoundParams.new(
			"simple_wound/alienflesh",
			"simple_wound/alienflesh"
		),

		["models/Combine_Strider.mdl"] = SWModelWoundParams.Disabled(),
	}
end





local sw_trigger_enable = CreateConVar('sw_trigger_enable', '1', {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_CLIENTCMD_CAN_EXECUTE}, '')
local sw_trigger_on_death = CreateConVar('sw_trigger_on_death', '0', {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_CLIENTCMD_CAN_EXECUTE}, '')
local sw_trigger_player = CreateConVar('sw_trigger_player', '0', {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_CLIENTCMD_CAN_EXECUTE}, '')
local sw_trigger_ragdoll = CreateConVar('sw_trigger_ragdoll', '1', {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_CLIENTCMD_CAN_EXECUTE}, '')
local sw_trigger_clientside_corpse = CreateConVar('sw_trigger_clientside_corpse', '1', {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_CLIENTCMD_CAN_EXECUTE}, '')
local sw_trigger_damage_threshold = CreateConVar('sw_trigger_damage_threshold', '5', {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_CLIENTCMD_CAN_EXECUTE}, '')


if SERVER then
	util.AddNetworkString('sw_trigger_apply')
	util.AddNetworkString('sw_trigger_sync')

	local MAX_TRIGGER_WOUNDS = 3

	local function AddPendingWound(ent, wound)
		local woundparams = ent.sw_trigger_params
		if not istable(woundparams) then
			woundparams = {}
			ent.sw_trigger_params = woundparams
		end

		if #woundparams >= MAX_TRIGGER_WOUNDS then
			return
		end

		table.insert(woundparams, wound)
		return #woundparams
	end

	local function BuildWoundTransform(ent, pos, dir, hitgroup, dmgtype)
		if not IsValid(ent) then
			return
		end

		local woundscale = SimpleWoundTrigger.GetWoundScale(ent, hitgroup, dmgtype)
		if not woundscale then
			return
		end

		local boneid = SimpleWoundTrigger.GetBoneIdByHitgroup(ent, hitgroup)
		local boneMatrix = ent:GetBoneMatrix(boneid) or Matrix()
		local woundtransform = Matrix()
		woundtransform:SetTranslation(pos)
		woundtransform:SetAngles(dir:Angle())
		woundtransform:SetScale(woundscale)
		woundtransform = boneMatrix:GetInverse() * woundtransform
		-- print("伤口变换矩阵:", woundtransform, "骨骼ID:", boneid, "伤口缩放:", woundscale)
		return woundtransform, boneid
	end

	local function Apply(ent, pos, dir, hitgroup, dmgtype)
		local woundtransform, boneid = BuildWoundTransform(ent, pos, dir, hitgroup, dmgtype)
		if not woundtransform then
			return
		end

		net.Start('sw_trigger_apply')
			if IsSinglePlayer then
				net.WriteEntity(ent)
			else
				net.WriteInt(ent:EntIndex(), 32)
			end

			net.WriteMatrix(woundtransform)
			net.WriteInt(boneid, 32)
		net.SendPVS(pos)
	end

	local function SyncClientsideWound(ent, pos, dir, hitgroup, dmgtype)
		if not IsValid(ent) or not sw_trigger_clientside_corpse:GetBool() then
			return
		end

		local woundtransform, boneid = BuildWoundTransform(ent, pos, dir, hitgroup, dmgtype)
		if not woundtransform then
			return
		end

		net.Start('sw_trigger_sync')
			net.WriteEntity(ent)
			net.WriteMatrix(woundtransform)
			net.WriteInt(boneid, 32)
		net.Broadcast()
	end

	hook.Add('ScaleNPCDamage', 'SimpleWoundTrigger' , function(npc, hitgroup, dmginfo)
		-- NPC伤口在这里触发
		-- 伤口参数初始化
		if not IsValid(npc) or not sw_trigger_enable:GetBool() then 
			return 
		end

		if dmginfo:GetDamage() < sw_trigger_damage_threshold:GetInt() then
			return
		end

		local wound = {
			pos = dmginfo:GetDamagePosition(),
			dir = -dmginfo:GetDamageForce(),
			dmg = dmginfo:GetDamage(),
			dmgtype = dmginfo:GetDamageType(),
			hitgroup = hitgroup
		}

		if not AddPendingWound(npc, wound) then
			return
		end

		SyncClientsideWound(npc, wound.pos, wound.dir, wound.hitgroup, wound.dmgtype)

		if not sw_trigger_on_death:GetBool() then
			Apply(npc, wound.pos, wound.dir, wound.hitgroup, wound.dmgtype)
		end
	end)

	hook.Add('EntityTakeDamage', 'SimpleWoundTriggerRagdoll', function(ent, dmginfo)
		-- 玩家伤口在这里触发
		if not IsValid(ent) or (not ent:IsRagdoll() and not ent:IsPlayer()) then
			return
		end

		if not sw_trigger_enable:GetBool() or not sw_trigger_ragdoll:GetBool() then
			return
		end

		if ent:IsPlayer() and not sw_trigger_player:GetBool() then
			return
		end

		local pos = dmginfo:GetDamagePosition()
		local hitgroup = SimpleWoundTrigger.GetHitGroupByPosition(ent, pos)
		local dir = -dmginfo:GetDamageForce()
		local dmgtype = dmginfo:GetDamageType()

		if ent:IsPlayer() then
			AddPendingWound(ent, {
				pos = pos,
				dir = dir,
				dmg = dmginfo:GetDamage(),
				dmgtype = dmgtype,
				hitgroup = hitgroup
			})

			SyncClientsideWound(ent, pos, dir, hitgroup, dmgtype)
		end

		Apply(ent, pos, dir, hitgroup, dmgtype)
	end)

	hook.Add('CreateEntityRagdoll', 'SimpleWoundTrigger', function(ent, rag)
		-- print("创建 ragdoll 实体:", ent, "ragdoll:", rag)
		local applied_count = 0
		local woundparams = ent.sw_trigger_params

		if istable(woundparams) then
			-- print(ent, "一开始就有伤口参数，数量: " .. #woundparams)
			for _, wound in ipairs(woundparams) do
				local succ, err = pcall(
					Apply,
					rag,
					wound.pos,
					wound.dir,
					wound.hitgroup,
					wound.dmgtype
				)

				if not succ then
					print(err)
				end
			end

			applied_count = #woundparams
		end

		timer.Simple(FrameTime() * 5, function()
			if not IsValid(ent) or not IsValid(rag) then
				-- print("实体被移除，无法应用伤口参数")
				return
			end

			local latest_params = ent.sw_trigger_params
			if not istable(latest_params) then
				-- print(ent, "没有伤口参数需要应用")
				return
			end

			if #latest_params > applied_count then
				-- print(ent, "有新的伤口参数需要应用，数量: " .. (#latest_params - applied_count))
				for i = applied_count + 1, #latest_params do
					local wound = latest_params[i]

					local succ, err = pcall(
						Apply,
						rag,
						wound.pos,
						wound.dir,
						wound.hitgroup,
						wound.dmgtype
					)

					if not succ then
						-- print(err)
					end
				end
			else
				-- print(ent, "没有新的伤口参数需要应用")
			end

			ent.sw_trigger_params = nil
		end)
	end)
end


if CLIENT then
	local sw_trigger_litegore_compatibility = CreateClientConVar('sw_trigger_litegore_compatibility', '0', true, false)
	local sw_trigger_blood_scale = CreateClientConVar('sw_trigger_blood_scale', '0.7', true, false)
	local sw_trigger_deform_texture = CreateClientConVar('sw_trigger_deform_texture', 'models/flesh', true, false)
	local sw_trigger_project_texture = CreateClientConVar('sw_trigger_project_texture', 'models/flesh', true, false)

	SimpleWoundTrigger.ClientWoundData = {}


	local function Apply(ent, woundLocalTransform, boneid)
		if not IsValid(ent) or not SimpleWound then
			return
		end

		local slot = SimpleWound.GetFreeWoundSlot(ent)
		if not slot then
			return
		end

		local modelname = ent:GetModel()
		local modelWoundParams = SimpleWoundTrigger.ModelWoundParams[modelname] or {}

		local blood_scale = sw_trigger_blood_scale:GetFloat() or 0.7
		local deform_texture = sw_trigger_deform_texture:GetString()
		local project_texture = sw_trigger_project_texture:GetString()
		local litegore_compatibility = sw_trigger_litegore_compatibility:GetInt()

		if istable(modelWoundParams) then
			blood_scale = modelWoundParams.blood_scale or blood_scale
			deform_texture = modelWoundParams.deform_texture or deform_texture
			project_texture = modelWoundParams.project_texture or project_texture
			if modelWoundParams.litegore_compatibility ~= nil then
				litegore_compatibility = modelWoundParams.litegore_compatibility
			end
		end

		if modelWoundParams.disabled then
			return
		end

		local easyparams = SWEasyParams.new(
			'VertexDeformationVertexLit',
			SWEllipsoid.new(
				woundLocalTransform:GetTranslation(),
				woundLocalTransform:GetAngles(),
				woundLocalTransform:GetScale()
			),
			deform_texture,
			project_texture,
			blood_scale,
			litegore_compatibility,
			boneid,
			slot
		)

		SimpleWound.ApplyWoundEasy(ent, easyparams, modelWoundParams.coordinate)
	end


	net.Receive('sw_trigger_apply', function()
		local ent = IsSinglePlayer and net.ReadEntity() or net.ReadInt(32)
		local woundLocalTransform = net.ReadMatrix()
		local boneid = net.ReadInt(32)

		if not SimpleWound or not sw_trigger_enable:GetBool() then
			return
		end

		if IsSinglePlayer then
			local succ, err = pcall(Apply, ent, woundLocalTransform, boneid)
			if not succ then
				ErrorNoHalt(string.format('[Simple Wound]: %s\n', err))
			end
		else
			if not IsValid(Entity(ent)) then
				-- 重试机制
				timer.Simple(0.3, function()
					if not IsValid(Entity(ent)) then
						return
					end

					local succ, err = pcall(Apply, Entity(ent), woundLocalTransform, boneid)
					if not succ then
						ErrorNoHalt(string.format('[Simple Wound]: %s\n', err))
					end
				end)
			else
				local succ, err = pcall(Apply, Entity(ent), woundLocalTransform, boneid)
				if not succ then
					ErrorNoHalt(string.format('[Simple Wound]: %s\n', err))
				end
			end
		end
    end)

	net.Receive('sw_trigger_sync', function()
		local ent = net.ReadEntity()
		local woundLocalTransform = net.ReadMatrix()
		local boneid = net.ReadInt(32)

		if not IsValid(ent) or not SimpleWound or not sw_trigger_enable:GetBool() or not sw_trigger_clientside_corpse:GetBool() then
			return
		end

		local wounds = SimpleWoundTrigger.ClientWoundData[ent]
		if not istable(wounds) then
			wounds = {}
			SimpleWoundTrigger.ClientWoundData[ent] = wounds
		end

		if #wounds >= 3 then
			return
		end

		table.insert(wounds, {
			woundLocalTransform = woundLocalTransform,
			boneid = boneid
		})
	end)

	hook.Add('CreateClientsideRagdoll', 'SimpleWoundTrigger', function(entity, ragdoll)
		-- print("创建 ragdoll 实体:", entity, "ragdoll:", ragdoll)
		if not IsValid(entity) or not IsValid(ragdoll) then
			return
		end

		if not sw_trigger_enable:GetBool() or not sw_trigger_clientside_corpse:GetBool() then
			return
		end

		local timer_name = 'sw2_clientside_wound_' .. math.random(1, 2147483647)
		local applied_count = 0
		local wounds = SimpleWoundTrigger.ClientWoundData[entity]

		if istable(wounds) then
			-- print(entity, "一开始就有伤口参数，数量: " .. #wounds)
			for _, wound in ipairs(wounds) do
				local succ, err = pcall(Apply, ragdoll, wound.woundLocalTransform, wound.boneid)
				if not succ then
					ErrorNoHalt(string.format('[Simple Wound]: %s\n', err))
				end
			end

			applied_count = #wounds
		end

		local has_initial_data = applied_count > 0
		local attempts = has_initial_data and 1 or 20
		local delay = 0.1

		timer.Create(timer_name, delay, attempts, function()
			if not IsValid(entity) or not IsValid(ragdoll) then
				-- print("实体被移除，无法应用伤口参数")
				timer.Remove(timer_name)
				return
			end

			local latest = SimpleWoundTrigger.ClientWoundData[entity]
			if not istable(latest) then
				if has_initial_data then
					SimpleWoundTrigger.ClientWoundData[entity] = nil
				end
				return
			end

			if #latest > applied_count then
				for i = applied_count + 1, #latest do
					local wound = latest[i]
					local succ, err = pcall(Apply, ragdoll, wound.woundLocalTransform, wound.boneid)
					if not succ then
						ErrorNoHalt(string.format('[Simple Wound]: %s\n', err))
					end
				end

				applied_count = #latest
				-- print(entity, "应用了新的伤口参数，数量: " .. #latest)
			else
				-- print(entity, "没有新的伤口参数需要应用")
			end

			SimpleWoundTrigger.ClientWoundData[entity] = nil
			timer.Remove(timer_name)
		end)
	end)
end

hook.Add('PlayerSpawn', 'SimpleWoundTriggerReset', function(ply)
	if SERVER then
		ply.sw_trigger_params = nil
	else
		SimpleWoundTrigger.ClientWoundData[ply] = nil
	end

	SimpleWound.Reset(ply)
end)
