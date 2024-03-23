comment "By: GamesByChris";
comment "Description: Spots units in 3D space and on the map when you look at them. Battlefield Style.";
comment "RUN SERVER SIDE IN PUBLIC ZEUS";

comment "
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\\\\\\\\\\\\\\\\	CLIENT SIDE CODE 	\\\\\\\\\\\\\\\\\\\\\
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
";
[[],{

	if (!hasInterface) exitWith {};
	if (isMultiplayer) then {waitUntil {sleep 0.1; getClientState isEqualTo "BRIEFING READ"};};
	if !(isNil "isSpotSystemAllowed") exitWith {};
	waitUntil {sleep 0.1; !((findDisplay 12 displayCtrl 51) isEqualTo controlNull)};

	comment "Show Hint to non-zeus players";
	[] spawn {
		waitUntil {sleep 0.1; alive player};
		if (player in (call BIS_fnc_listCuratorPlayers)) exitWith {};
		hint parseText ("Press "+"<t color='#ffb300'>"+(actionKeysNamesarray ["revealTarget",1,"Keyboard"] select 0)+"</t>"+" while looking at a target to spot them!");
	};

	if (!isNil "isSpotSystemAllowed") exitWith {};
	isSpotSystemAllowed = true;

	waitUntil {!isNil "ClientSpotUpdateRate"};

	SpotMaxDistanceUnitMarkerText3D = 10;
	SpotMaxCursorRangeUnitMarker = 0.02;
	SpotMinMapZoomUnitMarker = 0.035;
	SpotAllowAutoSpot = false;
	SpotTargetActionKey = "revealTarget";
	SpotIsPlayingVoice = false;

	disableMapIndicators [true,true,true,false];

	SPOT_fnc_RE_Server = {
		params["_arguments","_code"];
		_varName = ("SPOT"+str (round random 10000));

		TempCode = compile ("if(!isServer) exitWith{};_this call "+str _code+"; "+(_varName+" = nil;"));
		TempArgs = _arguments;

		call compile (_varName +" = [TempArgs,TempCode];
		publicVariable '"+_varName+"';

		[[], {
		("+_varName+" select 0) spawn ("+_varName+" select 1);
		}] remoteExec ['spawn',0];");
	};

	SPOT_fnc_spawnPlayMouthAnim = { 
		params ["_unit","_time"];

		comment "Make mouth move for some time";
		[_unit,true] remoteExec ["setRandomLip"]; 

		sleep _time; 

		[_unit,false] remoteExec ["setRandomLip"]; 
	};

	SPOT_fnc_getCardinalDirectionName = {
		params["_direction"];

		private _cardinals = ["north","northeast","east","southeast","south","southwest","west","northwest","north"];

		private _index = round (_direction * 8 / 360);

		_cardinals select _index
	}; 

	SPOT_fnc_spawnPlaySpotVoiceLine = {

		SpotIsPlayingVoice = true;

		[player,1.33] spawn SPOT_fnc_spawnPlayMouthAnim;

		private _speakerType = toLower speaker player;
		private _language = _speakerType select [6];
		private _cardinalName = [getDir player] call SPOT_fnc_getCardinalDirectionName;
		private _voiceFileName = format["%1_%2.ogg",_cardinalName,(selectRandom ["1","2"])];

		private _soundFilePath = switch (_language) do 
		{
			case "rus": {format ["A3\dubbing_radio_f_enoch\data\%1\%2\%3\010_Vehicles\%4",_language,_speakerType,"NORMALContact","veh_unknown_p.ogg"]};
			case "pol": {format ["A3\dubbing_radio_f_enoch\data\%1\%2\%3\010_Vehicles\%4",_language,_speakerType,"NORMALContact","veh_unknown_p.ogg"]};
			case "fre": {format ["A3\dubbing_radio_f_exp\data\%1\%2\RadioProtocol%3\%4\010_Vehicles\%5",_language,_speakerType,_language select [0,3],"NORMALContact","veh_unknown_p.ogg"]};
			case "engfre": {format ["A3\dubbing_radio_f_exp\data\%1\%2\RadioProtocol%3\%4\010_Vehicles\%5",_language,_speakerType,_language select [0,3],"NORMALContact","veh_unknown_p.ogg"]};
			case "chi": {format ["A3\dubbing_radio_f_exp\data\%1\%2\RadioProtocol%3\%4\010_Vehicles\%5",_language,_speakerType,_language select [0,3],"NORMALContact","veh_unknown_p.ogg"]};
			default {format ["A3\dubbing_radio_f\data\%1\%2\RadioProtocol%3\%4\010_Vehicles\%5",_language,_speakerType,_language select [0,3],"NORMALContact","veh_unknown_p.ogg"]};
		};

		private _soundID = playSound3D [_soundFilePath, player,false,getPosASL player,5,1,100];

		waitUntil { soundParams _soundID isEqualTo [] };

		private _soundFilePath = switch (_language) do 
		{
			case "rus": {format ["A3\dubbing_radio_f_enoch\data\%1\%2\%3\DirectionCompass1\%4",_language,_speakerType,"CombatEngage",_voiceFileName]};
			case "pol": {format ["A3\dubbing_radio_f_enoch\data\%1\%2\%3\DirectionCompass1\%4",_language,_speakerType,"CombatEngage",_voiceFileName]};
			case "fre": {format ["A3\dubbing_radio_f_exp\data\%1\%2\RadioProtocol%3\%4\DirectionCompass1\%5",_language,_speakerType,_language select [0,3],"CombatEngage",_voiceFileName]};
			case "engfre": {format ["A3\dubbing_radio_f_exp\data\%1\%2\RadioProtocol%3\%4\DirectionCompass1\%5",_language,_speakerType,_language select [0,3],"CombatEngage",_voiceFileName]};
			case "chi": {format ["A3\dubbing_radio_f_exp\data\%1\%2\RadioProtocol%3\%4\DirectionCompass1\%5",_language,_speakerType,_language select [0,3],"CombatEngage",_voiceFileName]};
			default {format ["A3\dubbing_radio_f\data\%1\%2\RadioProtocol%3\%4\DirectionCompass1\%5",_language,_speakerType,_language select [0,3],"CombatEngage",_voiceFileName]};
		};

		playSound3D [_soundFilePath, player,false,getPosASL player,5,1,100];

		sleep 20;

		SpotIsPlayingVoice = false;
	};

	SPOT_fnc_clientSpotTarget = {
		params["_target"];

		if (!(_target in AllSpottedTargets) && (_target isKindOf "AllVehicles") && (alive _target) && !(_target in allPlayers) && !(driver _target in allPlayers)) then 
		{
			AllSpottedTargets pushBack _target;
			[AllSpottedTargets,{AllSpottedTargets = _this;}] call SPOT_fnc_RE_Server;
			playSound "hint3";

			if !(cameraView isEqualTo "GUNNER") then {[player,"gestureGo"] remoteExec ["playActionNow",0];};
			if (!SpotIsPlayingVoice) then {[] spawn SPOT_fnc_spawnPlaySpotVoiceLine;};
		};
	};

	SPOT_fnc_getCursorTarget = {
		if (cursorTarget isEqualTo objNull) then {cursorObject} else {cursorTarget}
	};

	SpotGetInManEvent = player addEventHandler ["GetInMan", {
		params ["_unit", "_role", "_vehicle", "_turret"];
		AllSpottedTargets = (AllSpottedTargets - [_vehicle]);
		[AllSpottedTargets,{AllSpottedTargets = _this;}] call SPOT_fnc_RE_Server;
	}];

	comment "Update spotted targets the player is looking at on the server";
	if (SpotAllowAutoSpot) then {
		[] spawn {
			while {isSpotSystemAllowed} do 
			{
				[call SPOT_fnc_getCursorTarget] call SPOT_fnc_clientSpotTarget;
				uisleep ClientSpotUpdateRate;
			};
		};
	};

	comment "Update spotted targets when the player presses revealAction";
	SpotKeyDownEvent = findDisplay 46 displayAddEventHandler ["KeyDown", {
		private _pressed = ((_this select 1) isEqualTo ((actionKeys SpotTargetActionKey) select 0));
		if (_pressed && isSpotSystemAllowed) then {[call SPOT_fnc_getCursorTarget] call SPOT_fnc_clientSpotTarget;};
	}];

	comment "Render the spotted units in 3D space";
	SpotMissionDrawEvent = addMissionEventHandler ["Draw3D",{
		{
			comment "Check if visible in line of sight";
			_unit = driver vehicle _x;
			_vehicle = vehicle _x;
			if(_unit isEqualTo objNull) then {_unit = _vehicle;};
			_cansee = [player, "VIEW", _vehicle] checkVisibility [eyePos player, eyePos _vehicle];
			if (_cansee < 0.825) then {continue};
			_position = _x modelToWorldVisual (_x selectionPosition "head_axis");
			_position set[2,(_position select 2)+0.5];
			_distance = (player) distance (_position);
			_file = "\a3\ui_f\data\gui\rsc\RscDisplayEGSpectator\UnitIcon_ca.paa";
			_textSize = 0.02825;
			_text = getText(configfile >> "CfgVehicles" >> typeOf _x >> "displayName");
			if ((side _unit isEqualTo civilian) && (_unit isKindOf "Man")) then {_text = name _unit;};
			_imageSize = [4,4];
			_alpha = 1;
			_dif = ((getObjectViewDistance select 0)-_distance);
			_alpha = (_dif/(getObjectViewDistance select 0));
			if(vehicle _x isEqualTo cursorObject) then {_alpha = 1;}
			else {_text=""};
			if (_distance >= (getObjectViewDistance select 0)) then {_alpha = 0;};
			_color = switch (side group _x) do
			{
				case west: {[0,0.3,0.6,_alpha]};
				case east: {[0.5,0,0,_alpha]};
				case independent: {[0,0.5,0,_alpha]};
				case civilian: {[0.4,0,0.5,_alpha]};
				default {[0.7,0.6,0,_alpha]};
			};

			drawIcon3D [_file,_color,_position, _imageSize select 0,_imageSize select 1, 0,(""), 2, _textSize, "RobotoCondensedBold","center",false];
			drawIcon3D [_file,_color,_position, 0.5,0.5, 0,(_text), 2, _textSize, "RobotoCondensedBold","center",false];
		} forEach AllSpottedTargets;
	}];

	comment "Render the spotted units on the map";
	SpotMapDrawEvent = (findDisplay 12 displayCtrl 51) ctrlAddEventHandler ["Draw",{
		_vehicleList = [];
		{ 
			_pos = vehicle _x modelToWorldVisual [0,0,0];
			_unit = driver vehicle _x;
			if(_unit isEqualTo objNull) then {_unit = _x;};
			_dir = getDirVisual _x;
			_text = (name _x);
			_distance = player distance _x;
			_textSize = 0.04;
			_textSize2 = 0.05;

			_alpha = 1;
			_color = switch (side group _x) do
			{
				case west: {[0,0.3,0.6,_alpha]};
				case east: {[0.5,0,0,_alpha]};
				case independent: {[0,0.5,0,_alpha]};
				case civilian: {[0.4,0,0.5,_alpha]};
				default {[0.7,0.6,0,_alpha]};
			};
			
			comment "show name";
			_pos2D = (_this select 0) ctrlMapWorldToScreen _pos;
			_posCursor2D = getMousePosition;
			_dist = _pos2D distance2D _posCursor2D;
			_scale = ctrlMapScale (_this select 0);

			comment "check if man";
			if (_x isKindOf "Man") then 
			{
				if (vehicle _x != _x) exitWith {};

				comment "text";
				_text = getText(configfile >> "CfgVehicles" >> typeOf _x >> "displayName");
				if((_dist > SpotMaxCursorRangeUnitMarker)) then {_text = "";};
				if(_scale > SpotMinMapZoomUnitMarker) then {_textSize = _textSize2;};

				comment "text outline";
				_this select 0 drawIcon
				[
					"\A3\ui_f\data\Map\VehicleIcons\iconManVirtual_ca.paa",
					_color,
					_pos,
					20,
					20,
					_dir,
					_text,
					2,
					_textSize,
					"RobotoCondensedBold",
					"left"
				];

				comment "marker outline";
				_this select 0 drawIcon
				[
					"\A3\ui_f\data\Map\VehicleIcons\iconManVirtual_ca.paa",
					_color,
					_pos,
					20,
					20,
					_dir,
					_text,
					1,
					_textSize,
					"RobotoCondensedBold",
					"left"
				];
			}
			else
			{
				if (_x isKindOf "Man") exitWith {};

				_dir = getDirVisual _x;
				_pos = _x modelToWorldVisual [0,0,0];

				comment "file";
				_className = (typeOf _x);
				_file = getText (configfile >> "CfgVehicles" >> _className >> "icon");

				comment "text";
				_vehName = getText (configfile >> "CfgVehicles" >> _className >> "displayName");
				_text = _vehName;

				if((_dist > SpotMaxCursorRangeUnitMarker)) then {_text = "";};
				if(_scale > SpotMinMapZoomUnitMarker) then {_textSize = _textSize2;};
				
				comment "text outline";
				_this select 0 drawIcon
				[
					_file,
					_color,
					_pos,
					20,
					20,
					_dir,
					_text,
					2,
					_textSize,
					"RobotoCondensedBold",
					"left"
				];

				comment "marker outline";
				_this select 0 drawIcon
				[
					_file,
					_color,
					_pos,
					20,
					20,
					_dir,
					_text,
					1,
					_textSize,
					"RobotoCondensedBold",
					"left"
				];
			};
		} foreach AllSpottedTargets;
	}];
}] remoteExec ["Spawn",0,"JIP_ID_SPOTSYSTEM"];

comment "
/////////////////////////////////////////////////////////////
////////////////	SERVER SIDE CODE 	/////////////////////
/////////////////////////////////////////////////////////////
";
[[],{
	if !(isNil "isSpotSystemAllowedServer") exitWith {};
	isSpotSystemAllowedServer = true;
	ServerSpotUpdateRate = 1;
	ClientSpotUpdateRate = 1;
	MaxSpotTime = 60;
	AllSpottedTargets = [];
	
	publicVariable "ServerSpotUpdateRate";
	publicVariable "ClientSpotUpdateRate";
	publicVariable "AllSpottedTargets";

	while {isSpotSystemAllowedServer} do 
	{
		comment "Remove dead and missing units and update array across the network";
		AllSpottedTargets = (AllSpottedTargets - allDead - [objNull]);

		{
			_time = _x getVariable "SpotTime";
			if (isNil "_time") then {_time = MaxSpotTime};
			_time = (_time-1);
			_x setVariable ["SpotTime",_time];

			if (_time <= 0) then 
			{
				AllSpottedTargets = (AllSpottedTargets - [_x]);
				_x setVariable ["SpotTime",nil];
			};
		} foreach AllSpottedTargets;

		publicVariable "AllSpottedTargets";

		uisleep ServerSpotUpdateRate;
	};
}] remoteExec ["Spawn",2];

comment "
// disable
// run on server

[[],{}] remoteExec ['Spawn',0,'JIP_ID_SPOTSYSTEM'];
isSpotSystemAllowedServer = nil;

{
	isSpotSystemAllowed = nil;
	removeMissionEventHandler ['Draw3D',SpotMissionDrawEvent];
	(findDisplay 12 displayCtrl 51) ctrlRemoveEventHandler ['Draw',SpotMapDrawEvent];
	(findDisplay 46) displayRemoveEventHandler ['KeyDown',SpotKeyDownEvent];
	player removeEventHandler ['GetInMan',SpotGetInManEvent];
} remoteExec ['BIS_fnc_call',0];

";