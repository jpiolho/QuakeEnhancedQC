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

// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void(entity attacker, float damage) player_pain;
void() player_stand1;
void (vector org) spawn_tfog;
void (vector org, entity death_owner) spawn_tdeath;
void() UnHookPlayer;

float modelindex_eyes, modelindex_player;
float pregameover;

// if supported by the engine, block color changes from going through
void(float color) SV_ChangeTeam = {
  dprint("SV_ChangeTeam: blocking color change\n");
  return;
}

// ZOID: with several effects doing the dimlight thing, they just can't
// turn it off.  Do not set self.effects with EF_DIMLIGHT directly.  This
// will automatically do it when CheckPowerups is called
// EF_DIMLIGHT is used;
// 1. Invincible (Pentagram)
// 2. Super Damage (Quad Power)
// 3. Having Flag in Capture
// self is player
void () CheckDimLight = {
  local float flag;

  flag = 0;
  // invincable
  if (self.invincible_finished > time)
    flag = 1;
  // quad
  if (self.super_damage_finished > time)
    flag = 1;
  // flag
//  if (self.player_flag & ITEM_ENEMY_FLAG)
//    flag = 1;

  if (flag)
    self.effects = self.effects | EF_DIMLIGHT;
  else
    self.effects = self.effects - (self.effects & EF_DIMLIGHT);
};

/*
=============================================================================

        LEVEL CHANGING / INTERMISSION

=============================================================================
*/

float intermission_running;
float intermission_exittime;

/*QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
This is the camera point for the intermission.
Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
*/
void() info_intermission =
{
};

void() SetChangeParms =
{
  if (self.health <= 0)
  {
    parm14 = self.statstate;
    SetNewParms ();
// *TEAMPLAY*
    parm10 = self.lastteam; // Save the current team of the player
    parm15 = self.accesslvl; // remote admin state
    parm16 = self.player_flag;
    return;
  }

// remove items
  self.items = self.items - (self.items & 
  (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) );

// cap super health
  if (self.health > 100)
    self.health = 100;
  if (self.health < 50)
    self.health = 50;
  parm14 = self.statstate;
  SetNewParms();
// *TEAMPLAY*
  if (gamestart || self.observer)
    parm10 = -1;
  else
    parm10 = self.lastteam; // Save the current team of the player
  parm15 = self.accesslvl; // remote admin state
  parm16 = self.player_flag;
};

void() SetNewParms =
{
  if (gamestart && !pregameover) {
    parm1 = IT_AXE;
    parm2 = 100;
    parm4 = 0;
    parm8 = IT_AXE;
    parm10 = 1;
  } else {
    if (cvar("teamplay") & TEAM_DISABLE_GRAPPLE)
      parm1 = IT_SHOTGUN | IT_AXE;
    else
      parm1 = IT_SHOTGUN | IT_AXE | IT_HOOK;
    parm2 = 100;
    parm3 = 50;
    parm9 = 30;
    parm1 = parm1 + IT_ARMOR1;
    parm4 = 40;
    parm8 = IT_SHOTGUN;
    parm10 = -1;  // Reset 
  }
  parm5 = 0;
  parm6 = 0;
  parm7 = 0;
// *TEAMPLAY*
  parm14 = self.statstate;
  parm15 = 0; // remote admin
  parm16 = 0;
};

void() DecodeLevelParms =
{
  self.player_flag = self.player_flag | parm16;
  self.player_flag = self.player_flag - (self.player_flag & ITEM_RUNE_MASK);
  self.player_flag = self.player_flag - (self.player_flag & ITEM_ENEMY_FLAG);
  self.skin = (self.player_flag & 65280)/256;
  self.accesslvl = parm15;
  self.statstate = parm14;

  if (gamestart)
    SetNewParms ();   // take away all stuff on starting new episode
  
  self.items = parm1;
  self.health = parm2;
  self.armorvalue = parm3;
  self.ammo_shells = parm4;
  self.ammo_nails = parm5;
  self.ammo_rockets = parm6;
  self.ammo_cells = parm7;
  self.weapon = parm8;
  self.armortype = parm9 * 0.01;

  // *XXX* EXPERT CTF

  // Reset times for additional scoring system on level change and server join
  // dprint("decode level parms\n");
  self.last_returned_flag = -10;
  self.last_fragged_carrier = -10;
  self.flag_since = -10;
  self.last_hurt_carrier = -10;

// *TEAMPLAY*
  if(TeamColorIsLegal(parm10))
    self.lastteam = parm10;
};

/*
============
FindIntermission

Returns the entity to view from
============
*/
entity() FindIntermission =
{
  local entity spot;
  local float cyc;

// look for info_intermission first
  spot = find (world, classname, "info_intermission");
  if (spot)
  { // pick a random one
    cyc = random() * 4;
    while (cyc > 1)
    {
      spot = find (spot, classname, "info_intermission");
      if (!spot)
        spot = find (spot, classname, "info_intermission");
      cyc = cyc - 1;
    }
    return spot;
  }

// then look for the start position
  spot = find (world, classname, "info_player_start");
  if (spot)
    return spot;
  
// testinfo_player_start is only found in regioned levels
  spot = find (world, classname, "testplayerstart");
  if (spot)
    return spot;
  
  objerror ("FindIntermission: no spot");
};


string nextmap;
void() GotoNextMap =
{
  if (cvar("samelevel"))  // if samelevel is set, stay on same level
    changelevel (mapname);
  else {
    if (mapname == "ctf1") nextmap = "ctf2";
    else if (mapname == "ctf2") nextmap = "ctf3";
    else if (mapname == "ctf3") nextmap = "ctf4";
    else if (mapname == "ctf4") nextmap = "ctf5";
    else if (mapname == "ctf5") nextmap = "ctf6";
    else if (mapname == "ctf6") nextmap = "ctf7";
    else if (mapname == "ctf7") nextmap = "ctf8";
    else if (mapname == "ctf8") nextmap = "ctf9";
    else if (mapname == "ctf9") nextmap = "ctf1";
    else nextmap = "ctf1";

    changelevel (nextmap);
  }
};


