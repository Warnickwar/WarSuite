--[[TODO:
    - Create global variables upon installation
    - Actually MAKE a Warnet installer
    - Make a central WARNET server hosting all taken IDs
        > That is to be done in the MC server, but make the program ahead of time anyways with CraftOS-PC
    - Make a custom Hosting software for computers (_WARNET_HOST defaults to a generated ID that will repeat the message back to the computer to notify of an invalid hostname)
        > Probably gonna be done via an WarnetInterface add-on
    - Create an address reserve server
        > Simple string lookup on a file
    - ADD DOCUMENTATION
        > Need to look up Documentation formatting for this stuff...
    - Try and develop update software that runs on startup
        > Again to be done in CC:Tweaked directly instead of programmed on a compiler. Can be developed on CraftOS-PC Online.
    - (Optional) Make a Web Browser that users can host "Websites" out of
        > Allows for custom server management software
]]

--[[
    Error Documentation
    0  :  Successful Operation
    1  :  Port is open
    2  :  Port is closed
    3  :  Modem cannot open port (Maximum number of ports)
    4  :  No Modems attached
    5  :  Port is out of range
    11 :  Reply Port is not open
    16 :  Parameter must be a non-negative
    21 :  Timeout has expired
]]

-- NOTE: Origin will later be called out of a global Interface variable auto-generated by settings upon installation.


--[[
    build(message,...)

    Description:
    a command which automatically builds and creates a Warnet-compatible message.
    Typically updated to the latest version.

    Parameters:
    - message: The message, command, or data wanting to be sent
    - ...: Recipients for the message (can be either hostname or address)

    Returns:
    - A table with the prepared Warnet-Compatible message format.
]]
build = function(message, ...)
    local origin = 1
    -- Potentially gonna move Destination setting to just use a different Interface command instead of the same thing
    local args = {...}
    local destinations = {}
    for _,v in ipairs(args) do
        destinations[v] = true
    end
    dest = destinations
    local temp = {
        Protocol = "Warnet",
        Version = "1.0.0",
        Origin = origin, -- Represents the origin computer
        Destination = dest, -- Represents the destination computer
        Message = {
            Header = nil,
            Data = message,
            Footer = nil,
           
            getHeader = function(o)
                return o.Header
            end,
            
            getData = function(o)
                return o.Data
            end,
                
            getFooter = function(o)
                return o.Footer
            end
        },
         
        getProtocol = function(o)
            return o.Protocol
        end,
           
        getVersion = function(o)
            return o.Version
        end,
            
        getOrigin = function(o)
            return o.Origin
        end,
          
        getDestination = function(o)
            return o.Destination
        end,

        getMessage = function(o)
            return o.Message
        end,

        isRecipient = function(o,id)
            return o.Destination[id] or false
        end
    }
        
    --[[
        Header: Used for complex data needed to be separated.
        Data: General data. Cannot be nil. Can be anything else, however.
        Footer: Used for security information or alternative information to be separated from Data and Header data.
        Note to self: Make a standard on the uses of each piece of information. Unsure as of now. Perhaps encryption/signatures for footers?
    ]]
        
    --[[
        Reason for having functions in the transmitted message itself:
        - Allows for tangential compatability with other Network Interfaces
        - Allows users to directly call functions from the categories without needing WarnetInterface installed
            > Also prevents accidential changing of data in code
    ]]
       
    temp.Message.__index = temp.Message
    temp.__index = temp
    return temp
end

-- Gets the message from a Warnet-compatible table
function getMessage(builtData)
    return builtData.Message
end

-- Gets the header from a Warnet message table
function getHeader(message)
    return message.Header
end

-- Gets the data from a Warnet message table
function getData(message)
    return message.Data
end

-- Gets the footer from a Warnet message table
function getFooter(message)
    return message.Footer
end

-- Gets the list of destinations written on a Warnet message
function getDestination(builtData)
    return builtData.Destination or nil
end

