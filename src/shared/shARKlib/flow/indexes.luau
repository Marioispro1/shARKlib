--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sh = require(ReplicatedStorage.shARKlib)

sh.SetTemplate({
	Frame = {
		BackgroundColor3 = Color3.fromRGB(28, 28, 32),
		BorderSizePixel = 0,
	},
	TextLabel = {
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(235, 235, 240),
		TextSize = 14,
		Font = Enum.Font.Code,
	},
	TextButton = {
		BackgroundColor3 = Color3.fromRGB(50, 50, 58),
		TextColor3 = Color3.fromRGB(235, 235, 240),
		BorderSizePixel = 0,
		TextSize = 14,
		Font = Enum.Font.Code,
	},
})
sh.SetTemplate("accent", {
	TextButton = {
		BackgroundColor3 = Color3.fromRGB(34, 211, 238),
		TextColor3 = Color3.fromRGB(10, 10, 20),
	},
})
sh.SetTemplate("danger", {
	TextButton = {
		BackgroundColor3 = Color3.fromRGB(220, 60, 60),
		TextColor3 = Color3.fromRGB(255, 255, 255),
	},
})
sh.Init()

local function IndexesDemo()
	local list = sh.source({ 10, 20, 30 })
	local log  = sh.source({} :: { string })

	local function addLog(msg: string)
		local t = os.clock()
		local entry = string.format("[%.2f] %s", t, msg)
		local copy = table.clone(log())
		table.insert(copy, entry)
		if #copy > 6 then table.remove(copy, 1) end
		log(copy)
	end

	local function pushItem()
		local copy = table.clone(list())
		local v = math.random(10, 99)
		table.insert(copy, v)
		addLog("push(" .. v .. ")  len=" .. #copy)
		list(copy)
	end

	local function popItem()
		local copy = table.clone(list())
		if #copy == 0 then addLog("list is empty") return end
		local v = table.remove(copy)
		addLog("pop() removed " .. tostring(v) .. "  len=" .. #copy)
		list(copy)
	end

	local function updateRandom()
		local copy = table.clone(list())
		if #copy == 0 then addLog("list is empty") return end
		local i = math.random(1, #copy)
		local old = copy[i]
		local new = math.random(10, 99)
		copy[i] = new
		addLog("arr[" .. i .. "]  " .. old .. " → " .. new)
		list(copy)
	end

	local function resetList()
		addLog("reset → {10, 20, 30}")
		list({ 10, 20, 30 })
	end

	local rows = sh.indexes(list, function(valSrc, idx)
		return sh.create("Frame") {
			Size = UDim2.new(1, 0, 0, 28),
			sh.create("TextLabel") {
				Size = UDim2.fromOffset(30, 28),
				Text = "[" .. idx .. "]",
				TextColor3 = Color3.fromRGB(120, 120, 140),
			},
			sh.create("TextLabel") {
				Size = UDim2.new(1, -30, 1, 0),
				Position = UDim2.fromOffset(30, 0),
				Text = function() return tostring(valSrc()) end,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
		}
	end)

	local logRows = sh.indexes(log, function(entrySrc, _idx)
		return sh.create("TextLabel") {
			Size = UDim2.new(1, 0, 0, 18),
			Text = function() return entrySrc() end,
			TextColor3 = Color3.fromRGB(100, 200, 130),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 11,
		}
	end)

	return sh.create("Frame") {
		Size = UDim2.fromOffset(340, 420),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		sh.create("UICorner") { CornerRadius = UDim.new(0, 8) },
		sh.create("UIPadding") {
			PaddingTop    = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft   = UDim.new(0, 12),
			PaddingRight  = UDim.new(0, 12),
		},
		sh.create("UIListLayout") {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		},

		-- title
		sh.create("TextLabel") {
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, 22),
			Text = "indexes() demo",
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(200, 200, 220),
		},

		-- list display
		sh.create("Frame") {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 130),
			sh.create("UICorner") { CornerRadius = UDim.new(0, 4) },
			sh.create("UIPadding") {
				PaddingTop   = UDim.new(0, 6),
				PaddingLeft  = UDim.new(0, 6),
				PaddingRight = UDim.new(0, 6),
			},
			sh.create("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			},
			function() return rows() end,
		},

		-- buttons row 1
		sh.create("Frame") {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			sh.create("UIListLayout") {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			},
			sh.create("TextButton", "accent") {
				LayoutOrder = 1,
				Size = UDim2.fromOffset(90, 32),
				Text = "+ push",
				sh.create("UICorner") { CornerRadius = UDim.new(0, 6) },
				Activated = pushItem,
			},
			sh.create("TextButton", "danger") {
				LayoutOrder = 2,
				Size = UDim2.fromOffset(90, 32),
				Text = "- pop",
				sh.create("UICorner") { CornerRadius = UDim.new(0, 6) },
				Activated = popItem,
			},
			sh.create("TextButton") {
				LayoutOrder = 3,
				Size = UDim2.fromOffset(90, 32),
				Text = "~ update",
				sh.create("UICorner") { CornerRadius = UDim.new(0, 6) },
				Activated = updateRandom,
			},
			sh.create("TextButton") {
				LayoutOrder = 4,
				Size = UDim2.fromOffset(50, 32),
				Text = "reset",
				sh.create("UICorner") { CornerRadius = UDim.new(0, 6) },
				Activated = resetList,
			},
		},

		-- log
		sh.create("Frame") {
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 130),
			BackgroundColor3 = Color3.fromRGB(16, 16, 20),
			sh.create("UICorner") { CornerRadius = UDim.new(0, 4) },
			sh.create("UIPadding") {
				PaddingTop   = UDim.new(0, 6),
				PaddingLeft  = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 6),
			},
			sh.create("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 1),
			},
			function() return logRows() end,
		},
	}
end

local Players = game:GetService("Players")
sh.mount(IndexesDemo, Players.LocalPlayer:WaitForChild("PlayerGui"))