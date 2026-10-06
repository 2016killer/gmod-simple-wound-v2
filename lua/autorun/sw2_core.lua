AddCSLuaFile()


local function AngleToRadians(angle)
	if isangle(angle) then
		return Vector(math.rad(angle.p), math.rad(angle.y), math.rad(angle.r))
	end

	return Vector(angle)
end

-- ====================== 数据结构 ======================
SWParams = {}
SWParams.__index = SWParams

SWEasyParams = {}
SWEasyParams.__index = SWEasyParams

SWEllipsoid = {}
SWEllipsoid.__index = SWEllipsoid

local SW_DISABLED_CENTER = Vector(499, 499, 499)
local SW_DISABLED_ANGLE = Angle()
local SW_DISABLED_SCALE = Vector(0.025, 0.025, 0.025)


local OFFSET_Z90 = Matrix()
OFFSET_Z90:SetAngles(Angle(0, 90, 0))
local OFFSET_Z90_INVERT = OFFSET_Z90:GetInverse()

function SWParams.new(
	shader,
	ellipsoids,
	deform_texture, project_texture, blood_range, litegore_compatibility
)
	local self = {}

	-- string
	self.shader = shader or 'VertexDeformationVertexLit'

	-- Array<SWEllipsoid>
	self.ellipsoids = ellipsoids or {}

	-- float
	self.blood_range = blood_range or 0.5

	-- string
	self.deform_texture = deform_texture or 'models/flesh'
	self.project_texture = project_texture or 'models/flesh'

	-- Bool
	self.litegore_compatibility = litegore_compatibility

	return self
end

function SWEasyParams.new(
	shader,
	ellipsoid,
	deform_texture, project_texture, blood_range, litegore_compatibility,
	boneid, slot
)
	local self = {}

	self.shader = shader
	self.ellipsoid = ellipsoid or {}
	self.deform_texture = deform_texture
	self.project_texture = project_texture
	self.blood_range = blood_range
	self.litegore_compatibility = litegore_compatibility
	self.boneid = boneid
	self.slot = slot

	return self
end

function SWEllipsoid.new(center, angle, scale)
	local self = {}

	-- Vector
	self.center = center or SW_DISABLED_CENTER
	self.scale = scale or SW_DISABLED_SCALE

	-- Angle
	self.angle = angle or SW_DISABLED_ANGLE

	return self
end

local SW_DISABLED_ELLIPSOID = SWEllipsoid.new(SW_DISABLED_CENTER, SW_DISABLED_ANGLE, SW_DISABLED_SCALE)
-- ====================== 数据结构 ======================

