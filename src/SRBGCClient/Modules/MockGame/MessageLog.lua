-- Utility for a simple game message log.

-- RobloxBoardGameClient
local RobloxBoardGameClient = script.Parent.Parent.Parent.Parent.RobloxBoardGameClient
local GuiUtils = require(RobloxBoardGameClient.Modules.GuiUtils)

local MessageLog = {}
MessageLog.__index = MessageLog

export type MessageLog = {
    -- members
    parent: Frame,
    scrollingFrame: ScrollingFrame,
    messageLayoutOrder: number,

    -- static functions.
    new: (parent: Frame) -> ScrollingFrame,

    -- non static member functions.
    addMessage: (MessageLog, message: string) -> nil,
}

MessageLog.new = function(parent:Frame): MessageLog
    local self = setmetatable({}, MessageLog)

    self.parent = parent
    self.scrollingFrame = Instance.new("ScrollingFrame")
    self.scrollingFrame.Name = "MessageLog"
    self.scrollingFrame.Size = UDim2.new(1, -10, 0, 50)
    self.scrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    self.scrollingFrame.BackgroundColor3 = Color3.fromRGB(230, 210, 200)
    self.scrollingFrame.ScrollBarThickness = 8
    self.scrollingFrame.ScrollingEnabled = true
    self.scrollingFrame.Parent = parent
    self.scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.scrollingFrame.CanvasSize = UDim2.new(1, 0, 0, 0)

    self.messageLayoutOrder = 1

    GuiUtils.addUIListLayout(self.scrollingFrame, {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })

    self.scrollingFrame.ChildAdded:Connect(function(_)
        task.wait() -- delay for one frame to ensure child has been positioned
        -- set the canvasPosition to the bottom of the scrolling frame
        self.scrollingFrame.CanvasPosition = Vector2.new(0, self.scrollingFrame.CanvasSize.Y.Offset - self.scrollingFrame.AbsoluteSize.Y)
    end)

    return self
end

function MessageLog:addMessage(message: string)
    local layoutOrder = self.messageLayoutOrder
    self.messageLayoutOrder = self.messageLayoutOrder + 1

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, 0, 0, 20)
    messageLabel.Position = UDim2.new(0, 0, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextSize = 14
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = self.scrollingFrame
    messageLabel.LayoutOrder = layoutOrder
end

function MessageLog:destroy()
    self.scrollingFrame:Destroy()
end

return MessageLog