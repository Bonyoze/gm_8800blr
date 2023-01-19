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
	local oldKey, currKey

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

	local function draw()
		local eyePos, eyeVector = EyePos(), EyeVector()

		-- sort data by pos distance
		table.sort(PANO_DATA, function(a, b) return eyePos:DistToSqr(a.pos) < eyePos:DistToSqr(b.pos) end)
		local nearest = PANO_DATA[1]

		-- update keys
		oldKey = currKey
		currKey = input.IsKeyDown(FOCUS_KEY)

		-- handle viewing/focusing
		if not viewing then
			if currKey and eyePos:DistToSqr(nearest.pos) <= FOCUS_DIST then
				if not focusing then
					if not oldKey then
						focusing = true
						focusTime = SysTime()
					end
				elseif SysTime() - focusTime >= FOCUS_LEN then
					viewing = true
					focusing = false
				end
			else
				focusing = false
			end
		else
			if not oldKey and currKey or LocalPlayer():GetAbsVelocity():Length() > 0 then
				viewing = false
			end
		end

		-- draw icons
		if not viewing then
			render.SetMaterial(mat_icon)
			for i = PANO_TOTAL, 1, -1 do
				render.DrawQuadEasy(PANO_DATA[i].pos, -eyeVector, 16, 16, color_white, 180)
			end
		end

		-- draw pano
		if viewing or focusing then
			matrix_pano:SetTranslation(EyePos())
			matrix_pano:SetAngles(nearest.ang)

			color_pano.a = viewing and 255 or focusing and (SysTime() - focusTime) * 255 / FOCUS_LEN or 0

			local index = nearest.index

			cam.IgnoreZ(true)
			cam.PushModelMatrix(matrix_pano)
			for i = 1, 6 do
				mat_pano:SetTexture("$basetexture", string.format("8800blr/pano/%03d_%d", index - 1, i - 1))
				render.SetMaterial(mat_pano)
				render.DrawQuadEasy(norms_pano[i] * -5, norms_pano[i], 10, 10, color_pano, i ~= 1 and i ~= 6 and 180 or 0)
			end
			cam.PopModelMatrix()
			cam.IgnoreZ(false)
		end
	end

	hook.Add("PostDrawTranslucentRenderables", "8800blr_drawPano", draw)
end

hook.Add("Initialize", "8800blr_pano_init", function()
	if game.GetMap() == "gm_8800blr" then
		init()
	end
end)

init()