void() ExitIntermission =
{
// skip any text in deathmatch
  if (deathmatch)
  {
    GotoNextMap ();
    return;
  }
  
  intermission_exittime = time + 1;
  intermission_running = intermission_running + 1;

//
// run some text if at the end of an episode
//
  if (intermission_running == 2)
  {
    if (world.model == "maps/e1m7.bsp")
    {
      WriteByte (MSG_ALL, SVC_CDTRACK);
      WriteByte (MSG_ALL, 2);
      WriteByte (MSG_ALL, 3);
  
      if (!cvar("registered"))
      {
        WriteByte (MSG_ALL, SVC_FINALE);
        WriteString (MSG_ALL, "$qc_finale_e1_shareware");
      }
      else
      {
        WriteByte (MSG_ALL, SVC_FINALE);
        WriteString (MSG_ALL, "$qc_finale_e1");
      }
  
      return;
    }
    else if (world.model == "maps/e2m6.bsp")
    {
      WriteByte (MSG_ALL, SVC_CDTRACK);
      WriteByte (MSG_ALL, 2);
      WriteByte (MSG_ALL, 3);

      WriteByte (MSG_ALL, SVC_FINALE);
      WriteString (MSG_ALL, "$qc_finale_e2");
      return;
    }
    else if (world.model == "maps/e3m6.bsp")
    {
      WriteByte (MSG_ALL, SVC_CDTRACK);
      WriteByte (MSG_ALL, 2);
      WriteByte (MSG_ALL, 3);

      WriteByte (MSG_ALL, SVC_FINALE);
      WriteString (MSG_ALL, "$qc_finale_e3");
      return;
    }
    else if (world.model == "maps/e4m7.bsp")
    {
      WriteByte (MSG_ALL, SVC_CDTRACK);
      WriteByte (MSG_ALL, 2);
      WriteByte (MSG_ALL, 3);

      WriteByte (MSG_ALL, SVC_FINALE);
      WriteString (MSG_ALL, "$qc_finale_e4");
      return;
    }

    GotoNextMap();
  }
  
  if (intermission_running == 3)
  {
    if (!cvar("registered"))
    { // shareware episode has been completed, go to sell screen
      WriteByte (MSG_ALL, SVC_SELLSCREEN);
      return;
    }
    
    if ( (serverflags&15) == 15)
    {
      WriteByte (MSG_ALL, SVC_FINALE);
      WriteString (MSG_ALL, "$qc_finale_all_runes");
      return;
    }
    
  }

  GotoNextMap();
};

/*
============
IntermissionThink

When the player presses attack or jump, change to the next level
============
*/
void() IntermissionThink =
{
  if (time < intermission_exittime)
    return;

  if (!self.button0 && !self.button1 && !self.button2)
    return;
  
  ExitIntermission ();
};

void() execute_changelevel =
{
  local entity  pos;

  intermission_running = 1;

  // enforce a wait time before allowing changelevel
  if (deathmatch)
    intermission_exittime = time + 5;
  else
    intermission_exittime = time + 2;

  WriteByte (MSG_ALL, SVC_CDTRACK);
  WriteByte (MSG_ALL, 3);
  WriteByte (MSG_ALL, 3);
  
  pos = FindIntermission ();

  other = find (world, classname, "player");

  while (other != world)
  {
    other.view_ofs = '0 0 0';
    other.angles = other.v_angle = pos.mangle;
    other.fixangle = TRUE;    // turn this way immediately
    other.nextthink = time + 0.5;
    other.takedamage = DAMAGE_NO;
    other.solid = SOLID_NOT;
    other.movetype = MOVETYPE_NONE;
    other.modelindex = 0;
    setorigin (other, pos.origin);
    other = find (other, classname, "player");
  } 

  WriteByte (MSG_ALL, SVC_INTERMISSION);
};


void() changelevel_touch =
{
  local entity  pos;
  local float noexit;

  if (other.classname != "player")
    return;

  noexit = cvar("noexit");

  if (noexit == 1 || (noexit == 2 && !gamestart))
    return; // do nothing

  if (coop || deathmatch)
  {
    bprint("$qc_exited", other.netname);
  }
  
  nextmap = self.map;

  SUB_UseTargets ();

  if ( (self.spawnflags & 1) && (deathmatch == 0) )
  { // NO_INTERMISSION
    GotoNextMap();
    return;
  }
  
  self.touch = SUB_Null;

// we can't move people right now, because touch functions are called
// in the middle of C movement code, so set a think time to do it
  self.think = execute_changelevel;
  self.nextthink = time + 0.1;
};

/*QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
*/
void() trigger_changelevel =
{
  if (!self.map)
    objerror ("chagnelevel trigger doesn't have map");
  
  InitTrigger ();
  self.touch = changelevel_touch;
};


/*
=============================================================================

        PLAYER GAME EDGE FUNCTIONS

=============================================================================
*/

void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
  // make a copy of the dead body for appearances sake
  CopyToBodyQueue (self);
  // set default spawn parms
  SetNewParms ();
  // respawn    
  PutClientInServer ();
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
  if (self.observer)
    return; // can't suicide when observer

  if (gamestart) {
    return;
  }

  if (self.suicide_count > 3) {
    sprint(self, "$qc_ctf_too_many_suicide");
    return;
  }
  bprint("$qc_suicides", self.netname);
  DropRune();
    TeamCaptureDropFlagOfPlayer(self);
  UnHookPlayer();
  set_suicide_frame ();
  self.modelindex = modelindex_player;
  self.frags = self.frags - 2;  // extra penalty
  self.suicide_count = self.suicide_count + 1;
  respawn ();
};