-- Gets the source of the Warnet message (Either hostname or ID)
function getSource(builtData)
    return builtData.Origin
end

-- Gets the protocol name of a message, if there is one
function getProtocol(builtData)
    return builtData.Protocol
end

-- Gets a message version, useful for identifying what methods may be on the message
function getVersion(builtData)
    return builtData.Version
end

-- Checks a Warnet message to see if the device is the recipient
function isRecipient(builtData, deviceID)
    -- TODO: Get the deviceID or hosts from the device's global variables
    return builtData:getDestination()[deviceID] or false
end

-- Prepares a Warnet Message to change the header of the message
function setHeader(builtData, header)
    builtData.Message.Header = header
end

-- Prepares a Warnet Message to change the main data of the message 
function setData(builtData, data)
    builtData.Message.Data = data
end

-- Prepares a Warnet Message to change the footer of the message
function setFooter(builtData, footer)
    builtData.Message.Footer = footer
end

-- Checks a message to see if a message is of Warnet compatibility
function isCompatible(builtData)
    if type(builtData) ~= "table" or string.lower(builtData.Protocol) ~= "warnet" then return false end
    return true
end

-- Returns a list of all attached modems, or nil if there is no modems
function getAllModems()
    local modems = { peripheral.find("modem") }
    if #modems < 1 then return nil, 4, "No Modems attached" end
    return modems, 0
end

--[[
    openPort(port[, modem])

    Description:
    A Warnet interface command that allows users to open a port on a single modem.
    Recommended to use the Modem method directly rather than this method.

    Parameters:
    - port: The port wishing to be opened
    - modem: (Optional) The modem the port is to be closed on. Recommended to pass the Modem directly into the command.
        Defaults to the first findable modem.

    Returns:
    - on Success
        > true
        > Status Code 0
    - on Failure
        > false
        > Status Code
        > Short string explanation
]]
function openPort(port, modem)
    if port<0 or port>65535 then return false,5,"Requested port is out of range" end
    local modem = modem or 1
    if type(modem) == "number" then
        local temp = { peripheral.find("modem") }
        modem = temp[modem]
    end
    if modem.isOpen(port) then return false, 1, "Modem already has port open" end
    local status = pcall(function() modem.open(port) end)
    if status == false then
        return false, 3, "Modem cannot open port"
    end
    return true, 0
end

--[[
    closePort(port[, modem])

    Description:
    A Warnet interface command that allows users to close a port on a single modem.
    Recommended to use the Modem.close() method directly rather than this method.

    Parameters:
    - port: The port wishing to be closed
    - modem: (Optional) The modem the port is to be closed on. Recommended to pass the Modem directly into the command

    Returns:
    - on Success
        > true
        > Status Code 0
    - on Failure
        > false
        > Status Code (num)
        > Short string explanation (string)
]]
function closePort(port, modem)
    if port<0 or port>65535 then return false,4,"Requested port is out of range" end
    local modem = modem or 1
    if type(modem) == "number" then
        local temp = { peripheral.find("modem") }
        modem = temp[modem]
    end
    if not modem.isOpen(port) then return false, 1, "Modem already has port closed" end
    modem.close(port)
    return true, 0
end

--[[
    closePortOnAll(port[, modems])

    Description:
    Closes the designated port on all connected or passed modems.

    Parameters:
    - port: The port requested to be closed
    - modemList: (Optional) a list of modems to close the port on. Defaults to all modems

    Returns:
    - on Success
        > true
        > Status Code 0 (num)
        > Results on all applied modems (table)
    - on Failure
        > false
        > Status Code 5 (num)
        > Short string explanation (string)
]]
function closePortOnAll(port, modemList)
    if port<0 or port>65535 then return false,5,"Requested port is out of range" end
    local modems
    if type(modemList) ~= "table" then
        modems = { getAllModems() }
        if modems[1] == nil then return modems[1],modems[2],modems[3] end
        modems = modems[1]
    else
        modems = modemList
    end
    local statuses = {}
    for i,modem in ipairs(modems) do
        if peripheral.getType(modem) ~= "modem" then table.insert(statuses, i, "Peripheral is not modem.") end
        if not modem.isOpen(port) then table.insert(statuses, i, "Port is already closed") break end
        local status, err = pcall(function() modem.close(port) end)
        if status == false then
            table.insert(statuses, i, "Unexpected error. Something went wrong.")
        else
            table.insert(statuses, i, "Modem successfully closed port: "..port)
        end
    end
    return true, 0, statuses
