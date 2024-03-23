{
	[] spawn
	{
		if(!hasInterface) exitWith {};
		if (!isNil "TeamNameTagEvent") exitWith {};
		if(isMultiplayer) then {waitUntil{getClientState isEqualTo "BRIEFING READ"};};
		sleep 1;
		disableMapIndicators [true,false,false,false];
		
		TNTMaxDistanceUnitMarker3D = 20;
		TNTMaxDistanceUnitMarkerText3D = 7.5;
		
		TeamNameTagEvent = addMissionEventHandler ["Draw3D", {
			private _vehicleList = [];
			{
				if(((side group _x) isEqualTo (side group player)) && (_x != player)) then
				{
					_position = _x modelToWorldVisual (_x selectionPosition "head_axis");
					_position set[2,(_position select 2)+0.5];
					_distance = (player) distance (_position);
					_driver = if (driver vehicle _x isEqualTo objNull) then {effectiveCommander vehicle _x} else {driver vehicle _x};
					_textSize = 0.02825;
					_text = name _x;
					_imageSize = [0.5,0.5];
		
					_dif = (TNTMaxDistanceUnitMarker3D-_distance);
					_alpha = (_dif/TNTMaxDistanceUnitMarker3D);
					if(vehicle _x == cursorTarget) then {_alpha = 1;};

					_color = switch (side group player) do
					{
						case west: {[0,0.3,0.6,_alpha]};
						case east: {[0.5,0,0,_alpha]};
						case independent: {[0,0.5,0,_alpha]};
						case civilian: {[0.4,0,0.5,_alpha]};
						default {[1,1,1,_alpha]};
					};
					
					if((group player) isEqualTo (group _x)) then 
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
		
					_rankPath = switch (rank _x) do 
					{
						case "COLONEL": {"\a3\ui_f\data\GUI\cfg\Ranks\colonel_pr.paa"};
						case "MAJOR": {"\a3\ui_f\data\GUI\cfg\Ranks\major_pr.paa"};
						case "CAPTAIN": {"\a3\ui_f\data\GUI\cfg\Ranks\captain_pr.paa"};
						case "LIEUTENANT": {"\a3\ui_f\data\GUI\cfg\Ranks\lieutenant_pr.paa"};
						case "SERGEANT": {"\a3\ui_f\data\GUI\cfg\Ranks\sergeant_pr.paa"};
						case "CORPORAL": {"\a3\ui_f\data\GUI\cfg\Ranks\corporal_pr.paa"};
						case "PRIVATE": {"\a3\ui_f\data\GUI\cfg\Ranks\private_pr.paa"};
						default {"\a3\ui_f\data\GUI\cfg\Ranks\private_pr.paa"};
					};

					if((rank _x) isEqualTo "COLONEL") then {_imageSize = [0.75,0.75]; _color = [1,1,1,1];};

					comment "Dead";
					_deadIcon = "\A3\ui_f\data\igui\cfg\revive\overlayicons\d100_ca.paa";
					_deadColor = [0.25,0.25,0.25,0.75]; 

					comment "Incap";
					_incapIcon = "\A3\ui_f\data\igui\cfg\revive\overlayicons\u100_ca.paa";
					_incapColor = [0.75,0.15,0.15,1];

					comment "Mic";
					_micIcon = "\a3\ui_f\data\IGUI\RscIngameUI\RscDisplayVoiceChat\microphone_ca.paa";

					if (lifeState _driver isEqualTo "INCAPACITATED" && damage _driver > 0.4) then 
					{
						_color = _incapColor;
						_rankPath = _incapIcon;
					};

					if (!alive _driver) then 
					{
						_color = _deadColor;
						_rankPath = _deadIcon;
					};

					if !(getPlayerChannel _driver isEqualTo -1) then 
					{
						_rankPath = _micIcon;
					};

					if (vehicle _x != _x) then
					{
						if !((vehicle _x) in _vehicleList) then 
						{
							_vehicleList pushback vehicle _x;

							if (vehicle _x isEqualTo vehicle player) exitWith {};

							_position = (vehicle _x) modelToWorldVisual [0,0,2];

							_className = (typeOf vehicle _x);
							_file = getText (configfile >> "CfgVehicles" >> _className >> "icon");
							_rankPath = _file;

							if(_driver isEqualTo objNull) then {_driver = _x;};

							_vehName = getText (configfile >> "CfgVehicles" >> _className >> "displayName");
							_text = _vehName;

							_count = count crew vehicle _x;
							if(_count > 1) then 
							{
								_text = ((name _driver) + " + " + (str (_count-1)) + " more");
							}
							else
							{
								_text = (name _driver);
							};

							_imageSize = [0.65,0.65];

							if((_distance > TNTMaxDistanceUnitMarkerText3D) && (vehicle _x != cursorTarget) && ((group driver vehicle _x) != (group player))) then {_text = "";};

							if ((_distance < TNTMaxDistanceUnitMarker3D) || (vehicle _x == cursorTarget)) then
							{
								drawIcon3D [_rankPath,_color,_position, _imageSize select 0,_imageSize select 1, 0,(_text), 2, _textSize, "RobotoCondensedBold","center",false];
							};
						};
					};
					
					if !((vehicle _x) in _vehicleList) then 
					{
						if((_distance > TNTMaxDistanceUnitMarkerText3D) && (vehicle _x != cursorTarget) && ((group driver vehicle _x) != (group player))) then {_text = "";};

						if ((_distance < TNTMaxDistanceUnitMarker3D) || (vehicle _x == cursorTarget)) then
						{
							drawIcon3D [_rankPath,_color,_position, _imageSize select 0,_imageSize select 1, 0,(_text), 2, _textSize, "RobotoCondensedBold","center",false];
						};
					};
				};
			} foreach (if (count allPlayers isEqualTo 1) then {allUnits+allDeadMen} else {allPlayers});
		}];
	};
} remoteExec ["BIS_fnc_call",0,"TeamNameTag"];


comment "
// run on server

{	
	removeMissionEventHandler ['Draw3D', TeamNameTagEvent];
	TeamNameTagEvent = nil;
} remoteExec ['bis_fnc_call', 0];

{} remoteExec ['BIS_fnc_call',0,'TeamNameTag'];
";