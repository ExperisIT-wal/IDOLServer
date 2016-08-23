
function handler(document)

    -- NOTE: This is a CFS post-import lua script, not an eduction post processing script.

    -- This function is designed to work with any Autonomy Eduction sentiment analysis grammar file that supports scoring.
    -- Every document processed by this function has a new field added named "OVERALL_VIBE"
    -- "OVERALL_VIBE" can be positive, negative, mixed or neutral depending on the output from Eduction sentiment analysis.
    -- This function expects that the positive matches are in a field named "POSITIVE_VIBE"; and that
    --                            the negative matches are in a field named "NEGATIVE_VIBE".
    -- "OutputScores=True" should be set in the configuration file.
    
    -- Algorithm overview:
    --      -> The score for each match is modified and added/subtracted from a running total
    --      -> if the running total is close to zero then the document is classed as neutral or mixed
    --      -> if the running total is positive/negative then the document is classed as positive/negative respectively.
	
	-- The script can be called as a PostTask from CFS. Such a task should run after an Eduction PostTask that has added
	-- POSITIVE_VIBE/score and NEGATIVE_VIBE/score fields as a result of running sentiment analysis on the document. 
    -- That EductionTask must have OutputScores set to TRUE, as this function expects scores to be present as part of 
    -- the calculation. An example configuration would look like this:
	--
	-- [EductionTask]
	-- ResourceFiles=grammars/sentiment_eng.ecr
	-- SearchFields=DRECONTENT
	-- Entity0=sentiment/positive/eng
	-- EntityField0=POSITIVE_VIBE
	-- Entity1=sentiment/negative/eng
	-- EntityField1=NEGATIVE_VIBE
	-- OutputScores=TRUE
	--
    -- [ImportTasks]
    -- Post1=eduction:EductionTask
    -- Post2=lua:vibe.lua
    
    local zmatch = 0        -- the number of matches that don't have a tiny score
	local zscore = 0        -- the running total
    local this_score = 0    -- the current score
    -- iterate over the fields in the document in the same order as they would be printed:

    local positivevibes = { document:getFields("POSITIVE_VIBE") }
    for i, f in ipairs(positivevibes) do 
        this_score = tonumber(f:getFieldValues("score"))
        -- if score does not exceed 0.05 then it has been filtered out intentionally
        if this_score > 0.05 then
            zmatch = zmatch + 1
        end
        -- if a phrase has score exceeding 1.70 then it probably contains exaggeration.
        --    ...therefore we cap the score at 1.70:
        --      (The value of 1.70 may be tweaked to change the treatment of exaggerated matches)
        if this_score > 1.70 then
            this_score = 1.70
        end
        -- make scores slightly more extreme by mapping using the triangle function x |-> x(x+1)/2
        -- add or subtract from the running total:
        zscore = zscore + this_score * (this_score + 1) * 0.5
    end
    local negativevibes = { document:getFields("NEGATIVE_VIBE") }
    for i, f in ipairs(negativevibes) do 
        this_score = tonumber(f:getFieldValues("score"))
        -- if score does not exceed 0.05 then it has been filtered out intentionally
        if this_score > 0.05 then
            zmatch = zmatch + 1
        end
        -- if a phrase has score exceeding 1.70 then it probably contains exaggeration.
        --    ...therefore we cap the score at 1.70:
        --      (The value of 1.70 may be tweaked to change the treatment of exaggerated matches)
        if this_score > 1.70 then
            this_score = 1.70
        end
        -- make scores slightly more extreme by mapping using the triangle function x |-> x(x+1)/2
        -- add or subtract from the running total:
        zscore = zscore + -1 * this_score * (this_score + 1) * 0.5
    end

    -- Determine whether the running total is sufficiently far from zero to be statistically significant:
    --    (The value of 0.35 may be tweaked to adjust the sensitivity of the document classification...
    --      ...However the user is warned that values beneath 0.3 allow documents to be classified as positive or
    --      ...negative by exaggerating the importance of conditional and ambiguous phrases)
    if math.abs(zscore) > (0.35 * (zmatch ^ 0.5)) then
		if zscore > 0 then
            document:addField("OVERALL_VIBE","Positive")
		else
            document:addField("OVERALL_VIBE","Negative")
		end
	else
		if zmatch > 1 then -- need 2 non-trivial matches or more
            document:addField("OVERALL_VIBE","Mixed")
		else
            document:addField("OVERALL_VIBE","Neutral")
		end
	end
    return true
end

