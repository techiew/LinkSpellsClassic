
SLASH_LINKSPELLSCLASSIC1 = "/link"
SLASH_LINKSPELLSCLASSIC2 = "/linkspellsclassic"

-- Handle slash commands
SlashCmdList["LINKSPELLSCLASSIC"] = function(msg)

	if msg == "msg" then
	
		if LSC_MSG == 1 then
			LSC_MSG = 0
			print("The login message is now disabled.")
		else
			LSC_MSG = 1
			print("The login message is now enabled.")
		end
		
	end
	
end