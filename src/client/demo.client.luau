--!nonstrict
-- end-to-end smoke test for every public shARKlib export.
-- mounts a single scrollingframe with one labeled card per feature.
-- intended to be eyeballed in studio play mode.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local sh = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("shARKlib"))

----------------------------------------------------------------------
-- templates
----------------------------------------------------------------------

sh.SetTemplate({
	ScreenGui = { ResetOnSpawn = false, IgnoreGuiInset = true },
	ScrollingFrame = {
		BackgroundColor3 = Color3.fromRGB(8, 12, 22),
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	},
	Frame = {
		BackgroundColor3 = Color3.fromRGB(18, 24, 38),
		BorderSizePixel = 0,
	},
	TextLabel = {
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(230, 235, 245),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	},
	TextButton = {
		BackgroundColor3 = Color3.fromRGB(34, 211, 238),
		TextColor3 = Color3.fromRGB(2, 16, 24),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
	},
	TextBox = {
		BackgroundColor3 = Color3.fromRGB(10, 16, 28),
		TextColor3 = Color3.fromRGB(230, 235, 245),
		BorderSizePixel = 0,
		Font = Enum.Font.Code,
		TextSize = 14,
		ClearTextOnFocus = false,
	},
})

sh.SetTemplate("title", {
	TextLabel = { TextSize = 16, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(34, 211, 238) },
})
sh.SetTemplate("danger", {
	TextButton = { BackgroundColor3 = Color3.fromRGB(248, 113, 113), TextColor3 = Color3.fromRGB(20, 0, 0) },
})

sh.Init()

----------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------

