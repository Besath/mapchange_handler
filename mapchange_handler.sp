#include <sourcemod>

ConVar sm_mc_timelimit = null;
ConVar sm_nextmap = null;
float g_TimeToChange;
Handle g_MapChangeTimer;
int g_PlayerCount = 0;

public Plugin myinfo = 
{
	name = "Empty Server Mapchange Handler",
	author = "Besath",
	description = "This plugin pauses map changes when there are players in the server and resumes them when the server is empty",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	sm_mc_timelimit = CreateConVar("sm_mc_timelimit", "20", "Time in minutes before map changes when server is empty");
	HookConVarChange(sm_mc_timelimit, Timer_Changed);
	sm_nextmap = FindConVar("sm_nextmap");
}
// Restart timer when sm_mc_timelimit changes
public void Timer_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	PrintToServer("[SM] Maps will change every %d minutes when server is empty.", sm_mc_timelimit.IntValue);
	if(g_MapChangeTimer != INVALID_HANDLE)
	{
		KillTimer(g_MapChangeTimer);
		CreateMapchangeTimer();
	}
}

public void OnMapStart()
{
	CreateMapchangeTimer();
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		g_PlayerCount--;
	}
}

public OnClientDisconnect_Post(int client)
{
	CreateMapchangeTimer();
}
// Kill timer if it's running when a player connects
public OnClientConnected(int client)
{
	if(g_MapChangeTimer != INVALID_HANDLE && !IsFakeClient(client))
	{
		PrintToServer("Player connected. Pausing map changes.");
		g_PlayerCount++;
		KillTimer(g_MapChangeTimer);
	}
}
// Create a timer when the server is empty
public void CreateMapchangeTimer()
{
	if(g_PlayerCount == 0)
	{
		PrintToServer("[SM] Server is empty. Maps will change every %d minutes.", sm_mc_timelimit.IntValue);
		g_TimeToChange = sm_mc_timelimit.IntValue * 60.0;
		g_MapChangeTimer = CreateTimer(g_TimeToChange, ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
// Call changelevel when the timer reaches 0
public Action ChangeMap(Handle timer, any data)
{
	char nextmap[PLATFORM_MAX_PATH];
	sm_nextmap.GetString(nextmap, sizeof(nextmap));
	ServerCommand("changelevel %s", nextmap);
}