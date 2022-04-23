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


//Electrodes

void mge2m2_electrode_target()
{
}

// Electrode buttons

float mge2m2_match_cnt(entity e) { return self.cnt == e.cnt; }

void mge2m2_electrode_button_touch()
{
    if(other.classname != "player") return;
    if(other.health <= 0) return;
    
    button_touch();
    self.touch = SUB_Null;

    entity t = SUB_FindWithPredicate(world, classname, "mge2m2_electrode_target", mge2m2_match_cnt);
    while(t)
    {
        t.think = SUB_Remove;
        t.nextthink = time + 0.1;
        t = SUB_FindWithPredicate(t, classname, "mge2m2_electrode_target", mge2m2_match_cnt);
    }
}

void mge2m2_electrode_button()
{
    func_button();
    self.touch = mge2m2_electrode_button_touch;
}

// Opening the rune "egg"

void mge2m2_rune_egg_opener_use()
{
    entity t, oself;
    oself = self;
    t = find(world, targetname, self.target);
    while(t)
    {
        if(t.classname == "func_door")
        {
            self = t;
            self.movedir = self.dest2;
            self.pos1 = self.origin;
            self.pos2 = self.pos1 + self.movedir;
            self.state = STATE_BOTTOM;
            self.speed = 500;
            self.noise1 = "doors/drclos4.wav";
            self.noise2 = "doors/doormv1.wav";
            door_go_up();
        }
        t = find(t, targetname, oself.target);
    }
    self = oself;
}

void mge2m2_rune_egg_opener()
{
    self.use = mge2m2_rune_egg_opener_use;
}

// Rune pickupability

void mge2m2_rune_pickup_fixer_use()
{
    void() tutsh;
    if(self.state) tutsh = sigil_touch;
    else
    {
        self.state = 1;
        tutsh = SUB_Null;
    }
    entity ru = find(world, classname, "item_sigil");
    while(ru)
    {
        ru.touch = tutsh;
        ru = find(ru, classname, "item_sigil");
    }
}

void mge2m2_rune_pickup_fixer()
{
    self.use = mge2m2_rune_pickup_fixer_use;
    self.think = mge2m2_rune_pickup_fixer_use;
    self.nextthink = time + 0.8;
}

// Obsolete, replace with trigger_cleanup_corpses
void mge2m2_cleanup_corpses() { dprint("WARNING: entity 'mge2m2_cleanup_corpses' spawned. Please replace with 'trigger_cleanup_corpses'.\n"); trigger_cleanup_corpses();}