comment "Example Military Tablet by: GamesByChris";
comment "Designed for 16:9 aspect ratios and will look weird on other aspect ratios, nothing I can do about it 😥";
comment "There's 2 custom events you can listen to for your own needs.";

comment "Example Custom Events";
[missionNameSpace, "TabletOpened",{systemChat "Example Event: Tablet Opened"}] call BIS_fnc_addScriptedEventHandler;
[missionNameSpace, "TabletClosed",{systemChat "Example Event: Tablet Closed"}] call BIS_fnc_addScriptedEventHandler;



with uinamespace do {
	createDialog "RscDisplayEmpty";
	_display = (findDisplay -1);

	comment "Create 3D Terminal Control";
	Terminal3DModelCtrl = _display ctrlCreate ["RscObject",-1];
	Terminal3DModelCtrl ctrlSetModel "a3\props_f_exp_a\military\equipment\tablet_02_f.p3d";
	Terminal3DModelCtrl ctrlSetModelScale 1.25;
	Terminal3DModelCtrl ctrlSetModelDirAndUp [[0,0,-1],[0,-1,0]];
	Terminal3DModelCtrl ctrlCommit 0;

	[missionNameSpace, "TabletOpened",[]] call BIS_fnc_callScriptedEventHandler;
	
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
	
	["TabletUpdate","onEachFrame",{
		params ["_ctrl3D"];
		_ctrl3D ctrlSetPosition [0.5, 0.25, 0.505];
		if(_ctrl3D isEqualTo controlNull) exitWith 
		{
			["TabletUpdate","onEachFrame"] call BIS_fnc_removeStackedEventHandler;
			[missionNameSpace, "TabletClosed",[]] call BIS_fnc_callScriptedEventHandler;
		};
	},[Terminal3DModelCtrl]] call BIS_fnc_addStackedEventHandler;

	comment "Total Screen Area";
	_ctrl = _display ctrlCreate ["RscButtonMenu",-1];
	_ctrl ctrlSetText "Total Screen Area";
	_ctrl ctrlSetPosition [0.277137 * safezoneW + safezoneX,0.19256 * safezoneH + safezoneY,0.44625 * safezoneW,0.602 * safezoneH];
	_ctrl ctrlcommit 0;
};