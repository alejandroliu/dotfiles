local config = import("micro/config")
local micro = import("micro")
--~ local shell = import("micro/shell")

function MouseToggle()
  cmouse = config.GetGlobalOption("mouse")
  if cmouse then
    config.SetGlobalOption("mouse","false")
    micro.InfoBar():Message("Mouse control is now DISABLED")
  else
    config.SetGlobalOption("mouse","true")
    micro.InfoBar():Message("Mouse control is now ENABLED")
  end

end

function init()
  config.TryBindKey("Alt-m", "lua:initlua.MouseToggle", true)
end