void() SilentKill =
{
  set_suicide_frame ();
  self.modelindex = modelindex_player;
  respawn ();
};

float(vector v) CheckSpawnPoint =
{
  return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
  local entity spot;
  
// testinfo_player_start is only found in regioned levels
  spot = find (world, classname, "testplayerstart");
  if (spot)
    return spot;
    
// choose a info_player_deathmatch point
  if (coop)
  {
    lastspawn = find(lastspawn, classname, "info_player_coop");
    if (lastspawn == world)
      lastspawn = find (lastspawn, classname, "info_player_start");
    if (lastspawn != world)
      return lastspawn;
  }
  else if (deathmatch)
  {
    if (!self.killed) {
      spot = TeamCaptureSpawn();
      if (spot != world) 
        return spot;
    } else if (gamestart && self.killed) {
      lastvotespawn = find(lastvotespawn, classname, "info_vote_destination");
      if (lastvotespawn == world)
        lastvotespawn = find(lastvotespawn, classname, "info_vote_destination");
      return lastvotespawn;
    }
  
    lastspawn = find(lastspawn, classname, "info_player_deathmatch");
    if (lastspawn == world)
      lastspawn = find (lastspawn, classname, "info_player_deathmatch");
    if (lastspawn != world)
      return lastspawn;
  }

  if (serverflags)
  { // return with a rune to start
    spot = find (world, classname, "info_player_start2");
    if (spot)
      return spot;
  }
  
  spot = find (world, classname, "info_player_start");
  if (!spot)
    error ("PutClientInServer: no info_player_start on level");
  
  return spot;
};

/*
===========
PutClientInServer

called each time a player is spawned
============
*/
void() DecodeLevelParms;
void() PlayerDie;


void() PutClientInServer =
{
  local entity spot;

  serverflags = 0; // make sure it's clear

  spot = SelectSpawnPoint ();

  self.classname = "player";
  self.health = 100;
  self.takedamage = DAMAGE_AIM;
  self.solid = SOLID_SLIDEBOX;
  self.movetype = MOVETYPE_WALK;
  self.show_hostile = 0;
  self.max_health = 100;
  self.flags = FL_CLIENT;
  self.air_finished = time + 12;
  self.dmg = 2;       // initial water damage
  self.super_damage_finished = 0;
  self.radsuit_finished = 0;
  self.invisible_finished = 0;
  self.invincible_finished = 0;
  self.effects = 0;
  self.invincible_time = 0;
  self.staydeadtime = 0;
  self.regen_time = 0;
  self.rune_notice_time = 0;

  self.last_hurt_carrier = -10;

  DecodeLevelParms ();
  
  W_SetCurrentAmmo ();

  self.attack_finished = time;
  self.th_pain = player_pain;
  self.th_die = PlayerDie;
  
  self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
  self.pausetime = 0;
  
//  spot = SelectSpawnPoint ();

  self.fixangle = TRUE;   // turn this way immediately

// oh, this is a hack!
  setmodel (self, "progs/eyes.mdl");
  modelindex_eyes = self.modelindex;

  setmodel (self, "progs/player.mdl");
  modelindex_player = self.modelindex;

  setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
  self.view_ofs = '0 0 22';

  self.origin = spot.origin + '0 0 1';
  self.angles = spot.angles;
  player_stand1 ();

  if (self.do_observer) {
    BecomeObserver(self);
    return;
  }

  if (deathmatch || coop)
  {
    makevectors(self.angles);
    spawn_tfog (self.origin + v_forward*20);
  }

  spawn_tdeath (self.origin, self);
};


/*
=============================================================================

        QUAKED FUNCTIONS

=============================================================================
*/


/*QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
The normal starting point for a level.
*/
void() info_player_start =
{
};


/*QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
Only used on start map for the return point from an episode.
*/
void() info_player_start2 =
{
};


void() SpawnRunes;

/*
saved out by quaked in region mode
*/
void() testplayerstart =
{
};

/*QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for deathmatch games
*/
void() info_player_deathmatch =
{
  if (deathmatch)
    StartRuneSpawn();
};

void() info_player_team1 =
{
};

void() info_player_team2 =
{
};

/*QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
potential spawning position for coop games
*/
void() info_player_coop =
{
};

/*
===============================================================================

RULES

===============================================================================
*/

/*
go to the next level for deathmatch
only called if a time or frag limit has expired
*/
void() NextLevel =
{
  local entity o;

  if (mapname == "ctf1") nextmap = "ctf2";
  else if (mapname == "ctf2") nextmap = "ctf3";
  else if (mapname == "ctf3") nextmap = "ctf4";
  else if (mapname == "ctf4") nextmap = "ctf5";
  else if (mapname == "ctf5") nextmap = "ctf6";
  else if (mapname == "ctf6") nextmap = "ctf7";
  else if (mapname == "ctf7") nextmap = "ctf8";
  else if (mapname == "ctf8") nextmap = "ctf9";
  else if (mapname == "ctf9") nextmap = "ctf1";
  else nextmap = "ctf1";

  o = spawn();
  o.map = nextmap;
  o.think = execute_changelevel;
  o.nextthink = time + 0.1;
};

