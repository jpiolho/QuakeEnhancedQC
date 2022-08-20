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

/************\
* BreakChain *
\************/

void (entity Head) BreakChain =
{
        local entity link;

        link = Head.goalentity;
        while (link != world)
        {
                Head = link.goalentity;
                remove (link);
                link = Head;
        }
};

/*********\
* LinkPos *
\*********/

void () LinkPos =
{
        makevectors (self.enemy.angles);
        setorigin (self, self.owner.origin + ( ( ( self.enemy.origin + 
                (v_up * 16 * (!self.enemy.button2)) + (v_forward * 16) ) - self.owner.origin ) *
                ( self.weapon ) ) );
        self.nextthink = time + 0.1;
};

/**************\
* GrappleTrail *
\**************/

void (entity head, entity tail) GrappleTrail =
{
  // offset the hook beam by a bit to line up with the notch on the model
  local vector start = head.origin;
  makevectors(head.angles);
  local vector offset = v_forward * -7;
  offset.z *= -1; // z axis from makevectors is inverted
  start += offset;
  // draw_sphere(start, 1, 42, 0.1, 1);

  // draw a line to the hook
  WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
  WriteByte (MSG_BROADCAST, TE_BEAM);
  WriteEntity (MSG_BROADCAST, head);
  WriteCoord (MSG_BROADCAST, start_x);
  WriteCoord (MSG_BROADCAST, start_y);
  WriteCoord (MSG_BROADCAST, start_z);
  WriteCoord (MSG_BROADCAST, tail.origin_x);
  WriteCoord (MSG_BROADCAST, tail.origin_y);
  WriteCoord (MSG_BROADCAST, tail.origin_z + 16);
};

/************\
* HookVanish *
\************/

void () HookVanish =
{
        self.owner.hook_out = FALSE;
        self.owner.hook_pulling = FALSE;
/*
        if (self.enemy.classname == "player")
                self.enemy.attack_finished = time + 0.1;
*/
      // sound(self.owner, CHAN_WEAPON, "weapons/bounce2.wav", 1, ATTN_NORM);
        BreakChain (self);
        remove (self);
};

void() UnHookPlayer =
{
  local entity oself;

  if (self.hook_out) {
    oself = self;
    self = self.goalentity;
    HookVanish();
    self = oself;
  }
};

/**********\
* HookPull *
\**********/

void () HookPull =
{
        local vector vel, spray;
        local float v, dorg;

  self.owner.hook_pulling = TRUE;

  if ((!self.owner.button0 && (self.owner.weapon == IT_HOOK)) ||
    (self.owner.teleport_time > time ) || self.owner.deadflag ) {
    HookVanish();
    return;
  } else {
     if (self.enemy.takedamage) {
      // don't hurt teammates
      if (self.enemy.classname != "player" || !teamplay ||
        self.enemy.lastteam != self.owner.lastteam) {

        // 4.1, if we can't see our enemy, unlock
        if (!CanDamage(self.enemy, self.owner)) {
          HookVanish();
          return;
        }

        sound (self, CHAN_WEAPON, "blob/land1.wav", 1, ATTN_NORM);
        T_Damage (self.enemy, self, self.owner, 1);
        makevectors (self.v_angle);
        spray_x = 100 * crandom();
        spray_y = 100 * crandom();
        spray_z = 100 * crandom() + 50;
        SpawnBlood (self.origin, spray, 20);
      }
      if (self.enemy.solid == SOLID_SLIDEBOX) {
          self.velocity = '0 0 0';
          setorigin (self, self.enemy.origin +
              self.enemy.mins +
              (self.enemy.size * 0.5));
      } else {
          self.velocity = self.enemy.velocity;
      }
    } else {
        self.velocity = self.enemy.velocity;
    }
    if (self.enemy.solid == SOLID_NOT) {
        HookVanish();
        return;
    }
    makevectors (self.owner.angles);
    vel = self.origin - ( self.owner.origin + (v_up * 16 *
        (!self.owner.button2)) + (v_forward * 16));
    v = vlen (vel);
    if (v <= 100)
        vel = normalize(vel) * v * 10;  
    if ( v > 100 )
        vel = normalize(vel) * 1000;  

    // custom assets are always enabled
    dorg = vlen(self.owner.origin - self.dest);
    if (dorg > 10 && self.style == 3) {
      // sound(self.owner, CHAN_WEAPON, "weapons/chain2.wav", 1, ATTN_NORM);
      self.style = 2;
    }
    if (dorg < 10 && self.style == 2) {
      //  sound(self.owner, CHAN_WEAPON, "weapons/chain3.wav", 1, ATTN_NORM);
      self.style = 3;
    }

    self.owner.velocity = vel;
    self.dest = self.owner.origin;
    self.nextthink = time + 0.1;
  }
};

/**************\
* T_ChainTouch *
\**************/

void() T_ChainTouch =
{
  if (other == self.owner)
      return;         // don't attach to owner

  if (pointcontents(self.origin) == CONTENT_SKY) {
                HookVanish();
                return;
  }

  if (other.classname == "player" && teamplay &&
    other.team == self.owner.lastteam)
    return; // just pass through teammates

  if (other.takedamage) {
    // don't damage teammates
    if (other.classname == "player")
      other.axhitme = 1; // make axe noise
    else
      sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
    T_Damage (other, self, self.owner, 10 );
    SpawnBlood (self.origin, self.velocity, 10);
  } else {
    sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
    self.avelocity = '0 0 0';
  }
                
  if (!self.owner.button0) {
      HookVanish();
      return;
  } else {
      if (other.solid == SOLID_SLIDEBOX) {
          setorigin (self, other.origin + other.mins +
              (other.size * 0.5));
          self.velocity = '0 0 0';
      } else {
          self.velocity = other.velocity;
      }
      self.weapon = other.nextthink - time;
      // if (teamplay & TEAM_CAPTURE_CUSTOM)
      //  sound (self.owner, CHAN_WEAPON, "weapons/chain2.wav", 1, ATTN_NORM);

      self.style = 2;
      self.enemy = other;
      self.nextthink = time + 0.1;
      self.think = HookPull;
      self.touch = SUB_Null;
  }
};

void() T_ChainThink = 
{
  if (time >= self.hook_fire_time + 5) {
    HookVanish();
  }

  if (!self.owner.button0 && self.owner.weapon == IT_HOOK) {
    HookVanish();
    return;
  }

  self.nextthink = time + 0.1;
}

/*************\
* W_FireChain *
\*************/

void() W_FireChain =
{
        local entity hook;

        self.hook_out = TRUE;
        hook = spawn ();
        hook.owner = self;
    self.goalentity = hook;
        hook.movetype = MOVETYPE_FLY;
        hook.solid = SOLID_BBOX;
    
// set hook speed 

        makevectors (self.v_angle);
        hook.velocity = aim(self, 1000);
        hook.velocity = hook.velocity * 800;
        hook.angles = vectoangles(hook.velocity);
        hook.avelocity = '0 0 -500';
  
        hook.touch = T_ChainTouch;
  
// set hook sound
        hook.hook_fire_time = time;
        hook.nextthink = time + 0.1;
        hook.think = T_ChainThink;

        setmodel (hook, "progs/star.mdl");
        setsize (hook, '0 0 0', '0 0 0');     
        setorigin (hook, self.origin + (v_forward*16) + '0 0 16' );

        sound (self, CHAN_WEAPON, "weapons/chain1.wav", 1, ATTN_NORM);  
};

