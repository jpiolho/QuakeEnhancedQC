#define ShowModName 0
#define ModName "Unnamed"


#define FirstDefineMap(_bspname,_maptitle) if(mapname == ##_bspname && title == ##_maptitle) { return ##_maptitle" ("ModName")"; }
#define DefineMap(_bspname,_maptitle) else FirstDefineMap(_bspname,_maptitle)
#define OverrideDefineMap(_bspname,_maptitle) else if(mapname == ##_bspname) { return ##_maptitle" ("ModName")"; }

string(string title) GetMapName =
{
    #if ShowModName == 1

    // Id1 maps
	FirstDefineMap("base32b","Base 32")
    DefineMap("death32c","Death 32")
    DefineMap("dm1","Place of Two Deaths")
    DefineMap("dm2","Claustrophobopolis")
    DefineMap("dm3","The Abandoned Base")
    DefineMap("dm4","The Bad Place")
    DefineMap("dm5","The Cistern")
    DefineMap("dm6","The Dark Zone")
    DefineMap("dm7","The Edge")
    DefineMap("dm8","Acrophobia")
    DefineMap("e1m1","The Slipgate Complex")
    DefineMap("e1m2","Castle of the Damned")
    DefineMap("e1m3","The Necropolis")
    DefineMap("e1m4","The Grisly Grotto")
    DefineMap("e1m5","Gloom Keep")
    DefineMap("e1m6","The Door To Chthon")
    DefineMap("e1m7","The House of Chthon")
    DefineMap("e1m8","Ziggurat Vertigo")
    DefineMap("e2m1","The Installation")
    DefineMap("e2m2","The Ogre Citadel")
    DefineMap("e2m3","The Crypt of Decay")
    DefineMap("e2m4","The Ebon Fortress")
    DefineMap("e2m5","The Wizard's Manse")
    DefineMap("e2m6","The Dismal Oubliette")
    DefineMap("e2m7","The Underearth")
    DefineMap("e3m1","Termination Central")
    DefineMap("e3m2","The Vaults of Zin")
    DefineMap("e3m3","The Tomb of Terror")
    DefineMap("e3m4","Satan's Dark Delight")
    DefineMap("e3m5","The Wind Tunnels")
    DefineMap("e3m6","Chambers of Torment")
    DefineMap("e3m7","The Haunted Halls")
    DefineMap("e4m1","The Sewage System")
    DefineMap("e4m2","The Tower of Despair")
    DefineMap("e4m3","The Elder God Shrine")
    DefineMap("e4m4","The Palace of Hate")
    DefineMap("e4m5","Hell's Atrium")
    DefineMap("e4m6","The Pain Maze")
    DefineMap("e4m7","Azure Agony")
    DefineMap("e4m8","The Nameless City")
    DefineMap("end","Shub-Niggurath's Pit")
    DefineMap("start","Introduction")

	OverrideDefineMap("test/mals_combatbox","Mal's Combatbox")
	OverrideDefineMap("test/test_shadow","Shadow's Arena")
	OverrideDefineMap("test/test_aiming","Box Arena")
	OverrideDefineMap("test/test_obstacles","Obstacle Course")

    #endif

	// Default
	return title;

}