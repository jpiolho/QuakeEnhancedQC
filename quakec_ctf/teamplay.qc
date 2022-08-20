/*  Copyright (C) 1996-2022 id Software LLC

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

/** Defs **/

/** MODIFIABLE CONSTANTS **/

float TEAM_DEFAULT_PENALTY =    1;      // Default frag penalty
float TEAM_STRICT_COOP =  0;  // Strict Coop

// Allowed team colors
// -1 indicates no color

float TEAM_COLOR1       =       5;
float TEAM_COLOR2       =       14;

float team1shirt;
float team2shirt;

/** End of MODIFIABLE CONSTANTS **/

// Globals

entity team1_lastspawn;
entity team2_lastspawn;
float nextteamupdtime;  // time until next team update
float last_flag_capture;  // time of last capture
float last_capture_team;  // last team that captured

// Teamplay bitfield entries

float TEAM_HEALTH_PROTECT =     1;      // No health damage from friendly fire
float TEAM_ARMOR_PROTECT =      2;      // No armor damage from friendly fire
float TEAM_ATTACKER_DAMAGE =    4;      // Attacker takes damage from hitting teammates
float TEAM_FRAG_PENALTY =       8;      // One frag penalty for killing teammate
float TEAM_DEATH_PENALTY =      16;     // Die when you kill a teammate.
float TEAM_STATIC_TEAMS =       64;     // Don't allow players to switch teams
float TEAM_DROP_ITEMS =     128;  // Allow players to drop packs and 
float TEAM_CAPTURE_SELECT_TEAM = 1024; // team selection
float TEAM_DISABLE_GRAPPLE = 2048; // team selection

float TEAM_CAPTURE_CAPTURE_BONUS = 15; // what you get for capture
float TEAM_CAPTURE_TEAM_BONUS = 10; // what your team gets for capture
float TEAM_CAPTURE_RECOVERY_BONUS = 1; // what you get for recovery
float TEAM_CAPTURE_FLAG_BONUS = 0; // what you get for picking up enemy flag
float TEAM_CAPTURE_FRAG_CARRIER_BONUS = 2; // what you get for fragging
  //enemy flag carrier
float TEAM_CAPTURE_FLAG_RETURN_TIME = 15; // seconds until auto return

// XXX EXPERT CTF Additional scoring system

// bonuses

float TEAM_CAPTURE_CARRIER_DANGER_PROTECT_BONUS = 2; // bonus for fraggin someone
// who has recently hurt your flag carrier
float TEAM_CAPTURE_CARRIER_PROTECT_BONUS = 1; // bonus for fraggin someone while
// either you or your target are near your flag carrier
float TEAM_CAPTURE_FLAG_DEFENSE_BONUS = 1; // bonus for fraggin someone while
// either you or your target are near your flag
float TEAM_CAPTURE_RETURN_FLAG_ASSIST_BONUS = 1; // awarded for returning a flag that causes a
// capture to happen almost immediately
float TEAM_CAPTURE_FRAG_CARRIER_ASSIST_BONUS = 2; // award for fragging a flag carrier if a
// capture happens almost immediately

// radii

float TEAM_CAPTURE_TARGET_PROTECT_RADIUS = 550; // the radius around an object being
// defended where a target will be worth extra frags
float TEAM_CAPTURE_ATTACKER_PROTECT_RADIUS = 550; // the radius around an object being
// defended where an attacker will get extra frags when making kills

// timeouts

float TEAM_CAPTURE_CARRIER_DANGER_PROTECT_TIMEOUT = 4;
float TEAM_CAPTURE_CARRIER_FLAG_SINCE_TIMEOUT = 2;
float TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT = 6;
float TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT = 4;

float TEAM_CAPTURE_UPDATE_TIME = 120;

// END EXPERT CTF

// flag status used in cnt field of flag
float FLAG_AT_BASE = 0;
float FLAG_CARRIED = 1;
float FLAG_DROPPED = 2;


// Prototypes
float() W_BestWeapon;
void() W_SetCurrentAmmo;
void() bound_other_ammo;
void(float o, float n) Deathmatch_Weapon;
void() BackpackTouch;

// Return a name for the color of a team
string(float Team) GetTeamColor =
{
  if(Team == 0) return("Blue");
  else if(Team == 1) return("Steel blue");
  else if(Team == 2) return("Brown");
  else if(Team == 3) return("Baby blue");
  else if(Team == 4) return("Green");
  else if(Team == 5) return("Red");
  else if(Team == 6) return("Olive");
  else if(Team == 7) return("Orange");
  else if(Team == 8) return("Peech");
  else if(Team == 9) return("Purple");
  else if(Team == 10) return("Majenta");
  else if(Team == 11) return("Grey");
  else if(Team == 12) return("Aqua");
  else if(Team == 13) return("Yellow");
  else if(Team == 14) return("Blue");
  return "Unknown";
};

