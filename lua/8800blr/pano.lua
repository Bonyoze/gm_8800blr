local function loadData()
	local f = file.Open("8800blr/pano.dat.lua", "rb", "LUA")

	local total, data = f:ReadUShort(), {}

	for i = 1, total do
		local pX, pY, pZ = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
		local aX, aY, aZ = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
		table.insert(data, {
			index = i,
			pos = Vector(pX, pY, pZ),
			ang = Angle(aX, aY, aZ)
		})
	end

	return total, data
end

local function init()
	local PANO_TOTAL, PANO_DATA = loadData()
	local FOCUS_LEN = 0.5
	local FOCUS_DIST = 1000
	local FOCUS_KEY = KEY_E

	local viewing = false
	local focusing = false
	local focusTime
	local oldKey
	local currKey

	local mat_icon = Material("8800blr/pano_icon.png", "smooth")
	local mat_pano = CreateMaterial("8800blr_pano", "UnlitGeneric", { ["$vertexalpha"] = 1 })
	local norms_pano = {
		Vector(0, 0, -1),
		Vector(-1, 0, 0),
		Vector(0, 1, 0),
		Vector(1, 0, 0),
		Vector(0, -1, 0),
		Vector(0, 0, 1)
	}
	local color_pano = Color(255, 255, 255)
	local matrix_pano = Matrix()

	local LocalPlayer = LocalPlayer
	local table_sort = table.sort
	local string_format = string.format
	local gui_IsGameUIVisible = gui.IsGameUIVisible
	local vgui_GetKeyboardFocus = vgui.GetKeyboardFocus
	local input_IsKeyDown = input.IsKeyDown
	local render_SetMaterial = render.SetMaterial
	local render_DrawQuadEasy = render.DrawQuadEasy
	local cam_IgnoreZ = cam.IgnoreZ
	local cam_PushModelMatrix = cam.PushModelMatrix
	local cam_PopModelMatrix = cam.PopModelMatrix

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
			render_SetMaterial(mat_icon)
			for i = PANO_TOTAL, 1, -1 do
				render_DrawQuadEasy(PANO_DATA[i].pos, -eyeVector, 16, 16, color_white, 180)
			end
		end

		-- draw pano
		if viewing or focusing then
			matrix_pano:SetTranslation(eyePos)
			matrix_pano:SetAngles(closest.ang)

			color_pano.a = viewing and 255 or (time - focusTime) * 255 / FOCUS_LEN

			cam_IgnoreZ(true)
			cam_PushModelMatrix(matrix_pano)
			local closestIndex = closest.index
			for i = 1, 6 do
				mat_pano:SetTexture("$basetexture", string_format("8800blr/pano/%03d_%d", closestIndex - 1, i - 1))
				render_SetMaterial(mat_pano)
				render_DrawQuadEasy(norms_pano[i] * -5, norms_pano[i], 10, 10, color_pano, i ~= 1 and i ~= 6 and 180 or 0)
			end
			cam_PopModelMatrix()
			cam_IgnoreZ(false)
		end
	end

	hook.Add("PostDrawTranslucentRenderables", "8800blr_drawPano", draw)
end

hook.Add("Initialize", "8800blr_pano_init", function()
	if game.GetMap() == "gm_8800blr" then
		init()
	end
end)