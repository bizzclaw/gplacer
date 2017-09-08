GPLACER.CurVersion = nil


function GPLACER.FindVersion(mapname, forceupdate)
  mapname = mapname or game.GetMap()
  if not forceupdate and GPLACER.CurVersion then
    return GPLACER.CurVersion
  end
  local bspversion = game.GetMapVersion()
  for i = 0, 20 do
    local ver = bspversion + i
    if hammer.SendCommand("session_begin "..mapname.." "..ver) == "ok" then
      GPLACER.CurVersion = ver
      print("Current Map Version: "..ver)
      hammer.SendCommand("session_end")
      return bspversion + i
    end
  end
  hammer.SendCommand("session_end")
  return false
end

function GPLACER.On(ply, mapname)
  local version = GPLACER.FindVersion(mapname, true)
  if not version then
    ply:ChatPrint("Either Hammer is not running with the current map, or the Proper map version was not found and the map must be recompiled and reloaded in game.")
    return false
  end
  GPLACER.Enabled = true
  GPLACER.Sync()
  return true
end

function GPLACER.Off(ply, mapname)
  GPLACER.Enabled = false
  GPLACER.Sync()
  return true
end

function GPLACER.MatrixToString(matrix, iscolor)
  if iscolor then
    return " "..matrix.r.." "..matrix.g.." "..matrix.b
  else
    return " "..matrix[1].." "..matrix[2].." "..matrix[3]
  end
end

function GPLACER.Update(mapname, forceupdate)
  local version = GPLACER.FindVersion(mapname, forceupdate)
  if not version then
    return false
  end
  mapname = mapname or game.GetMap()
  hammer.SendCommand("session_begin "..mapname.." "..version)

  for k, v in pairs(GPLACER.CurPlaced) do
    if v.LastPlaced then
      hammer.SendCommand("entity_delete "..(v.LastClass or v.Class)..GPLACER.MatrixToString(v.LastPlaced)) -- delete all of the entities from the last update
    end
    if not IsValid(v.Ent) then
      GPLACER.CurPlaced[k] = nil -- table.Remove wasn't working.
      continue
    end

    v.LastClass = v.Class
    v.LastPlaced = v.Pos or v.Ent:GetPos()
    local col = v.Ent:GetColor()
    local mdl = v.Ent:GetModel()
    local ang = v.Ent:GetAngles()

    local KeyValues = {
      ["model"] = mdl,
      ["angles"] = ang and GPLACER.MatrixToString(ang),
      ["skin"] = v.Ent:GetSkin(),
      ["rendercolor"] = col and not istable(col) and GPLACER.MatrixToString(col),
      ["renderamt"] = col and col.a,
      ["renderfx"] = v.Ent:GetRenderFX()
    }

    if v.KeyValues then
      table.Merge(KeyValues, v.KeyValues)
    end

    local Pos = GPLACER.MatrixToString(v.LastPlaced)

    hammer.SendCommand("entity_create "..v.Class..Pos)
    for key, value in pairs(KeyValues) do
      if not value then continue end -- skip if false
      hammer.SendCommand("entity_set_keyvalue "..v.LastClass..Pos.." \""..key.."\" \""..value.."\"")
    end
  end

  hammer.SendCommand("session_end")
  return true
end

function GPLACER.Sync()
  net.Start("gplacer_updatestate")
  net.WriteBool(GPLACER.Enabled)
  net.Broadcast()
end

GPLACER.CurPlaced = GPLACER.CurPlaced or {}
util.AddNetworkString("gplacer_updateprops")
util.AddNetworkString("gplacer_updatestate")

local SpawnHooks = {
  ["PlayerSpawnedProp"] = false,
  ["PlayerSpawnedEffect"] = false,
  ["PlayerSpawnedRagdoll"] = "prop_ragdoll"
}

