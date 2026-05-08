--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sh = require(ReplicatedStorage:WaitForChild("Shared").shARKlib)

-- register some templates before init
sh.SetTemplate({
	Frame = { BackgroundColor3 = Color3.fromRGB(28, 28, 32) },
	TextLabel = { TextColor3 = Color3.fromRGB(235, 235, 240) },
})
sh.SetTemplate("primary", {
	TextButton = { BackgroundColor3 = Color3.fromRGB(90, 130, 220) },
})
sh.SetTemplate("ghost", {
	TextButton = { BackgroundColor3 = Color3.fromRGB(70, 70, 80) },
})

sh.Init()

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

sh.mount(function()
	local count = sh.source(0)
	local items = sh.source({ "alpha", "beta", "gamma" })
	local progress = sh.spring(function()
		return UDim2.fromScale(math.min(count() / 10, 1), 1)
	end, 0.5, 0.7)

	return sh.create("ScreenGui")({
		Name = "shARKlibDemo",
		IgnoreGuiInset = true,

		sh.create("Frame")({
			Size = UDim2.fromOffset(320, 260),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(28, 28, 32),

			sh.create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
			sh.create("UIPadding")({
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			sh.create("UIListLayout")({
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			sh.create("TextLabel")({
				Size = UDim2.new(1, 0, 0, 24),
				Text = function()
					return ("count = %d"):format(count())
				end,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			sh.create("TextButton", "primary")({
				Size = UDim2.new(1, 0, 0, 28),
				Text = "increment",
				Activated = function()
					count(count() + 1)
				end,
				sh.create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
			}),

			-- animated progress bar
			sh.create("Frame")({
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = Color3.fromRGB(60, 60, 70),
				sh.create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				sh.create("Frame")({
					Size = progress,
					BackgroundColor3 = Color3.fromRGB(120, 220, 160),
					sh.create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
				}),
			}),

			sh.create("TextButton", "ghost")({
				Size = UDim2.new(1, 0, 0, 24),
				Text = "shuffle items",
				Activated = function()
					local copy = table.clone(items())
					for i = #copy, 2, -1 do
						local j = math.random(i)
						copy[i], copy[j] = copy[j], copy[i]
					end
					items(copy)
				end,
				sh.create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
			}),

			-- keyed list: re-uses textlabels across reorderings
			sh.create("Frame")({
				Size = UDim2.new(1, 0, 0, 90),
				BackgroundTransparency = 1,
				sh.smoothLayout({
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, { period = 0.35, damping = 0.7 }),
				sh.values(items, function(item, index)
					return sh.create("TextLabel")({
						Size = UDim2.new(1, 0, 0, 22),
						Text = function()
							return ("%d. %s"):format(index(), item)
						end,
						BackgroundColor3 = Color3.fromRGB(40, 40, 48),
						BackgroundTransparency = 0,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = function()
							return index()
						end,
						sh.create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
						sh.create("UIPadding")({ PaddingLeft = UDim.new(0, 8) }),
					})
				end),
			}),
		}),
	})
end, PlayerGui)
