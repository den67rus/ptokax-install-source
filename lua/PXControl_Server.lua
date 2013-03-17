--[[##################################################################################

  PXControl Server 1.01a by alex82
	Based on Ptokax Remote Administration by Hungarista

####################################################################################

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

###################################################################################]]
-- НАСТРОЙКИ

y,n = true,false

tCfg = {
	CheckNick = n,	-- Разрешить доступ только определенным никам
	CheckIP = n,	-- Разрешить доступ только определенным IP
	AllowLocalhost = y,	-- Разрешить доступ без авторизации с локального IP-адреса (127.0.0.1)
}

tProfiles = {	-- Настройки прав доступа
	[0] = y,	-- Master
	[1] = n,	-- OP
	[2] = n,	-- VIP
	[3] = n,	-- Reg
	[4] = n,
	[5] = n,
	[-1] = n,	-- Unreg
}

tNicks = {	-- Разрешенные ники
	["RemoteAdmin"] = y,
}

tIPs = {	-- Разрешенные IP
	["127.0.0.1"] = y,
}

--###################################################################################
--###################################################################################

path,selfname = debug.getinfo(1).source:match("^@?(.+[/\\]).-[/\\](.-)$")
path = path:gsub("\\","/")

if not pcall(function() require"pxlfs" end) then
	if not pcall(function() require"lfs" end) then
		error("Для работы скрипта необходимо установить библиотеку LuaFileSystem")
	end
end

-- Equivalent to C's "cond ? a : b", all terms will be evaluated
function iff(cond,a,b) return cond and a or b end
endpipe = string.char(91).."endpipe"..string.char(93)

function UnknownArrival(user,data)
	data = data:sub(1,-2)
	local cmd = data:match("^(%$%w+)")
	if tProtocol[cmd] then
		if (tProfiles[user.iProfile] and (not tCfg.CheckNick or tCfg.CheckNick and tNicks[user.sNick]) and (not tCfg.CheckIP or tCfg.CheckIP and tIPs[user.sIP])) or (tCfg.AllowLocalhost and user.sIP == "127.0.0.1") then
			tProtocol[cmd](user,data:gsub("%[endpipe%]","|"))
			return true -- Don't disconnect the user
		else
			Core.SendToUser(user,"<"..SetMan.GetString(21).."> У вас нет доступа к этой команде!")
			Core.SendToOpChat("Попытка несанкционированного доступа к командам удаленного управления. Ник юзера:"..user.sNick..", IP: "..user.sIP..".")
		end
	end
end

tProtocol = {
	["$GET"] = function(user,data)
		local type = data:match("^$GET%s(%d)")
		if type == "0" then
			local tSet = {}
			-- Booleans
			for i=0,55 do
				table.insert(tSet,iff(SetMan.GetBool(i),"1","0"))
			end
			Send(user,"$SET 1 "..table.concat(tSet,"$$").."$$")
		elseif type == "1" then
			local tSet = {}
			-- Numbers
			for i=0,113 do
				table.insert(tSet,tostring(SetMan.GetNumber(i)))
			end
			Send(user,"$SET 2 "..table.concat(tSet,"$$").."$$")
		elseif type == "2" then
			local tSet = {}
			for langfile in lfs.dir(Core.GetPtokaXPath().."/language") do
				if langfile ~= "." and langfile ~= ".." then
					table.insert(tSet,langfile:sub(1,-5))
				end
			end
			if next(tSet) then
				Send(user,"$SET 3 lang "..table.concat(tSet,"$$").."$$")
			end
			tSet = {}
			-- Strings
			for i=0,34 do
				table.insert(tSet,tostring(SetMan.GetString(i)))
			end
			Send(user,"$SET 3 "..table.concat(tSet,"$$").."$$")
			-- MOTD
			Send(user,"$SET 3 motd "..(SetMan.GetMOTD() or ""))
		elseif type == "3" then
			-- Bans
			local subtype = data:match("^%$GET%s3%s([01])$")
			if subtype then
				if subtype == "0" then
					local tSet = {}
					for k,v in ipairs(BanMan.GetPermBans()) do
						table.insert(tSet,(v.sIP or "<Nick ban>").."$"..(v.sNick or "<IP ban>").."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A"))
					end
					Send(user,"$SET 4 1 "..table.concat(tSet,"$$").."$$")
					tSet = {}
					for k,v in ipairs(BanMan.GetTempBans()) do
						table.insert(tSet,(v.sIP or "<Nick ban>").."$"..(v.sNick or "<IP ban>").."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A").."$"..v.iExpireTime)
					end
					Send(user,"$SET 4 2 "..table.concat(tSet,"$$").."$$")
				else
					local tSet = {}
					for k,v in ipairs(BanMan.GetPermRangeBans()) do
						table.insert(tSet,v.sIPFrom.."$"..v.sIPTo.."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A"))
					end
					Send(user,"$SET 4 3 "..table.concat(tSet,"$$").."$$")
					tSet = {}
					for k,v in ipairs(BanMan.GetTempRangeBans()) do
						table.insert(tSet,v.sIPFrom.."$"..v.sIPTo.."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A").."$"..v.iExpireTime)
					end
					Send(user,"$SET 4 4 "..table.concat(tSet,"$$").."$$")
				end
			else
				local tSet = {}
				for k,v in ipairs(BanMan.GetPermBans()) do
					table.insert(tSet,(v.sIP or "<Nick ban>").."$"..(v.sNick or "<IP ban>").."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A"))
				end
				Send(user,"$SET 4 1 "..table.concat(tSet,"$$").."$$")
				tSet = {}
				for k,v in ipairs(BanMan.GetTempBans()) do
					table.insert(tSet,(v.sIP or "<Nick ban>").."$"..(v.sNick or "<IP ban>").."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A").."$"..v.iExpireTime)
				end
				Send(user,"$SET 4 2 "..table.concat(tSet,"$$").."$$")
				tSet = {}
				for k,v in ipairs(BanMan.GetPermRangeBans()) do
					table.insert(tSet,v.sIPFrom.."$"..v.sIPTo.."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A"))
				end
				Send(user,"$SET 4 3 "..table.concat(tSet,"$$").."$$")
				tSet = {}
				for k,v in ipairs(BanMan.GetTempRangeBans()) do
					table.insert(tSet,v.sIPFrom.."$"..v.sIPTo.."$"..iff(v.bFullIpBan,1,0).."$"..(v.sBy or "N/A").."$"..(v.sReason or "N/A").."$"..v.iExpireTime)
				end
				Send(user,"$SET 4 4 "..table.concat(tSet,"$$").."$$")
			end
		elseif type == "4" then
			-- Scripts
			ScriptMan.Refresh()
			local tSet = {}
			for _,script in ipairs(ScriptMan.GetScripts()) do
				if script.sName ~= selfname then
					table.insert(tSet,script.sName.."$"..iff(script.bEnabled,"1","0").."$"..(script.iMemUsage or "0"))
				end
			end
			Send(user,"$SET 5 "..table.concat(tSet,"$$").."$$")
		elseif type == "5" then
			-- Profiles
			local tSet = {}
			for i,v in ipairs(ProfMan.GetProfiles()) do
				local sPermissions = ""
				for j=0,55 do
					sPermissions = sPermissions..iff(ProfMan.GetProfilePermission(v.iProfileNumber, j),"1","0")
				end
				table.insert(tSet,v.iProfileNumber.."$"..v.sProfileName.."$"..sPermissions)
			end
			Send(user,"$SET 6 "..table.concat(tSet,"$$").."$$")
		elseif type == "6" then
			local tSet = {}
			-- Registered users
			for i,v in ipairs(RegMan.GetRegs()) do
				table.insert(tSet,v.sNick.."$"..v.sPassword.."$"..v.iProfile)
			end
			Send(user,"$SET 7 "..table.concat(tSet,"$$").."$$")
		elseif type == "7" then
			local tSet = {}
			for textfile in lfs.dir(Core.GetPtokaXPath().."/texts") do
				if textfile ~= "." and textfile ~= ".." then
					table.insert(tSet,textfile:sub(1,-5))
				end
			end
			if next(tSet) then
				Send(user,"$SET 8 "..table.concat(tSet,"$$").."$$")
			end
		elseif type == "8" then
			-- Files
			local file = data:match("^%$GET%s8%s(.+)$")
			local p = ""
			if file:lower():sub(-4) == ".lua" then
				p = "scripts/"
			else
				p = "texts/"
			end
			local f = io.open(Core.GetPtokaXPath()..p..file,"rb")
			if f then
				local c = f:read("*a")
				Send(user,"$FILE "..file..":"..c)
				f:close()
			else
				Send(user,"$ERR 1")
			end
		end
	end,
	["$SET"] = function(user,data)
		local type = data:match("^%$SET%s(%d)")
		if type == "0" then
			for id,value in data:sub(8):gmatch("(%d+)%$(%d)%$%$") do
				SetMan.SetBool(tonumber(id),iff(value=="1",true,false))
			end
			SetMan.Save()
		elseif type == "1" then
			for id,value in data:sub(8):gmatch("(%d+)%$(%d+)%$%$") do
				SetMan.SetNumber(tonumber(id),tonumber(value))
			end
			SetMan.Save()
		elseif type == "2" then
			if data:find("^%$SET%s2%smotd") then
				local motd = data:match("^%$SET%s2%smotd%s(.*)")
				SetMan.SetMOTD(motd)
				SetMan.Save()
				return
			end
			for id,value in data:sub(8):gmatch("(%d+)%$(.-)%$%$") do
				SetMan.SetString(tonumber(id),value)
			end
			SetMan.Save()
		elseif type == "3" then
			local subtype = data:match("^%$SET%s3%s([0-7])")
			-- 0 - Unban; 1 - Clear tempbans; 2 - Clear permbans; 3 - Rangeunban
			-- 4 - Clear rangetempbans; 5 - Clear rangepermbans; 6 - Ban; 7 - Rangeban
			if subtype == "0" then
				local item,sIPorsNick,sIP = data:match("^%$SET%s3%s0%s(%d+)%s(%S+)%s*(%S*)")
				if BanMan.Unban(sIPorsNick) then
					if sIP ~= "" then BanMan.Unban(sIP) end
					BanMan.Save()
					Send(user,"$CONF 10 0 "..item)
				else
					Send(user,"$ERR 10 0")
				end
			elseif subtype == "1" then
				BanMan.ClearTempBans()
				BanMan.Save()
				Send(user,"$CONF 10 2")
			elseif subtype == "2" then
				BanMan.ClearPermBans()
				BanMan.Save()
				Send(user,"$CONF 10 3")
			elseif subtype == "3" then
				local item,sIPFrom,sIPTo = data:match("^%$SET%s3%s3%s(%d+)%s(%S+)%s%-%s(%S+)$")
				if item then
					if BanMan.RangeUnban(sIPFrom,sIPTo) then
						BanMan.Save()
						Send(user,"$CONF 10 1 "..item)
					else
						Send(user,"$ERR 10 1")
					end
				end
			elseif subtype == "4" then
				BanMan.ClearRangeTempBans()
				BanMan.Save()
				Send(user,"$CONF 10 4")
			elseif subtype == "5" then
				BanMan.ClearRangePermBans()
				BanMan.Save()
				Send(user,"$CONF 10 5")
			elseif subtype == "6" then
				local this = data:match("%$SET%s3%s6%s(.+)$")
				assert(loadstring(this))()
				if t[8] > 0 then
					local nTime = math.floor((t[8]-os.time())/60)
					if t[1] == true then BanMan.TempBanIP(t[4],nTime,t[6],t[7],t[2]) end
					if t[3] == true then BanMan.TempBanNick(t[5],nTime,t[6],t[7]) end
					Send(user,"$SET 4 2 "..iff(t[4]=="","<Nick ban>",t[4]).."$"..iff(t[5]==" ","<IP ban>",t[5]).."$"..
					iff(t[2]==true,"1","0").."$"..t[7].."$"..t[6].."$"..t[8].."$$")
				else
					if t[1] == true then BanMan.BanIP(t[4],t[6],t[7],t[2]) end
					if t[3] == true then BanMan.BanNick(t[5],t[6],t[7]) end
					Send(user,"$SET 4 1 "..iff(t[4]=="","<Nick ban>",t[4]).."$"..iff(t[5]=="","<IP ban>",t[5])..
					"$"..iff(t[2]==true,"1","0").."$"..t[7].."$"..t[6].."$$")
				end
			elseif subtype == "7" then
				local this = data:match("%$SET%s3%s7%s(.+)$")
				assert(loadstring(this))()
				if t[6] > 0 then
					local nTime = math.floor((t[6]-os.time())/60)
					BanMan.RangeTempBan(t[1],t[2],nTime,t[4],t[5],t[3])
					Send(user,"$SET 4 4 "..t[1].."$"..t[2].."$"..iff(t[3]==true,"1","0").."$"..t[5].."$"..t[4].."$"..t[6].."$$")
				else
					BanMan.RangeBan(t[1],t[2],t[4],t[5],t[3])
					Send(user,"$SET 4 3 "..t[1].."$"..t[2].."$"..iff(t[3]==true,"1","0").."$"..t[5].."$"..t[4].."$$")
				end
			end
		elseif type == "4" then
			local script,stat = data:match("^%$SET%s4%s(.+)%s(%S+)$")
			-- Scripts. stat: 0/1 moves down/up, true/false starts/stops the given script
			if script then
				if stat == "true" then
					if ScriptMan.StartScript(script) then
						ScriptMan.Save()
						Send(user,"$CONF 4 "..script)
					else
						Send(user,"$ERR 4 "..script)
					end
				elseif stat == "false" then
					if ScriptMan.StopScript(script) then
						ScriptMan.Save()
						Send(user,"$CONF 4 "..script)
					else
						Send(user,"$ERR 4 "..script)
					end
				elseif stat == "0" then
					if ScriptMan.MoveDown(script) then
						ScriptMan.Save()
						Send(user,"$CONF 2 "..script)
					else
						Send(user,"$ERR 2")
					end
				elseif stat == "1" then
					if ScriptMan.MoveUp(script) then
						ScriptMan.Save()
						Send(user,"$CONF 3 "..script)
					else
						Send(user,"$ERR 3")
					end
				end
			end
		elseif type == "5" then
			local profile,todo = data:match("^%$SET%s5%s(%S+)%s(%S+)")
			-- Profiles. todo: 0/1 moves down/up, true/false adds/deletes the given profile
			-- if todo = p then it'll set up the given permission id to the given value
			if todo == "0" then
				if ProfMan.MoveDown(tonumber(profile)) then
					ProfMan.Save()
					Send(user,"$CONF 6 "..profile)
				else
					Send(user,"$ERR 6")
				end
			elseif todo == "1" then
				if ProfMan.MoveUp(tonumber(profile)) then
					ProfMan.Save()
					Send(user,"$CONF 7 "..profile)
				else
					Send(user,"$ERR 7")
				end
			elseif todo == "true" then
				if ProfMan.AddProfile(profile) then
					ProfMan.Save()
					Send(user,"$CONF 8 "..profile)
				else
					Send(user,"$ERR 8")
				end
			elseif todo == "false" then
				if ProfMan.RemoveProfile(profile) then
					ProfMan.Save()
					Send(user,"$CONF 9 "..profile)
				else
					Send(user,"$ERR 9")
				end
			elseif todo == "p" then -- permission
				local profile,ID,value = data:match("^%$SET%s5%s(%d+)%sp%s(%d+)%s([01])$")
				if profile then
					if ID == "56" then -- Check/uncheck all
						for i=0,55 do
							if ProfMan.SetProfilePermission(tonumber(profile),i,iff(value == "1",true,false)) then
								Send(user,"$CONF 11 "..i.." "..value)
							else
								Send(user,"$ERR 11")
							end
						end
						ProfMan.Save()
					else
						if ProfMan.SetProfilePermission(tonumber(profile),tonumber(ID),iff(value == "1",true,false)) then
							ProfMan.Save()
							Send(user,"$CONF 11 "..ID.." "..value)
						else
							Send(user,"$ERR 11 "..ID)
						end
					end
				end
			end
		elseif type == "6" then
			-- regs
			local subtype = data:match("^%$SET%s6%s(%d)")
			-- subtype: 0 - del; 1 - add; 2 - mod registered user
			if subtype == "0" then
				local nick = data:match("^%$SET%s6%s0%s(%S+)$")
				if nick then
					if RegMan.DelReg(nick) then
						RegMan.Save()
						Send(user,"$CONF 12 "..nick)
					else
						Send(user,"$ERR 12 "..nick)
					end
				end
			elseif subtype == "1" then
				local nick,pass,profile = data:match("^%$SET%s6%s1%s(%S+)%s(%S+)%s(%d+)$")
				if nick then
					if RegMan.AddReg(nick,pass,tonumber(profile)) then
						RegMan.Save()
						Send(user,"$CONF 13 "..nick.." "..pass.." "..profile)
					else
						Send(user,"$ERR 13 "..nick)
					end
				end
			elseif subtype == "2" then
				local nick,pass,profile = data:match("^%$SET%s6%s2%s(%S+)%s(%S+)%s(%d+)$")
				if nick then
					if RegMan.ChangeReg(nick,pass,tonumber(profile)) then
						RegMan.Save()
						Send(user,"$CONF 14 "..nick.." "..pass.." "..profile)
					else
						Send(user,"$ERR 14 "..nick)
					end
				end
			end
		elseif type == "7" then
			local file,contents = data:match("^%$SET%s7%s(.-):(.*)$")
			local p,s = "",false
			if file:lower():sub(-4) == ".lua" then
				p,s = "scripts/",true
			else
				p = "texts/"
			end
			local f = io.open(Core.GetPtokaXPath()..p..file,"wb")
			if f then
				if contents == "del" then
					f:close()
					if s then ScriptMan.StopScript(file) end -- Nevermind if it doesn't run
					os.remove(Core.GetPtokaXPath()..p..file)
				else
					f:write(contents)
					f:close()
				end
			else
				Send(user,"$ERR 1")
			end
		end
	end,
	["$RSS"] = function(user,data)
		local script = data:match("^%$RSS%s(.+)$")
		if script then
			if ScriptMan.RestartScript(script) then
				Send(user,"$CONF 5 "..script)
			else
				Send(user,"$ERR 5")
			end
		else
			ScriptMan.Restart()
		end
	end,
}

