os.pullEvent = os.pullEventRaw

-- Support Functions

-- If this installer isn't obvious, I have zero clue wtf I'm doing

local repoLink = "https://raw.githubusercontent.com/Warnickwar/WarSuite/main/Warnet/"
local files = {
    programs = {
        ["WarnetInterface.lua"] = "Program/WarnetInterface.lua"
    },
    libs = {}
}
Address = ""
local termDimensions = { term.getSize() }
local styles = {
    foreground = colors.gray,
    background = colors.lightGray,
    text = colors.red,
    selectedText = colors.black,
    selectedBackground = colors.white,
    progress = colors.green
}
local selLine = 1

local function fromRepo(url)
    return { url = repoLink..url}
end

local function applyFile(path, content)
    local file = { fs.open(path,"wb") }
    if not file[1] then
        error("Cannot open file '$s'.\n$s"):format(path,file[2])
    end
    file[1].write(content)
    file[1].close()
end

local function downloadFile(path, file)
    local response = {http.get(fromRepo(file),nil,true)}
    if not response[1] then
        return nil
    end
    local content = response[1].readAll()
    response[1].close()

    applyFile(path,content)
end

local textArrs = {
    [1] = {
        "This app will guide you",
        "through the process of",
        "installing WARNET for",
        "your computer!",
        nil,
        nil,
        "Press \x1A to continue!"
    },
    [2] = {
        "Configuration",
        nil,
        "First, we need to go",
        "through some initial",
        "configuration setup!",
        nil,
        "Press \x1A to get started!"
    },
    [3] = { -- Selection list
        {"Assign new address", true},
        "Use Whitelist",
        "Use Blacklist"
    }
}
local page = 1

term.setPaletteColor(colors.red, 0xFF0000)
if not term.isColor() then
    styles.text = colors.lightGray
    styles.progress = colors.white
end

local ProgressBar = {
    x = (termDimensions[1]/2)-14,
    w = 29,
    y = 12,
    h = 1,
    progressColor = styles.progress,
    backgroundColor = styles.background,
    borderColor = styles.foreground,

    drawBar = function(o, val,max)
        if o.visible == false then return end
        local percent = val/max
        if percent<0 then percent=0 end
        if percent>100 then percent=100 end
        local result = math.floor(o.w*percent)
        for i=0,o.h-1 do
            term.setCursorPos(o.x,o.y+i)
            term.setBackgroundColor(o.progressColor)
            for i=0,result do
                term.write("\x00")
            end
            term.setBackgroundColor(o.backgroundColor)
            for i=0,(o.w-result) do
                term.write("\x00")
            end
        end
        paintutils.drawBox(o.x-1,o.y-1,o.x+o.w+1,o.y+o.h,o.borderColor)
    end
}

local TextBox = {
    x = (termDimensions[1]/2)-14,
    w = termDimensions[1]/2+2,
    y=10,
    h=8,
    backgroundColor = styles.background,
    borderColor = styles.foreground,
    textColor = styles.text,
    visible = true,
    text = {},

    drawTextBox = function(o,line)
        paintutils.drawBox(o.x,o.y,o.x+o.w,o.y+o.h,o.borderColor)
        paintutils.drawFilledBox(o.x+1,o.y+1,o.x+o.w-1,o.y+o.h-1,o.backgroundColor)
        if o.text == nil then o.text = {} end
        line = line or 1
        local textSpace = { o.w-2, o.h-1 }
        term.setTextColor(o.textColor)
        if type(o.text[line+textSpace[2]]) ~= "string" and #o.text>textSpace[2] then
            line = #o.text-textSpace[2]
        end
        for i=1,textSpace[2] do
            term.setCursorPos(o.x+1,o.y+i)
            if type(o.text[line]) == "string" then
                term.write(o.text[line])
            end
            line = line + 1
        end
        term.setCursorPos(1,1)
    end,

    setText = function(o, textArray)
        o.text = textArray
    end
}

