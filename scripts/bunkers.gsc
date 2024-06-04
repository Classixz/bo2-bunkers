#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init() 
{
    level thread onplayerconnect();

    header = level createServerFontString("default", 1);
    header setPoint("BOTTOMLEFT", "BOTTOMLEFT", 0, -225);
    header.glowalpha = 1;
    header.glowcolor = (0,0,1);
    header.sort = 1001;
    header.foreground = false;
    header setText("^5ZAMBunkermaker for BOII v1.0");

    if(!isDefined(level.bunkerList)) {
        level.bunkerList = [];
        level.blockEnt = [];
    }

    setdvar("sv_cheats", 1);
    setdvar("gametype_setting", "timelimit 60");
}

onplayerconnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread onplayerspawned();
    }
}

onplayerspawned()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("spawned_player");
        
        if(self isHost()) {
            self iPrintLn("^5Message ^7>^7 Press ^5[{+smoke}] ^7to save the bunkers inside main/games_mp.log");
        }

        self.createdBlocks = [];
        self.createdMiniguns = [];
        
        self.spacing = "Spread Out";
        self.spawning = "Under";
        self.position = "0";
        self.blockAngles = (0, 0, 0);
        self.allowBlock = true;
        
        self thread dumpList();

        self thread spawnCP();
        self thread showCoords();

        self createHUD();
    }
}

showCoords() {
	self endon("death");
	self endon("disconnect");
	for(;;) {
		self IPrintLn(self.origin + " " + self getPlayerAngles());
		wait 1;
	}
}

createHUD() {
    self endon("disconnect");

    self.space = self createFontString("default", 1.1);
    self.space setPoint("TOPRIGHT", "TOPRIGHT", -5, 80);
    self.space setText("^5[{+actionslot 1}] ^7- ^1Spacing: ^7" + self.spacing);
    self.spawn = self createFontString("default", 1.1);
    self.spawn setPoint("TOPRIGHT", "TOPRIGHT", -5, 100);
    self.spawn setText("^5[{+gostand}] ^7and ^5[{+melee}] ^7- ^2Spawn Area: ^7" + self.spawning);
    self.pos = self createFontString("default", 1.1);
    self.pos setPoint("TOPRIGHT", "TOPRIGHT", -5, 120);
    self.pos setText("^5[{+actionslot 3}] ^7- ^5Angles: ^7" + self.position);
    blockSpawn = self createFontString("default", 1.1);
    blockSpawn setPoint("TOPRIGHT", "TOPRIGHT", -5, 140);
    blockSpawn setText("^5[{+activate}] ^7- Spawn Block");
    delBlock = self createFontString("default", 1.1);
    delBlock setPoint("TOPRIGHT", "TOPRIGHT", -5, 160);
    delBlock setText("^5[{+actionslot 2}] ^7- Delete Last Block");   
    delBlock = self createFontString("default", 1.1);
    delBlock setPoint("TOPRIGHT", "TOPRIGHT", -5, 180);
    delBlock setText("^5[{+actionslot 4}] ^7- Save bunkers");

    count = 0;
        
    self endon("disconnect");
    while(1) {
        if(self jumpButtonPressed() && self meleeButtonPressed()) {
                if(self.spawning == "Under") {
                    self.spawning = "Crosshair";
                } else {
                    self.spawning = "Under";
                }

                self.spawn setText("^3[{+gostand}] ^7and ^3[{+melee}] ^7- ^2Spawn Area: ^7" + self.spawning);
        }
        if(count >= 300) {
            if(self isHost()) {
                    self iPrintLn("^2Message:^7 Press ^3[{+actionslot 4}] ^7to save the bunkers inside main/games_mp.log");
            }
            count = 0;
        }
        wait 0.1;
        count++;
    }

}

dumpList() {
    self endon("disconnect");
    while(1) {
        if(self ActionSlotFourButtonPressed()) {        
            self IPrintLn("saving");
            self thread logFile(level.bunkerList, "level.bunkerList", "createBlock", 1);
            // self playSoundToPlayer("mpl_turret_alert", self);
            self iPrintLn("^3Bunker list saved! ^7Open your games_mp.log with BunkerListExtractor!");
        }

        if(self ActionSlotTwoButtonPressed()) {
            if(self.createdBlocks.size <= 0) {
                self iPrintLnBold("No blocks to delete!");
            } else {
                size = self.createdBlocks.size - 1;
                level.blockEnt[self.createdBlocks[size]] delete();
                level.blockEnt[self.createdBlocks[size]] = undefined;
                level.bunkerList[self.createdBlocks[size]].location = undefined;
                level.bunkerList[self.createdBlocks[size]].angle = undefined;
                level.bunkerList[self.createdBlocks[size]] = undefined;
                self.createdBlocks[size] = undefined;
            }
        }

        if(self ActionSlotThreeButtonPressed()) {
            text = self getNext(self.position);
        }

        if(self ActionSlotOneButtonPressed()) {
            if(self.spacing == "Close Together") {
                self.spacing = "Spread Out";
            } else {
                self.spacing = "Close Together";
            }

            self.space setText("^3[{+actionslot 1}] ^7- ^1Spacing: ^7" + self.spacing);
        }
        wait 0.05;
    }
}
 