local function Card(title: string, body)
	return sh.create("Frame")({
		Size = UDim2.new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		sh.create("UIPadding")({
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		sh.create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		sh.create("UIListLayout")({
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		sh.create("TextLabel", "title")({
			Text = title,
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = 1,
		}),
		body,
	})
end

local function Status(getText)
	return sh.create("TextLabel")({
		Size = UDim2.new(1, 0, 0, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = getText,
		TextWrapped = true,
		LayoutOrder = 10,
	})
end

local function Row(...)
	local children = { ... }
	local row = sh.create("Frame")({
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		LayoutOrder = 5,
		sh.create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for i, c in ipairs(children) do
		c.LayoutOrder = i
		c.Parent = row
	end
	return row
end

----------------------------------------------------------------------
-- destroy host of any previous run
----------------------------------------------------------------------

local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local existing = pg:FindFirstChild("shARKlibDemo")
if existing then
	existing:Destroy()
end

----------------------------------------------------------------------
-- the demo
----------------------------------------------------------------------

local destroy = sh.mount(function()
	-- 1. source / derive / effect / watch / untrack / batch / cleanup
	local count = sh.source(0)
	local doubled = sh.derive(function()
		return count() * 2
	end)
	local effectRuns = sh.source(0)
	local _effectN = 0
	sh.effect(function()
		count() -- subscribe
		_effectN += 1
		effectRuns(_effectN) -- write only; reading effectRuns inside would self-loop
		sh.cleanup(function() end) -- exercise cleanup() registration
	end)
	local watchRuns = sh.source(0)
	sh.watch(count, function()
		watchRuns(watchRuns() + 1)
	end)

	-- 2. signal
	local sig = sh.signal()
	local sigCount = sh.source(0)
	sig:connect(function(n)
		sigCount(sigCount() + n)
	end)

	-- 3. show / switch / match
	local mode = sh.source("a")
	local visible = sh.source(true)

	-- 4. indexes / values
	local items = sh.source({ "alpha", "beta", "gamma" })
	local function shuffle()
		local copy = table.clone(items())
		for i = #copy, 2, -1 do
			local j = math.random(i)
			copy[i], copy[j] = copy[j], copy[i]
		end
		items(copy)
	end

	-- 5. spring / tween bound to the same target
	local target = sh.source(0)
	local sprung = sh.spring(target, 0.4, 0.7)
	local tweened = sh.tween(target, TweenInfo.new(0.5, Enum.EasingStyle.Quad))

	-- 6. data utilities
	local typed = sh.source("")
	local debounced = sh.debounce(typed, 0.5)
	local throttled = sh.throttle(typed, 0.3)
	local combined = sh.combine(count, doubled, function(a, b)
		return a + b
	end)
	local mapped = sh.mapList(items, function(item, i)
		return string.format("[%d] %s", i, item)
	end)

	-- 7. store + selector
	local store = sh.store({ name = "Ada", level = 1 })
	local activeId = sh.source("a")
	local sel = sh.selector(activeId)

	-- 8. resource
	local fetched, fetchStatus = sh.resource(function()
		task.wait(0.5)
		if math.random() < 0.15 then
			error("simulated fetch failure")
		end
		return "fetched at " .. os.date("%X")
	end)

	-- 9. errorBoundary
	local breakIt = sh.source(false)
	local safe = sh.errorBoundary(function()
		if breakIt() then
			error("kaboom")
		end
		return "ok"
	end, function(err, reset)
		return "caught: " .. tostring(err) .. " (will retry)"
	end)

	-- 10. context
	local ThemeCtx = sh.context("light")
	local theme
	ThemeCtx:provide("dark", function()
		theme = ThemeCtx:read()
	end)

	-- 11. lazy
	local lazyComp = sh.lazy(function()
		return function()
			return sh.create("TextLabel")({
				Text = "lazy-loaded label (built on first render)",
				Size = UDim2.new(1, 0, 0, 20),
			})
		end
	end)

	-- 12. screenSize / drag / hover / pressed / keybind / changed / ref / onMount / onEvent / tag / fade
	local screenSize = sh.screenSize()
	local hAct, hovering = sh.hover()
	local pAct, isDown = sh.pressed()
	local dAct, dragPos = sh.drag(UDim2.fromOffset(40, 40))
	local refTarget
	local mountSeen = sh.source(false)
	local typedTextRef = sh.source("")
	local clickCount = sh.source(0)

	sh.keybind(Enum.KeyCode.Space, function()
		count(count() + 1)
	end)

	-- scheduler hooks
	sh.scheduler.setStrict(false)
	sh.scheduler.setOnError(function(err)
		warn("[shARKlib demo] caught:", err)
	end)

	----------------------------------------------------------------
	-- the ui itself
	----------------------------------------------------------------

	return sh.create("ScreenGui")({
		Name = "shARKlibDemo",

		-- portal target lives outside the main tree
		sh.create("Folder")({ Name = "PortalHost" }),

		sh.create("ScrollingFrame")({
			Size = UDim2.fromScale(1, 1),
			sh.create("UIPadding")({
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			sh.create("UIListLayout")({
				Padding = UDim.new(0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- ---- header ----
			sh.create("TextLabel")({
				Size = UDim2.new(1, 0, 0, 28),
				Text = "shARKlib feature demo",
				TextSize = 22,
				Font = Enum.Font.GothamBold,
				TextColor3 = Color3.fromRGB(34, 211, 238),
				LayoutOrder = 0,
			}),
			sh.create("TextLabel")({
				Size = UDim2.new(1, 0, 0, 18),
				Text = function()
					return "viewport: " .. tostring(screenSize())
				end,
				TextColor3 = Color3.fromRGB(150, 160, 180),
				LayoutOrder = 1,
			}),

			-- ---- card 1: source / derive / effect / watch ----
			sh.create("Frame")({ LayoutOrder = 10, Visible = false, Size = UDim2.new() }), -- spacer
			Card(
				"1. source / derive / effect / watch / batch / untrack",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 11,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return string.format(
							"count=%d  doubled=%d  effectRuns=%d  watchRuns=%d",
							count(),
							doubled(),
							effectRuns(),
							watchRuns()
						)
					end),
					Row(
						sh.create("TextButton")({
							Size = UDim2.fromOffset(80, 26),
							Text = "+1",
							Activated = function()
								count(count() + 1)
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(120, 26),
							Text = "batch +5",
							Activated = function()
								sh.batch(function()
									for _ = 1, 5 do
										count(count() + 1)
									end
								end)
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(120, 26),
							Text = "untrack read",
							Activated = function()
								local v = sh.untrack(function()
									return count()
								end)
								print("[demo] untracked read =", v)
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(120, 26),
							Text = "+1 (space too)",
							Activated = function()
								count(count() + 1)
							end,
						})
					),
				})
			),

			-- ---- card 2: signal ----
			Card(
				"2. signal (pub/sub)",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 12,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return "fired sum: " .. sigCount()
					end),
					Row(sh.create("TextButton")({
						Size = UDim2.fromOffset(120, 26),
						Text = "fire(3)",
						Activated = function()
							sig:fire(3)
						end,
					})),
				})
			),

			-- ---- card 3: show / switch / match ----
			Card(
				"3. show / switch / match",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 13,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return "mode=" .. mode() .. "   visible=" .. tostring(visible())
					end),
					Row(
						sh.create("TextButton")({
							Size = UDim2.fromOffset(80, 26),
							Text = "a",
							Activated = function()
								mode("a")
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(80, 26),
							Text = "b",
							Activated = function()
								mode("b")
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(80, 26),
							Text = "c",
							Activated = function()
								mode("c")
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(120, 26),
							Text = "toggle visible",
							Activated = function()
								visible(not visible())
							end,
						})
					),
					sh.show(visible, function()
						return sh.create("TextLabel")({
							Size = UDim2.new(1, 0, 0, 18),
							Text = "[show] visible right now",
						})
					end, function()
						return sh.create("TextLabel")({
							Size = UDim2.new(1, 0, 0, 18),
							Text = "[show] hidden (fallback)",
							TextColor3 = Color3.fromRGB(150, 160, 180),
						})
					end),
					sh.switch(mode)({
						a = function()
							return sh.create("TextLabel")({
								Size = UDim2.new(1, 0, 0, 18),
								Text = "[switch] you picked A",
							})
						end,
						b = function()
							return sh.create("TextLabel")({
								Size = UDim2.new(1, 0, 0, 18),
								Text = "[switch] you picked B",
							})
						end,
						c = function()
							return sh.create("TextLabel")({
								Size = UDim2.new(1, 0, 0, 18),
								Text = "[switch] you picked C",
							})
						end,
					}),
					sh.match(count)({
						{
							function(n)
								return n == 0
							end,
							function()
								return sh.create("TextLabel")({
									Size = UDim2.new(1, 0, 0, 18),
									Text = "[match] count is zero",
								})
							end,
						},
						{
							function(n)
								return n < 5
							end,
							function()
								return sh.create("TextLabel")({
									Size = UDim2.new(1, 0, 0, 18),
									Text = "[match] count is small",
								})
							end,
						},
						{
							function()
								return true
							end,
							function()
								return sh.create("TextLabel")({
									Size = UDim2.new(1, 0, 0, 18),
									Text = "[match] count is large",
								})
							end,
						},
					}),
				})
			),

			-- ---- card 4: indexes / values ----
			Card(
				"4. indexes / values + smoothLayout",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 200),
					LayoutOrder = 14,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 8) }),
					Row(
						sh.create("TextButton")({
							Size = UDim2.fromOffset(120, 26),
							Text = "shuffle",
							Activated = shuffle,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(120, 26),
							Text = "push item",
							Activated = function()
								local copy = table.clone(items())
								table.insert(copy, "item-" .. (#copy + 1))
								items(copy)
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(120, 26),
							Text = "pop",
							Activated = function()
								local copy = table.clone(items())
								copy[#copy] = nil
								items(copy)
							end,
						})
					),
					sh.create("Frame")({
						Size = UDim2.new(1, 0, 0, 140),
						BackgroundColor3 = Color3.fromRGB(10, 16, 28),
						sh.create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
						sh.create("UIPadding")({ PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6) }),
						sh.smoothLayout({ Padding = UDim.new(0, 4) }, { period = 0.35, damping = 0.7 }),
						sh.values(items, function(item, index)
							return sh.create("TextLabel")({
								Size = UDim2.new(1, -12, 0, 22),
								BackgroundColor3 = Color3.fromRGB(34, 211, 238),
								BackgroundTransparency = 0.85,
								Text = function()
									return string.format("(values keyed) %d. %s", index(), item)
								end,
								LayoutOrder = function()
									return index()
								end,
								sh.create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
								sh.fade({ duration = 0.25, fadeOut = false }),
							})
						end),
					}),
				})
			),

			-- ---- card 5: spring / tween / combine / mapList ----
			Card(
				"5. spring / tween / combine / mapList",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 15,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return string.format(
							"target=%d  spring=%.2f  tween=%.2f  combined=%d  list=[%s]",
							target(),
							sprung(),
							tweened(),
							combined(),
							table.concat(mapped(), ", ")
						)
					end),
					Row(
						sh.create("TextButton")({
							Size = UDim2.fromOffset(80, 26),
							Text = "+25",
							Activated = function()
								target(target() + 25)
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(80, 26),
							Text = "-25",
							Activated = function()
								target(target() - 25)
							end,
						})
					),
					sh.create("Frame")({
						Size = UDim2.new(1, 0, 0, 14),
						BackgroundColor3 = Color3.fromRGB(10, 16, 28),
						sh.create("Frame")({
							Size = function()
								return UDim2.new(0, math.max(sprung(), 0), 1, 0)
							end,
							BackgroundColor3 = Color3.fromRGB(34, 211, 238),
						}),
					}),
					sh.create("Frame")({
						Size = UDim2.new(1, 0, 0, 14),
						BackgroundColor3 = Color3.fromRGB(10, 16, 28),
						sh.create("Frame")({
							Size = function()
								return UDim2.new(0, math.max(tweened(), 0), 1, 0)
							end,
							BackgroundColor3 = Color3.fromRGB(244, 114, 182),
						}),
					}),
				})
			),

			-- ---- card 6: debounce / throttle ----
			Card(
				"6. debounce / throttle (type fast)",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 16,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					sh.create("TextBox")({
						Size = UDim2.new(1, 0, 0, 28),
						PlaceholderText = "type something...",
						Text = function()
							return typed()
						end,
						sh.changed("Text", function(v)
							typed(v)
						end),
					}),
					Status(function()
						return string.format(
							"immediate='%s'  debounced(0.5s)='%s'  throttled(0.3s)='%s'",
							typed(),
							debounced(),
							throttled()
						)
					end),
				})
			),

			-- ---- card 7: store / selector ----
			Card(
				"7. store / selector",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 17,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return string.format("store: name=%s  level=%d", store:read().name, store:read().level)
					end),
					Row(
						sh.create("TextButton")({
							Size = UDim2.fromOffset(140, 26),
							Text = "level up",
							Activated = function()
								store:set("level", store:read().level + 1)
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(140, 26),
							Text = "rename",
							Activated = function()
								local names = { "Ada", "Grace", "Linus", "Margaret", "Donald" }
								store:set("name", names[math.random(1, #names)])
							end,
						})
					),
					Status(function()
						return string.format(
							"active=%s  selA=%s  selB=%s  selC=%s",
							activeId(),
							tostring(sel("a")()),
							tostring(sel("b")()),
							tostring(sel("c")())
						)
					end),
					Row(
						sh.create("TextButton")({
							Size = UDim2.fromOffset(60, 26),
							Text = "select A",
							Activated = function()
								activeId("a")
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(60, 26),
							Text = "select B",
							Activated = function()
								activeId("b")
							end,
						}),
						sh.create("TextButton")({
							Size = UDim2.fromOffset(60, 26),
							Text = "select C",
							Activated = function()
								activeId("c")
							end,
						})
					),
				})
			),

			-- ---- card 8: resource ----
			Card(
				"8. resource (async loader)",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 18,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						if fetchStatus.loading() then
							return "loading..."
						end
						if fetchStatus.error() then
							return "error: " .. tostring(fetchStatus.error())
						end
						return "value: " .. tostring(fetched())
					end),
					Row(sh.create("TextButton")({
						Size = UDim2.fromOffset(120, 26),
						Text = "refetch",
						Activated = function()
							fetchStatus.refetch()
						end,
					})),
				})
			),

			-- ---- card 9: errorBoundary / lazy / context ----
			Card(
				"9. errorBoundary / lazy / context",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 19,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return "boundary says: " .. tostring(safe())
					end),
					Status(function()
						return "context theme: " .. tostring(theme)
					end),
					Row(sh.create("TextButton", "danger")({
						Size = UDim2.fromOffset(140, 26),
						Text = "throw error",
						Activated = function()
							breakIt(true)
							task.wait(0.5)
							breakIt(false)
						end,
					})),
					lazyComp(),
				})
			),

			-- ---- card 10: instance helpers ----
			Card(
				"10. hover / pressed / drag / ref / onMount / onEvent / tag / changed / fade",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 20,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 6) }),
					Status(function()
						return string.format(
							"hover=%s  pressed=%s  clicks(onEvent)=%d  ref=%s  mounted=%s  typed-via-changed='%s'",
							tostring(hovering()),
							tostring(isDown()),
							clickCount(),
							tostring(refTarget and refTarget.Name or "nil"),
							tostring(mountSeen()),
							typedTextRef()
						)
					end),
					sh.create("TextButton")({
						Size = UDim2.fromOffset(220, 36),
						Text = function()
							return hovering() and "hovering" or (isDown() and "pressed" or "hover/press me")
						end,
						BackgroundColor3 = function()
							if isDown() then
								return Color3.fromRGB(244, 114, 182)
							end
							if hovering() then
								return Color3.fromRGB(103, 232, 249)
							end
							return Color3.fromRGB(34, 211, 238)
						end,
						hAct,
						pAct,
						sh.ref(function(inst)
							refTarget = inst
						end),
						sh.onMount(function(inst)
							mountSeen(true)
							print("[demo] onMount fired for", inst:GetFullName())
						end),
						sh.onEvent("Activated", function()
							clickCount(clickCount() + 1)
						end),
						sh.tag("shARKlibDemoButton"),
						sh.changed("Text", function(v)
							typedTextRef(v)
						end),
					}),
					sh.create("Frame")({
						Size = UDim2.new(1, 0, 0, 140),
						BackgroundColor3 = Color3.fromRGB(10, 16, 28),
						sh.create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
						sh.create("Frame")({
							Size = UDim2.fromOffset(80, 80),
							Position = dragPos,
							BackgroundColor3 = Color3.fromRGB(248, 113, 113),
							Text = "drag me",
							sh.create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
							dAct,
							sh.create("TextLabel")({
								Size = UDim2.fromScale(1, 1),
								Text = "drag me",
								TextXAlignment = Enum.TextXAlignment.Center,
							}),
						}),
					}),
				})
			),

			-- ---- card 11: portal ----
			Card(
				"11. portal",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 21,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return "child below is rendered into PlayerGui directly via portal()"
					end),
					sh.portal(pg, function()
						return sh.create("ScreenGui")({
							Name = "shARKlibDemoPortal",
							ResetOnSpawn = false,
							sh.create("Frame")({
								Size = UDim2.fromOffset(180, 28),
								Position = UDim2.new(1, -190, 0, 10),
								BackgroundColor3 = Color3.fromRGB(34, 211, 238),
								sh.create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
								sh.create("TextLabel")({
									Size = UDim2.fromScale(1, 1),
									TextXAlignment = Enum.TextXAlignment.Center,
									TextColor3 = Color3.fromRGB(2, 16, 24),
									Font = Enum.Font.GothamBold,
									Text = function()
										return "portal · count=" .. count()
									end,
								}),
							}),
						})
					end),
				})
			),

			-- ---- card 12: scheduler / flushSync ----
			Card(
				"12. scheduler.flushSync()",
				sh.create("Frame")({
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 22,
					sh.create("UIListLayout")({ Padding = UDim.new(0, 4) }),
					Status(function()
						return "press the button; check the output for ordering"
					end),
					Row(sh.create("TextButton")({
						Size = UDim2.fromOffset(180, 26),
						Text = "batch + flushSync",
						Activated = function()
							sh.batch(function()
								count(count() + 100)
								sh.scheduler.flushSync()
								print("[demo] mid-batch count =", count(), "doubled =", doubled())
							end)
						end,
					})),
				})
			),
		}),
	})
end, pg)

----------------------------------------------------------------------
-- check tag (CollectionService) attached after one frame
----------------------------------------------------------------------

task.delay(0.1, function()
	local tagged = CollectionService:GetTagged("shARKlibDemoButton")
	print(string.format("[demo] CollectionService sees %d tagged button(s)", #tagged))
end)

print("[demo] mounted. press space to bump the counter. press F8 to stop.")
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.F8 then
		print("[demo] tearing down")
		destroy()
	end
end)