if CLIENT then
	local tooltipDialog


	local function Tooltip_MissingModule()
		if IsValid(tooltipDialog) then
			tooltipDialog:Center()
			tooltipDialog:MakePopup()
			return
		end

		local releaseURL = 'https://github.com/2016killer/gmod-simple-wound-v2/releases/latest'



		local bits
		if jit.version == 'LuaJIT 2.0.4' then
			bits = language.GetPhrase('sw2.bitness.32')
		elseif jit.version == 'LuaJIT 2.1.0-beta3' then
			bits = language.GetPhrase('sw2.bitness.64')
		else
			bits = language.GetPhrase('sw2.bitness.unknown')
		end
		
		local branch_name
		if BRANCH == 'unknown' then
			branch_name = language.GetPhrase('sw2.branch.main')
		elseif BRANCH == 'x86-64' then
			branch_name = language.GetPhrase('sw2.branch.x86_64')
		else
			branch_name = BRANCH
		end

		local frame = vgui.Create('DFrame')
		tooltipDialog = frame

		frame:SetTitle(language.GetPhrase('#sw2.missing_module'))
		frame:SetSize(560, 340)
		frame:Center()
		frame:MakePopup()
		frame.OnRemove = function()
			tooltipDialog = nil
		end

		local branchInfo = vgui.Create('DLabel', frame)
		branchInfo:Dock(TOP)
		branchInfo:DockMargin(12, 12, 12, 0)
		branchInfo:SetWrap(true)
		branchInfo:SetAutoStretchVertical(true)
		branchInfo:SetText(string.format(
			language.GetPhrase('sw2.missing_module_info'),
			branch_name,
			bits,
			BRANCH,
			jit.version,
			language.GetPhrase('sw2.supported.main32'),
			language.GetPhrase('sw2.supported.x86_64_32'),
			language.GetPhrase('sw2.supported.x86_64_64')
		))

		local help = vgui.Create('DLabel', frame)
		help:Dock(TOP)
		help:DockMargin(12, 8, 12, 0)
		help:SetWrap(true)
		help:SetAutoStretchVertical(true)
		help:SetText(string.format(language.GetPhrase('sw2.missing_module_help'), releaseURL))

		local openRelease = vgui.Create('DButton', frame)
		openRelease:Dock(BOTTOM)
		openRelease:DockMargin(12, 8, 12, 12)
		openRelease:SetTall(32)
		openRelease:SetText(language.GetPhrase('sw2.open_release'))
		openRelease.DoClick = function()
			gui.OpenURL(releaseURL)
		end
	end


	local function Tooltip_BranchMismatch()
		if IsValid(tooltipDialog) then
			tooltipDialog:Center()
			tooltipDialog:MakePopup()
			return
		end

		local bits
		if jit.version == 'LuaJIT 2.0.4' then
			bits = language.GetPhrase('sw2.bitness.32')
		elseif jit.version == 'LuaJIT 2.1.0-beta3' then
			bits = language.GetPhrase('sw2.bitness.64')
		else
			bits = language.GetPhrase('sw2.bitness.unknown')
		end

		local branch_name
		if BRANCH == 'unknown' then
			branch_name = language.GetPhrase('sw2.branch.main')
		elseif BRANCH == 'x86-64' then
			branch_name = language.GetPhrase('sw2.branch.x86_64')
		else
			branch_name = BRANCH
		end

		local frame = vgui.Create('DFrame')
		tooltipDialog = frame

		frame:SetTitle(language.GetPhrase('#sw2.branch_mismatch'))
		frame:SetSize(560, 300)
		frame:Center()
		frame:MakePopup()
		frame.OnRemove = function()
			tooltipDialog = nil
		end

		local branchInfo = vgui.Create('DLabel', frame)
		branchInfo:Dock(TOP)
		branchInfo:DockMargin(12, 12, 12, 0)
		branchInfo:SetWrap(true)
		branchInfo:SetAutoStretchVertical(true)
		branchInfo:SetText(string.format(
			language.GetPhrase('sw2.branch_mismatch_help') .. '\n\n' ..
			language.GetPhrase('sw2.missing_module_info'),
			branch_name,
			bits,
			BRANCH,
			jit.version,
			language.GetPhrase('sw2.supported.main32'),
			language.GetPhrase('sw2.supported.x86_64_32'),
			language.GetPhrase('sw2.supported.x86_64_64')
		))
	end

    local modulename_main = 'simple_wound'
	local modulename_x86_x64 = 'simple_wound_x86_x64'

    if not util.IsBinaryModuleInstalled(modulename_x86_x64) and not util.IsBinaryModuleInstalled(modulename_main) then
		-- 标记为缺失模块
        ErrorNoHalt(string.format('[Simple Wound]: %s\n', language.GetPhrase('sw2.missing_module')))
		hook.Add('InitPostEntity', 'SimpleWoundShowTooltip', Tooltip_MissingModule)
        return
    end


	local success, err = pcall(function() require(modulename_main) end)
	if not success then
		success, err = pcall(function() require(modulename_x86_x64) end)
		if not success then
			ErrorNoHalt(string.format('[Simple Wound]: %s\n', err))
			print('Only supported on:\n-- main branch 32-bit\n-- x86_x64 branch 32-bit\n-- x86_x64 branch 64-bit')
			-- 标记为不支持的分支
			hook.Add('InitPostEntity', 'SimpleWoundShowTooltip', Tooltip_BranchMismatch)
			return
		else
			print('[Simple Wound]: x86_x64 module installed')
		end
	else
		print('[Simple Wound]: main module installed')
	end

    SimpleWound = SimpleWound or {}
	SimpleWound.MaxWounds = 3
    SimpleWound.Version = '2.0.1'
	SimpleWound.BinVersion = isfunction(SimpleWoundGetVersion) and SimpleWoundGetVersion() or '<= 2.0.1'
	
	print('[Simple Wound]: Bin VERSION ' .. SimpleWound.BinVersion)
    print('[Simple Wound]: LUA VERSION ' .. SimpleWound.Version)

    SimpleWound.MaterialsCache = {}


	SimpleWound.Shaders = {
		['VertexDeformation'] = {},
		['VertexDeformationVertexLit'] = {},
		['EllipsoidClip'] = {},
		['EllipsoidClipVertexLit'] = {}
	}

	local function WoundRender(self)
		local materials = self.sw_materials
		local params = self.sw_params

		for j, matvar in pairs(materials) do
			for slot = 1, SimpleWound.MaxWounds do
				if not params.ellipsoids[slot] then
					matvar:SetVector('$ellipsoid_center_' .. slot, SW_DISABLED_CENTER)
					matvar:SetVector('$ellipsoid_angle_' .. slot, AngleToRadians(SW_DISABLED_ANGLE))
					matvar:SetVector('$ellipsoid_scale_' .. slot, SW_DISABLED_SCALE)
				else
					matvar:SetVector('$ellipsoid_center_' .. slot, params.ellipsoids[slot].center)
					matvar:SetVector('$ellipsoid_angle_' .. slot, AngleToRadians(params.ellipsoids[slot].angle))
					matvar:SetVector('$ellipsoid_scale_' .. slot, params.ellipsoids[slot].scale)
				end
			end

			matvar:SetFloat('$blood_range', params.blood_range)
			render.MaterialOverrideByIndex(j - 1, matvar)
		end
			self:DrawModel()
		for j, _ in pairs(materials) do
			render.MaterialOverrideByIndex(j - 1)
		end
	end


	local fleshMat = Material("models/flesh")
	local function WoundRender_Compatible_LiteGore(ent)
		-- 兼容LiteGore的伤口渲染
		-- 代码修改自LiteGore的RenderWounds函数
		
		if not IsValid(ent.goreModel) then
			WoundRender(ent)
			return
		end

		if not ent.LiteGibWounds then
			WoundRender(ent)
			return
		end

		if halo.RenderedEntity() == ent then
			WoundRender(ent)
			return
		end

		if #ent.LiteGibWounds == 0 then
			WoundRender(ent)
			return
		end

		--start off by clearing stencil
		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)
		render.SetStencilReferenceValue(0)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.ClearStencil()
		--first we write the entity to the stencil buffer with value 1
		--writing to the depth buffer but not color allows us to clip the wound with the model
		render.SetStencilEnable(true)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.CullMode(MATERIAL_CULLMODE_CCW)
		render.OverrideColorWriteEnable(true, false)
		ent:DrawModel()
		render.OverrideColorWriteEnable(false, false)
		--now we write the wound model, which increments the see-through areas to stencil value 2
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_INCR)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.SetBlend(0)
		render.OverrideDepthEnable(true, false)

		for _, v in ipairs(ent.LiteGibWounds) do
			if IsValid(v.model) and v.bone and v.pos and v.ang then
				local mat = ent:GetBoneMatrix(v.bone)

				if mat then
					local bpos, bang
					bpos = mat:GetTranslation()
					bang = mat:GetAngles()
					local pos, ang = LocalToWorld(v.pos, v.ang, bpos, bang)
					v.model:SetupBones()
					v.model:SetRenderOrigin(pos)
					v.model:SetRenderAngles(ang)
					v.model:DrawModel()
				end
			end
		end

		render.OverrideDepthEnable(false, false)
		render.SetBlend(1)
		--now we clear the depth of the wound area
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		render.SetStencilReferenceValue(0)
		render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
		render.OverrideColorWriteEnable(true, false)
		render.ClearBuffersObeyStencil(0, 0, 0, 0, true)
		render.OverrideColorWriteEnable(false, false)
		--now we write, in order, the fleshy interior of the model, and the wound model
		render.SetStencilReferenceValue(2)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.ModelMaterialOverride(fleshMat)
		render.CullMode(MATERIAL_CULLMODE_CW)
		ent:DrawModel()
		render.OverrideDepthEnable(true, false)
		render.CullMode(MATERIAL_CULLMODE_CCW)
		ent.goreModel:SetupBones()
		ent.goreModel:DrawModel()
		render.OverrideDepthEnable(false, false)
		render.ModelMaterialOverride()
		render.SetStencilReferenceValue(2)
		render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
		WoundRender(ent)
		render.ClearStencil()
		render.SetStencilEnable(false)
	end


	local function IsVertexLitMaterial(material)
		local shader = string.lower(material:GetShader() or '')
		return string.find(shader, 'vertexlit', 1, true) == 1
	end

	local function IsRemovedMaterialParameter(key)
		local lowerKey = string.lower(key)
		return string.find(lowerKey, 'envmap', 1, true) ~= nil or
			string.sub(lowerKey, 1, 6) == '$flags'
	end

	local SerializeMaterialTable
	local function SerializeMaterialValue(value)
		local valueType = type(value)

		if valueType == 'table' then
			return SerializeMaterialTable(value)
		end

		if valueType == 'userdata' then
			local ok, valueTable = pcall(function()
				return value:ToTable()
			end)
			if ok and type(valueTable) == 'table' then
				return SerializeMaterialTable(valueTable)
			end
		end

		return valueType .. ':' .. tostring(value)
	end

	SerializeMaterialTable = function(tbl)
		local keys = {}
		for key in pairs(tbl) do
			keys[#keys + 1] = key
		end

		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)

		local parts = {}
		for _, key in ipairs(keys) do
			parts[#parts + 1] = string.format(
				'%s=%s',
				tostring(key),
				SerializeMaterialValue(tbl[key])
			)
		end

		return '{' .. table.concat(parts, ';') .. '}'
	end

	SimpleWound.ApplyWound = function(ent, swparams)
		if not SimpleWound.Shaders[swparams.shader] then
			ErrorNoHalt(string.format('[Simple Wound]: Unknown shader "%s"\n', swparams.shader))
			return
		end

        ent.sw_params = swparams
		ent.sw_materials = {}
		for i, matpath in pairs(ent:GetMaterials()) do
			local idx = i - 1
			local subMaterial = ent:GetSubMaterial(idx)
			local matpathUsed = subMaterial == '' and matpath or subMaterial
			local sourceMaterial = Material(matpathUsed)

			if not IsVertexLitMaterial(sourceMaterial) then
				-- Only VertexLit materials can use the wound shaders.
				continue
			end

			local baseTexture = sourceMaterial:GetTexture('$basetexture')
			if not baseTexture then
				continue
			end

			local deform_texture = swparams.deform_texture or 'models/flesh'
			local project_texture = swparams.project_texture or 'models/flesh'
			local materialParameters = {}
			local matrixParameters = {}
			local sourceKeyValues = sourceMaterial:GetKeyValues() or {}

			for key, value in pairs(sourceKeyValues) do
				if
					type(value) ~= 'table' and
					not IsRemovedMaterialParameter(key)
				then
					materialParameters[key] = value
				end
			end
			-- print('SOURCE MATERIAL KEY VALUES=========')
			-- PrintTable(sourceMaterial:GetKeyValues())

			for _, key in ipairs({
				'$basetexture',
				'$bumpmap',
				'$phongexponenttexture'
			}) do
				if sourceKeyValues[key] ~= nil then
					local texture = sourceMaterial:GetTexture(key)
					if texture then
						materialParameters[key] = texture:GetName()
					end
				end
			end

			for _, key in ipairs({
				'$basetexturetransform',
				'$bumptransform'
			}) do
				local ok, matrix = pcall(
					sourceMaterial.GetMatrix,
					sourceMaterial,
					key
				)
				if ok and matrix then
					matrixParameters[key] = matrix
				end
			end

			materialParameters['$deform_texture'] = deform_texture
			materialParameters['$project_texture'] = project_texture

			local cacheParameters = {
				shader = swparams.shader,
				material = materialParameters,
				matrix = matrixParameters
			}
			local matname = string.format(
				'sw2_wound_%08x',
				util.CRC(SerializeMaterialTable(cacheParameters))
			)

			-- 应用材质 (如果不存在则创建)
			local matcache = SimpleWound.MaterialsCache[matname]
			if matcache then
				ent.sw_materials[i] = matcache
				-- print('USE CACHE MATERIAL=========')
				-- PrintTable(matcache:GetKeyValues())
			else
				local matvar = CreateMaterial(
					matname,
					swparams.shader,
					materialParameters
				)

				for key, matrix in pairs(matrixParameters) do
					pcall(matvar.SetMatrix, matvar, key, matrix)
				end

				SimpleWound.MaterialsCache[matname] = matvar

				ent.sw_materials[i] = matvar	
				-- print('CREATE MATERIAL=========')
				-- PrintTable(matvar:GetKeyValues())
			end

		end

		local litegore_compatibility = swparams.litegore_compatibility or 0
		ent.RenderOverride =
			litegore_compatibility == 1 and WoundRender_Compatible_LiteGore or WoundRender
    end

	net.Receive('sw_apply', function()
		local swparams = net.ReadTable()
		local ent = net.ReadEntity()

		if IsValid(ent) then
			SimpleWound.ApplyWound(ent, swparams)
		end
    end)

	SimpleWound.ApplyWoundEasy = function(ent, easyparams, coordinate)
		if not IsValid(ent) then
			return
		end

		local shader = easyparams.shader
		local ellipsoid = easyparams.ellipsoid
		local deform_texture = easyparams.deform_texture
		local project_texture = easyparams.project_texture
		local blood_range = easyparams.blood_range
		local litegore_compatibility = easyparams.litegore_compatibility
		local boneid = easyparams.boneid
		local slot = easyparams.slot

		local modelent = SimpleWound.GetClientModel(ent:GetModel())
		local bindBoneMatrix = SimpleWound.GetBoneMatrixSafe(modelent, boneid)

		local boneLocalTransform = Matrix()

		boneLocalTransform:SetTranslation(ellipsoid.center)
		boneLocalTransform:SetAngles(ellipsoid.angle)
		boneLocalTransform:SetScale(ellipsoid.scale)

		-- Convert the hit bone's local space back to bind-pose model space.
		local is_z90
		if coordinate == nil then
			is_z90 = ent:GetBoneCount() > 1
		elseif coordinate == 'z90' then
			is_z90 = true
		elseif coordinate == 'norm' then
			is_z90 = false
		else
			print('UNKNOWN COORDINATE', coordinate)
		end

		local modelSpaceTransform = is_z90 and (OFFSET_Z90_INVERT * bindBoneMatrix * boneLocalTransform) or (bindBoneMatrix * boneLocalTransform)
		local modelSpaceCenter = modelSpaceTransform:GetTranslation()
		local modelSpaceAngle = modelSpaceTransform:GetAngles()
		local modelSpaceScale = modelSpaceTransform:GetScale()

		shader = shader or 'VertexDeformationVertexLit'
		slot = math.floor(tonumber(slot) or 1)
		slot = ((slot - 1) % SimpleWound.MaxWounds) + 1

		local swparams = ent.sw_params
		if not swparams then
			swparams = SWParams.new(
				shader,
				{},
				deform_texture, project_texture, blood_range, litegore_compatibility
			)
		end

		swparams.shader = shader
		swparams.deform_texture = deform_texture
		swparams.project_texture = project_texture
		swparams.blood_range = blood_range or 0.5
		swparams.litegore_compatibility = litegore_compatibility
		swparams.ellipsoids[slot] = SWEllipsoid.new(modelSpaceCenter, modelSpaceAngle, modelSpaceScale)

		SimpleWound.ApplyWound(ent, swparams)
	end


	net.Receive('sw_apply_easy', function()
		local easyparams = net.ReadTable()
		local ent = net.ReadEntity()

		if IsValid(ent) then
			SimpleWound.ApplyWoundEasy(ent, easyparams)
		end
    end)

	concommand.Add('cl_sw2_breentest', function(ply, cmd, args)
		local entities = ents.FindInSphere(ply:GetPos(), 2000)

		for _, ent in pairs(entities) do
			if ent:GetModel() ~= 'models/breen.mdl' then
				continue
			end

			local ellipsoid = Matrix()
			ellipsoid:SetTranslation(Vector(0, -12, 50 + math.random(-10, 10)))
			ellipsoid:SetScale(Vector(math.random(5, 10), 15, math.random(5, 10)))

			SimpleWound.ApplyWound(
				ent, 
				SWParams.new(
					'VertexDeformationVertexLit',
					{
						SWEllipsoid.new(Vector(0, -12, 70 + math.random(-10, 10)), Angle(), Vector(math.random(5, 10), 15, math.random(5, 10))),
						SWEllipsoid.new(Vector(0, -12, 50 + math.random(-10, 10)), Angle(), Vector(math.random(5, 10), 15, math.random(5, 10))),
						SWEllipsoid.new(Vector(0, -12, 30 + math.random(-10, 10)), Angle(), Vector(math.random(5, 10), 15, math.random(5, 10)))
					},
					'models/flesh', 'models/flesh', 0.5, false
				)
			)
		end
    end)

	SimpleWound.ClientModels = {}

	local ClientModels = SimpleWound.ClientModels

	SimpleWound.GetClientModel = function(model)
		local modelent = ClientModels[model]
		if not IsValid(modelent) then
			modelent = ClientsideModel(model)
			modelent:SetNoDraw(true)
			ClientModels[model] = modelent
		end
		return modelent
	end

	SimpleWound.GetFreeWoundSlot = function(ent)
		local swparams = ent.sw_params
		if not swparams then
			return 1
		end

		for slot = 1, SimpleWound.MaxWounds do
			if not swparams.ellipsoids[slot] then
				return slot
			end
		end
	end

	SimpleWound.Reset = function(ent)
		ent.RenderOverride = nil
		ent.sw_params = nil
		ent.sw_materials = nil
	end

	net.Receive('sw_reset', function()
		local ent = net.ReadEntity()
		if IsValid(ent) then
			SimpleWound.Reset(ent)
		end
	end)
