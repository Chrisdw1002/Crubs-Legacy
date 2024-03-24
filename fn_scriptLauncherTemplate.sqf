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

with uiNamespace do {SLTScriptDisplayName = "Script Launcher Template";};

SLT_fnc_enableScript = {
	comment "Paste script in here";

	hint "Enabled";
};

SLT_fnc_disableScript = {
	comment "Paste disable code in here";

	hint "Disabled";
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