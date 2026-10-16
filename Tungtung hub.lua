local _0xTXT = {
	CHOOSE_PET="Chọn: pet",FIND_EGG="Tìm trứng",GO_EGG="Đến trứng",GRAB_EGG="Lụm trứng",
	DELIVER_OK="Giao hàng thành công",DELIVER_FAIL="Giao hàng thất bại",EGG_GONE="Trứng không còn",
	CANT_REACH="Không đến được trứng",CANT_GRAB="Không lụm được",CANCELLING="Đang huỷ",
	AUTO_OFF="Auto: TẮT",AUTO_ON="Auto: BẬT",BAY_OFF="Auto Bay: TẮT",BAY_ON="Auto Bay: BẬT",
	EGG_FAR="Trứng rơi xa, đang TP lại",EGG_NEAR="Trứng rơi gần, lụm lại",GO_HOME="Về nhà",
	DROP_EGG="Thả trứng qua vạch",REGRAB_EGG="Lụm trứng lại",CANT_REGRAB="Không lụm được trứng",
	BAY_DONE="Auto Bay: xong",BAY_FAIL="Auto Bay: thất bại",BAY_LOST="Auto Bay: mất trứng, dừng",
	BAY_DROP="Auto Bay: thả trứng",BAY_LAND="Auto Bay: hạ cánh",BAY_HOME="Auto Bay: về nhà",
	BAY_FLYING="Auto Bay: đang bay về nhà",WAIT_STABLE="Chờ ổn định...",
	AUTO_TAKING="Auto: đang lấy ",AUTO_NO_EGG="Auto: không có trứng, thử lại...",
	FLYING_HOME="Đang bay về",PULLED_BACK="Bị kéo lại, thử ",LAND_NEAR="Hạ cánh gần vạch",
	LAND_AGAIN="Hạ cánh lại lần ",DELIVERING="Đang giao hàng",ERR="Lỗi: ",
	CHOOSE="Chọn: ",DELIVERING_ALT="Đang giao hàng",FLYING_HOME_ALT="Đang bay về nhà",
}

local Pl  = game:GetService("Players")
local RS  = game:GetService("RunService")
local Rep = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CG  = game:GetService("CoreGui")
local lp  = Pl.LocalPlayer

local CFG = {
	SpeedCap=1.15, HopRatio=1.515, HopMin=40,
	HopGap=0.06, HopGapMin=0.06, HopGapMax=0.2,
	HopRetries=6, HopLift=42, LandOffset=14,
	LandSettle=0.08, DropDelay=0.05, GrabInterval=0.03,
	RegrabFar=40, Height=70, ClimbShare=0.5,
	CarryRatio=0.9, EasyRatio=1.3,
}
local FPS = {60,30,0.15}

local function safeReq(fn)
	local ok,r = pcall(function() return require(fn()) end)
	return ok and r or nil
end

local net = Rep:WaitForChild("Packages"):WaitForChild("Networking")
local ES  = safeReq(function() return Rep.Client.EggState end)
local As  = safeReq(function() return Rep.Data.Assets end)
local Mu  = safeReq(function() return Rep.Shared.Modules.Mutations end)

local function rm(n)  return net:FindFirstChild(n) end
local function rt()   local c=lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end

local sh = {Or=nil,Cl=nil,Lk={},Co=nil,Ad=nil}

local function ws()
	local c  = lp.Character
	local hm = c and c:FindFirstChildOfClass("Humanoid")
	local sp = hm and hm.WalkSpeed or 16
	if sh.Or and sh.Or.Health>0 then sp=math.min(sp,sh.Or.WalkSpeed) end
	local ok,r = pcall(function()
		local st2 = lp:FindFirstChild("leaderstats")
		st2 = st2 and st2:FindFirstChild("Speed")
		local u = require(Rep.Shared.Util.TreadmillUtil)
		return st2 and u.SpeedPowerToWalkSpeed(st2.Value) or nil
	end)
	if ok and type(r)=="number" and r>0 then sp=math.min(sp,r) end
	return sp
end

local function shCtrl(hm)
	pcall(function()
		local s = lp:FindFirstChild("PlayerScripts")
		local m = s and s:FindFirstChild("PlayerModule")
		if m then
			local c = require(m):GetControls()
			if type(c)=="table" then c.humanoid=hm end
		end
	end)
end

local function shAnim(c)
	local a = c and c:FindFirstChild("Animate")
	if a and a:IsA("LocalScript") then
		task.spawn(function() a.Enabled=false; task.wait(); a.Enabled=true end)
	end
end

local function shUnlk()
	for _,l in ipairs(sh.Lk) do pcall(function() l:Disconnect() end) end
	table.clear(sh.Lk)
end

local gSt = {
	[Enum.HumanoidStateType.Running]=true,
	[Enum.HumanoidStateType.RunningNoPhysics]=true,
	[Enum.HumanoidStateType.Landed]=true,
}

local function grnd(hm)
	if not hm or hm.Health<=0 or hm.FloorMaterial==Enum.Material.Air then return false end
	return gSt[hm:GetState()]==true
end

local function shSwap()
	local c  = lp.Character
	local hm = c and c:FindFirstChildOfClass("Humanoid")
	if not hm or hm.Health<=0 then return end
	if sh.Cl and sh.Cl.Parent==c then return end
	if not grnd(hm) then return end
	local cl = hm:Clone()
	hm.Parent = nil
	cl.Parent = c
	workspace.CurrentCamera.CameraSubject = cl
	shCtrl(cl); shAnim(c)
	sh.Or=hm; sh.Cl=cl
	table.insert(sh.Lk, hm:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if cl.Parent~=nil then cl.WalkSpeed=hm.WalkSpeed end
	end))
	local a1=hm:FindFirstChildOfClass("Animator")
	local a2=cl:FindFirstChildOfClass("Animator")
	if a1 and a2 then
		table.insert(sh.Lk, a1.AnimationPlayed:Connect(function(pl)
			local an=pl.Animation
			if not an or cl.Parent==nil then return end
			local ok,tr=pcall(function() return a2:LoadAnimation(an) end)
			if not ok or not tr then return end
			pcall(function()
				tr.Priority=pl.Priority; tr.Looped=pl.Looped
				tr:Play(0.05,math.max(pl.WeightTarget,0.01),pl.Speed)
			end)
			local st2; st2=pl.Stopped:Connect(function()
				st2:Disconnect(); pcall(function() tr:Stop(0.1) end)
			end)
		end))
	end
	table.insert(sh.Lk, cl.Died:Connect(function()
		shUnlk(); sh.Or,sh.Cl=nil,nil
		local cur=lp.Character
		if cur and hm.Parent==nil then
			hm.Parent=cur
			workspace.CurrentCamera.CameraSubject=hm
			shCtrl(hm)
		end
		pcall(function() cl:Destroy() end)
		hm.Health=0
	end))