local SelectionBox = {
    x = (termDimensions[1]/2)-14,
    w = termDimensions[1]/2+2,
    y=10,
    h=8,
    backgroundColor = styles.background,
    selectedBackgroundColor = styles.selectedBackground,
    borderColor = styles.foreground,
    textColor = styles.text,
    selectedTextColor = styles.selectedText,
    visible = false,
    options = {},
    currentSel = 1,

    drawSelectionBox = function(o, line, selection)
        paintutils.drawBox(o.x,o.y,o.x+o.w,o.y+o.h,o.borderColor)
        paintutils.drawFilledBox(o.x+1,o.y+1,o.x+o.w-1,o.y+o.h-1,o.backgroundColor)
        local textSpace = { o.w-6, o.h-1 }
        if selection>#o.options then
            selection = #o.options
        end
        if selection>textSpace[2] then
            selection = selection - line
        end
        if #o.options>textSpace[2] then
            o.currentSel = line-selection
        else
            o.currentSel = selection
        end
        local toggled = {
            [true] = "[X] ",
            [false] = "[ ] "
        }
        for i=0,textSpace[2] do
            if o.options[i+line] == nil then break end
            term.setCursorPos(o.x+1,o.y+i+1)
            if i+1 == selection then
                term.setTextColor(o.selectedTextColor)
                term.setBackgroundColor(o.selectedBackgroundColor)
                for j=0,textSpace[1]+5 do
                    term.write("\x00")
                end
                term.setCursorPos(o.x+1,o.y+i+1)
                term.write(toggled[o.options[i+line].toggled]..o.options[i+line].message)
            else
                term.setTextColor(o.textColor)
                term.setBackgroundColor(o.backgroundColor)
                term.write(toggled[o.options[i+line].toggled]..o.options[i+line].message)
            end
        end
    end,

    setOptions = function(o, selArray)
        o.options = {}
        for i,v in ipairs(selArray) do
            if type(v) == "string" then
                o.options[#o.options+1] = {message = v, toggled = false}
            elseif type(v) == "table" then
                o.options[#o.options+1] = {message = v[1], toggled = v[2]}
            end
        end
    end,

    getOption = function(o,sel)
        return o.options[sel].toggled
    end,

    toggleSel = function(o,line)
        if type(o.options[o.currentSel].toggled) == "boolean" then
            if o.options[o.currentSel].toggled == true then
                o.options[o.currentSel].toggled = false
            elseif o.options[o.currentSel].toggled == false then
                o.options[o.currentSel].toggled = true
            end
            o:drawSelectionBox(line,o.currentSel)
        end
    end
}

local function printCentered(s,y)
    term.setCursorPos(termDimensions[1]/2-#s/2,y)
    term.write(s)
end

local function addressGen()
    math.randomseed(os.time("utc"), os.clock())
    for i=0,math.floor(math.random(15,100)) do
        math.random() -- tosses random values
    end
    local address = ""
    for i=1,9 do
        address = address..tostring(math.random(0,9))
    end
    local a,b,c = address:sub(1,3), address:sub(4,6), address:sub(7,9)
    address = a..":"..b..":"..c
    return tostring(address)
end

local function InstallManager()
    if page ~= 4 then return end
    local completed, remainder = 0, 5
    paintutils.drawFilledBox((termDimensions[1]/2)-14, 8, (termDimensions[1]/2)+14,18, colors.black)
    term.setTextColor(colors.white)
    printCentered("Starting install...",9)
    ProgressBar:drawBar(completed,remainder)
    if not fs.exists("/Warnet/") then
        printCentered("Making /Warnet/...", 9)
        fs.makeDir("/Warnet/")
        completed = 1
        ProgressBar:drawBar(completed, remainder)

    end
    if not fs.exists("/Warnet/WarnetInterface.lua") then
        printCentered("Downloading WarnetInterface.lua...",9)
        downloadFile("/Warnet/WarnetInterface.lua", files.programs["WarnetInterface.lua"])
    end
    completed = 2
    ProgressBar:drawBar(completed,remainder)
    if SelectionBox:getOption(1) == true and settings.get("warnet.address") == nil then
        printCentered("Setting network address...",9)
        local address = addressGen()
        settings.define("warnet.address", {"The primary hosting address of the computer",address,"string"})
        settings.set("warnet.address", address)
    end
    Address = settings.get("warnet.address")
    completed = 3
    printCentered("Setting whitelist settings...",9)
    settings.define("warnet.use_whitelist", {"Whether or not the device responds only to IDs listed in the 'warnet.whitelisted_hosts' setting",false,"boolean")
    if SelectionBox:getOption(2) == true then
        settings.set("warnet.use_whitelist", true)
    end
    completed = 4
    ProgressBar:drawBar(completed,remainder)
    settings.define("warnet.whitelisted_hosts", {"Hosts and/or addresses which the device will respond to, ignoring other devices if 'warnet.use_whitelist' is true",{},"table")
    settings.define("warnet.invert_whitelist", {"Changes functionality so that instead of only accepting responses from 'warnet.whitelisted_hosts', it will deny responses from only those hosts",false,"boolean")
    if SelectionBox:getOption(3) == true then
        settings.set("warnet.invert_whitelist", true)
    end
    completed = 5
    ProgressBar:drawBar(completed,remainder)
    page = 5
    pageHandler()
end

function pageHandler()
    if page == 1 then
        TextBox:setText(textArrs[1])
        TextBox:drawTextBox()
    elseif page == 2 then
        TextBox:setText(textArrs[2])
        TextBox:drawTextBox()
    elseif page == 3 then
        selLine = 1
        SelectionBox:setOptions(textArrs[3])
        SelectionBox:drawSelectionBox(1,selLine)
    elseif page == 4 then
        InstallManager()
    elseif page == 5 then
        term.setBackgroundColor(colors.black)
        for i=1,termDimensions[2]-6 do
            term.setCursorPos(1,i+6)
            term.clearLine()
        end
        TextBox:setText({
            "Warnet has been",
            "successfully installed!",
            nil,
            "Exit this program by",
            "pressing enter!",
            "Your address is:",
            tostring(Address)
        })
        TextBox:drawTextBox()
    end
end

-- Actual GUI
term.clear()
term.setCursorPos(1,1)
term.setTextColor(styles.text)
Title = paintutils.parseImage("e   e  ee  eee   e  e eee eee\ne   e e  e e  e  e  e e    e\ne e e e  e eee   ee e ee   e\ne e e eeee e  e  e ee e    e\n e e  e  e e  e  e  e eee  e\n")
paintutils.drawImage(Title,(termDimensions[1]/2)-14,2)
pageHandler()
while true do
    local event =  { os.pullEvent() }
    if event[1] == "terminate" then break end
    if event[1] == "key" then
        if event[2] == keys.right then
            if page+1 <= 5 then
                page = page + 1
                pageHandler()
            end
        elseif event[2] == keys.left then
            if page-1 >= 1 and page ~= 5 then
                page = page - 1
                pageHandler()
            end
        elseif event[2] == keys.enter then
            if page == 3 then
                SelectionBox:toggleSel(selLine)
            end
            if page == 5 then
                endInstall()
                break
            end
        end
    end
end

function endInstall()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    term.setPaletteColor(colors.red, 0x4000)
end