for hooks, override in pairs(SpawnHooks) do
  hook.Add(hooks, "GPlacer_"..hooks, function(ply, model, ent)
    if GPLACER.Enabled then
      if override then
        local pos = ent:GetPos() + Vector(0,0,4)
        local model = ent:GetModel()
        ent:Remove()
        ent = ents.Create("prop_effect")
        ent:SetPos(pos)
        ent:SetModel(model)
        ent:Spawn()
        ent:Activate()
        undo.Create( "Hammer Prop" )
         undo.AddEntity( ent )
         undo.SetPlayer( ply )
        undo.Finish()
      end
      GPLACER.RegisterEnt(ent, override or ply:GetInfo("gplacer_class"))
    end
  end)
end

function GPLACER.RegisterEnt(ent, class, pos, KeyValues)
  table.insert(GPLACER.CurPlaced, {
    Ent = ent,
    Pos = pos,
    Class = class,
    KeyValues = KeyValues
  })
  timer.Simple(math.Min(FrameTime(),1), function() -- for some reason was causing issues until I put it on a timer, probably waiting for then end to initialize in the next frame.
    net.Start("gplacer_updateprops")
    net.WriteTable(GPLACER.CurPlaced)
    net.Broadcast()
  end)
end

GPLACER.OldRopeFunction = GPLACER.OldRopeFunction or constraint.CreateKeyframeRope

function constraint.CreateKeyframeRope(pos, width, mat, constraint, ent1, lpos1, bone1, ent2, lpos2, bone2, tab)
  local rope = GPLACER.OldRopeFunction(pos, width, mat, constraint, ent1, lpos1, bone1, ent2, lpos2, bone2, tab)
  if GPLACER.Enabled then  -- I found out about GExporter after I finished making this and it supported ropes. This saves the same Key Values as GExporter, but as you can see the code is completely different.
    local RopeID = table.Count(GPLACER.CurPlaced or {}) + 1
    local StartName = "grope_begin_"..RopeID
    local EndName = "grope_end_"..RopeID
      local PositionProcess = {
        [1] = {ent = ent1, pos = lpos1},
        [2] = {ent = ent2, pos =  lpos2}
      }

      local Positions = {}

      for pid, info in pairs(PositionProcess) do
        if info.ent:IsWorld() then
          Positions[pid] = info.pos
        else
          local EntPos = info.ent:GetPos() -- I want to die
          Positions[pid] = EntPos - (info.ent:GetRight() * info.pos[2])
          Positions[pid] = Positions[pid] + (info.ent:GetForward() * info.pos[1])
          Positions[pid] = Positions[pid] + (info.ent:GetUp() * info.pos[3])
        end
      end

      local Slack = math.Max(tab.Length - (Positions[1]:Distance(Positions[2])), 0)

      GPLACER.RegisterEnt(rope, "move_rope", Positions[1], {
        width = width,
        RopeMaterial = mat,
        targetname = StartName,
        NextKey = EndName,
        Slack = Slack,
        Type = (rope.rigid and "2") or nil
      })
      GPLACER.RegisterEnt(rope, "keyframe_rope",  Positions[2], {
        width = width,
        RopeMaterial = mat,
        targetname = EndName,
        Slack = Slack,
        Type = (rope.rigid and "2") or nil
      })
  end
  return rope
end

-- not going to bother putting admin checks here, I figure this will only ever be used by one person or their friends while mapping.
concommand.Add("gplacer_toggle", function(ply, cmd, args)
  local enabled = GPLACER.Enabled and "Off" or "On"
  if GPLACER[enabled](ply) then
    ply:ChatPrint("Gplacer "..enabled..".")
  end
end)

concommand.Add("gplacer_update", function(ply, cmd, args)
  if GPLACER.Update(args[1], true) then
    ply:ChatPrint("Gplacer: Entities Updated to map!")
    timer.Simple(math.Min(FrameTime(),0.4), function()
      GPLACER.Update(args[1]) -- failsafe for weird behavior.
    end)
  end
end)