/*
============
CheckRules

Exit deathmatch games upon conditions
============
*/
void() CheckRules =
{
  local float   timelimit;
  local float   fraglimit;
  local entity    o;

  if (gameover || pregameover)  // someone else quit the game already
    return;

  if (gamestart) {
    if ((vote_leader != world) && voteexit_time && (time > voteexit_time)) {
      pregameover = 1;
      o = spawn();
      nextmap = vote_leader.map;
      o.map = nextmap;
      o.think = execute_changelevel;
      o.nextthink = time + 0.1;
      return;
    }
    return;
  }

  timelimit = cvar("timelimit") * 60;
  fraglimit = cvar("fraglimit");
  
  if ((timelimit && time >= timelimit) ||
    (fraglimit && (teamscr1 >= fraglimit || teamscr2 >= fraglimit))) {
    pregameover = 1;
    TeamEndScore();
    NextLevel ();
    return;
  }

};

//============================================================================

void() PlayerDeathThink =
{
  local entity  old_self;
  local float   forward;

  if ((self.flags & FL_ONGROUND))
  {
    forward = vlen (self.velocity);
    forward = forward - 20;
    if (forward <= 0)
      self.velocity = '0 0 0';
    else
      self.velocity = forward * normalize(self.velocity);
  }

// wait for all buttons released
  if (self.deadflag == DEAD_DEAD)
  {
    if (self.button2 || self.button1 || self.button0)
      return;
    self.deadflag = DEAD_RESPAWNABLE;
    return;
  }

// wait for any button down
  if (!self.button2 && !self.button1 && !self.button0)
    return;

  self.button0 = 0;
  self.button1 = 0;
  self.button2 = 0;
  respawn();
};


void() PlayerJump =
{
  local vector start, end;
  
  if (self.flags & FL_WATERJUMP)
    return;
  
  if (self.waterlevel >= 2)
  {
    if (self.watertype == CONTENT_WATER)
      self.velocity_z = 100;
    else if (self.watertype == CONTENT_SLIME)
      self.velocity_z = 80;
    else
      self.velocity_z = 50;

// play swiming sound
    if (self.swim_flag < time)
    {
      self.swim_flag = time + 1;
      if (random() < 0.5)
        sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
      else
        sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
    }

    return;
  }

  if (!(self.flags & FL_ONGROUND))
    return;

  if ( !(self.flags & FL_JUMPRELEASED) )
    return;   // don't pogo stick

  self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

  self.flags = self.flags - FL_ONGROUND;  // don't stairwalk
  
  self.button2 = 0;
// player jumping sound
  sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
  self.velocity_z = self.velocity_z + 270;
};


/*
===========
WaterMove

============
*/
.float  dmgtime;

void() WaterMove =
{
//dprint (ftos(self.waterlevel));
  if (self.movetype == MOVETYPE_NOCLIP)
    return;
  if (self.health < 0)
    return;

  if (self.waterlevel != 3)
  {
    if (self.air_finished < time)
      sound (self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM);
    else if (self.air_finished < time + 9)
      sound (self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM);
    self.air_finished = time + 12;
    self.dmg = 2;
  }
  else if (self.air_finished < time)
  { // drown!
    if (self.pain_finished < time)
    {
      self.dmg = self.dmg + 2;
      if (self.dmg > 15)
        self.dmg = 10;
      T_Damage (self, world, world, self.dmg);
      self.pain_finished = time + 1;
    }
  }

  if (!self.waterlevel)
  {
    if (self.flags & FL_INWATER)
    { 
      // play leave water sound
      sound (self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM);
      self.flags = self.flags - FL_INWATER;
    }
    return;
  }

  if (self.watertype == CONTENT_LAVA)
  { // do damage
    if (self.dmgtime < time)
    {
      if (self.radsuit_finished > time)
        self.dmgtime = time + 1;
      else
        self.dmgtime = time + 0.2;

      T_Damage (self, world, world, 10*self.waterlevel);
    }
  }
  else if (self.watertype == CONTENT_SLIME)
  { // do damage
    if (self.dmgtime < time && self.radsuit_finished < time)
    {
      self.dmgtime = time + 1;
      T_Damage (self, world, world, 4*self.waterlevel);
    }
  }
  
  if ( !(self.flags & FL_INWATER) )
  { 

// player enter water sound

    if (self.watertype == CONTENT_LAVA)
      sound (self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM);
    if (self.watertype == CONTENT_WATER)
      sound (self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM);
    if (self.watertype == CONTENT_SLIME)
      sound (self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM);

    self.flags = self.flags + FL_INWATER;
    self.dmgtime = 0;
  }
  
  if (! (self.flags & FL_WATERJUMP) )
    self.velocity = self.velocity - 0.8*self.waterlevel*frametime*self.velocity;
};

void() CheckWaterJump =
{
  local vector start, end;

// check for a jump-out-of-water
  makevectors (self.angles);
  start = self.origin;
  start_z = start_z + 8; 
  v_forward_z = 0;
  normalize(v_forward);
  end = start + v_forward*24;
  traceline (start, end, TRUE, self);
  if (trace_fraction < 1)
  { // solid at waist
    start_z = start_z + self.maxs_z - 8;
    end = start + v_forward*24;
    self.movedir = trace_plane_normal * -50;
    traceline (start, end, TRUE, self);
    if (trace_fraction == 1)
    { // open at eye level
      self.flags = self.flags | FL_WATERJUMP;
      self.velocity_z = 225;
      self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
      self.teleport_time = time + 2;  // safety net
      return;
    }
  }

};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
  local float mspeed, aspeed;
  local float r;
  local string  s;

  if (intermission_running)
  {
    IntermissionThink (); // otherwise a button could be missed between
    return;         // the think tics
  }
  if (self.staydeadtime && self.staydeadtime > time)
    return;// wait a bit before respawn