end


if SERVER then
	util.AddNetworkString('sw_apply_easy')
	util.AddNetworkString('sw_apply')
	util.AddNetworkString('sw_reset')

    SimpleWound = SimpleWound or {}
	SimpleWound.MaxWounds = 3
    SimpleWound.Version = '2.0.1'

	SimpleWound.ApplyWound = function(ent, swparams)
		ent.sw_params = swparams

		net.Start('sw_apply')
			net.WriteTable(swparams)
			net.WriteEntity(ent)
		net.Broadcast()
    end

	local COPY_MODIFIER = 'SimpleWound2'
	local SerializeToolWounds

	-- ent.sw_tool_wounds = {
	--   shader, deform_texture, project_texture, blood_range,
	--   litegore_compatibility, coordinate,
	--   slots = {
	--     [slot] = { boneid, center = Vector(), angle = Angle(), scale = Vector() }
	--   }
	-- }
	SimpleWound.ApplyWoundEasy = function(ent, easyparams)
		if not IsValid(ent) then
			return
		end

		easyparams.slot = math.floor(tonumber(easyparams.slot) or 1)
		easyparams.slot = ((easyparams.slot - 1) % SimpleWound.MaxWounds) + 1
		easyparams.shader = easyparams.shader or 'VertexDeformationVertexLit'

		if easyparams.persistent then
			local toolWounds = ent.sw_tool_wounds
			if not istable(toolWounds) or not istable(toolWounds.slots) then
				toolWounds = { slots = {} }
				ent.sw_tool_wounds = toolWounds
			end

			toolWounds.shader = easyparams.shader
			toolWounds.deform_texture = easyparams.deform_texture
			toolWounds.project_texture = easyparams.project_texture
			toolWounds.blood_range = easyparams.blood_range
			toolWounds.litegore_compatibility = easyparams.litegore_compatibility
			toolWounds.coordinate = easyparams.coordinate
			toolWounds.slots[easyparams.slot] = {
				boneid = easyparams.boneid,
				center = easyparams.ellipsoid.center,
				angle = easyparams.ellipsoid.angle,
				scale = easyparams.ellipsoid.scale
			}

			duplicator.StoreEntityModifier(ent, COPY_MODIFIER, SerializeToolWounds(ent))
		end

		net.Start('sw_apply_easy')
			net.WriteTable(easyparams)
			net.WriteEntity(ent)
		net.Broadcast()
	end

	SimpleWound.Reset = function(ent)
		ent.sw_params = nil
		ent.sw_tool_wounds = nil
		duplicator.StoreEntityModifier(ent, COPY_MODIFIER, { slots = {} })

		net.Start('sw_reset')
			net.WriteEntity(ent)
		net.Broadcast()
	end

	SerializeToolWounds = function(ent)
		local toolWounds = ent.sw_tool_wounds
		if not istable(toolWounds) or not istable(toolWounds.slots) then
			return
		end

		local slots = {}
		for slot = 1, SimpleWound.MaxWounds do
			local wound = toolWounds.slots[slot]
			if wound then
				local center = wound.center or Vector()
				local angle = wound.angle or Angle()
				local scale = wound.scale or Vector()

				slots[#slots + 1] = {
					slot = slot,
					boneid = wound.boneid,
					center = { center.x, center.y, center.z },
					angle = { angle.p, angle.y, angle.r },
					scale = { scale.x, scale.y, scale.z }
				}
			end
		end

		if #slots == 0 then
			return
		end

		return {
			shader = toolWounds.shader,
			deform_texture = toolWounds.deform_texture,
			project_texture = toolWounds.project_texture,
			blood_range = toolWounds.blood_range,
			litegore_compatibility = toolWounds.litegore_compatibility,
			coordinate = toolWounds.coordinate,
			slots = slots
		}
	end

	local function RestoreToolWounds(ent, data)
		if not IsValid(ent) or not istable(data) or not istable(data.slots) then
			return
		end

		for _, slotData in ipairs(data.slots) do
			local center = slotData.center or {}
			local angle = slotData.angle or {}
			local scale = slotData.scale or {}

			local easyparams = SWEasyParams.new(
				data.shader,
				SWEllipsoid.new(
					Vector(center[1] or 0, center[2] or 0, center[3] or 0),
					Angle(angle[1] or 0, angle[2] or 0, angle[3] or 0),
					Vector(scale[1] or 0, scale[2] or 0, scale[3] or 0)
				),
				data.deform_texture,
				data.project_texture,
				data.blood_range,
				data.litegore_compatibility,
				slotData.boneid,
				slotData.slot
			)
			easyparams.persistent = true
			easyparams.coordinate = data.coordinate

			SimpleWound.ApplyWoundEasy(ent, easyparams)
		end
	end

	hook.Add('PostEntityCopy', 'SimpleWound2', function(ent)
		local copyData = SerializeToolWounds(ent)
		if copyData then
			duplicator.StoreEntityModifier(ent, COPY_MODIFIER, copyData)
		end
	end)

	duplicator.RegisterEntityModifier(COPY_MODIFIER, function(ply, ent, data)
		if IsValid(ent) then
			RestoreToolWounds(ent, data)
		end
	end)