end

--[[
    ping(port,destination[, replyport[, timeout] ])

    Description:
    Pings a specified destination- hostname or computer ID- to check if they are active and responding

    Parameters:
    - destination: The host or computer ID to attempt to ping
        > Note: If destination is passed as a table of destinations, Ping will only ping the first object in the table.
    - timeout: (Optional) The amount of ticks to await a response. Defaults to 5 seconds (100 ticks).

    Returns:
    - on Success
        > true (Reachable)
        > Status Code 0 (num)
        > Time for response (num)
    - on Failure
        > false (Not reachable)
        > Status Code (num)
        > Short explanation on error (string)
]]
function ping(destination, timeout)
    timeout = timeout or 100 -- in Ticks
    if timeout < 1 then timeout = 1 end
    if type(destination) == "table" then destination = destination[1] end
    if timeout < 0 then timeout = 0 end
    local message = build("PING", destination)
    local modems = { getAllModems() }
    if modems[1] == nil then return modems[1],modems[2],modems[3] end
    modems = modems[1]
    local modem = nil
    modem.transmit(600, 600, message)
    local timeoutTimer = os.startTimer(timeout/20)
    local startTime = os.epoch()/3600 -- translates in-game time to ticks
    local i = true
    local results = {}
    local function messageListener()
        while i do
            local response = { awaitMessage() }
            if response[1] == nil then
                results = { false,response[2],response[3] }
                break
            end
            if response[1]:getMessage():getData() == "PING_REPONSE" then
                local elapsedTime = (os.epoch()/3600)-startTime
                results = { true, 0, elapsedTime }
                break
            end
        end
    end
    
    local function timerListener()
        while true do
            local event = { os.pullEventRaw("timer") }
            if event[2] == timeoutTimer then
                results = { false, 21, "The request has timed out" }
                break
            end
        end
    end

    parallel.waitForAny(messageListener, timerListener)
    return results[1],results[2],results[3]
end

-- repeatPing | Pings a requested host multiple times, similar to a conventional ping command
--[[
    repeatPing(destination[, times[, timeout] ])


    Description:
    Pings a specified destination- hostname or computer ID- to check if they are active and responding.
    Repeats a set amount of times, or 0 for indefinite pinging.


    Parameters:
    - destination: The host or computer ID to ping
        > Note: If destination is passed as a table of destinations, repeatPing will only ping the first object in the table.
    - times: (Optional) The amount of times to ping the host. Set to 0 for indefinite pinging.
    - timeout: (Optional) The time it takes before the program returns false, in ticks.


    Returns:
    - a table of results from the pings
]]
function repeatPing(destination, times, timeout)
    local results = { }
    if type(times) ~= 'number' then times = 5 end
    times = times or 5
    timeout = timeout or 100 
    if times>0 then
        for i=1,times do
            local pingResult = { ping(destination, timeout) }
            if pingResult[1] == true then
                print("Response from "..destination.." ("..i.."): "..pingResult[3].." Ticks for a response.")
            else
                print(destination.." Unreachable. No response. ("..i..")(Timeout: "..timeout.." Ticks)")
            end
        end
    else
        local i=1
        while true do
            local pingResult = { ping(destination, timeout) }
            if pingResult[1] == true then
                print("Response from "..destination.." ("..i.."): "..pingResult[3].." Ticks for a response.")
                i=i+1
            else
                print(destination.." Unreachable. No response. ("..i..") (Timeout: "..timeout.." Ticks)")
                i=i+1
            end
        end
    end
