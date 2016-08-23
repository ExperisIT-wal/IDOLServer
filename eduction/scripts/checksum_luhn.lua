local function luhn_checksum(number)

    -- This function determines whether each match has a valid Luhn checksum
    -- Matches with an invalid checksum have their score reduced by a factor of 10
    -- It is appropriate for the vast majority of credit/debit card numbers and for Canadian Social Insurance Numbers, etc.

	-- Temporary table so we can iterate digits in reverse order:
	local digits = {}
	for d in string.gmatch(number, "%d") do
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

function processmatch (edkmatch)
	if edkmatch then
		local number = edkmatch:getOutputText()
		if luhn_checksum(number) ~= 0 then
			edkmatch:setScore(0.1 * edkmatch:getScore())
		end
	end
	return true
end
