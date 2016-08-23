local function luhn_checksum(card_number)

	-- Temporary table so we can iterate digits in reverse order
	local digits = {}
	for d in string.gmatch(card_number, "%d") do
		table.insert(digits, 1, d)
	end
	
	local checksum = 0
	for ii, d in ipairs(digits) do
		d = tonumber(d)
		if 1 == (ii % 2) then
			-- Odd position (note lua numbers from 1...)
			checksum = checksum + d
		elseif d < 5 then
			-- Must be even, 2*d < 10
			checksum = checksum + (2 * d)
		else
			-- Must be even with 10 <= 2*d < 20
			checksum = checksum + (2 * d) - 9
		end
	end

    return checksum % 10
end
 
local function is_luhn_valid(card_number)
    return luhn_checksum(card_number) == 0
end

function processmatches(matches)
	if matches then
		validNums = 0
		for ii = 1, #matches, 1 do
			match = matches[ii]:getMatch()
			val = match:getOutputText()
			if is_luhn_valid(val) then
				validNums = validNums + 1
			else
				matches[ii]:setOutput(false)
			end
		end
		
		multiplier = validNums / #matches
		for ii = 1, #matches, 1 do
			match = matches[ii]:getMatch()
			if matches[ii]:getOutput() then
				match:setScore(multiplier * match:getScore())
			end
		end
		
	end
end