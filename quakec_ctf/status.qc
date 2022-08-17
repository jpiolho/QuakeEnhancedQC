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

.float laststattime;    // time of last status update
.float statstate;     // is the status bar on?

float PLAYERSTATTIME = 1.75;

void() MOTD =
{
  SendCTFScoresUpdate(self);

  if (gamestart) {
    centerprint(self, "$qc_choose_exit");
    return;
  }

  if (self.team == TEAM_COLOR1)
    centerprint(self, "$qc_ctf_red"); //red
  else
    centerprint(self, "$qc_ctf_blue"); //blue

  return;
};

void() MOTD_ChooseTeam =
{
  SendCTFScoresUpdate(self);
  if (PromptSupported()) {
    prompt(self, "$qc_ctf_intro", 4);
    promptchoice(self, "$qc_ctf_intro_auto", 103);
    promptchoice(self, "$qc_ctf_intro_red", 101);
    promptchoice(self, "$qc_ctf_intro_blue", 102);
    promptchoice(self, "$qc_ctf_intro_observer", 104);
  } else {
    centerprint(self, "Welcome!\nRunning ThreeWave CTF 5.0\n\nCapture the Flag!\n\nPress 1 for RED team\nPress 2 for BLUE team\nOr press JUMP for automatic team\n");
  }
};

void() TeamEndScore = 
{
  local string s;

  if (gamestart)
    return;

  if (teamscr1 > teamscr2) {
    s = ftos(teamscr1);
    bprint("$qc_ks_red_won", s);
    s = ftos(teamscr2);
    bprint("$qc_ks_blue_lost", s);
  } else if (teamscr1 < teamscr2) {
    s = ftos(teamscr2);
    bprint("$qc_ks_blue_won", s);
    s = ftos(teamscr1);
    bprint("$qc_ks_red_lost", s);
  } else {
    s = ftos(teamscr1);
    bprint("$qc_ks_match_tied", s);
  }
};

void(entity e) SendCTFScoresUpdate =
{
  local float flagstatus = 0;
  local entity flag;

  flag = find(world, classname, "item_flag_team1");
  if (flag.cnt == FLAG_AT_BASE)
    flagstatus |= 1;
  else if (flag.cnt == FLAG_CARRIED)
    flagstatus |= 2;
  else if (flag.cnt == FLAG_DROPPED)
    flagstatus |= 4;

  flag = find(world, classname, "item_flag_team2");
  if (flag.cnt == FLAG_AT_BASE)
    flagstatus |= 8;
  else if (flag.cnt == FLAG_CARRIED)
    flagstatus |= 16;
  else if (flag.cnt == FLAG_DROPPED)
    flagstatus |= 32;

  stuffcmd(e, "ctfscores ");
  stuffcmd(e, ftos(teamscr1));
  stuffcmd(e, " ");
  stuffcmd(e, ftos(teamscr2));
  stuffcmd(e, " ");
  stuffcmd(e, ftos(flagstatus));
  stuffcmd(e, "\n");
};

void() SendCTFScoresUpdateAll =
{
  local entity e = find(world, classname, "player");
  while(e)
  {
    SendCTFScoresUpdate(e);
    e = find(e, classname, "player");
  }
}