end

local function shUndo()
	shUnlk()
	local c=lp.Character; local or_,cl=sh.Or,sh.Cl
	sh.Or,sh.Cl=nil,nil
	if or_ and cl and c and or_.Parent==nil and cl.Parent==c then
		or_.Parent=c
		workspace.CurrentCamera.CameraSubject=or_
		shCtrl(or_); pcall(function() cl:Destroy() end); shAnim(c)
	end
end

local function shStart()
	shSwap()
	local n=0
	sh.Co=RS.Heartbeat:Connect(function(dt)
		n+=dt
		local c=lp.Character
		local ms=not(sh.Cl and c and sh.Cl.Parent==c)
		if (ms and 0.25 or 3)<=n then n=0; shSwap() end
	end)
	sh.Ad=lp.CharacterAdded:Connect(function(c)
		shUnlk(); sh.Or,sh.Cl=nil,nil
		task.spawn(function()
			c:WaitForChild("Humanoid",10); task.wait(1)
			if sh.Co and lp.Character==c then shSwap() end
		end)
	end)
end

local function shStop()
	if sh.Co then sh.Co:Disconnect(); sh.Co=nil end
	if sh.Ad then sh.Ad:Disconnect(); sh.Ad=nil end
	shUndo()
end

local st = {
	Cr=false, Uid=nil, Dv=0, Bz=false,
	Cx=false, Ml=1, Pa=0, HS=0, GD=false, RC=nil,
}
local au  = {On=false, Th=nil}
local afh = {On=false, Th=nil, Bz=false, Cx=false}

local function rstSt()
	st.Cx=false; st.Bz=false; st.GD=false
	if st.RC then pcall(st.RC); st.RC=nil end
end

if type(ES)=="table" and type(ES.CarryChanged)=="table" and type(ES.CarryChanged.Connect)=="function" then
	ES.CarryChanged:Connect(function(a)
		local cr=type(a)=="table" and a.IsCarrying==true
		if cr and a.GuardDisabled==true then cr=false end
		st.GD=false
		if cr then st.HS=os.clock() end
		if cr and type(a.Uid)=="string" then
			st.Uid=a.Uid
			local m=tonumber(a.SpeedMultiplier)
			if m and m>0 then st.Ml=m end
		end
		st.Cr=cr
	end)
end

pcall(function()
	rm("RE/EggWorld/FieldEggRedeemVerdict").OnClientEvent:Connect(function()
		st.Dv=os.clock()
	end)
end)
pcall(function()
	rm("RE/RigSync/Refresh").OnClientEvent:Connect(function(a)
		if type(a)=="table" and a.Action=="Relocate" then st.Pa=os.clock() end
	end)
end)

local function tkEgg(uid)
	if type(uid)=="string" and type(ES)=="table" and type(ES.CarryFieldEgg)=="function" then
		pcall(ES.CarryFieldEgg,uid)
	end
end
local function dpEgg()
	if type(ES)=="table" and type(ES.DropFieldEgg)=="function" then
		pcall(ES.DropFieldEgg,"PlayerRequest")
	end
end

local function prNear(pos,rad)
	local bt,bd=nil,rad
	for _,c in ipairs(workspace:GetChildren()) do
		if c.Name=="SmartPromptPart" and c:IsA("BasePart") then
			local p=c:FindFirstChild("CarryAreaEgg")
			if p and p:IsA("ProximityPrompt") then
				local d=(c.Position-pos).Magnitude
				if d<bd then bt,bd=p,d end
			end
		end
	end
	return bt
end

local function hbMe(uid)
	local c=lp.Character
	if type(uid)~="string" or not c then return false end
	local e=workspace:FindFirstChild(uid)
	if not e then return false end
	for _,d in ipairs(e:GetDescendants()) do
		if d:IsA("WeldConstraint") or d:IsA("JointInstance") then
			local ok,a,b=pcall(function() return d.Part0,d.Part1 end)
			if ok and((a and a:IsDescendantOf(c)) or (b and b:IsDescendantOf(c))) then return true end
		end
	end
	return false
end

task.spawn(function()
	while true do
		task.wait(0.2)
		if not st.Cr then
			if st.GD and hbMe(st.Uid) then st.GD,st.Cr,st.HS=false,true,os.clock() end
		elseif hbMe(st.Uid) then
			st.HS=os.clock()
		elseif os.clock()-st.HS>0.8 then
			st.Cr,st.GD=false,true
		end
	end
end)