function Send(user,sMessage)
	sMessage = sMessage:gsub("|",endpipe)
	Core.SendToUser(user,sMessage.."|")
end

function OnStartup()
	function ProfMan.Save()
		local f = io.open(Core.GetPtokaXPath().."cfg/Profiles.xml","w")
		f:write("<?xml version=\"1.0\" encoding=\"windows-1252\" standalone=\"yes\" ?>\n<Profiles>")
		for _,v in ipairs(ProfMan.GetProfiles()) do
			f:write("\n    <Profile>\n        <Name>"..XMLEscape(v.sProfileName).."</Name>\n        <Permissions>")
			for i=0,255 do
				local exst,val = pcall(ProfMan.GetProfilePermission,v.iProfileNumber,i)
				f:write(exst and val and "1" or "0")
			end
			f:write("</Permissions>\n    </Profile>")
		end
		f:write("\n</Profiles>\n")
		f:close()
	end

	function ScriptMan.Save()
		local f = io.open(Core.GetPtokaXPath().."cfg/Scripts.xml","w")
		f:write("<?xml version=\"1.0\" encoding=\"windows-1252\" standalone=\"yes\" ?>\n<Scripts>")
		for _,v in ipairs(ScriptMan.GetScripts()) do
			f:write("\n    <Script>\n        <Name>"..XMLEscape(v.sName).."</Name>\n        <Enabled>"..(v.bEnabled and "1" or "0").."</Enabled>\n    </Script>")
		end
		f:write("\n</Scripts>\n")
		f:close()
	end
end

function XMLEscape(str)
	str=str:gsub("&","&amp;")
	for i,v in pairs({["'"] = "&apos;", ["\""] = "&quot;", ["<"] = "&lt;", [">"] = "&gt;", }) do
		str=str:gsub(i,v)
	end
	return str
end
