script_name("GT3PEDAL")
script_author("KolaFiend + ChatGPT")
script_description("Gran Turismo 3 Replay Pedal HUD")
script_version("10.0")

require 'widgets'
require 'monetloader'

local imgui  = require 'mimgui'
local ffi    = require 'ffi'
local jsoncfg = require 'jsoncfg'

local mem = require 'SAMemory'
require 'SAMemory.game.CVehicle'
require 'SAMemory.game.CAutomobile'

local MDS = MONET_DPI_SCALE or 1.0

local filename = "GT3PEDAL"

local default_config = {
    ACTIVE = true,
    XPOSITION = 1650,
    YPOSITION = 820,
    XSCALE = 12,
    YSCALE = 92,
    GAP = 5,
    SHAPE = 0
}

local config =
    jsoncfg.load(default_config, filename)

jsoncfg.save(config, filename)

local states = {

    ACTIVE =
        config.ACTIVE,

    XPOSITION =
        config.XPOSITION,

    YPOSITION =
        config.YPOSITION,

    XSCALE =
        config.XSCALE,

    YSCALE =
        config.YSCALE,

    GAP =
        config.GAP,

    SHAPE =
        config.SHAPE or 0
}

imgui.Process = true

local showMenu =
    imgui.new.bool(false)

local function rgba(r, g, b, a)

    return imgui.ColorConvertFloat4ToU32(
        imgui.ImVec4(
            r / 255,
            g / 255,
            b / 255,
            a / 255
        )
    )
end

local COL_BG =
    rgba(0, 0, 0, 140)

local COL_WHITE =
    rgba(255, 255, 255, 255)

local COL_ACCEL =
    rgba(0, 255, 0, 255)

local COL_HANDBRAKE =
     rgba(238, 89, 33, 255)

local COL_BRAKE =
    rgba(255, 0, 0, 255)

local COL_REVERSE =
    rgba(255, 140, 0, 255)

local function clamp(v, lo, hi)

    return v < lo and lo or (
        v > hi and hi or v
    )
end

local function getVehiclePtr()

    local p =
        mem.player_vehicle[0]

    if p == nil or ffi.cast(
        "uintptr_t",
        p
    ) == 0 then
        return nil
    end

    return p
end

local function drawGT3Bar(
    dl,
    x,
    y,
    w,
    h,
    fill,
    label,
    color
)

    dl:AddText(
        imgui.ImVec2(
            x + 2 * MDS,
            y - 18 * MDS
        ),
        COL_WHITE,
        label
    )

    dl:AddRectFilled(
        imgui.ImVec2(
            x,
            y
        ),
        imgui.ImVec2(
            x + w,
            y + h
        ),
        COL_BG,
        0
    )

    -- FILL

    if fill > 0.001 then

        local fh = h * fill

        if states and states.SHAPE == 1 then

            local topY = y + h - fh
            local shrink = (1.0 - fill) * (w * 0.5)

            local pts = {
                imgui.ImVec2(x, y + h),
                imgui.ImVec2(x + w, y + h),
                imgui.ImVec2(x + w - shrink, topY),
                imgui.ImVec2(x + shrink, topY)
            }

            dl:AddConvexPolyFilled(
                pts,
                4,
                color
            )

        else

            dl:AddRectFilled(
                imgui.ImVec2(x, y + h - fh),
                imgui.ImVec2(x + w, y + h),
                color,
                0
            )

        end
    end
end

imgui.OnInitialize(function()

    imgui.GetIO().IniFilename = nil

    imgui.GetStyle():ScaleAllSizes(MDS)

end)

