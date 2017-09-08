net.Receive("gplacer_updateprops",function()
	GPLACER.CurPlaced = net.ReadTable()
end)

net.Receive("gplacer_updatestate",function()
	GPLACER.Enabled = net.ReadBool()
	if GPLACER.Enabled then
		hook.Add("HUDPaint", "GPlacerHud", function()
			draw.SimpleTextOutlined("GPlacer Enabled", "DermaLarge", ScrW()*0.5, ScrH()*0.9, Color(0,130,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0,0,0,255))
			for k, v in pairs(GPLACER.CurPlaced or {}) do
				local ent = v.Ent
				if not IsValid(ent) then continue end
				local pos = v.Pos or (ent:GetPos() + ent:OBBCenter())
				local pos2d = pos:ToScreen()
				if pos:Distance(EyePos()) <= 1024 then
				draw.SimpleTextOutlined(v.Class, "DermaLarge", pos2d.x, pos2d.y,	Color(0,130,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255))
				end
			end
		end)
	else
		hook.Remove("HUDPaint", "GPlacerHud")
	end
end)
	
CreateClientConVar("gplacer_class", "prop_static", false, true)
