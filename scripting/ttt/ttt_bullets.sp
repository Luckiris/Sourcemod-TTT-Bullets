#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <ttt>
#include <ttt_shop>
#include <config_loader>
#include <multicolors>

#pragma newdecls required

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Items: Bullets (Fire, Freeze, Poison)"
#define SHORT_NAME_ICE "bullets_ice"
#define SHORT_NAME_FIRE "bullets_fire"
#define SHORT_NAME_POISON "bullets_poison"

int gIcePrice = 0;
int gIcePrio = 0;
int gIceNb = 0;
float gIceTimer = 0.0;
int gFirePrice = 0;
int gFirePrio = 0;
int gFireNb = 0;
float gFireTimer = 0.0;
int gPoisonPrice = 0;
int gPoisonPrio = 0;
int gPoisonNb = 0;
int gPoisonTimer = 0;
int gPoisonDmg = 0;

int timerPoison[MAXPLAYERS + 1] = { 0, ... };

int bulletsIce[MAXPLAYERS + 1] =  { 0, ... };
int bulletsFire[MAXPLAYERS + 1] =  { 0, ... };
int bulletsPoison[MAXPLAYERS + 1] =  { 0, ... };

bool hasIce[MAXPLAYERS + 1] =  { false, ... };
bool hasFire[MAXPLAYERS + 1] =  { false, ... };
bool hasPoison[MAXPLAYERS + 1] =  { false, ... };

char g_sConfigFile[PLATFORM_MAX_PATH] = "";
char g_sPluginTag[PLATFORM_MAX_PATH] = "";
char gIceLongName[64];
char gFireLongName[64];
char gPoisonLongName[64];

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

	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/config.cfg");
	Config_Setup("TTT", g_sConfigFile);

	Config_LoadString("ttt_plugin_tag", "{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %T", "The prefix used in all plugin messages (DO NOT DELETE '%T')", g_sPluginTag, sizeof(g_sPluginTag));

	Config_Done();

	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/bullets.cfg");
	Config_Setup("TTT-Bullets", g_sConfigFile);

	Config_LoadString("bullets_ice", "Bullets (Ice)", "The name of this in Shop", gIceLongName, sizeof(gIceLongName));
	Config_LoadString("bullets_fire", "Bullets (Fire)", "The name of this in Shop", gFireLongName, sizeof(gFireLongName));
	Config_LoadString("bullets_poison", "Bullets (Poison)", "The name of this in Shop", gPoisonLongName, sizeof(gPoisonLongName));
	
	gIcePrice = Config_LoadInt("bullets_ice_price", 5000, "The amount of credits ice bullets costs as traitor. 0 to disable.");
	gIcePrio = Config_LoadInt("bullets_ice_sort_prio", 0, "The sorting priority of the ice bullets in the shop menu.");
	gIceNb = Config_LoadInt("bullets_ice_number", 5, "The number of ice bullets that the player can use");
	gIceTimer = Config_LoadFloat("bullets_ice_timer", 2.0, "The time the target should be frozen");	
	
	gFirePrice = Config_LoadInt("bullets_fire_price", 5000, "The amount of credits fire bullets costs as traitor. 0 to disable.");
	gFirePrio = Config_LoadInt("bullets_fire_sort_prio", 0, "The sorting priority of the fire bullets in the shop menu.");
	gFireNb = Config_LoadInt("bullets_fire_number", 5, "The number of fire bullets that the player can use per time");	
	gFireTimer = Config_LoadFloat("bullets_fire_timer", 2.0, "The time the target should be burned");		
	
	gPoisonPrice = Config_LoadInt("bullets_poison_price", 5000, "The amount of credits poison bullets costs as traitor. 0 to disable.");
	gPoisonPrio = Config_LoadInt("bullets_poison_sort_prio", 0, "The sorting priority of the poison bullets in the shop menu.");
	gPoisonNb = Config_LoadInt("bullets_poison_number", 5, "The number of poison bullets that the player can use per time");
	gPoisonTimer = Config_LoadInt("bullets_poison_timer", 2, "The number of time the target should be poisened");		
	gPoisonDmg = Config_LoadInt("bullets_poison_dmg", 5, "The damage the target should receive per time");	
	
	Config_Done();

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
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, g_sPluginTag, "Have already", client);
				return Plugin_Stop;
			}

			hasIce[client] = true;
			bulletsIce[client] += gIceNb;
			CPrintToChat(client, g_sPluginTag, "Buy bullets", client, bulletsIce[client], gIceLongName);		
		}
		
		else if (StrEqual(itemshort, SHORT_NAME_FIRE, false))
		{
			int role = TTT_GetClientRole(client);
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, g_sPluginTag, "Have already", client);
				return Plugin_Stop;
			}		

			hasFire[client] = true;
			bulletsFire[client] += gFireNb;
			CPrintToChat(client, g_sPluginTag, "Buy bullets", client, bulletsFire[client], gFireLongName);					
		}	

		else if (StrEqual(itemshort, SHORT_NAME_POISON, false))
		{
			int role = TTT_GetClientRole(client);
			
			if (role != TTT_TEAM_TRAITOR)
			{
				return Plugin_Stop;
			}
			else if (HasBullets(client))
			{
				CPrintToChat(client, g_sPluginTag, "Have already", client);
				return Plugin_Stop;
			}			

			hasPoison[client] = true;
			bulletsPoison[client] += gPoisonNb;
			CPrintToChat(client, g_sPluginTag, "Buy bullets", client, bulletsPoison[client], gPoisonLongName);		
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
			CreateTimer(gIceTimer, TimerIce, GetClientUserId(client));
		}
		else if (hasFire[attacker])
		{
			IgniteEntity(client, gFireTimer);
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
		if (hasIce[client])
		{
			bulletsIce[client]--;
			CPrintToChat(client, g_sPluginTag, "Number bullets", client, gIceLongName, bulletsIce[client], gIceNb);
			if (bulletsIce[client] <= 0)
			{
				hasIce[client] = false;
			}
		}
		else if (hasFire[client])
		{
			bulletsFire[client]--;
			CPrintToChat(client, g_sPluginTag, "Number bullets", client, gFireLongName, bulletsFire[client], gFireNb);
			if (bulletsFire[client] <= 0)
			{
				hasFire[client] = false;
			}		
		}
		else if (hasPoison[client])
		{
			bulletsPoison[client]--;
			CPrintToChat(client, g_sPluginTag, "Number bullets", client, gPoisonLongName, bulletsPoison[client], gPoisonNb);
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
		if (timerPoison[client] <= gPoisonTimer)
		{
			SetEntityRenderColor(client, 78, 7, 104, 255);
			SetEntityHealth(client, GetClientHealth(client) - gPoisonDmg);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			timerPoison[client]++;
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
	}
	return Plugin_Stop;
}

public void OnAllPluginsLoaded()
{
	TTT_RegisterCustomItem(SHORT_NAME_ICE, gIceLongName, gIcePrice, TTT_TEAM_TRAITOR, gIcePrio);
	TTT_RegisterCustomItem(SHORT_NAME_FIRE, gFireLongName, gFirePrice, TTT_TEAM_TRAITOR, gFirePrio);
	//TTT_RegisterCustomItem(SHORT_NAME_POISON, gPoisonLongName, gPoisonPrice, TTT_TEAM_TRAITOR, gPoisonPrio);	
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
	if (StrContains(weapon, "nade") != -1 || StrContains(weapon, "knife") != -1 || StrContains(weapon, "healthshot") != -1 || StrContains(weapon, "molotov") != -1)
	{
		result = false;
	}	
	return result;
}