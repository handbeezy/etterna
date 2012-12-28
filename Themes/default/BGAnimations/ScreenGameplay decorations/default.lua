local maxSegments = 150

local function CreateSegments(Player)
	local t = Def.ActorFrame { };
	local bars = Def.ActorFrame{ Name="CoverBars" };
	local bpmFrame = Def.ActorFrame{ Name="BPMFrame"; };
	local stopFrame = Def.ActorFrame{ Name="StopFrame"; };
	local delayFrame = Def.ActorFrame{ Name="DelayFrame"; };
	local warpFrame = Def.ActorFrame{ Name="WarpFrame"; };
	local fakeFrame = Def.ActorFrame{ Name="FakeFrame"; };
	local scrollFrame = Def.ActorFrame{ Name="ScrollFrame"; };
	local speedFrame = Def.ActorFrame{ Name="SpeedFrame"; };

	local fFrameWidth = 380;
	local fFrameHeight = 8;
	-- XXX: doesn't work in course mode -aj
	if not GAMESTATE:IsSideJoined( Player ) then
		return t
	elseif not GAMESTATE:IsCourseMode() then
	-- Straight rip off NCRX
		local song = GAMESTATE:GetCurrentSong();
		local steps = GAMESTATE:GetCurrentSteps( Player );
		if steps then
			local timingData = steps:GetTimingData();
			-- use the StepsSeconds, which will almost always be more proper
			-- than a file with ITG2r21 compatibility.
			if song then
				local songLen = song:MusicLengthSeconds();

				local firstBeatSecs = song:GetFirstSecond();
				local lastBeatSecs = song:GetLastSecond();

				local bpms = timingData:GetBPMsAndTimes();
				local stops = timingData:GetStops();
				local delays = timingData:GetDelays();
				local warps = timingData:GetWarps();
				local fakes = timingData:GetFakes();
				local scrolls = timingData:GetScrolls();
				local speeds = timingData:GetSpeeds();

				-- we don't want too many segments to be shown.
				local sumSegments = #bpms + #stops + #delays + #warps + #fakes + #scrolls + #speeds
				if sumSegments > maxSegments then
					return Def.ActorFrame{}
				end

				local function CreateLine(beat, secs, firstShadow, firstDiffuse, secondShadow, firstEffect, secondEffect)
					local beatTime = timingData:GetElapsedTimeFromBeat(beat);
					if beatTime < 0 then beatTime = 0; end;
					return Def.ActorFrame {
						Def.Quad {
							InitCommand=function(self)
								self:shadowlength(0);
								self:shadowcolor(color(firstShadow));
								-- set width
								self:zoomto(math.max((secs/songLen)*fFrameWidth, 1), fFrameHeight);
								-- find location
								self:x((scale(beatTime,firstBeatSecs,lastBeatSecs,-fFrameWidth/2,fFrameWidth/2)));
							end;
							OnCommand=function(self)
								self:diffuse(color(firstDiffuse));
							end;
						};
						--[[ there's a cool effect that can't happen because we don't fade out like we did before
						Def.Quad {
							InitCommand=function(self)
								--self:diffuse(HSVA(192,1,0.8,0.8));
								self:shadowlength(0);
								self:shadowcolor(color(secondShadow));
								-- set width
								self:zoomto(math.max((secs/songLen)*fFrameWidth, 1),fFrameHeight);
								-- find location
								self:x((scale(beatTime,firstBeatSecs,lastBeatSecs,-fFrameWidth/2,fFrameWidth/2)));
							end;
							OnCommand=function(self)
								self:diffusealpha(1);
								self:diffuseshift();
								self:effectcolor1(color(firstEffect));
								self:effectcolor2(color(secondEffect));
								self:effectclock('beat');
								self:effectperiod(1/8);
								--
								self:diffusealpha(0);
								self:sleep(beatTime+1);
								self:diffusealpha(1);
								self:linear(4);
								self:diffusealpha(0);
							end;
						};]]
					};
				end;

				for i=2,#bpms do
					local data = split("=",bpms[i]);
					bpmFrame[#bpmFrame+1] = CreateLine(data[1], 0,
						"#00808077", "#00808077", "#00808077", "#FF634777", "#FF000077");
				end;

				for i=1,#delays do
					local data = split("=",delays[i]);
					delayFrame[#delayFrame+1] = CreateLine(data[1], data[2],
						"#FFFF0077", "#FFFF0077", "#FFFF0077", "#00FF0077", "#FF000077");
				end;

				for i=1,#stops do
					local data = split("=",stops[i]);
					stopFrame[#stopFrame+1] = CreateLine(data[1], data[2],
						"#FFFFFF77", "#FFFFFF77", "#FFFFFF77", "#FFA50077", "#FF000077");
				end;

				for i=1,#scrolls do
					local data = split("=",scrolls[i]);
					scrollFrame[#scrollFrame+1] = CreateLine(data[1], 0,
						"#4169E177", "#4169E177", "#4169E177", "#0000FF77", "#FF000077");
				end;

				for i=1,#speeds do
					local data = split("=",speeds[i]);
					-- TODO: Turn beats into seconds for this calculation?
					speedFrame[#speedFrame+1] = CreateLine(data[1], 0,
						"#ADFF2F77", "#ADFF2F77", "#ADFF2F77", "#7CFC0077", "#FF000077");
				end;

				for i=1,#warps do
					local data = split("=",warps[i]);
					warpFrame[#warpFrame+1] = CreateLine(data[1], 0,
						"#CC00CC77", "#CC00CC77", "#CC00CC77", "#FF33CC77", "#FF000077");
				end;

				for i=1,#fakes do
					local data = split("=",fakes[i]);
					fakeFrame[#fakeFrame+1] = CreateLine(data[1], 0,
						"#BC8F8F77", "#BC8F8F77", "#BC8F8F77", "#F4A46077", "#FF000077");
				end;
			end;
			bars[#bars+1] = bpmFrame;
			bars[#bars+1] = scrollFrame;
			bars[#bars+1] = speedFrame;
			bars[#bars+1] = stopFrame;
			bars[#bars+1] = delayFrame;
			bars[#bars+1] = warpFrame;
			bars[#bars+1] = fakeFrame;
			t[#t+1] = bars;
			--addition here: increase performance a ton by only rendering once
			t[#t+1] = Def.ActorFrameTexture{Name="Target"}
			t[#t+1] = Def.Sprite{Name="Actual"}
			local FirstPass=true;
			local function Draw(self)
				kids=self:GetChildren();
				if FirstPass then
					kids.Target:setsize(fFrameWidth,fFrameHeight);
					kids.Target:EnableAlphaBuffer(true);
					kids.Target:Create();

					kids.Target:GetTexture():BeginRenderingTo();
					for k,v in pairs(kids) do
						if k~="Target" and k~="Actual" then
							v:Draw();
						end
					end
					kids.Target:GetTexture():FinishRenderingTo();
					
					kids.Actual:SetTexture(kids.Target:GetTexture());
					FirstPass=false;
				end
				kids.Actual:Draw();
			end
			t.InitCommand=function(self) self:SetDrawFunction(Draw); end
		end
	end
	return t
end
local t = LoadFallbackB()
t[#t+1] = StandardDecorationFromFileOptional("ScoreFrame","ScoreFrame");

local function songMeterScale(val) return scale(val,0,1,-380/2,380/2) end

for pn in ivalues(PlayerNumber) do
	local MetricsName = "SongMeterDisplay" .. PlayerNumberToString(pn);
	local songMeterDisplay = Def.ActorFrame{
		InitCommand=function(self) 
			self:player(pn); 
			self:name(MetricsName); 
			ActorUtil.LoadAllCommandsAndSetXY(self,Var "LoadingScreen"); 
		end;
		Def.Quad {
			InitCommand=cmd(zoomto,420,20);
			OnCommand=cmd(fadeleft,0.35;faderight,0.35;diffuse,Color.Black;diffusealpha,0.5);
		};
 		LoadActor( THEME:GetPathG( 'SongMeterDisplay', 'frame ' .. PlayerNumberToString(pn) ) ) .. {
			InitCommand=function(self)
				self:name('Frame'); 
				ActorUtil.LoadAllCommandsAndSetXY(self,MetricsName); 
			end;
		};
		Def.Quad {
			InitCommand=cmd(zoomto,2,8);
			OnCommand=cmd(x,songMeterScale(0.25);diffuse,PlayerColor(pn);diffusealpha,0.5);
		};
		Def.Quad {
			InitCommand=cmd(zoomto,2,8);
			OnCommand=cmd(x,songMeterScale(0.5);diffuse,PlayerColor(pn);diffusealpha,0.5);
		};
		Def.Quad {
			InitCommand=cmd(zoomto,2,8);
			OnCommand=cmd(x,songMeterScale(0.75);diffuse,PlayerColor(pn);diffusealpha,0.5);
		};
		Def.SongMeterDisplay {
			StreamWidth=THEME:GetMetric( MetricsName, 'StreamWidth' );
			Stream=LoadActor( THEME:GetPathG( 'SongMeterDisplay', 'stream ' .. PlayerNumberToString(pn) ) )..{
				InitCommand=cmd(diffuse,PlayerColor(pn);diffusealpha,0.5;blend,Blend.Add;);
			};
			Tip=LoadActor( THEME:GetPathG( 'SongMeterDisplay', 'tip ' .. PlayerNumberToString(pn) ) ) .. { InitCommand=cmd(visible,false); };
		};
	};
	if ThemePrefs.Get("TimingDisplay") == true then
		songMeterDisplay[#songMeterDisplay+1] = CreateSegments(pn);
	end
	t[#t+1] = songMeterDisplay
end;

for pn in ivalues(PlayerNumber) do
	local MetricsName = "ToastyDisplay" .. PlayerNumberToString(pn);
	t[#t+1] = LoadActor( THEME:GetPathG("Player", 'toasty'), pn ) .. {
		InitCommand=function(self) 
			self:player(pn); 
			self:name(MetricsName); 
			ActorUtil.LoadAllCommandsAndSetXY(self,Var "LoadingScreen"); 
		end;
	};
end;


t[#t+1] = StandardDecorationFromFileOptional("BPMDisplay","BPMDisplay");
t[#t+1] = StandardDecorationFromFileOptional("StageDisplay","StageDisplay");
t[#t+1] = StandardDecorationFromFileOptional("SongTitle","SongTitle");

do
	local w1PrefValue = PREFSMAN:GetPreference("AllowW1")
	local showingW1 = w1PrefValue == 'AllowW1_Everywhere' or (w1PrefValue=='AllowW1_CoursesOnly' and GAMESTATE:IsCourseMode())
	local pointLookup={
		['TapNoteScore_W1']=5,
		['TapNoteScore_W2']=4,
		['TapNoteScore_W3']=3,
		['TapNoteScore_W4']=2,
		['TapNoteScore_W5']=1,
		['TapNoteScore_HitMine']=-1}
	local ignorableTapNoteScores = {
		['TapNoteScore_HitMine']=true,
		['TapNoteScore_AvoidMine']=true,
		['TapNoteScore_CheckpointHit']=true,
		['TapNoteScore_CheckpointMiss']=true
	}
	setmetatable(pointLookup,{__index=0})
	t[#t+1] = {Class="Actor",
		JudgmentMessageCommand=function(self,params)
			if not showingW1 then
				local withinW1Windows = math.abs(params.Offset)<=PREFSMAN:GetPreference("TimingWindowW1")
				if withinW1Windows then params.TapNoteScore='TapNoteScore_W1' end
			end
			local PSS = STATSMAN:GetCurStageStats():GetPlayerStageStats(params.Player)
			local holdNoteInfo = params.HoldNoteScore == nil and nil or params.HoldNoteScore == 'HoldNoteScore_Held' and true or false
			PSS:SetScore(PSS:GetScore()+pointLookup[params.TapNoteScore]+(holdNoteInfo and 5 or 0))
			PSS:SetCurMaxScore(PSS:GetCurMaxScore()+(holdNoteInfo~=nil and 5 or 0)+(ignorableTapNoteScores[params.TapNoteScore] and 0 or 5))
		end
	}
end
return t
