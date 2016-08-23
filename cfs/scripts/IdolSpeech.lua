-- This script uses IdolSpeech Server to perform speech-to-text on audio files.
-- The transcribed speech will be added to the document content.
-- Video files will also be sent to IdolSpeech Server as they may contain audio
-- tracks that speech-to-text can be performed on.
-- Other documents will be filtered by keyview as normal.

-- These are the KeyView DocumentClasses that should be sent to IdolSpeech
-- Server for speech-to-text.
local documentClassesForIdolSpeech = {
	["9"] = true, -- sound
	["20"] = true, -- movie
}

function shouldSendToIdolSpeech(document)
	local docClass = document:getFieldValue("DocumentClass");
	return documentClassesForIdolSpeech[docClass];
end

function handler(document)
	if shouldSendToIdolSpeech(document) then
		-- Send the file to Idol Speech Server for speech-to-text.
		-- This will throw on failure resulting in an error being
		-- logged and the document being filtered by KeyView as normal
		-- (provided no later tasks disable filtering).
		idol_speech(document, "IdolSpeechSettings");

		-- If speech-to-text was performed successfully, don't extract
		-- text using KeyView, just get the metadata.
		document:addField("AUTN_FILTER_META_ONLY", "");
	end
	return true;
end