// *TEAMPLAY*
  if (coop && TEAM_STRICT_COOP)
    return;

  if (self.motd_sent == 2)
  {
    self.motd_sent += 1;
    if (self.observer)
      MOTD_ChooseTeam();
    else
      MOTD();
  }

  // don't send the message immediately on connect, wait a frame
  if (self.motd_sent < 2)
    self.motd_sent += 1;

  if ( self.flags & FL_ISBOT ) { // make sure bots end up on a team...
      if ( self.team != TEAM_COLOR1 && self.team != TEAM_COLOR2 ) {
          self.impulse = 103;
    }
  }

  DoObserverImpulse();

  if (self.view_ofs == '0 0 0')
    return;   // intermission or finale

  makevectors (self.v_angle);   // is this still used

  CheckRules ();
  WaterMove ();

// *TEAMPLAY*
// TeamCheckLock performs all necessary teamlock checking, and performs all
// actions needed.
  TeamCheckLock();

  if (self.waterlevel == 2)
    CheckWaterJump ();

  if (self.deadflag >= DEAD_DEAD)
  {
    PlayerDeathThink ();
    return;
  }

//ZOID-Observer
  if (self.observer) {
    ObserverThink();
    return;
  }
//

  if (self.deadflag == DEAD_DYING)
    return; // dying, so do nothing

  if (self.button2)
  {
    PlayerJump ();
  }
  else
    self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time  
  if (time < self.pausetime)
    self.velocity = '0 0 0';


// RUNE: If player has rune of elder magic (4), regeneration
  if (self.player_flag & ITEM_RUNE4_FLAG) {
    if (self.regen_time < time) {
      self.regen_time = time;
      if (self.health < 150) {
        self.health = self.health + 5;
        if (self.health > 150)
          self.health = 150;
        self.regen_time = self.regen_time + 0.5;
        RegenerationSound();
      }
      if (self.armorvalue < 150 && self.armortype) {
        self.armorvalue = self.armorvalue + 5;
        if (self.armorvalue > 150)
          self.armorvalue = 150;
        self.regen_time = self.regen_time + 0.5;
        RegenerationSound();
      }
    }
  }
// RUNE

  if(time > self.attack_finished && self.currentammo == 0 && 
    self.weapon != IT_AXE && self.weapon != IT_HOOK)
  {
    self.weapon = W_BestWeapon ();
    W_SetCurrentAmmo ();
  }

  // Track the grapple
  if (self.hook_out)
    GrappleTrail(self.goalentity, self);
};
  
/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
  if (self.health <= 0)
    return;

// invisibility
  if (self.invisible_finished)
  {
// sound and screen flash when items starts to run out
    if (self.invisible_sound < time)
    {
      sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
      self.invisible_sound = time + ((random() * 3) + 1);
    }


    if (self.invisible_finished < time + 3)
    {
      if (self.invisible_time == 1)
      {
        sprint(self, "$qc_ring_fade");
        stuffcmd (self, "bf\n");
        sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
        self.invisible_time = time + 1;
      }
      
      if (self.invisible_time < time)
      {
        self.invisible_time = time + 1;
        stuffcmd (self, "bf\n");
      }
    }

    if (self.invisible_finished < time)
    { // just stopped
      self.items = self.items - IT_INVISIBILITY;
      self.invisible_finished = 0;
      self.invisible_time = 0;
    }
    
  // use the eyes
    self.frame = 0;
    self.modelindex = modelindex_eyes;
  }
  else
    self.modelindex = modelindex_player;  // don't use eyes

// invincibility
  if (self.invincible_finished)
  {
// sound and screen flash when items starts to run out
    if (self.invincible_finished < time + 3)
    {
      if (self.invincible_time == 1)
      {
        sprint(self, "$qc_protection_fade");
        stuffcmd (self, "bf\n");
        sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
        self.invincible_time = time + 1;
      }
      
      if (self.invincible_time < time)
      {
        self.invincible_time = time + 1;
        stuffcmd (self, "bf\n");
      }
    }
    
    if (self.invincible_finished < time)
    { // just stopped
      self.items = self.items - IT_INVULNERABILITY;
      self.invincible_time = 0;
      self.invincible_finished = 0;
    }
// ZOID, next line isn't needed, EF_DIMLIGHT is handled by
// client.qc:CheckDimLight
//    if (self.invincible_finished > time)
//      self.effects = self.effects | EF_DIMLIGHT;
//    else
//      self.effects = self.effects - (self.effects & EF_DIMLIGHT);
  }

// super damage
  if (self.super_damage_finished)
  {

// sound and screen flash when items starts to run out

    if (self.super_damage_finished < time + 3)
    {
      if (self.super_time == 1)
      {
        sprint(self, "$qc_quad_fade");
        stuffcmd (self, "bf\n");
        sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
        self.super_time = time + 1;
      }   
      
      if (self.super_time < time)
      {
        self.super_time = time + 1;
        stuffcmd (self, "bf\n");
      }
    }

    if (self.super_damage_finished < time)
    { // just stopped
      self.items = self.items - IT_QUAD;
      self.super_damage_finished = 0;
      self.super_time = 0;
    }
// ZOID, next line isn't needed, EF_DIMLIGHT is handled by
// client.qc:CheckDimLight
//    if (self.super_damage_finished > time)
//      self.effects = self.effects | EF_DIMLIGHT;
//    else
//      self.effects = self.effects - (self.effects & EF_DIMLIGHT);
  } 

// suit 
  if (self.radsuit_finished)
  {
    self.air_finished = time + 12;    // don't drown

// sound and screen flash when items starts to run out
    if (self.radsuit_finished < time + 3)
    {
      if (self.rad_time == 1)
      {
        sprint(self, "$qc_biosuit_fade");
        stuffcmd (self, "bf\n");
        sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
        self.rad_time = time + 1;
      }
      
      if (self.rad_time < time)
      {
        self.rad_time = time + 1;
        stuffcmd (self, "bf\n");
      }
    }

    if (self.radsuit_finished < time)
    { // just stopped
      self.items = self.items - IT_SUIT;
      self.rad_time = 0;
      self.radsuit_finished = 0;
    }
  } 

  // Check to see about DIMLIGHT effects
  CheckDimLight();
};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
  local float mspeed, aspeed;
  local float r;
    local   string  num;


  if (self.view_ofs == '0 0 0')
    return;   // intermission or finale

  if (self.deadflag) {
    return;
  }