// *XXX* EXPERT CTF
// Just a quickie to return the ASCII-ized team names for CTF
string(float Team) GetCTFTeam =
{

  if (Team == TEAM_COLOR1) return "$qc_ctf_redteam";
  if (Team == TEAM_COLOR2) return "$qc_ctf_blueteam";
  return "";

};

void(entity e, float top, float bottom) TeamSetColor =
{
  if (cvar("pr_checkextension"))
  {
    if (checkextension("DP_SV_SETCOLOR"))
    {
      local float color = bottom + top * 16
      setcolor(e, color);
      return;
    }
  }

  local string n;
  
  stuffcmd(self, "color ");
  n = ftos(top);
  stuffcmd(self, n);
  stuffcmd(self, " ");
  n = ftos(bottom);
  stuffcmd(self, n);
  stuffcmd(self, "\n");
}


/*
================
TeamPrintSettings

Print out current teamplay options
================
*/

void() TeamPrintSettings =
{
  local string s;
  
  sprint(self,"The following Teamplay options are set:\n");
  
  if(teamplay < 0)
  {
    sprint(self, "Frag penalty manually set to ");
    s = ftos(teamplay);
    sprint(self, s);
    sprint(self, "\n");
    return;
  }
  
  if(!teamplay) 
  {
    sprint(self, "None\n");
    return;
  }
  
  if(1 == teamplay)
  {
    sprint(self, "ID's original teamplay 1\n");
    return;
  }
  
  if(teamplay & TEAM_HEALTH_PROTECT)
    sprint(self, "Health-Protect ");
  
  if(teamplay & TEAM_ARMOR_PROTECT)
    sprint(self, "Armor-Protect ");
    
  if(teamplay & TEAM_ATTACKER_DAMAGE)
    sprint(self, "Mirror-Damage ");
    
  if(teamplay & TEAM_FRAG_PENALTY)
    sprint(self, "Frag-Penalty ");
    
  if(teamplay & TEAM_DEATH_PENALTY)
    sprint(self, "Death-Penalty ");
    
  if(teamplay & TEAM_STATIC_TEAMS)
    sprint(self, "Static-Teams ");
    
  if(teamplay & TEAM_DROP_ITEMS)
    sprint(self, "Drop-Items (Backpack Impulse 20, Weapon Impulse 21) ");
    
  sprint(self, "\n");
};

/*
================
TeamArmorDam

Return TRUE if the target's armor can take damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamArmorDam =
{
        if ((teamplay < 0) || gamestart)
                return TRUE;

        if( (teamplay & TEAM_ARMOR_PROTECT) && 
      (attacker.lastteam == targ.lastteam) && 
      (attacker != targ) && (targ.lastteam > 0) )
        {
                // Armor is protected
                return FALSE;
        }
        return TRUE;
};

/*
================
TeamHealthDam

Return TRUE if the target can take health damage from this attacker.
================
*/

float(entity targ, entity inflictor, entity attacker, float damage) TeamHealthDam =
{
        if ((teamplay < 0) || gamestart)
                return TRUE;

        if( (attacker.lastteam == targ.lastteam) && 
      (attacker != targ) && (targ.lastteam > 0) ) {
                // Attacker and target are on the same team.
                if( teamplay & TEAM_ATTACKER_DAMAGE )
                {
                        // Damage applied to teammate.
                        T_Damage(attacker, inflictor, attacker, damage);
                }
                if( teamplay & TEAM_HEALTH_PROTECT )
                {
                        // Health is protected
                        return FALSE;
                }
        }
        return TRUE;
};

/*
================
TeamPFrags

Return the number of frags we should penalize attacker for killing targ.
================
*/

float(entity targ, entity attacker) TeamPFrags =
{
        if( teamplay < 0 )
                return (-1 * teamplay);
        if( (targ.lastteam > 0) && (targ != attacker) && (targ.lastteam ==
      attacker.lastteam) )
        {
                // targ and attacker are on the same team
                if( teamplay < 0 )
                {
                        // teamplay indicates frag penalty
                        return ( -1 * teamplay );
                }
                if( teamplay & TEAM_FRAG_PENALTY )
                {
                        // default penalty
                        return TEAM_DEFAULT_PENALTY;
                }
        }
        // No frag penalty
        return 0;
};

/*
================
TeamFragPenalty

If attacker should be penalized for killing targ, penalize attacker
and return TRUE.
================
*/

float(entity targ, entity attacker) TeamFragPenalty =
{
        local float f;

        f = TeamPFrags(targ, attacker);

        if( f )
        {
                // We should penalize some frags.
                attacker.frags = attacker.frags - f;
                return TRUE;
        }
        // No penalty
        return FALSE;
};

/*
=================
TeamDeathPenalty

If attacker should be killed for killing targ, kill attacker and
add a frag to offset the one attacker will lose for killing himself.
*/