logFile(array, arrayString, functionString, startingVar) {
    if(startingVar != array.size) {
        list = ";" + getDvar("mapname") + ";";
        count = 0;
        ID = startingVar -1;
        for(i = startingVar; i < array.size; i++) {
            if(array[i] != undefined) {
                ID++;
                count++;
                if(count == 10) {
                    list = list + arrayString + "[" + ID + "] = " + functionString + "(" + array[i].location + ", " + array[i].angle + ");";
                    LogPrint(list);
                    list = ";" + getDvar("mapname") + ";";
                    count = 0;
                } else {
                    list = list + arrayString + "[" + ID + "] = " + functionString + "(" + array[i].location + ", " + array[i].angle + ");";
                }
            }
        }
        if(count != startingVar) {
            LogPrint(list);
        }
    } else {
        self iPrintLnBold("No Changes Were Detected!");
    }
}

getNext(pos) {
    switch(pos) {
        case "0":
            pos = "10";
            self.blockAngles = (0, 0, 0);
            break;
        case "10":
            pos = "20";
            self.blockAngles = (0, 10, 0);
            break;
        case "20":
            pos = "30";
            self.blockAngles = (0, 20, 0);
            break;
        case "30":
            pos = "40";
            self.blockAngles = (0, 30, 0);
            break;
        case "40":
            pos = "50";
            self.blockAngles = (0, 40, 0);
            break;
        case "50":
            pos = "60";
            self.blockAngles = (0, 50, 0);
            break;
        case "60":
            pos = "70";
            self.blockAngles = (0, 60, 0);
            break;
        case "70":
            pos = "80";
            self.blockAngles = (0, 70, 0);
            break;
        case "80":
            pos = "90";
            self.blockAngles = (0, 80, 0);
            break;
        case "90":
            pos = "100";
            self.blockAngles = (0, 90, 0);
            break;
        case "100":
            pos = "110";
            self.blockAngles = (0, 100, 0);
            break;
        case "110":
            pos = "120";
            self.blockAngles = (0, 110, 0);
            break;
        case "120":
            pos = "130";
            self.blockAngles = (0, 120, 0);
            break;
        case "130":
            pos = "140";
            self.blockAngles = (0, 130, 0);
            break;
        case "140":
            pos = "150";
            self.blockAngles = (0, 140, 0);
            break;
        case "150":
            pos = "160";
            self.blockAngles = (0, 150, 0);
            break;
        case "160":
            pos = "170";
            self.blockAngles = (0, 160, 0);
            break;
        case "170":
            pos = "0";
            self.blockAngles = (0, 170, 0);
            break;    
        default:
            break;
    }
    self.position = pos;
    self.pos setText("^3[{+actionslot 3}] ^7- ^5Angles: ^7" + self.position);
}

spawnCP() {
    self.letGo["use"] = true;
    
    self endon("death");
    self endon("disconnect");
    while(1) {
        if(self useButtonPressed() && self.letGo["use"] && self.allowBlock) {
            self doNotPressed("use");
            angle = self.blockAngles;
            if(self.spacing == "Spread Out")
                origin = self.origin + (0, 0, 17);
            else
                origin = self.origin;
            if(self.spawning == "Crosshair")
                origin = self getAim(); 
            if(distance(origin, self.origin) > 1000) {
                self iPrintLnBold("Too far away!");
            } else {
                size = level.bunkerList.size;
                self.createdBlocks[self.createdBlocks.size] = size;
                level.bunkerList[size] = createBlock(origin, angle);
                self thread createJumpArea(level.bunkerList[size].location, level.bunkerList[size].angle);
            }
        }
        wait 0.1;
    }
}

createBlock(origin, angle) {
    block = spawnstruct();
    block.location = origin;
    block.angle = angle;
    return block;
}
 
 
getAim() {
    forward = self getTagOrigin("tag_eye");
    end = self vector_Scal(anglestoforward(self getPlayerAngles()),1000000);
    Crosshair = BulletTrace( forward, end, 0, self )[ "position" ];
    return Crosshair;
}
 
