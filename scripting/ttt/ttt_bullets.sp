#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <ttt>
#include <ttt_shop>
#include <multicolors>

#pragma newdecls required

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Items: Bullets (Fire, Freeze, Poison)"
#define SHORT_NAME_ICE "bullets_ice"
#define SHORT_NAME_FIRE "bullets_fire"
#define SHORT_NAME_POISON "bullets_poison"

ConVar gIcePrice;
ConVar gIcePrio;
ConVar gIceNb;
ConVar gIceTimer;
ConVar gFirePrice;
ConVar gFirePrio;
ConVar gFireNb;
ConVar gFireTimer;
ConVar gPoisonPrice;
ConVar gPoisonPrio;
ConVar gPoisonNb;
ConVar gPoisonTimer;
ConVar gPoisonDmg;
ConVar gIceLongName;
ConVar gFireLongName;
ConVar gPoisonLongName;

int timerPoison[MAXPLAYERS + 1] = { 0, ... };

int bulletsIce[MAXPLAYERS + 1] =  { 0, ... };
int bulletsFire[MAXPLAYERS + 1] =  { 0, ... };
int bulletsPoison[MAXPLAYERS + 1] =  { 0, ... };

bool hasIce[MAXPLAYERS + 1] =  { false, ... };
bool hasFire[MAXPLAYERS + 1] =  { false, ... };
bool hasPoison[MAXPLAYERS + 1] =  { false, ... };

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = TTT_PLUGIN_AUTHOR,
	description = TTT_PLUGIN_DESCRIPTION,
	version = TTT_PLUGIN_VERSION,
	url = TTT_PLUGIN_URL
};

public void OnPluginStart()
{
	TTT_IsGameCSGO();

	LoadTranslations("ttt.phrases");
	LoadTranslations("ttt_bullets.phrases");
	
	StartConfig("bullets");
	CreateConVar("bullets_version", TTT_PLUGIN_VERSION, TTT_PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_REPLICATED);
	gIceLongName = AutoExecConfig_CreateConVar("bullets_ice", "Bullets (Ice)", "The name of this in Shop");
	gFireLongName = AutoExecConfig_CreateConVar("bullets_fire", "Bullets (Fire)", "The name of this in Shop");
	gPoisonLongName = AutoExecConfig_CreateConVar("bullets_poison", "Bullets (Poison)", "The name of this in Shop");	
	gIcePrice = AutoExecConfig_CreateConVar("bullets_ice_price", "5000", "The amount of credits ice bullets costs as traitor. 0 to disable.");
	gIcePrio = AutoExecConfig_CreateConVar("bullets_ice_sort_prio", "0", "The sorting priority of the ice bullets in the shop menu.");
	gIceNb = AutoExecConfig_CreateConVar("bullets_ice_number", "5", "The number of ice bullets that the player can use");
	gIceTimer = AutoExecConfig_CreateConVar("bullets_ice_timer", "2.0", "The time the target should be frozen");		
	gFirePrice = AutoExecConfig_CreateConVar("bullets_fire_price", "5000", "The amount of credits fire bullets costs as traitor. 0 to disable.");
	gFirePrio = AutoExecConfig_CreateConVar("bullets_fire_sort_prio", "0", "The sorting priority of the fire bullets in the shop menu.");
	gFireNb = AutoExecConfig_CreateConVar("bullets_fire_number", "5", "The number of fire bullets that the player can use per time");	
	gFireTimer = AutoExecConfig_CreateConVar("bullets_fire_timer", "2.0", "The time the target should be burned");			
	gPoisonPrice = AutoExecConfig_CreateConVar("bullets_poison_price", "5000", "The amount of credits poison bullets costs as traitor. 0 to disable.");
	gPoisonPrio = AutoExecConfig_CreateConVar("bullets_poison_sort_prio", "0", "The sorting priority of the poison bullets in the shop menu.");
	gPoisonNb = AutoExecConfig_CreateConVar("bullets_poison_number", "5", "The number of poison bullets that the player can use per time");
	gPoisonTimer = AutoExecConfig_CreateConVar("bullets_poison_timer", "2", "The number of time the target should be poisened");		
	gPoisonDmg = AutoExecConfig_CreateConVar("bullets_poison_dmg", "5", "The damage the target should receive per time");	
	EndConfig();	

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_hurt", Event_PlayerHurt);
}