void(entity targ, entity attacker) TeamDeathPenalty =
{
        //Don't kill anyone if teamplay is negative.
        if ( teamplay < 0 )
                return;

        if ( (teamplay & TEAM_DEATH_PENALTY) && (targ.lastteam > 0) &&
      (attacker != targ) && (attacker.lastteam == targ.lastteam) )
        {
                //We should kill the attacker.
                T_Damage(attacker,attacker,attacker,1000);
                //Add a frag to offset the self-kill penalty.
                attacker.frags = attacker.frags + 1;
        }
};

/*
==================
TeamColorIsLegal

Return TRUE if the indicated color is legal
==================
*/
float(float color) TeamColorIsLegal =
{
        // All colors are legal if teamplay is negative.
        if( teamplay < 0 )
                return TRUE;
        if( (color == TEAM_COLOR1) && (TEAM_COLOR1 >= 0) )
                return TRUE;
        if( (color == TEAM_COLOR2) && (TEAM_COLOR2 >= 0) )
                return TRUE;
};

float(float t) TeamGetShirt =
{
  if (t == TEAM_COLOR1) {
    team1shirt = team1shirt + 1;
    if (team1shirt > 14)
      team1shirt = 0;
    if (team1shirt == TEAM_COLOR2 - 1)
      team1shirt = team2shirt + 1;
    return team1shirt;
  } else { // color2
    team2shirt = team2shirt + 1;
    if (team2shirt > 14)
      team2shirt = 0;
    if (team2shirt == TEAM_COLOR1 - 1)
      team2shirt = team1shirt + 1;
    return team2shirt;
  }
  return t - 1;
};

/*
==================
TeamCheckTeam

Check if the team self is on is legal, and put self in a legal team if not.
==================
*/
void() TeamCheckTeam =
{
  local float TEAM1;
  local float TEAM2;

  local float newcolor;

  local entity p;

  local string n;

  if ( self.lastteam >= 0 ) {
      if( TeamColorIsLegal(self.team ) ) {
          self.lastteam = self.team;
          return;
      }
  }

  // Assign the player to a team.

  // Sum the players on all the teams.

  TEAM1 = 0;
  TEAM2 = 0;

  p = find (world, classname, "player");

  while(p)
  {
    if (p != self) {
      if (p.team == TEAM_COLOR1)
        TEAM1 = TEAM1 + 1;
      else if (p.team == TEAM_COLOR2)
        TEAM2 = TEAM2 + 1;
    }
    p = find(p, classname, "player");
  }

  // Find the team with the least players.
  newcolor = TEAM_COLOR1;
  if (((TEAM2 < TEAM1) || (TEAM2 == TEAM1 && random() < 0.5)))
    newcolor = TEAM_COLOR2;

  // Put the player on a the new team.
  TeamSetColor(self, newcolor - 1, newcolor - 1);

  self.lastteam = newcolor;      // Remember what team we're on
  self.team = newcolor;
};

/*
===============
TeamCheckLock

Check for team changing and perform whatever actions are neccessary.
===============
*/
void() TeamCheckLock =
{
  local   float   n;
  local   string  s;

  // Don't do anything if teamplay is negative
  if ( teamplay < 0 )
      return;
  
  if (self.observer || self.do_observer || gamestart) {
    if (self.lastteam != 1)
      TeamSetColor(self, 0, 0);
    self.lastteam = 1;
    return;
  }

  if (self.player_flag & TEAM_STUFF_COLOR) {
    self.player_flag = self.player_flag - TEAM_STUFF_COLOR;
    TeamSetColor(self, self.lastteam - 1, self.lastteam - 1);
    return;
  }

  if ( !TeamColorIsLegal(self.team) && (self.team == self.lastteam)) {
    self.lastteam = -1;
  }

  // Check to see if the player has changed colors
  if (self.team != self.lastteam)
  {
    // Player has changed colors

    // If teams are static and we've been on some team already,
    // put us back on the team we were on.

    if ( (teamplay & TEAM_STATIC_TEAMS) && (self.lastteam >= 0) )
    {
      if ( TeamColorIsLegal(self.lastteam) )
      {
        // changing teams sucks, kill him

        // if he has tried to change teams several
        // times, kick him off the server.
        if (self.suicide_count > 3) {
          stuffcmd(self, "disconnect\n");
        }
        // case base respawn
        if (self.killed != 1)
          self.killed = 2;
        self.invincible_finished = 0;
        T_Damage(self,self,self,1000);  // Kill the player
        // trying to change teams counts as a suicide
        self.suicide_count = self.suicide_count + 1;

        stuffcmd(self, "color ");
        n = TeamGetShirt(self.lastteam);
        TeamSetColor(self, self.lastteam - 1, self.lastteam - 1);
        return;
      }
      else {
        // If we're on an illegal team, force a change.
        self.lastteam = -50;
      }
    }

    if(self.lastteam > 0) {
      // case base respawn
      if (self.killed != 1)
        self.killed = 2;
      T_Damage(self,self,self,1000);  // Kill the player
    }
    self.frags = 0;                 // Zero out frags
    TeamCheckTeam();
  }
};