// do weapon stuff

if (!self.observer)
  W_WeaponFrame ();

// check to see if player landed and play landing sound 
  if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
  {
    if (self.watertype == CONTENT_WATER)
      sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
    else if (self.jump_flag < -650 && !self.hook_pulling)
    {
      T_Damage (self, world, world, 5); 
      sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
      self.deathtype = "falling";
    }
    else
      sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);

    self.jump_flag = 0;
  }

  if (!(self.flags & FL_ONGROUND))
    self.jump_flag = self.velocity_z;

  CheckPowerups ();

};


/*
===========
ClientConnect

called when a player connects to a server
============
*/
void() ClientConnect =
{
  bprint("$qc_entered", self.netname);
  
  LogMsg(self, "CONNECT");

  self.suicide_count = 0;
  self.killed = 0;
  self.frags = 0;
  self.voted = 0;
  self.motd_sent = 0;

  if ( parm10 < 0 && teamplay > 0 ) {
    // *TEAMPLAY*
    // If this is our first connection, parm10 is < 0
    // Set lastteam negative.
    self.lastteam = -50;
    self.team = -1;

    if ( teamplay & TEAM_CAPTURE_SELECT_TEAM ) {
      self.do_observer = 1;
    } else if ( !self.do_observer ) {
      TeamCheckLock();
      self.player_flag = self.player_flag | TEAM_STUFF_COLOR;
      self.player_flag = self.player_flag - ( self.player_flag & 65280 );
      self.player_flag = self.player_flag | ( self.skin * 256 );  
    }
  }

  SendCTFScoresUpdate( self );

// a client connecting during an intermission can cause problems
  if ( intermission_running ) {
    ExitIntermission();
  }
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
  if (gameover)
    return;
  // if the level end trigger has been activated, just return
  // since they aren't *really* leaving

  // let everyone else know
  bprint("$qc_left_game", self.netname, ftos(self.frags));
  sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);
  DropRune();
    TeamCaptureDropFlagOfPlayer(self);
  set_suicide_frame ();

  self.lastteam = -50;
  self.team = -50;
  self.frags = 0;
  self.statstate = 0;

  LogMsg(self, "DISCONNECT");
};

// *TEAMPLAY*
// Prototypes

float(entity targ, entity attacker) TeamFragPenalty;
void(entity targ, entity attacker) TeamDeathPenalty;

