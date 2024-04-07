-- Support Functions

local gitLink = "https://github.com/Warnickwar/WarSuite/tree/main/Warnet"
local termDimensions = { term.getSize() }
local styles = {
    foreground = colors.gray,
    background = colors.lightGray,
    text = colors.red,
    selectedText = colors.black,
    selectedBackground = colors.white,
    progress = colors.green
}
term.setPaletteColor(colors.red, 0xFF0000)
if not term.isColor() then
    styles.text = colors.lightGray
    styles.progress = colors.white
end

ProgressBar = {
    x = (termDimensions[1]/2)-14,
    w = 29,
    y = 12,
    h = 1,
    color = styles.progress,
    backgroundColor = styles.background,

    drawBar = function(o, val,max)
        if o.visible == false then return end
        local percent = val/max
        if percent<0 then percent=0 end
        if percent>100 then percent=100 end
        local result = math.floor(o.w*percent)
        for i=0,o.h-1 do
            term.setCursorPos(o.x,o.y+i)
            term.setBackgroundColor(o.color)
            for i=0,result do
                term.write("\x00")
            end
            term.setBackgroundColor(o.backgroundColor)
            for i=0,(o.w-result) do
                term.write("\x00")
            end
        end
        paintutils.drawBox(o.x-1,o.y-1,o.x+o.w+1,o.y+o.h,styles.foreground)
    end
}

local function printCentered(s,y)
    term.setCursorPos(termDimensions[1]/2-#s/2,y)
    term.write(s)
end

-- Actual GUI
term.clear()
term.setBackgroundColor(styles.background)
term.setCursorPos(1,1)
print(termDimensions[2])
for i=1,termDimensions[2] do
    term.setCursorPos(1,i)
    term.clearLine()
end
term.setTextColor(styles.text)
Title = paintutils.parseImage("e   e  ee  eee   e  e eee eee\ne   e e  e e  e  e  e e    e\ne e e e  e eee   ee e ee   e\ne e e eeee e  e  e ee e    e\n e e  e  e e  e  e  e eee  e\n")
paintutils.drawImage(Title,(termDimensions[1]/2)-14,2)
paintutils.drawBox((termDimensions[1]/2)-14, 8, (termDimensions[1]/2)+14,16, styles.foreground)