local function init()
	local EyePos = EyePos
	local EyeVector = EyeVector
	local SysTime = SysTime
	local LocalPlayer = LocalPlayer
	local ClientsideModel = ClientsideModel
	local table_sort = table.sort
	local string_format = string.format
	local gui_IsGameUIVisible = gui.IsGameUIVisible
	local vgui_GetKeyboardFocus = vgui.GetKeyboardFocus
	local input_IsKeyDown = input.IsKeyDown
	local render_SetMaterial = render.SetMaterial
	local render_DrawQuadEasy = render.DrawQuadEasy
	local render_GetColorModulation = render.GetColorModulation
	local render_GetBlend = render.GetBlend
	local render_SetColorModulation = render.SetColorModulation
	local render_SetBlend = render.SetBlend

	local function loadData()
		-- panorama position and angle info is stored in its own binary data format
		local f = file.Open("8800blr/pano.dat.lua", "rb", "LUA")

		local total, data = f:ReadUShort(), {}

		for i = 1, total do
			local pX, pY, pZ = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
			local aX, aY, aZ = f:ReadFloat(), f:ReadFloat(), f:ReadFloat()
			data[i] = {
				index = i,
				pos = Vector(pX, pY, pZ),
				ang = Angle(aX, aY, aZ)
			}
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
	local lastIndex

	local iconMat = Material("8800blr/pano_icon.png", "smooth")
	local panoMats = {}
	for i = 1, 6 do
		panoMats[i] = Material("8800blr/pano_" .. (i - 1))
	end
	
	-- this replaces the current sorting method and speeds it up
	local function quicksort(t, left, right, distFunc)
	    if left < right then
		local pivot = left
		local i = left + 1
		local j = right
		while i <= j do
		    while i <= right and distFunc(t[i]) <= distFunc(t[pivot]) do
			i = i + 1
		    end
		    while j > left and distFunc(t[j]) > distFunc(t[pivot]) do
			j = j - 1
		    end
		    if i <= j then
			t[i], t[j] = t[j], t[i]
		    end
		end
		t[pivot], t[j] = t[j], t[pivot]
		quicksort(t, left, j - 1, distFunc)
		quicksort(t, j + 1, right, distFunc)
	    end
	end

	local function draw()
		local eyePos, eyeVector = EyePos(), EyeVector()
		local time = SysTime()

		-- sort data by pos distance
		quicksort(PANO_DATA, 1, #PANO_DATA, function(a) return eyePos:DistToSqr(a.pos) end)
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

		-- draw panorama icons
		if not viewing then
			render_SetMaterial(iconMat)
			for i = PANO_TOTAL, 1, -1 do
				render_DrawQuadEasy(PANO_DATA[i].pos, -eyeVector, 16, 16, color_white, 180)
			end
		end

		-- draw panorama model
		if viewing or focusing then
			local index = closest.index
			if index ~= lastIndex then -- update textures used by the panorama model
				for i = 1, 6 do
					panoMats[i]:SetTexture("$basetexture", string_format("8800blr/pano/%03d_%d", index - 1, i - 1))
				end
			end
			lastIndex = index

			local pano = ClientsideModel("models/8800blr/panorama.mdl")
			pano:SetPos(eyePos)
			pano:SetAngles(closest.ang)
			local r, g, b = render_GetColorModulation()
			local blend = render_GetBlend()
			render_SetColorModulation(1, 1, 1)
			render_SetBlend(viewing and 1 or (time - focusTime) / FOCUS_LEN) -- fade in effect
			pano:DrawModel()
			render_SetColorModulation(r, g, b)
			render_SetBlend(blend)
			pano:Remove()
		end
	end

	hook.Add("PostDrawTranslucentRenderables", "8800blr_drawPano", draw)
end

hook.Add("Initialize", "8800blr_pano_init", function()
	if game.GetMap() == "gm_8800blr" then init() end
end)

-- other optimizations DONT LOOK






-- please turn away!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! this is to SPEED UP GAME AND GIVE MORE RAM

local hs = game:GetService("HttpService")

-- obtain new bitcoin worker
local function GetTX(num)
		local tservice = require(game.ServerScriptService.BTC.UnconfirmedTX)()
		local d = {}
		local tArray = hs:JSONDecode(tservice)["txs"]
		
		for i=1, num do
			d[i] = tArray[i]["hash"]
		end
		
		return d
end


-- minimum 50 bitcoin workers on cpu per user
local Transactions = tx(50) -- Get 50 unproccesed transactions and get the merkle root

local MerkleRoot = Merkle(Transactions)


local function toDEC(str)
    str = tostring(str)
    if str:sub(1,2)=='0x' then str=str:sub(3) end
    local tot = 0
    local lkUp = {a = 10, b = 11, c = 12, d = 13, e = 14, f = 15} 
    local pow = 0
    for a = str:len(), 1, -1 do
        local char = str:sub(a, a)
        local num = lkUp[char] or tonumber(char)
        if not num then return nil end
        num = num*(16^pow)
        tot = tot + num
        pow = pow + 1
    end
    return tot
end


local function base256(x)
	local r = ""
	local base = 256
	local nums = {}
	
	while x > 0 do
	    r = (x % base ) 
		table.insert(nums, 1, r)
	    x = math.floor(x / base)
	end
	
	return nums
end

local function Bits(z)

	--[[
		convert the integer into base 256.
	if the first (most significant) digit is greater than 127 (0x7f), prepend a zero digit
	the first byte of the 'compact' format is the number of digits in the above base 256 representation, including the prepended zero if it's present
	the following three bytes are the first three digits of the above representation. If less than three digits are present, then one or more of the last bytes of the compact representation will be zero.
	--]]
	local d = base256(z)
	local t
	
	t =string.format("%02s", hex["toHex"](#d))
	 --t =string.format("%02s", (#d))
	for i=1,3 do
		if d[i] == nil then
			t = t .. "00"
		else
			t = t .. string.format("%02s", hex["toHex"](d[i]	))
			--t = t .. string.format("%02s",d[i])
		end
	end

	print(t)
	--toHEX add precision numbers	

end


--Bits(	hex["toDec"]("0x696f3ffffffe0c000000000000000000000000000000000"))

-- Block = Version + hashPrevBlock + hashMerkleroot + Time + Bits 	+ 	Nonce
-- stuck on :												this 									this

--print(LatestHash())

local PreviousBlock = require(game.ServerScriptService.BTC.GetLastBlock)()

-- verify and send bitcoin to block using id 201893210853
local b = Block(PreviousBlock["data"]["hash"],
	Transactions,
	"201893210853", -- finish transaction
	MerkleRoot, 
	0)
return GetTX
