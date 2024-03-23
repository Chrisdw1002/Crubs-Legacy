comment "Server Code";
{
	if !(isNil "isZombieSystemAllowed") exitWith {hint "Zombie System v3 Already Running!";};

	isZombieSystemAllowed = true;
	isRandomZombieSpawnAllowed = true;
	isZombieInfectionAllowed = true;

	AllZombieAgents = [];
	AllAlertedZombieAgents = [];
	AllInfectedClasses = ["C_man_p_beggar_F"];
	AllSafeZoneClasses = ["ProtectionZone_Invisible_F","ProtectionZone_F"];
	AllInfectionAntidotes = ["Antimalaricum","Item_AntidoteKit_01_F","Item_DeconKit_01_F","AntimalaricumVaccine"];
	AllInfectionCurables = ["DeconShower_01_F","DeconShower_02_F","Land_FirstAidKit_01_closed_F"];
	AllInfectionMedication = ["Antibiotic","Bandage"];
	AllZombieSafeZones = [];
	AllKnownAboutTargets = [];
	AllCivilianClasses = [];
	SafeZoneRadius = 25;
	ZombieInfectionChance = 15;
	ZombieMaxSpottingRadius = 150;
	ZombieMaxDetectionRadius = 300;
	ZombieMinDetectionRadius = 7.5;
	ZombieForgetTime = 60;
	ZombieMaxSpeedCoef = 2;
	ZombieMinSpeedCoef = 1.25;
	ZombieAttackRange = 2.5;
	ZombieAttackDamage = 0.125;

	private _allMagClasses = ("getNumber (_x >> 'Type') == 256" configClasses (configFile >> "CfgMagazines")) apply {configName _x;};

	private _allBlacklistedMags = [
		"CA_Magazine",
		"ProbingWeapon_01_magazine",
		"ProbingWeapon_02_magazine",
		"Dummy_Magazine_Base",
		"ESD_01_DummyMagazine_base",
		"ESD_01_DummyMagazine_1",
		"ESD_01_DummyMagazine_2",
		"ESD_01_DummyMagazine_3",
		"ESD_01_DummyMagazine_4",
		"ESD_01_DummyMagazine_5",
		"ESD_01_DummyMagazine_6",
		"ESD_01_DummyMagazine_7",
		"ESD_01_DummyMagazine_8",
		"ESD_01_DummyMagazine_9",
		"ESD_01_DummyMagazine_10",
		"ESD_01_DummyMagazine_11",
		"ESD_01_DummyMagazine_12",
		"ESD_01_DummyMagazine_13",
		"ESD_01_DummyMagazine_14",
		"ESD_01_DummyMagazine_15",
		"ESD_01_DummyMagazine_16",
		"ESD_01_DummyMagazine_17",
		"ESD_01_DummyMagazine_18",
		"ESD_01_DummyMagazine_19",
		"ESD_01_DummyMagazine_20",
		"OM_Magazine",
		"60Rnd_CMFlareMagazine",
		"120Rnd_CMFlareMagazine",
		"240Rnd_CMFlareMagazine",
		"60Rnd_CMFlare_Chaff_Magazine",
		"120Rnd_CMFlare_Chaff_Magazine",
		"240Rnd_CMFlare_Chaff_Magazine",
		"192Rnd_CMFlare_Chaff_Magazine",
		"168Rnd_CMFlare_Chaff_Magazine",
		"300Rnd_CMFlare_Chaff_Magazine"
	];

	ZSCAllMagazineClasses = (_allMagClasses - _allBlacklistedMags);
	ZSCAnyLootChance = 75;
	ZSCMaxUniqueLoot = 3;
	ZSCMaxLootAmount = 5;

	private _conversionRate = 1;
	private _awarenessRate = 1;
	private _persueRate = 0.625;

	publicVariable "ZombieMaxDetectionRadius";
	publicVariable "ZombieAttackRange";
	publicVariable "ZombieAttackDamage";
	publicVariable "ZombieInfectionChance";
	publicVariable "AllInfectionAntidotes";
	publicVariable "AllInfectionCurables";
	publicVariable "AllInfectionMedication";

	comment "remoteexec all zombie modules and for jip";
	[[],{

		if(!hasInterface) exitWith {};
		if (isMultiplayer) then {waitUntil {sleep 0.1; getClientState == "BRIEFING READ"};};
		if !(isNil "ZSC_fnc_addSystemModules") exitWith {};

		ZSC_EZM_fnc_createZombieModule = {
			private _unit = [civilian,"C_man_p_beggar_F","UP","AWARE"] call MAZ_EZM_fnc_createMan;
		};

		ZSC_EZM_fnc_createZombieHorde = {
			params[["_hoveredObject",objNull]];

			private _pos = [] call MAZ_EZM_fnc_getScreenPosition;

			comment "Create dialog with sliders";
			["Create Zombie Horde",
				[ 
					[
						"SLIDER:RADIUS", 
						"Spawn Radius", 
						[10,250,25,_pos,[1,1,1,1]] 
					], 
					[ 
						"SLIDER", 
						"Spawn Amount", 
						[1,100,15] 
					]
				],
				{ 
					params ["_values","_pos","_display"]; 
					_values params ["_radius","_amount"]; 

					for "_i" from 1 to _amount do { 
						private _randomPos = [ 
							[[_pos,_radius]], 
							[] 
						] call BIS_fnc_randomPos; 

						_randomPos set [2,0];

						(createGroup [civilian,true]) createUnit ["C_man_p_beggar_F",_randomPos,[],0,"CAN_COLLIDE"]; 
					};

					_display closeDisplay 1; 
				},
				{ 
					params ["_values","_args","_display"]; 
					_display closeDisplay 2; 
				},
				_pos
			] call MAZ_EZM_fnc_createDialog; 
		};

		ZSC_EZM_fnc_infectUnit = {
			params[["_hoveredObject",objNull]];

			if (_hoveredObject isEqualTo objNull) exitWith {[objNull, "No unit selected!"] call BIS_fnc_showCuratorFeedbackMessage;};

			[[_hoveredObject],{
				if (local (_this select 0)) then 
				{
					if (isPlayer (_this select 0)) then 
					{
						_this call ZSC_fnc_infectPlayer;
					}
					else 
					{
						(_this select 0) setUnconscious true;
					};
				};
			}] call ZSC_fnc_RE_Global;
		};

		ZSC_EZM_fnc_infectUnitsRadius = {
			private _pos = [] call MAZ_EZM_fnc_getScreenPosition;

			comment "Create dialog with sliders";
			["Infect Unit",
				[ 
					[
						"SLIDER:RADIUS", 
						"Infection Radius", 
						[10,250,50,_pos,[1,1,1,1]] 
					]
				],
				{ 
					params ["_values","_pos","_display"]; 
					_values params ["_radius","_amount"]; 

					private _units = _pos nearEntities [["Man"], _radius];

					{
						[[_x],{
							if (local (_this select 0)) then 
							{
								if (isPlayer (_this select 0)) then 
								{
									_this call ZSC_fnc_infectPlayer;
								}
								else 
								{
									(_this select 0) setUnconscious true;
								};
							};
						}] call ZSC_fnc_RE_Global;
					} foreach _units;

					_display closeDisplay 1; 
				},
				{ 
					params ["_values","_args","_display"]; 
					_display closeDisplay 2; 
				},
				_pos
			] call MAZ_EZM_fnc_createDialog; 
		};

		ZSC_EZM_fnc_cureUnit = {
			params[["_hoveredObject",objNull]];

			if (_hoveredObject isEqualTo objNull) exitWith {[objNull, "No unit selected!"] call BIS_fnc_showCuratorFeedbackMessage;};
			if !(isPlayer _hoveredObject) exitWith {};
			[[_hoveredObject],{if (local (_this select 0)) then {call ZSC_fnc_cancelInfectPlayer;};}] call ZSC_fnc_RE_Global;
		};

		ZSC_EZM_fnc_cureUnitsRadius = {
			private _pos = [] call MAZ_EZM_fnc_getScreenPosition;

			comment "Create dialog with sliders";
			["Cure Unit",
				[ 
					[
						"SLIDER:RADIUS", 
						"Cure Radius", 
						[10,250,50,_pos,[1,1,1,1]] 
					]
				],
				{ 
					params ["_values","_pos","_display"]; 
					_values params ["_radius","_amount"]; 

					private _players = _pos nearEntities [["Man"], _radius];

					{
						if (!isPlayer _x) then {continue};
						[[_x],{if (local (_this select 0)) then {call ZSC_fnc_cancelInfectPlayer;};}] call ZSC_fnc_RE_Global;
					} foreach _players;

					_display closeDisplay 1; 
				},
				{ 
					params ["_values","_args","_display"]; 
					_display closeDisplay 2; 
				},
				_pos
			] call MAZ_EZM_fnc_createDialog; 
		};

		ZSC_EZM_fnc_createDeconShower = {
			private _pos = [] call MAZ_EZM_fnc_getScreenPosition;

			createVehicle ["DeconShower_01_F",_pos,[],0,"CAN_COLLIDE"]; 
		};

		ZSC_EZM_fnc_createMedicalBag = {
			private _pos = [] call MAZ_EZM_fnc_getScreenPosition;

			createVehicle ["Land_FirstAidKit_01_closed_F",_pos,[],0,"CAN_COLLIDE"]; 
		};

		ZSC_EZM_fnc_addMedicationToInventory = {
			params[["_hoveredObject",objNull]];

			if (_hoveredObject isEqualTo objNull) exitWith {[objNull, "No object selected!"] call BIS_fnc_showCuratorFeedbackMessage;};

			ZSC_EZM_LAST_MEDICATION_OBJECT = _hoveredObject;

			private _pos = [] call MAZ_EZM_fnc_getScreenPosition;

			comment "Create dialog with sliders";
			["Add Medication To Inventory",
				[ 
					[
						"COMBO", 
						"Medication", 
						[ 
							["Antimalaricum","Antibiotic","Bandage","Item_AntidoteKit_01_F","Item_DeconKit_01_F","AntimalaricumVaccine"], 
							["Antimalarial Pills","Antibiotics","Bandage","Antidote Kit","Decon Kit","Vaccine"], 
							0 
						] 
					],
					[ 
						"SLIDER", 
						"Amount", 
						[1,10,2] 
					]
				],
				{ 
					params ["_values","_pos","_display"]; 
					_values params ["_medType","_amount"]; 

					if (isPlayer ZSC_EZM_LAST_MEDICATION_OBJECT) then 
					{
						private _uniform = uniformContainer ZSC_EZM_LAST_MEDICATION_OBJECT;
						private _vest = vestContainer ZSC_EZM_LAST_MEDICATION_OBJECT;
						private _backpack = backpackContainer ZSC_EZM_LAST_MEDICATION_OBJECT;
						private _playerContainers = [_uniform, _vest, _backpack];

						{
							if (!(isNull _x)) then {
								if (_x canAdd [_medType, _amount]) exitWith {
									_x addItemCargoGlobal [_medType,_amount];
									break;
								};
							};
						} foreach _playerContainers;
					}
					else 
					{
						ZSC_EZM_LAST_MEDICATION_OBJECT addItemCargoGlobal [_medType, _amount];
					};
					
					_display closeDisplay 1; 
				},
				{ 
					params ["_values","_args","_display"]; 
					_display closeDisplay 2; 
				},
				_pos
			] call MAZ_EZM_fnc_createDialog; 
		};

		ZSC_fnc_addUnitModules = {
			with uiNamespace do {
				comment "
					params [
						['_parentTree', findDisplay 312 displayCtrl 280], 
						['_parentCategory', 1], 
						['_parentSubcategory',1], 
						['_moduleName', '[ Module ]'], 
						['_moduleTip', '[ Placeholder ]'], 
						['_moduleFunction', 'MAZ_EZM_fnc_nullFunction'], 
						['_iconPath', '\a3\ui_f_curator\Data\Displays\RscDisplayCurator\modeModules_ca.paa'], 
						['_textColor', [1,1,1,1]], 
						['_iconColor', [1,1,1,1]], 
						['_iconColorSelected', [0,0,0,1]], 
						['_iconColorDisabled', [0.8,0,0,0.8]] 
					];
				";

				ZSC_ZombieCivsTree = [ 
					MAZ_UnitsTree_CIVILIAN, 
					"Simple Zombies", 
					"\a3\ui_f_curator\data\cfgmarkers\kia_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddCategory;

				ZSC_ZombieMenTree = [   
					MAZ_UnitsTree_CIVILIAN,   
					ZSC_ZombieCivsTree,   
					"Men",   
					""   
				] call MAZ_EZM_fnc_zeusAddSubCategory;   

				[
					MAZ_UnitsTree_CIVILIAN, 
					ZSC_ZombieCivsTree, 
					ZSC_ZombieMenTree, 
					"Zombie", 
					"Creates a zombie unit.", 
					"ZSC_EZM_fnc_createZombieModule", 
					"\a3\ui_f_curator\data\cfgmarkers\kia_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule_CIVILIAN;
			};
		};

		ZSC_fnc_addSystemModules = {
			with uiNamespace do {

				ZSC_ZombieModuleCategory = [ 
					MAZ_zeusModulesTree, 
					"Simple Zombies", 
					"\a3\ui_f_curator\data\cfgmarkers\kia_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddCategory;
				
				[ 
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Create Zombie Horde", 
					"Spawn a horde of zombies in a specified radius", 
					"ZSC_EZM_fnc_createZombieHorde", 
					"\a3\ui_f_curator\data\cfgmarkers\kia_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;
				
				[
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Infect Unit", 
					"Infect a single unit", 
					"ZSC_EZM_fnc_infectUnit", 
					"\a3\ui_f_curator\data\cfgcurator\laser_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;

				[
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Infect Radius", 
					"Infect all units in a specified radius", 
					"ZSC_EZM_fnc_infectUnitsRadius", 
					"\a3\ui_f_curator\data\cfgcurator\laser_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;

				[
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Cure Unit", 
					"Cure a single unit", 
					"ZSC_EZM_fnc_cureUnit", 
					"\a3\ui_f_curator\data\cfgcurator\laser_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;

				[
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Cure Radius", 
					"Cure all units in a specified radius", 
					"ZSC_EZM_fnc_cureUnitsRadius", 
					"\a3\ui_f_curator\data\cfgcurator\laser_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;

				[
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Create Decon Shower", 
					"Create a decon shower that cures infections", 
					"ZSC_EZM_fnc_createDeconShower", 
					"\a3\ui_f\data\IGUI\cfg\cursors\unitBleeding_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;

				[
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Create Medical Bag", 
					"Create a medical bag that cures infections", 
					"ZSC_EZM_fnc_createMedicalBag", 
					"\a3\ui_f\data\IGUI\cfg\cursors\unitBleeding_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;

				[
					MAZ_zeusModulesTree, 
					ZSC_ZombieModuleCategory, 
					"Add Medication Items", 
					"Add a specific medication to an inventory", 
					"ZSC_EZM_fnc_addMedicationToInventory", 
					"\a3\ui_f\data\IGUI\cfg\cursors\unitBleeding_ca.paa" 
				] call MAZ_EZM_fnc_zeusAddModule;
			};
		};

		[] spawn {

			with uiNamespace do 
			{
				waitUntil {!isNil "MAZ_EZM_fnc_zeusAddModule_CIVILIAN"};
				waitUntil {!isNil "MAZ_UnitsTree_CIVILIAN"};
				waitUntil {!isNil "MAZ_zeusModulesTree"};
			};

			waitUntil {!isNil "MAZ_EZM_fnc_addNewFactionToDynamicFactions"};
			waitUntil {!isNil "MAZ_EZM_fnc_addNewModulesToDynamicModules"};

			sleep 3;

			["ZSC_fnc_addUnitModules"] call MAZ_EZM_fnc_addNewFactionToDynamicFactions;
			["ZSC_fnc_addSystemModules"] call MAZ_EZM_fnc_addNewModulesToDynamicModules;
		};
	}] remoteExec ["Spawn",0,"JIP_ID_ZombieModules"];

	comment "Find all civilan classes";
	{
		_sideNum = getNumber(configFile >> "CfgVehicles" >> _x >> "side");
		_sideVeh = switch (_sideNum) do {case 0: {east}; case 1: {west}; case 2: {independent}; case 3: {civilian}; default {sideUnknown};};
		_kind = getText(configFile >> "CfgVehicles" >> _x >> "simulation");
		_editorPrev = getText(configFile >> "CfgVehicles" >> _x >> "editorPreview");
		if((_sideVeh isEqualTo civilian) && (_kind isEqualTo "soldier") && !(_editorPrev isEqualTo "")) then {AllCivilianClasses pushBack _x;};
	} foreach ((configFile >> "CfgVehicles") call BIS_fnc_getCfgSubClasses);
	AllCivilianClasses = (AllCivilianClasses - ["C_Protagonist_VR_F","C_Driver_1_F","C_Driver_2_F","C_Driver_3_F","C_Driver_1_random_base_F","C_Driver_1_black_F","C_Driver_1_blue_F","C_Driver_1_green_F","C_Driver_1_red_F","C_Driver_1_white_F","C_Driver_1_yellow_F","C_Driver_1_orange_F"]);
	AllCivilianClasses = (AllCivilianClasses + ["B_Soldier_unarmed_F","O_Soldier_unarmed_F","O_R_JTAC_F","I_Soldier_unarmed_F","I_E_Soldier_unarmed_F","B_Captain_Dwarden_F","B_CTRG_Soldier_tna_F","B_Captain_Jay_F"]);

	comment "Remove entity from known when it respawns";
	addMissionEventHandler ["EntityRespawned", {
		params ["_entity", "_corpse"];
		[_entity] call ZSC_fnc_markAsUnknown;
	}];

	comment "Manage Dead Zombies";
	addMissionEventHandler ["EntityKilled",{
		params ["_unit", "_killer", "_instigator", "_useEffects"];

		[_unit] call ZSC_fnc_removeFromArrays;
		_isZombie = _unit getVariable "isZombie";
		if (isNil "_isZombie") exitWith {};
		_unit removeAllEventHandlers "FiredNear";
		_unit removeAllEventHandlers "HandleDamage";
		[_unit]spawn{uisleep 180;if((_this select 0) isEqualTo objNull)exitWith{};deleteVehicle(_this select 0);};

		private _sounds = [
			"a3\sounds_F\characters\human-sfx\p07\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p07\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p07\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p09\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p09\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p09\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p10\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p12\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p13\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p13\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p14\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p14\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p14\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p16\hit_max_1.wss"
		];
		private _pitch = random [0, 0.5, 0.9];
		playSound3D [selectRandom _sounds,_unit,false,getPosATL _unit,5,_pitch,ZombieMaxDetectionRadius];

		comment "Add loot";
		[_unit,_instigator] call ZCS_fnc_addRandomLootToZombie;
	}];

	comment "Find all protection zones";
	{
		{
			AllZombieSafeZones pushBack _x;
			_x addEventHandler ["Deleted", {
				params ["_entity"];
				AllZombieSafeZones = ((AllZombieSafeZones-[_entity])-[objNull]);
			}];
		} foreach allMissionObjects _x;
	} foreach AllSafeZoneClasses;

	comment "Add Zeus Placed Safezones";
	{
		_x addEventHandler ["CuratorObjectPlaced", {
			params ["_curator", "_entity"];
			if (typeOf _entity in AllSafeZoneClasses) then 
			{
				AllZombieSafeZones pushBack	_entity;
				_entity addEventHandler ["Deleted", {
					params ["_entity"];
					AllZombieSafeZones = ((AllZombieSafeZones-[_entity])-[objNull]);
				}];
			};
		}];
	} foreach allCurators;

	comment "Convert civilians to zombies outside safezones";
	ZSC_fnc_startConverting = {
		params["_updateRate"];
		while {isZombieSystemAllowed} do 
		{
			{
				private _unit = _x;
				if ((typeOf _unit in AllInfectedClasses) && !([_unit] call ZSC_fnc_isTargetInSafeZone) || (side _unit isEqualTo civilian && lifeState _unit isEqualTo "INCAPACITATED")) then 
				{
					[_unit] call ZSC_fnc_createZombieAgent;
				};
			} foreach (allUnits - allPlayers);

			comment "Forget Known Entites When No More Zombies";
			if((AllZombieAgents isEqualTo []) && !(AllKnownAboutTargets isEqualTo [])) then 
			{
				{[_x] call ZSC_fnc_markAsUnknown;} forEach AllKnownAboutTargets;
				AllKnownAboutTargets = [];
			};

			comment "Forget Known Entities Over Time";
			if(!(AllKnownAboutTargets isEqualTo [])) then 
			{
				{
					private _sec = _x getVariable "isKnownSeconds";
					if(!isNil "_sec") then 
					{
						_x setVariable ["isKnownSeconds",_sec+_updateRate];
						if((_sec+_updateRate) >= ZombieForgetTime) then 
						{
							[_x] call ZSC_fnc_markAsUnknown; 
						};
					};
				} foreach AllKnownAboutTargets;
			};
			{_x addCuratorEditableObjects[AllZombieAgents,false];} foreach allCurators;
			{deleteGroup _x;} foreach allGroups;
			uisleep _updateRate;
		};
	};

	comment "Check the surroundings for targets";
	ZSC_fnc_startSearching = {
		params["_updateRate"];
		while {isZombieSystemAllowed} do 
		{
			private ["_zombie","_nearbyTargets","_hasTarget", "_visibility","_activeAgents","_isAlerted"];
			_activeAgents = [];
			{
				_zombie = _x;
				_isAlerted = _zombie getVariable "isAlerted";
				_nearbyTargets = getPosATL _zombie nearEntities [["Man","Car","APC","Tank","Ship","Air"],ZombieMaxDetectionRadius];
				{
					private _target = _x;
					private _isKnown = _target getVariable "isKnown";
					private _isZombie = _target getVariable "isZombie";
					private _distance = _zombie distance _target;
					private _validCrewCount = (count crew _target > 0);
					private _isInSafeZone = ([_target] call ZSC_fnc_isTargetInSafeZone);
					private _isInfectedSide = (typeOf _target in AllInfectedClasses);
					private _isCloseEnough = (_distance <= ZombieMaxSpottingRadius);
					private _isAlive = alive _target;
					private _isIncap = (lifeState _target isEqualTo "INCAPACITATED");
					if (isNil "_isZombie" && isNil "_isKnown" && _validCrewCount && !_isInSafeZone && !_isInfectedSide && _isCloseEnough && _isAlive && !_isIncap) then 
					{
						_visibility = [_target, "VIEW"] checkVisibility [eyePos _target, eyePos _zombie];
						private _relAngle = _zombie getRelDir _target;
						if(((_visibility > 0.825) && ((_relAngle <= 80) || (_relAngle >= 280))) || (_distance <= ZombieMinDetectionRadius)) then 
						{
							[_zombie] call ZSC_fnc_setZombieAlert;
							[_target] call ZSC_fnc_markAsKnown;
							_activeAgents pushBack _zombie;
						};
					}
					else 
					{	
						comment "Spot Enemies Reported by Other Zombies";
						if(isNil "_isZombie" && !isNil "_isKnown" && _validCrewCount && !_isInSafeZone && !_isInfectedSide && (isNil "_isAlerted") && _isAlive && !_isIncap) then 
						{
							[_zombie] call ZSC_fnc_setZombieAlert;
							_activeAgents pushBack _zombie;
						};
					};
				} forEach _nearbyTargets;

				comment "Sounds";
				if(isNil "_isAlerted") then {[_zombie,5] call ZSC_fnc_randomChanceIdleSound;};
			} foreach AllZombieAgents;
			uisleep _updateRate;
		};
	};

	comment "Persue closest target";
	ZSC_fnc_startPersuing = {
		params["_updateRate"];
		while {isZombieSystemAllowed} do 
		{
			private ["_zombie","_target","_nearbyTargets","_idleZombies"];
			_idleZombies = [];
			{
				_target = objNull;
				_zombie = _x;
				comment "Find Nearest Known Target";
				_nearbyTargets = nearestObjects [_zombie,["Man","Car","APC","Tank","Ship","Air","StaticWeapon"],ZombieMaxDetectionRadius];
				if !(_nearbyTargets isEqualTo []) then 
				{
					_index = _nearbyTargets findIf 
					{
						private _unit = _x;
						private _isKnown = _unit getVariable "isKnown";
						private _isZombie = _unit getVariable "isZombie";
						private _validCrewCount = (count crew _unit > 0);
						private _isInSafeZone = ([_unit] call ZSC_fnc_isTargetInSafeZone);
						private _isInfectedSide = (typeOf _unit in AllInfectedClasses);
						private _isAlive = alive _unit;
						private _isIncap = (lifeState _unit isEqualTo "INCAPACITATED");
						(isNil "_isZombie" && !isNil "_isKnown" && _validCrewCount && !_isInSafeZone && !_isInfectedSide && _isAlive && !_isIncap)
					};
					if(_index != -1) then {_target = (_nearbyTargets select _index);};
				};
				
				if (_target isEqualTo objNull) then
				{
					[_zombie] call ZSC_fnc_setZombieIdle;
					_idleZombies pushBack _zombie;
				}
				else 
				{
					_zombie moveTo getPosATL _target;
					private _isVehicle = !(_target isKindOf "Man");
					private _isAircraft = (_target isKindOf "Air");
					private _dist = (_zombie distance _target);

					if((_dist <= ZombieAttackRange) && alive _zombie && !_isVehicle)then {[_zombie,_target,_isVehicle] spawn ZSC_fnc_spawnPlayAttack;};
					if((_dist <= ZombieAttackRange*3) && alive _zombie && _isVehicle)then {[_zombie,_target,_isVehicle] spawn ZSC_fnc_spawnPlayAttack;}
					else {if((_dist <= ZombieAttackRange*5) && _isAircraft)then{[_zombie,_target,_isVehicle] spawn ZSC_fnc_spawnPlayAttack;};};
				};

				comment "Sound";
				[_zombie,5] call ZSC_fnc_randomAttackSound;
			} foreach AllAlertedZombieAgents;
			AllAlertedZombieAgents = (AllAlertedZombieAgents - _idleZombies);
			uisleep _updateRate;
		};
	};

	ZCS_fnc_addRandomLootToZombie = {
		params["_zombie","_instigator"];

		if !(ZSCAnyLootChance >= random 100) exitWith {};

		private _uniform = uniformContainer _zombie;
		private _vest = vestContainer _zombie;
		private _backpack = backpackContainer _zombie;
		private _zombieContainers = [_uniform, _vest, _backpack];

		comment "Add random items";
		private _lootItemClasses = [];
		for "_i" from 1 to (round random ZSCMaxUniqueLoot) do 
		{
			_lootItemClasses pushBackUnique selectRandom ZSCAllMagazineClasses;
		};

		{
			private _itemClass = _x;
			{
				if (!(isNull _x)) then {
					private _amount = (round random ZSCMaxLootAmount);
					if (_x canAdd [_itemClass, _amount]) exitWith {
						_x addItemCargoGlobal [_itemClass,_amount];
					};
				};
			} foreach _zombieContainers;
		} foreach _lootItemClasses;
		
		comment "Add magazine of killer";
		if (_instigator isEqualTo objNull) exitWith {};

		private _weaponUsed = currentWeapon _instigator;
		if (75 >= random 100) then 
		{
			private _magazines = getArray (configFile >> 'CfgWeapons' >> _weaponUsed >> 'magazines');
			_magazineClass = selectRandom _magazines;
			if (isClass (configFile >> 'CfgMagazines' >> _magazineClass)) then 
			{
				{
					if (!(isNull _x)) then {
						private _amount = (round random ZSCMaxLootAmount);
						if (_x canAdd [_magazineClass, _amount]) exitWith {
							_x addItemCargoGlobal [_magazineClass,_amount];
							break;
						};
					};
				} foreach _zombieContainers;
			};
		};

		comment "Add medication or cure";
		if (25 >= random 100) then 
		{
			private _itemClass = selectRandom (AllInfectionAntidotes+AllInfectionMedication);
			{
				if (!(isNull _x)) then {
					if (_x canAdd [_itemClass, 1]) exitWith {
						_x addItemCargoGlobal [_itemClass,1];
						break;
					};
				};
			} foreach _zombieContainers;
		};
	};

	ZSC_fnc_createZombieAgent = {
		params["_unit"];
		private _speed = random ZombieMaxSpeedCoef;
		if(_speed < ZombieMinSpeedCoef) then {_speed = ZombieMinSpeedCoef;};

		private _stances = ["ApanPpneMsprSnonWnonDf","ApanPercMsprSnonWnonDf","ApanPknlMsprSnonWnonDf"];
		private _weights = [1,3,3];
		private _stance = _stances selectRandomWeighted _weights;
		if (_stance isEqualTo "ApanPpneMsprSnonWnonDf") then {_speed = ZombieMaxSpeedCoef*1.5;};
		private _sideNum = getNumber(configFile >> "CfgVehicles" >> typeOf _unit >> "side");
		private _sideVeh = switch (_sideNum) do {case 0: {east}; case 1: {west}; case 2: {independent}; case 3: {civilian}; default {sideUnknown};};
		private _className = if (_sideVeh isEqualTo civilian) then {selectRandom AllCivilianClasses} else {typeof _unit};
		private _zombie = createAgent [_className, ASLToAGL(getPosASL _unit), [], 0, "CAN_COLLIDE"];
		_zombie setDir (floor random 360);
		_zombie disableAI "FSM";
		_zombie setBehaviour "CARELESS";
    	_zombie forceSpeed (_zombie getSpeed "FAST");
		[_zombie,-100000] remoteExec ["addRating",0];
		[_zombie,"ApanPknlMstpSnonWnonDnon"] remoteExec ["switchMove",0,_zombie];
		[_zombie,_speed] remoteExec ["setAnimSpeedCoef",0,_zombie];
		_zombie setVariable ["isZombie",true];
		_zombie setVariable ["ZombieStance",_stance];
		[_zombie] call ZSC_fnc_setStance;
		_zombie setDamage 0.475;
		removeAllWeapons _zombie;

		private _grp = group _unit;
		AllZombieAgents pushBack _zombie;
		AllKnownAboutTargets = (AllKnownAboutTargets - [_unit,objNull]);
		_grp deleteGroupWhenEmpty true;
		deleteVehicle _unit;
		deleteGroup _grp;

		comment "listen for gunshots";
		_zombie addEventHandler ["FiredNear", {
			params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];

			_isKnown = _firer getVariable "isKnown";
			if (isNil "_isKnown") then 
			{
				[_firer] call ZSC_fnc_markAsKnown;
			};
		}];

		comment "Damage Resistance and Move To Attacker";
		_zombie addEventHandler["HandleDamage", {
			params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

			_isKnown = _source getVariable "isKnown";
			if (isNil "_isKnown" && !(_source isEqualTo objNull)) then 
			{
				_unit moveTo getPosATL _source;
			};

			if (vest _unit isEqualTo "") then {
				_constant = 0.275;
				_selections = _unit getVariable ["selections", []];
				_gethit = _unit getVariable ["gethit", []];
				if !(_selection in _selections) then
				{_selections set [count _selections, _selection];
				 _gethit set [count _gethit, 0];};
				_i = _selections find _selection;
				_olddamage = _gethit select _i;
				_damage = _olddamage + ((_this select 2) - _olddamage) * (_constant);
				_gethit set [_i, _damage];
				_damage
			};
		}];

		comment "Remove deleted unit from arrays";
		_zombie addEventHandler ["Deleted", {
			params ["_entity"];
			[_entity] call ZSC_fnc_removeFromArrays;
		}];
	};

	ZSC_fnc_removeFromArrays = {
		params["_unit"];
		AllZombieAgents = (AllZombieAgents - [_unit,objNull]);
		AllAlertedZombieAgents = (AllAlertedZombieAgents - [_unit]);
		AllKnownAboutTargets = (AllKnownAboutTargets - [_unit]);
	};

	ZSC_fnc_isTargetInSafeZone = {
		params["_target"];
		private _value = (AllZombieSafeZones findIf {_target distance _x < SafeZoneRadius});
		(_value != -1)
	};

	ZSC_fnc_setZombieAlert = {
		params["_zombie"];
		_isAlerted = _zombie getVariable "isAlerted";
		if(!isNil "_isAlerted") exitWith {};
		_zombie setVariable ["isAlerted",true];
		AllAlertedZombieAgents pushBack _zombie;
	};

	ZSC_fnc_setZombieIdle = {
		params["_zombie"];
		_isAlerted = _zombie getVariable "isAlerted";
		if(isNil "_isAlerted") exitWith {};
		_zombie setVariable ["isAlerted",nil];
		_zombie moveTo ([_zombie] call ZSC_fnc_randomNearbyPosition);
	};

	ZSC_fnc_randomNearbyPosition = {
		params["_zombie"];
		private _pos = getPosATL _zombie getPos [random 20, random 360];
		_pos = _pos findEmptyPosition [1.25, 20, typeof _zombie];
		_pos
	};

	ZSC_fnc_markAsKnown = {
		params["_unit"];
		_isZombie = _unit getVariable "isZombie";
		if(!isNil "_isZombie") exitWith {};
		AllKnownAboutTargets pushBack _unit;
		_unit setVariable ["isKnown",true];
		_unit setVariable ["isKnownSeconds",0];
	};

	ZSC_fnc_markAsUnknown = {
		params["_unit"];
		_unit setVariable ["isKnown",nil];
		_unit setVariable ["isKnownSeconds",0];
		AllKnownAboutTargets = (AllKnownAboutTargets - [_unit]);
	};

	ZSC_fnc_setStance = {
		params["_zombie"];
		_stance = _zombie getVariable "ZombieStance";
		if(isNil "_stance") exitWith {};
		if(_stance isEqualTo "ApanPercMsprSnonWnonDf") then {[_zombie,"GestureAgonyCargo"] remoteExec ["playActionNow",0,_zombie];};
		[_zombie,_stance] remoteExec ["switchMove",0,_zombie];
	};

	ZSC_fnc_spawnPlayAttack = {
		params["_zombie","_target","_isVehicle"];
		if(_zombie isEqualTo objNull) exitWith {};
		if(_target isEqualTo objNull) exitWith {};
		_stance = _zombie getVariable "ZombieStance";
		if(isNil "_stance") exitWith {};

		comment "Check if target is visible before hitting (stops zombies from hitting thorugh walls)";
		_visibility = [_target, "VIEW"] checkVisibility [eyePos _target, eyePos _zombie];
		private _relAngle = _zombie getRelDir _target;
		if !(_visibility > 0.5) exitWith {};

		comment "random delay to attack to prevent in sync attacks";
		uisleep random 0.33;

		if (!alive _zombie) exitWith {};
		if (!alive _target) exitWith {};
		if (lifeState _target isEqualTo "INCAPACITATED") exitWith {};

		_zombie playAction "gestureNod";
		_hitAnim = switch (_stance) do 
		{
			case "ApanPpneMsprSnonWnonDf": {"AwopPpneMstpSgthWpstDnon_Part4"};
			case "ApanPercMsprSnonWnonDf": {"AwopPercMstpSgthWnonDnon_end"};
			case "ApanPknlMsprSnonWnonDf": {"AwopPknlMstpSgthWrflDnon_End"};
		};
		_zombie setDir ((getDir _zombie)+(_zombie getRelDir _target));
		[_zombie,_hitAnim] remoteExec ["switchMove",0,_zombie];
		[_zombie,_stance] spawn 
		{
			params["_zombie","_stance"];
			uisleep 1.25;
			if(isNil "_zombie") exitWith {};
			if(!alive _zombie) exitWith {};
			if(_stance isEqualTo "ApanPercMsprSnonWnonDf") then {[_zombie,"GestureAgonyCargo"] remoteExec ["playActionNow",0,_zombie];};
			[_zombie,_stance]remoteExec["switchMove",0,_zombie];
		};
		{
			if (player in call BIS_fnc_listCuratorPlayers) exitWith {};
			[100] call BIS_fnc_bloodEffect;
			call BIS_fnc_indicateBleeding;
		} remoteExec ["BIS_fnc_Call",owner _target];
		if (!_isVehicle) then 
		{
			comment "Push unit with random strength";
			_vectorDir = vectorDir _zombie;
			_vectorDir set[2,(_vectorDir select 2)+0.5];
			_force = random [0,2,6];

			comment "slam dunk final hit!";
			if ((damage _target + ZombieAttackDamage) >= 0.5) then 
			{
				_vectorDir = vectorDir _zombie;
				_vectorDir set[2,(_vectorDir select 2)+0.2];
				_force = 6;
			};

			_vectorVel = _vectorDir vectorMultiply _force;
			[_target,((velocity _target) vectorAdd _vectorVel)] remoteExec ["setVelocity",owner _target];

			comment "wait";
			sleep 0.05;

			if (lifeState _target isEqualTo "INCAPACITATED") exitWith {};

			comment "damage the unit";
			_target setDamage ((damage _target)+ZombieAttackDamage);

			comment "set ai unit unconcious";
			if ((damage _target < 0.5) && !(isPlayer _target)) then 
			{
				[_target] spawn 
				{
					params["_target"];

					[_target,true] remoteExec ["setUnconscious",owner _target];
					_target setVariable ["isZombie",true];
					sleep 7.5; 
					[_target,true] remoteExec ["setCaptive",owner _target];
				};
			};
			
			comment "chance for player to be infected by damage";
			if ((ZombieInfectionChance >= random 100) && (isPlayer _target) && isZombieInfectionAllowed) then {[_target] remoteExec ["ZSC_fnc_infectPlayer",owner _target];};
		}
		else 
		{
			if((round random 2) == 2) then {[_target] call ZSC_fnc_vehicleDamage;};

			comment "Push vehicle with random strength";
			_vectorDir = vectorDir _zombie;
			_force = random [2,3,4];
			_vectorVel = _vectorDir vectorMultiply _force;
			[_target,((velocity _target) vectorAdd _vectorVel)] remoteExec ["setVelocity",owner _target];
		};
		[_zombie,0] call ZSC_fnc_randomAttackSound;
	};

	ZSC_fnc_vehicleDamage = {
		params["_target"];
		comment "apply wheel damage";
		if(_target isKindOf "Land") then 
		{
			_wheels = [
				["wheel_1_1_steering"],
				["wheel_1_2_steering"],
				["wheel_1_3_steering"],
				["wheel_1_4_steering"],
				["wheel_2_1_steering"],
				["wheel_2_2_steering"],
				["wheel_2_3_steering"],
				["wheel_2_4_steering"],
				["hit_trackR_point"],
				["hit_trackL_point"]
			];								
			_dmgWheel =  selectRandom _wheels;				
			[_target,[_dmgWheel select 0, 1]] remoteExec ["setHit",owner driver _target];
			[_target,["engine", ((_target getHit "engine")+0.05)]] remoteExec ["setHit",owner driver _target];
			[_target,["motor", ((_target getHit "motor")+0.05)]] remoteExec ["setHit",owner driver _target];
			[_target,["hit_engine_point", ((_target getHit "hit_engine_point")+0.05)]] remoteExec ["setHit",owner driver _target];
			if(_target getHit "engine" >= 1) then {_target setDamage 1;};
			if(_target getHit "motor" >= 1) then {_target setDamage 1;};
			if(_target getHit "hit_engine_point" >= 1) then {_target setDamage 1;};
		}
		else 
		{
			_target setDamage ((damage _target)+0.05);
		};
	};

	ZSC_fnc_randomChanceIdleSound = {
		params["_zombie","_chance"];

		private _sounds = [
			"a3\sounds_f\characters\human-sfx\person3\P3_moan_02.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_moan_04.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_moan_06.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_moan_07.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_moan_08.wss",
			"a3\sounds_F\characters\human-sfx\p03\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p03\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p02\max_hit_04.wss",
			"a3\sounds_F\characters\human-sfx\p03\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p04\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p04\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p05\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p05\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p06\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p06\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p07\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p08\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p08\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p10\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p10\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p11\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p12\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p12\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p14\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p15\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p18\hit_max_3.wss"
		];
		if ((round random _chance) != _chance) exitWith {false};
		private _pitch = random [0, 0.5, 0.75];
		playSound3D [selectRandom _sounds,_zombie,false,getPosATL _zombie,5,_pitch,300*0.325];
		true
	};

	ZSC_fnc_randomAttackSound = {
		params["_zombie","_chance"];

		private _sounds = [
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_01.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_02.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_03.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_04.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_05.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_06.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_07.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_08.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_09.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_10.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_11.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_12.wss",
			"a3\sounds_f\characters\human-sfx\person3\P3_hit_13.wss",
			"a3\sounds_F\characters\human-sfx\p02\max_hit_02.wss",
			"a3\sounds_F\characters\human-sfx\p04\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p04\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p04\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p05\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p05\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p05\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p05\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p06\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p06\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p06\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p06\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p07\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p07\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p08\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p08\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p08\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p09\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p09\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p10\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p11\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p11\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p11\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p12\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p13\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p13\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p13\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p15\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p15\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p15\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p15\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p16\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p16\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p16\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p16\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p17\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p17\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p17\hit_max_3.wss",
			"a3\sounds_F\characters\human-sfx\p17\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p17\hit_max_5.wss",
			"a3\sounds_F\characters\human-sfx\p18\hit_max_1.wss",
			"a3\sounds_F\characters\human-sfx\p18\hit_max_2.wss",
			"a3\sounds_F\characters\human-sfx\p18\hit_max_4.wss",
			"a3\sounds_F\characters\human-sfx\p18\hit_max_5.wss"
		];
		if ((round random _chance) != _chance) exitWith {false};
		private _pitch = random [0, 0.5, 0.9];
		playSound3D [selectRandom _sounds,_zombie,false,getPosATL _zombie,5,_pitch,ZombieMaxDetectionRadius];
		true
	};
	publicVariable "ZSC_fnc_randomAttackSound";
	[_conversionRate] spawn ZSC_fnc_startConverting;
	[_awarenessRate] spawn ZSC_fnc_startSearching;
	[_persueRate] spawn ZSC_fnc_startPersuing;
} remoteExec ["BIS_fnc_Call",2];

comment "/////////////////////////////////////////////////////////////////////////////////////////////////////";
comment "////////////////////////////////////// CLIENT ONLY CODE BELOW ///////////////////////////////////////";
comment "/////////////////////////////////////////////////////////////////////////////////////////////////////";

comment "JIP Client";
[[],{
	if(!hasInterface) exitWith {};
	if(!isServer) then {if !(isNil "isZombieSystemAllowed") exitWith {hint "Zombie System v3 Already Running!"; if(true)exitWith{};};}; 
	if (isMultiplayer) then {waitUntil {sleep 0.1; getClientState == "BRIEFING READ"};};
	sleep 1;
	0 fadeRadio 0;
	enableRadio false;
	enableSentences false;
	player addRating 1e10;
	comment"player addMPEventHandler ['MPRespawn',{player addRating 1e10; [] spawn ZSC_fnc_initSpawnInfectionSupplies;}];";

	isZombieSystemAllowed = true;
	isInfectionCureSearchAllowed = true;
	isInfectedPlayerFullZombie = false;
	InfectedPlayerMedicationDelay = 0;
	InfectedPlayerLastAntidoteActionIndex = -1;
	InfectedPlayerLastMedicationActionIndex = -1;

	ZSC_fnc_RE_Global = {
		params["_arguments","_code"];
		_varName = ("ZSC"+str (round random 10000));

		TempCode = compile ("_this call "+str _code+"; "+(_varName+" = nil;"));
		TempArgs = _arguments;

		call compile (_varName +" = [TempArgs,TempCode];
		publicVariable '"+_varName+"';

		[[], {
		("+_varName+" select 0) spawn ("+_varName+" select 1);
		}] remoteExec ['spawn',0];");
	};

	ZSC_fnc_initSpawnInfectionSupplies = {
		waitUntil {alive player};
		if(InfectedPlayerLastAntidoteActionIndex == -1) then {player addItem 'Antimalaricum';};
		if(InfectedPlayerLastMedicationActionIndex == -1) then {player addItem 'Antibiotic';};
		call ZSC_fnc_updateActionOptions;
	};

	comment "player killed event handling";
	player addEventHandler ["Killed",{
		call ZSC_fnc_cancelInfectPlayer;
		removeAllActions player;
		InfectedPlayerLastAntidoteActionIndex = -1;
		InfectedPlayerLastMedicationActionIndex = -1;
	}];

	comment "search for curable objects";
	[] spawn 
	{
		while {isInfectionCureSearchAllowed && isZombieSystemAllowed} do 
		{
			_nearObjects = nearestObjects [player,AllInfectionCurables,10];
			if !(_nearObjects isEqualTo []) then 
			{
				{
					_isCureInit = _x getVariable "isCureInit";
					if (isNil "_isCureInit") then 
					{
						comment "addaction to stuff";
						if(typeof _x in AllInfectionCurables) then 
						{
							_x setVariable ["isCureInit",true];
							[_x,3.5] call ZSC_fnc_addInstantCleanseAction;
						};
					};
				} foreach _nearObjects;
			};
			sleep 2;
		};
	};

	comment "add infection supplies when closing arsenal";
	[] spawn 
	{
	    isArsenalEventAllowed = true;
	    while {isArsenalEventAllowed && isZombieSystemAllowed} do 
	    {
	        waitUntil  {sleep 1; !isNull (uiNamespace getVariable [ 'BIS_fnc_arsenal_cam', objNull ])};
	        waitUntil  {sleep 1; isNull (uiNamespace getVariable [ 'BIS_fnc_arsenal_cam', objNull ])};
			waitUntil {!isNil 'ZSC_fnc_updateActionOptions'};
			call ZSC_fnc_updateActionOptions;
			[] spawn ZSC_fnc_initSpawnInfectionSupplies;
	    };
	};

	comment "Inventory events";
	{player addEventHandler [_x, {call ZSC_fnc_updateActionOptions;}];} foreach ["InventoryOpened","InventoryClosed","Take","Put"];

	ZSC_fnc_addInstantCleanseAction = {
		params ["_object","_range"];

		_object addAction 
		[
		    "<a color='#006eff' font='PuristaMedium' shadow='2' size='1.5'><img image='\a3\ui_f\data\IGUI\cfg\cursors\unitBleeding_ca.paa'/>Cleanse Infection</a>",
		    {
		        params ["_target", "_caller", "_actionId", "_arguments"];
				[_caller] call ZSC_fnc_cancelInfectPlayer;
				_showers = ["DeconShower_01_F","DeconShower_02_F"];
				if(typeof _target in _showers) then 
				{
					[_target,{
						if(!hasInterface) exitWith {};
						[_this] call BIN_fnc_deconShowerDelete;
						[_this] call BIN_fnc_deconShowerAnim;
						sleep 5;
						[_this] call BIN_fnc_deconShowerAnimStop;
					}] call ZSC_fnc_RE_Global;
				};
		    },[],10, true, true, "","true",_range,false,"",""
		];
	};

	ZSC_fnc_addAntidoteAction = {
		params ["_object","_range","_itemClass"];

		_picturePath = getText(configFile >> "CfgWeapons" >> _itemClass >> "picture");
		_displayName = getText(configFile >> "CfgWeapons" >> _itemClass >> "displayName");

		if ((_displayName isEqualTo "") || ( _picturePath isEqualTo "")) then 
		{
			_picturePath = getText(configFile >> "CfgMagazines" >> _itemClass >> "picture");
			_displayName = getText(configFile >> "CfgMagazines" >> _itemClass >> "displayName");
		};

		InfectedPlayerLastAntidoteActionIndex = _object addAction 
		[
		    "<a color='#ffffff' font='RobotoCondensed' shadow='1' size='1.1'><img image='"+_picturePath+"'/> Use "+_displayName+" (Cure Infection)</a>",
		    {
		        params ["_target", "_caller", "_actionId", "_arguments"];
				[_caller] call ZSC_fnc_cancelInfectPlayer;
				player playMove "AinvPknlMstpSlayWrflDnon_medic";
				player removeItem (_arguments select 0);
				[] spawn {sleep 1; call ZSC_fnc_updateActionOptions;};
		    },[_itemClass],-1, false, true, "","true",_range,false,"",""
		];
	};

	ZSC_fnc_addMedicationAction = {
		params ["_object","_range","_itemClass"];

		_picturePath = getText(configFile >> "CfgWeapons" >> _itemClass >> "picture");
		_displayName = getText(configFile >> "CfgWeapons" >> _itemClass >> "displayName");

		if ((_displayName isEqualTo "") || ( _picturePath isEqualTo "")) then 
		{
			_picturePath = getText(configFile >> "CfgMagazines" >> _itemClass >> "picture");
			_displayName = getText(configFile >> "CfgMagazines" >> _itemClass >> "displayName");
		};

		InfectedPlayerLastMedicationActionIndex = _object addAction 
		[
		    "<a color='#ffffff' font='RobotoCondensed' shadow='1' size='1.1'><img image='"+_picturePath+"'/> Use "+_displayName+" (Delay Infection)</a>",
		    {
		        params ["_target", "_caller", "_actionId", "_arguments"];
				InfectedPlayerMedicationDelay = 300;
				player playMove "AinvPknlMstpSlayWrflDnon_medic";
				player removeItem (_arguments select 0);
				[] spawn {sleep 1; call ZSC_fnc_updateActionOptions;};
		    },[_itemClass],-1, false, true, "","true",_range,false,"",""
		];
	};

	ZSC_fnc_updateActionOptions = {
		comment "reset actions";
		player removeAction InfectedPlayerLastAntidoteActionIndex;
		player removeAction InfectedPlayerLastMedicationActionIndex;
		InfectedPlayerLastAntidoteActionIndex = -1;
		InfectedPlayerLastMedicationActionIndex = -1;

		_items = ((uniformItems player) + (vestItems player) + (backpackItems player));
		comment "Add actions";
		{
			if(_x in AllInfectionMedication && (InfectedPlayerLastMedicationActionIndex == -1)) then 
			{
				[player,1,_x] call ZSC_fnc_addMedicationAction;
			};
			if(_x in AllInfectionAntidotes && (InfectedPlayerLastAntidoteActionIndex == -1)) then 
			{
				[player,1,_x] call ZSC_fnc_addAntidoteAction;
			};
		} foreach _items;
	};

	ZSC_fnc_spawnInfectionHints = {
		player setVariable ["hasBeenInfected",true];

		hint parseText ("<a font='PuristaMedium' shadow='2' size='10'><img image='\a3\Missions_F_Oldman\Props\data\Antibiotic_ca.paa'/></a> 
       	<t size='1'><br/>If you start coughing, check your </t><t color='#1ee300'>inventory</t><t> for antibiotics.<br/><br/>Use antibiotics with [</t><t color='#ff8000'>Scroll Wheel</t><t>] to slow down the infection.<br/><br/>Only works if taken quickly.</t>");
		
		sleep 15;

		hint parseText ("<a font='PuristaMedium' shadow='2' size='10'><img image='\a3\Missions_F_Oldman\Props\data\Antimalaricum_ca.paa'/></a> 
       	<t size='1'><br/>Antimalarial pills will completely cure you, but </t><t color='#ff3030'>are extremely rare to find</t>");

		sleep 15;

		hint parseText ("<a font='PuristaMedium' shadow='2' size='10'><img image='\A3\EditorPreviews_F\Data\CfgVehicles\B_supplyCrate_F.jpg'/></a> 
       	<t size='1'><br/>However, if you use an </t><t color='#15ff00'>Arsenal</t><t>, then medication will be added to your inventory automatically.</t>");

		sleep 15;

		hint parseText ("<a font='PuristaMedium' shadow='2' size='10'><img image='\A3\EditorPreviews_F_Enoch\Data\CfgVehicles\DeconShower_01_F.jpg'/></a> 
       	<t size='1'><br/>A DECON shower will also </t><t color='#00aae3'>cleanse</t><t> the infection for free.<br/><br/>Find one ASAP.</t>");

		sleep 15;

		hint parseText ("<a font='PuristaMedium' shadow='2' size='10'><img image='\a3\ui_f_curator\data\Displays\RscDisplayCurator\modeGroups_ca.paa'/></a> 
       	<t size='1'><br/>Don't team kill infected players, <t color='#ffe100'>help them</t>.<br/><br/><t color='#ff3030'>Only kill them if they become dangerous.</t>");

		sleep 15;

		hint "";
	};

	ZSC_fnc_cancelInfectPlayer = {
		isInfectedCoughingAllowed = false;
		isInfectedHeartBeatAllowed = false;
		isInfectedRandomZombieSoundsAllowed = false;
		InfectedPlayerMedicationDelay = 0;
		player addRating ((-1*(rating player))+1e11);
		(findDisplay 46) displayRemoveAllEventHandlers "MouseButtonDown";
		player removeAllEventHandlers "GetInMan";
		{ctrlDelete _x;} foreach (uiNamespace getVariable "InfectedGradients");
		{ctrlDelete _x;} foreach (uiNamespace getVariable "InfectedDarkImages");
		player playAction "gestureNod";
		resetCamShake;

		if(isNil "InfectedPlayerScriptHandle") then {InfectedPlayerScriptHandle = scriptNull;};
		if !(InfectedPlayerScriptHandle isEqualTo scriptNull) then {terminate InfectedPlayerScriptHandle;};

		[] spawn 
		{
			sleep 1;

			comment "Check if full zombie already";
			if(isInfectedPlayerFullZombie && alive player) then 
			{
				player switchMove "AmovPercMstpSnonWnonDnon";
				player setUnconscious true; 
				sleep 10;
				player setUnconscious false;
				player playMoveNow "AmovPpneMstpSnonWnonDnon"; 
			};
			isInfectedPlayerFullZombie = false;

			comment "Play cure sound";
			_isInfected = player getVariable "isInfected";
			if (alive player && (!isNil "_isInfected")) then 
			{
				private _sounds = [
					"a3\sounds_f\characters\human-sfx\other\vzkriseni_01.wss",
					"a3\sounds_f\characters\human-sfx\other\vzkriseni_02.wss",
					"a3\sounds_f\characters\human-sfx\other\vzkriseni_03.wss",
					"a3\sounds_f\characters\human-sfx\other\vzkriseni_04.wss"
				];
				_sound = selectRandom _sounds;
				playSound3D [_sound,player,false,getPosATL player,5,1,125];
				playSound3D [_sound,player,false,getPosATL player,5,1,125];
			};

			player setVariable ["isInfected",nil];
			player setVariable ["isZombie",nil,true];
		};
	};
	
	ZSC_fnc_infectPlayer = {
		params["_player"];

		comment "🤮";
		comment "[cursorTarget] remoteExec ['ZSC_fnc_infectPlayer',owner cursorTarget]";

		if (!hasInterface) exitWith {};
		if !(player isEqualTo _player) exitWith {};
		if (player in call BIS_fnc_listCuratorPlayers) exitWith {};
		_infected = player getVariable "isInfected";
		if !(isNil "_infected") exitWith {};
		if (!alive player) exitWith {call ZSC_fnc_cancelInfectPlayer;};

		comment "Check if player is infected for the first time";
		_hasBeenInfected = player getVariable "hasBeenInfected";
		if (isNil "_hasBeenInfected") then {[] spawn ZSC_fnc_spawnInfectionHints;};
		
		InfectedPlayerScriptHandle = [] spawn 
		{
			isInfectedHeartBeatAllowed = false;
			isInfectedCoughingAllowed = false;

			player setVariable ["isZombie",true,true];
			player setVariable ["isInfected",true];

			comment "incubation time";
			_incubationDelay = 120;

			comment "create gradient effects";
			with uiNamespace do 
			{
				InfectedGradients = [];
				_ctrl = (findDisplay 46) ctrlCreate ["RscPicture",-1];
				_ctrl ctrlSetText "\A3\ui_f\data\gui\rsccommon\rscvignette\vignette_gs.paa";
				_ctrl ctrlSetPosition [safeZoneX,safeZoneY,safeZoneW,safeZoneH];
				_ctrl ctrlSetTextColor [0,1,0,0.5];
				_ctrl ctrlSetFade 1;
				_ctrl ctrlCommit 0;
				_ctrl ctrlSetFade 0;
				_ctrl ctrlCommit _incubationDelay;
				InfectedGradients pushBack _ctrl;
				_ctrl = (findDisplay 46) ctrlCreate ["RscPicture",-1];
				_ctrl ctrlSetText "\A3\ui_f\data\gui\rsccommon\rscvignette\vignette_gs.paa";
				_ctrl ctrlSetPosition [safeZoneX,safeZoneY,safeZoneW,safeZoneH];
				_ctrl ctrlSetTextColor [0.35,0,0,0.9];
				_ctrl ctrlSetFade 1;
				_ctrl ctrlCommit 0;
				_ctrl ctrlSetFade 0;
				_ctrl ctrlCommit _incubationDelay;
				InfectedGradients pushBack _ctrl;
			};

			comment "Start coughing effects";
			[] spawn 
			{
				isInfectedCoughingAllowed = true;
				while {isInfectedCoughingAllowed && isZombieSystemAllowed} do 
				{	
					sleep random [5,10,15];
					if !(isInfectedCoughingAllowed) exitWith {};
					_sounds = 
					[
						"a3\sounds_F\characters\human-sfx\person0\P0_choke_02.wss",
						"a3\sounds_F\characters\human-sfx\person0\P0_choke_03.wss",
						"a3\sounds_F\characters\human-sfx\person0\P0_choke_04.wss",
						"a3\sounds_F\characters\human-sfx\person1\P1_choke_04.wss",
						"a3\sounds_F\characters\human-sfx\person2\P2_choke_04.wss",
						"a3\sounds_F\characters\human-sfx\person3\P3_choke_02.wss"
					];

					_sound = selectRandom _sounds; 
					playSound3D [_sound,player,false,getPosASL player,5,1,100];
					playSound3D [_sound,player,false,getPosASL player,5,1,100];
					playSound3D ["a3\sounds_F\characters\human-sfx\08_hum_inside_head1.wss",player,false,getPosASL player,5,0.75,100];
					playSound3D ["a3\sounds_F\characters\human-sfx\08_hum_inside_head1.wss",player,false,getPosASL player,5,0.75,100];

					if !(isInfectedHeartBeatAllowed) then 
					{
						player playAction "GestureAgonyCargo";
						sleep 3;
						if(isInfectedHeartBeatAllowed) exitWith {};
						player playAction "gestureNod";
					};
				};
			};
			
			sleep _incubationDelay;
			sleep InfectedPlayerMedicationDelay;

			addCamShake [7.5, 180, 2];
			player playAction "GestureAgonyCargo";

			comment "heart beat effects";
			[] spawn 
			{
				isInfectedHeartBeatAllowed = true;
				_scalar = 10;
				_delay = 1;
				_i = 1;
				while {_delay > 0 && isInfectedHeartBeatAllowed && isZombieSystemAllowed} do 
				{
					playSound3D ["a3\sounds_F\characters\human-sfx\05_heart_1.wss",player,false,getPosASL player,5,1,100];
					playSound3D ["a3\sounds_F\characters\human-sfx\05_heart_1.wss",player,false,getPosASL player,5,1,100];
					playSound3D ["a3\sounds_F\characters\human-sfx\05_heart_1.wss",player,false,getPosASL player,5,1,100];
					playSound3D ["a3\sounds_F\characters\human-sfx\05_heart_1.wss",player,false,getPosASL player,5,1,100];
					sleep (_delay*_scalar);
					_i = (_i + 1);
					if(_i < 20) then {_delay = (1/_i);};
				};
			};
	
			sleep 30;
	
			player setUnconscious true;
			moveOut player;
			addCamShake [15, 60, 25];

			with uiNamespace do 
			{
				InfectedDarkImages = [];
				_ctrl = (findDisplay 46) ctrlCreate ["RscPicture",-1];
				_ctrl ctrlSetText "#(argb,8,8,3)color(1,1,1,1)";
				_ctrl ctrlSetPosition [safeZoneX,safeZoneY,safeZoneW,safeZoneH];
				_ctrl ctrlSetTextColor [0,0,0,0.85];
				_ctrl ctrlSetFade 1;
				_ctrl ctrlCommit 0;
				_ctrl ctrlSetFade 0;
				_ctrl ctrlCommit 5;
				InfectedDarkImages pushBack _ctrl;
				_ctrl = (findDisplay 46) ctrlCreate ["RscPicture",-1];
				_ctrl ctrlSetText "\A3\ui_f\data\gui\rsccommon\rscvignette\vignette_gs.paa";
				_ctrl ctrlSetPosition [safeZoneX,safeZoneY,safeZoneW,safeZoneH];
				_ctrl ctrlSetTextColor [0,0,0,1];
				_ctrl ctrlSetFade 1;
				_ctrl ctrlCommit 0;
				_ctrl ctrlSetFade 0;
				_ctrl ctrlCommit 5;
				InfectedDarkImages pushBack _ctrl;
			};

			sleep 15;

			isInfectedCoughingAllowed = false;
			isInfectedHeartBeatAllowed = false;
			isInfectedPlayerFullZombie = true;
	
			player playAction "gestureNod";
			player addRating ((-1*(rating player))-10000);
			player addRating ((-1*(rating player))-10000);
			player setDamage 0.4;
			removeAllWeapons player;
			player setUnconscious false;
			[player] call BIS_fnc_reviveEhRespawn;
			player setUnconscious false;
			player setCaptive false;
			waitUntil 
			{
				player playMoveNow "AmovPpneMstpSnonWnonDnon";
				sleep 0.2;
				animationState player isEqualTo "amovppnemstpsnonwnondnon"
			};
			player switchMove "ApanPknlMstpSnonWnonDnon";

			playSound3D ["a3\sounds_F\characters\human-sfx\p02\max_hit_02.wss",player,false,getPosASL player,5,0.1,300];
			sleep 0.01;
			playSound3D ["a3\sounds_F\characters\human-sfx\p02\max_hit_02.wss",player,false,getPosASL player,5,0.1,300];
			playSound3D ["a3\sounds_F\characters\human-sfx\p02\max_hit_02.wss",player,false,getPosASL player,5,0.1,300];
			playSound3D ["a3\sounds_F\characters\human-sfx\p02\max_hit_02.wss",player,false,getPosASL player,5,0.1,300];
			playSound3D ["a3\sounds_F\characters\human-sfx\p02\max_hit_02.wss",player,false,getPosASL player,5,0.1,300];

			isZombieInfectedPlayerHitting = false;
			(findDisplay 46) displayAddEventHandler ["MouseButtonDown", 
			{
				[] spawn {
					if (isZombieInfectedPlayerHitting) exitWith {};
					_target = cursorTarget;
					_valid = false;
					_distance = player distance _target;
					_types = ["Man","Car","APC","Tank","Ship","Air","StaticWeapon"];
					{if(_target isKindOf _x) exitWith {_valid = true;};} foreach _types;
					_range = ZombieAttackRange;
					if !(_target isKindOf "Man") then {_range = 6;};
					if (_valid && (_distance <= _range)) then 
					{
						comment "Damage effects";
						_target setDamage (damage _target + ZombieAttackDamage);

						comment "Push vehicle with random strength";
						_vectorDir = vectorDir player;
						if (_target isKindOf "Man") then {_vectorDir set[2,(_vectorDir select 2)+0.5];};
						_force = random [2,5,8];
						_vectorVel = _vectorDir vectorMultiply _force;
						[[_target,((velocity _target) vectorAdd _vectorVel)],{if (local (_this select 0)) then {(_this select 0) setVelocity (_this select 1)};}] call ZSC_fnc_RE_Global;

						comment "Infect random chance";
						if ((ZombieInfectionChance >= random 100) && (isPlayer _target)) then {[[_target],{if (local (_this select 0)) then {_this call ZSC_fnc_infectPlayer;};}] call ZSC_fnc_RE_Global;};
					};
					[player,0] call ZSC_fnc_randomAttackSound;
					removeAllWeapons player;

					comment "Animation stuff";
					[[player,"AwopPercMstpSgthWnonDnon_end"],{(_this select 0) switchMove (_this select 1)}] call ZSC_fnc_RE_Global;
					isZombieInfectedPlayerHitting = true;
					sleep 0.8;
					[[player,"apanpercmstpsnonwnondnon"],{(_this select 0) switchMove (_this select 1)}] call ZSC_fnc_RE_Global;
					isZombieInfectedPlayerHitting = false;
					showChat true;
				};
			}];

			player addEventHandler ["GetInMan", {
				params ["_unit", "_role", "_vehicle", "_turret"];

				_isZombie = player getVariable "isZombie";
				if (isNil "_isZombie") exitWith {};
				moveOut player;
			}];

			{
				_x ctrlSetFade 1;
				_x ctrlCommit 5;
			} foreach (uiNamespace getVariable "InfectedDarkImages");

			[] spawn 
			{
				isInfectedRandomZombieSoundsAllowed = true;
				while {isInfectedRandomZombieSoundsAllowed && isZombieSystemAllowed} do {[player,1] call ZSC_fnc_randomAttackSound; sleep 3;};
			};
	
			waitUntil {(lifeState player isEqualTo "INCAPACITATED") || !alive player};
			
			call ZSC_fnc_cancelInfectPlayer;
			player setDamage 1;
		};
	};

	comment "[] spawn ZSC_fnc_initSpawnInfectionSupplies;";
}] remoteExec ["Spawn",0,"JIP_ID_zombieClient"];

comment "

// disable on server 

[[],{}] remoteExec ['Spawn',0,'JIP_ID_zombieClient'];
{deleteVehicle agent _x;} foreach agents;
{isZombieSystemAllowed = nil;} remoteExec ['BIS_fnc_call',0];


";