
    -- this function works with number_dni_spa.ecr and discards all matches where the checksum is incorrect
    -- you may wish instead to keep incorrect matches but reduce their score (if so, change line 32 accordingly)

function processmatch (edkmatch)
	if edkmatch then
        local number = nil
        local checksum = nil

        -- read through the components and find the number and checksum:
		for ii = 0, edkmatch:getComponentCount()-1 do
			local component = edkmatch:getComponent(ii)
            if component:getName() == "NUMBER" then
                number = component:getText()
            end
            if component:getName() == "CHECKSUM" then
                checksum = component:getText()
            end
		end
        -- check that the number and the checksum are both present:
        if checksum == nil then
            return false
        elseif checksum == nil then
            return false
        end

        -- in lua, array indices start at '1', not '0'...
        -- indices:  1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23
        local uc = {"T","R","W","A","G","M","Y","F","P","D","X","B","N","J","Z","S","Q","V","H","L","C","K","E"}
        local lc = {"t","r","w","a","g","m","y","f","p","d","x","b","n","j","z","s","q","v","h","l","c","k","e"}

        -- check that the checksum is what it's supposed to be - although it can be upper case or lower case:
        if not (uc[1 + number % 23] == checksum or lc[1 + number % 23] == checksum) then
            return false
         end
	end
	return true
end
