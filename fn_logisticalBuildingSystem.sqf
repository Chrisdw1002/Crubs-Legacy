comment "Made by: GamesByChris (Capt. Chris)";
comment "

Execute Server Side!

Description: 
- Use vehicles or containers to hold Construction Supplies
- Vehicle Ammo Boxes are also supplies
- 'Construction Supplies' are a point system used to spawn new assets and place them
- An Object that contains Construction Supplies is called a 'Construction Unit'
- Construction Units hold a limited amount of Construction Supplies
- Assets can only be placed within proximity to a Construction Unit
- When Construction Units are close together, the supplies available to the builder is combined
- Construction Supplies eventually run out
- Bringing more construction supplies allow bigger bases to be built

Basics:
- Open Container on truck
- Build Construction Unit
- Stand near Construction Unit
- Open Terminal
- Choose asset from asset tree
- Click button to place
- Look where you want the asset placed
- Left mouse button to place
";

PUB_fnc_RE_Server = {
	params["_arguments","_code"];
	_varName = ("PUB"+str (round random 10000));

	TempCode = compile ("if(!isServer) exitWith{};_this call "+str _code+"; "+(_varName+" = nil;"));
	TempArgs = _arguments;

	call compile (_varName +" = [TempArgs,TempCode];
	publicVariable '"+_varName+"';

	[[], {
	("+_varName+" select 0) spawn ("+_varName+" select 1);
	}] remoteExec ['spawn',0];");
};

[[],{
	LBS_fnc_RE = {
		params["_arguments","_code"];
		_varName = ("LBS"+str (round random 10000));

		TempCode = compile ("_this call "+str _code+"; "+(_varName+" = nil;"));
		TempArgs = _arguments;

		call compile (_varName +" = [TempArgs,TempCode];
		publicVariable '"+_varName+"';

		[[], {
		("+_varName+" select 0) spawn ("+_varName+" select 1);
		}] remoteExec ['spawn',0];");
	};
	[[],{if (!isServer) exitWith {};publicVariable "LBS_fnc_RE";}] call LBS_fnc_RE;

	comment "Client Code";
	[[],{
		if (!isServer) exitWith {};
	[[],{
		if(!hasInterface) exitWith {};
		if(isMultiplayer) then {waitUntil{getClientState isEqualTo "BRIEFING READ"};};
		sleep 1;
		if !(isNil "isLBSAllowed") exitWith {systemChat "Logistical Building System already running...";};

		LBS_fnc_RE_Server = {
			params["_arguments","_code"];
			_varName = ("LBS"+str (round random 10000));

			TempCode = compile ("if(!isServer) exitWith{};_this call "+str _code+"; "+(_varName+" = nil;"));
			TempArgs = _arguments;

			call compile (_varName +" = [TempArgs,TempCode];
			publicVariable '"+_varName+"';

			[[], {
			("+_varName+" select 0) spawn ("+_varName+" select 1);
			}] remoteExec ['spawn',0];");
		};
		
		waitUntil {!isNil "LBS_fnc_RE"};
		waitUntil {!isNil "LBSMaxDistanceSuppliesUpgradeTiers"};
		waitUntil {!isNil "LBSMaxDistancePlacingUpgradeTiers"};
		waitUntil {!isNil "LBSMaxPlaceDistance"};
		waitUntil {!isNil "LBSConstructionUnitCost"};
		waitUntil {!isNil "LBSAllConstructionUnitClassNames"};
		waitUntil {!isNil "LBSAllConstructionSuppliesDictionary"};
		waitUntil {!isNil "LBSAllConstructionSuppliesClassNames"};
		waitUntil {!isNil "LBSAllAssetsDictionary"};
		waitUntil {!isNil "LBS_fnc_findSupplyObjectData"};
		waitUntil {!isNil "LBS_fnc_findAssetObjectData"};
		waitUntil {!isNil "LBS_fnc_getClosestObjectOfClassNames"};
		waitUntil {!isNil "LBS_fnc_spawnConstructionSoundEffects"};
		waitUntil {!isNil "LBS_fnc_spawnConstructionParticleEffects"};
		waitUntil {!isNil "LBS_fnc_spawnBuildAssetAnimation"};
		waitUntil {!isNil "LBS_fnc_systemMessage"};

		comment "Build Mode Controls";
		LBSOpenTerminalKey = 219;
		LBSRotateRightKey = 18;
		LBSRotateLeftKey = 16;

		comment "UI Settings";
		with uiNamespace do 
		{
			LBSMaxDistanceIcon3D = 100;
			LBS3DLoadAngleSpeed = 200;
			LBSLast3DLoadingAngle = 0;
		};

		comment "Important Client Variables";
		isLBSAllowed = true;
		LBSNearbyLocalSupplyObjects = [];
		LBSNearbyLocalConstructionUnits = [];
		LBSRotateRightHeld = false;
		LBSRotateLeftHeld = false;
		LBSPlaceModeEnabled = false;
		LBSHUDEnabled = false;
		LBSPlaceRotationSpeed = 100;
		LBSPlaceMaxDistanceFromPlayer = 20;
		LBSMaxDistanceNearbyCrates = 15;
		LBSPlaceMaxDistanceFromPlayerNoConstructionUnit = 7.5;
		LBSLocalPreviewObject = objNull;

		comment "List of Scripted Events";
		[missionNameSpace, "LBSAssetPlaceStarted",{["PLACEMENT MODE STARTED",5,46] call LBS_fnc_systemMessage;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSAssetPlaceCancelled",{["PLACEMENT MODE CANCELLED",5,46] call LBS_fnc_systemMessage;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSAssetBuildStarted",{["ASSET BUILD STARTED",5,46] call LBS_fnc_systemMessage;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSAssetBuildDone",{["ASSET BUILD COMPLETED",5,46] call LBS_fnc_systemMessage;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSAssetBuildCancelled",{["ASSET BUILD CANCELLED",5,46] call LBS_fnc_systemMessage;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSHUDEnabled",{["BUILD MODE ENABLED",1,46] call LBS_fnc_systemMessage;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSHUDDisabled",{["BUILD MODE DISABLED",1,46] call LBS_fnc_systemMessage;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSTerminalOpened",{}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSTerminalClosed",{showChat true;}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSLeftMouseClick",{}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSRightMouseClick",{}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSSystemMessageAdded",{}] call BIS_fnc_addScriptedEventHandler;
		[missionNameSpace, "LBSSystemMessageRemoved",{}] call BIS_fnc_addScriptedEventHandler;

		LBS_fnc_startMainLoop = {
			LBSMainLoopScriptHandle = [] spawn {
				while {isLBSAllowed} do 
				{
					comment "Update Nearby Supplies to player";
					LBSNearbyLocalSupplyObjects = [ASLToAGL(getPosASL player),LBSAllConstructionSuppliesClassNames,["AllVehicles","ReammoBox_F","Cargo_base_F"],uiNamespace getVariable "LBSMaxDistanceIcon3D"] call LBS_fnc_getNearFilteredObjects;
					LBSNearbyLocalConstructionUnits = [ASLToAGL(getPosASL player),LBSAllConstructionUnitClassNames,["AllVehicles","ReammoBox_F","Cargo_base_F"],uiNamespace getVariable "LBSMaxDistanceIcon3D"] call LBS_fnc_getNearFilteredObjects;

					{
						_hasAction = _x getVariable "LBShasAction";
						_isCrate = _x getVariable "LBSisCrate";
						if(isNil "_hasAction" && !isNil "_isCrate") then 
						{
							if (!_isCrate) then 
							{
								_x setVariable ["LBShasAction",true];
								[_x] call LBS_fnc_addActionToSupply;
							}
						};
					} foreach LBSNearbyLocalSupplyObjects;

					{
						_hasAction = _x getVariable "LBShasAction";
						if(isNil "_hasAction") then 
						{
							_x setVariable ["LBShasAction",true];
							[_x] call LBS_fnc_addActionToConstructionUnit;
						};
					} foreach LBSNearbyLocalConstructionUnits;
					sleep 1;
				};
			};
		};

		LBS_fnc_getNearFilteredObjects = {
			params["_center",["_classes",[],[]],["_types",[],[]],"_range"];

			_objects = _center nearEntities [_types, _range];
			_validObjs = [];
			{
				if (!alive _x) then {continue};
				if (typeOf _x in _classes) then {_validObjs pushBack _x;};
			} forEach _objects;
			_classes = _validObjs;
			_validObjs
		};

		LBS_fnc_getNearbySupplyCount = {
			params["_center","_range"];
			_supplyObjects = [_center,LBSAllConstructionSuppliesClassNames+LBSAllConstructionUnitClassNames,["AllVehicles","ReammoBox_F","Cargo_base_F"],_range] call LBS_fnc_getNearFilteredObjects;
			_totalSupply = 0;
			{
				_sp = _x getVariable "LBSCurrentSupplyCount";
				if !(isNil "_sp") then {_totalSupply = (_totalSupply+_sp);};
			} foreach _supplyObjects;
			_totalSupply
		};

		LBS_fnc_getSupplyCountNearestConstructionUnit = {
			params["_center"];
			_constructionUnit = [_center,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
			if (isNil "_constructionUnit") exitWith {0};
			_tier = _constructionUnit getVariable "LBSMaxDistanceSuppliesUpgradeTier";
			if (isNil "_tier") exitWith {["FAILED TO GET CONSTRUCTION UNIT SUPPLY DISTANCE TIER",5,46] call LBS_fnc_systemMessage; 0};
			_range = LBSMaxDistanceSuppliesUpgradeTiers select (_tier-1);
			([ASLToAGL(getPosASL _constructionUnit),_range] call LBS_fnc_getNearbySupplyCount)
		};

		LBS_fnc_getSupplyCountConstructionUnit = {
			params["_constructionUnit"];
			if (isNil "_constructionUnit") exitWith {["INVALID CONSTRUCTION UNIT OBJECT",5,46] call LBS_fnc_systemMessage;};
			_tier = _constructionUnit getVariable "LBSMaxDistanceSuppliesUpgradeTier";
			if (isNil "_tier") exitWith {["FAILED TO GET CONSTRUCTION UNIT SUPPLY DISTANCE TIER",5,46] call LBS_fnc_systemMessage;};
			_range = LBSMaxDistanceSuppliesUpgradeTiers select (_tier-1);
			([ASLToAGL(getPosASL _constructionUnit),_range] call LBS_fnc_getNearbySupplyCount)
		};

		LBS_fnc_subtractFromSupplies = {
			params["_cost","_center","_range"];
			_supplyObjects = [_center,LBSAllConstructionSuppliesClassNames+LBSAllConstructionUnitClassNames,["AllVehicles","ReammoBox_F","Cargo_base_F"],_range] call LBS_fnc_getNearFilteredObjects;
			private _remainingCost = _cost;
			{
				_sp = _x getVariable "LBSCurrentSupplyCount";
				_isCrate = _x getVariable "LBSisCrate";
				if (!isNil "_sp" && !isNil "_isCrate") then 
				{
					if (_sp <= 0) then {continue}; 
					if (_sp > _remainingCost) then 
					{
						_sp = (_sp - _remainingCost);
						[[_x,_sp],{(_this select 0) setVariable ["LBSCurrentSupplyCount",(_this select 1),true];}] call LBS_fnc_RE_Server;
						_remainingCost = 0;
					}
					else 
					{
						_remainingCost = (_remainingCost - _sp);
						_sp = 0;
						if (_isCrate) then {deleteVehicle _x;} else {[[_x,_sp],{(_this select 0) setVariable ["LBSCurrentSupplyCount",(_this select 1),true];}] call LBS_fnc_RE_Server;};
					};
				};
				if (_remainingCost <= 0) exitWith {};
			} foreach _supplyObjects;
		};

		LBS_fnc_Transaction = {
			params["_assetData",["_constructionUnit",objNull]];

			comment "Check for enough supplies";
			_supplyCount = 0;
			_cost = (_assetData select 1);
			_isInit = _constructionUnit getVariable "LBSInitUnit";
			if (isNil "_isInit") then {_constructionUnit = objNull;};
			_supplyCount = [_constructionUnit] call LBS_fnc_getCorrectSupplyCount;
			if (_supplyCount < _cost) exitWith {false};

			comment "handle removal of supplies";
			_center = getPos player;
			_range = LBSMaxDistanceNearbyCrates;

			comment "Get Con Unit info";
			if !(_constructionUnit isEqualTo objNull) then 
			{
				_center = ASLToAGL(getPosASL _constructionUnit);
				_rangeTier = _constructionUnit getVariable "LBSMaxDistancePlacingUpgradeTier";
				_range = (LBSMaxDistancePlacingUpgradeTiers select (_rangeTier-1));
				if (isNil "_range") then {_range = LBSMaxDistanceNearbyCrates;};
			};
			[_cost,_center,_range] call LBS_fnc_subtractFromSupplies;
			true
		};

		LBS_fnc_isPlayerAuthorized = {
			params["_player","_constructionUnit"];

			if (isNil "_constructionUnit") then {_constructionUnit = objNull;};
			_validConUnit = !(_constructionUnit isEqualTo objNull);
			_ownerUID = _constructionUnit getVariable "LBSOwnerUID";
			if (isNil "_ownerUID") then {_ownerUID = "UNKNOWN ID"};

			if (!alive _constructionUnit && _validConUnit) exitWith {false};

			comment "CHECK WHITE LIST HERE";
			_trustedList = _constructionUnit getVariable "LBSTrustedPlayers";
			if (isNil "_trustedList") then {_trustedList = [""];};
			if ((_trustedList isEqualTo [""]) && !(_constructionUnit isEqualTo objNull)) exitWith {false};
			if (getPlayerUID _player in _trustedList) exitWith {true};

			if (!(_ownerUID isEqualTo (getPlayerUID _player)) && _validConUnit) exitWith {false};
			true
		};

		LBS_fnc_isPlayerOwner = {
			params["_player","_constructionUnit"];

			if (isNil "_constructionUnit") then {_constructionUnit = objNull;};
			if (_constructionUnit isEqualTo objNull) exitWith {false};

			_ownerUID = _constructionUnit getVariable "LBSOwnerUID";
			if (getPlayerUID player isEqualTo _ownerUID) exitWith {true};
			false
		};

		LBS_fnc_getCurrentSupplyString = {
			params ["_object"];
			_maxSupply = (_object getVariable "LBSMaxSupplyCount");
			_currentSupply = (_object getVariable "LBSCurrentSupplyCount");
			_text = (str _currentSupply+"/"+str _maxSupply+" SP");
			if(isNil "_text") then {_text = "ERROR: UNKNOWN SUPPLY COUNT";};
			_text
		};

		LBS_fnc_isPlayerInConstructionUnitPlaceRange = {
			params[["_constructionUnit",objNull]];
			if (_constructionUnit isEqualTo objNull) exitWith {false};

			_tier = _constructionUnit getVariable "LBSMaxDistanceSuppliesUpgradeTier";
			if (isNil "_tier") exitWith {false};
			_range = LBSMaxDistancePlacingUpgradeTiers select (_tier-1);

			((player distance _constructionUnit) <= _range)
		};

		LBS_fnc_getCorrectSupplyCount = {
			params[["_constructionUnit",objNull]];
			_supplyCount = 0;
			if (_constructionUnit isEqualTo objNull) then {_supplyCount = ([getpos player,LBSMaxDistanceNearbyCrates] call LBS_fnc_getNearbySupplyCount);}
			else 
			{
				_isInRange = [_constructionUnit] call LBS_fnc_isPlayerInConstructionUnitPlaceRange;
				if (_isInRange) then {_supplyCount = [_constructionUnit] call LBS_fnc_getSupplyCountConstructionUnit;}
				else {_supplyCount = ([getpos player,LBSMaxDistanceNearbyCrates] call LBS_fnc_getNearbySupplyCount);};	
			};
			_supplyCount
		};

		LBS_fnc_createTerminal = {
			createDialog "RscDisplayEmpty";
			_display = (findDisplay -1);
			
			with uinamespace do {
				comment "Create 3D Terminal Control";
				Terminal3DModelCtrl = _display ctrlCreate ["RscObject",-1];
				Terminal3DModelCtrl ctrlSetModel "a3\props_f_exp_a\military\equipment\tablet_02_f.p3d";
				Terminal3DModelCtrl ctrlSetModelScale 1.25;
				Terminal3DModelCtrl ctrlSetModelDirAndUp [[0,0,-1],[0,-1,0]];
				Terminal3DModelCtrl ctrlCommit 0;
				
				comment "Set Scale Based on Interface Size";
				switch (str (getResolution select 5)) do 
				{
					case "0.47": {Terminal3DModelCtrl ctrlSetModelScale 1.47;};
					case "0.55": {Terminal3DModelCtrl ctrlSetModelScale 1.25;};
					case "0.7": {Terminal3DModelCtrl ctrlSetModelScale 1;};
					case "0.85": {Terminal3DModelCtrl ctrlSetModelScale 0.825;};
					case "1": {Terminal3DModelCtrl ctrlSetModelScale 0.7;};
					default {Terminal3DModelCtrl ctrlSetModelScale 1;};
				};
				
				["LBSTerminal","onEachFrame",{
					params ["_ctrl3D"];
					_ctrl3D ctrlSetPosition [0.5, 0.25, 0.505];
					if(_ctrl3D isEqualTo controlNull) exitWith 
					{
						["LBSTerminal","onEachFrame"] call BIS_fnc_removeStackedEventHandler;
						[missionNameSpace, "LBSTerminalClosed",[]] call BIS_fnc_callScriptedEventHandler;
					};
				},[Terminal3DModelCtrl]] call BIS_fnc_addStackedEventHandler;

				_RscStructuredText_1100 = _display ctrlCreate ["RscStructuredText", 1100];
				_RscStructuredText_1100 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1100 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1100 ctrlCommit 0;

				_RscStructuredText_1106 = _display ctrlCreate ["RscStructuredText", 1106];
				_RscStructuredText_1106 ctrlSetPosition [0.29 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1106 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1106 ctrlCommit 0;

				_RscStructuredText_1107 = _display ctrlCreate ["RscStructuredText", 1107];
				_RscStructuredText_1107 ctrlSetPosition [0.303125 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1107 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1107 ctrlCommit 0;

				_RscStructuredText_1108 = _display ctrlCreate ["RscStructuredText", 1108];
				_RscStructuredText_1108 ctrlSetPosition [0.31625 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1108 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1108 ctrlCommit 0;

				_RscStructuredText_1109 = _display ctrlCreate ["RscStructuredText", 1109];
				_RscStructuredText_1109 ctrlSetPosition [0.329375 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1109 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1109 ctrlCommit 0;

				_RscStructuredText_1110 = _display ctrlCreate ["RscStructuredText", 1110];
				_RscStructuredText_1110 ctrlSetPosition [0.341979 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1110 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1110 ctrlCommit 0;

				_RscStructuredText_1111 = _display ctrlCreate ["RscStructuredText", 1111];
				_RscStructuredText_1111 ctrlSetPosition [0.355625 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1111 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1111 ctrlCommit 0;

				_RscStructuredText_1112 = _display ctrlCreate ["RscStructuredText", 1112];
				_RscStructuredText_1112 ctrlSetPosition [0.36875 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1112 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1112 ctrlCommit 0;

				_RscStructuredText_1113 = _display ctrlCreate ["RscStructuredText", 1113];
				_RscStructuredText_1113 ctrlSetPosition [0.381875 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1113 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1113 ctrlCommit 0;

				_RscStructuredText_1114 = _display ctrlCreate ["RscStructuredText", 1114];
				_RscStructuredText_1114 ctrlSetPosition [0.395 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1114 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1114 ctrlCommit 0;

				_RscStructuredText_1115 = _display ctrlCreate ["RscStructuredText", 1115];
				_RscStructuredText_1115 ctrlSetPosition [0.408125 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1115 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1115 ctrlCommit 0;

				_RscStructuredText_1116 = _display ctrlCreate ["RscStructuredText", 1116];
				_RscStructuredText_1116 ctrlSetPosition [0.42125 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136459 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1116 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1116 ctrlCommit 0;

				_RscStructuredText_1117 = _display ctrlCreate ["RscStructuredText", 1117];
				_RscStructuredText_1117 ctrlSetPosition [0.434375 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1117 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1117 ctrlCommit 0;

				_RscStructuredText_1118 = _display ctrlCreate ["RscStructuredText", 1118];
				_RscStructuredText_1118 ctrlSetPosition [0.4475 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1118 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1118 ctrlCommit 0;

				_RscStructuredText_1119 = _display ctrlCreate ["RscStructuredText", 1119];
				_RscStructuredText_1119 ctrlSetPosition [0.460625 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1119 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1119 ctrlCommit 0;

				_RscStructuredText_1120 = _display ctrlCreate ["RscStructuredText", 1120];
				_RscStructuredText_1120 ctrlSetPosition [0.473229 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0141666 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1120 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1120 ctrlCommit 0;

				_RscStructuredText_1121 = _display ctrlCreate ["RscStructuredText", 1121];
				_RscStructuredText_1121 ctrlSetPosition [0.486875 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1121 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1121 ctrlCommit 0;

				_RscStructuredText_1122 = _display ctrlCreate ["RscStructuredText", 1122];
				_RscStructuredText_1122 ctrlSetPosition [0.5 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1122 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1122 ctrlCommit 0;

				_RscStructuredText_1123 = _display ctrlCreate ["RscStructuredText", 1123];
				_RscStructuredText_1123 ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1123 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1123 ctrlCommit 0;

				_RscStructuredText_1124 = _display ctrlCreate ["RscStructuredText", 1124];
				_RscStructuredText_1124 ctrlSetPosition [0.52625 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1124 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1124 ctrlCommit 0;

				_RscStructuredText_1125 = _display ctrlCreate ["RscStructuredText", 1125];
				_RscStructuredText_1125 ctrlSetPosition [0.539375 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1125 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1125 ctrlCommit 0;

				_RscStructuredText_1126 = _display ctrlCreate ["RscStructuredText", 1126];
				_RscStructuredText_1126 ctrlSetPosition [0.5525 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1126 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1126 ctrlCommit 0;

				_RscStructuredText_1127 = _display ctrlCreate ["RscStructuredText", 1127];
				_RscStructuredText_1127 ctrlSetPosition [0.565625 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1127 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1127 ctrlCommit 0;

				_RscStructuredText_1128 = _display ctrlCreate ["RscStructuredText", 1128];
				_RscStructuredText_1128 ctrlSetPosition [0.57875 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0136458 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1128 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1128 ctrlCommit 0;

				_RscStructuredText_1129 = _display ctrlCreate ["RscStructuredText", 1129];
				_RscStructuredText_1129 ctrlSetPosition [0.591875 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1129 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1129 ctrlCommit 0;

				_RscStructuredText_1130 = _display ctrlCreate ["RscStructuredText", 1130];
				_RscStructuredText_1130 ctrlSetPosition [0.604479 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0141666 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1130 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1130 ctrlCommit 0;

				_RscStructuredText_1131 = _display ctrlCreate ["RscStructuredText", 1131];
				_RscStructuredText_1131 ctrlSetPosition [0.618125 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1131 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1131 ctrlCommit 0;

				_RscStructuredText_1132 = _display ctrlCreate ["RscStructuredText", 1132];
				_RscStructuredText_1132 ctrlSetPosition [0.63125 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0141666 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1132 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1132 ctrlCommit 0;

				_RscStructuredText_1133 = _display ctrlCreate ["RscStructuredText", 1133];
				_RscStructuredText_1133 ctrlSetPosition [0.644375 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1133 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1133 ctrlCommit 0;

				_RscStructuredText_1134 = _display ctrlCreate ["RscStructuredText", 1134];
				_RscStructuredText_1134 ctrlSetPosition [0.6575 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0141666 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1134 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1134 ctrlCommit 0;

				_RscStructuredText_1135 = _display ctrlCreate ["RscStructuredText", 1135];
				_RscStructuredText_1135 ctrlSetPosition [0.670625 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1135 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1135 ctrlCommit 0;

				_RscStructuredText_1136 = _display ctrlCreate ["RscStructuredText", 1136];
				_RscStructuredText_1136 ctrlSetPosition [0.68375 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0141666 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1136 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1136 ctrlCommit 0;

				_RscStructuredText_1137 = _display ctrlCreate ["RscStructuredText", 1137];
				_RscStructuredText_1137 ctrlSetPosition [0.696875 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.013125 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1137 ctrlSetBackgroundColor [1,0.75,0,1];
				_RscStructuredText_1137 ctrlCommit 0;

				_RscStructuredText_1138 = _display ctrlCreate ["RscStructuredText", 1138];
				_RscStructuredText_1138 ctrlSetPosition [0.71 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.0141666 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1138 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1138 ctrlCommit 0;
			};
			[missionNameSpace, "LBSTerminalOpened",[]] call BIS_fnc_callScriptedEventHandler;
			(findDisplay -1)
		};

		LBS_fnc_openBuildOptionsTerminal = {
			params["_object"];
			_display = call LBS_fnc_createTerminal;
			
			_allAssets = (missionNamespace getVariable "LBSAllAssetsDictionary");
			_isNearbyConstructionUnit = true;
			_closestConUnit = [getPos player,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
			if (isNil "_closestConUnit") then {_isNearbyConstructionUnit = false; _closestConUnit = objNull;};
			_isInRange = [_closestConUnit] call LBS_fnc_isPlayerInConstructionUnitPlaceRange;
			if (!_isInRange) then {_isNearbyConstructionUnit = false;};
			_supplyCount = [_closestConUnit] call LBS_fnc_getCorrectSupplyCount;

			with uiNamespace do {
				LBSTerminalSupplyPointText = _display ctrlCreate ["RscStructuredText", 1140];
				LBSTerminalSupplyPointText ctrlSetStructuredText parseText ("<t size='2' font='RobotoCondensedBold' align='center' shadow='0'>"+(str _supplyCount)+" SP</t>");
				LBSTerminalSupplyPointText ctrlSetPosition [0.276874 * safezoneW + safezoneX, 0.738 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.056 * safezoneH];
				LBSTerminalSupplyPointText ctrlSetBackgroundColor [0,0,0,0.25];
				LBSTerminalSupplyPointText ctrlCommit 0;

				LBSTerminalSearchBox = _display ctrlCreate ["RscEdit", 645];
				LBSTerminalSearchBox ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.028 * safezoneH];
				LBSTerminalSearchBox ctrlCommit 0;

				_RscPicture_1200 = _display ctrlCreate ["RscPicture", 1200];
				_RscPicture_1200 ctrlSetText "\a3\Ui_f\data\GUI\RscCommon\RscButtonSearch\search_start_ca.paa";
				_RscPicture_1200 ctrlSetPosition [0.47375 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.0196875 * safezoneW, 0.028 * safezoneH];
				_RscPicture_1200 ctrlCommit 0;

				LBSTerminalAssetTree = _display ctrlCreate ["RscTreeSearch", 1500];
				LBSTerminalAssetTree ctrlSetPosition [0.276874 * safezoneW + safezoneX, 0.304 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.392 * safezoneH];
				LBSTerminalAssetTree ctrlSetBackgroundColor [0,0,0,0.25];
				LBSTerminalAssetTree ctrlCommit 0;
				[_allAssets,_isNearbyConstructionUnit] spawn {
					params["_allAssets","_isNearbyConstructionUnit"];
					waitUntil {!isNil "LBSTerminalAssetTree"};
					waitUntil {!(LBSTerminalAssetTree isEqualTo controlNull)};
					_treeDictionary = [];
					{
						_requiresConUnit = (_x select 2);
						if (_isNearbyConstructionUnit || !_requiresConUnit) then 
						{
							_className = _x select 0;
							_displayName = getText(configFile >> "CfgVehicles" >> _className >> "displayName");
							_assetCatagory = getText(configFile >> "CfgVehicles" >> _className >> "editorSubcategory");
							_found = false;
							_pindex = -1;
							{
								_catagory = _x select 0;
								_pindex = _x select 1;
								if (_catagory isEqualTo _assetCatagory) exitWith {_found = true;};
							} foreach _treeDictionary;
							if(!_found) then 
							{
								comment "Add new catagory";
								_catagory = getText(configFile >> "CfgVehicles" >> _className >> "editorSubcategory");
								_catagoryDisplayName = getText(configFile >> "CfgEditorSubcategories" >> _catagory >> "displayName");
								_pindex = LBSTerminalAssetTree tvAdd [[],_catagoryDisplayName];
								_treeDictionary pushBack [_catagory,_pindex];
							};
							comment "Add asset to catagory";
							_cindex = LBSTerminalAssetTree tvAdd [[_pindex],_displayName];
							LBSTerminalAssetTree tvSetData [[_pindex,_cindex],_className];
						};
					} foreach _allAssets;
				};
				LBSTerminalAssetTree ctrlAddEventHandler ["TreeSelChanged",{
					params ["_control", "_selectionPath"];

					_closestConUnit = [getPos player,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
					if (isNil "_closestConUnit") then {_closestConUnit = objNull;};
					_supplyCount = [_closestConUnit] call LBS_fnc_getCorrectSupplyCount;
					_classSelected = tvData [ctrlIDC _control,_selectionPath];
					_assetData = [_classSelected] call LBS_fnc_findAssetObjectData;
					if (_assetData isEqualTo []) exitWith {};
					with uiNamespace do {
						_image = getText(configFile >> "CfgVehicles" >> _classSelected >> "editorPreview");
						LBSTerminalPreviewImage ctrlSetText _image;
						LBSTerminalPreviewImage ctrlCommit 0;

						comment "Update Cost Info";
						_costText = ((str(_assetData select 1))+" SP");
						_buildTimeText = ((str(_assetData select 3))+" seconds");
						_remainingSupplyCountText = (str(_supplyCount-(_assetData select 1))+ " SP");
						_line1 = ("<t size='0.9' font='PuristaSemibold'>Asset Cost: </t>"+"<t size='0.9' font='PuristaSemibold' color='#a7ff8c'>"+_costText+"<br/></t>");
						_line2 = ("<t size='0.9' font='PuristaSemibold'>Build Time: </t>"+"<t size='0.9' font='PuristaSemibold' color='#ff8800'>"+_buildTimeText+"<br/></t>");
						_line3 = ("<t size='0.9' font='PuristaSemibold'>Remaining Supply: </t>"+"<t size='0.9' font='PuristaSemibold' color='#abe6ff'>"+_remainingSupplyCountText+"<br/></t>");
						LBSTerminalCostTextBox ctrlSetStructuredText parseText (_line1 + _line2 + _line3);
						LBSTerminalCostTextBox ctrlCommit 0;
					};
				}];

				LBSTerminalBuildButton = _display ctrlCreate ["RscButtonMenu", 2400];
				LBSTerminalBuildButton ctrlSetText "Build It";
				LBSTerminalBuildButton ctrlSetPosition [0.5 * safezoneW + safezoneX, 0.752 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.042 * safezoneH];
				LBSTerminalBuildButton ctrlCommit 0;
				LBSTerminalBuildButton ctrlAddEventHandler ["ButtonDown",{
					with uiNamespace do 
					{
						_className = tvData [ctrlIDC LBSTerminalAssetTree,(tvCurSel LBSTerminalAssetTree)];
						with missionNamespace do 
						{
							_error = {
								["YOU DONT HAVE PERMISSION TO BUILD HERE!",5,46] call LBS_fnc_systemMessage;
							};
							_closestConUnit = [getPos player,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
							if (isNil "_constructionUnit") then {_constructionUnit = objNull;};
							_validConUnit = !(_constructionUnit isEqualTo objNull);
							_isAuth = [player,_closestConUnit] call LBS_fnc_isPlayerAuthorized; 
							if (!_isAuth) exitWith {call _error;};

							_assetData = [_className] call LBS_fnc_findAssetObjectData;
							_supplyCount = [_closestConUnit] call LBS_fnc_getCorrectSupplyCount;
							if (isNil "_assetData") exitWith {["INVALID DATA!",5,46] call LBS_fnc_systemMessage;};
							if (_assetData isEqualTo []) exitWith {["NOTHING SELECTED!",5,46] call LBS_fnc_systemMessage;};
							_cost = (_assetData select 1);
							if (_supplyCount < _cost) exitWith {["NOT ENOUGH SUPPLIES NEARBY!",5,46] call LBS_fnc_systemMessage;};

							_range = LBSPlaceMaxDistanceFromPlayerNoConstructionUnit;
							if (_validConUnit) then {_range = LBSPlaceMaxDistanceFromPlayer};
							[_assetData,_range] call LBS_fnc_placeAsset;
						};
						closeDialog 1;
					};
				}];

				LBSTerminalCostTextBox = _display ctrlCreate ["RscStructuredText", 1105];
				LBSTerminalCostTextBox ctrlSetPosition [0.5 * safezoneW + safezoneX, 0.64 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.098 * safezoneH];
				LBSTerminalCostTextBox ctrlSetBackgroundColor [0,0,0,0.25];
				LBSTerminalCostTextBox ctrlCommit 0;

				_RscPicture_1205 = _display ctrlCreate ["RscPicture", 1205];
				_RscPicture_1205 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1205 ctrlSetTextColor [0,0,0,0.25];
				_RscPicture_1205 ctrlSetPosition [0.499999 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.322 * safezoneH];
				_RscPicture_1205 ctrlCommit 0;

				LBSTerminalPreviewImage = _display ctrlCreate ["RscPicture", 1201];
				LBSTerminalPreviewImage ctrlSetText "";
				LBSTerminalPreviewImage ctrlSetPosition [0.499999 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.322 * safezoneH];
				LBSTerminalPreviewImage ctrlCommit 0;

				_RscStructuredText_1101 = _display ctrlCreate ["RscStructuredText", 1101];
				_RscStructuredText_1101 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>ASSETS</t>";
				_RscStructuredText_1101 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.248 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1101 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1101 ctrlCommit 0;

				_RscStructuredText_1102 = _display ctrlCreate ["RscStructuredText", 1102];
				_RscStructuredText_1102 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>PREVIEW</t>";
				_RscStructuredText_1102 ctrlSetPosition [0.499999 * safezoneW + safezoneX, 0.248 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1102 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1102 ctrlCommit 0;

				_RscStructuredText_1103 = _display ctrlCreate ["RscStructuredText", 1103];
				_RscStructuredText_1103 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>COST</t>";
				_RscStructuredText_1103 ctrlSetPosition [0.5 * safezoneW + safezoneX, 0.612 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1103 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1103 ctrlCommit 0;

				_RscStructuredText_1104 = _display ctrlCreate ["RscStructuredText", 1104];
				_RscStructuredText_1104 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>AVAILABLE SUPPLY</t>";
				_RscStructuredText_1104 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.71 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1104 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1104 ctrlCommit 0;

				_RscStructuredText_1139 = _display ctrlCreate ["RscStructuredText", 1139];
				_RscStructuredText_1139 ctrlSetStructuredText parseText "<t size='1.5' font='PuristaBold' align='center' shadow='1'>BUILD OPTIONS</t>";
				_RscStructuredText_1139 ctrlSetPosition [0.335938 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.321562 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1139 ctrlSetBackgroundColor [0,0,0,0];
				_RscStructuredText_1139 ctrlCommit 0;
			};
		};

		LBS_fnc_openConstructionOptionsTerminal = {
			params ["_object"];

			_display = call LBS_fnc_createTerminal;
			_supplyCount = [_object] call LBS_fnc_getSupplyCountConstructionUnit;

			with uiNamespace do {
				LBSUILocalConstructionUnit = _object;
				LBSOptionsTabControls = [];
				LBSUpgradeTabControls = [];

				LBS_UI_updateTrustedListBoxes = {
					_trustedList = LBSUILocalConstructionUnit getVariable "LBSTrustedPlayers";
					if (isNil "_trustedList") exitWith {};

					lbClear LBSAllPlayersListBox;
					lbClear LBSTrustedPlayersListBox;
					{
						if (getPlayerUID _x in _trustedList) then 
						{
							_index = LBSTrustedPlayersListBox lbAdd name _x;
							LBSTrustedPlayersListBox lbSetData [_index,getPlayerUID _x];
						}
						else 
						{
							_index = LBSAllPlayersListBox lbAdd name _x;
							LBSAllPlayersListBox lbSetData [_index,getPlayerUID _x];
						};
					} foreach allPlayers;
				};

				_RscStructuredText_1101 = _display ctrlCreate ["RscStructuredText", 1101];
				_RscStructuredText_1101 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>AVAILABLE BASE SUPPLY</t>";
				_RscStructuredText_1101 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.71 * safezoneH + safezoneY, 0.229687 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1101 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1101 ctrlCommit 0;

				LBSConstructionUnitAvailableSupplyText = _display ctrlCreate ["RscStructuredText", 1103];
				LBSConstructionUnitAvailableSupplyText ctrlSetStructuredText parseText ("<t size='2' font='RobotoCondensedBold' align='center' shadow='0'>"+(str _supplyCount)+" SP</t>");
				LBSConstructionUnitAvailableSupplyText ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.738 * safezoneH + safezoneY, 0.229687 * safezoneW, 0.056 * safezoneH];
				LBSConstructionUnitAvailableSupplyText ctrlSetBackgroundColor [0,0,0,0.25];
				LBSConstructionUnitAvailableSupplyText ctrlCommit 0;

				_RscStructuredText_1139 = _display ctrlCreate ["RscStructuredText", 1139];
				_RscStructuredText_1139 ctrlSetStructuredText parseText "<t size='1.5' font='PuristaBold' align='center' shadow='1'>CONSTRUCTION UNIT</t>";
				_RscStructuredText_1139 ctrlSetPosition [0.335938 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.321562 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1139 ctrlSetBackgroundColor [0,0,0,0];
				_RscStructuredText_1139 ctrlCommit 0;

				LBSAllPlayersListBox = _display ctrlCreate ["RscListbox", 1500];
				LBSAllPlayersListBox ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.304 * safezoneH + safezoneY, 0.111562 * safezoneW, 0.35 * safezoneH];
				LBSAllPlayersListBox ctrlCommit 0;
				LBSOptionsTabControls pushBack LBSAllPlayersListBox;

				_RscStructuredText_1100 = _display ctrlCreate ["RscStructuredText", 1100];
				_RscStructuredText_1100 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>ALL PLAYERS</t>";
				_RscStructuredText_1100 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.111562 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1100 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1100 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscStructuredText_1100;

				LBSTrustedPlayersListBox = _display ctrlCreate ["RscListbox", 1501];
				LBSTrustedPlayersListBox ctrlSetPosition [0.395 * safezoneW + safezoneX, 0.304 * safezoneH + safezoneY, 0.111562 * safezoneW, 0.35 * safezoneH];
				LBSTrustedPlayersListBox ctrlCommit 0;
				LBSOptionsTabControls pushBack LBSTrustedPlayersListBox;

				_RscStructuredText_1102 = _display ctrlCreate ["RscStructuredText", 1102];
				_RscStructuredText_1102 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>TRUSTED PLAYERS</t>";
				_RscStructuredText_1102 ctrlSetPosition [0.395 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.111562 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1102 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1102 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscStructuredText_1102;

				_RscButtonMenu_2402 = _display ctrlCreate ["RscButtonMenu", 2402];
				_RscButtonMenu_2402 ctrlSetText "Add trusted";
				_RscButtonMenu_2402 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.654 * safezoneH + safezoneY, 0.111562 * safezoneW, 0.042 * safezoneH];
				_RscButtonMenu_2402 ctrlSetTooltip "Select a player and click this button to allow them to build on your base";
				_RscButtonMenu_2402 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscButtonMenu_2402;
				_RscButtonMenu_2402 ctrlAddEventHandler ["ButtonDown",{
					with uiNamespace do {
						_trustedList = LBSUILocalConstructionUnit getVariable "LBSTrustedPlayers";
						if (isNil "_trustedList") exitWith {};
						_trustedList pushBack (LBSAllPlayersListBox lbData (lbCurSel LBSAllPlayersListBox));
						_conUnit = LBSUILocalConstructionUnit;
						with missionNamespace do {[[_conUnit,_trustedList],{(_this select 0) setVariable ["LBSTrustedPlayers",(_this select 1),true];}] call LBS_fnc_RE_Server;};
						call LBS_UI_updateTrustedListBoxes;
					};
				}];

				_RscButtonMenu_2403 = _display ctrlCreate ["RscButtonMenu", 2403];
				_RscButtonMenu_2403 ctrlSetText "Remove trusted";
				_RscButtonMenu_2403 ctrlSetPosition [0.395 * safezoneW + safezoneX, 0.654 * safezoneH + safezoneY, 0.111562 * safezoneW, 0.042 * safezoneH];
				_RscButtonMenu_2403 ctrlSetTooltip "Select a trusted player and click this to remove them";
				_RscButtonMenu_2403 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscButtonMenu_2403;
				_RscButtonMenu_2403 ctrlAddEventHandler ["ButtonDown",{
					with uiNamespace do {
						_trustedList = LBSUILocalConstructionUnit getVariable "LBSTrustedPlayers";
						if (isNil "_trustedList") exitWith {};
						_index = _trustedList findIf {_x isEqualTo (LBSTrustedPlayersListBox lbData (lbCurSel LBSTrustedPlayersListBox))};
						_conUnit = LBSUILocalConstructionUnit;
						if (_index != -1) then {_trustedList deleteAt _index; with missionNamespace do {[[_conUnit,_trustedList],{(_this select 0) setVariable ["LBSTrustedPlayers",(_this select 1),true];}] call LBS_fnc_RE_Server;};};
						call LBS_UI_updateTrustedListBoxes;
					};
				}];

				LBS_UI_UpdateBaseMarkers = {
					_radiusMarker = LBSUILocalConstructionUnit getVariable "LBSBaseRadiusMarker";
					_nameMarker = LBSUILocalConstructionUnit getVariable "LBSBaseNameMarker";
					_baseColor = LBSBaseColorComboBox lbData (lbCurSel LBSBaseColorComboBox);
					_baseName = ctrlText LBSBaseNameEditBox;

					if (isNil "_radiusMarker") then 
					{
						_radiusMarker = createMarker ["LBSRaduisMarker_"+str(count allMapMarkers),getPos LBSUILocalConstructionUnit];
						LBSUILocalConstructionUnit setVariable ["LBSBaseRadiusMarker",_radiusMarker,true];
					};
					if (!(ctrlShown LBSBaseColorComboBox)) then {_baseColor = getMarkerColor _radiusMarker};

					_radiusMarker setMarkerShape "ELLIPSE";
					_r = LBSUILocalConstructionUnit getVariable "LBSMaxDistancePlacingUpgradeTier";
					with missionNamespace do {_r = LBSMaxDistancePlacingUpgradeTiers select (_r-1);};
					_radiusMarker setMarkerSize [_r,_r];
					_radiusMarker setMarkerBrush "SolidBorder";
					_radiusMarker setMarkerColor _baseColor;
					_radiusMarker setMarkerAlpha 0.5;
					_radiusMarker setMarkerPos getPos LBSUILocalConstructionUnit;

					if (isNil "_nameMarker") then 
					{
						_nameMarker = createMarker ["LBSRaduisMarker_"+str(count allMapMarkers),getPos LBSUILocalConstructionUnit];
						LBSUILocalConstructionUnit setVariable ["LBSBaseNameMarker",_nameMarker,true];
					};
					_nameMarker setMarkerType "b_hq";
					_nameMarker setMarkerColor _baseColor;
					_nameMarker setMarkerText _baseName;
					_nameMarker setMarkerAlpha 1;
					_nameMarker setMarkerPos getPos LBSUILocalConstructionUnit;
				};

				_RscButtonMenu_2404 = _display ctrlCreate ["RscButtonMenu", 2404];
				_RscButtonMenu_2404 ctrlSetText "Submit base settings";
				_RscButtonMenu_2404 ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.752 * safezoneH + safezoneY, 0.21 * safezoneW, 0.042 * safezoneH];
				_RscButtonMenu_2404 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscButtonMenu_2404;
				_RscButtonMenu_2404 ctrlAddEventHandler ["ButtonDown",{
					with uiNamespace do {
						_radiusMarker = LBSUILocalConstructionUnit getVariable "LBSBaseRadiusMarker";
						_nameMarker = LBSUILocalConstructionUnit getVariable "LBSBaseNameMarker";
						_baseColor = LBSBaseColorComboBox lbData (lbCurSel LBSBaseColorComboBox);
						_baseName = ctrlText LBSBaseNameEditBox;

						if (isNil "_radiusMarker") then 
						{
							_radiusMarker = createMarker ["LBSRaduisMarker_"+str(count allMapMarkers),getPos LBSUILocalConstructionUnit];
							_conUnit = LBSUILocalConstructionUnit;
							with missionNamespace do {[[_conUnit,_radiusMarker],{(_this select 0) setVariable ["LBSBaseRadiusMarker",(_this select 1),true];}] call LBS_fnc_RE_Server;};
						};
						_radiusMarker setMarkerShape "ELLIPSE";
						_r = LBSUILocalConstructionUnit getVariable "LBSMaxDistancePlacingUpgradeTier";
						with missionNamespace do {_r = LBSMaxDistancePlacingUpgradeTiers select (_r-1);};
						_radiusMarker setMarkerSize [_r,_r];
						_radiusMarker setMarkerBrush "SolidBorder";
						_radiusMarker setMarkerColor _baseColor;
						_radiusMarker setMarkerAlpha 0.5;

						if (isNil "_nameMarker") then 
						{
							_nameMarker = createMarker ["LBSRaduisMarker_"+str(count allMapMarkers),getPos LBSUILocalConstructionUnit];
							_conUnit = LBSUILocalConstructionUnit;
							with missionNamespace do {[[_conUnit,_nameMarker],{(_this select 0) setVariable ["LBSBaseNameMarker",(_this select 1),true];}] call LBS_fnc_RE_Server;};
						};
						_nameMarker setMarkerType "b_hq";
						_nameMarker setMarkerColor _baseColor;
						_nameMarker setMarkerText _baseName;
						_nameMarker setMarkerAlpha 1;
					};
				}];

				_RscStructuredText_1104 = _display ctrlCreate ["RscStructuredText", 1104];
				_RscStructuredText_1104 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>MAP</t>";
				_RscStructuredText_1104 ctrlSetPosition [0.513124 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.21 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1104 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1104 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscStructuredText_1104;

				_RscPicture_1203 = _display ctrlCreate ["RscMapControl", 1203];
				_RscPicture_1203 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1203 ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.304 * safezoneH + safezoneY, 0.21 * safezoneW, 0.294 * safezoneH];
				_RscPicture_1203 ctrlCommit 0; 
				[[10,10],position player,0.5,_RscPicture_1203] call BIS_fnc_zoomOnArea;
				LBSOptionsTabControls pushBack _RscPicture_1203;

				_RscStructuredText_1105 = _display ctrlCreate ["RscStructuredText", 1105];
				_RscStructuredText_1105 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>BASE NAME</t>";
				_RscStructuredText_1105 ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.612 * safezoneH + safezoneY, 0.21 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1105 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1105 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscStructuredText_1105;

				LBSBaseNameEditBox = _display ctrlCreate ["RscEdit", 1400];
				LBSBaseNameEditBox ctrlSetText "base name...";
				LBSBaseNameEditBox ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.64 * safezoneH + safezoneY, 0.21 * safezoneW, 0.028 * safezoneH];
				LBSBaseNameEditBox ctrlSetBackgroundColor [0,0,0,0.5];
				_nameMarker = LBSUILocalConstructionUnit getVariable "LBSBaseNameMarker";
				if !(isNil "_nameMarker") then {LBSBaseNameEditBox ctrlSetText markerText _nameMarker;};
				LBSBaseNameEditBox ctrlCommit 0;
				LBSOptionsTabControls pushBack LBSBaseNameEditBox;

				_RscStructuredText_1106 = _display ctrlCreate ["RscStructuredText", 1106];
				_RscStructuredText_1106 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>BASE COLOR</t>";
				_RscStructuredText_1106 ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.682 * safezoneH + safezoneY, 0.21 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1106 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1106 ctrlCommit 0;
				LBSOptionsTabControls pushBack _RscStructuredText_1106;

				LBSBaseColorComboBox = _display ctrlCreate ["RscCombo", 2100];
				LBSBaseColorComboBox ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.71 * safezoneH + safezoneY, 0.21 * safezoneW, 0.028 * safezoneH];
				LBSBaseColorComboBox ctrlCommit 0;
				_colorClasses = (configfile >> "CfgMarkerColors") call BIS_fnc_getCfgSubClasses;
				{
					_name = getText(configfile >> "CfgMarkerColors" >> _x >> "name");
					_index = LBSBaseColorComboBox lbAdd _name;
					LBSBaseColorComboBox lbSetData [_index,_x];
				} foreach _colorClasses;
				LBSBaseColorComboBox lbSetCurSel 0;
				LBSOptionsTabControls pushBack LBSBaseColorComboBox;

				comment "UPGRADE TAB";
				_RscPicture_1202 = _display ctrlCreate ["RscPicture", 1202];
				_RscPicture_1202 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1202 ctrlSetPosition [0.434375 * safezoneW + safezoneX, 0.234 * safezoneH + safezoneY, 0.28875 * safezoneW, 0.028 * safezoneH];
				_RscPicture_1202 ctrlSetTextColor [0,0,0,0.5];
				_RscPicture_1202 ctrlCommit 0;

				_RscButtonMenu_2400 = _display ctrlCreate ["RscButtonMenu", 2400];
				_RscButtonMenu_2400 ctrlSetText "Options";
				_RscButtonMenu_2400 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.234 * safezoneH + safezoneY, 0.07875 * safezoneW, 0.028 * safezoneH];
				_RscButtonMenu_2400 ctrlCommit 0;
				_RscButtonMenu_2400 ctrlAddEventHandler ["ButtonDown",{
					with uiNamespace do {
						{_x ctrlShow true;} foreach LBSOptionsTabControls;
						{_x ctrlShow false;} foreach LBSUpgradeTabControls;
					};
				}];

				_RscButtonMenu_2401 = _display ctrlCreate ["RscButtonMenu", 2401];
				_RscButtonMenu_2401 ctrlSetText "Upgrades";
				_RscButtonMenu_2401 ctrlSetPosition [0.355625 * safezoneW + safezoneX, 0.234 * safezoneH + safezoneY, 0.07875 * safezoneW, 0.028 * safezoneH];
				_RscButtonMenu_2401 ctrlCommit 0;
				_RscButtonMenu_2401 ctrlAddEventHandler ["ButtonDown",{
					with uiNamespace do {
						{_x ctrlShow false;} foreach LBSOptionsTabControls;
						{_x ctrlShow true;} foreach LBSUpgradeTabControls;
						call LBS_UI_UpdateUpgradeListBox;
						call LBS_UI_UpdateCurrentUpgradesText;
					};
				}];

				LBS_UI_UpdateUpgradeListBox = {
					lbClear LBSUpgradeListbox;

					_placingDistanceTier = LBSUILocalConstructionUnit getVariable "LBSMaxDistancePlacingUpgradeTier";
					_supplyDistanceTier = LBSUILocalConstructionUnit getVariable "LBSMaxDistanceSuppliesUpgradeTier";
					_parallelBuildAllowed = LBSUILocalConstructionUnit getVariable "LBSParallelBuildUpgradeAllowed";

					if (isNil "_placingDistanceTier") exitWith {};
					if (isNil "_supplyDistanceTier") exitWith {};
					if (isNil "_parallelBuildAllowed") exitWith {};

					_nextPlacingDistanceTier = (_placingDistanceTier + 1);
					_nextSupplyDistanceTier = (_supplyDistanceTier + 1);

					_supplyCount = 0;
					_contUnit = LBSUILocalConstructionUnit;
					with missionNamespace do {_supplyCount = [_contUnit] call LBS_fnc_getCorrectSupplyCount;};
					
					comment "Placing Tier Cost";
					with missionNamespace do 
					{
						if !(_nextPlacingDistanceTier > (count LBSMaxDistancePlacingUpgradeTiers)) then 
						{
							_ctrl = controlNull;
							_index = -1;
							with uiNamespace do 
							{
								_ctrl = LBSUpgradeListbox;
								_index = LBSUpgradeListbox lbAdd ("Upgrade Placing Range -> Tier "+str _nextPlacingDistanceTier);
								LBSUpgradeListbox lbSetValue [_index,_placingDistanceTier];
								LBSUpgradeListbox lbSetPictureRight [_index,"\a3\ui_f\data\IGUI\cfg\actions\take_ca.paa"];
							};
							_ctrl lbSetData [_index,"Increase the placing range to " + str (LBSMaxDistancePlacingUpgradeTiers select (_nextPlacingDistanceTier-1))+"m"];
						};
					};

					comment "Supply Tier Cost";
					with missionNamespace do 
					{
						if !(_nextSupplyDistanceTier > (count LBSMaxDistanceSuppliesUpgradeTiers)) then 
						{
							_ctrl = controlNull;
							_index = -1;
							with uiNamespace do 
							{
								_ctrl = LBSUpgradeListbox;
								_index = LBSUpgradeListbox lbAdd ("Upgrade Supply Range -> Tier "+str _nextSupplyDistanceTier);
								LBSUpgradeListbox lbSetValue [_index,_supplyDistanceTier];
								LBSUpgradeListbox lbSetPictureRight [_index,"\a3\ui_f_curator\data\Displays\RscDisplayCurator\modeModules_ca.paa"];
							};
							_ctrl lbSetData [_index,"Increase the supply range to " + str (LBSMaxDistanceSuppliesUpgradeTiers select (_nextSupplyDistanceTier-1))+"m"];
						};
					};

					comment "Parallel Building Cost";
					with missionNamespace do 
					{
						if !(_parallelBuildAllowed) then 
						{
							_ctrl = controlNull;
							_index = -1;
							with uiNamespace do 
							{
								_ctrl = LBSUpgradeListbox;
								_index = LBSUpgradeListbox lbAdd ("Enable Parallel Construction");
								LBSUpgradeListbox lbSetValue [_index,2];
								LBSUpgradeListbox lbSetPictureRight [_index,"\a3\modules_f_curator\Data\portraitRespawnTickets_ca.paa"];
							};
							_ctrl lbSetData [_index,"Enable the ability to build multiple assets at once"];
						};
					};
				};

				LBSUpgradeListbox = _display ctrlCreate ["RscListbox", 1500];
				LBSUpgradeListbox ctrlSetPosition [0.276874 * safezoneW + safezoneX, 0.304 * safezoneH + safezoneY, 0.229687 * safezoneW, 0.35 * safezoneH];
				LBSUpgradeListbox ctrlCommit 0;
				LBSUpgradeTabControls pushBack LBSUpgradeListbox;
				LBSUpgradeListbox ctrlAddEventHandler ["LBSelChanged",{
					params ["_control", "_selectedIndex"];
					with uiNamespace do 
					{
						_tierValue = _control lbValue _selectedIndex;
						_upgradeDesc = _control lbData _selectedIndex;
						if (isNil "_tierValue") exitWith {};
						if (isNil "_upgradeDesc") exitWith {};

						_nextSelectedTier = (_tierValue + 1);

						_supplyCount = 0;
						_conUnit = LBSUILocalConstructionUnit;
						with missionNamespace do {_supplyCount = [_conUnit] call LBS_fnc_getCorrectSupplyCount;};
						
						comment "Selected Tier Cost";
						_line1 = "";
						_line2 = "";
						_line3 = "";

						with missionNamespace do {
							_costText = ((str(LBSTierUpgradeCost*_tierValue))+" SP");
							_remainingSupplyCountText = (str(_supplyCount-(LBSTierUpgradeCost*_tierValue))+ " SP");

							_line1 = ("<t size='0.9' font='PuristaSemibold'>Upgrade Cost: </t>"+"<t size='1' font='PuristaSemibold' color='#a7ff8c'>"+_costText+"<br/></t>");
							_line2 = ("<t size='0.9' font='PuristaSemibold'>Remaining Supply: </t>"+"<t size='1' font='PuristaSemibold' color='#abe6ff'>"+_remainingSupplyCountText+"<br/><br/></t>");
							_line3 = ("<t size='1' font='RobotoCondensedBold'>"+_upgradeDesc+"<br/></t>");
						};
						LBSSelectedUpgradeInfoText ctrlSetStructuredText parseText (_line1 + _line2+ _line3);
						LBSSelectedUpgradeInfoText ctrlCommit 0;
					};
				}];

				_RscStructuredText_1102 = _display ctrlCreate ["RscStructuredText", 1102];
				_RscStructuredText_1102 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>AVAILABLE UPGRADES</t>";
				_RscStructuredText_1102 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.229687 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1102 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1102 ctrlCommit 0;
				LBSUpgradeTabControls pushBack _RscStructuredText_1102;

				_RscButtonMenu_2402 = _display ctrlCreate ["RscButtonMenu", 2402];
				_RscButtonMenu_2402 ctrlSetText "Purchase upgrade";
				_RscButtonMenu_2402 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.654 * safezoneH + safezoneY, 0.229687 * safezoneW, 0.042 * safezoneH];
				_RscButtonMenu_2402 ctrlCommit 0;
				LBSUpgradeTabControls pushBack _RscButtonMenu_2402;
				_RscButtonMenu_2402 ctrlAddEventHandler ["ButtonDown",{
					params ["_control"];
					with uiNamespace do {
						if ((lbSize LBSUpgradeListbox) isEqualTo 0) exitWith {playSound "addItemFailed";};

						[_control] spawn {params ["_control"]; _control ctrlEnable false; sleep 1;  _control ctrlEnable true;};

						_tierValue = LBSUpgradeListbox lbValue (lbCurSel LBSUpgradeListbox);
						_upgradeDesc = LBSUpgradeListbox lbData (lbCurSel LBSUpgradeListbox);
						if (isNil "_tierValue") exitWith {};

						_placingDistanceTier = LBSUILocalConstructionUnit getVariable "LBSMaxDistancePlacingUpgradeTier";
						_supplyDistanceTier = LBSUILocalConstructionUnit getVariable "LBSMaxDistanceSuppliesUpgradeTier";
						_parallelBuildAllowed = LBSUILocalConstructionUnit getVariable "LBSParallelBuildUpgradeAllowed";

						if (isNil "_placingDistanceTier") exitWith {};
						if (isNil "_supplyDistanceTier") exitWith {};
						if (isNil "_parallelBuildAllowed") exitWith {};

						_success = false;
						_conUnit = LBSUILocalConstructionUnit;
						with missionNamespace do {_success = [["",(LBSTierUpgradeCost*_tierValue)],_conUnit] call LBS_fnc_Transaction;};

						if (_success) then {
							switch (toLower(LBSUpgradeListbox lbPictureRight (lbCurSel LBSUpgradeListbox))) do 
							{
								case (toLower "a3\ui_f\data\IGUI\cfg\actions\take_ca.paa"): {with missionNamespace do {[[_conUnit,"LBSMaxDistancePlacingUpgradeTier",_placingDistanceTier+1],{(_this select 0) setVariable [(_this select 1),(_this select 2),true]}] call LBS_fnc_RE_Server;};};
								case (toLower "a3\ui_f_curator\data\Displays\RscDisplayCurator\modeModules_ca.paa"): {with missionNamespace do {[[_conUnit,"LBSMaxDistanceSuppliesUpgradeTier",_supplyDistanceTier+1],{(_this select 0) setVariable [(_this select 1),(_this select 2),true]}] call LBS_fnc_RE_Server;};};
								case (toLower "a3\modules_f_curator\Data\portraitRespawnTickets_ca.paa"): {with missionNamespace do {[[_conUnit,"LBSParallelBuildUpgradeAllowed"],{(_this select 0) setVariable [(_this select 1),true,true]}] call LBS_fnc_RE_Server;};};
							};
							playSound "addItemOK";
							with missionNamespace do {["UPGRADE INSTALLED!",3,46] call LBS_fnc_systemMessage;};
						}
						else {with missionNamespace do {playSound "addItemFailed"; ["NOT ENOUGH SUPPLIES NEARBY!",1.5,46] call LBS_fnc_systemMessage;};};
						[] spawn 
						{
							with uiNamespace do 
							{
								sleep 0.5;
								_supplyCount = 0;
								_conUnit = LBSUILocalConstructionUnit;
								with missionNamespace do {_supplyCount = [_conUnit] call LBS_fnc_getSupplyCountConstructionUnit;};
								LBSConstructionUnitAvailableSupplyText ctrlSetStructuredText parseText ("<t size='2' font='RobotoCondensedBold' align='center' shadow='0'>"+(str _supplyCount)+" SP</t>");
								LBSConstructionUnitAvailableSupplyText ctrlCommit 0;

								call LBS_UI_UpdateBaseMarkers;
								call LBS_UI_UpdateUpgradeListBox;
								call LBS_UI_UpdateCurrentUpgradesText;
							};
						};
					};
				}];

				_RscStructuredText_1103 = _display ctrlCreate ["RscStructuredText", 1103];
				_RscStructuredText_1103 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>CURRENT UPGRADES</t>";
				_RscStructuredText_1103 ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.486 * safezoneH + safezoneY, 0.21 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1103 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1103 ctrlCommit 0;
				LBSUpgradeTabControls pushBack _RscStructuredText_1103;

				_RscStructuredText_1104 = _display ctrlCreate ["RscStructuredText", 1104];
				_RscStructuredText_1104 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>UPGRADE INFO</t>";
				_RscStructuredText_1104 ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.21 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1104 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1104 ctrlCommit 0;
				LBSUpgradeTabControls pushBack _RscStructuredText_1104;

				LBS_UI_UpdateCurrentUpgradesText = {
					_placingDistanceTier = LBSUILocalConstructionUnit getVariable "LBSMaxDistancePlacingUpgradeTier";
					_supplyDistanceTier = LBSUILocalConstructionUnit getVariable "LBSMaxDistanceSuppliesUpgradeTier";
					_parallelBuildAllowed = LBSUILocalConstructionUnit getVariable "LBSParallelBuildUpgradeAllowed";

					if (isNil "_placingDistanceTier") exitWith {};
					if (isNil "_supplyDistanceTier") exitWith {};
					if (isNil "_parallelBuildAllowed") exitWith {};

					_line1 = ("<t size='0.9' font='PuristaSemibold'>Placing Range: </t>"+"<t size='0.9' font='PuristaSemibold' color='#ffcc00'>Tier "+str _placingDistanceTier+"<br/></t>");
					_line2 = ("<t size='0.9' font='PuristaSemibold'>Supply Range: </t>"+"<t size='0.9' font='PuristaSemibold' color='#ffcc00'>Tier "+str _supplyDistanceTier+"<br/></t>");
					_line3 = "";
					if(_parallelBuildAllowed) then {_line3 = ("<t size='0.9' font='PuristaSemibold'>Parallel Construction: </t>"+"<t size='0.9' font='PuristaSemibold' color='#ffcc00'>Enabled<br/></t>");}
					else {_line3 = ("<t size='0.9' font='PuristaSemibold'>Parallel Construction: </t>"+"<t size='0.9' font='PuristaSemibold' color='#ff1100'>Disabled<br/></t>");};

					LBSCurrentUpgradesText ctrlSetStructuredText parseText (_line1 + _line2 + _line3);
					LBSCurrentUpgradesText ctrlCommit 0;
				};

				LBSCurrentUpgradesText = _display ctrlCreate ["RscStructuredText", 1105];
				LBSCurrentUpgradesText ctrlSetStructuredText parseText "";
				LBSCurrentUpgradesText ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.514 * safezoneH + safezoneY, 0.21 * safezoneW, 0.182 * safezoneH];
				LBSCurrentUpgradesText ctrlSetBackgroundColor [0,0,0,0.25];
				LBSCurrentUpgradesText ctrlCommit 0;
				LBSUpgradeTabControls pushBack LBSCurrentUpgradesText;

				LBSSelectedUpgradeInfoText = _display ctrlCreate ["RscStructuredText", 1106];
				LBSSelectedUpgradeInfoText ctrlSetStructuredText parseText "";
				LBSSelectedUpgradeInfoText ctrlSetPosition [0.513125 * safezoneW + safezoneX, 0.304 * safezoneH + safezoneY, 0.21 * safezoneW, 0.168 * safezoneH];
				LBSSelectedUpgradeInfoText ctrlSetBackgroundColor [0,0,0,0.25];
				LBSSelectedUpgradeInfoText ctrlCommit 0;
				LBSUpgradeTabControls pushBack LBSSelectedUpgradeInfoText;

				{_x ctrlShow true;} foreach LBSOptionsTabControls;
				{_x ctrlShow false;} foreach LBSUpgradeTabControls;
				call LBS_UI_updateTrustedListBoxes;
			};
		};

		LBS_fnc_openSupplyOptionsTerminal = {
			params ["_object"];

			_display = call LBS_fnc_createTerminal;
			_supplyText = ([_object] call LBS_fnc_getCurrentSupplyString);
			_unitCost = LBSConstructionUnitCost;

			with uiNamespace do {
				LBSUILocalSupplyObject = _object;

				LBS_UI_updateCrateListBoxes = {
					params["_object"];
					if (isNil "_object") exitWith {};
					if (_object isEqualTo objNull) exitWith {};
					[_object] spawn {
						params ["_object"];
						waitUntil {!isNil "LBSNearbySupplyCratesListBoxCtrl"};

						comment "Update Nearby Crates ListBox";
						_allCrates = [];
						with missionNamespace do {_allCrates = [getPos _object,LBSAllConstructionSuppliesClassNames,["Reammobox_F"],LBSMaxDistanceNearbyCrates] call LBS_fnc_getNearFilteredObjects;};
						_allCrates = (_allCrates-[_object]);
						_nearbyCrates = [];
						lbClear LBSNearbySupplyCratesListBoxCtrl;
						{
							_className = typeOf _x;
							_displayName = getText(configFile >> "CfgVehicles" >> _className >> "displayName");
							_crateSupplyCount = (_x getVariable "LBSCurrentSupplyCount");
							_isCrate = (_x getVariable "LBSisCrate");
							if (!isNil "_crateSupplyCount" && !isNil "_isCrate") then 
							{
								_index = LBSNearbySupplyCratesListBoxCtrl lbAdd (_displayName + " | " + str _crateSupplyCount + " SP");
								_nearbyCrates pushBack [_x,_crateSupplyCount,_className];
							};
						} foreach _allCrates;
						_object setVariable ["LBSNearbyCrates",_nearbyCrates];
					};
					_supplyText = (with missionNamespace do {[_object] call LBS_fnc_getCurrentSupplyString});
					LBSSupplyOptionsSupplyTextCtrl ctrlSetStructuredText parseText ("<t size='2' font='RobotoCondensedBold' align='center' shadow='0'>"+_supplyText+"</t>");
				};

				LBS_UI_loadCrate = {
					if (isNil "LBSUILocalSupplyObject") exitWith {};
					if (LBSUILocalSupplyObject isEqualTo objNull) exitWith {};
					_currentSupply = LBSUILocalSupplyObject getVariable "LBSCurrentSupplyCount";
					_maxSupply = LBSUILocalSupplyObject getVariable "LBSMaxSupplyCount";
					if (isNil "_maxSupply") exitWith {};
					if (isNil "_currentSupply") exitWith {};
					
					_index = lbCurSel LBSNearbySupplyCratesListBoxCtrl;
					_allCrateData = LBSUILocalSupplyObject getVariable "LBSNearbyCrates";
					if (_index == -1) exitWith {};
					if (isNil "_allCrateData") exitWith {};
					_data = _allCrateData select _index;
					_crateObj = _data select 0;
					_crateSupplyCount = _data select 1;
					_crateClassName = _data select 2;
					if (isNil "_crateSupplyCount" || isNil "_crateClassName") exitWith {};

					comment "Update current supplies";
					_deleteCrate = true;
					_remainderSupply = 0;
					if (_currentSupply >= _maxSupply) exitWith {with missionNamespace do {["NOT ENOUGH ROOM IN THE CONTAINER!",3,46] call LBS_fnc_systemMessage;};};
					_newSupplyCount = (_currentSupply + _crateSupplyCount);
					if (_newSupplyCount > _maxSupply) then 
					{
						_deleteCrate = false;
						_remainderSupply = (_newSupplyCount - _maxSupply);
						_newSupplyCount = _maxSupply;
					};
					if (isNil "_newSupplyCount") exitWith {};
					_supplyObj = LBSUILocalSupplyObject;
					with missionNamespace do {[[_supplyObj,_newSupplyCount],{(_this select 0) setVariable ["LBSCurrentSupplyCount",(_this select 1),true];}] call LBS_fnc_RE_Server;};

					comment "handle crate removal";
					if (_deleteCrate) then {deleteVehicle _crateObj;}
					else {with missionNamespace do {[[_crateObj,_remainderSupply],{(_this select 0) setVariable ["LBSCurrentSupplyCount",(_this select 1),true];}] call LBS_fnc_RE_Server;};};
				};

				LBS_UI_unloadAllSupplies = {
					if (isNil "LBSUILocalSupplyObject") exitWith {};
					if (LBSUILocalSupplyObject isEqualTo objNull) exitWith {};
					_currentSupply = LBSUILocalSupplyObject getVariable "LBSCurrentSupplyCount";
					if (isNil "_currentSupply") exitWith {};
					_constructionUnit = nil;
					with missionNamespace do {_constructionUnit = [ASLToAGL(getPosASL player),LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;};
					if (isNil "_constructionUnit") exitWith {with missionNamespace do {["NO NEARBY CONSTRUCTION UNIT!",5,46] call LBS_fnc_systemMessage;};};
					_conCurrentSupply = _constructionUnit getVariable "LBSCurrentSupplyCount";
					if (isNil "_conCurrentSupply") exitWith {};

					comment "Update current supplies";
					with missionNamespace do {[[_constructionUnit,(_conCurrentSupply + _currentSupply)],{(_this select 0) setVariable ["LBSCurrentSupplyCount",(_this select 1),true];}] call LBS_fnc_RE_Server;};
					_supplyObj = LBSUILocalSupplyObject;
					with missionNamespace do {[[_supplyObj,0],{(_this select 0) setVariable ["LBSCurrentSupplyCount",(_this select 1),true];}] call LBS_fnc_RE_Server;};
				};

				_RscStructuredText_1100 = _display ctrlCreate ["RscStructuredText", 1100];
				_RscStructuredText_1100 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>SUPPLIES IN THIS CONTAINER</t>";
				_RscStructuredText_1100 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.71 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1100 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1100 ctrlCommit 0;

				LBSSupplyOptionsSupplyTextCtrl = _display ctrlCreate ["RscStructuredText", 1101];
				LBSSupplyOptionsSupplyTextCtrl ctrlSetStructuredText parseText ("<t size='2' font='RobotoCondensedBold' align='center' shadow='0'>"+_supplyText+"</t>");
				LBSSupplyOptionsSupplyTextCtrl ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.738 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.056 * safezoneH];
				LBSSupplyOptionsSupplyTextCtrl ctrlSetBackgroundColor [0,0,0,0.25];
				LBSSupplyOptionsSupplyTextCtrl ctrlCommit 0;

				_RscButtonMenu_2400 = _display ctrlCreate ["RscButtonMenu", 2400];
				_RscButtonMenu_2400 ctrlSetText "BUILD CONSTRUCTION UNIT";
				_RscButtonMenu_2400 ctrlSetPosition [0.506562 * safezoneW + safezoneX, 0.738 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.056 * safezoneH];
				_RscButtonMenu_2400 ctrlSetTooltip ("A new base can't be started close to another base. You also need "+(str _unitCost)+" SP minimum.");
				_RscButtonMenu_2400 ctrlCommit 0;
				_RscButtonMenu_2400 ctrlAddEventHandler ["ButtonDown",{
					if !(vehicle player isEqualTo player) exitWith {["CANT PLACE ASSETS WHILE INSIDE VEHICLE",5,46] call LBS_fnc_systemMessage;};

					_nearbyConUnits = [getPos player,LBSAllConstructionUnitClassNames,["Reammobox_F"],LBSMaxPlaceDistance*2] call LBS_fnc_getNearFilteredObjects;
					if (count _nearbyConUnits > 0) exitWith {["YOU'RE TOO CLOSE TO AN EXISTING BASE!",7,46] call LBS_fnc_systemMessage;};

					_supplyCount = ([getpos player,LBSMaxDistanceNearbyCrates] call LBS_fnc_getNearbySupplyCount);
					if (_supplyCount >= LBSConstructionUnitCost) then 
					{
						closeDialog 1;
						[[selectRandom LBSAllConstructionUnitClassNames,LBSConstructionUnitCost,false,30,"SMALL"]] call LBS_fnc_placeAsset;
					}
					else {["NOT ENOUGH NEARBY SUPPLIES TO START A BASE!",5,46] call LBS_fnc_systemMessage;};
				}];

				_RscStructuredText_1102 = _display ctrlCreate ["RscStructuredText", 1102];
				_RscStructuredText_1102 ctrlSetStructuredText parseText ("<t size='0.85' font='PuristaMedium'>START A NEW BASE ("+(str _unitCost)+" SP)</t>");
				_RscStructuredText_1102 ctrlSetPosition [0.506562 * safezoneW + safezoneX, 0.71 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1102 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1102 ctrlCommit 0;

				LBSNearbySupplyCratesListBoxCtrl = _display ctrlCreate ["RscListbox", 1500];
				LBSNearbySupplyCratesListBoxCtrl ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.276 * safezoneH + safezoneY, 0.44625 * safezoneW, 0.378 * safezoneH];
				LBSNearbySupplyCratesListBoxCtrl ctrlCommit 0;

				_RscStructuredText_1102 = _display ctrlCreate ["RscStructuredText", 1102];
				_RscStructuredText_1102 ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium'>NEARBY SUPPLY CRATES</t>";
				_RscStructuredText_1102 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.248 * safezoneH + safezoneY, 0.44625 * safezoneW, 0.028 * safezoneH];
				_RscStructuredText_1102 ctrlSetBackgroundColor [0,0,0,1];
				_RscStructuredText_1102 ctrlCommit 0;

				_RscButtonMenu_2400 = _display ctrlCreate ["RscButtonMenu", 2400];
				_RscButtonMenu_2400 ctrlSetText "TAKE SUPPLIES";
				_RscButtonMenu_2400 ctrlSetPosition [0.276875 * safezoneW + safezoneX, 0.654 * safezoneH + safezoneY, 0.223125 * safezoneW, 0.042 * safezoneH];
				_RscButtonMenu_2400 ctrlSetTooltip "Take supplies from the selected crate";
				_RscButtonMenu_2400 ctrlCommit 0;
				_RscButtonMenu_2400 ctrlAddEventHandler ["ButtonDown",{
					with uinamespace do {
						call LBS_UI_loadCrate;
						[] spawn {sleep 0.125; [LBSUILocalSupplyObject] call LBS_UI_updateCrateListBoxes;};

						comment "Prevent Spam";
						[(_this select 0)] spawn {
							params["_ctrl"]; 
							_ctrl ctrlEnable false;
							sleep 0.5;
							if (_ctrl isEqualTo controlNull) exitWith {};
							_ctrl ctrlEnable true;
						};
					};
				}];

				_RscStructuredText_2401 = _display ctrlCreate ["RscButtonMenu", 2401];
				_RscStructuredText_2401 ctrlSetText "UNLOAD ALL SUPPLIES";
				_RscStructuredText_2401 ctrlSetPosition [0.506562 * safezoneW + safezoneX, 0.654 * safezoneH + safezoneY, 0.216562 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_2401 ctrlSetTooltip "Unload all supplies into the nearest base";
				_RscStructuredText_2401 ctrlCommit 0; 
				_RscStructuredText_2401 ctrlAddEventHandler ["ButtonDown",{
					with uinamespace do {
						call LBS_UI_unloadAllSupplies;
						[LBSUILocalSupplyObject] call LBS_UI_updateCrateListBoxes;
					};
				}];

				_RscStructuredText_1139 = _display ctrlCreate ["RscStructuredText", 1139];
				_RscStructuredText_1139 ctrlSetStructuredText parseText "<t size='1.5' font='PuristaBold' align='center' shadow='1'>SUPPLY CONTAINER</t>";
				_RscStructuredText_1139 ctrlSetPosition [0.335938 * safezoneW + safezoneX, 0.192 * safezoneH + safezoneY, 0.321562 * safezoneW, 0.042 * safezoneH];
				_RscStructuredText_1139 ctrlSetBackgroundColor [0,0,0,0];
				_RscStructuredText_1139 ctrlCommit 0;

				[_object] call LBS_UI_updateCrateListBoxes;
			};
		};

		LBS_fnc_placeAsset = {
			params["_assetData",["_maxDistanceFromPlayer",LBSPlaceMaxDistanceFromPlayer]];
			
			if (isNil "_assetData") exitWith 
			{
				["INVALID DATA PROVIDED!",5,46] call LBS_fnc_systemMessage;
			};
			if (_assetData isEqualTo []) exitWith 
			{
				["EMPTY DATA PROVIDED!",5,46] call LBS_fnc_systemMessage;
			};

			[_assetData,_maxDistanceFromPlayer] spawn {
				params["_assetData","_maxDistanceFromPlayer"];
				_localObject = (_assetData select 0) createVehicleLocal [0,0,0];
				_attachedObject = (_assetData select 0) createVehicleLocal [0,0,0];

				if (isNil "_attachedObject") exitWith 
				{
					["INVALID CLASS NAME PROVIDED!",5,46] call LBS_fnc_systemMessage;
				};

				[true] call LBS_fnc_enableLBSHUD;
				[true,false] call LBS_fnc_enableControlHints;
				LBSPlaceModeEnabled = true;

				_localObject setVariable ["AssetData",_assetData];
				_localObject allowDamage false;
				hideObject _localObject;
				_attachedObject attachTo [_localObject,[0,0,0]];
				_attachedObject disableCollisionWith player;
				LBSLocalPreviewObject = _localObject;

				sleep 0.1;

				["LBSPreviewPlacement","onEachFrame",{
					params ["_localObject","_maxDistanceFromPlayer"];
					_ins = lineIntersectsSurfaces [ 
						AGLToASL positionCameraToWorld [0,0,0],  
						AGLToASL positionCameraToWorld [0,0,_maxDistanceFromPlayer],
						player,
						((attachedObjects _localObject) select 0)
					]; 
					if (count _ins == 0) exitWith {_localObject setPosASL [0,0,0]}; 
					_posASL = (_ins select 0 select 0);
					_vectorUp = (_ins select 0 select 1);
					_localObject setPosASL _posASL;
					_localObject setVectorUp _vectorUp;

					if(LBSRotateRightHeld || LBSRotateLeftHeld) then 
					{
						_neg = 1;
						if (LBSRotateRightHeld) then {_neg = 1;};
						if (LBSRotateLeftHeld) then {_neg = -1;};
						_dirAndUp = ([
							[vectorDirVisual _localObject, vectorUpVisual _localObject],
							(LBSPlaceRotationSpeed*diag_deltaTime)*_neg,
							0,
							0
						] call BIS_fnc_transformVectorDirAndUp);
						_localObject setVectorDirAndUp _dirAndUp;
					};

					comment "Update Attached Object";
					{
						_x attachTo [_localObject,[0,0,0]];
					} foreach attachedObjects _localObject;
				},[_localObject,_maxDistanceFromPlayer]] call BIS_fnc_addStackedEventHandler;
				[missionNameSpace, "LBSAssetPlaceStarted",[_localObject,_assetData]] call BIS_fnc_callScriptedEventHandler;
			};
		};
	
		LBS_fnc_cancelPlaceAsset = {
			params["_localObject"];
			if (_localObject isEqualTo objNull) exitWith {["LBSPreviewPlacement","onEachFrame"] call BIS_fnc_removeStackedEventHandler;};
			{deleteVehicle _x;} foreach attachedObjects _localObject;
			_localObject spawn {sleep 1; deleteVehicle _this;};
			[false,true] call LBS_fnc_enableControlHints;
			["LBSPreviewPlacement","onEachFrame"] call BIS_fnc_removeStackedEventHandler;
			[missionNameSpace, "LBSAssetPlaceCancelled",[]] call BIS_fnc_callScriptedEventHandler;
		};
		
		LBS_fnc_buildAsset = {
			params["_localObject","_assetData"];

			comment "Create the object";
			_object = createVehicle [_assetData select 0,getPos _localObject,[],0,"CAN_COLLIDE"];
			_object allowDamage false;
			_object setPosWorld getPosWorld _localObject;
			_object setVectorDirAndUp [vectorDir _localObject,vectorUp _localObject];
			if (_object isKindOf "StaticWeapon") then {_object enableWeaponDisassembly false;};

			[missionNameSpace, "LBSAssetBuildStarted",[_object,_assetData]] call BIS_fnc_callScriptedEventHandler;

			comment "Start Building Animation";
			[[_object,_assetData,getPosWorld _object,vectorDir _localObject,vectorUp _localObject],{
				_this spawn LBS_fnc_spawnBuildAssetAnimation;
			}] call LBS_fnc_RE_Server;
			[_object,_assetData] spawn 
			{
				params ["_object","_assetData"];
				sleep (_assetData select 3);
				[missionNameSpace, "LBSAssetBuildDone",_this] call BIS_fnc_callScriptedEventHandler;
			};

			comment "set is building variable";
			_constructionUnit = [getPos player,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
			if (!(isNil "_constructionUnit")) then {[[_constructionUnit,true],{(_this select 0) setVariable ["LBSisUnitUnderConstruction",(_this select 1),true];}] call LBS_fnc_RE_Server;};
		};

		LBS_fnc_cancelBuildAsset = {
			params["_object"];

			[missionNameSpace, "LBSAssetBuildCancelled",[]] call BIS_fnc_callScriptedEventHandler;
		};
		
		LBS_fnc_addActionToSupply = {
			params["_object"];

			_actionIndex = _object addAction
			[
				"<t size='1' font='PuristaSemibold' align='center' valign='middle'>Open Container</t>",	
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					if (LBSPlaceModeEnabled) exitWith {["CANT OPEN SUPPLY CONTAINER WHILE PLACING ASSET",5,46] call LBS_fnc_systemMessage;};
					_arguments call LBS_fnc_openSupplyOptionsTerminal;
				},
				[_object],		
				10,			
				true,		
				true,		
				"",			
				"true", 	
				7.5,		
				false,		
				"",			
				""			
			];
			_object spawn {waitUntil{sleep 0.1; !alive _this}; removeAllActions _this;};
		};

		LBS_fnc_addActionToConstructionUnit = {
			params["_object"];
			
			_actionIndex = _object addAction
			[
				"<t size='1' font='PuristaSemibold' align='center' valign='middle'>Access Construction Unit</t>",
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					if (LBSPlaceModeEnabled) exitWith {["CANT OPEN CONSTRUCTION UNIT WHILE PLACING ASSET",5,46] call LBS_fnc_systemMessage;};
					_closestConUnit = [getPos player,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
					if (isNil "_closestConUnit") then {_closestConUnit = objNull;};
					_isAuth = [player,_closestConUnit] call LBS_fnc_isPlayerOwner;
					if (_isAuth) then {_arguments call LBS_fnc_openConstructionOptionsTerminal;}
					else {["ONLY THE BASE OWNER CAN ACCESS THIS",5,46] call LBS_fnc_systemMessage;};
				},
				[_object],		
				10,			
				true,		
				true,		
				"",			
				"true", 	
				7.5,		
				false,		
				"",			
				""			
			];
			_object spawn {waitUntil{sleep 0.1; !alive _this}; removeAllActions _this;};
		};

		LBS_fnc_addActionToOpenBuildOptions = {
			params["_object"];

			_actionIndex = _object addAction
			[
				"<t size='1' font='PuristaSemibold' align='center' valign='middle'>Open Build Options</t>",	
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					if (LBSPlaceModeEnabled) exitWith {["CANT OPEN BUILD OPTIONS WHILE PLACING ASSET",5,46] call LBS_fnc_systemMessage;};
					if !(vehicle player isEqualTo player) exitWith {["CANT OPEN BUILD OPTIONS WHILE INSIDE VEHICLE",5,46] call LBS_fnc_systemMessage;};
					_arguments call LBS_fnc_openBuildOptionsTerminal;
				},
				[_object],		
				10,			
				true,		
				true,		
				"",			
				"true", 	
				7.5,		
				false,		
				"",			
				""			
			];
			[_actionIndex] call LBS_fnc_registerPlayerAddAction;
			_object spawn {waitUntil{sleep 0.1; !alive _this}; removeAllActions _this;};
		};

		LBS_fnc_addActionToDeleteObjects = {
			params["_object"];

			_actionIndex = _object addAction
			[
				"<t color='#d90000' size='1' font='PuristaSemibold' align='center' valign='middle'>Delete Object (Look at It)</t>",	
				{
					params ["_target", "_caller", "_actionId", "_arguments"];
					if (LBSPlaceModeEnabled) exitWith {["CANT DELETE WHILE PLACING ASSET",5,46] call LBS_fnc_systemMessage;};
					if !(vehicle player isEqualTo player) exitWith {["CANT DELETE WHILE INSIDE VEHICLE",5,46] call LBS_fnc_systemMessage;};
					if (typeOf cursorObject in LBSAllConstructionUnitClassNames) exitWith {["SORRY BUDDY, YOU CANT DELETE THIS BASE",5,46] call LBS_fnc_systemMessage;};
					_closestConUnit = [getPos player,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;

					_objectToDelete = cursorObject;
					if (cursorObject isEqualTo objNull) then 
					{
						_helipad = nearestObject [getPosASL player,"Helipad_base_F"];
						_objectToDelete = if (_helipad distance player < 2.5) then {_helipad} else {objNull};
					};

					if (_objectToDelete isEqualTo objNull) exitWith {};

					_isAsset = _objectToDelete getVariable "IsLBSAsset";
					if (isNil "_isAsset") exitWith {};

					if (isNil "_closestConUnit") then {_closestConUnit = objNull;};
					_isAuth = [player,_closestConUnit] call LBS_fnc_isPlayerAuthorized;
					if (_isAuth) then {deleteVehicle _objectToDelete;} 
					else {["YOU DONT HAVE PERMISSION TO DELETE OBJECTS HERE",5,46] call LBS_fnc_systemMessage;};
				},
				[_object],		
				9,			
				true,		
				true,		
				"",			
				"true", 	
				7.5,		
				false,		
				"",			
				""			
			];
			[_actionIndex] call LBS_fnc_registerPlayerAddAction;
			_object spawn {waitUntil{sleep 0.1; !alive _this}; removeAllActions _this;};
		};

		LBS_fnc_registerPlayerAddAction = {
			params["_actionIndex"];
			_actionIndexList = (player getVariable "LBSActionIndexList");
			if(isNil "_actionIndexList") then {_actionIndexList = []};
			_actionIndexList pushBack _actionIndex; 
			player setVariable ["LBSActionIndexList",_actionIndexList];
		};
		
		LBS_fnc_enableControlHints = {
			params ["_enable","_enable2"];
			with uiNamespace do {
				_display = (findDisplay 46);
				if(isNil "LBSPlaceControlsCtrl") then {LBSPlaceControlsCtrl = controlNull;};
				if(isNil "LBSPlaceCursorCtrl") then {LBSPlaceCursorCtrl = controlNull;};
				if(isNil "LBSModeControlsCtrl") then {LBSModeControlsCtrl = controlNull;};
				if (LBSPlaceControlsCtrl isEqualTo controlNull) then {
					LBSPlaceControlsCtrl = _display ctrlCreate ["RscStructuredText", 1100];
					LBSPlaceControlsCtrl ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium' align='left'>Q - ROTATE LEFT<br/>E - ROTATE RIGHT<br/>LMB - PLACE<br/>RMB - CANCEL</t>";
					LBSPlaceControlsCtrl ctrlSetPosition [0.2375 * safezoneW + safezoneX, 0.43 * safezoneH + safezoneY, 0.1575 * safezoneW, 0.112 * safezoneH];
					LBSPlaceControlsCtrl ctrlSetBackgroundColor [-1,-1,-1,0];
					LBSPlaceControlsCtrl ctrlCommit 0;
				};
				if (LBSPlaceCursorCtrl isEqualTo controlNull) then {
					LBSPlaceCursorCtrl = _display ctrlCreate ["RscPicture", 1200];
					LBSPlaceCursorCtrl ctrlSetText "\a3\ui_f\data\igui\cfg\cursors\mission_ca.paa";
					LBSPlaceCursorCtrl ctrlSetPosition [0.486875 * safezoneW + safezoneX, 0.444 * safezoneH + safezoneY, 0.02625 * safezoneW, 0.056 * safezoneH];
					LBSPlaceCursorCtrl ctrlCommit 0;
				};
				LBSPlaceControlsCtrl ctrlShow _enable;
				LBSPlaceCursorCtrl ctrlShow _enable;

				if (LBSModeControlsCtrl isEqualTo controlNull) then {
					LBSModeControlsCtrl = _display ctrlCreate ["RscStructuredText", 1101];
					LBSModeControlsCtrl ctrlSetStructuredText parseText "<t size='0.85' font='PuristaMedium' align='left'>WINDOWS KEY - EXIT BUILD MODE</t>";
					LBSModeControlsCtrl ctrlSetPosition [0.2375 * safezoneW + safezoneX, 0.794 * safezoneH + safezoneY, 0.249375 * safezoneW, 0.056 * safezoneH];
					LBSModeControlsCtrl ctrlSetBackgroundColor [-1,-1,-1,0];
					LBSModeControlsCtrl ctrlCommit 0;
				};
				LBSModeControlsCtrl ctrlShow _enable2;
			};
		};

		LBS_fnc_enable3DUIRendering = {
			params["_enable"];

			if !(isNil "LBS3DUIRenderingEventHandle") then {removeMissionEventHandler ["Draw3D",LBS3DUIRenderingEventHandle];};

			if(_enable) then 
			{
				LBS3DUIRenderingEventHandle = addMissionEventHandler ["Draw3D",{
					with uiNamespace do {
						{
							_position = _x modelToWorldVisual (_x selectionPosition "head_axis");
							_distance = (player) distance (_position);
							_textSize = 0.02825;
							_text = [_x] call (missionNamespace getVariable "LBS_fnc_getCurrentSupplyString");
							_isCrate = _x getVariable "LBSisCrate";
							if (isNil "_isCrate") then {_isCrate = false;};
							_imageSize = [0.5,0.5];

							_dif = (LBSMaxDistanceIcon3D-_distance);
							_alpha = (_dif/LBSMaxDistanceIcon3D);
							if(_x == cursorTarget) then {_alpha = 1;};
							_color = [1,1,1,_alpha];

							if(_x != cursorTarget) then {_text = "";};

							if (_alpha == 0) exitWith {};

							if !(_isCrate) then {
								drawIcon3D ["\A3\ui_f\data\IGUI\Cfg\simpleTasks\types\box_ca.paa",_color,_position, _imageSize select 0,_imageSize select 1, 0,(_text), 2, _textSize, "RobotoCondensedBold","center",false];
							}
							else {
								_imageSize = [1,1];
								drawIcon3D ["\a3\ui_f_curator\data\Displays\RscDisplayCurator\modeModules_ca.paa",_color,_position, _imageSize select 0,_imageSize select 1, 0,(_text), 2, _textSize, "RobotoCondensedBold","center",false];
							};
						} forEach (missionNamespace getVariable "LBSNearbyLocalSupplyObjects");
					};
					with uiNamespace do {
						_somethingLoading = false;
						{
							_isLoading = _x getVariable "LBSisUnitUnderConstruction";
							_position = _x modelToWorldVisual (_x selectionPosition "head_axis");
							_distance = (player) distance (_position);
							_textSize = 0.02825;
							_text = "Construction Unit";
							_imageSize = [0.65,0.65];
							_angle = 90;

							_dif = (LBSMaxDistanceIcon3D-_distance);
							_alpha = (_dif/LBSMaxDistanceIcon3D);
							if(_x == cursorTarget) then {_alpha = 1;};
							_color = [1,1,1,_alpha];

							if (_alpha == 0) exitWith {};

							if !(isNil "_isLoading") then 
							{
								if (_isLoading) exitWith {};
								drawIcon3D ["\a3\ui_f\data\IGUI\cfg\actions\repair_ca.paa",_color,_position, _imageSize select 0,_imageSize select 1, _angle,(_text), 2, _textSize, "RobotoCondensedBold","center",false];
							};
							
							if !(isNil "_isLoading") then 
							{
								if !(_isLoading) exitWith {};
								_somethingLoading = true;
								_imageSize = [1,1];
								drawIcon3D ["\a3\modules_f_curator\Data\portraitRespawnTickets_ca.paa",_color,_position, _imageSize select 0,_imageSize select 1, LBSLast3DLoadingAngle,_text, 2, _textSize, "RobotoCondensedBold","center",false];
							};
						} forEach (missionNamespace getVariable "LBSNearbyLocalConstructionUnits");

						if (_somethingLoading) then 
						{
							LBSLast3DLoadingAngle = (LBSLast3DLoadingAngle - (LBS3DLoadAngleSpeed*diag_deltaTime));
							if (LBSLast3DLoadingAngle <= -360) then {LBSLast3DLoadingAngle = 0;};
						};
					};
				}];
			};
		};

		LBS_fnc_enableLBSHUD = {
			params["_enable"];

			if (LBSHUDEnabled isEqualTo _enable) exitWith {};
			LBSHUDEnabled = _enable;
			[_enable] call LBS_fnc_enable3DUIRendering;

			_actionIndexList = (player getVariable "LBSActionIndexList");
			if(!isNil "_actionIndexList") then {{player removeAction _x;} foreach _actionIndexList;player setVariable ["LBSActionIndexList",[]];};

			if(_enable) then 
			{
				[false,true] call LBS_fnc_enableControlHints;
				[missionNamespace,"LBSHUDEnabled",[]] call BIS_fnc_callScriptedEventHandler;
				[player] call LBS_fnc_addActionToOpenBuildOptions;
				[player]call LBS_fnc_addActionToDeleteObjects;
			}
			else 
			{
				if (LBSPlaceModeEnabled) then {[LBSLocalPreviewObject] call LBS_fnc_cancelPlaceAsset; LBSPlaceModeEnabled = false;};
				[false,false] call LBS_fnc_enableControlHints;
				[missionNamespace,"LBSHUDDisabled",[]] call BIS_fnc_callScriptedEventHandler;
			};
		};

		comment "Start System";
		call LBS_fnc_startMainLoop;
		[] spawn 
		{
			["Logistical Building System Online! (LBS v1.4)",8,46] call LBS_fnc_systemMessage;
			sleep 4;
			["Toggle Build Mode With Windows Key",8,46] call LBS_fnc_systemMessage;
		};

		comment "Input Events";
		(findDisplay 46) displayAddEventHandler ["KeyDown", {
			0 = switch (_this select 1) do 
			{
				case LBSOpenTerminalKey: {};
				case LBSRotateRightKey: {LBSRotateRightHeld = true};
				case LBSRotateLeftKey: {LBSRotateLeftHeld = true;};
			};
		}];
		(findDisplay 46) displayAddEventHandler ["KeyUp", {
			0 = switch (_this select 1) do 
			{
				case LBSOpenTerminalKey: 
				{
					if !((findDisplay 37) isEqualTo displayNull) exitWith {};
					[!LBSHUDEnabled] call LBS_fnc_enableLBSHUD;
				};
				case LBSRotateRightKey: {LBSRotateRightHeld = false;};
				case LBSRotateLeftKey: {LBSRotateLeftHeld = false;};
			};
		}];
		(findDisplay 46) displayAddEventHandler ["MouseButtonDown",{
			params ["_displayorcontrol", "_button", "_xPos", "_yPos", "_shift", "_ctrl", "_alt"];
			if (_button == 0) then {[missionNameSpace, "LBSLeftMouseClick",[]] call BIS_fnc_callScriptedEventHandler;}
			else {[missionNameSpace, "LBSRightMouseClick",[]] call BIS_fnc_callScriptedEventHandler;};
		}];

		comment "Generic Events";
		player addEventHandler ["GetInMan",{
			if (LBSPlaceModeEnabled) then {
				LBSPlaceModeEnabled = false;
				[LBSLocalPreviewObject] call LBS_fnc_cancelPlaceAsset;
			};
		}];

		comment "Scripted Input Events";
		[missionNamespace, "LBSLeftMouseClick",{
			if (LBSPlaceModeEnabled) then 
			{
				_assetData = (LBSLocalPreviewObject getVariable "AssetData");
				_isConUnit = ((typeOf LBSLocalPreviewObject) in LBSAllConstructionUnitClassNames);
				_constructionUnit = [getPos player,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
				if (isNil "_constructionUnit") then {_constructionUnit = objNull;};

				_isLoading = _constructionUnit getVariable "LBSisUnitUnderConstruction";
				_isParallelAllowed = _constructionUnit getVariable "LBSParallelBuildUpgradeAllowed";
				if (isNil "_isLoading") then {_isLoading = false;};
				if (isNil "_isParallelAllowed") then {_isParallelAllowed = false;};
				if (_isLoading && !_isParallelAllowed) exitWith {["THE CONSTRUCTION UNIT IS ALREADY BUILDING SOMETHING!",5,46] call LBS_fnc_systemMessage;};

				if ((vectorMagnitude getPos LBSLocalPreviewObject) <= 25) exitWith {["UNKNOWN POSITION. TRY AGAIN!",5,46] call LBS_fnc_systemMessage;};	

				_TransSuccess = [_assetData,_constructionUnit] call LBS_fnc_Transaction;
				if (!_TransSuccess) exitWith {["NOT ENOUGH NEARBY SUPPLIES TO BUILD!",5,46] call LBS_fnc_systemMessage;};

				[LBSLocalPreviewObject,_assetData] call LBS_fnc_buildAsset;

				comment "Cancel Placing";
				if (_isConUnit) then 
				{
					LBSPlaceModeEnabled = false;
					[LBSLocalPreviewObject] call LBS_fnc_cancelPlaceAsset;
				};
			};
		}] call BIS_fnc_addScriptedEventHandler;
		[missionNamespace, "LBSRightMouseClick",{
			if (LBSPlaceModeEnabled) then 
			{
				[LBSLocalPreviewObject] call LBS_fnc_cancelPlaceAsset;
				LBSPlaceModeEnabled = false;
			};
		}] call BIS_fnc_addScriptedEventHandler;

		comment "Scripted Generic Events";
		[missionNamespace, "LBSTerminalOpened",{
			if (LBSHUDEnabled) then 
			{
				[false,false] call LBS_fnc_enableControlHints;
			};
		}] call BIS_fnc_addScriptedEventHandler;
		[missionNamespace, "LBSTerminalClosed",{
			if (LBSHUDEnabled) then 
			{
				[false,true] call LBS_fnc_enableControlHints;
			};
		}] call BIS_fnc_addScriptedEventHandler;
		[missionNamespace, "LBSAssetPlaceStarted",{
			player action ["SwitchWeapon", player, player, -1];
		}] call BIS_fnc_addScriptedEventHandler;
		[missionNamespace, "LBSAssetBuildStarted",{
			_object = _this select 0;
			if ((typeof _object) in LBSAllConstructionUnitClassNames) then 
			{
				comment "initialize construction unit";
				_isInit = _x getVariable "LBSInitUnit";
				if (isNil "_isInit") then 
				{
					[[_object,player],{
						params["_object","_player"];
						_object setVariable ["LBSInitUnit",true,true];
						_object setVariable ["LBSisCrate",false,true];
						_object setVariable ["LBSMaxDistanceSuppliesUpgradeTier",1,true];
						_object setVariable ["LBSMaxDistancePlacingUpgradeTier",1,true];
						_object setVariable ["LBSParallelBuildUpgradeAllowed",false,true];
						_object setVariable ["LBSisUnitUnderConstruction",false,true];
						_object setVariable ["LBSCurrentSupplyCount",0,true];
						_object setVariable ["LBSTrustedPlayers",[],true];
						_object setVariable ["LBSOwnerUID",getPlayerUID _player,true];
						[_object,false] remoteExec ["allowDamage",0,_object];

						comment "Event when con unit is deleted";
						_object addEventHandler ["Deleted", {
							params ["_entity"];
							_radiusMarker = _entity getVariable "LBSBaseRadiusMarker";
							_nameMarker = _entity getVariable "LBSBaseNameMarker";
							_name = "";
							if !(isNil "_radiusMarker") then {deleteMarker _radiusMarker;};
							if !(isNil "_nameMarker") then {_name = markerText _nameMarker; deleteMarker _nameMarker;};
							[(_name + " HAS BEEN DESTROYED!"),10,46]  remoteExec ["LBS_fnc_systemMessage",0];
						}];
					}] call LBS_fnc_RE_Server;

					["YOU NOW OWN A NEW BASE!",10,46] call LBS_fnc_systemMessage;
				};
			};
		}] call BIS_fnc_addScriptedEventHandler;
	}] remoteExec ["Spawn",0,"JIP_ID_LBSClient"];
	}] call LBS_fnc_RE;

	comment "Server Code";
	[[],{
		if (!isServer) exitWith {};
		if!(isNil "isLBSAllowedServer") exitWith {["Logistical Building System already running on server..."] remoteExec ["systemChat",0];};
		isLBSAllowedServer = true;

		comment "Important Server Variables";
		LBSMaxDistanceSuppliesUpgradeTiers = [100,150,200,250];
		LBSMaxDistancePlacingUpgradeTiers = [100,150,200,250];
		LBSTierUpgradeCost = 1000;
		LBSConstructionUnitCost = 4000;
		LBSCostMultiplier = 1;
		LBSMaxSupplyMultiplier = 2;
		LBSVehiclesStartWithSupply = true;
		LBSMaxPlaceDistance = (LBSMaxDistancePlacingUpgradeTiers select ((count LBSMaxDistancePlacingUpgradeTiers)-1));
		LBSAllConstructionSuppliesClassNames = [];
		publicVariable "LBSMaxDistanceSuppliesUpgradeTiers";
		publicVariable "LBSMaxDistancePlacingUpgradeTiers";
		publicVariable "LBSMaxPlaceDistance";
		publicVariable "LBSConstructionUnitCost";
		publicVariable "LBSTierUpgradeCost";

		LBSAllConstructionUnitClassNames = [
			"Land_RepairDepot_01_green_F",
			"Land_RepairDepot_01_civ_F",
			"Land_RepairDepot_01_tan_F"
		];
		publicVariable "LBSAllConstructionUnitClassNames";
		
		comment "[className,maxSupply,isCrate]";
		LBSAllConstructionSuppliesDictionary = [
			["VirtualReammoBox_F",750,true],
			["Box_IND_AmmoVeh_F",750,true],
			["Box_East_AmmoVeh_F",750,true],
			["Box_EAF_AmmoVeh_F",750,true],
			["Box_NATO_AmmoVeh_F",750,true],
			["CargoNet_01_box_F",500,true],
			["I_CargoNet_01_ammo_F",500,true],
			["O_CargoNet_01_ammo_F",500,true],
			["C_IDAP_CargoNet_01_supplies_F",500,true],
			["I_E_CargoNet_01_ammo_F",500,true],
			["B_CargoNet_01_ammo_F",500,true],
			["Land_Pod_Heli_Transport_04_ammo_F",2000,false],
			["Land_Pod_Heli_Transport_04_box_F",3500,false],
			["Land_Pod_Heli_Transport_04_repair_F",2000,false],
			["B_Slingload_01_Ammo_F",2000,false],
			["B_Slingload_01_Cargo_F",3500,false],
			["B_Slingload_01_Repair_F",2000,false],
			["O_T_Truck_03_ammo_ghex_F",2500,false],
			["O_T_Truck_03_repair_ghex_F",2500,false],
			["O_T_Truck_02_Ammo_F",2000,false],
			["O_T_Truck_02_Box_F",2000,false],
			["O_Truck_03_ammo_F",2500,false],
			["O_Truck_03_repair_F",2500,false],
			["O_Truck_02_Ammo_F",2000,false],
			["O_Truck_02_box_F",2000,false],
			["I_Truck_02_ammo_F",2000,false],
			["I_Truck_02_box_F",2000,false],
			["B_T_Truck_01_ammo_F",2500,false],
			["B_T_Truck_01_box_F",5000,false],
			["B_T_Truck_01_Repair_F",2500,false],
			["B_Truck_01_ammo_F",2500,false],
			["B_Truck_01_box_F",5000,false],
			["B_Truck_01_Repair_F",2500,false],
			["I_E_Truck_02_Ammo_F",2000,false],
			["I_E_Truck_02_Box_F",2000,false],
			["C_Truck_02_box_F",2000,false],
			["O_MRAP_02_F",500,false],
			["O_T_MRAP_02_ghex_F",500,false],
			["B_MRAP_01_F",500,false],
			["B_T_MRAP_01_F",500,false],
			["I_MRAP_03_F",500,false],
			["I_E_Van_02_transport_F",750,false],
			["I_C_Van_02_transport_F",750,false],
			["C_Van_02_transport_F",750,false],
			["C_IDAP_Van_02_transport_F",750,false],
			["O_G_Van_02_transport_F",750,false],
			["B_G_Van_02_transport_F",750,false],
			["I_G_Van_02_transport_F",750,false],
			["C_IDAP_Van_02_vehicle_F",1500,false],
			["C_Van_02_service_F",1500,false],
			["C_Van_02_vehicle_F",1500,false],
			["I_E_Van_02_vehicle_F",1500,false],
			["O_G_Van_02_vehicle_F",1500,false],
			["B_G_Van_02_vehicle_F",1500,false],
			["I_G_Van_02_vehicle_F",1500,false],
			["C_Van_01_box_F",1000,false],
			["I_E_Offroad_01_comms_F",500,false],
			["C_Offroad_01_comms_F",500,false],
			["I_E_Offroad_01_covered_F",500,false],
			["C_Offroad_01_covered_F",500,false],
			["I_Heli_Transport_02_F",1750,false],
			["C_IDAP_Heli_Transport_02_F",1750,false],
			["B_Heli_Transport_03_F",1500,false],
			["B_Heli_Transport_03_unarmed_F",1750,false],
			["O_T_VTOL_02_infantry_dynamicLoadout_F",2500,false],
			["O_T_VTOL_02_infantry_F",2500,false],
			["O_T_VTOL_02_infantry_ghex_F",2500,false],
			["O_T_VTOL_02_infantry_grey_F",2500,false],
			["O_T_VTOL_02_infantry_hex_F",2500,false],
			["O_T_VTOL_02_vehicle_F",5000,false],
			["O_T_VTOL_02_vehicle_ghex_F",5000,false],
			["O_T_VTOL_02_vehicle_grey_F",5000,false],
			["O_T_VTOL_02_vehicle_hex_F",5000,false],
			["O_T_VTOL_02_vehicle_dynamicLoadout_F",5000,false],
			["O_Heli_Transport_04_ammo_F",1750,false],
			["O_Heli_Transport_04_box_F",3000,false],
			["O_Heli_Transport_04_repair_F",1750,false],
			["B_T_VTOL_01_infantry_F",7500,false],
			["B_T_VTOL_01_vehicle_F",10000,false],
			["B_T_VTOL_01_infantry_olive_F",7500,false],
			["B_T_VTOL_01_infantry_blue_F",7500,false],
			["B_T_VTOL_01_vehicle_blue_F",10000,false],
			["B_T_VTOL_01_vehicle_olive_F",10000,false],
			["B_APC_Tracked_01_CRV_F",1000,false],
			["B_Truck_01_cargo_F",2500,false],
			["B_T_Truck_01_cargo_F",2500,false],
			["O_G_Offroad_01_repair_F",500,false],
			["I_G_Offroad_01_repair_F",500,false],
			["B_G_Offroad_01_repair_F",500,false],
			["C_G_Offroad_01_repair_F",500,false],
			["Land_Cargo40_military_green_F",999999,true]
		];

		comment "Update Max Supply by Multiplier Value";
		{
			_assetData = _x;
			_newCost = (_assetData select 1)*LBSMaxSupplyMultiplier;
			_assetData set [1,_newCost];
			LBSAllConstructionSuppliesDictionary set [_foreachIndex,_assetData];
		} foreach LBSAllConstructionSuppliesDictionary;
		publicVariable "LBSAllConstructionSuppliesDictionary";

		comment "Fill LBSAllConstructionSuppliesClassNames Array";
		{_className = _x select 0; LBSAllConstructionSuppliesClassNames pushBack _className;} foreach LBSAllConstructionSuppliesDictionary;
		publicVariable "LBSAllConstructionSuppliesClassNames";

		comment "[className,cost,requiresContructionUnit,buildTime,effectType]";
		LBSAllAssetsDictionary = [
			["Land_BagBunker_Large_F",750,true,30,"MEDIUM"],
			["Land_BagBunker_Small_F",250,true,30,"SMALL"],
			["Land_BagBunker_Tower_F",500,true,30,"SMALL"],
			["Land_BagBunker_01_large_green_F",750,true,30,"MEDIUM"],
			["Land_BagBunker_01_small_green_F",250,true,15,"SMALL"],
			["Land_HBarrier_01_tower_green_F",500,true,30,"SMALL"],
			["Land_Cargo_HQ_V1_F",1750,true,60,"MEDIUM"],
			["Land_Cargo_HQ_V3_F",1750,true,60,"MEDIUM"],
			["Land_Medevac_HQ_V1_F",1750,true,60,"MEDIUM"],
			["Land_Research_HQ_F",1750,true,60,"MEDIUM"],
			["Land_Cargo_HQ_V4_F",1750,true,60,"MEDIUM"],
			["Land_Cargo_Patrol_V1_F",1000,true,45,"SMALL"],
			["Land_Cargo_Patrol_V3_F",1000,true,45,"SMALL"],
			["Land_Cargo_Patrol_V4_F",1000,true,45,"SMALL"],
			["Land_Cargo_Tower_V1_F",2500,true,120,"MEDIUM"],
			["Land_Cargo_Tower_V3_F",2500,true,120,"MEDIUM"],
			["Land_Cargo_Tower_V4_F",2500,true,120,"MEDIUM"],
			["Land_HBarrier_5_F",200,true,5,"TINY"],
			["Land_HBarrier_3_F",150,true,5,"TINY"],
			["Land_HBarrier_Big_F",300,true,15,"TINY"],
			["Land_HBarrierWall_corridor_F",200,true,15,"TINY"],
			["Land_HBarrierWall_corner_F",175,true,15,"TINY"],
			["Land_HBarrierWall6_F",300,true,15,"TINY"],
			["Land_HBarrierWall4_F",250,true,15,"TINY"],
			["Land_HBarrierTower_F",500,true,30,"SMALL"],
			["Land_HBarrier_01_line_3_green_F",150,true,5,"TINY"],
			["Land_HBarrier_01_line_5_green_F",200,true,5,"TINY"],
			["Land_HBarrier_01_big_4_green_F",300,true,15,"TINY"],
			["Land_HBarrier_01_wall_corridor_green_F",200,true,15,"TINY"],
			["Land_HBarrier_01_wall_corner_green_F",175,true,15,"TINY"],
			["Land_HBarrier_01_wall_6_green_F",300,true,15,"TINY"],
			["Land_HBarrier_01_wall_4_green_F",250,true,15,"TINY"],
			["Land_HBarrier_01_big_tower_green_F",500,true,30,"SMALL"],
			["Land_Cargo_House_V3_F",500,true,30,"SMALL"],
			["Land_Cargo_House_V1_F",500,true,30,"SMALL"],
			["Land_Medevac_house_V1_F",500,true,30,"SMALL"],
			["Land_Research_house_V1_F",500,true,30,"SMALL"],
			["Land_Cargo_House_V4_F",500,true,30,"SMALL"],
			["CargoPlaftorm_01_brown_F",500,true,30,"SMALL"],
			["CargoPlaftorm_01_green_F",500,true,30,"SMALL"],
			["CargoPlaftorm_01_jungle_F",500,true,30,"SMALL"],
			["Land_i_Barracks_V1_F",3250,true,180,"LARGE"],
			["Land_i_Barracks_V2_F",3250,true,180,"LARGE"],
			["Land_u_Barracks_V2_F",3250,true,180,"LARGE"],
			["Land_Barracks_01_dilapidated_F",3250,true,180,"LARGE"],
			["Land_Barracks_01_grey_F",3250,true,180,"LARGE"],
			["Land_Barracks_01_camo_F",3250,true,180,"LARGE"],
			["Land_MilOffices_V1_F",3000,true,180,"LARGE"],
			["BlockConcrete_F",350,true,30,"SMALL"],
			["Land_RampConcrete_F",350,true,30,"SMALL"],
			["Land_RampConcreteHigh_F",350,true,30,"SMALL"],
			["Dirthump_2_F",350,true,30,"SMALL"],
			["Dirthump_3_F",375,true,30,"SMALL"],
			["Dirthump_4_F",400,true,30,"SMALL"],
			["Dirthump_1_F",325,true,30,"SMALL"],
			["Land_Rampart_F",325,true,30,"SMALL"],
			["Land_DragonsTeeth_01_4x2_new_F",250,true,15,"TINY"],
			["Land_Bunker_F",300,true,30,"SMALL"],
			["Land_wpp_Turbine_V1_F",1000,true,120,"MEDIUM"],
			["Land_wpp_Turbine_V2_F",1000,true,120,"MEDIUM"],
			["Land_CamoConcreteWall_01_l_4m_v2_F",300,true,5,"TINY"],
			["Land_Mil_WallBig_4m_F",300,true,5,"TINY"],
			["Land_ConcreteWall_01_m_8m_F",300,true,5,"TINY"],
			["Land_Hedge_01_s_4m_F",100,true,5,"TINY"],
			["Land_Hedge_01_s_2m_F",50,true,5,"TINY"],
			["Land_ConcreteWall_01_l_8m_F",300,true,5,"TINY"],
			["Land_Concrete_SmallWall_8m_F",300,true,5,"TINY"],
			["Land_New_WiredFence_10m_F",300,true,5,"TINY"],
			["Land_Mil_WiredFence_F",300,true,5,"TINY"],
			["Land_Mil_WiredFence_Gate_F",300,true,5,"TINY"],
			["Land_Razorwire_F",300,true,5,"TINY"],
			["Land_CamoConcreteWall_01_l_4m_v1_F",200,true,5,"TINY"],
			["Land_ConcreteWall_01_m_4m_F",200,true,5,"TINY"],
			["Land_ConcreteWall_01_l_4m_F",200,true,5,"TINY"],
			["Land_Concrete_SmallWall_4m_F",200,true,5,"TINY"],
			["Land_New_WiredFence_5m_F",200,true,5,"TINY"],
			["Land_PlasticNetFence_01_long_F",200,true,5,"TINY"],
			["Land_BarGate_F",250,true,5,"TINY"],
			["Land_RoadBarrier_01_F",250,true,5,"TINY"],
			["Land_NetFence_02_m_gate_v2_F",250,true,5,"TINY"],
			["Land_ConcreteWall_01_m_gate_F",250,true,5,"TINY"],
			["Land_ConcreteWall_01_l_gate_F",250,true,5,"TINY"],
			["Land_Mil_WallBig_Corner_F",125,true,5,"TINY"],
			["Land_ConcreteWall_01_m_pole_F",125,true,5,"TINY"],
			["Land_CncBarrier_F",125,true,5,"TINY"],
			["Land_CncBarrierMedium_F",125,true,5,"TINY"],
			["Land_CncBarrier_stripes_F",125,true,5,"TINY"],
			["Land_CncWall1_F",125,true,5,"TINY"],
			["Land_PlasticNetFence_01_short_F",125,true,5,"TINY"],
			["Land_CncBarrierMedium4_F",400,true,5,"TINY"],
			["Land_CncWall4_F",400,true,5,"TINY"],
			["Land_spp_Mirror_F",275,true,5,"TINY"],
			["Land_spp_Panel_F",275,true,5,"TINY"],
			["Land_SolarPanel_3_F",275,true,5,"TINY"],
			["Land_SolarPanel_1_F",150,true,5,"TINY"],
			["Land_TTowerSmall_1_F",275,true,5,"TINY"],
			["Land_Dome_Big_F",4000,true,180,"LARGE"],
			["Land_Dome_Small_F",2000,true,90,"MEDIUM"],
			["Land_Airport_Tower_F",3500,true,120,"MEDIUM"],
			["Land_Airport_02_controlTower_F",3500,true,120,"MEDIUM"],
			["Land_LampAirport_F",1000,true,30,"SMALL"],
			["Land_LampHalogen_F",400,true,30,"TINY"],
			["Land_LampHarbour_F",400,true,30,"TINY"],
			["Land_LampStreet_F",350,true,30,"TINY"],
			["Land_Bunker_01_big_F",2000,true,45,"MEDIUM"],
			["Land_Bunker_01_HQ_F",2000,true,45,"MEDIUM"],
			["Land_Bunker_01_small_F",1000,true,30,"MEDIUM"],
			["Land_Bunker_01_tall_F",2000,true,45,"MEDIUM"],
			["Land_Bunker_01_blocks_3_F",300,true,5,"TINY"],
			["Land_Bunker_01_blocks_1_F",300,true,5,"TINY"],
			["Land_Radar_F",4000,true,180,"LARGE"],
			["Land_Radar_Small_F",1000,true,45,"MEDIUM"],
			["Land_MobileRadar_01_radar_F",1000,true,45,"MEDIUM"],
			["Land_Airport_01_controlTower_F",1500,true,60,"MEDIUM"],
			["Land_GuardTower_01_F",750,true,30,"MEDIUM"],
			["Land_GuardTower_02_F",500,true,30,"SMALL"],
			["Land_Hangar_F",3500,true,180,"LARGE"],
			["Land_TentHangar_V1_F",1750,true,120,"MEDIUM"],
			["Land_Airport_01_hangar_F",3000,true,180,"LARGE"],
			["Land_Airport_02_terminal_F",3000,true,120,"LARGE"],
			["Land_Radar_01_HQ_F",3000,true,120,"LARGE"],
			["Land_PierLadder_F",300,true,10,"TINY"],
			["Land_GH_Stairs_F",300,true,10,"TINY"],
			["Land_PortableLight_double_F",100,false,5,"TINY"],
			["Land_PortableLight_single_F",100,false,5,"TINY"],
			["Land_Portable_generator_F",100,false,5,"TINY"],
			["Land_PortableWeatherStation_01_olive_F",100,false,5,"TINY"],
			["Land_PortableGenerator_01_F",100,false,5,"TINY"],
			["Land_PortableGenerator_01_black_F",100,false,5,"TINY"],
			["Land_PortableGenerator_01_sand_F",100,false,5,"TINY"],
			["Land_PortableServer_01_black_F",100,false,5,"TINY"],
			["Land_PortableServer_01_olive_F",100,false,5,"TINY"],
			["Land_PortableServer_01_sand_F",100,false,5,"TINY"],
			["Land_PortableLight_02_double_black_F",100,false,5,"TINY"],
			["Land_PortableLight_02_double_olive_F",100,false,5,"TINY"],
			["Land_PortableLight_02_double_sand_F",100,false,5,"TINY"],
			["Land_PortableLight_02_double_yellow_F",100,false,5,"TINY"],
			["Land_PortableLight_02_quad_black_F",100,false,5,"TINY"],
			["Land_PortableLight_02_quad_olive_F",100,false,5,"TINY"],
			["Land_PortableLight_02_quad_sand_F",100,false,5,"TINY"],
			["Land_PortableLight_02_quad_yellow_F",100,false,5,"TINY"],
			["Land_PortableLight_02_single_folded_black_F",100,false,5,"TINY"],
			["Land_PortableLight_02_single_folded_olive_F",100,false,5,"TINY"],
			["Land_PortableLight_02_single_folded_yellow_F",100,false,5,"TINY"],
			["Land_PortableLight_02_single_folded_sand_F",100,false,5,"TINY"],
			["Land_EngineCrane_01_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_4drawers_black_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_7drawers_black_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_bookcase_black_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_closed_black_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_medical_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_7drawers_sand_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_bookcase_sand_F",100,false,5,"TINY"],
			["Land_PortableCabinet_01_closed_sand_F",100,false,5,"TINY"],
			["Land_PortableDesk_01_black_F",100,false,5,"TINY"],
			["Land_PortableDesk_01_olive_F",100,false,5,"TINY"],
			["Land_PortableDesk_01_sand_F",100,false,5,"TINY"],
			["Land_CncShelter_F",150,false,5,"TINY"],
			["Land_Obstacle_Bridge_F",150,false,5,"TINY"],
			["Land_Obstacle_Climb_F",150,false,5,"TINY"],
			["Land_Obstacle_Crawl_F",150,false,5,"TINY"],
			["Land_Obstacle_Pass_F",150,false,5,"TINY"],
			["Land_Obstacle_Ramp_F",150,false,5,"TINY"],
			["Land_Obstacle_RunAround_F",150,false,5,"TINY"],
			["Land_Target_Pistol_01_F",150,false,5,"TINY"],
			["Land_Target_Single_01_F",150,false,5,"TINY"],
			["Land_Target_Line_01_F",150,false,5,"TINY"],
			["Land_Target_Line_PaperTargets_01_F",150,false,5,"TINY"],
			["Land_CanvasCover_02_F",125,false,7.5,"TINY"],
			["Land_IRMaskingCover_02_F",125,false,7,5,"TINY"],
			["Land_CanvasCover_01_F",150,false,10,"TINY"],
			["Land_IRMaskingCover_01_F",150,false,10,"TINY"],
			["CamoNet_INDP_F",100,false,5,"TINY"],
			["CamoNet_wdl_F",100,false,5,"TINY"],
			["CamoNet_ghex_F",100,false,5,"TINY"],
			["CamoNet_BLUFOR_F",100,false,5,"TINY"],
			["CamoNet_INDP_open_F",125,false,7.5,"TINY"],
			["CamoNet_BLUFOR_open_F",125,false,7.5,"TINY"],
			["CamoNet_OPFOR_open_F",125,false,7.5,"TINY"],
			["CamoNet_wdl_open_F",125,false,7.5,"TINY"],
			["CamoNet_ghex_open_F",125,false,7.5,"TINY"],
			["CamoNet_INDP_big_F",175,false,10,"TINY"],
			["CamoNet_BLUFOR_big_F",175,false,10,"TINY"],
			["CamoNet_OPFOR_big_F",175,false,10,"TINY"],
			["CamoNet_wdl_big_F",175,false,10,"TINY"],
			["CamoNet_ghex_big_F",175,false,10,"TINY"],
			["Land_DeconTent_01_yellow_F",300,false,30,"TINY"],
			["Land_DeconTent_01_white_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_digital_closed_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_brownhex_closed_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_MTP_closed_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_CSAT_greenhex_generic_inner_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_NATO_tropic_generic_inner_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_wdl_generic_inner_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_aaf_generic_inner_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_CSAT_brownhex_generic_inner_F",300,false,30,"TINY"],
			["Land_MedicalTent_01_NATO_generic_inner_F",300,false,30,"TINY"],
			["Land_HBarrier_1_F",100,false,0.25,"TINY"],
			["Land_HBarrier_01_line_1_green_F",100,false,0.25,"TINY"],
			["Land_CzechHedgehog_01_new_F",200,false,1,"TINY"],
			["Land_BagFence_Corner_F",50,false,0.25,"TINY"],
			["Land_BagFence_End_F",25,false,0.25,"TINY"],
			["Land_BagFence_Long_F",100,false,0.25,"TINY"],
			["Land_BagFence_Round_F",75,false,0.25,"TINY"],
			["Land_BagFence_Short_F",50,false,0.25,"TINY"],
			["Land_SandbagBarricade_01_half_F",100,false,0.25,"TINY"],
			["Land_SandbagBarricade_01_F",175,false,0.25,"TINY"],
			["Land_SandbagBarricade_01_hole_F",200,false,0.25,"TINY"],
			["Land_BagFence_01_corner_green_F",50,false,0.25,"TINY"],
			["Land_BagFence_01_end_green_F",25,false,0.25,"TINY"],
			["Land_BagFence_01_long_green_F",100,false,0.25,"TINY"],
			["Land_BagFence_01_round_green_F",75,false,0.25,"TINY"],
			["Land_BagFence_01_short_green_F",50,false,0.25,"TINY"],
			["B_HMG_01_F",400,false,0.25,"TINY"],
			["B_HMG_01_high_F",450,false,0.25,"TINY"],
			["B_GMG_01_F",500,false,0.25,"TINY"],
			["B_GMG_01_high_F",550,false,0.25,"TINY"],
			["B_Static_Designator_01_F",100,false,0.25,"TINY"],
			["B_static_AA_F",750,false,0.25,"TINY"],
			["B_static_AT_F",600,false,0.25,"TINY"],
			["B_G_HMG_02_F",300,false,0.25,"TINY"],
			["B_G_HMG_02_high_F",350,false,0.25,"TINY"],
			["O_static_AA_F",750,false,0.25,"TINY"],
			["O_static_AT_F",600,false,0.25,"TINY"],
			["O_Static_Designator_02_F",100,false,0.25,"TINY"],
			["I_HMG_02_F",400,false,0.25,"TINY"],
			["I_HMG_02_high_F",450,false,0.25,"TINY"],
			["I_static_AA_F",750,false,0.25,"TINY"],
			["I_static_AT_F",600,false,0.25,"TINY"],
			["I_E_Static_AT_F",600,false,0.25,"TINY"],
			["I_E_Static_AA_F",750,false,0.25,"TINY"],
			["ShootingPos_F",100,false,0.25,"TINY"],
			["Land_CampingChair_V2_F",100,false,0.25,"TINY"],
			["Land_CampingChair_V2_white_F",100,false,0.25,"TINY"],
			["Land_CampingTable_F",100,false,0.25,"TINY"],
			["Land_CampingTable_small_F",100,false,0.25,"TINY"],
			["Land_CampingTable_small_white_F",100,false,0.25,"TINY"],
			["Land_CampingTable_white_F",100,false,0.25,"TINY"],
			["Land_ChairPlastic_F",100,false,0.25,"TINY"],
			["Land_CampingChair_V1_F",100,false,0.25,"TINY"],
			["Land_Sun_chair_F",100,false,0.25,"TINY"],
			["Land_Sun_chair_green_F",100,false,0.25,"TINY"],
			["Land_Sunshade_F",100,false,0.25,"TINY"],
			["Land_Sunshade_01_F",100,false,0.25,"TINY"],
			["Land_Sunshade_03_F",100,false,0.25,"TINY"],
			["Land_Sunshade_04_F",100,false,0.25,"TINY"],
			["Land_Sunshade_02_F",100,false,0.25,"TINY"],
			["MapBoard_altis_F",100,false,0.25,"TINY"],
			["Land_MapBoard_Enoch_F",100,false,0.25,"TINY"],
			["MapBoard_Malden_F",100,false,0.25,"TINY"],
			["MapBoard_stratis_F",100,false,0.25,"TINY"],
			["MapBoard_Tanoa_F",100,false,0.25,"TINY"],
			["MapBoard_seismic_F",100,false,0.25,"TINY"],
			["Land_MapBoard_F",100,false,0.25,"TINY"],
			["Land_Campfire_F",100,false,0.25,"TINY"],
			["Campfire_burning_F",100,false,0.25,"TINY"],
			["Land_TentA_F",100,false,0.25,"TINY"],
			["Land_TentDome_F",100,false,0.25,"TINY"],
			["Land_TentSolar_01_bluewhite_F",100,false,0.25,"TINY"],
			["Land_TentSolar_01_olive_F",100,false,0.25,"TINY"],
			["Land_TentSolar_01_redwhite_F",100,false,0.25,"TINY"],
			["Land_TentSolar_01_sand_F",100,false,0.25,"TINY"],
			["Land_Sleeping_bag_brown_F",100,false,0.25,"TINY"],
			["Land_Sleeping_bag_blue_F",100,false,0.25,"TINY"],
			["Land_Sleeping_bag_F",100,false,0.25,"TINY"],
			["FirePlace_burning_F",50,false,0.25,"TINY"],
			["Land_FirePlace_F",50,false,0.25,"TINY"],
			["Land_Camping_Light_F",50,false,0.25,"TINY"],
			["Land_Camping_Light_off_F",50,false,0.25,"TINY"],
			["Land_HelipadCircle_F",50,false,0.25,"TINY"],
			["Land_HelipadCivil_F",50,false,0.25,"TINY"],
			["Land_HelipadRescue_F",50,false,0.25,"TINY"],
			["Land_HelipadSquare_F",50,false,0.25,"TINY"]
		];

		comment "Update Cost by Multiplier Value";
		{
			_assetData = _x;
			_newCost = (_assetData select 1)*LBSCostMultiplier;
			_assetData set [1,_newCost];
			LBSAllAssetsDictionary set [_foreachIndex,_assetData];
		} foreach LBSAllAssetsDictionary;
		publicVariable "LBSAllAssetsDictionary";

		LBS_fnc_findSupplyObjectData = {
			params["_className"];
			_data = [];
			_index = LBSAllConstructionSuppliesDictionary findif {(_className isEqualTo (_x select 0))};
			if (_index != -1) then {_data = (LBSAllConstructionSuppliesDictionary select _index);};
			_data
		};
		publicVariable "LBS_fnc_findSupplyObjectData";

		LBS_fnc_findAssetObjectData = {
			params["_className"];
			_data = [];
				_index = LBSAllAssetsDictionary findif {(_className isEqualTo (_x select 0))};
				if (_index != -1) then {_data = (LBSAllAssetsDictionary select _index);};
			_data
		};
		publicVariable "LBS_fnc_findAssetObjectData";

		LBS_fnc_getClosestObjectOfClassNames = {
			params["_center","_range","_classNames"];
			((nearestObjects [_center,_classNames, _range]) select 0)
		};
		publicVariable "LBS_fnc_getClosestObjectOfClassNames";

		LBS_fnc_spawnConstructionSoundEffects = {
			params["_position","_length","_type"];

			_sounds = switch (_type) do {
				case "TINY": {
					{
						params["_position","_range","_length","_volume"];
						playSound3D ["a3\sounds_f\sfx\ui\vehicles\vehicle_repair.wss", player,false,_position,_volume,2,_range];
					}
				};
				case "SMALL": {
					{
						params["_position","_range","_length","_volume"];
						playSound3D ["a3\sounds_f\vehicles\air\cas_01\gear_up.wss", player,false,_position,_volume,0.5,_range];
						playSound3D ["a3\sounds_f_jets\Buildings\Carrier\deflector_up_1.wss", player,false,_position,_volume,1.5,_range];

						sleep 6;

						playSound3D ["a3\sounds_f\vehicles\air\cas_01\gear_up.wss", player,false,_position,_volume,0.5,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,1,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,1,_range];

						sleep 7;

						playSound3D ["a3\sounds_f_jets\Buildings\Carrier\deflector_up_1.wss", player,false,_position,_volume,1.5,_range];
						playSound3D ["a3\sounds_f\sfx\ui\vehicles\vehicle_repair.wss", player,false,_position,_volume,1,_range];

						sleep 6;

						playSound3D ["a3\sounds_f\vehicles\air\cas_01\gear_up.wss", player,false,_position,_volume,0.5,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,1,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,1,_range];

						sleep 7;

						playSound3D ["a3\sounds_f\vehicles\air\cas_01\gear_up.wss", player,false,_position,_volume,0.5,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carpenter\orange_carpentershop_tools_02.wss", player,false,_position,_volume,0.1,_range];
						playSound3D ["a3\sounds_f\sfx\ui\vehicles\vehicle_repair.wss", player,false,_position,_volume,1,_range];
					}
				};
				case "MEDIUM": {
					{
						params["_position","_range","_length","_volume"];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_09.wss", player,false,_position,_volume,1,_range];
						playSound3D ["a3\sounds_f_jets\Buildings\Carrier\deflector_up_1.wss", player,false,_position,_volume,0.75,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_08.wss", player,false,_position,_volume,1,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,1,_range];

						for "_i" from 2 to (round (_length/7)) do {
							sleep 7;
						
							if (_i mod 2 == 0) then {
								playSound3D ["a3\sounds_f\environment\structures\windturbine\windturbine.wss", player,false,_position,_volume,0.75,_range];
								playSound3D ["a3\sounds_f_jets\Buildings\Carrier\deflector_up_1.wss", player,false,_position,_volume,0.75,_range];
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_08.wss", player,false,_position,_volume,1,_range];
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,1,_range];
							}
							else 
							{
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,1,_range];
								playSound3D ["a3\sounds_f\vehicles\air\cas_01\gear_up.wss", player,false,_position,_volume,0.1,_range];
								playSound3D ["a3\sounds_f\sfx\ui\vehicles\vehicle_repair.wss", player,false,_position,_volume,0.1,_range];
								playSound3D ["a3\sounds_f\sfx\ui\vehicles\vehicle_repair.wss", player,false,_position,_volume,0.1,_range];
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_09.wss", player,false,_position,_volume,1,_range];
							};
						};

						sleep 7;

						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_08.wss", player,false,_position,_volume,2,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carpenter\orange_carpentershop_tools_02.wss", player,false,_position,_volume,0.5,_range];
					}
				};
				case "LARGE": {
					{
						params["_position","_range","_length","_volume"];
						
						for "_i" from 1 to (round (_length/15)) do {
							if (_i mod 2 == 0) then 
							{		
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,0.25,_range];
								playSound3D ["a3\sounds_f_jets\Buildings\Carrier\deflector_up_1.wss", player,false,_position,_volume,0.1,_range];
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_08.wss", player,false,_position,_volume,0.25,_range];
								playSound3D ["a3\sounds_f\vehicles\armor\bobcat\bobcat_plow_up_01.wss", player,false,_position,_volume,0.25,_range];
							}
							else 
							{
								playSound3D ["a3\sounds_f\sfx\ui\vehicles\vehicle_repair.wss", player,false,_position,_volume,0.25,_range];
								playSound3D ["a3\sounds_f_jets\Buildings\Carrier\deflector_up_1.wss", player,false,_position,_volume,0.1,_range];
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_09.wss", player,false,_position,_volume,0.25,_range];
								playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_07.wss", player,false,_position,_volume,0.25,_range];
							};
							sleep 15;
						};

						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carrepairshop\orange_carrepairshop_amb_08.wss", player,false,_position,_volume,1,_range]; 
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carpenter\orange_carpentershop_tools_02.wss", player,false,_position,_volume,0.1,_range];
						playSound3D ["a3\sounds_f_orange\missionsfx\pastambiences\carpenter\orange_carpentershop_tools_02.wss", player,false,_position,_volume,0.1,_range];
					}
				};
			};
			[_position,300,_length,1] spawn _sounds;
		};
		publicVariable "LBS_fnc_spawnConstructionSoundEffects";

		LBS_fnc_spawnConstructionParticleEffects = {
			params["_position","_length","_type"];

			_particleObjects = [];
			_particleObjects = switch (_type) do {
				case "TINY": {
					[]
				};
				case "SMALL": {
					_effects = [];

					_sourceEffect = createVehicle ["#particlesource",_position,[],0,"CAN_COLLIDE"]; 
					[_sourceEffect,"HouseDestrSmokeLongSmall"] remoteExec ["setParticleClass",0,_sourceEffect];
					_effects pushBack _sourceEffect;

					for "_i" from 0 to 2 do {
						_sourceEffect = createVehicle ["#particlesource",_position,[],0,"CAN_COLLIDE"]; 
						[_sourceEffect,"DeminingExplosiveDirt"] remoteExec ["setParticleClass",0,_sourceEffect];
						_effects pushBack _sourceEffect;
					};
		
					_effects
				};
				case "MEDIUM": {
					_effects = [];

					_sourceEffect = createVehicle ["#particlesource",_position,[],0,"CAN_COLLIDE"]; 
					[_sourceEffect,"HouseDestrSmokeLongMed"] remoteExec ["setParticleClass",0,_sourceEffect];
					_effects pushBack _sourceEffect;

					for "_i" from 0 to 2 do {
						_sourceEffect = createVehicle ["#particlesource",_position,[],0,"CAN_COLLIDE"]; 
						[_sourceEffect,"DeminingExplosiveDirt"] remoteExec ["setParticleClass",0,_sourceEffect];
						_effects pushBack _sourceEffect;
					};

					_effects
				};
				case "LARGE": {
					_effects = [];

					_sourceEffect = createVehicle ["#particlesource",_position,[],0,"CAN_COLLIDE"]; 
					[_sourceEffect,"BombDust"] remoteExec ["setParticleClass",0,_sourceEffect];
					_effects pushBack _sourceEffect;

					_sourceEffect = createVehicle ["#particlesource",_position,[],0,"CAN_COLLIDE"]; 
					[_sourceEffect,"ExploRocksDark"] remoteExec ["setParticleClass",0,_sourceEffect];
					_effects pushBack _sourceEffect;

					_effects
				};
			};

			sleep _length;

			{deleteVehicle _x} foreach _particleObjects;
		};
		publicVariable "LBS_fnc_spawnConstructionParticleEffects";

		LBS_fnc_spawnBuildAssetAnimation = {
			params["_targetObject","_assetData","_worldPosition","_vectorDir","_vectorUp"];

			[getPosWorld _targetObject,_assetData select 3,_assetData select 4] spawn LBS_fnc_spawnConstructionParticleEffects;
			[getPosWorld _targetObject,_assetData select 3,_assetData select 4] spawn LBS_fnc_spawnConstructionSoundEffects;

			comment "Set Construction Unit Under Construction to false after correct time";
			_constructionUnit = [getPos _targetObject,LBSMaxPlaceDistance,LBSAllConstructionUnitClassNames] call LBS_fnc_getClosestObjectOfClassNames;
			if !(isNil "_constructionUnit") then {
				[_constructionUnit,_assetData select 3] spawn 
				{
					params ["_constructionUnit","_time"];
					sleep _time;
					if (!(isNil "_constructionUnit")) then {_constructionUnit setVariable ["LBSisUnitUnderConstruction",false,true];};
				};
			};

			_animID = ("BuildAnimation" + str round random 100000);
			[_animID,"onEachFrame",{
				params["_targetObject","_assetData","_startTime","_targetPosition","_targetDirAndUp","_animID"];

				private["_targetHeight","_buildSpeed","_startHeight"];
				_targetHeight = _targetPosition select 2;
				_buildSpeed = _assetData select 3;

				comment "Calculate model height";
				_bbr = boundingBoxReal _targetObject;
				_p1 = _bbr select 0;
				_p2 = _bbr select 1;
				_maxHeight = abs ((_p2 select 2) - (_p1 select 2));
				_startHeight = (_targetHeight-_maxHeight);

				_t1 = _startTime; 
				_t2 = _startTime + _buildSpeed;
				_currentHeight = linearConversion [_t1, _t2, time, _startHeight,_targetHeight];
				
				comment"hint  ((str _maxHeight)+' | '+(str _startHeight)+' | '+(str _targetHeight));"; 

				_targetObject setPosWorld [_targetPosition select 0,_targetPosition select 1,_currentHeight];
				_targetObject setVectorDirAndUp _targetDirAndUp;

				if (time > _t2) then {
					[_animID,"onEachFrame"] call BIS_fnc_removeStackedEventHandler;
					if (!(isNil "_targetObject")) then {_targetObject setVariable ["IsLBSAsset",true,true];};
					if (!(isNil "_targetObject") && ((typeof _targetObject) in LBSAllConstructionUnitClassNames)) then {_targetObject spawn {sleep 2; _this enableSimulationGlobal false;};};
				};
			},[_targetObject,_assetData,time,_worldPosition,[_vectorDir,_vectorUp],_animID]] call BIS_fnc_addStackedEventHandler;
		};
		publicVariable "LBS_fnc_spawnBuildAssetAnimation";

		LBS_fnc_systemMessage = {
			params["_message","_time","_displayNumber",["_image","\a3\modules_f_curator\Data\portraitObjective_ca.paa"]];
			with uiNamespace do {	
				if(isNil "LBSAllSystemMessageGroupControls") then {LBSAllSystemMessageGroupControls = [];};
				LBSLocalSystemMessageControls = [];

				_display = (findDisplay _displayNumber);
				_RscControlsGroup_2300 = _display ctrlCreate ["RscControlsGroupNoScrollbars", 2300];
				_RscControlsGroup_2300 ctrlSetPosition [-0.5 * safezoneW + safezoneX, ((0.15+(0.09*((count LBSAllSystemMessageGroupControls)))) * safezoneH + safezoneY), 0.223125 * safezoneW, 0.084 * safezoneH];
				_RscControlsGroup_2300 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscControlsGroup_2300;

				_RscPicture_1201 = _display ctrlCreate ["RscPicture", 1201,_RscControlsGroup_2300];
				_RscPicture_1201 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1201 ctrlSetPosition [0 * safezoneW, 0 * safezoneH, 0.216562 * safezoneW, 0.084 * safezoneH];
				_RscPicture_1201 ctrlSetTextColor [0,0,0,0.75];
				_RscPicture_1201 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1201;

				_RscPicture_1202 = _display ctrlCreate ["RscPicture", 1202,_RscControlsGroup_2300];
				_RscPicture_1202 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1202 ctrlSetPosition [0.216562 * safezoneW, 0 * safezoneH, 0.00525 * safezoneW, 0.014 * safezoneH];
				_RscPicture_1202 ctrlSetTextColor [0,0,0,1];
				_RscPicture_1202 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1202;

				_RscPicture_1203 = _display ctrlCreate ["RscPicture", 1203,_RscControlsGroup_2300];
				_RscPicture_1203 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1203 ctrlSetPosition [0.216562 * safezoneW, 0.014 * safezoneH, 0.00525 * safezoneW, 0.014 * safezoneH];
				_RscPicture_1203 ctrlSetTextColor [1,0.75,0,1];
				_RscPicture_1203 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1203;

				_RscPicture_1204 = _display ctrlCreate ["RscPicture", 1204,_RscControlsGroup_2300];
				_RscPicture_1204 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1204 ctrlSetPosition [0.216562 * safezoneW, 0.028 * safezoneH, 0.00525 * safezoneW, 0.014 * safezoneH];
				_RscPicture_1204 ctrlSetTextColor [0,0,0,1];
				_RscPicture_1204 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1204;

				_RscPicture_1205 = _display ctrlCreate ["RscPicture", 1205,_RscControlsGroup_2300];
				_RscPicture_1205 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1205 ctrlSetPosition [0.216562 * safezoneW, 0.042 * safezoneH, 0.00525 * safezoneW, 0.014 * safezoneH];
				_RscPicture_1205 ctrlSetTextColor [1,0.75,0,1];
				_RscPicture_1205 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1205;

				_RscPicture_1206 = _display ctrlCreate ["RscPicture", 1206,_RscControlsGroup_2300];
				_RscPicture_1206 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1206 ctrlSetPosition [0.216562 * safezoneW, 0.056 * safezoneH, 0.00525 * safezoneW, 0.014 * safezoneH];
				_RscPicture_1206 ctrlSetTextColor [0,0,0,1];
				_RscPicture_1206 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1206;

				_RscPicture_1207 = _display ctrlCreate ["RscPicture", 1207,_RscControlsGroup_2300];
				_RscPicture_1207 ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_RscPicture_1207 ctrlSetPosition [0.216562 * safezoneW, 0.07 * safezoneH, 0.00525 * safezoneW, 0.014 * safezoneH];
				_RscPicture_1207 ctrlSetTextColor [1,0.75,0,1];
				_RscPicture_1207 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1207;

				_RscPicture_1208 = _display ctrlCreate ["RscPicture", 1208,_RscControlsGroup_2300];
				_RscPicture_1208 ctrlSetText _image;
				_RscPicture_1208 ctrlSetPosition [0.00656251 * safezoneW, 0.014 * safezoneH, 0.0328125 * safezoneW, 0.056 * safezoneH];
				_RscPicture_1208 ctrlSetTextColor [1,1,1,1];
				_RscPicture_1208 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscPicture_1208;

				_RscStructuredText_1100 = _display ctrlCreate ["RscStructuredText", 1100,_RscControlsGroup_2300];
				_RscStructuredText_1100 ctrlSetStructuredText parseText ("<t size='0.9' font='PuristaSemiBold' align='center' valign='center' shadow='0'>"+_message+"</t>");
				_RscStructuredText_1100 ctrlSetPosition [0.0459375 * safezoneW,0.014 * safezoneH,0.170625 * safezoneW,0.056 * safezoneH];
				_RscStructuredText_1100 ctrlSetBackgroundColor [0,0,0,0];
				_RscStructuredText_1100 ctrlCommit 0;
				LBSLocalSystemMessageControls pushBack _RscStructuredText_1100;

				{_x ctrlSetFade 1; _x ctrlCommit 0;} forEach LBSLocalSystemMessageControls;

				LBSAllSystemMessageGroupControls pushBack LBSLocalSystemMessageControls;
				[missionNameSpace, "LBSSystemMessageAdded",[]] call BIS_fnc_callScriptedEventHandler;

				comment "Animate messages";
				[_RscControlsGroup_2300,_time,LBSLocalSystemMessageControls,count LBSAllSystemMessageGroupControls] spawn 
				{
					params["_ctrl","_time","_allControls","_count"];
					with uiNamespace do {
						{_x ctrlSetFade 0; _x ctrlCommit 0.5;} forEach _allControls;
						_ctrl ctrlSetPosition [0.0078125 * safezoneW + safezoneX, ((0.15+(0.09*(_count-1))) * safezoneH + safezoneY), 0.223125 * safezoneW, 0.084 * safezoneH];
						_ctrl ctrlCommit 0.5;
						sleep 0.5;
						sleep _time;
						{_x ctrlSetFade 1; _x ctrlCommit 0.5;} forEach _allControls;
						_ctrl ctrlSetPosition [-0.5 * safezoneW + safezoneX, ((0.15+(0.09*(_count-1))) * safezoneH + safezoneY), 0.223125 * safezoneW, 0.084 * safezoneH];
						_ctrl ctrlCommit 0.5;
						sleep 0.5;

						comment "Clean Up Messages";
						{ctrlDelete _x;} forEach _allControls;
						_badIndexes = [];
						{if((_x select 0) isEqualTo controlNull) then {_badIndexes pushBack _forEachIndex};} foreach LBSAllSystemMessageGroupControls;
						{LBSAllSystemMessageGroupControls deleteAt _x} foreach _badIndexes;
						LBSAllSystemMessageGroupControls = [LBSAllSystemMessageGroupControls-[controlNull]];
						[missionNameSpace, "LBSSystemMessageRemoved",[]] call BIS_fnc_callScriptedEventHandler;
					};
				};
			};
		};
		publicVariable "LBS_fnc_systemMessage";

		[] spawn {
			while {isLBSAllowedServer} do {
				comment "Initialize Objects";
				{
					_maxSupplies = _x getVariable "LBSMaxSupplyCount";
					_className = typeOf _x;

					comment "initialize supply";
					if(isNil "_maxSupplies") then 
					{
						_data = [_className] call LBS_fnc_findSupplyObjectData;
						if (_data isEqualTo []) exitWith {};
						_x setVariable ["LBSMaxSupplyCount",(_data select 1),true];
						_x setVariable ["LBSisCrate",(_data select 2),true];
						if ((_data select 2) || LBSVehiclesStartWithSupply) then {_x setVariable ["LBSCurrentSupplyCount",(_data select 1),true];}
						else {_x setVariable ["LBSCurrentSupplyCount",0,true];};
					};
					uisleep 0.05;
				} foreach vehicles;
				uisleep 1;
			};
		};

		comment "Events";
		addMissionEventHandler ["EntityKilled",{
			params ["_killed", "_killer", "_instigator"];
			if (typeOf _killed in LBSAllConstructionUnitClassNames) then {deleteVehicle _killed;};
		}];
	}] call LBS_fnc_RE;
}] call PUB_fnc_RE_Server;