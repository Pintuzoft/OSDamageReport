#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define MAXHITGROUPS 8

int damageGiven[MAXPLAYERS+1][MAXPLAYERS+1];
int hitsGiven[MAXPLAYERS+1][MAXPLAYERS+1];
int hitboxGiven[MAXPLAYERS][MAXPLAYERS+1][MAXHITGROUPS+1];
int hitboxGivenDamage[MAXPLAYERS][MAXPLAYERS+1][MAXHITGROUPS+1];

int damageTaken[MAXPLAYERS+1][MAXPLAYERS+1];
int hitsTaken[MAXPLAYERS+1][MAXPLAYERS+1];
int hitboxTaken[MAXPLAYERS][MAXPLAYERS+1][MAXHITGROUPS+1];
int hitboxTakenDamage[MAXPLAYERS][MAXPLAYERS+1][MAXHITGROUPS+1];
 
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
    hitboxGivenDamage[attacker][victim][hitgroup] += healthDmg;

    damageTaken[victim][attacker] += healthDmg;
    hitsTaken[victim][attacker]++;
    hitboxTaken[victim][attacker][hitgroup]++;
    hitboxTakenDamage[victim][attacker][hitgroup] += healthDmg;

    /* if attacker is dead show updated report at the end of the round ? */

}
public void Event_PlayerSpawn ( Event event, const char[] name, bool dontBroadcast ) {
    int userid = GetEventInt ( event,"userid" );
    int player = GetClientOfUserId ( userid );
    GetClientName ( player, playerName[player], 64 );
}
public void Event_PlayerDisconnect ( Event event, const char[] name, bool dontBroadcast ) {
    resetClient ( event );
}
public void Event_PlayerConnect ( Event event, const char[] name, bool dontBroadcast ) {
    resetClient ( event );     
}

/* END EVENTS */

public void resetClient ( Event event ) {

}

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
// new line: ^n
public void printReport ( int player ) {
    char buf[255];
    if ( victimsExists ( player ) ) {
        PrintToChat ( player, " \x04===[ victims - Total: %s dmg, %s hits ]===", totalDamageGiven(player), totalHitsGiven(player) );
        for ( int victim = 1; victim <= MaxClients; victim++ ) {
            if ( playerKilledVictim ( player, victim ) ) {
                Format ( buf, sizeof(buf), "%s", getDamageInfo ( player, victim ) );
                PrintToChat ( player, " \x05%s (killed): ", playerName[victim])
            } else {

            }
        }        
    }
    if ( attackersExists ( player ) ) {

        PrintToChat ( player, " \x04===[ Attackers ]===========" );

    }
}

public char getDamageInfo ( int player, int victim ) {
    char buf[255];
    for ( int hitboxgroup = 0; hitboxgroup <= MAXHITGROUPS; hitboxgroup++ ) {
        if ( hitboxGiven[hitboxgroup][player][victim] > 0 ) {
            Format ( buf, sizeof(buf), "%s   ")
        }
    }
}

public int totalDamageGiven ( int player ) {
    int damage = 0;
    for ( int victim = 1; victim <= MaxClients; victim++ ) {
        damage += damageGiven[player][victim];
    }
    return damage;
}
public int totalHitsGiven ( int player ) {
    int damage = 0;
    for ( int victim = 1; victim <= MaxClients; victim++ ) {
        damage += hitsGiven[player][victim];
    }
    return damage;
}

public bool playerKilledVictim ( int player, int victim ) {
    return ( killedPlayer[player][victim] == 1 );
}


public bool victimsExists ( int player ) {
    for ( int victim = 1; victim <= MaxClients; victim++ ) {
        if ( damageGiven[player][victim] > 0 ) {
            return true;
        }
    }
    return false;
}

public bool attackersExists ( int player ) {
    for ( int attacker = 1; attacker <= MaxClients; attacker++ ) {
        if ( damageTaken[player][attacker] > 0 ) {
            return true;
        }
    }
    return false;
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