vector_scal(vec, scale) {
    vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
    return vec;
}


doNotPressed(button) {
    switch(button) {
        case "use":
            if(self useButtonPressed()) {
                self.letGo[button] = false;
                while(1) {
                    if(!self useButtonPressed()) {
                        self.letGo[button] = true;
                        break;
                    }
                    wait 0.1;
                }
            }
        break;
        case "frag":
            if(self fragButtonPressed()) {
                self.letGo[button] = false;
                while(1) {
                    if(!self fragButtonPressed()) {
                        self.letGo[button] = true;
                        break;
                    }
                    wait 0.1;
                }
            }
        break;
        case "secoff":
            if(self secondaryOffhandButtonPressed()) {
                self.letGo[button] = false;
                while(1) {
                    if(!self secondaryOffhandButtonPressed()) {
                        self.letGo[button] = true;
                        break;
                    }
                    wait 0.1;
                }
            }
        break;
        default:
        break;
    }
}


createJumpArea(pos, rotation) {
	jumpArea = spawn("script_model", pos);
	jumpArea setModel("t6_wpn_supply_drop_ally");
	jumpArea.angles = rotation;
	// if(level.failCODJumper)
	// 	jumpArea thread jumpAreaThink(50);
	level.blockEnt[level.blockEnt.size] = jumpArea;
}


jumpAreaThink(radius) {
	self.disableFor = "";
	self endon("death");
	self endon("disconnect");
	while(1) {
		if(isDefined(level.players)) {
			for(i = 0; i < level.players.size; i++) {
				if(!isDefined(level.players[i].highestPoint) && isAlive(level.players[i]) && !level.players[i] isOnGround()) {
					level.players[i].highestPoint = level.players[i].origin[2];
				}
				
				if(!level.players[i] isOnGround()) {
					level.players[i].highestPoint = level.players[i].origin[2];
					while(!level.players[i] isOnGround())
					{
						if ( level.players[i].origin[2] > level.players[i].highestPoint )
							level.players[i].highestPoint = level.players[i].origin[2];
						wait .05;
					}
					
					falldist = level.players[i].highestPoint - level.players[i].origin[2];
					
					if(distance(self.origin, level.players[i].origin) <= radius + 200 && falldist >= 90 && level.players[i].name != self.disableFor)
					{
						invisObj = spawn("script_model", level.players[i].origin + (0, 0, 45));
						
						angles = level.players[i] getPlayerAngles();
						
						flipLaunch = false;
						if(angles < -45)
							flipLaunch = true;
						
						if(!flipLaunch)
							angles[1] = angles[1] - 90;
						else
							angles[1] = angles[1] + 90;
						
						direction = anglesToForward((0, angles[1], 0));
						finalDir = level.players[i] vector_scal(direction, 1000);
						
						forward = level.players[i] getTagOrigin("tag_eye");
						location = BulletTrace( forward, finalDir, 0, level.players[i])[ "position" ];
						invisObj PhysicsLaunch(invisObj.origin, (0, 0, 1));
						
						height = distance(self.origin, location) / 2;
						
						if(distance(self.origin, location) > 600)
							height = int(distance(self.origin, location) / 3);
						
						if(!flipLaunch) {
							if(angles[1] > 45 && angles[1] < 135)
								invisObj MoveGravity((location[1] - self.origin[1], location[0] + self.origin[0], height), 1.5);
							else
								invisObj MoveGravity((location[1] + self.origin[1], location[0] + self.origin[0], height), 1.5);
						} else {
							if(angles[1] > 45 && angles[1] < 110)
								invisObj MoveGravity((location[0] - self.origin[0], location[1] + self.origin[1], height), 1.5);
							else
								invisObj MoveGravity((location[0] - self.origin[0], location[1] - self.origin[1], height), 1.5);
						}
						invisObj thread doFlyingTogether(level.players[i]);
						invisObj thread doEnd();
						self thread doubleJumpFix(level.players[i].name);
					}
				}
			}
		}
		wait 0.05;
	}
}

doubleJumpFix(name) {
	self.disableFor = name;
	wait 2;
	if(self.disableFor == name) {
		self.disableFor = "";
	}
}

doEnd()
{
	wait 1.5;
	self.end = true;
}

doFlyingTogether(player) {
	self.end = false;
	while(1) {
		if(isAlive(player) && !self.end && self.origin[2] > (player.groundLevel - 3)) {
			player setOrigin(self.origin);
			wait 0.01;
		} else {
			break;
		}
	}
}