/*
===========
ClientObituary

called when a player dies
============
*/
void(entity targ, entity attacker) ClientObituary =
{

  // *XXX* EXPERT CTF variable for 
  // flag/flag carrier defense bonus determination
  local entity head;
  local float flag_radius;
  local float flag_carrier_radius;

  local float rnum;

  // from GPL QW source
  local   float  attackerteam, targteam;
  
  attackerteam = attacker.team;
  targteam = targ.team;
  local string s;

  rnum = random();

  if (targ.classname == "player")
  {

    // *XXX* EXPERT CTF: 
    // When the flag carrier dies, reset the last_hurt_carrier field in
    // all players on the opposite team from the flag carrier.  The carrier
    // has been killed, so there is no longer a reason to award points for
    // killing off his assailants
    if (targ.player_flag & ITEM_ENEMY_FLAG) {

      head = find(world, classname, "player");

      while (head != world) { 
        if (head.team != targ.team) {
          head.last_hurt_carrier = -10;
        }
        head = find(head, classname, "player");
      }
    }
    // END EXPERT CTF

    if (attacker.classname == "teledeath")
    {
      bprint("$qc_telefragged", targ.netname, attacker.owner.netname);


      attacker.owner.frags = attacker.owner.frags + 1;
      LogPlayerDMDeath(targ, attacker.owner, "telefrag");
      return;
    }

    if (attacker.classname == "teledeath2")
    {
      bprint("$qc_satans_power", targ.netname);


      targ.frags = targ.frags - 1;
      LogPlayerDeath(targ, "telefrag");
      return;
    }

    if (attacker.classname == "player")
    {
      if (targ == attacker)
      {
        // killed self
        attacker.frags = attacker.frags - 1;
        
        if (targ.weapon == 64 && targ.waterlevel > 1)
        {
          if (targ.watertype == CONTENT_SLIME)
            bprint("$qc_discharge_slime", targ.netname);

          else if (targ.watertype == CONTENT_LAVA)
            bprint("$qc_discharge_lava", targ.netname);

          else
            bprint("$qc_discharge_water", targ.netname);

          LogPlayerDeath(targ, "discharge");
          return;
        }
        if (targ.weapon == IT_GRENADE_LAUNCHER) {
          bprint("$qc_suicide_pin", targ.netname);
          LogPlayerDeath(targ, "grenade");
        } else if (targ.team != targ.lastteam) {
          //ZOID: try if player was gibbed for changing teams
          if (teamplay & TEAM_STATIC_TEAMS)
            bprint ("$qc_ks_tried_change_teams", targ.netname);
          else
            bprint ("$qc_ks_changed_teams", targ.netname);
          LogPlayerDeath(targ, "teamchange");
        } else {
          bprint("$qc_suicide_bored", targ.netname);
          LogPlayerDeath(targ, "rocket");
        }
        return;
      }
      else if ( (teamplay == 2) && (targteam == attackerteam) &&
        (attackerteam != 0) )
      {
        if (rnum < 0.25)
          bprint("$qc_ff_teammate", attacker.netname);
        else if (rnum < 0.50)
          bprint("$qc_ff_glasses", attacker.netname);
        else if (rnum < 0.75)
          bprint("$qc_ff_otherteam", attacker.netname);
        else
          bprint("$qc_ff_friend", attacker.netname);

        attacker.frags = attacker.frags - 1;
        return;
      }
      else
      {
        // *TEAMPLAY*
        // TeamFragPenalty returns true if the attacker gets a frag penalty for
        // killing this target.  It also deducts frags as needed.
        if (!TeamFragPenalty(targ, attacker)) {

          // the attacker is award the normal one frag.. now we 
          // determine if he gets any bonuses
          attacker.frags = attacker.frags + 1;
 
          if ((targ.player_flag & ITEM_ENEMY_FLAG) &&
            (targ.team != attacker.team)) {
            //ZOID: one team fragged the other team's flag carrier
 
            // *XXX* EXPERT CTF
            // Mark the attacker with the time at which he killed the flag
            // carrier, for awarding assist points
 
            attacker.last_fragged_carrier = time;
 
            // *XXX* EXPERT CTF: give player only the normal amount of frags
            // if the carrier has only had the flag for a few seconds, to
            // prevent ppl intentionally allowing enemies to grab the flag,
            // then immediately fragging them
 
            if (targ.flag_since + TEAM_CAPTURE_CARRIER_FLAG_SINCE_TIMEOUT > time) {
              sprint(attacker, "$qc_ctf_carrier_no_bonus");
            } else {
              attacker.frags = attacker.frags + TEAM_CAPTURE_FRAG_CARRIER_BONUS;
                              // TeamScore (attacker, TEAM_CAPTURE_FRAG_CARRIER_BONUS);
              s = ftos(TEAM_CAPTURE_FRAG_CARRIER_BONUS);
              sprint(attacker, "$qc_ctf_kill_carrier", s);
            }
            // END FLAG CARRIER FRAG CODE
          }
          
          // *XXX* EXPERT CTF
          // This code checks for all game-critical kills OTHER THAN fragging the enemy
          // flag carrier, like killing players who are trying to kill your flag carrier
          // or trying to grab your flag, and hands out bonus frags.
 
          // The two variables below track whether special bonus frags have already
          // been awarded for the attacker or target being near the flag or flag carrier.  
 
          flag_radius = 0;
          flag_carrier_radius = 0;
 
          // get a string for the attacker's team now, for later announcements
          s = GetCTFTeam(attacker.team);
 
          if ((targ.last_hurt_carrier + TEAM_CAPTURE_CARRIER_DANGER_PROTECT_TIMEOUT > time) &&
              !(attacker.player_flag & ITEM_ENEMY_FLAG) ) {
            // a player on the same team as the flag carrier killed 
            // someone who recently shot the flag carrier
            attacker.frags = attacker.frags + 
              TEAM_CAPTURE_CARRIER_DANGER_PROTECT_BONUS;
            flag_carrier_radius = 1;
            // NOTE: getting CARRIER_DANGER_PROTECT_BONUS precludes getting
            // other kinds of bonuses for defending the flag carrier, since
            // it's worth more points
            bprint("$qc_ks_defends_carrier_aggressive", attacker.netname, s);
          }
 
          // *XXX* EXPERT CTF
          // Bonusus for defending the flag carrier or the flag itself.
          // Extra frags are awarded if either the attacker or the target are
          // 1. within 40 feet of a flag carrier on the same team as the attacker
          // 2. within 40 feet of the attacker's flag
          // These bonuses are cumulative with respect to defending both the
          // flag and the flag carrier at the same time, but not cumulative with
          // respect to both the target and attacker being near the object being defended
 
          // find flags or flag carriers within a radius of the attacker
          head = findradius(attacker.origin, TEAM_CAPTURE_ATTACKER_PROTECT_RADIUS);
 
          while (head) {
            if (head.classname == "player") {
              if ( (head.team == attacker.team) &&
                   (head.player_flag & ITEM_ENEMY_FLAG) &&
                   (head != attacker) && // self defense
                   (!flag_carrier_radius) ) { 
                // attacker was near his own flag carrier
                attacker.frags = attacker.frags + 
                  TEAM_CAPTURE_CARRIER_PROTECT_BONUS;
                flag_carrier_radius = 1;
                bprint("$qc_ks_defends_carrier", attacker.netname, s);
              }
            }
            if ( (head.classname == "item_flag_team1") ||
                 (head.classname == "item_flag_team2")) {
              if (((attacker.team == TEAM_COLOR1) &&
                (head.classname == "item_flag_team1")) ||
                ((attacker.team == TEAM_COLOR2) &&
                (head.classname == "item_flag_team2"))) { 
                // attacker was near his own flag
                attacker.frags = attacker.frags + 
                  TEAM_CAPTURE_FLAG_DEFENSE_BONUS;
                flag_radius = 1; 
                 bprint("$qc_ks_defends_flag", attacker.netname, s);
              }
            }
            head = head.chain;
          }
 
          // find flags or flag carriers within a radius from the target
          head = findradius(targ.origin, TEAM_CAPTURE_TARGET_PROTECT_RADIUS);
          while (head) {
            if (head.classname == "player") {
              if ( (head.team == attacker.team) &&
                   (head.player_flag & ITEM_ENEMY_FLAG) &&
                   (head != attacker) &&
                   (!flag_carrier_radius)) { // prevents redundant points awarded
                // target was near attacker's flag carrier
                attacker.frags = attacker.frags + 
                  TEAM_CAPTURE_CARRIER_PROTECT_BONUS;
                flag_carrier_radius = 1;
                bprint("$qc_ks_defends_carrier", attacker.netname, s);
              }
            }
            if (((attacker.team == TEAM_COLOR1) &&
              (head.classname == "item_flag_team1")) ||
              ((attacker.team == TEAM_COLOR2) &&
              (head.classname == "item_flag_team2"))
              && (!flag_radius)) { // prevents redundant points awarded
              // target was near attacker's flag
              attacker.frags = attacker.frags + 
                TEAM_CAPTURE_FLAG_DEFENSE_BONUS;
              flag_radius = 1;
              bprint("$qc_ks_defends_the_flag", attacker.netname, s);
            }
            head = head.chain;
          }
        } 
       
        // *XXX* EXPERT CTF 
        // End frag determination code.  Now determine death text for
        // a member of one team killing a member of the other
 
        // *TEAMPLAY*
        // TeamDeathPenalty kills the attacker if necessary and adjusts frags to
        // offset the one frag penalty for dying.
        TeamDeathPenalty(targ, attacker);

        rnum = attacker.weapon;
        if (rnum == IT_AXE)
        {
          bprint("$qc_death_ax", targ.netname, attacker.netname);
          LogPlayerDMDeath(targ, attacker, "axe");
          return;
        }
        if (rnum == IT_HOOK) {
          LogPlayerDMDeath(targ, attacker, "hook");
          if (random() < 0.5)
            bprint("$qc_death_hook1", targ.netname, attacker.netname);
          else
          bprint("$qc_death_hook2", targ.netname, attacker.netname);
          return;
          
        }
        if (rnum == IT_SHOTGUN)
        {
          bprint("$qc_death_sg", targ.netname, attacker.netname);
          LogPlayerDMDeath(targ, attacker, "shotgun");
          return;
        }

        if (rnum == IT_SUPER_SHOTGUN)
        {
          bprint("$qc_death_dbl", targ.netname, attacker.netname);
          LogPlayerDMDeath(targ, attacker, "supershotgun");
          return;
        }

        if (rnum == IT_NAILGUN)
        {
          bprint("$qc_death_nail", targ.netname, attacker.netname);
          LogPlayerDMDeath(targ, attacker, "nailgun");
          return;
        }

        if (rnum == IT_SUPER_NAILGUN)
        {
          bprint("$qc_death_sng", targ.netname, attacker.netname);
          LogPlayerDMDeath(targ, attacker, "supernailgun");
          return;
        }

        if (rnum == IT_GRENADE_LAUNCHER)
        {
          LogPlayerDMDeath(targ, attacker, "grenade");
          if (targ.health < -40)
          {
            bprint("$qc_death_gl1", targ.netname, attacker.netname);
            return;
          }
          else
          {
            bprint("$qc_death_gl2", targ.netname, attacker.netname);
            return;
          }
        }

        if (rnum == IT_ROCKET_LAUNCHER)
        {
          LogPlayerDMDeath(targ, attacker, "rocket");
          if (attacker.super_damage_finished > 0 && targ.health < -40)
          {
            rnum = random();

            if (rnum < 0.3)
            {
              bprint("$qc_death_rl_quad1", targ.netname, attacker.netname);
              return;
            }
            else if (rnum < 0.6)
            {
              bprint("$qc_death_rl_quad2", targ.netname, attacker.netname);
              return;
            }
            else
            {
              bprint("$qc_death_rl1", targ.netname, attacker.netname);
              return;
            }
          }
          else
          {
            if (targ.health < -40)
            {
              bprint("$qc_death_rl2", targ.netname, attacker.netname);
              return;
            }
            else
            {
              bprint("$qc_death_rl3", targ.netname, attacker.netname);
              return;
            }
          }
        }

        if (rnum == IT_LIGHTNING)
        {
          LogPlayerDMDeath(targ, attacker, "lightning");
          if (attacker.waterlevel > 1)
          {
            bprint("$qc_death_lg1", targ.netname, attacker.netname);
            if (attacker.invincible_finished)
            {
              msg_entity = attacker;
              WriteByte (MSG_ONE, SVC_ACHIEVEMENT);
              WriteString(MSG_ONE, "ACH_SURVIVE_DISCHARGE");
            }
          }
          else
            bprint("$qc_death_lg2", targ.netname, attacker.netname);
          
          return;
        }
      }
      return;
    }
    else
    {
      targ.frags = targ.frags - 1;    // killed self
      rnum = targ.watertype;

      if (rnum == -3)
      {
        LogPlayerDMDeath(targ, attacker, "drowned");
        if (random() < 0.5)
          bprint("$qc_death_drown1", targ.netname);
        else
          bprint("$qc_death_drown2", targ.netname);

        return;
      }
      else if (rnum == -4)
      {
        LogPlayerDMDeath(targ, attacker, "slimed");
        if (random() < 0.5)
          bprint("$qc_death_slime1", targ.netname);
        else
          bprint("$qc_death_slime2", targ.netname);

        return;
      }
      else if (rnum == -5)
      {
        LogPlayerDMDeath(targ, attacker, "melted");
        if (targ.health < -15)
        {
          bprint("$qc_death_lava1", targ.netname);
          return;
        }

        if (random() < 0.5)
          bprint("$qc_death_lava2", targ.netname);
        else
          bprint("$qc_death_lava3", targ.netname);

        return;
      }

      if (attacker.solid == SOLID_BSP && attacker != world)
      { 
        bprint("$qc_death_squish", targ.netname);
        LogPlayerDMDeath(targ, attacker, "squished");
        return;
      }

      if (targ.deathtype == "falling")
      {
        targ.deathtype = string_null;
        bprint("$qc_death_fall", targ.netname);
        LogPlayerDMDeath(targ, attacker, "falling");
        return;
      }

      bprint("$qc_death_died", targ.netname);
      LogPlayerDMDeath(targ, attacker, "died");
    }
  }
};