public void OnClientDisconnect(int client)
{
	ResetTemplate(client);
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort, bool count)
{
	if (TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (StrEqual(itemshort, SHORT_NAME_ICE, false))
		{
			int role = TTT_GetClientRole(client);
			ConVar cvTag = FindConVar("ttt_plugin_tag");
			char tag[128];
			char itemName[128];
			cvTag.GetString(tag, sizeof(tag));
			gIceLongName.GetString(itemName, sizeof(itemName));
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, tag, "Have already", client);
				return Plugin_Stop;
			}

			hasIce[client] = true;
			bulletsIce[client] += gIceNb.IntValue;
			CPrintToChat(client, tag, "Buy bullets", client, bulletsIce[client], itemName);		
		}
		
		else if (StrEqual(itemshort, SHORT_NAME_FIRE, false))
		{
			int role = TTT_GetClientRole(client);
			ConVar cvTag = FindConVar("ttt_plugin_tag");
			char tag[128];
			char itemName[128];
			cvTag.GetString(tag, sizeof(tag));
			gFireLongName.GetString(itemName, sizeof(itemName));
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, tag, "Have already", client);
				return Plugin_Stop;
			}		

			hasFire[client] = true;
			bulletsFire[client] += gFireNb.IntValue;
			CPrintToChat(client, tag, "Buy bullets", client, bulletsFire[client], itemName);					
		}	

		else if (StrEqual(itemshort, SHORT_NAME_POISON, false))
		{
			int role = TTT_GetClientRole(client);
			ConVar cvTag = FindConVar("ttt_plugin_tag");
			char tag[128];
			char itemName[128];
			cvTag.GetString(tag, sizeof(tag));
			gPoisonLongName.GetString(itemName, sizeof(itemName));			
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, tag, "Have already", client);
				return Plugin_Stop;
			}			

			hasPoison[client] = true;
			bulletsPoison[client] += gPoisonNb.IntValue;
			CPrintToChat(client, tag, "Buy bullets", client, bulletsPoison[client], itemName);		
		}	
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (TTT_IsClientValid(client))
	{
		ResetTemplate(client);
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (TTT_IsClientValid(client))
	{
		if (hasIce[attacker])
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntityRenderColor(client, 0, 128, 255, 192);
			CreateTimer(gIceTimer.FloatValue, TimerIce, GetClientUserId(client));
		}
		else if (hasFire[attacker])
		{
			IgniteEntity(client, gFireTimer.FloatValue);
		}
		else if (hasPoison[attacker])
		{
			CreateTimer(1.0, TimerPoison, GetClientUserId(client), TIMER_REPEAT); 
		}			
	}
	return Plugin_Continue;	
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (TTT_IsClientValid(client) && IsWeapon(weapon))
	{
		char tag[128];
		ConVar cvTag = FindConVar("ttt_plugin_tag");	
		cvTag.GetString(tag, sizeof(tag));
		
		if (hasIce[client])
		{
			char itemName[128];	
			gIceLongName.GetString(itemName, sizeof(itemName));		
			bulletsIce[client]--;
			CPrintToChat(client, tag, "{orchid}{%s} : {lightgreen}{%d}/{green}{%d}.", client, itemName, bulletsIce[client], gIceNb.IntValue);
			if (bulletsIce[client] <= 0)
			{
				hasIce[client] = false;
			}
		}
		else if (hasFire[client])
		{
			char itemName[128];	
			gFireLongName.GetString(itemName, sizeof(itemName));					
			bulletsFire[client]--;
			CPrintToChat(client, tag, "{orchid}{%s} : {lightgreen}{%d}/{green}{%d}.", client, itemName, bulletsFire[client], gFireNb.IntValue);
			if (bulletsFire[client] <= 0)
			{
				hasFire[client] = false;
			}		
		}
		else if (hasPoison[client])
		{
			char itemName[128];	
			gPoisonLongName.GetString(itemName, sizeof(itemName));			
			bulletsPoison[client]--;
			CPrintToChat(client, tag, "{orchid}{%s} : {lightgreen}{%d}/{green}{%d}.", client, itemName, bulletsPoison[client], gPoisonNb.IntValue);
			if (bulletsPoison[client] <= 0)
			{
				hasPoison[client] = false;
			}			
		}	
	}
	return Plugin_Continue;
}

public Action TimerIce(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (TTT_IsClientValid(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	return Plugin_Handled;
}

public Action TimerPoison(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if (TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (timerPoison[client] <= gPoisonTimer.IntValue)
		{
			SetEntityRenderColor(client, 78, 7, 104, 192);
			SetEntityHealth(client, GetClientHealth(client) - gPoisonDmg.IntValue);
			SetEntityRenderColor(client);
			timerPoison[client]++;
		}
		if (GetClientHealth(client) <= 0)
		{
			ForcePlayerSuicide(client);
			timerPoison[client] = 0;
			return Plugin_Stop;		
		}
		else
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

public void OnAllPluginsLoaded()
{
	char itemName[128];
	gIceLongName.GetString(itemName, sizeof(itemName));	
	TTT_RegisterCustomItem(SHORT_NAME_ICE, itemName, gIcePrice.IntValue, TTT_TEAM_TRAITOR, gIcePrio.IntValue);
	gFireLongName.GetString(itemName, sizeof(itemName));		
	TTT_RegisterCustomItem(SHORT_NAME_FIRE, itemName, gFirePrice.IntValue, TTT_TEAM_TRAITOR, gFirePrio.IntValue);
	gPoisonLongName.GetString(itemName, sizeof(itemName));		
	TTT_RegisterCustomItem(SHORT_NAME_POISON, itemName, gPoisonPrice.IntValue, TTT_TEAM_TRAITOR, gPoisonPrio.IntValue);	
}

void ResetTemplate(int client)
{
	bulletsIce[client] = 0;
	bulletsFire[client] = 0;
	bulletsPoison[client] = 0;
	hasIce[client] = false;
	hasFire[client] = false;
	hasPoison[client] = false;
}

bool HasBullets(int client)
{
	bool result = false;
	if (hasIce[client])
		result = true;
	else if (hasFire[client])
		result = true;
	else if (hasPoison[client])		
		result = true;
	return result;
}

bool IsWeapon(char[] weapon)
{
	bool result = true;
	if (StrContains(weapon, "nade") != -1 || StrContains(weapon, "knife") != -1 || StrContains(weapon, "healthshot") != -1 || StrContains(weapon, "molotov") != -1  || StrContains(weapon, "decoy"))
	{
		result = false;
	}	
	return result;
}