end

-- multiPing | Pings multiple hosts at the same time, creating a table with average response times from all
function multiPing(destinations, times, timeout, returnResults)
    times = times or 1
    if type(times) ~= "number" then times = 1 end
    if times > 100 then times = 100 end
    if times < 1 then times = 1 end
    if type(destinations) ~= "table" then
        destinations = { destinations } --Converts a string to a table
    end
    timeout = timeout or 100
    local pingTimes = { }
    local averages = { }
    for k,v in pairs(destinations) do
        table.insert(pingTimes, k, {})
        table.insert(averages, k, 0)  
    end
    while true do
        for k,v in pairs(destinations) do
            local attempt = 1
            print("Now pinging host: "..k)
            while attempt < times do
                local pingResult = { ping(k, timeout) }
                if pingResult[1] == true then
                    print("Response from "..k..": "..pingResult[3].." Ticks for a response.")
                    table.insert(pingTimes[k], pingResult[3])
                else
                    print(k.." Unreachable. No response. (Timeout: "..timeout.." Ticks)")
                    table.insert(pingTimes[k], 0)
                end
                attempt = attempt + 1
            end
            local sum
            for i,v2 in ipairs(pingTimes[k]) do
                sum = sum + v2
            end
            table.insert(averages, k, sum/attempt)
            print("Host "..k.." completed! Continuing next host...")
            print("Average response time: "..averages[k])
        end
        print("Pings complete! Destination Averages:")
        for k,v in pairs(averages) do
            print(k..": "..v.." Ticks")
        end
    end
end

--[[
    awaitMessage([timeout[, port] ])

    Description:
    Awaits a Warnet-compatible message to be sent to the device

    Parameters:
    - timeout: (Optional) Defines how much time to wait for a response
    to this device, returning if no response is made (in Ticks)
    - port: (Optional) Filters incoming messages for a single port

    Returns:
    - on Success
        > The received message (WARNET table)
        > The port in which the message was received from (num)
        > The requested reply port (num)
    - on Failure
        > nil
        > Status code (num)
        > String with a short explanation of the error (string)
]]
function awaitMessage(timeout, port)
    timeout = timeout or 0
    local modemTest = { getAllModems() }
    if modemTest[1] == nil then return modemTest[1], modemTest[2], modemTest[3] end
    if timeout < 0 then timeout = 0 end
    local timer = nil
    if timeout <= 0 then timer = os.startTimer(timeout/20) end-- Divide by 20 to get ticks
    local filterPort = false
    if type(port) == "number" then filterPort = true end
    while true do
        local event = { os.pullEventRaw() }
        if event[1] == "modem message" then
            if isCompatible(event[5]) --[[and isRecipient(event[5]) (Commented until implemented fully)]] then
                if filterPort then
                    if event[3] == port then
                        return event[5],event[3],event[4] -- Message, Receiving Port, Reply Port
                    end
                else
                    return event[5],event[3],event[4] -- Message, Receiving Port, Reply Port
                end
            end
        else if event[1] == "timer" and timer == event[2] then
                return nil,21,"The request has timed out" -- nil, Status code, Explanation
            end
        end
    end
end

return {
    build = build,
    getMessage = getMessage,
    getHeader = getHeader,
    getData = getData,
    getFooter = getFooter,
    getDestination = getDestination,
    getSource = getSource,
    getProtocol = getProtocol,
    getVersion = getVersion,
    isRecipient = isRecipient,
    setHeader = setHeader,
    setData = setData,
    setFooter = setFooter,
    isCompatible = isCompatible,
    getAllModems = getAllModems,
    openPort = openPort,
    closePort = closePort,
    closePortOnAll = closePortOnAll,
    ping = ping,
    repeatPing = repeatPing,
    multiPing = multiPing,
    awaitMessage = awaitMessage
}