local function snap()
	local li={}
	local ok,r=pcall(function() return rm("RF/EggWorld/AskFieldEggSnapshot"):InvokeServer() end)
	local rc=ok and type(r)=="table" and r.Records or nil
	if type(rc)~="table" then return li end
	for _,rec in pairs(rc) do
		if type(rec)=="table" and type(rec.Uid)=="string"
			and (rec.State=="Slot" or rec.State=="Dropped")
			and typeof(rec.BottomCFrame)=="CFrame"
		then li[#li+1]=rec end
	end
	return li
end

local function eggPos(uid)
	for _,rec in ipairs(snap()) do
		if rec.Uid==uid then return rec.BottomCFrame.Position end
	end
	return nil
end

local function desc(rec)
	local dir=type(As)=="table" and As.Directory or nil
	local en=type(dir)=="table" and dir[tostring(rec.AssetCategory)] or nil
	local inf={Uid=rec.Uid,Cat=tostring(rec.AssetCategory),Name=tostring(rec.AssetCategory),Icon="",Rar=0,Val=0}
	if type(en)=="table" then
		inf.Name=tostring(en.DisplayName or rec.AssetCategory)
		local ic=en.Icon
		if ic~=nil and tostring(ic)~="" then
			ic=tostring(ic)
			inf.Icon=tonumber(ic) and ("rbxassetid://"..ic) or ic
		end
		if type(en.Rarity)=="table" then
			inf.Rar=tonumber(en.Rarity.RarityNumber or en.Rarity.Rank) or 0
		end
		local sc=tonumber(rec.AssetScale) or 1
		local fc=sc>5 and (sc/5)^1.2*19.637875755794113 or sc^1.85
		local mu=1
		if type(Mu)=="table" and type(Mu.EarningsFor)=="function" then
			local ok,re=pcall(Mu.EarningsFor,type(rec.Mutations)=="table" and rec.Mutations or {})
			if ok and type(re)=="number" then mu=re end
		end
		inf.Val=(tonumber(en.EarningRate) or 0)*fc*mu
	end
	return inf
end

local function fmtMoney(v)
	local u={{1e12,"N"},{1e9,"T"},{1e6,"Tr"},{1e3,"K"}}
	for _,x in ipairs(u) do
		if v>=x[1] then return string.format("$%.2f%s/s",v/x[1],x[2]) end
	end
	return string.format("$%d/s",math.floor(v+0.5))
end

local setStatus=function() end

local fpsG=0
local function fpsOn()
	if typeof(setfpscap)~="function" then return end
	fpsG+=1; local mn=fpsG
	task.spawn(function()
		local hi=true; local t=os.clock()
		while fpsG==mn and os.clock()-t<60 do
			pcall(setfpscap,hi and FPS[1] or FPS[2])
			hi=not hi; task.wait(FPS[3])
		end
	end)
end
local function fpsOff()
	fpsG+=1
	if typeof(setfpscap)=="function" then pcall(setfpscap,240) end
end

local sCl=nil
local function dpCl()
	local cp=sCl; sCl=nil
	if cp then pcall(function() cp:Destroy() end) end
end
local function mkCl()
	dpCl()
	local c=lp.Character; if not c then return end
	local w=c.Archivable; c.Archivable=true
	local cp=c:Clone(); c.Archivable=w
	if cp then
		for _,d in ipairs(cp:GetDescendants()) do
			if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") then
				pcall(function() d:Destroy() end)
			elseif d:IsA("BasePart") then
				d.Anchored=true; d.CanCollide=false; d.CanTouch=false; d.CanQuery=false
			end
		end
		cp.Name="Clone"; cp.Parent=workspace; sCl=cp
	end
end

local function lineI()
	local w=workspace:FindFirstChild("World") or workspace:FindFirstChild("__OBJECTS")
	w=w and w:FindFirstChild("Areas"); w=w and w:FindFirstChild("SeparationLine")
	local ok=w and w:IsA("BasePart")
	return ok and w.Position.X or 552.2, ok and w.Position.Y or 67.67
end

local function homeP()
	for _,df in ipairs({
		{{"GearGiver_Slap","Podium"},Vector3.new(-16.415,21.072,-6.106)},
		{{"World","Machines","RiftMachine","Rift","Meshes/VoidPortal_Cube.003"},Vector3.new(-26.776,1.75,18.665)},
		{{"__OBJECTS","Machines","RiftMachine","Rift","Meshes/VoidPortal_Cube.003"},Vector3.new(-26.776,1.75,18.665)},
	}) do
		local nd=workspace
		for _,nm in ipairs(df[1]) do nd=nd and nd:FindFirstChild(nm) or nil end
		if nd and nd:IsA("BasePart") then return nd.CFrame:PointToWorldSpace(df[2]) end
	end
	return Vector3.new(615.70,70.57,-395.30)
end

local function plc(pos)
	local r=rt(); if not r then return end
	pcall(function()
		r.CFrame=CFrame.new(pos)*CFrame.Angles(0,math.rad(90),0)
		r.AssemblyLinearVelocity=Vector3.zero
		r.AssemblyAngularVelocity=Vector3.zero
	end)
end

local dCa,dAt={},0
local function dngrs()
	if os.clock()-dAt<1 then return dCa end
	dAt=os.clock(); local li={}
	local function add(i)
		local ok,cf,sz=pcall(function()
			if i:IsA("Model") then return i:GetBoundingBox()
			elseif i:IsA("BasePart") then return i.CFrame,i.Size end
		end)
		if ok and cf and sz then
			local hf=Vector3.new(math.abs(sz.X),0,math.abs(sz.Z))*0.5
			local ro=(cf-cf.Position):VectorToWorldSpace(hf)
			local rx=math.max(math.abs(ro.X),hf.X,hf.Z)
			local rz=math.max(math.abs(ro.Z),hf.X,hf.Z)
			li[#li+1]={MinX=cf.Position.X-rx,MaxX=cf.Position.X+rx,MinZ=cf.Position.Z-rz,MaxZ=cf.Position.Z+rz}
		end
	end
	local function bad(n)
		if n=="ScrambleLocalVisuals" or n=="DrScrambleEvent" then return false end
		n=string.lower(n)
		return string.find(n,"portal",1,true) or string.find(n,"teleport",1,true)
			or string.find(n,"mech",1,true) or string.find(n,"arena",1,true)
			or string.find(n,"scramble",1,true)
	end
	for _,ch in ipairs(workspace:GetChildren()) do
		if (ch:IsA("Model") or ch:IsA("BasePart") or ch:IsA("Folder")) and bad(ch.Name) then
			if ch:IsA("Folder") then for _,i in ipairs(ch:GetChildren()) do add(i) end
			else add(ch) end
		end
	end
	local bl=workspace:FindFirstChild("World"); bl=bl and bl:FindFirstChild("Build")
	if bl then
		for _,ch in ipairs(bl:GetChildren()) do
			if bad(ch.Name) then for _,i in ipairs(ch:GetChildren()) do add(i) end end
		end
	end
	dCa=li; return li
end

local function avd(fr,to)
	for _,d in ipairs(dngrs()) do
		local x0,x1,z0,z1=d.MinX-12,d.MaxX+12,d.MinZ-12,d.MaxZ+12
		local ins=fr.X>=x0 and fr.X<=x1 and fr.Z>=z0 and fr.Z<=z1
		if not ins then
			local t0,t1,hit=0,1,true
			for _,ax in ipairs({{fr.X,to.X-fr.X,x0,x1},{fr.Z,to.Z-fr.Z,z0,z1}}) do
				local p,dl,lo,hi=ax[1],ax[2],ax[3],ax[4]
				if math.abs(dl)<1e-6 then
					if p<lo or p>hi then hit=false end
				else
					local ta,tb=(lo-p)/dl,(hi-p)/dl
					if ta>tb then ta,tb=tb,ta end
					t0,t1=math.max(t0,ta),math.min(t1,tb)
					if t0>t1 then hit=false end
				end
			end
			if hit then
				local zL,zH=z0-2,z1+2
				local z=math.abs(fr.Z-zL)<=math.abs(fr.Z-zH) and zL or zH
				if z<-440 or z>-290 then z=z==zL and zH or zL end
				local x=math.abs(fr.X-x0)<=math.abs(fr.X-x1) and x0 or x1
				if math.abs(fr.Z-z)<3 then x=math.abs(to.X-x0)<=math.abs(to.X-x1) and x0 or x1 end
				return Vector3.new(x,to.Y,z)
			end
		end
	end
	return to
end

local function runToEgg(uid,egg)
	local lX=lineI(); local hm2=homeP()
	local c=lp.Character; local hm=c and c:FindFirstChildOfClass("Humanoid")
	if hm then
		hm.PlatformStand=false
		if c:FindFirstChildWhichIsA("Tool") then pcall(function() hm:UnequipTools() end) end
	end
	local r=rt(); if not r then return false end
	local stg="field"
	if r.Position.X<lX-2 and Vector3.new(r.Position.X-hm2.X,0,r.Position.Z-hm2.Z).Magnitude>20 then stg="safe" end
	local t0,lC,lP,lT=os.clock(),os.clock(),r.Position,0
	while os.clock()-t0<120 and not st.Cx do
		r=rt(); if not r then return false end
		local fE=Vector3.new(egg.X-r.Position.X,0,egg.Z-r.Position.Z)
		if stg=="field" and fE.Magnitude<=2.5 then break end
		local tg=egg
		if stg=="safe" then
			if Vector3.new(hm2.X-r.Position.X,0,hm2.Z-r.Position.Z).Magnitude<=6 then stg="field"
			else tg=hm2 end
		end
		local wp=avd(r.Position,tg)
		local fl=Vector3.new(wp.X-r.Position.X,0,wp.Z-r.Position.Z)
		local un=fl.Magnitude>0.01 and fl.Unit or Vector3.zero
		local sp=math.max(ws()*CFG.SpeedCap,8)
		local v=un*math.min(sp,fl.Magnitude/0.05)
		pcall(function()
			r.AssemblyLinearVelocity=Vector3.new(v.X,r.AssemblyLinearVelocity.Y,v.Z)
			if hm and un.Magnitude>0 then hm:Move(un,false) end
		end)
		if os.clock()-lC>=1.5 then
			if (r.Position-lP).Magnitude<3 and hm and fE.Magnitude>15 then pcall(function() hm.Jump=true end) end
			lP,lC=r.Position,os.clock()
		end
		if stg=="field" and fE.Magnitude<=9 and os.clock()-lT>0.1 then lT=os.clock(); tkEgg(uid) end
		RS.Heartbeat:Wait()
	end
	r=rt()
	if r then
		pcall(function()
			r.AssemblyLinearVelocity=Vector3.new(0,r.AssemblyLinearVelocity.Y,0)
			if hm then hm:Move(Vector3.zero,false) end
		end)
	end
	return st.Cr or (r~=nil and Vector3.new(egg.X-r.Position.X,0,egg.Z-r.Position.Z).Magnitude<=6)
end

local function eggNow(uid,ca)
	local nd=workspace:FindFirstChild(uid)
	local sl=workspace:FindFirstChild("AreaEggSlotsClient")
	nd=nd or (sl and sl:FindFirstChild(uid))
	if nd then
		local ok,p=pcall(function() return nd:GetPivot().Position end)
		if ok and p then ca.Pos,ca.At=p,os.clock(); return p end
	end
	if os.clock()-ca.At>=0.5 then ca.At=os.clock(); ca.Pos=eggPos(uid) or ca.Pos end
	return ca.Pos
end

local function grab(uid,to)
	local ca={At=0}; local wd,si=0,1
	while not st.Cr and wd<to and not st.Cx do
		local r=rt(); local e=eggNow(uid,ca)
		local dt=math.max(RS.Heartbeat:Wait(),1/240)
		wd+=dt; si+=dt
		if r and e then
			local dl=e-r.Position
			if dl.Magnitude>2 then
				local pc=math.max(ws()*CFG.SpeedCap,16)
				local v=dl/math.max(0.08,dt)
				if v.Magnitude>pc then v=v.Unit*pc end
				pcall(function()
					r.AssemblyLinearVelocity=v+Vector3.new(0,workspace.Gravity*dt*0.5,0)
					r.AssemblyAngularVelocity=Vector3.zero
				end)
			end
			if si>=CFG.GrabInterval then
				si=0
				local pr=prNear(e-Vector3.new(0,3,0),10)
				if pr and typeof(fireproximityprompt)=="function" then
					pcall(function() pr.HoldDuration=0 end)
					pcall(fireproximityprompt,pr)
				end
				task.spawn(tkEgg,uid)
			end
		elseif si>=CFG.GrabInterval then si=0; task.spawn(tkEgg,uid) end
	end
	local r=rt()
	if r then pcall(function() r.AssemblyLinearVelocity=Vector3.zero end) end
	return st.Cr and st.Uid==uid
end

local function regrab(uid)
	if st.Cr then return true end
	local r=rt(); local e=eggPos(uid)
	if r and e and Vector3.new(r.Position.X-e.X,0,r.Position.Z-e.Z).Magnitude>CFG.RegrabFar then
		setStatus(_0xTXT.EGG_FAR)
		plc(e+Vector3.new(0,3,0))
	else
		setStatus(_0xTXT.EGG_NEAR)
	end
	return grab(uid,3)
end

local function grndY(pos,fb)
	local y=fb
	pcall(function()
		local p=RaycastParams.new()
		p.FilterType=Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances={lp.Character}
		p.IgnoreWater=true
		local h=workspace:Raycast(pos+Vector3.new(0,60,0),Vector3.new(0,-140,0),p)
		if h and h.Material~=Enum.Material.Water and math.abs(h.Position.Y-fb)<40 then y=h.Position.Y+3.5 end
	end)
	return y
end

local function crySpd(dist)
	local w=ws(); local bs=w*math.min(CFG.CarryRatio,CFG.SpeedCap)*st.Ml
	local fs=bs*1.5; local ex=5.5*bs; local lm=fs
	if dist and dist>ex then lm=math.min(fs,bs*dist/(dist-ex)) end
	return math.min(math.max(math.min(bs*CFG.EasyRatio,lm),bs),math.max(w*CFG.SpeedCap,bs))
end

local function runHome(lX,lZ,cx_ref)
	cx_ref = cx_ref or function() return st.Cx end
	local t0=os.clock(); local hm=homeP()
	local cp=lX-7; local ht=CFG.Height
	local sh2=math.clamp(CFG.ClimbShare,0.1,0.9)
	local ds=ht*math.sqrt(1-sh2*sh2)/sh2
	local c=lp.Character; local hu=c and c:FindFirstChildOfClass("Humanoid")
	if hu then hu.PlatformStand=false end
	local r=rt()
	if r and c and ht>0.5 and hm.Y+ht-2>r.Position.Y then
		pcall(function()
			c:PivotTo(CFrame.new(Vector3.new(r.Position.X,hm.Y+ht,r.Position.Z))*r.CFrame.Rotation)
			r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
		end)
	end
	local st2=rt()
	local sp=crySpd(st2 and (Vector3.new(st2.Position.X-hm.X,0,st2.Position.Z-hm.Z).Magnitude+math.max(0,ht)*2) or nil)
	local last,tm=os.clock(),0
	setStatus(_0xTXT.GO_HOME)
	while st.Dv<t0 and not cx_ref() and tm<25 do
		r=rt(); if not r then return false end
		local now=os.clock(); local dt=math.max(now-last,1/240)
		last=now; tm+=dt
		local toH=r.Position.X<=cp+2
		local tg=toH and hm or Vector3.new(cp,hm.Y,lZ)
		if toH and Vector3.new(hm.X-r.Position.X,0,hm.Z-r.Position.Z).Magnitude<2 then break end
		local aim=avd(r.Position,tg)
		local fl=Vector3.new(aim.X-r.Position.X,0,aim.Z-r.Position.Z)
		local rm2=toH and 0 or math.max(0,r.Position.X-cp)
		local wY=hm.Y+ht
		if toH or rm2<=ds then wY=hm.Y+ht*math.clamp(rm2/math.max(ds,1),0,1) end
		local vy=math.clamp((wY-r.Position.Y)/0.12,-sp*sh2,sp*sh2)
		local hz=math.sqrt(math.max(sp*sp-vy*vy,0))
		local v=fl.Magnitude>0.01 and fl.Unit*math.min(hz,fl.Magnitude/0.05) or Vector3.zero
		pcall(function() r.AssemblyLinearVelocity=Vector3.new(v.X,vy,v.Z) end)
		RS.Heartbeat:Wait()
	end
	if hu then pcall(function() hu:Move(Vector3.zero,false) end) end
	local sv=0
	while sv<2 and st.Dv<t0 and st.Cr and not cx_ref() do sv+=RS.Heartbeat:Wait() end
	if st.Cr and st.Dv<t0 and not cx_ref() then
		plc(Vector3.new(615.70,70.57,-395.30))
		task.wait(0.2)
		dpEgg()
		local wd=0
		while st.Dv<t0 and wd<1 do wd+=RS.Heartbeat:Wait() end
	end
	return st.Dv>=t0
end

local function instTP(uid, cx_ref)
	cx_ref = cx_ref or function() return st.Cx end
	local t0=os.clock(); local lX,lY=lineI()
	local r=rt(); if not r then return false end
	local lZ=-395.30
	local ld=Vector3.new(lX+CFG.LandOffset,lY+3.35,lZ)
	local hpS=math.max(ws()*CFG.HopRatio,CFG.HopMin)
	local hpY=r.Position.Y+CFG.HopLift
	local x=r.Position.X; local re=0
	st.RC=nil
	pcall(mkCl); fpsOn()
	while x-hpS>ld.X and not cx_ref() do
		if not st.Cr then
			if not regrab(uid) then break end
			local cu=rt(); if cu then x=math.min(x,cu.Position.X) end
			continue
		end
		local nX=x-hpS
		setStatus(_0xTXT.FLYING_HOME)
		local pb=st.Pa; local hd=0
		while hd<CFG.HopGap do plc(Vector3.new(nX,hpY,lZ)); hd+=RS.Heartbeat:Wait() end
		local ck=rt()
		local pl2=st.Pa>pb or (ck~=nil and (ck.Position.X-nX>10 or ck.AssemblyLinearVelocity.Magnitude>150))
		if pl2 and st.Cr and not cx_ref() then
			re+=1; CFG.HopGap=math.min(CFG.HopGapMax,CFG.HopGap+0.02)
			if re>CFG.HopRetries then break end
			setStatus(_0xTXT.PULLED_BACK..re.."/"..CFG.HopRetries)
			local sv=0
			while sv<0.12 and not cx_ref() do plc(Vector3.new(x,hpY,lZ)); sv+=RS.Heartbeat:Wait() end
		else
			x=nX; CFG.HopGap=math.max(CFG.HopGapMin,CFG.HopGap-0.01)
		end
	end
	setStatus(_0xTXT.LAND_NEAR)
	ld=Vector3.new(ld.X,grndY(ld,ld.Y),ld.Z)
	local function land()
		local cu=rt()
		if cu and cu.Position.X<=ld.X+1 and cu.Position.Y>ld.Y-25 then
			pcall(function() cu.AssemblyLinearVelocity=Vector3.zero end); return
		end
		plc(ld)
	end
	land()
	for at=1,3 do
		local sv=0
		while sv<CFG.LandSettle and not cx_ref() do sv+=RS.Heartbeat:Wait() end
		local ln=rt()
		if st.Cr and ln and (ln.Position.X-ld.X>12 or ln.Position.Y<ld.Y-25) then
			setStatus(_0xTXT.LAND_AGAIN..at); land()
		else break end
	end
	dpCl()
	if st.Cr and not cx_ref() then
		setStatus(_0xTXT.WAIT_STABLE)
		local settle=0
		while settle<0.6 and not cx_ref() do settle+=RS.Heartbeat:Wait() end
		if cx_ref() then fpsOff(); return false end
		local dl=0
		while dl<CFG.DropDelay do dl+=RS.Heartbeat:Wait() end
		setStatus(_0xTXT.DROP_EGG)
		dpEgg()
		local wd=0
		while st.Cr and wd<1 and not cx_ref() do wd+=RS.Heartbeat:Wait() end
		if cx_ref() then fpsOff(); return false end
		local cu=rt()
		if cu then
			pcall(function()
				cu.AssemblyLinearVelocity=Vector3.zero
				cu.AssemblyAngularVelocity=Vector3.zero
			end)
		end
		dpCl()
		setStatus(_0xTXT.REGRAB_EGG)
		if not grab(uid,3) and not regrab(uid) then
			fpsOff()
			if cx_ref() then return false end
			setStatus(_0xTXT.CANT_REGRAB); return false
		end
		dpCl()
	end
	local ok=false
	if st.Cr then ok=runHome(lX,lZ,cx_ref) end
	fpsOff()
	if cx_ref() then return false end
	return ok or st.Dv>=t0
end

local function stealDlv(uid,onDone)
	if st.Bz then return end
	st.Bz=true; st.Cx=false
	task.spawn(function()
		local ok,err=pcall(function()
			setStatus(_0xTXT.FIND_EGG)
			local e=eggPos(uid)
			if not e then setStatus(_0xTXT.EGG_GONE); return end
			if st.Cr and st.Uid~=uid then
				dpEgg(); local wd=0
				while st.Cr and wd<1 do wd+=RS.Heartbeat:Wait() end
			end
			fpsOn()
			setStatus(_0xTXT.GO_EGG)
			if not runToEgg(uid,e) then
				fpsOff()
				if st.Cx then return end
				setStatus(_0xTXT.CANT_REACH); return
			end
			if st.Cx then fpsOff(); return end
			setStatus(_0xTXT.GRAB_EGG)
			if not grab(uid,4) then
				fpsOff()
				if st.Cx then return end
				setStatus(_0xTXT.CANT_GRAB); return
			end
			local dv=instTP(uid)
			if st.Cx then return end
			setStatus(dv and _0xTXT.DELIVER_OK or _0xTXT.DELIVER_FAIL)
		end)
		fpsOff(); dpCl()
		if not ok then setStatus(_0xTXT.ERR..tostring(err)) end
		st.Bz=false
		if onDone then onDone() end
	end)
end

local function afhFlyHome()
	if afh.Bz then return end
	if not st.Cr then return end
	afh.Bz=true; afh.Cx=false
	task.spawn(function()
		local uid=st.Uid
		setStatus(_0xTXT.BAY_FLYING)
		local ok,err=pcall(function()
			local dv=instTP(uid, function() return afh.Cx end)
			setStatus(dv and _0xTXT.BAY_DONE or _0xTXT.BAY_FAIL)
		end)
		dpCl(); fpsOff()
		if not ok then setStatus(_0xTXT.ERR..tostring(err)) end
		afh.Bz=false
	end)
end

local function startAfh()
	if afh.On then return end
	afh.On=true
	afh.Th=task.spawn(function()
		local wasCarry=false
		while afh.On do
			task.wait(0.3)
			local now=st.Cr
			if now and not wasCarry and not afh.Bz and not st.Bz then
				task.wait(0.05)
				if st.Cr and not afh.Bz and not st.Bz then
					afhFlyHome()
				end
			end
			wasCarry=now
		end
	end)
end

local function stopAfh()
	afh.On=false; afh.Cx=true; afh.Th=nil
end

local function getSorted()
	local li={}
	local ok,rc=pcall(snap)
	if not ok then return li end
	for _,rec in ipairs(rc) do li[#li+1]=desc(rec) end
	table.sort(li,function(a,b) return a.Val>b.Val end)
	return li
end

local function startAuto()
	if au.On then return end
	au.On=true
	au.Th=task.spawn(function()
		while au.On do
			st.Cx=false
			if st.Bz then task.wait(0.3); continue end
			local eggs=getSorted()
			if #eggs==0 then setStatus(_0xTXT.AUTO_NO_EGG); task.wait(3); continue end
			local tg=eggs[1]
			setStatus(_0xTXT.AUTO_TAKING..tg.Name)
			local dn=false
			stealDlv(tg.Uid,function() dn=true end)
			local bw=0
			while not st.Bz and bw<0.5 and au.On do bw+=task.wait(0.05) end
			local wd=0
			while not dn and au.On do
				task.wait(0.1); wd+=0.1
				if wd>60 then
					st.Cx=true
					local dr=0
					while st.Bz and dr<2 do dr+=task.wait(0.1) end
					st.Bz=false; break
				end
			end
			task.wait(0.5)
		end
	end)
end

local function stopAuto()
	au.On=false; au.Th=nil; st.Cx=true
end

local WH = Color3.fromRGB(255,255,255)
local SL = Color3.fromRGB(150,150,156)
local ST = Color3.fromRGB(70,70,76)
local BG = Color3.fromRGB(0,0,0)
local AON = Color3.fromRGB(50,200,100)
local AOF = Color3.fromRGB(0,0,0)
local AFN = Color3.fromRGB(50,160,255)
local AFF = Color3.fromRGB(0,0,0)
local RC = {
	Color3.fromRGB(190,190,190),Color3.fromRGB(110,210,110),Color3.fromRGB(90,160,255),
	Color3.fromRGB(190,110,255),Color3.fromRGB(255,170,50),Color3.fromRGB(255,80,80),
	Color3.fromRGB(255,90,200),Color3.fromRGB(80,235,235),
}

local function pGui()
	if typeof(gethui)=="function" then
		local ok,r=pcall(gethui)
		if ok and typeof(r)=="Instance" then return r end
	end
	return CG
end

local function mk(cl,pr)
	local i=Instance.new(cl)
	for k,v in pairs(pr or {}) do i[k]=v end
	return i
end
local function cr(p,r2) mk("UICorner",{CornerRadius=UDim.new(0,r2 or 6)}).Parent=p end

local lv={}
local function bds(a,b)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0,a),ColorSequenceKeypoint.new(0.25,b),
		ColorSequenceKeypoint.new(0.5,a),ColorSequenceKeypoint.new(0.75,b),
		ColorSequenceKeypoint.new(1,a),
	})
