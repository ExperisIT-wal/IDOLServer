-- rounds a number in the interval [0, 999999.5) to the nearest integer
-- returns a 6-digit string with leading zeros if necessary to represent this number
-- if the number is in the interval [999999.5, 1000000) we return "999999"...
--  ...this is guaranteed to be within 12cm of the correct answer, so increased precision is unnecessary
function round6(original)
    if math.floor(original) + math.ceil(original) > 2*original then
        original = math.floor(original)
    else
        original = math.ceil(original)
    end
    if original == 1000000 then
        original = 999999
    end
    -- pad out with leading zeros
    local output = string.match(original, "^(%d%d?%d?%d?%d?%d?)")
    for ii = 0, 5 - string.len(output) do
        output = "0" .. output
    end
    return output
end

function convert_to_decimals(minutes,seconds)
    if minutes == 0 and seconds == 0 then
        return "000000"
    else
        return round6((minutes/60 + seconds/3600) * 1000000)
    end
end

function convert_to_minutes(decimals)
    local contribution = "0." .. decimals
    return math.floor (contribution * 60)
end

function convert_to_seconds(decimals,minutes)
    local contribution = "0." .. decimals
    return (contribution * 3600 - minutes * 60)
end

-- normalizes the components' values and stores them in both "edkmatch" and "components"
function processmatch (edkmatch)
	if edkmatch then
        -- add components to memory:
		local components = {}
		for ii = 0, edkmatch:getComponentCount()-1 do
			local component = edkmatch:getComponent(ii)
			components[component:getName()] = component:getText()
		end

        -- fill in north/south and east/west components with sensible default values:
        if not components["EW"] then
            local component = edkmatch:addComponent("EW",0,0)
            component:setText("E")
            components["EW"] = "E"
        end
        if not components["NS"] then
            local component = edkmatch:addComponent("NS",0,0)
            component:setText("N")
            components["NS"] = "N"
        end
        
        -- fill in the latitude components with calculated and adjusted values
        if components["LAT_MINUTES"] then
            if not components["LAT_SECONDS"] then
                components["LAT_SECONDS"] = "0"
                local seconds = edkmatch:addComponent("LAT_SECONDS",0,0)
                seconds:setText("0")
            end
            local decimals = edkmatch:addComponent("LAT_DECIMAL",0,0)
            decimals:setText(convert_to_decimals(components["LAT_MINUTES"],components["LAT_SECONDS"]))
            components["LAT_DECIMAL"] = decimals:getText()
        else
            local minutes = edkmatch:addComponent("LAT_MINUTES",0,0)
            minutes:setText(convert_to_minutes(components["LAT_DECIMAL"]))
            components["LAT_MINUTES"] = minutes:getText()
            local seconds = edkmatch:addComponent("LAT_SECONDS",0,0)
            seconds:setText(convert_to_seconds(components["LAT_DECIMAL"],components["LAT_MINUTES"]))
            components["LAT_SECONDS"] = seconds:getText()
            components["LAT_DECIMAL"] = round6(("0." .. components["LAT_DECIMAL"]) * 1000000)
        end

        -- fill in the longitude components with calculated and adjusted values
        if components["LONG_MINUTES"] then
            if not components["LONG_SECONDS"] then
                components["LONG_SECONDS"] = "0"
                local seconds = edkmatch:addComponent("LONG_SECONDS",0,0)
                seconds:setText("0")
            end
            local decimals = edkmatch:addComponent("LONG_DECIMAL",0,0)
            decimals:setText(convert_to_decimals(components["LONG_MINUTES"],components["LONG_SECONDS"]))
            components["LONG_DECIMAL"] = decimals:getText()
        else
            local minutes = edkmatch:addComponent("LONG_MINUTES",0,0)
            minutes:setText(convert_to_minutes(components["LONG_DECIMAL"]))
            components["LONG_MINUTES"] = minutes:getText()
            local seconds = edkmatch:addComponent("LONG_SECONDS",0,0)
            seconds:setText(convert_to_seconds(components["LONG_DECIMAL"],components["LONG_MINUTES"]))
            components["LONG_SECONDS"] = seconds:getText()
            components["LONG_DECIMAL"] = round6(("0." .. components["LONG_DECIMAL"]) * 1000000)
        end
        
        -- get the seconds and if there are any decimal places, normalize to 3 decimal places
        -- ...but if it is simply an integer then just leave it as it is...
        -- ...even without rounding we are guaranteed to be within 4cm of the correct answer...
        -- ...so we take the floor function rather than rounding up/down
        if string.find(components["LAT_SECONDS"], "[.]") then
            local temp = components["LAT_SECONDS"] .. "00"
            components["LAT_SECONDS"] = string.match(temp, "%d%d?%.%d%d%d")
        end
        if string.find(components["LONG_SECONDS"], "[.]") then
            local temp = components["LONG_SECONDS"] .. "00"
            components["LONG_SECONDS"] = string.match(temp, "%d%d?%.%d%d%d")
        end
        
        -- find the decimal components and replace them with the 6-digit values that have now been calculated:
        -- find the seconds components and replace them with the 3 d.p.  values that have now been calculated:
        for jj = 0, edkmatch:getComponentCount()-1 do
            local temp_component = edkmatch:getComponent(jj)
            if temp_component:getName() == "LAT_DECIMAL" then
                temp_component:setText(components["LAT_DECIMAL"])
            elseif temp_component:getName() == "LONG_DECIMAL" then
                temp_component:setText(components["LONG_DECIMAL"])
            elseif temp_component:getName() == "LAT_SECONDS" then
                temp_component:setText(components["LAT_SECONDS"])
            elseif temp_component:getName() == "LONG_SECONDS" then
                temp_component:setText(components["LONG_SECONDS"])
            end
        end
        
        --[[
            if the user would like to replace the educed test with the geo-co-ordinates in a standardized form...
            ...they are invited to do so here, by piecing together the desired form from the components...
            ...the following is an interpretation that sets the normalized text to the format:
                        12.345678° N, 23.456789° W
      ]]--

        edkmatch:setOutputText(components["LAT_DEGREES"] .. "." .. components["LAT_DECIMAL"] .. "° " .. components["NS"] .. ", " .. components["LONG_DEGREES"] .. "." .. components["LONG_DECIMAL"] .. "° " .. components["EW"])
        
	end
	return true
end