imgui.OnFrame(

    function()
        return true
    end,

    function()

        local screenW, screenH =
            getScreenResolution()

        if showMenu[0] then

            imgui.SetNextWindowSize(
                imgui.ImVec2(
                    420,
                    320
                ),
                imgui.Cond.FirstUseEver
            )

            imgui.Begin(
                "GT3PEDAL Settings",
                showMenu
            )

            local xpos =
                imgui.new.float(
                    states.XPOSITION
                )

            local ypos =
                imgui.new.float(
                    states.YPOSITION
                )

            local xscale =
                imgui.new.float(
                    states.XSCALE
                )

            local yscale =
                imgui.new.float(
                    states.YSCALE
                )

            local gap =
                imgui.new.float(
                    states.GAP
                )

            imgui.Text("Position")
            imgui.Separator()

            if imgui.SliderFloat(
                "X Position",
                xpos,
                0,
                screenW
            ) then

                states.XPOSITION =
                    xpos[0]
            end

            if imgui.SliderFloat(
                "Y Position",
                ypos,
                0,
                screenH
            ) then

                states.YPOSITION =
                    ypos[0]
            end

            imgui.Spacing()

            imgui.Text("Size")
            imgui.Separator()

            if imgui.SliderFloat(
                "Width",
                xscale,
                4,
                60
            ) then

                states.XSCALE =
                    xscale[0]
            end

            if imgui.SliderFloat(
                "Height",
                yscale,
                20,
                300
            ) then

                states.YSCALE =
                    yscale[0]
            end

            if imgui.SliderFloat(
                "Gap",
                gap,
                0,
                30
            ) then

                states.GAP =
                    gap[0]
            end

            jsoncfg.save(states, filename)

            local shape =
                imgui.new.int(
                    states.SHAPE
                )
            
            local shapeItems =
                ffi.new(
                    "const char *[2]",
                    {
                        "Rectangle",
                        "Triangle"
                    }
                )
            
            if imgui.Combo(
                "Shape",
                shape,
                shapeItems,
                2
            ) then
            
                states.SHAPE =
                    shape[0]
            
            end

            imgui.End()
        end

        if not states.ACTIVE then
            return
        end

        local ped =
            PLAYER_PED

        if not doesCharExist(
            ped
        ) then
            return
        end

        if not isCharInAnyCar(
            ped
        ) then
            return
        end

        local veh =
            getVehiclePtr()

        if not veh then
            return
        end

        local rawGas =
            tonumber(
                veh.fGasPedal
            ) or 0.0
        
        local rawBrake =
            tonumber(
                veh.fBreakPedal
            ) or 0.0
        
        local gasForward =
            clamp(
                rawGas,
                0.0,
                1.0
            )
        
        local gasReverse =
            clamp(
                -rawGas,
                0.0,
                1.0
            )
        
        local reversing =
            gasReverse > 0.01
        
        local accelFill =
            reversing
            and gasReverse
            or gasForward
        
        local brakeFill =
            clamp(
                rawBrake,
                0.0,
                1.0
            )
        
        local handbrakePressed =
            isWidgetPressed(
                WIDGET_HANDBRAKE
            )
        
        local barAFill =
            accelFill
        
        local barBFill =
            brakeFill
        
        local brakeColor =
            COL_BRAKE
        
        local accelColor =
            reversing
            and COL_REVERSE
            or COL_ACCEL
        
        if handbrakePressed then
        
            barBFill = 1.0
            brakeColor = COL_HANDBRAKE
        
            if brakeFill > 0.01 then
        
                barAFill = brakeFill
                accelColor = COL_BRAKE
        
            end
        
        end

        local barW =
            states.XSCALE * MDS

        local barH =
            states.YSCALE * MDS

        local gap =
            states.GAP * MDS

        local startX =
            states.XPOSITION

        local startY =
            states.YPOSITION

        local draw =
            imgui.GetBackgroundDrawList()

        drawGT3Bar(
            draw,
            startX,
            startY,
            barW,
            barH,
            barBFill,
            "B",
            brakeColor
        )

        drawGT3Bar(
            draw,
            startX + barW + gap,
            startY,
            barW,
            barH,
            barAFill,
            "A",
            accelColor
        )
    end
)

function main()

    repeat
        wait(100)
    until isSampAvailable()

    sampAddChatMessage(
        "[GT3PEDAL] Loaded.",
        -1
    )

    sampRegisterChatCommand(

        "pedal",

        function()

            showMenu[0] =
                not showMenu[0]
        end
    )

    while true do
        wait(0)
    end
end