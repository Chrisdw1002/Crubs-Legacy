SLT_fnc_RE_Server = {
	params["_arguments","_code"];
	_varName = ("SLT"+str (round random 10000));

	TempCode = compile ("if(!isServer) exitWith{};_this call "+str _code+"; "+(_varName+" = nil;"));
	TempArgs = _arguments;

	call compile (_varName +" = [TempArgs,TempCode];
	publicVariable '"+_varName+"';

	[[], {
	("+_varName+" select 0) spawn ("+_varName+" select 1);
	}] remoteExec ['spawn',2];");
};

with uiNamespace do {SLTScriptDisplayName = "Team Map Icons";};

SLT_fnc_enableScript = {
	{
		[] spawn 
		{
			if(!hasInterface) exitWith {};
			if (!isNil "TeamMapEvent") exitWith {};
			if(isMultiplayer) then {waitUntil{getClientState isEqualTo "BRIEFING READ"};};
			sleep 1;
			waitUntil {sleep 0.1; !((findDisplay 12 displayCtrl 51) isEqualTo controlNull)};
			disableMapIndicators [true,false,false,false];

			with uiNamespace do 
			{
				TMIMaxCursorRangeUnitMarker = 0.02;
				TMIMinMapZoomUnitMarker = 0.0010;

				comment "[location,direction,isOnFoot,lifetime]";
				TMIAllMapTrails = [];
				TMITrailLifetime = 30;
				TMITrailDistance = 10;
				TMIMaxAlpha = 0.5;
				TMITrailSize = 1;

				TMI_fnc_mapTrailTick = {

					comment "Add new trails";
					private _unit = player;

					private _lastTrailLocation = _unit getVariable "TMILastTrailLocation";

					if (isNil "_lastTrailLocation") then 
					{
						_unit setVariable ["TMILastTrailLocation",(_unit modelToWorldVisual [0,0,0])];
						_lastTrailLocation = (_unit modelToWorldVisual [0,0,0]);
					};

					private _currentLocation = (_unit modelToWorldVisual [0,0,0]);
					private _dist = _lastTrailLocation distance2D _currentLocation;

					if (_dist >= TMITrailDistance) then 
					{
						TMIAllMapTrails pushBack [_lastTrailLocation,getdir _unit,vehicle _unit isEqualTo _unit,TMITrailLifetime];
						_unit setVariable ["TMILastTrailLocation",_currentLocation];
					};

					private _updatedTrails = TMIAllMapTrails;
					{
						private _location = _x select 0;
						private _direction = _x select 1;
						private _isOnFoot = _x select 2;
						private _timeLeft = _x select 3;

						comment "Update trails data";
						_updatedTrails set [_forEachIndex,[_location,_direction,_isOnFoot,_timeleft-diag_deltaTime]];
						if (_timeLeft <= 0) then {_updatedTrails deleteAt _forEachIndex;};
					} foreach TMIAllMapTrails;

					TMIAllMapTrails = _updatedTrails;
				};

				TMI_fnc_mapTrailDraw = {
					{
						private _location = _x select 0;
						private _direction = _x select 1;
						private _isOnFoot = _x select 2;
						private _timeLeft = _x select 3;
						private _alpha = linearConversion [0, 1, (_timeLeft/TMITrailLifetime), 0, TMIMaxAlpha, true];
						private _color = [1,1,1,_alpha];
						private _scale = 6.4 * worldSize / 8192 * ctrlMapScale (findDisplay 12 displayCtrl 51);
						private _size = (TMITrailSize) / _scale;
						private _iconFile = if (_isOnFoot) 
						then {"\a3\ui_f\data\igui\cfg\simpletasks\types\walk_ca.paa"} 
						else {"\a3\ui_f_curator\data\cfgcurator\entity_selected_ca.paa"};

						(findDisplay 12 displayCtrl 51) drawIcon
						[
							_iconFile,
							_color,
							_location,
							_size,
							_size,
							_direction-10,
							"",
							0
						];
					} foreach TMIAllMapTrails;
				};
			};

			TeamMapMissionEvent = addMissionEventHandler ["EachFrame",{
				with uiNamespace do {call TMI_fnc_mapTrailTick;};
			}];
			
			TeamMapEvent = (findDisplay 12 displayCtrl 51) ctrlAddEventHandler ["Draw", 
			{
				_vehicleList = [];
				{ 
					if((side group _x) isEqualTo (side group player)) then
					{
						_pos = _x modelToWorldVisual [0,0,0];
						_driver = if (driver vehicle _x isEqualTo objNull) then {effectiveCommander vehicle _x} else {driver vehicle _x};
						_dir = getDir _x;
						_text = (name _x);
						_textSize = 0.05;
						_font = "RobotoCondensedBold";
						_distance = player distance _x;
						_iconFile = "\A3\ui_f\data\Map\VehicleIcons\iconManVirtual_ca.paa";
						_iconSize = 21;
						_vehicleIconSize = 21;

						comment "Dead";
						_deadIcon = "\A3\ui_f\data\igui\cfg\revive\overlayicons\d100_ca.paa";
						_deadColor = [0.25,0.25,0.25,0.75]; 

						comment "Incap";
						_incapIcon = "\A3\ui_f\data\igui\cfg\revive\overlayicons\u100_ca.paa";
						_incapColor = [0.75,0.15,0.15,1];

						comment "Mic";
						_micIcon = "\a3\ui_f\data\IGUI\RscIngameUI\RscDisplayVoiceChat\microphone_ca.paa";
						
						_alpha = 1;
						_color = switch (side group _x) do
						{
							case west: {[0,0.3,0.6,_alpha]};
							case east: {[0.5,0,0,_alpha]};
							case independent: {[0,0.5,0,_alpha]};
							case civilian: {[0.4,0,0.5,_alpha]};
							default {[1,1,1,_alpha]};
						};
						
						if((group player) isEqualTo (group _driver)) then 
						{
							_color = switch (side group _x) do
							{
								case west: {[0,0.45,1,_alpha]};
								case east: {[0.8,0.35,0,_alpha]};
								case independent: {[0.34,0.75,0,_alpha]};
								case civilian: {[0.7,0,0.75,_alpha]};
								default {[1,1,1,_alpha]};
							};
						};

						if (lifeState _driver isEqualTo "INCAPACITATED" && damage _driver > 0.4) then 
						{
							_color = _incapColor;
							_iconFile = _incapIcon;
							_dir = 0;
							_iconSize = 25;
						};

						if (!alive _driver) then 
						{
							_color = _deadColor;
							_iconFile = _deadIcon;
							_dir = 0;
							_iconSize = 25;
						};

						if !(getPlayerChannel _driver isEqualTo -1) then 
						{
							_iconFile = _micIcon;
							_dir = 0;
						};
						
						_pos2D = (_this select 0) ctrlMapWorldToScreen _pos;
						_posCursor2D = getMousePosition;
						_dist = _pos2D distance2D _posCursor2D;
						_scale = ctrlMapScale (_this select 0);
			
						if (vehicle _x == _x) then 
						{
							if((_scale > (uiNamespace getVariable "TMIMinMapZoomUnitMarker")) && (_dist > (uiNamespace getVariable "TMIMaxCursorRangeUnitMarker"))) then {_text = "";};
			
							_this select 0 drawIcon
							[
								_iconFile,
								_color,
								_pos,
								_iconSize,
								_iconSize,
								_dir,
								_text,
								2,
								_textSize,
								_font,
								"left"
							];
			
							_this select 0 drawIcon
							[
								_iconFile,
								_color,
								_pos,
								_iconSize,
								_iconSize,
								_dir,
								_text,
								1,
								_textSize,
								_font,
								"left"
							];
						}
						else 	
						{
							if !((vehicle _x) in _vehicleList) then 
							{
								_vehicleList pushback vehicle _x;
			
								_dir = getDir vehicle _x;
			
								_className = (typeOf vehicle _x);
								_iconFile = getText (configfile >> "CfgVehicles" >> _className >> "icon");
			
								_vehName = getText (configfile >> "CfgVehicles" >> _className >> "displayName");
								_text = _vehName;
			
								_text2 = "";
								_count = count crew vehicle _x;
								if(_count > 1) then 
								{
									_text2 = ((name _driver) + " + " + (str (_count-1)) + " more");
								}
								else
								{
									_text2 = (name _driver);
								};

								if((_scale > (uiNamespace getVariable "TMIMinMapZoomUnitMarker")) && (_dist > (uiNamespace getVariable "TMIMaxCursorRangeUnitMarker"))) then {_text = ""; _text2 = "";};
								
								_this select 0 drawIcon
								[
									_iconFile,
									_color,
									_pos,
									_vehicleIconSize,
									_vehicleIconSize,
									_dir,
									_text,
									2,
									_textSize,
									_font,
									"left"
								];

								_this select 0 drawIcon
								[
									_iconFile,
									_color,
									_pos,
									_vehicleIconSize,
									_vehicleIconSize,
									_dir,
									_text,
									1,
									_textSize,
									_font,
									"left"
								];
			
								_this select 0 drawIcon
								[
									_iconFile,
									_color,
									_pos,
									_vehicleIconSize,
									_vehicleIconSize,
									_dir,
									_text2,
									1,
									_textSize,
									_font,
									"right"
								];
			
								_this select 0 drawIcon
								[
									_iconFile,
									_color,
									_pos,
									_vehicleIconSize,
									_vehicleIconSize,
									_dir,
									_text2,
									2,
									_textSize,
									_font,
									"right"
								];
							};
						};
			
						if(_x == player) then 
						{
							_color set[3,0.5];
							_draw = {
								_this select 0 drawIcon
								[
									"\a3\ui_f\data\Map\groupIcons\selector_selected_ca.paa",
									_color,
									_pos,
									32,
									32,
									_dir,
									"",
									0,
									0.05,
									_font,
									"left"
								];
							};
							[_this select 0] call _draw;
							[_this select 0] call _draw;
						};
					};
				} foreach (if (count allPlayers isEqualTo 1) then {allUnits+allDeadMen} else {allPlayers});
				
				with uiNamespace do {call TMI_fnc_mapTrailDraw;};
			}];
		};
	} remoteExec ["BIS_fnc_call",0,"TeamMapIcons"];
};

SLT_fnc_disableScript = {
	{} remoteExec ['BIS_fnc_call',0,'TeamMapIcons'];
	{
		(findDisplay 12 displayCtrl 51) ctrlRemoveEventHandler ['Draw',TeamMapEvent];
		removeMissionEventHandler ['EachFrame',TeamMapMissionEvent];
		TeamMapEvent = nil;
		TeamMapMissionEvent = nil;
	} remoteExec ['BIS_fnc_call',0];
};

SLT_fnc_init = {
	params[["_useToggleOptions",true]];

	with uiNamespace do {
		
		createDialog "RscDisplayEmpty";
		private _display = findDisplay -1;
		{_x ctrlShow false;} foreach allControls _display;

		private _ctrlHeader = _display ctrlCreate ["RscStructuredText",-1];
		_ctrlHeader ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.445 * safezoneH + safezoneY,0.20625 * safezoneW,0.022 * safezoneH];
		_ctrlHeader ctrlSetBackgroundColor [1,0.7,0,0.66];
		_ctrlHeader ctrlSetStructuredText parseText ("<t size='0.85' font='PuristaMedium'>"+toUpper SLTScriptDisplayName+"</t>");
		_ctrlHeader ctrlCommit 0;

		private _ctrlBorder = _display ctrlCreate ["RscPicture",-1];
		_ctrlBorder ctrlSetPosition [0.396875 * safezoneW + safezoneX,0.467 * safezoneH + safezoneY,0.20625 * safezoneW,0.077 * safezoneH];
		_ctrlBorder ctrlSetText "#(rgb,1,1,1)color(1,1,1,1)";
		_ctrlBorder ctrlSetTextColor [0,0,0,0.5];
		_ctrlBorder ctrlCommit 0;

		private _ctrlBackground = _display ctrlCreate ["RscPicture",-1];
		_ctrlBackground ctrlSetPosition [0.402031 * safezoneW + safezoneX,0.478 * safezoneH + safezoneY,0.195937 * safezoneW,0.055 * safezoneH];
		_ctrlBackground ctrlSetText "#(rgb,1,1,1)color(1,1,1,1)";
		_ctrlBackground ctrlSetTextColor [0.1,0.1,0.1,0.75];
		_ctrlBackground ctrlCommit 0;

		SLTEnableButton = _display ctrlCreate ["RscButtonMenu",-1];
		SLTEnableButton ctrlSetPosition [0.407187 * safezoneW + safezoneX,0.489 * safezoneH + safezoneY,0.0928125 * safezoneW,0.033 * safezoneH];
		SLTEnableButton ctrlSetText "ENABLE";
		SLTEnableButton ctrlCommit 0;
		SLTEnableButton ctrlAddEventHandler ["ButtonClick",{
			[[],missionNamespace getVariable "SLT_fnc_enableScript"] call (missionNamespace getVariable "SLT_fnc_RE_Server");
			closeDialog 0;
		}];

		SLTDisableButton = _display ctrlCreate ["RscButtonMenu",-1];
		SLTDisableButton ctrlSetPosition [0.5 * safezoneW + safezoneX,0.489 * safezoneH + safezoneY,0.0928125 * safezoneW,0.033 * safezoneH];
		SLTDisableButton ctrlSetText "DISABLE";
		SLTDisableButton ctrlCommit 0;
		SLTDisableButton ctrlAddEventHandler ["ButtonClick",{
			[[],missionNamespace getVariable "SLT_fnc_disableScript"] call (missionNamespace getVariable "SLT_fnc_RE_Server");
			closeDialog 0;
		}];

		if (!_useToggleOptions) then 
		{
			SLTEnableButton ctrlSetText "ARE YOU SURE?";
			SLTEnableButton ctrlSetTooltip "This script cannot be disabled!";
			SLTEnableButton ctrlCommit 0;

			SLTDisableButton ctrlSetText "CANCEL";
			SLTDisableButton ctrlCommit 0;
		};
	};
	deleteVehicle this;
};

if (time < 1) then 
{
	[] spawn SLT_fnc_enableScript;
}
else 
{
	[true] call SLT_fnc_init;
};