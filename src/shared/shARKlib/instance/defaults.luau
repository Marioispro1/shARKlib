--!strict
--[[
    defaults.luau
    Default property overrides applied to instances created via
    `create(className)` so newly created GUI elements aren't loudly
    styled by Roblox's stock defaults (borders, transparent text, etc).
]]

local defaults: { [string]: { [string]: any } } = {
	ScreenGui = {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	},
	BillboardGui = { Active = true },
	SurfaceGui = {
		Active = true,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 50,
	},
	Frame = { BorderSizePixel = 0 },
	ScrollingFrame = {
		BorderSizePixel = 0,
		ScrollBarImageColor3 = Color3.new(0, 0, 0),
	},
	TextLabel = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Font.fromEnum(Enum.Font.Ubuntu),
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
	},
	TextButton = {
		AutoButtonColor = false,
		BorderSizePixel = 0,
		FontFace = Font.fromEnum(Enum.Font.Ubuntu),
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
	},
	TextBox = {
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		FontFace = Font.fromEnum(Enum.Font.Ubuntu),
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
	},
	ImageLabel = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	},
	ImageButton = {
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	},
	ViewportFrame = { BorderSizePixel = 0 },
}

return defaults
