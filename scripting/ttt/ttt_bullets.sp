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

/* ConVars of the plugin */
ConVar cvIcePrice;
ConVar cvIcePrio;
ConVar cvIceNb;
ConVar cvIceTimer;
ConVar cvFirePrice;
ConVar cvFirePrio;
ConVar cvFireNb;
ConVar cvFireTimer;
ConVar cvPoisonPrice;
ConVar cvPoisonPrio;
ConVar cvPoisonNb;
ConVar cvPoisonTimer;
ConVar cvPoisonDmg;
ConVar cvIceLongName;
ConVar cvFireLongName;
ConVar cvPoisonLongName;
ConVar cvTag;

/* Global vars */
int gTimerPoison[MAXPLAYERS + 1] = { 0, ... };

int gBulletsIce[MAXPLAYERS + 1] =  { 0, ... };
int gBulletsFire[MAXPLAYERS + 1] =  { 0, ... };
int gBulletsPoison[MAXPLAYERS + 1] =  { 0, ... };

bool gHasIce[MAXPLAYERS + 1] =  { false, ... };
bool gHasFire[MAXPLAYERS + 1] =  { false, ... };
bool gHasPoison[MAXPLAYERS + 1] =  { false, ... };

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
	cvIceLongName = AutoExecConfig_CreateConVar("bullets_ice", "Bullets (Ice)", "The name of this in Shop");
	cvFireLongName = AutoExecConfig_CreateConVar("bullets_fire", "Bullets (Fire)", "The name of this in Shop");
	cvPoisonLongName = AutoExecConfig_CreateConVar("bullets_poison", "Bullets (Poison)", "The name of this in Shop");	
	cvIcePrice = AutoExecConfig_CreateConVar("bullets_ice_price", "5000", "The amount of credits ice bullets costs as traitor. 0 to disable.");
	cvIcePrio = AutoExecConfig_CreateConVar("bullets_ice_sort_prio", "0", "The sorting priority of the ice bullets in the shop menu.");
	cvIceNb = AutoExecConfig_CreateConVar("bullets_ice_number", "5", "The number of ice bullets that the player can use");
	cvIceTimer = AutoExecConfig_CreateConVar("bullets_ice_timer", "2.0", "The time the target should be frozen");		
	cvFirePrice = AutoExecConfig_CreateConVar("bullets_fire_price", "5000", "The amount of credits fire bullets costs as traitor. 0 to disable.");
	cvFirePrio = AutoExecConfig_CreateConVar("bullets_fire_sort_prio", "0", "The sorting priority of the fire bullets in the shop menu.");
	cvFireNb = AutoExecConfig_CreateConVar("bullets_fire_number", "5", "The number of fire bullets that the player can use per time");	
	cvFireTimer = AutoExecConfig_CreateConVar("bullets_fire_timer", "2.0", "The time the target should be burned");			
	cvPoisonPrice = AutoExecConfig_CreateConVar("bullets_poison_price", "5000", "The amount of credits poison bullets costs as traitor. 0 to disable.");
	cvPoisonPrio = AutoExecConfig_CreateConVar("bullets_poison_sort_prio", "0", "The sorting priority of the poison bullets in the shop menu.");
	cvPoisonNb = AutoExecConfig_CreateConVar("bullets_poison_number", "5", "The number of poison bullets that the player can use per time");
	cvPoisonTimer = AutoExecConfig_CreateConVar("bullets_poison_timer", "2", "The number of time the target should be poisened");		
	cvPoisonDmg = AutoExecConfig_CreateConVar("bullets_poison_dmg", "5", "The damage the target should receive per time");	
	EndConfig();	

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_hurt", Event_PlayerHurt);
	
	cvTag = FindConVar("ttt_plugin_tag");
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort, bool count)
{
	/*
		Check if the client is valid and alive
		For each type of bullets, we check
		IF the client is traitor, the inventory of client is empty
		THEN we give him the bullets
		ELSE we stop the action and print a message
	*/
	if (TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (StrEqual(itemshort, SHORT_NAME_ICE, false))
		{
			int role = TTT_GetClientRole(client);
			char tag[128];
			char itemName[128];
			cvTag.GetString(tag, sizeof(tag));
			cvIceLongName.GetString(itemName, sizeof(itemName));
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, "%s %t", tag, "Have already");
				return Plugin_Stop;
			}

			gHasIce[client] = true;
			gBulletsIce[client] += cvIceNb.IntValue;
			CPrintToChat(client, "%s %t", tag, "Buy bullets", gBulletsIce[client], itemName);		
		}
		
		else if (StrEqual(itemshort, SHORT_NAME_FIRE, false))
		{
			int role = TTT_GetClientRole(client);
			char tag[128];
			char itemName[128];
			cvTag.GetString(tag, sizeof(tag));
			cvFireLongName.GetString(itemName, sizeof(itemName));
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, "%s %t", tag, "Have already");
				return Plugin_Stop;
			}		

			gHasFire[client] = true;
			gBulletsFire[client] += cvFireNb.IntValue;
			CPrintToChat(client, "%s %t", tag, "Buy bullets", gBulletsFire[client], itemName);					
		}	

		else if (StrEqual(itemshort, SHORT_NAME_POISON, false))
		{
			int role = TTT_GetClientRole(client);
			char tag[128];
			char itemName[128];
			cvTag.GetString(tag, sizeof(tag));
			cvPoisonLongName.GetString(itemName, sizeof(itemName));			
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, "%s %t", tag, "Have already");
				return Plugin_Stop;
			}			

			gHasPoison[client] = true;
			gBulletsPoison[client] += cvPoisonNb.IntValue;
			CPrintToChat(client, "%s %t", tag, "Buy bullets", gBulletsPoison[client], itemName);		
		}	
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	/* 
		Reset the inventory of the client
	*/
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (TTT_IsClientValid(client))
	{
		ResetBullets(client);
	}
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	/*
		IF a client is hurt and has one type of bullets
		THEN we apply the desired effet
	*/
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (TTT_IsClientValid(client))
	{
		if (gHasIce[attacker])
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntityRenderColor(client, 0, 128, 255, 192);
			CreateTimer(cvIceTimer.FloatValue, TimerIce, GetClientUserId(client));
		}
		else if (gHasFire[attacker])
		{
			IgniteEntity(client, cvFireTimer.FloatValue);
		}
		else if (gHasPoison[attacker])
		{
			CreateTimer(1.0, TimerPoison, GetClientUserId(client), TIMER_REPEAT); 
		}			
	}
	return Plugin_Continue;	
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	/*
		After each shot, we check if the client has a normal weapon (primary and secondary) and if he have a type of bullets
		IF he have a type of bullets
		THEN we decrease the number of bullets of client + disable the bullets of the client if bullets = 0
	*/
	int client = GetClientOfUserId(event.GetInt("userid"));
	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (TTT_IsClientValid(client) && IsWeapon(weapon))
	{	
		if (gHasIce[client])
		{
			char tag[128];
			char itemName[128];	
			cvTag.GetString(tag, sizeof(tag));
			cvIceLongName.GetString(itemName, sizeof(itemName));		
			gBulletsIce[client]--;
			CPrintToChat(client, "%s %t", tag, "Number bullets", itemName, gBulletsIce[client], cvIceNb.IntValue);			
			if (gBulletsIce[client] <= 0)
			{
				gHasIce[client] = false;
			}
		}
		else if (gHasFire[client])
		{
			char tag[128];
			char itemName[128];	
			cvTag.GetString(tag, sizeof(tag));
			cvFireLongName.GetString(itemName, sizeof(itemName));					
			gBulletsFire[client]--;
			CPrintToChat(client, "%s %t", tag, "Number bullets", itemName, gBulletsFire[client], cvFireNb.IntValue);
			if (gBulletsFire[client] <= 0)
			{
				gHasFire[client] = false;
			}
		}
		else if (gHasPoison[client])
		{
			char tag[128];
			char itemName[128];	
			cvTag.GetString(tag, sizeof(tag));
			cvPoisonLongName.GetString(itemName, sizeof(itemName));			
			gBulletsPoison[client]--;
			CPrintToChat(client, "%s %t", tag, "Number bullets", itemName, gBulletsPoison[client], cvPoisonNb.IntValue);
			if (gBulletsPoison[client] <= 0)
			{
				gHasPoison[client] = false;
			}	
		}	
	}
	return Plugin_Continue;
}

