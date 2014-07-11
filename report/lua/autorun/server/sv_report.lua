util.AddNetworkString("NewReport");
util.AddNetworkString("UpdateReport");
util.AddNetworkString("OpenReportMenu");
util.AddNetworkString("OpenReportMenu_Admin");
util.AddNetworkString("DeleteReport");

reports = {};

local Player = FindMetaTable("Player");

function Player:CanReport()
	if ((CurTime() - self:GetPData("LastReport", 0)) / 60 > report.ReportCoolDown) then return true, 0; end
	return false, ((CurTime() - self:GetPData("LastReport", 0)) / 60);
end

local function msg(caller, msg)
	caller:Chat(report.BracketColor, "[", report.ReportTextColor, "Reports", report.BracketColor, "] ", report.MsgColor, msg);
end

local function CreateReport(creator, against, reason, details)
	if (!creator or !against or !reason or !details) then msg(creator, "One or more fields were not supplied!"); return; end

	local can, tim = creator:CanReport();

	if (!can) then msg(creator, "You must wait at least "..report.ReportCoolDown.." minutes to report again! Time left: "..math.Round(report.ReportCoolDown - tim).." minutes."); return; end
	
	creator:SetPData("LastReport", CurTime());
	table.insert(reports, {creator:Nick(), creator:SteamID(), against:Nick(), against:SteamID(), reason, details, "Open", os.time()});
	msg(creator, "Report successfully submitted! Online admins have been notified!");
	for k,v in pairs(player.GetAll()) do
		if (v:Admin()) then
			msg(v, "A new report has been submitted!");
		end
	end
end

local function UpdateReportStatus(caller, reportId, status)
	if (!caller:Admin()) then msg(creator, "You must be an admin to do this!"); return; end
	if (!reportId or !status) then msg(creator, "One or more fields were not supplied!"); return; end
	
	local rep = reports[reportId];
	if (!rep) then msg(creator, "Report not found! Try re-opening your menu!"); return; end
	
	rep[7] = status;
end

local function DeleteReport(caller, reportId)
	if (!caller:SA()) then msg(creator, "You must be a super admin to do this!"); return; end
	if (!reportId) then msg(creator, "One or more fields were not supplied!"); return; end
	
	local rep = reports[reportId];
	if (!rep) then msg(creator, "No report found with that ID! Try re-opening your menu!"); return; end
	
	table.remove(reports, reportId);
end

net.Receive("NewReport", function(len, client)
	local against = net.ReadString();
	local reason = net.ReadString();
	local details = net.ReadString();

	if (!against or !reason or !details) then msg(creator, "One or more fields were not supplied!"); return; end
	
	for k, v in pairs(player.GetAll()) do
		print(v:Nick(), against)
		if (v:Nick() == against) then against = v; end
	end

	if (type(against) == "string") then msg(creator, "No valid target found!"); return; end

	CreateReport(client, against, reason, details);
end)

net.Receive("UpdateReport", function(len, client)
	local status = net.ReadString();
	local reportID = net.ReadString();
	local reportID = tonumber(reportID);

	if (!status or !reportID) then msg(creator, "One or more fields were not supplied!"); return; end
	
	UpdateReportStatus(client, reportID, status);
end)

net.Receive("DeleteReport", function(len, client)
	local reportID = net.ReadString();
	local reportID = tonumber(reportID);

	if (!reportID) then msg(creator, "One or more fields were not supplied!"); return; end
	
	DeleteReport(client, reportID);
end)

hook.Add("PlayerSay", "OpenReportMenu", function(ply, text)
	if (string.sub(text, 1, 8) == "!reporta" && ply:SA() then
		net.Start("OpenReportMenu_Admin");
			net.WriteTable(reports);
		net.Send(ply);
	elseif (string.sub(text, 1, 7) == "!report") then
		net.Start("OpenReportMenu");
		net.Send(ply);
	end
end)