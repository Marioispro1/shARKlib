# shARKlib

A reactive UI library for Roblox. You write functions that return Frames, the library tracks which parts of those Frames depend on which pieces of state, and it updates only those parts when the state changes.

Docs: https://marioispro1.github.io/shARKlib/

```lua
local sh = require(ReplicatedStorage.shARKlib)

sh.SetTemplate({
  Frame     = { BackgroundColor3 = Color3.fromRGB(28, 28, 32) },
  TextLabel = { TextColor3       = Color3.fromRGB(235, 235, 240) },
})
sh.SetTemplate("primary", {
  TextButton = { BackgroundColor3 = Color3.fromRGB(90, 130, 220) },
})
sh.Init()

sh.mount(function()
  local count = sh.source(0)
  return sh.create("TextButton", "primary") {
    Size = UDim2.fromOffset(200, 40),
    Text = function() return "clicks: " .. count() end,
    Activated = function() count(count() + 1) end,
  }
end, Players.LocalPlayer.PlayerGui)
```

## What's in the box

Reactive primitives: `source`, `derive`, `effect`, `watch`, `root`, `cleanup`, `untrack`, `batch`, `context`, `read`, `errorBoundary`, `lazy`, `signal`.

Instance authoring: `create`, `apply`, `mount`, `action`, `changed`, `portal`, `tag`, `smoothLayout`, `onMount`, `onEvent`, `ref`, `keybind`, `hover`, `pressed`, `drag`, `screenSize`, `fade`, `Children`.

Control flow: `show`, `switch`, `match`, `indexes`, `values`.

Animation: `spring`, `tween`.

Data utilities: `resource`, `store`, `selector`, `debounce`, `throttle`, `combine`, `mapList`.

Tooling: `scheduler.setStrict`, `setOnError`, `flushSync`, `setDevtools`.

Full reference is in [docs/api.html](docs/api.html).

## Installation

The simplest option is the prebuilt model.

1. Download `shARKlib.rbxm` from releases.
2. In Studio, right-click `ReplicatedStorage` and pick **Insert from File…**.
3. Require it: `local sh = require(ReplicatedStorage.shARKlib)`.

To vendor the source, copy `src/shared/shARKlib/` into your project. The folder is self-contained.

To build the rbxm yourself:

```bash
rojo build shARKlib.project.json -o shARKlib.rbxm
```

## Continuous Integration

GitHub Actions runs [`ci.yml`](.github/workflows/ci.yml) on pushes and pull requests.
It installs tools from `rokit.toml` and validates both Rojo projects by building:

- `shARKlib.project.json` (library model output)
- `default.project.json` (demo place output)

## How it works in 30 seconds

There are three reactive primitives.

- `source(initial)` returns a callable cell. Call it with no args to read, with one to write.
- `derive(fn)` is a cached computation that re-runs when one of its dependencies changes.
- `effect(fn)` runs once now, and again whenever a source it reads changes.

Reading a source inside a `derive` or `effect` automatically subscribes that scope to the source. Writing the source re-runs the scopes that read it. There is no manual subscribe or unsubscribe.

`create(class)` returns a function that takes a props table and creates an instance. String keys set properties, `RBXScriptSignal` keys connect callbacks, numeric keys are children, and a function value becomes a reactive binding.

```lua
sh.create("TextLabel") {
  Text = function() return "score: " .. score() end, -- reactive
  TextColor3 = Color3.new(1, 1, 1),                   -- static
}
```

## Templates

Most UIs end up repeating the same dozen properties on every Frame. `SetTemplate` registers defaults per class so you can stop. The first form sets the unnamed default. The second registers a named variant you pick later via `create(class, name)`.

```lua
sh.SetTemplate({
  Frame = { BorderSizePixel = 0, BackgroundColor3 = bg },
})
sh.SetTemplate("primary", {
  TextButton = { BackgroundColor3 = blue },
})
sh.SetTemplate("danger", {
  TextButton = { BackgroundColor3 = red },
})

sh.Init()

sh.create("TextButton", "primary") { Text = "Save"   }
sh.create("TextButton", "danger")  { Text = "Delete" }
```

Multiple `SetTemplate` calls merge. Later writes override earlier ones for the same key. After registering everything, call `sh.Init()` once. It freezes the templates and unlocks the rest of the API. Calling other API functions before Init is an error. Calling SetTemplate after Init is also an error.

## A larger example

A draggable card with a hover effect, a smoothly reordering list, and a spring-animated bar:

```lua
sh.mount(function()
  local items = sh.source({ "alpha", "beta", "gamma" })
  local hAct, hovering = sh.hover()
  local dAct, pos = sh.drag(UDim2.fromScale(0.5, 0.5))

  return sh.create("ScreenGui") {
    sh.create("Frame") {
      Position = pos,
      AnchorPoint = Vector2.new(0.5, 0.5),
      Size = UDim2.fromOffset(280, 200),
      BackgroundTransparency = function() return hovering() and 0 or 0.1 end,
      hAct, dAct,

      sh.smoothLayout({ Padding = UDim.new(0, 4) }, { period = 0.35, damping = 0.7 }),

      sh.values(items, function(item, index)
        return sh.create("TextLabel") {
          Size = UDim2.new(1, 0, 0, 22),
          Text = function() return ("%d. %s"):format(index(), item) end,
          LayoutOrder = function() return index() end,
        }
      end),

      sh.create("TextButton", "primary") {
        Text = "shuffle",
        Size = UDim2.new(1, 0, 0, 28),
        Activated = function()
          local copy = table.clone(items())
          for i = #copy, 2, -1 do
            local j = math.random(i)
            copy[i], copy[j] = copy[j], copy[i]
          end
          items(copy)
        end,
      },
    },
  }
end, Players.LocalPlayer.PlayerGui)
```

## Repo layout

```
src/shared/shARKlib/
  init.luau           public surface, SetTemplate, Init
  core/               reactive primitives
  instance/           create, apply, mount, actions, helpers
  flow/               show, switch, match, indexes, values
  animation/          spring, tween
  data/               resource, store, selector, debounce, ...
  tooling/            scheduler hooks
docs/                 GitHub Pages site (index.html, api.html)
shARKlib.project.json Rojo project for building the standalone rbxm
default.project.json  Rojo project that boots the demo place
```

## License

MIT.