end


SimpleWound.DISABLED_CENTER = SW_DISABLED_CENTER
SimpleWound.DISABLED_ANGLE = SW_DISABLED_ANGLE
SimpleWound.DISABLED_SCALE = SW_DISABLED_SCALE
SimpleWound.OFFSET_Z90 = OFFSET_Z90
SimpleWound.OFFSET_Z90_INVERT = OFFSET_Z90_INVERT
SimpleWound.DISABLED_ELLIPSOID = SW_DISABLED_ELLIPSOID


SimpleWound.GetBoneMatrixSafe = function(ent, boneid)
	-- 某些实体可能会返回奇异矩阵
	if boneid == -1 then
		return ent:GetWorldTransformMatrix()
	else

		if CLIENT then 
			ent:SetupBones()
		end

		local bonematrix = ent:GetBoneMatrix(boneid)

		if bonematrix then
			return bonematrix
		else
			local modelname = isfunction(ent.GetModel) and ent:GetModel() or 'unknown model'
			local bonename = isfunction(ent.GetBoneName) and ent:GetBoneName(boneid) or 'unknown bone'

			print(
				string.format(
					'%s: %s, %s, %s',
					language.GetPhrase('sw2.err.unknowboneid'),
					boneid,
					modelname,
					bonename
				)
			)

			return ent:GetWorldTransformMatrix()
		end
	end
end
