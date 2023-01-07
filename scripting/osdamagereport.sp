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

char damageInfo[255];

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
    hitboxName[0] = "Body";
    hitboxName[1] = "Head";
    hitboxName[2] = "Chest";
    hitboxName[3] = "Stomach";
    hitboxName[4] = "L-arm";
    hitboxName[5] = "R-arm";
    hitboxName[6] = "L-leg";
    hitboxName[7] = "R-Leg";
    hitboxName[8] = "Neck";    
}

public void OnMapStart ( ) {
    clearAllDamageData ( );
}

/* EVENTS */
public void Event_RoundStart ( Event event, const char[] name, bool dontBroadcast ) {
    clearAllDamageData ( );
}

public void Event_RoundEnd ( Event event, const char[] name, bool dontBroadcast ) {
    CreateTimer ( 2.1, printAliveReports );
}

public void Event_PlayerDeath ( Event event, const char[] name, bool dontBroadcast ) {
    int victim_id = GetEventInt(event, "userid");
    int attacker_id = GetEventInt(event, "attacker");
    int victim = GetClientOfUserId(victim_id);
    int attacker = GetClientOfUserId(attacker_id);
    killedPlayer[attacker][victim] = 1;

    /* show report */
    if ( ! isWarmup ( ) ) {
        CreateTimer ( 2.1, printSingleReport, victim );
    }
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

}
public void Event_PlayerSpawn ( Event event, const char[] name, bool dontBroadcast ) {
    int userid = GetEventInt ( event,"userid" );
    int player = GetClientOfUserId ( userid );
    GetClientName ( player, playerName[player], 64 );
}
 
/* END EVENTS */

public Action printSingleReport ( Handle timer, int victim ) {
    PrintToConsole ( victim, "PrintSingleReport: %s", playerName[victim] );
    printReport ( victim );
    CreateTimer ( 3.0, clearDamageDataForPlayer, victim );
    return Plugin_Continue;
}

public Action printAliveReports ( Handle timer ) {
    for ( int player = 1; player <= MaxClients; player++ ) {
        if ( playerIsReal ( player ) ) {
            if ( IsPlayerAlive ( player ) ) {
                printReport ( player );
                CreateTimer ( 3.0, clearDamageDataForPlayer, player );
            }
        }
    }
    return Plugin_Handled;
}

public void printReport ( int player ) {
    if ( victimsExists ( player ) ) {
        PrintToChat ( player, " \x04===[ victims - Total: [%d:%d] (hits:damage) ]===", totalHitsGiven(player), totalDamageGiven(player) );
        /* LOOP ALL VICTIMS */
        for ( int victim = 1; victim <= MaxClients; victim++ ) {
            if ( isVictim ( player, victim ) ) {
                fetchVictimDamageInfo ( player, victim );
                PrintToChat ( player, " \x05%s", damageInfo );      
            }
        }        
    }
    if ( attackersExists ( player ) ) {
        PrintToChat ( player, " \x04===[ Attackers - Total: [%d:%d] (hits:damage) ]===", totalHitsTaken(player), totalDamageTaken(player) );
        /* LOOP ALL ATTACKERS */
        for ( int attacker = 1; attacker <= MaxClients; attacker++ ) {
            if ( isVictim ( attacker, player ) ) {
                fetchAttackerDamageInfo ( attacker, player );
                PrintToChat ( player, " \x05%s", damageInfo );
            }
        }
    }
}

