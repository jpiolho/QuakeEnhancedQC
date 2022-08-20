
const float MISC_MODEL_ANIMATED = 1;
const float MISC_MODEL_ANIMATED_ONCE = 2;
const float MISC_MODEL_ANIMATED_START_OFF = 4;

///////////////////////////////
// Behaviour for a looping animation
///////////////////////////////

void misc_model_think_loop()
{
    self.frame += 1;
    if(self.frame == self.cnt)
    {
        self.frame = self.count; // Back to start
    }
    self.nextthink = time + 0.1;
}

void misc_model_use_loop()
{
    if(self.spawnflags & MISC_MODEL_ANIMATED_START_OFF)
    {
        self.spawnflags (-) MISC_MODEL_ANIMATED_START_OFF;
        self.think = misc_model_think_loop;
        misc_model_think_loop();
    }
    else
    {
        self.spawnflags (+) MISC_MODEL_ANIMATED_START_OFF;
        self.think = SUB_Null;
        self.nextthink = -1;
    }
    
}

///////////////////////////////
// Behaviour for a single animation
///////////////////////////////

void misc_model_think_once()
{
    self.frame += 1;
    if(self.frame < self.cnt)
    {
        self.nextthink = time + 0.1;
    }
}

void misc_model_use_once()
{
    self.frame = self.count;
    self.think = misc_model_think_once;
    self.nextthink = time + 0.1;
}

///////////////////////////////

void misc_model()
{
    if(self.model == "") { objerror("misc_model with no model specified"); }
    precache_model(self.model);
    setmodel(self, self.model);
    setorigin(self, self.origin);
    self.solid = SOLID_NOT;

    if(self.spawnflags == 0)
    {
        makestatic(self);
        return;
    }

    if(self.cnt < self.frame) { objerror("misc_model with invalid frame range (cnt < frame)"); }
    if(self.targetname == "") { objerror("misc_model with no targetname"); }
    self.count = self.frame;
    
    if(self.spawnflags & MISC_MODEL_ANIMATED_ONCE)
    {
        self.use = misc_model_use_once;
    }
    else if(self.spawnflags & (MISC_MODEL_ANIMATED | MISC_MODEL_ANIMATED_START_OFF))
    {
        self.use = misc_model_use_loop;
        // Stupid way to do it but just flip the bit flag and pretend we just used it.
        self.spawnflags ^= MISC_MODEL_ANIMATED_START_OFF;
        misc_model_use_loop();
    }

}

















