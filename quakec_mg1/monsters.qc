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

/* ALL MONSTERS SHOULD BE 1 0 0 IN COLOR */

// name =[framenum,	nexttime, nextthink] {code}
// expands to:
// name ()
// {
//		self.frame=framenum;
//		self.nextthink = time + nexttime;
//		self.think = nextthink
//		<code>
// };

float MONSTER_SPAWNED = 4;
float MONSTER_SPAWNED_ANGRY = 8;
float MONSTER_SPAWNED_TFOG = 16;
float MONSTER_WAITWALK = 4096;

float MONSTER_TYPE_WALK = 1;
float MONSTER_TYPE_FLY = 2;
float MONSTER_TYPE_SWIM = 3;

float MONSTER_SIZE_SMALL = 1;
float MONSTER_SIZE_LARGE = 2;


/*
================
monster_use

Using a monster makes it angry at the current activator
================
*/
void() monster_use =
{
	if (self.enemy)
		return;
	if (self.health <= 0)
		return;
	if (activator.items & IT_INVISIBILITY)
		return;
	if (activator.flags & FL_NOTARGET)
		return;
	if (activator.classname != "player")
		return;

// delay reaction so if the monster is teleported, its sound is still
// heard
	self.enemy = activator;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
};

/*
================
monster_death_use

When a mosnter dies, it fires all of its targets with the current
enemy as activator.
================
*/
void() monster_death_use =
{
	// fall to ground
	if (self.flags & FL_FLY)
		self.flags = self.flags - FL_FLY;
	if (self.flags & FL_SWIM)
		self.flags = self.flags - FL_SWIM;
	
	if (cvar("horde") && self.classname != "monster_zombie")
	{
		remote_wavecheck();
	}
	

	if (!self.target)
		return;

	activator = self.enemy;
	SUB_UseTargets ();
};

void monster_begin_walking()
{
	self.use = monster_use;
	self.pausetime = 0;
	self.th_walk();
}

//============================================================================

void() StartMonster =
{
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	
	setmodel (self, self.mdl);
	if(self.state == MONSTER_SIZE_SMALL) setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	if(self.state == MONSTER_SIZE_LARGE) setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);

	if(self.lefty == MONSTER_TYPE_WALK)
	{
		self.origin_z = self.origin_z + 1;	// raise off floor a bit
		droptofloor();
	}

	if (!walkmove(0,0))
	{
		dprint ("monster in wall at: ");
		dprint (vtos(self.origin));
		dprint (":\n");

		dprint (self.classname);
		if(self.target){
			dprint (" (target = ");
			dprint (self.target);
			dprint (" )");
		}
		if(self.targetname){
			dprint (" (targetname = ");
			dprint (self.targetname);
			dprint (" )");
		}
		dprint ("\n");
	}

	if(self.spawnflags & MONSTER_SPAWNED)
	{
		spawn_tdeath (self.origin, self);
		if(self.spawnflags & MONSTER_SPAWNED_TFOG)
		{
			spawn_tfog(self.origin);
		}
	}
	
	
	self.takedamage = DAMAGE_AIM;
	
	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed)
	self.yaw_speed = 20;
	self.view_ofs = '0 0 25';
	self.use = monster_use;
	self.team = TEAM_MONSTERS;
	
	self.flags = self.flags | FL_MONSTER;
	if(self.lefty == MONSTER_TYPE_FLY) self.flags = self.flags | FL_FLY;
	if(self.lefty == MONSTER_TYPE_SWIM) self.flags = self.flags | FL_SWIM;
	
	if (self.target)
	{
		if(self.spawnflags & MONSTER_ATTACK_FRIEND)
		{
			entity f = SUB_RandomTarget(self, CanTakedamage);
			if(f)
			{
				self.enemy = f;
				FoundTarget ();
				return;
			}
		}
	
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			dprint ("Monster can't find target at ");
			dprint (vtos(self.origin));
			dprint ("\n");
		}
		if (self.movetarget.classname == "path_corner")
		{
			if(self.spawnflags & MONSTER_WAITWALK)
			{
				self.pausetime = 99999999;
				self.th_stand ();
				self.use = monster_begin_walking;
			}
			else
			{
				self.th_walk ();
			}
		}
		else
		{
			self.pausetime = 99999999;
			self.th_stand ();
		}
	}
	else
	{
		self.pausetime = 99999999;
		self.th_stand ();
	}
	
	if(self.spawnflags & MONSTER_SPAWNED)
	{
		// Yoder, Sept29, horde fix so that preplaced monsters are counted on spawn_tdeath
		if (horde_ent)
			total_monsters = total_monsters + 1;
		// end Yoder chunk, back to normal
		
		if(self.spawnflags & MONSTER_SPAWNED_ANGRY)
		{	
			monster_use(); //Make monster angry!
		}
		
		
	}
	else
	{
		// spread think times so they don't all happen at same time
		self.nextthink = self.nextthink + random()*0.5;
	}
};

void InitMonster(string model, float type, float size)
{
	if (deathmatch)
	{
		remove(self);
		return;
	}

	INHIBIT_COOP
	if (RemovedOutsideCoop()) return;
	
	self.flags |= FL_FUTUREMONSTER;

	self.mdl = model;
	self.lefty = type;
	self.state = size;
	
	// CG: This was removed because it caused the entity alpha to differ from the baseline alpha somehow, causing it to be transmitted over the network every frame for every monster.
	// self.alpha = 1; 
	
	// Yoder, Sept29, fix for preplaced monsters in horde_ent
	// in horde, mosnters shouldn't increase total count until spawned
	if (cvar("horde"))
	{
		if (!(self.spawnflags & MONSTER_SPAWNED))
			total_monsters = total_monsters + 1;
	}
	else // normal behavior
		total_monsters = total_monsters + 1;

	if(self.spawnflags & MONSTER_SPAWNED)
	{
		self.use = StartMonster;
		return;
	}
	// delay drop to floor to make sure all doors have been spawned
	// spread think times so they don't all happen at same time
	self.nextthink = self.nextthink + random()*0.5;
	self.think = StartMonster;

}

// Yoder Sept24 2021, Horde Merge
// Monster fade, used to fade out the model a few seconds after deathmatch
void() MonsterFade2 =
{
	if (self.alpha > 0)
	{
		self.alpha = self.alpha - 1 * frametime;
		//self.think = MonsterFade;
		self.nextthink = time; // think next frame
	}
	else
		remove(self);
}
void() MonsterFade =
{
	if (!cvar("horde"))
	{
		self.think = SUB_Null;
		return;
	}
	if (!self.alpha)
		self.alpha = 1;
	self.think = MonsterFade2;
	self.nextthink = time + 10 + random() * 5; // wait a bit before fading
};