/* compile damage report for a single enemy */
public void fetchVictimDamageInfo ( int attacker, int victim ) {
    char victimName[64];
    GetClientName ( victim, victimName, sizeof(victimName) );
    Format ( damageInfo, sizeof(damageInfo), " - %s", victimName );
    if ( attackerKilledVictim ( attacker, victim ) ) {
        Format ( damageInfo, sizeof(damageInfo), "%s (Killed)", damageInfo );
    }
    Format ( damageInfo, sizeof(damageInfo), "%s: %d hits, %d dmg \x08- ", damageInfo, hitsGiven[attacker][victim], damageGiven[attacker][victim] );
    bool first = true;
    for ( int hitboxgroup = 0; hitboxgroup <= MAXHITGROUPS; hitboxgroup++ ) {
        if ( hitboxGiven[attacker][victim][hitboxgroup] > 0 ) {
            if ( first ) {
                Format ( damageInfo, sizeof(damageInfo), "%s%s %d:%d", damageInfo, hitboxName[hitboxgroup], hitboxGiven[attacker][victim][hitboxgroup], hitboxGivenDamage[attacker][victim][hitboxgroup] );
                first = false;
            } else {
                Format ( damageInfo, sizeof(damageInfo), "%s, %s %d:%d", damageInfo, hitboxName[hitboxgroup], hitboxGiven[attacker][victim][hitboxgroup], hitboxGivenDamage[attacker][victim][hitboxgroup] );
            }
        }
    }
}
/* compile damage report for a single enemy */
public void fetchAttackerDamageInfo ( int attacker, int victim ) {
    char attackerName[64];
    GetClientName ( attacker, attackerName, sizeof(attackerName) );
    Format ( damageInfo, sizeof(damageInfo), " - %s", attackerName );
    if ( attackerKilledVictim ( attacker, victim ) ) {
        Format ( damageInfo, sizeof(damageInfo), "%s (killed by)", damageInfo );
    }
    Format ( damageInfo, sizeof(damageInfo), "%s: %d hits, %d dmg \x08- ", damageInfo, hitsTaken[victim][attacker], damageTaken[victim][attacker] );
    bool first = true;
    for ( int hitboxgroup = 0; hitboxgroup <= MAXHITGROUPS; hitboxgroup++ ) {
        if ( hitboxGiven[attacker][victim][hitboxgroup] > 0 ) {
            if ( first ) {
                Format ( damageInfo, sizeof(damageInfo), "%s%s %d:%d", damageInfo, hitboxName[hitboxgroup], hitboxTaken[victim][attacker][hitboxgroup], hitboxTakenDamage[victim][attacker][hitboxgroup] );
                first = false;
            } else {
                Format ( damageInfo, sizeof(damageInfo), "%s, %s %d:%d", damageInfo, hitboxName[hitboxgroup], hitboxTaken[victim][attacker][hitboxgroup], hitboxTakenDamage[victim][attacker][hitboxgroup] );
            }
        }
    }
}
 
public bool isVictim ( int player, int victim ) {
    if ( damageGiven[player][victim] > 0 ) {
        return true;
    }
    return false;
}

public int totalDamageGiven ( int player ) {
    int damage = 0;
    for ( int victim = 1; victim <= MaxClients; victim++ ) {
        damage += damageGiven[player][victim];
    }
    return damage;
}

public int totalDamageTaken ( int player ) {
    int damage = 0;
    for ( int enemy = 1; enemy <= MaxClients; enemy++ ) {
        damage += damageTaken[player][enemy];
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

public int totalHitsTaken ( int player ) {
    int damage = 0;
    for ( int enemy = 1; enemy <= MaxClients; enemy++ ) {
        damage += hitsTaken[player][enemy];
    }
    return damage;
}

public bool attackerKilledVictim ( int attacker, int victim ) {
    return ( killedPlayer[attacker][victim] == 1 );
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

public void clearAllDamageData ( ) {
    PrintToConsoleAll ( "Clearing all damage data:" );
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
                hitboxGivenDamage[i][j][k] = 0;
                hitboxTakenDamage[i][j][k] = 0;
            }
        }
    }
}

public Action clearDamageDataForPlayer ( Handle timer, int player ) {
    for ( int enemy = 1; enemy <= MaxClients; enemy++ ) {
        damageGiven[player][enemy] = 0;
        damageTaken[player][enemy] = 0;
        hitsGiven[player][enemy] = 0;
        hitsTaken[player][enemy] = 0;
        killedPlayer[player][enemy] = 0;
        for ( int k = 0; k <= MAXHITGROUPS; k++ ) {
            hitboxGiven[player][enemy][k] = 0;
            hitboxTaken[player][enemy][k] = 0;
            hitboxGivenDamage[player][enemy][k] = 0;
            hitboxTakenDamage[player][enemy][k] = 0;
        }
    }
    return Plugin_Continue;
}

/* return true if player is real */
public bool playerIsReal ( int player ) {
    return ( IsClientInGame ( player ) &&
             ! IsClientSourceTV ( player ) );
}

/* is warmup */
public bool isWarmup ( ) {
    if ( GameRules_GetProp ( "m_bWarmupPeriod" ) == 1 ) {
        return true;
    } 
    return false;
}