/*
=======================
TossBackPack

Original idea by Vhold
Rewritten by John Spickes

Toss out a backpack containing some ammo from your current weapon,
and any weapons you don't have.
=======================
*/
void() TossBackpack =
{
  local entity  item;

  // If we don't have any ammo, return
  if(self.currentammo <= 0)
    return;

  item = spawn();

  // See if you have the Shotgun or Super Shotgun on
        if ( (self.weapon == IT_SHOTGUN) || (self.weapon == IT_SUPER_SHOTGUN)) {
    if( self.ammo_shells >= 20 ) {
      item.ammo_shells = 20;
      self.ammo_shells = self.ammo_shells - 20;
    }
    else
    {
      item.ammo_shells = self.ammo_shells;
      self.ammo_shells = 0;
    }
  }   
  
  // See if you have neither the Shotgun or Super Shotgun
        if ( !(self.items & IT_SHOTGUN) && !(self.items & IT_SUPER_SHOTGUN)) {
    if( self.ammo_shells >= 20 ) {
      item.ammo_shells = 20;
      self.ammo_shells = self.ammo_shells - 20;
    }
    else
    {
      item.ammo_shells = self.ammo_shells;
      self.ammo_shells = 0;
    }
  }   
  
  // See if we are using a nailgun
        if ( (self.weapon == IT_NAILGUN) || (self.weapon == IT_SUPER_NAILGUN) )
  {
    if( self.ammo_nails >= 20 )
    {
      item.ammo_nails = 20;
      self.ammo_nails = self.ammo_nails - 20;
    }
    else
    {
      item.ammo_nails = self.ammo_nails;
      self.ammo_nails = 0;
    }
  } 
  // Check to see if we have neither nailgun
        if ( !(self.items & IT_NAILGUN) && !(self.items & IT_SUPER_NAILGUN) )
  {
    if( self.ammo_nails >= 20 )
    {
      item.ammo_nails = 20;
      self.ammo_nails = self.ammo_nails - 20;
    }
    else
    {
      item.ammo_nails = self.ammo_nails;
      self.ammo_nails = 0;
    }
  } 
  
  // See if we are using a grenade or rocket launcher
        if ( (self.weapon == IT_GRENADE_LAUNCHER) || (self.weapon == IT_ROCKET_LAUNCHER) )
  {
    if( self.ammo_rockets >= 10 )
    {
      item.ammo_rockets = 10;
      self.ammo_rockets = self.ammo_rockets - 10;
    }
    else
    {
      item.ammo_rockets = self.ammo_rockets;
      self.ammo_rockets = 0;
    }
  }
  // See if we have neither the Grenade or rocket launcher
        if ( !(self.items & IT_GRENADE_LAUNCHER) && !(self.items & IT_ROCKET_LAUNCHER) )
  {
    if( self.ammo_rockets >= 10 )
    {
      item.ammo_rockets = 10;
      self.ammo_rockets = self.ammo_rockets - 10;
    }
    else
    {
      item.ammo_rockets = self.ammo_rockets;
      self.ammo_rockets = 0;
    }
  }

  // See if we're using the lightning gun
  if ( self.weapon == IT_LIGHTNING )
  { 
    if( self.ammo_cells >= 20 )
    {
      item.ammo_cells = 20;
      self.ammo_cells = self.ammo_cells - 20;
    }
    else
    {
      item.ammo_cells = self.ammo_cells;
      self.ammo_cells = 0;
    }
  }
  // see if we don't have the lightning gun
        if ( !(self.items & IT_LIGHTNING) )
  { 
    if( self.ammo_cells >= 20 )
    {
      item.ammo_cells = 20;
      self.ammo_cells = self.ammo_cells - 20;
    }
    else
    {
      item.ammo_cells = self.ammo_cells;
      self.ammo_cells = 0;
    }
  }
   
  item.owner = self;
  makevectors(self.v_angle);

  setorigin(item, self.origin + '0 0 16');
  item.velocity = aim(self, 1000);
  item.velocity = item.velocity * 500;
  item.flags = FL_ITEM;
  item.solid = SOLID_TRIGGER;
  item.movetype = MOVETYPE_BOUNCE;

  setmodel (item, "progs/backpack.mdl");
  setsize(item, '-16 -16 0', '16 16 56');
  item.touch = BackpackTouch;
  item.nextthink = time + 120;  // remove after 2 minutes
  item.think = SUB_Remove;

  W_SetCurrentAmmo();

};