end

local function lvStr(p,th,br)
	local s=mk("UIStroke",{Thickness=th or 1,Color=WH,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
	s.Parent=p
	local g=mk("UIGradient",{Rotation=45,Color=bds(br and WH or SL,ST)})
	g.Parent=s; lv[#lv+1]=g; return s,g
end
local function lvTx(lb)
	local g=mk("UIGradient",{Color=bds(WH,SL)})
	g.Parent=lb; lv[#lv+1]=g; return g
end
local function tx(p,pr)
	local al=pr.Lv~=false; pr.Lv=nil
	pr.BackgroundTransparency=1; pr.TextColor3=pr.TextColor3 or WH
	local l=mk("TextLabel",pr); l.Parent=p
	if al then lvTx(l) end; return l
end

local old=pGui():FindFirstChild("tungtungHub")
if old then old:Destroy() end
local gui=mk("ScreenGui",{Name="tungtungHub",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true})
gui.Parent=pGui()

local W,H,HD=158,252,20
local win=mk("Frame",{Size=UDim2.fromOffset(W,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2),BackgroundColor3=BG,BorderSizePixel=0,ClipsDescendants=false})
win.Parent=gui; cr(win,18); lvStr(win,1,true)

local rot,tk2=0,0
local shinC=RS.Heartbeat:Connect(function(dt)
	tk2+=1; if tk2%2~=0 then return end
	rot=(rot+dt*72)%360
	for _,g in ipairs(lv) do
		if g.Parent then g.Rotation=g.Parent:IsA("UIStroke") and (45+rot)%360 or rot end
	end
end)

local hdr=mk("Frame",{Size=UDim2.new(1,-8,0,HD-4),Position=UDim2.fromOffset(4,4),BackgroundColor3=WH,BorderSizePixel=0})
hdr.Parent=win; cr(hdr,10)
do local g=mk("UIGradient",{Color=bds(WH,SL)}); g.Parent=hdr; lv[#lv+1]=g end
tx(hdr,{Size=UDim2.new(1,-44,1,0),Position=UDim2.fromOffset(6,0),Font=Enum.Font.GothamBlack,TextSize=10,TextColor3=Color3.new(0,0,0),TextXAlignment=Enum.TextXAlignment.Left,Text="Tungtung Hub",Lv=false})

local function hBtn(lb,of)
	local b=mk("TextButton",{Size=UDim2.fromOffset(17,14),Position=UDim2.new(1,of,0.5,-7),BackgroundColor3=BG,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=WH,Text=lb,AutoButtonColor=true})
	b.Parent=hdr; cr(b,7); lvStr(b,1,true); lvTx(b); return b
end
local btnMn=hBtn("-",-39)
local btnCl=hBtn("x",-20)

local bdy=mk("Frame",{Size=UDim2.new(1,-10,1,-(HD+8)),Position=UDim2.fromOffset(5,HD+4),BackgroundTransparency=1})
bdy.Parent=win

local lst=mk("ScrollingFrame",{Size=UDim2.new(1,0,1,-124),BackgroundColor3=BG,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=SL,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y})
lst.Parent=bdy; cr(lst,12); lvStr(lst,1,false)
mk("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder}).Parent=lst
mk("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,6)}).Parent=lst

local sLb=tx(bdy,{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-116),Font=Enum.Font.Gotham,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Text=_0xTXT.CHOOSE_PET})

local PUB={
	[_0xTXT.CHOOSE_PET]=true,[_0xTXT.FIND_EGG]=true,[_0xTXT.GO_EGG]=true,
	[_0xTXT.GRAB_EGG]=true,[_0xTXT.DELIVER_OK]=true,[_0xTXT.DELIVER_FAIL]=true,
	[_0xTXT.EGG_GONE]=true,[_0xTXT.CANT_REACH]=true,
	[_0xTXT.CANT_GRAB]=true,[_0xTXT.CANCELLING]=true,
	[_0xTXT.AUTO_OFF]=true,[_0xTXT.AUTO_ON]=true,
	[_0xTXT.BAY_OFF]=true,[_0xTXT.BAY_ON]=true,
	[_0xTXT.EGG_FAR]=true,[_0xTXT.EGG_NEAR]=true,
	[_0xTXT.GO_HOME]=true,[_0xTXT.DROP_EGG]=true,[_0xTXT.REGRAB_EGG]=true,
	[_0xTXT.CANT_REGRAB]=true,[_0xTXT.BAY_DONE]=true,[_0xTXT.BAY_FAIL]=true,
	[_0xTXT.BAY_LOST]=true,[_0xTXT.BAY_DROP]=true,
	[_0xTXT.BAY_LAND]=true,[_0xTXT.BAY_HOME]=true,
	[_0xTXT.BAY_FLYING]=true,[_0xTXT.WAIT_STABLE]=true,
}
setStatus=function(msg)
	msg=tostring(msg)
	if PUB[msg]
		or string.sub(msg,1,6)=="Chọn:"
		or string.sub(msg,1,5)=="Auto:"
		or string.sub(msg,1,9)=="Auto Bay:"
		or string.sub(msg,1,3)=="TP "
		or string.sub(msg,1,3)=="Bị "
		or string.sub(msg,1,4)=="Hạ c"
		or string.sub(msg,1,3)=="Lỗi"
	then
		sLb.Text=msg
	elseif st.Bz then
		sLb.Text=_0xTXT.DELIVERING_ALT
	elseif afh.Bz then
		sLb.Text=_0xTXT.FLYING_HOME_ALT
	end
end

local function bigBtn(lb,pos,sz)
	local b=mk("TextButton",{Size=sz,Position=pos,BackgroundColor3=BG,Font=Enum.Font.GothamBlack,TextSize=12,TextColor3=WH,Text=lb,AutoButtonColor=true})
	b.Parent=bdy; cr(b,17); lvStr(b,1,true); lvTx(b); return b
end

local btnR=bigBtn("Làm mới",UDim2.new(0,0,1,-98),UDim2.new(0.4,-2,0,30))
local btnS=bigBtn("Lấy",   UDim2.new(0.4,2,1,-98),UDim2.new(0.6,-2,0,30))

local btnA=mk("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,1,-64),BackgroundColor3=AOF,Font=Enum.Font.GothamBlack,TextSize=11,TextColor3=WH,Text="Auto Steal: TẮT",AutoButtonColor=true})
btnA.Parent=bdy; cr(btnA,17)
local aStr,_=lvStr(btnA,1,true)

local btnF=mk("TextButton",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,1,-32),BackgroundColor3=AFF,Font=Enum.Font.GothamBlack,TextSize=11,TextColor3=WH,Text="Auto Bay: TẮT",AutoButtonColor=true})
btnF.Parent=bdy; cr(btnF,17)
local fStr,_=lvStr(btnF,1,true)

local function updAuto()
	if au.On then
		btnA.Text="Auto Steal: BẬT"; btnA.BackgroundColor3=AON; aStr.Color=AON
	else
		btnA.Text="Auto Steal: TẮT"; btnA.BackgroundColor3=AOF; aStr.Color=WH
	end
end

local function updAfh()
	if afh.On then
		btnF.Text="Auto Bay: BẬT"; btnF.BackgroundColor3=AFN; fStr.Color=AFN
	else
		btnF.Text="Auto Bay: TẮT"; btnF.BackgroundColor3=AFF; fStr.Color=WH
	end
end

btnA.MouseButton1Click:Connect(function()
	if au.On then stopAuto(); setStatus(_0xTXT.AUTO_OFF)
	else startAuto(); setStatus(_0xTXT.AUTO_ON) end
	updAuto()
end)

btnF.MouseButton1Click:Connect(function()
	if afh.On then
		stopAfh(); setStatus(_0xTXT.BAY_OFF)
	else
		startAfh(); setStatus(_0xTXT.BAY_ON)
	end
	updAfh()
end)

local selUid=nil
local rows={}

local function setSel(uid)
	selUid=uid
	for rUid,row in pairs(rows) do
		local on=rUid==uid
		row.Sk.Thickness=on and 1.5 or 1
		row.Gd.Color=on and bds(WH,ST) or bds(ST,Color3.fromRGB(30,30,34))
	end
end

local function mkRow(inf,idx)
	local fr=mk("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=BG,LayoutOrder=idx,Text="",AutoButtonColor=true})
	fr.Parent=lst; cr(fr,10)
	local rSk,rGd=lvStr(fr,1,false)
	mk("ImageLabel",{Size=UDim2.fromOffset(22,22),Position=UDim2.fromOffset(3,3),BackgroundTransparency=1,Image=inf.Icon,ScaleType=Enum.ScaleType.Fit}).Parent=fr
	tx(fr,{Size=UDim2.new(1,-30,0,13),Position=UDim2.fromOffset(28,2),Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Text=inf.Name,TextColor3=RC[math.clamp(inf.Rar,1,#RC)] or WH})
	tx(fr,{Size=UDim2.new(1,-30,0,11),Position=UDim2.fromOffset(28,15),Font=Enum.Font.GothamMedium,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,Text=fmtMoney(inf.Val)})
	fr.MouseButton1Click:Connect(function() setSel(inf.Uid); setStatus(_0xTXT.CHOOSE..inf.Name) end)
	return {Fr=fr,Sk=rSk,Gd=rGd}
end

local function refresh()
	local ok,rc=pcall(snap)
	if not ok then return end
	local infos={}
	for _,rec in ipairs(rc) do infos[#infos+1]=desc(rec) end
	table.sort(infos,function(a,b) return a.Val>b.Val end)
	local live={}
	for _,inf in ipairs(infos) do live[inf.Uid]=inf end
	for uid,row in pairs(rows) do
		if not live[uid] then row.Fr:Destroy(); rows[uid]=nil end
	end
	for idx,inf in ipairs(infos) do
		if not rows[inf.Uid] then rows[inf.Uid]=mkRow(inf,idx)
		else rows[inf.Uid].Fr.LayoutOrder=idx end
	end
	for i=#lv,1,-1 do if not lv[i].Parent then table.remove(lv,i) end end
	if selUid and not live[selUid] then selUid=nil end
	setSel(selUid)
	if #infos==0 then setStatus(_0xTXT.CHOOSE_PET) end
end

btnR.MouseButton1Click:Connect(function() if not st.Bz then refresh() end end)

btnS.MouseButton1Click:Connect(function()
	if st.Bz then st.Cx=true; setStatus(_0xTXT.CANCELLING); return end
	if not selUid then setStatus(_0xTXT.CHOOSE_PET); return end
	stealDlv(selUid)
end)

task.spawn(function()
	while gui.Parent do
		task.wait(0.25)
		btnS.Text=st.Bz and "Huỷ" or "Lấy"
		updAuto(); updAfh()
	end
end)

do
	local dg,sP,sI
	hdr.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
			dg,sP,sI=true,win.Position,inp.Position
			inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dg=false end end)
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dg and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
			local dl=inp.Position-sI
			win.Position=UDim2.new(sP.X.Scale,sP.X.Offset+dl.X,sP.Y.Scale,sP.Y.Offset+dl.Y)
		end
	end)
end

local mini=false
btnMn.MouseButton1Click:Connect(function()
	mini=not mini; bdy.Visible=not mini
	win.Size=mini and UDim2.fromOffset(W,HD+4) or UDim2.fromOffset(W,H)
end)

btnCl.MouseButton1Click:Connect(function()
	st.Cx=true; afh.Cx=true; stopAuto(); stopAfh(); fpsOff(); shStop(); shinC:Disconnect(); gui:Destroy()
end)

refresh()

task.spawn(function()
	while gui.Parent do
		task.wait(3)
		if not st.Bz and not afh.Bz and bdy.Visible then refresh() end
	end
end)

shStart()
