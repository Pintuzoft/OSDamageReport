#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define MAXHITGROUPS 8

int damageGiven[MAXPLAYERS+1][MAXPLAYERS+1];
int hitsGiven[MAXPLAYERS+1][MAXPLAYERS+1];
int hitboxGiven[MAXPLAYERS][MAXPLAYERS+1][MAXHITGROUPS+1];

int damageTaken[MAXPLAYERS+1][MAXPLAYERS+1];
int hitsTaken[MAXPLAYERS+1][MAXPLAYERS+1];
int hitboxTaken[MAXPLAYERS][MAXPLAYERS+1][MAXHITGROUPS+1];
 
int killedPlayer[MAXPLAYERS+1][MAXPLAYERS+1];
int showReportAgain[MAXPLAYERS+1];

char playerName[MAXPLAYERS+1][64];

char hitboxName[MAXHITGROUPS+1][12];


public Plugin myinfo = {
	name = "OSDamageReport",
	author = "Pintuz",
	description = "OldSwedes Damage-Report plugin",
	version = "0.01",
	url = "https://github.com/Pintuzoft/OSDamageReport"
}

public void OnPluginStart ( ) {
    HookEvent ( "round_start", Event_RoundStart );
    HookEvent ( "round_end", Event_RoundEnd );
    HookEvent ( "player_death", Event_PlayerDeath );
    HookEvent ( "player_hurt", Event_PlayerHurt );
    HookEvent ( "player_spawn", Event_PlayerSpawn );
    HookEvent ( "player_disconnect", Event_PlayerDisconnect );
    HookEvent ( "player_connect", Event_PlayerConnect );
    hitboxName[0] = "Body";
    hitboxName[1] = "Head";
    hitboxName[2] = "Chest";
    hitboxName[3] = "Stomach";
    hitboxName[4] = "Left arm";
    hitboxName[5] = "Right arm";
    hitboxName[6] = "Left leg";
    hitboxName[7] = "Right Leg";
    hitboxName[8] = "Neck";    
}

/* EVENTS */
public void Event_RoundStart ( Event event, const char[] name, bool dontBroadcast ) {
    clearAllDamageData ( );
    updatePlayerNames ( );
}

public void Event_RoundEnd ( Event event, const char[] name, bool dontBroadcast ) {
    printReports ( );
    printUpdatedReports ( );
}

public void Event_PlayerDeath ( Event event, const char[] name, bool dontBroadcast ) {
    int victim_id = GetEventInt(event, "userid");
    int attacker_id = GetEventInt(event, "attacker");
    int victim = GetClientOfUserId(victim_id);
    int attacker = GetClientOfUserId(attacker_id);
    killedPlayer[attacker][victim] = 1;

    /* show report */

}
public void Event_PlayerHurt ( Event event, const char[] name, bool dontBroadcast ) {
    int healthDmg = GetEventInt(event,"dmg_health");
    int hitgroup = GetEventInt(event, "hitgroup");
    int victim_id = GetEventInt(event, "userid");
    int attacker_id = GetEventInt(event, "attacker");
    int victim = GetClientOfUserId(victim_id);
    int attacker = GetClientOfUserId(attacker_id);

    damageGiven[attacker][victim] += healthDmg;
    hitsGiven[attacker][victim]++;
    hitboxGiven[attacker][victim][hitgroup]++;

    damageTaken[victim][attacker] += healthDmg;
    hitsTaken[victim][attacker]++;
    hitboxTaken[victim][attacker][hitgroup]++;

    /* if attacker is dead show updated report at the end of the round ? */

}
public void Event_PlayerSpawn ( Event event, const char[] name, bool dontBroadcast ) {
    int userid = GetEventInt ( event,"userid" );
    int player = GetClientOfUserId ( userid );
    GetClientName ( player, playerName[player], 64 );
}
public void Event_PlayerDisconnect ( Event event, const char[] name, bool dontBroadcast ) {
    /* do we need this? */
}
public void Event_PlayerConnect ( Event event, const char[] name, bool dontBroadcast ) {
     
}

/* END EVENTS */

public void updatePlayerNames ( ) {
    for ( int player = 1; player <= MaxClients; player++ ) {
        if ( playerIsReal ( player ) ) {
            GetClientName ( player, playerName[player], 64 );
        } else {
            playerName[player] = "";
        }
    }
}

public void printReports ( ) {
    for ( int player = 1; player <= MaxClients; player++ ) {
        if ( playerIsReal ( player ) && IsPlayerAlive ( player ) ) {
            printReport ( player );
        }
    }
}
public void printReport ( int player ) {
    PrintToChat ( player, " \x03===[ Damage Report ]===========" );


    
    PrintToChat ( player, " \x03===[ End of damage report]")
}
public void printUpdatedReports ( ) {

}

public void clearAllDamageData ( ) {
    for ( int i = 1; i <= MaxClients; i++ ) {
        showReportAgain[i] = 0;
        for ( int j = 1; j <= MaxClients; j++ ) {
            damageGiven[i][j] = 0;
            damageTaken[i][j] = 0;
            hitsGiven[i][j] = 0;
            hitsTaken[i][j] = 0;
            killedPlayer[i][j] = 0;
            for ( int k = 0; k <= MAXHITGROUPS; k++ ) {
                hitboxGiven[i][j][k] = 0;
                hitboxTaken[i][j][k] = 0;
            }
        }
    }
}

/* return true if player is real */
public bool playerIsReal ( int player ) {
    return ( IsClientInGame ( player ) &&
             !IsClientSourceTV ( player ) );
}