void() Team_weapon_touch =
{
  local float hadammo, best, new, old;
  local entity stemp;

  if (!(other.flags & FL_CLIENT))
    return;
  // Don't let the owner pick up his own weapon for a second.
  if ( (other == self.owner) && ( (self.nextthink - time) > 119 ) )
    return;

// if the player was using his best weapon, change up to the new one if better    
  stemp = self;
  self = other;
  best = W_BestWeapon();
  self = stemp;

  if (self.classname == "weapon_nailgun")
  {
    hadammo = other.ammo_nails;     
    new = IT_NAILGUN;
  }
  else if (self.classname == "weapon_supernailgun")
  {
    hadammo = other.ammo_rockets;     
    new = IT_SUPER_NAILGUN;
  }
  else if (self.classname == "weapon_supershotgun")
  {
    hadammo = other.ammo_rockets;     
    new = IT_SUPER_SHOTGUN;
  }
  else if (self.classname == "weapon_rocketlauncher")
  {
    hadammo = other.ammo_rockets;     
    new = IT_ROCKET_LAUNCHER;
  }
  else if (self.classname == "weapon_grenadelauncher")
  {
    hadammo = other.ammo_rockets;     
    new = IT_GRENADE_LAUNCHER;
  }
  else if (self.classname == "weapon_lightning")
  {
    hadammo = other.ammo_rockets;     
    new = IT_LIGHTNING;
  }
  else
    objerror ("Team_weapon_touch: unknown classname");

  sprint(other, "$qc_got_item", self.netname);
// weapon touch sound
  sound (other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
  stuffcmd (other, "bf\n");

  bound_other_ammo ();

// change to the weapon
  old = other.items;
  other.items = other.items | new;
  
  remove(self);
  self = other;

  if (!deathmatch)
    self.weapon = new;
  else
    Deathmatch_Weapon (old, new);

  W_SetCurrentAmmo();

  activator = other;
  SUB_UseTargets();       // fire all targets / killtargets
};
        
void() TossWeapon =
{
  local entity item;
  
  if (deathmatch != 1)
    return;  // only in deathmatch 1

  if((self.weapon == IT_AXE) || (self.weapon == IT_SHOTGUN) ||
    (self.weapon == IT_HOOK))
    return;
    
  item = spawn();
  item.owner = self;
  makevectors(self.v_angle);

  setorigin(item, self.origin + '0 0 16');
  item.velocity = aim(self, 1000);
  item.velocity = item.velocity * 500;
  item.flags = FL_ITEM;
  item.solid = SOLID_TRIGGER;
  item.movetype = MOVETYPE_BOUNCE;
  
  if(self.weapon == IT_SUPER_SHOTGUN)
  {
    setmodel (item, "progs/g_shot.mdl");
    item.weapon = IT_SUPER_SHOTGUN;
    item.netname = "Double-barrelled Shotgun";
    item.classname = "weapon_supershotgun";
    self.items = self.items - IT_SUPER_SHOTGUN;
  }

  if( self.weapon == IT_NAILGUN )
  {
    setmodel (item, "progs/g_nail.mdl");
    item.weapon = IT_NAILGUN;
    item.netname = "nailgun";
    item.classname = "weapon_nailgun";
    self.items = self.items - IT_NAILGUN;
  }
    
  if( self.weapon == IT_SUPER_NAILGUN)
  {
    setmodel (item, "progs/g_nail2.mdl");
    item.weapon = IT_SUPER_NAILGUN;
    item.netname = "Super Nailgun";
    item.classname = "weapon_supernailgun";
    self.items = self.items - IT_SUPER_NAILGUN;
  }
  
  if( self.weapon == IT_GRENADE_LAUNCHER)
  {
    setmodel (item, "progs/g_rock.mdl");
    item.weapon = IT_GRENADE_LAUNCHER;
    item.netname = "Grenade Launcher";
    item.classname = "weapon_grenadelauncher";
    self.items = self.items - IT_GRENADE_LAUNCHER;
  }
  
  if( self.weapon == IT_ROCKET_LAUNCHER )
  {
    setmodel (item, "progs/g_rock2.mdl");
    item.weapon = IT_ROCKET_LAUNCHER;
    item.netname = "Rocket Launcher";
    item.classname = "weapon_rocketlauncher";
    self.items = self.items - IT_ROCKET_LAUNCHER;
  }
  
  if( self.weapon == IT_LIGHTNING )
  {
    setmodel (item, "progs/g_light.mdl");
    item.weapon = IT_LIGHTNING;
    item.netname = "Thunderbolt";
    item.classname = "weapon_lightning";
    self.items = self.items - IT_LIGHTNING;
  }
  setsize(item, '-16 -16 0', '16 16 56');
  item.touch = Team_weapon_touch;
  item.think = SUB_Remove;
  item.nextthink = time + 120;
  
  self.weapon = W_BestWeapon();
  W_SetCurrentAmmo();
};

void(entity flg) RegenFlag =
{
  flg.movetype = MOVETYPE_TOSS;
  flg.solid = SOLID_TRIGGER;
  sound (flg, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM); // play respawn sound
  setorigin(flg, flg.oldorigin);
  flg.angles = flg.mangle;
  flg.cnt = FLAG_AT_BASE; // it's at home base
  flg.owner = world;
};

void(entity flg) TeamCaptureReturnFlag =
{
  local entity p;

  RegenFlag(flg);

  p = find(world, classname, "player");
  while (p != world) {
    if (p.team != flg.team)
      centerprint(p, "$qc_ctf_enemy_returned");
    else if (p.team == flg.team)
      centerprint(p, "$qc_ctf_your_returned");
    p = find(p, classname, "player");
  }
};

void () TeamCaptureRegenFlags =
{
  local entity f;

  f = find(world, classname, "item_flag_team1");
  if (f != world)
    RegenFlag(f);
  f = find(world, classname, "item_flag_team2");
  if (f != world)
    RegenFlag(f);
};

void(entity flg) TeamDropFlag =
{
  local entity item, f, oself;
  local entity p;

  p = flg.owner;

  if (p.lastteam == TEAM_COLOR1)
    bprint("$qc_ks_blue_dropped", p.netname); // blue
  else
    bprint("$qc_ks_red_dropped", p.netname); // red
  LogMsg(p, "FLAG-DROP");

  flg.origin = p.origin - '0 0 24';
  flg.cnt = FLAG_DROPPED;
  //NOTE! We check lastteam here instead of team--this is because
  //in the mode where we change colors, we get killed
  flg.velocity_z = 300;
  flg.velocity_x = 0;
  flg.velocity_y = 0;
  flg.flags = FL_ITEM | FL_OBJECTIVE;
  flg.solid = SOLID_TRIGGER;
  flg.movetype = MOVETYPE_TOSS;
  setsize(flg, '-16 -16 0', '16 16 74');
  // return it after so long
  flg.super_time = time + TEAM_CAPTURE_FLAG_RETURN_TIME;
  SendCTFScoresUpdateAll();
};

void(entity player) TeamCaptureDropFlagOfPlayer =
{
  local string kn;
  local entity e;

  if (!(player.player_flag & ITEM_ENEMY_FLAG))
    return;
  if (player.lastteam == TEAM_COLOR1) 
    kn = "item_flag_team2";
  else
    kn = "item_flag_team1";
  player.player_flag = player.player_flag - ITEM_ENEMY_FLAG;
  e = find(world, classname, kn);
  if (e != world)
    TeamDropFlag(e);
};

void() TeamCaptureFlagTouch =
{
  local entity p, oself;

  if (other.classname != "player")
    return;
  if (other.health <= 0)
    return;

  if (other.team != other.lastteam)
    return; // something is fishy, somebody is playing with colors

  if (self.lastteam == other.lastteam) {
    // same team, if the flag is *not* at the base, return
    // it to base.  we overload the 'cnt' field for this
    if (self.cnt == FLAG_AT_BASE) {
      // the flag is at home base.  if the player has the enemy
      // flag, he's just won!

      if (other.player_flag & ITEM_ENEMY_FLAG) {
        if (other.team == TEAM_COLOR1)
          bprint("$qc_ks_blue_captured", other.netname); // blue
        else
          bprint("$qc_ks_red_captured", other.netname); // red
        LogMsg(other, "FLAG-CAPTURE");
        other.items = other.items - (other.items & (IT_KEY1 | IT_KEY2));

        last_flag_capture = time;
        last_capture_team = other.team;

        sound (other, CHAN_VOICE, "misc/flagcap.wav", 1, ATTN_NONE);
        if (other.team == TEAM_COLOR1) {
          teamscr1 += 1;
        } else {
          teamscr2 += 1;
        }

        // other gets another 10 frag bonus
        other.frags = other.frags + TEAM_CAPTURE_CAPTURE_BONUS;

        // Ok, let's do the player loop, hand out the bonuses
        p = find(world, classname, "player");
        while (p != world) {
          self = p;
          self.killed = 0;
          if (self.lastteam == other.lastteam && self != other)
            self.frags = self.frags + TEAM_CAPTURE_TEAM_BONUS;
          if (self.lastteam != other.lastteam) {
            // *XXX* EXPERT CTF
            // reset the last_hurt_carrier variable in all enemy players, so that you don't get
            // bonuses for defending the flag carrier if the flag carrier has already
            // completed a capture
            self.last_hurt_carrier = -5;
          } else if (self.lastteam == other.lastteam) {
            // done to all players on the capturing team
            // *XXX* EXPERT CTF
  
            // award extra points for capture assists
            if (self.last_returned_flag + TEAM_CAPTURE_RETURN_FLAG_ASSIST_TIMEOUT > time) {
              bprint("$qc_ks_assist", self.netname);
              self.frags = self.frags + TEAM_CAPTURE_RETURN_FLAG_ASSIST_BONUS;
            }
            if (self.last_fragged_carrier + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_TIMEOUT > time) {
              bprint("$qc_ks_assist_carrier", self.netname);
              self.frags = self.frags + TEAM_CAPTURE_FRAG_CARRIER_ASSIST_BONUS;
            }
          }
          self.player_flag = self.player_flag - (self.player_flag & ITEM_ENEMY_FLAG);
          
          p = find(p, classname, "player");
        }

        
        p = find(world, classname, "player");
        while (p != world) {
          if ((p.lastteam == TEAM_COLOR1 && other.lastteam == TEAM_COLOR2) ||
            (p.lastteam == TEAM_COLOR2 && other.lastteam == TEAM_COLOR1))
            centerprint(p, "$qc_ctf_your_captured");
          else if (p.lastteam == other.lastteam)
            centerprint(p, "$qc_ctf_team_captured");
          p = find(p, classname, "player");
        }
        // respawn flags
        TeamCaptureRegenFlags();
        SendCTFScoresUpdateAll();
        return;
      }

      return; // its at home base already
    } 
    // hey, its not home.  return it by teleporting it back
    if (other.team == TEAM_COLOR1)
      bprint("$qc_ks_red_returned", other.netname); // red
    else
      bprint("$qc_ks_blue_returned", other.netname); // blue
    LogMsg(other, "FLAG-RECOVERY");
    other.frags = other.frags + TEAM_CAPTURE_RECOVERY_BONUS;
    // *XXX* EXPERT CTF set time when player last returned his flag
    other.last_returned_flag = time;
    sound (other, CHAN_ITEM, self.noise1, 1, ATTN_NORM);
    TeamCaptureReturnFlag(self);
    SendCTFScoresUpdateAll();
    return;
  }

  // hey, its not our flag, pick it up
  if (other.team == TEAM_COLOR1)
    bprint("$qc_ks_blue_picked_up", other.netname); // blue
  else
    bprint("$qc_ks_blue_picked_up", other.netname); // red
  LogMsg(other, "FLAG-PICKUP");
  if (TEAM_CAPTURE_FLAG_BONUS)
    other.frags = other.frags + TEAM_CAPTURE_FLAG_BONUS;
  centerprint(other, "$qc_ctf_have_flag");
  sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

  other.player_flag = other.player_flag + ITEM_ENEMY_FLAG;
  other.items = other.items | self.items;

  // *XXX* EXPERT CTF set the time at which the carrier picked up the flag
  other.flag_since = time;

  // pick up the flag
  self.cnt = FLAG_CARRIED;
  self.movetype = MOVETYPE_NOCLIP;
  self.solid = SOLID_NOT;
  self.owner = other;

  p = find(world, classname, "player");
  while (p != world) {
    if (p != other) {
      if ((p.team == TEAM_COLOR1 && other.team == TEAM_COLOR2) ||
        (p.team == TEAM_COLOR2 && other.team == TEAM_COLOR1))
        centerprint(p, "$qc_ctf_your_taken");
      else if (p.team == other.team)
        centerprint(p, "$qc_ctf_your_has");
    }
    p = find(p, classname, "player");
  }

  SendCTFScoresUpdateAll();
};

void() TeamCaptureFlagThink =
{
  local entity e;
  local vector v;
  local float f;
  local string s;

  self.nextthink = time + 0.1;

  if (self.cnt == FLAG_AT_BASE)
    return; // just sitting around waiting to be picked up

  if (self.cnt == FLAG_DROPPED) {
    if (time - self.super_time > TEAM_CAPTURE_FLAG_RETURN_TIME)
      TeamCaptureReturnFlag(self);
      SendCTFScoresUpdateAll();
    return;
  }

  if (self.cnt != FLAG_CARRIED)
    objerror("Flag in invalid state\n");

  e = self.owner;
  if ((e.classname != "player") || (e.deadflag) ||
    (!(e.player_flag & ITEM_ENEMY_FLAG))) {
    TeamDropFlag(self);
    return;
  }
  makevectors (e.angles);
  v = v_forward;
//dprint("fwd: ");
//s = vtos(v);
//dprint(s);
//dprint("\n");
//  if (v_z < 0) { 
//    v_z = (-1)*v_z; 
//    v = v + v * 1.2 * v_z; 
//  }
//dprint("adj: ");
//s = vtos(v);
//dprint(s);
//dprint("\n");
  v_z = (-1) * v_z; // reverse z component

  f = 14;
  if (self.owner.frame >= 29 && self.owner.frame <= 40) {
    if (self.owner.frame >= 29 && self.owner.frame <= 34) { //axpain
      if      (self.owner.frame == 29) f = f + 2; 
      else if (self.owner.frame == 30) f = f + 8;
      else if (self.owner.frame == 31) f = f + 12;
      else if (self.owner.frame == 32) f = f + 11;
      else if (self.owner.frame == 33) f = f + 10;
      else if (self.owner.frame == 34) f = f + 4;
    } else if (self.owner.frame >= 35 && self.owner.frame <= 40) { // pain
      if      (self.owner.frame == 35) f = f + 2; 
      else if (self.owner.frame == 36) f = f + 10;
      else if (self.owner.frame == 37) f = f + 10;
      else if (self.owner.frame == 38) f = f + 8;
      else if (self.owner.frame == 39) f = f + 4;
      else if (self.owner.frame == 40) f = f + 2;
    }
  } else if (self.owner.frame >= 103 && self.owner.frame <= 118) {
    if      (self.owner.frame >= 103 && self.owner.frame <= 104) f = f + 6;  //nailattack
    else if (self.owner.frame >= 105 && self.owner.frame <= 106) f = f + 6;  //light 
    else if (self.owner.frame >= 107 && self.owner.frame <= 112) f = f + 7;  //rocketattack
    else if (self.owner.frame >= 112 && self.owner.frame <= 118) f = f + 7;  //shotattack
  }
  self.origin = e.origin + '0 0 -16' - f*v + v_right * 22;
  self.angles = e.angles + '0 0 -45';
  setorigin (self, self.origin);
  self.nextthink = time + 0.01;
};

// self is player
entity() TeamCaptureSpawn =
{
  if (self.team == TEAM_COLOR1) {
    team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
    if (team1_lastspawn == world)
      team1_lastspawn = find(team1_lastspawn, classname, "info_player_team1");
    return team1_lastspawn;
  } else if (self.team == TEAM_COLOR2) {
    team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
    if (team2_lastspawn == world)
      team2_lastspawn = find(team2_lastspawn, classname, "info_player_team2");
    return team2_lastspawn;
  }
  return world;
};

/////////////////////////////////////////////////////////////////////////

$cd id1/models/flag
$base base
$skin skin

void() place_flag = {
  self.mdl = self.model;      // so it can be restored on respawn
  self.flags = FL_ITEM | FL_OBJECTIVE;  // make extra wide
  self.solid = SOLID_TRIGGER;
  self.movetype = MOVETYPE_TOSS;  
  self.velocity = '0 0 0';
  self.origin_z = self.origin_z + 6;
  self.think = TeamCaptureFlagThink;
  self.touch = TeamCaptureFlagTouch;
  self.nextthink = time + 0.1;
  self.cnt = FLAG_AT_BASE;
  self.mangle = self.angles;
  self.effects = self.effects | EF_DIMLIGHT;
  if (!droptofloor()) {
    dprint ("Flag fell out of level at ");
    dprint (vtos(self.origin));
    dprint ("\n");
    remove(self);
    return;
  }
  self.oldorigin = self.origin; // save for flag return
};

// ZOID Capture the flag
void() item_flag_team1 =
{
  self.team = TEAM_COLOR1;
  self.lastteam = TEAM_COLOR1;
  self.items = IT_KEY2;
  precache_model ("progs/flag.mdl");
  setmodel (self, "progs/flag.mdl");
  self.skin = 0;
  precache_sound ("misc/flagtk.wav");     // flag taken
  precache_sound ("misc/flagcap.wav");      // flag capture
  precache_sound ("doors/runetry.wav");
  self.noise = "misc/flagtk.wav";
  self.noise1 = "doors/runetry.wav";
  self.effects = EF_PENTALIGHT;
  setsize(self, '-16 -16 0', '16 16 74');
  self.nextthink = time + 0.2;  // items start after other solids
  self.think = place_flag;
};

void() item_flag_team2 =
{
  self.team = TEAM_COLOR2;
  self.lastteam = TEAM_COLOR2;
  self.items = IT_KEY1;
  precache_model ("progs/flag.mdl");
  setmodel (self, "progs/flag.mdl");
  self.skin = 1;
  precache_sound ("misc/flagtk.wav");     // flag taken
  precache_sound ("misc/flagcap.wav");      // flag capture
  precache_sound ("doors/runetry.wav");
  self.noise = "misc/flagtk.wav";
  self.noise1 = "doors/runetry.wav";
  self.effects = EF_QUADLIGHT;
  setsize(self, '-16 -16 0', '16 16 74');
// make it glow
  self.nextthink = time + 0.2;  // items start after other solids
  self.think = place_flag;
};


/*QUAKED func_ctf_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
Only appears in CTF teamplay
*/
void() func_ctf_wall =
{
  self.angles = '0 0 0';
  self.movetype = MOVETYPE_PUSH;  // so it doesn't get pushed by anything
  self.solid = SOLID_BSP;
  setmodel (self, self.model);
};