public Action TimerIce(Handle timer, any userid)
{
	/* 
		Unfreeze the client and put his playerskin color back to normal
		IF client is valid and alive
		THEN remove the freeze and the color on the client
	*/
	int client = GetClientOfUserId(userid);
	if (TTT_IsClientValid(client))
	{
		if (IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntityRenderColor(client);
		}
	}
	return Plugin_Handled;
}

public Action TimerPoison(Handle timer, any userid)
{
	/*
		Remove health from the player each seconds
		IF client is valid and alive + timer is on
		THEN we remove health and toggle the color
		IF after that, the health is under 0
		THEN we kill the client
		ELSE We let the timer continue or stop it
	*/
	int client = GetClientOfUserId(userid);
	
	if (TTT_IsClientValid(client))
	{
		if (IsPlayerAlive(client))
		{
			if (gTimerPoison[client] <= cvPoisonTimer.IntValue)
			{
				SetEntityRenderColor(client, 78, 7, 104, 192);
				SetEntityHealth(client, GetClientHealth(client) - cvPoisonDmg.IntValue);
				SetEntityRenderColor(client);
				gTimerPoison[client]++;
			}
			if (GetClientHealth(client) <= 0)
			{
				ForcePlayerSuicide(client);
				gTimerPoison[client] = 0;
				return Plugin_Stop;		
			}
			else
			{
				if (gTimerPoison[client] > cvPoisonTimer.IntValue)
				{
					gTimerPoison[client] = 0;
					return Plugin_Stop;			
				}
				return Plugin_Continue;
			}
		}
	}	
	return Plugin_Stop;
}

