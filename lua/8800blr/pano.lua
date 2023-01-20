local function init()
	local LocalPlayer = LocalPlayer
	local table_insert = table.insert
	local table_sort = table.sort
	local string_format = string.format
	local gui_IsGameUIVisible = gui.IsGameUIVisible
	local vgui_GetKeyboardFocus = vgui.GetKeyboardFocus
	local input_IsKeyDown = input.IsKeyDown
	local render_SetMaterial = render.SetMaterial
	local render_DrawQuadEasy = render.DrawQuadEasy
	local render_SetBlend = render.SetBlend

	local function loadData()
		local f = file.Open("8800blr/pano.dat.lua", "rb", "LUA")

		local total, data = f:ReadUShort(), {}

		for i = 1, total do
			local pX, pY, pZ = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
			local aX, aY, aZ = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
			table_insert(data, {
				index = i,
				pos = Vector(pX, pY, pZ),
				ang = Angle(aX, aY, aZ)
			})
		end

		return total, data
	end

	local PANO_TOTAL, PANO_DATA = loadData()
	local FOCUS_LEN = 0.5
	local FOCUS_DIST = 1000
	local FOCUS_KEY = KEY_E

	local viewing = false
	local focusing = false
	local focusTime
	local oldKey
	local currKey

	local icon = Material("8800blr/pano_icon.png", "smooth")
	local faces = {}
	for i = 1, 6 do
		table_insert(faces, CreateMaterial("8800blr_pano_" .. i, "UnlitGeneric", { ["$ignorez"] = 1 }))
	end

	local function draw()
		local eyePos, eyeVector = EyePos(), EyeVector()
		local time = SysTime()

		-- sort data by pos distance
		table_sort(PANO_DATA, function(a, b) return eyePos:DistToSqr(a.pos) < eyePos:DistToSqr(b.pos) end)
		local closest = PANO_DATA[1]

		-- update keys
		oldKey = currKey
		currKey = input_IsKeyDown(FOCUS_KEY)

		-- handle viewing/focusing
		if not viewing then
			if not gui_IsGameUIVisible() and not vgui_GetKeyboardFocus()
				and currKey and eyePos:DistToSqr(closest.pos) <= FOCUS_DIST then
				if not focusing then
					if not oldKey then -- start focusing
						focusing = true
						focusTime = time
					end
				elseif time - focusTime >= FOCUS_LEN then -- start viewing/stop focusing
					viewing = true
					focusing = false
				end
			else -- cancel focusing
				focusing = false
			end
		elseif not gui_IsGameUIVisible() and not vgui_GetKeyboardFocus()
			and not oldKey and currKey or LocalPlayer():GetAbsVelocity():Length() > 0 then -- stop viewing
			viewing = false
		end

		-- draw icons
		if not viewing then
			render_SetMaterial(icon)
			for i = PANO_TOTAL, 1, -1 do
				render_DrawQuadEasy(PANO_DATA[i].pos, -eyeVector, 16, 16, color_white, 180)
			end
		end

		-- draw panorama
		if viewing or focusing then
			local csm = ClientsideModel("models/8800blr/panorama.mdl")
			csm:SetPos(eyePos)
			csm:SetAngles(closest.ang)
			local closestIndex = closest.index
			for i = 1, 6 do
				faces[i]:SetTexture("$basetexture", string_format("8800blr/pano/%03d_%d", closestIndex - 1, i - 1))
				csm:SetSubMaterial(i - 1, "!8800blr_pano_" .. i)
			end
			render_SetBlend(viewing and 1 or (time - focusTime) / FOCUS_LEN)
			csm:DrawModel()
			render_SetBlend(1)
			csm:Remove()
		end
	end

	hook.Add("PostDrawTranslucentRenderables", "8800blr_drawPano", draw)
end

hook.Add("Initialize", "8800blr_pano_init", function()
	if game.GetMap() == "gm_8800blr" then init() end
end)