public void OnConfigsExecuted()
{
	char itemName[128];
	cvIceLongName.GetString(itemName, sizeof(itemName));	
	TTT_RegisterCustomItem(SHORT_NAME_ICE, itemName, cvIcePrice.IntValue, TTT_TEAM_TRAITOR, cvIcePrio.IntValue);
	cvFireLongName.GetString(itemName, sizeof(itemName));		
	TTT_RegisterCustomItem(SHORT_NAME_FIRE, itemName, cvFirePrice.IntValue, TTT_TEAM_TRAITOR, cvFirePrio.IntValue);
	cvPoisonLongName.GetString(itemName, sizeof(itemName));		
	TTT_RegisterCustomItem(SHORT_NAME_POISON, itemName, cvPoisonPrice.IntValue, TTT_TEAM_TRAITOR, cvPoisonPrio.IntValue);	
}

void ResetBullets(int client)
{
	/*
		Reset the inventory of client
	*/
	gBulletsIce[client] = 0;
	gBulletsFire[client] = 0;
	gBulletsPoison[client] = 0;
	gHasIce[client] = false;
	gHasFire[client] = false;
	gHasPoison[client] = false;
}

bool HasBullets(int client)
{
	/* 
		Check if the client has one type of bullets
	*/
	bool result = false;
	if (gHasIce[client] || gHasFire[client] || gHasPoison[client])
		result = true;
	return result;
}

bool IsWeapon(char[] weapon)
{
	/* 
		Check if the client is using a primary or a secondary weapon
	*/
	bool result = true;
	if (StrContains(weapon, "nade") != -1 
	|| StrContains(weapon, "knife") != -1 
	|| StrContains(weapon, "healthshot") != -1 
	|| StrContains(weapon, "molotov") != -1  
	|| StrContains(weapon, "decoy") != -1
	|| StrContains(weapon, "c4") != -1
	|| StrContains(weapon, "flashbang") != -1
	|| StrContains(weapon, "taser") != -1)
	{
		result = false;
	}	
	return result;
}