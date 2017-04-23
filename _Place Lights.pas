{
    Place a light at the coordinates of each item in each cell that matches anything in _formsToChange but excluding _thingsToIgnore which compares against the full path for exclusion purposes.
    Only used on fallout 4 so far.
}
unit PlaceLights;

// I gave all globals an uncerscore at the beginning for easy identification.
const
    _outputMax = 5000; // maximum number of times function sOutput can be used
    _exceptionCountMax = 1000; // number of exceptions allowed before we crash out the script
var
    _plugin: IInterface; // the new plugin
    _fullPath, _name: String; // the FullPath and the NAME elements
    _thingsToIgnore, _formsToChange: TStringList; // List of words to use to exit, list of base form IDs to be manipulated when they occur in the world.
    _recordCount, _exceptionCount: Integer; // current count of sOutput uses and exceptions caught.

//====================================================================================================================================================
//
//====================================================================================================================================================
function Initialize: Integer;
    begin
        // this is the tally of outputs we've done via the sOutput function, used for killing out of control scripts and debugging.
        _recordCount := 0;

        // the tally of exception caught in the main loop. Used for killing out of control scripts and debugging.
        _exceptionCount := 0;

        // these strings will be compared to the full path, if they occur then the script will reject the record for processing.
        _thingsToIgnore := TStringList.Create;
        _thingsToIgnore.NameValueSeparator := ',';
        _thingsToIgnore.Duplicates := dupIgnore;
        _thingsToIgnore.Sorted := False;
        _thingsToIgnore.Add('SanctuaryHillsWorld'); // ignore prewar sanctuary
        _thingsToIgnore.Add('DiamondCityFX'); // skip whatever this place is
        _thingsToIgnore.Add('TestMadCoast'); // leave TestMadCoast alone
        _thingsToIgnore.Add('TestClaraCoast'); // leave TestClaraCoast alone
        _thingsToIgnore.Add('DLC03VRWorldspace'); // Dima's head is off limits
        _thingsToIgnore.Add('TestMadWorld'); // leave TestMadWorld alone
        
        // these form IDs are compared against the NAME of every reference in every cell. If there is a match (after exlusion) then the record is accepted for processing.
        _formsToChange := TStringList.Create;
        _formsToChange.NameValueSeparator := ',';
        _formsToChange.Duplicates := dupIgnore;
        _formsToChange.Sorted := False;
        _formsToChange.Add('00019570'); // BranchPileStumpRocks01 "Branch Pile" [SCOL:00019570]
        _formsToChange.Add('00019572'); // BranchPileStumpVines01 "Branch Pile" [SCOL:00019572]
        _formsToChange.Add('00026FEA'); // TreeScrubVines03 "Trees" [SCOL:00026FEA]
        _formsToChange.Add('0002716E'); // TreeLeanScrub01 "Trees" [SCOL:0002716E]
        _formsToChange.Add('00027785'); // TreeLeanScrub03 "Trees" [SCOL:00027785]
        _formsToChange.Add('0002C7AC'); // TreeLeanCluster01 "Trees" [SCOL:0002C7AC]
        _formsToChange.Add('0002C7AF'); // TreeClusterVines01 "Tree Cluster" [SCOL:0002C7AF]
        _formsToChange.Add('0002C7B3'); // TreeLeanDead01 "Trees" [SCOL:0002C7B3]
        _formsToChange.Add('0002C808'); // TreeLeanScrub02 "Trees" [SCOL:0002C808]
        _formsToChange.Add('00031A08'); // TreeLeanScrub04 "Trees" [SCOL:00031A08]
        _formsToChange.Add('00031A0A'); // TreeLeanScrub05 "Trees" [SCOL:00031A0A]
        _formsToChange.Add('00031A0D'); // TreeLeanScrub06 "Trees" [SCOL:00031A0D]
        _formsToChange.Add('00031A0E'); // TreeLeanScrub07 "Trees" [SCOL:00031A0E]
        _formsToChange.Add('00031A10'); // TreeScrubVines01 "Trees" [SCOL:00031A10]
        _formsToChange.Add('00031A11'); // TreeScrubVines02 "Trees" [SCOL:00031A11]
        _formsToChange.Add('00032028'); // TreeScrubVines04 "Trees" [SCOL:00032028]
        _formsToChange.Add('000321AE'); // TreeLeanScrub08 "Trees" [SCOL:000321AE]
        _formsToChange.Add('00034F55'); // BranchPileStump01 "Branch Pile" [SCOL:00034F55]
        _formsToChange.Add('00035813'); // TreeCluster04 "Tree Cluster" [SCOL:00035813]
        _formsToChange.Add('0003581A'); // TreeCluster05 "Tree Cluster" [SCOL:0003581A]
        _formsToChange.Add('0003581C'); // TreeLeanCluster02 "Trees" [SCOL:0003581C]
        _formsToChange.Add('00035871'); // TreeCluster03 "Tree Cluster" [SCOL:00035871]
        _formsToChange.Add('00035887'); // TreeCluster01 "Tree Cluster" [SCOL:00035887]
        _formsToChange.Add('0003589F'); // TreeCluster07 "Tree Cluster" [SCOL:0003589F]
        _formsToChange.Add('000358D1'); // TreeCluster02 "Tree Cluster" [SCOL:000358D1]
        _formsToChange.Add('000358D6'); // TreeCluster06 "Tree Cluster" [SCOL:000358D6]
        _formsToChange.Add('000393E9'); // BranchPile02 "Maple Branches" [SCOL:000393E9]
        _formsToChange.Add('00039709'); // TreeClusterTall01 [SCOL:00039709]
        _formsToChange.Add('0003E000'); // TreeCluster08 "Tree Cluster" [SCOL:0003E000]
        _formsToChange.Add('00046E61'); // TreeLeanDead02 "Trees" [SCOL:00046E61]
        _formsToChange.Add('00046E62'); // TreeLeanDead03 "Trees" [SCOL:00046E62]
        _formsToChange.Add('00046E63'); // TreeLeanDead04 "Trees" [SCOL:00046E63]
        _formsToChange.Add('00046E64'); // TreeClusterDead01 "Tree Cluster" [SCOL:00046E64]
        _formsToChange.Add('00046E65'); // TreeLeanDead05 "Trees" [SCOL:00046E65]
        _formsToChange.Add('00046E66'); // TreeCluster09 "Tree Cluster" [SCOL:00046E66]
        _formsToChange.Add('00046E6F'); // TreeLeanDead06 "Trees" [SCOL:00046E6F]
        _formsToChange.Add('00056270'); // ElectricalTowerVines01 [SCOL:00056270]
        _formsToChange.Add('00056271'); // ElectricalTowerVines02 [SCOL:00056271]
        _formsToChange.Add('00056274'); // ElectricalTowerVines03 [SCOL:00056274]
        _formsToChange.Add('0005E20C'); // TreeClusterDead02 "Tree Cluster" [SCOL:0005E20C]
        _formsToChange.Add('0005E20D'); // TreeClusterDead03 "Tree Cluster" [SCOL:0005E20D]
        _formsToChange.Add('0005E20E'); // TreeClusterDead04 "Tree Cluster" [SCOL:0005E20E]
        _formsToChange.Add('0006477D'); // BranchPile03 "Maple Branches" [SCOL:0006477D]
        _formsToChange.Add('0002F81A'); // REObjectDL01TrashPile [SCOL:0002F81A]
        _formsToChange.Add('00077DDE'); // ConcordTrashPile01 [SCOL:00077DDE]
        _formsToChange.Add('00077DE8'); // ConcordTrashPile02 [SCOL:00077DE8]
        _formsToChange.Add('00077DEA'); // ConcordTrashPile03 [SCOL:00077DEA]
        _formsToChange.Add('00077DEE'); // ConcordTrashPile05 [SCOL:00077DEE]
        _formsToChange.Add('00077DF0'); // ConcordTrashPile06 [SCOL:00077DF0]
        _formsToChange.Add('00077DF2'); // ConcordTrashPile07 [SCOL:00077DF2]
        _formsToChange.Add('00077DF9'); // ConcordTrashPile08 [SCOL:00077DF9]
        _formsToChange.Add('00077DFB'); // ConcordTrashPile09 [SCOL:00077DFB]
        _formsToChange.Add('00077DFF'); // ConcordTrashPile10 [SCOL:00077DFF]
        _formsToChange.Add('00077E10'); // ConcordTrashPile11 [SCOL:00077E10]
        _formsToChange.Add('00134638'); // TreeBlastedForestClusterFallen01 "Fallen Trees" [SCOL:00134638]
        _formsToChange.Add('0013463A'); // TreeBlastedForestCluster01 "Trees" [SCOL:0013463A]
        _formsToChange.Add('0013463C'); // TreeBlastedForestCluster02 "Trees" [SCOL:0013463C]
        _formsToChange.Add('0013463E'); // TreeBlastedForestCluster03 "Trees" [SCOL:0013463E]
        _formsToChange.Add('00134641'); // TreeBlastedForestCluster04 "Trees" [SCOL:00134641]
        _formsToChange.Add('00135CF7'); // TreeBlastedForestCluster05 "Trees" [SCOL:00135CF7]
        _formsToChange.Add('0014825D'); // TreeForestCluster01 [SCOL:0014825D]
        _formsToChange.Add('0014B7C1'); // TreeForestCluster02 [SCOL:0014B7C1]
        _formsToChange.Add('0014B7C3'); // TreeForestCluster03 [SCOL:0014B7C3]
        _formsToChange.Add('0014EC0A'); // TreeClusterDestroyedFallen01 [SCOL:0014EC0A]
        _formsToChange.Add('0014EC0B'); // TreeClusterDestroyedFallen02 [SCOL:0014EC0B]
        _formsToChange.Add('0014EC0C'); // TreeClusterDestroyedFallen03 [SCOL:0014EC0C]
        _formsToChange.Add('0014F6C7'); // TreeClusterGSFallen01 [SCOL:0014F6C7]
        _formsToChange.Add('0014F6C9'); // TreeClusterGSFallen02 [SCOL:0014F6C9]
        _formsToChange.Add('0014F6CA'); // TreeClusterGSFallen03 [SCOL:0014F6CA]
        _formsToChange.Add('000BBD3F'); // Tree_NF_Cluster01 [SCOL:000BBD3F]
        _formsToChange.Add('000BBD43'); // Tree_NF_Cluster02 [SCOL:000BBD43]
        _formsToChange.Add('000BBD45'); // Tree_NF_Cluster03 [SCOL:000BBD45]
        _formsToChange.Add('000BBD48'); // Tree_NF_FallenCluster01 [SCOL:000BBD48]
        _formsToChange.Add('000BBD4B'); // Tree_NF_Cluster04 [SCOL:000BBD4B]
        _formsToChange.Add('000BBD4E'); // Tree_NF_Cluster05 [SCOL:000BBD4E]
        _formsToChange.Add('000BBD50'); // Tree_NF_FallenCluster02 [SCOL:000BBD50]
        _formsToChange.Add('000BBD52'); // Tree_NF_FallenCluster03 [SCOL:000BBD52]
        _formsToChange.Add('000BBD55'); // Tree_NF_FallenCluster04 [SCOL:000BBD55]
        _formsToChange.Add('000BBD58'); // Tree_NF_Cluster06 [SCOL:000BBD58]
        _formsToChange.Add('000BBD62'); // Tree_NF_Cluster07 [SCOL:000BBD62]
        _formsToChange.Add('000BBD64'); // Tree_NF_FallenCluster05 [SCOL:000BBD64]
        _formsToChange.Add('000BD5C0'); // Tree_NF_RockGroundCluster01 [SCOL:000BD5C0]
        _formsToChange.Add('000BD5C2'); // Tree_NF_RockGroundCluster02 [SCOL:000BD5C2]
        _formsToChange.Add('000D09BA'); // CITTrashPile01 [SCOL:000D09BA]
        _formsToChange.Add('000D09BC'); // CITTrashPile02 [SCOL:000D09BC]
        _formsToChange.Add('000D09BE'); // CITTrashPile03 [SCOL:000D09BE]
        _formsToChange.Add('000D7D7C'); // CITLeafPile01 [SCOL:000D7D7C]
        _formsToChange.Add('0016B7DC'); // DN76Ship1TrashStaticCollection [SCOL:0016B7DC]
        _formsToChange.Add('0016B914'); // DN76Ship8TrashStaticCollection [SCOL:0016B914]
        _formsToChange.Add('0019B595'); // CafeTable01Debris01 [SCOL:0019B595]
        _formsToChange.Add('0019B597'); // CafeTable01Debris02 [SCOL:0019B597]
        _formsToChange.Add('0019B599'); // CafeTable01Debris03 [SCOL:0019B599]
        _formsToChange.Add('0019B59B'); // CafeTable02Debris01 [SCOL:0019B59B]
        _formsToChange.Add('0019B59D'); // CafeTable02Debris02 [SCOL:0019B59D]
        _formsToChange.Add('0019B59F'); // CafeTable03Debris01 [SCOL:0019B59F]
        _formsToChange.Add('001C38BF'); // Bldg_CornerVines01_SG [SCOL:001C38BF]
        _formsToChange.Add('001C38C1'); // BLDG_CornerVines02_SG [SCOL:001C38C1]
        _formsToChange.Add('000393CD'); // TreeBlasted02 "Tree" [STAT:000393CD]
        _formsToChange.Add('00038599'); // TreeBlasted01 "Tree" [STAT:00038599]
        _formsToChange.Add('00032464'); // TreeStump01 "Stump" [STAT:00032464]
        _formsToChange.Add('00032936'); // TreeStump02 "Stump" [STAT:00032936]
        _formsToChange.Add('00033F54'); // TreeStump03 "Stump" [STAT:00033F54]
        _formsToChange.Add('000299B3'); // TreeLog01 "Maple Log" [STAT:000299B3]
        _formsToChange.Add('0002A620'); // TreeLog02 "Maple Log" [STAT:0002A620]
        _formsToChange.Add('0002B8DB'); // TreefallenBranch01 "Branch" [STAT:0002B8DB]
        _formsToChange.Add('0001E95B'); // DebrisInteriorWoodPileBg04 [STAT:0001E95B]
        _formsToChange.Add('0001E957'); // DebrisInteriorWoodPile03Trash [STAT:0001E957]
        _formsToChange.Add('0001E953'); // DebrisInteriorWoodPile01Trash [STAT:0001E953]
        _formsToChange.Add('0001E94F'); // DebrisInteriorWoodPileSm03 [STAT:0001E94F]
        _formsToChange.Add('0001D907'); // DebrisWoodPileSm05 [STAT:0001D907]
        _formsToChange.Add('0001D8FB'); // DebrisWoodPile03Trash [STAT:0001D8FB]
        _formsToChange.Add('0001D8F7'); // DebrisWoodPile01Trash [STAT:0001D8F7]
        _formsToChange.Add('0001D8F3'); // DebrisWoodPile04Trash [STAT:0001D8F3]
        _formsToChange.Add('0001D1C7'); // DebrisPile04 [STAT:0001D1C7]
        _formsToChange.Add('0001D1AF'); // TrashDecal03 [STAT:0001D1AF]
        _formsToChange.Add('0001D191'); // DebrisPile03 [STAT:0001D191]
        _formsToChange.Add('0001D17F'); // DebrisPile01Dirt [STAT:0001D17F]
        _formsToChange.Add('0001D166'); // DebrisPile01 [STAT:0001D166]
        _formsToChange.Add('0001D181'); // DebrisPile02 [STAT:0001D181]
        _formsToChange.Add('0001D184'); // TrashDecal01 [STAT:0001D184]
        _formsToChange.Add('0001D18E'); // TrashDecal02 [STAT:0001D18E]
        _formsToChange.Add('0001D199'); // DebrisPile02Trash [STAT:0001D199]
        _formsToChange.Add('0001D1A0'); // DebrisPile01Trash [STAT:0001D1A0]
        _formsToChange.Add('0001D1A6'); // DebrisPileRoad01Trash [STAT:0001D1A6]
        _formsToChange.Add('0001D1B5'); // TrashDecal04 [STAT:0001D1B5]
        _formsToChange.Add('0001D1BA'); // DebrisPile03Trash [STAT:0001D1BA]
        _formsToChange.Add('0001D1C3'); // TrashDecal05 [STAT:0001D1C3]
        _formsToChange.Add('0001D1CF'); // DebrisPile04Trash [STAT:0001D1CF]
        _formsToChange.Add('0001D549'); // DebrisPileRoad02Trash [STAT:0001D549]
        _formsToChange.Add('0001D8F4'); // DebrisWoodPileRoad01Trash [STAT:0001D8F4]
        _formsToChange.Add('0001D8F5'); // DebrisWoodPileRoad02Trash [STAT:0001D8F5]
        _formsToChange.Add('0001D8F6'); // DebrisWoodPile01 [STAT:0001D8F6]
        _formsToChange.Add('0001D8F8'); // DebrisWoodPile02 [STAT:0001D8F8]
        _formsToChange.Add('0001D8F9'); // DebrisWoodPile02Trash [STAT:0001D8F9]
        _formsToChange.Add('0001D8FA'); // DebrisWoodPile03 [STAT:0001D8FA]
        _formsToChange.Add('0001D8FC'); // DebrisWoodPile04 [STAT:0001D8FC]
        _formsToChange.Add('0001D905'); // DebrisWoodPileSm03 [STAT:0001D905]
        _formsToChange.Add('0001D906'); // DebrisWoodPileSm04 [STAT:0001D906]
        _formsToChange.Add('0001D908'); // DebrisWoodPileSm01 [STAT:0001D908]
        _formsToChange.Add('0001D909'); // DebrisWoodPileSm02 [STAT:0001D909]
        _formsToChange.Add('0001E94D'); // DebrisInteriorWoodPileSm01 [STAT:0001E94D]
        _formsToChange.Add('0001E94E'); // DebrisInteriorWoodPileSm02 [STAT:0001E94E]
        _formsToChange.Add('0001E950'); // DebrisInteriorWoodPileSm04 [STAT:0001E950]
        _formsToChange.Add('0001E951'); // DebrisInteriorWoodPileSm05 [STAT:0001E951]
        _formsToChange.Add('0001E952'); // DebrisInteriorWoodPile01 [STAT:0001E952]
        _formsToChange.Add('0001E954'); // DebrisInteriorWoodPile02 [STAT:0001E954]
        _formsToChange.Add('0001E955'); // DebrisInteriorWoodPile02Trash [STAT:0001E955]
        _formsToChange.Add('0001E956'); // DebrisInteriorWoodPile03 [STAT:0001E956]
        _formsToChange.Add('0001E958'); // DebrisInteriorWoodPile04 [STAT:0001E958]
        _formsToChange.Add('0001E959'); // DebrisInteriorWoodPile04Trash [STAT:0001E959]
        _formsToChange.Add('0001E95A'); // DebrisInteriorWoodPileBg03 [STAT:0001E95A]
        _formsToChange.Add('0001E95C'); // DebrisInteriorWoodPileBg01 [STAT:0001E95C]
        _formsToChange.Add('0001E95D'); // DebrisInteriorWoodPileBg02 [STAT:0001E95D]
        _formsToChange.Add('0001E95F'); // DebrisInteriorWoodPileBg05 [STAT:0001E95F]
        _formsToChange.Add('00001B58'); // DecalDebris01 [STAT:00001B58]
        _formsToChange.Add('00001B56'); // DecalDebris03 [STAT:00001B56]
        _formsToChange.Add('00001B57'); // DecalDebris02 [STAT:00001B57]
        _formsToChange.Add('00039BF1'); // TreeBlasted03 "Tree" [STAT:00039BF1]
        _formsToChange.Add('0003A9F2'); // OfficePaperDebris01 [STAT:0003A9F2]
        _formsToChange.Add('00045618'); // TreeStump04 "Stump" [STAT:00045618]
        _formsToChange.Add('000457C2'); // VineHanging01 [STAT:000457C2]
        _formsToChange.Add('000457C3'); // VineHanging02 [STAT:000457C3]
        _formsToChange.Add('000457C4'); // VineHanging03 [STAT:000457C4]
        _formsToChange.Add('00047E39'); // VineDecalCorner01 [STAT:00047E39]
        _formsToChange.Add('00047E3A'); // VineDecalCorner02 [STAT:00047E3A]
        _formsToChange.Add('00047E3B'); // VineDecalLarge01 [STAT:00047E3B]
        _formsToChange.Add('00047E3C'); // VineDecalLarge02 [STAT:00047E3C]
        _formsToChange.Add('00047E3D'); // VineDecalLarge03 [STAT:00047E3D]
        _formsToChange.Add('00047E3E'); // VineDecalMed01 [STAT:00047E3E]
        _formsToChange.Add('00047E3F'); // VineDecalMed02 [STAT:00047E3F]
        _formsToChange.Add('00048BAB'); // VineDecalMed03 [STAT:00048BAB]
        _formsToChange.Add('00048BAC'); // VineDecalSmall01 [STAT:00048BAC]
        _formsToChange.Add('00048BAD'); // VineDecalSmall02 [STAT:00048BAD]
        _formsToChange.Add('00048BAE'); // VineDecalSmall03 [STAT:00048BAE]
        _formsToChange.Add('00048BAF'); // VineDecalXSmall01 [STAT:00048BAF]
        _formsToChange.Add('00048BB0'); // VineDecalXSmall02 [STAT:00048BB0]
        _formsToChange.Add('00048BB1'); // VineHanging04 [STAT:00048BB1]
        _formsToChange.Add('00048BB2'); // VineHanging05 [STAT:00048BB2]
        _formsToChange.Add('00048BB3'); // VineHanging06 [STAT:00048BB3]
        _formsToChange.Add('00048BB4'); // VineHangingLarge01 [STAT:00048BB4]
        _formsToChange.Add('00048BB5'); // VineHangingLarge02 [STAT:00048BB5]
        _formsToChange.Add('00049532'); // TreeBlasted04 "Tree" [STAT:00049532]
        _formsToChange.Add('0004A071'); // TreeMapleForest5 "Maple Tree" [STAT:0004A071]
        _formsToChange.Add('0004A072'); // TreeMapleForest6 "Maple Tree" [STAT:0004A072]
        _formsToChange.Add('0004A073'); // TreeMapleForest1 "Maple Tree" [STAT:0004A073]
        _formsToChange.Add('0004A074'); // TreeMapleForest2 "Maple Tree" [STAT:0004A074]
        _formsToChange.Add('0004A075'); // TreeMapleForest3 "Maple Tree" [STAT:0004A075]
        _formsToChange.Add('0004A076'); // TreeMapleForest4 "Maple Tree" [STAT:0004A076]
        _formsToChange.Add('0004C901'); // VineGround01 [STAT:0004C901]
        _formsToChange.Add('0004C902'); // VineGround02 [STAT:0004C902]
        _formsToChange.Add('0004D320'); // VineHanging07 [STAT:0004D320]
        _formsToChange.Add('0004D322'); // VineHanging08 [STAT:0004D322]
        _formsToChange.Add('0004D93B'); // TreeMapleblasted01 "Maple Tree" [STAT:0004D93B]
        _formsToChange.Add('000503B6'); // TreeMapleblasted02 "Maple Tree" [STAT:000503B6]
        _formsToChange.Add('000516A3'); // BranchPileBark01 "Maple Bark" [STAT:000516A3]
        _formsToChange.Add('000521BB'); // TreeMapleblasted03 "Maple Trunk" [STAT:000521BB]
        _formsToChange.Add('00052A19'); // TreeRoots01 [STAT:00052A19]
        _formsToChange.Add('00052A1E'); // TreeRoots02 [STAT:00052A1E]
        _formsToChange.Add('00052A20'); // TreeRoots03 [STAT:00052A20]
        _formsToChange.Add('000531AE'); // TreeMapleblasted04 "Maple Tree" [STAT:000531AE]
        _formsToChange.Add('000531B3'); // TreeMapleblasted05 "Maple Tree" [STAT:000531B3]
        _formsToChange.Add('000531BC'); // TreeMapleblasted06 "Maple Trunk" [STAT:000531BC]
        _formsToChange.Add('0005325A'); // BranchPileBark02 "Tree" [STAT:0005325A]
        _formsToChange.Add('0005325E'); // BranchPile01 "Maple Branches" [STAT:0005325E]
        _formsToChange.Add('00053262'); // TreefallenBranch02 "Branch" [STAT:00053262]
        _formsToChange.Add('000542F4'); // TreeRoots04 [STAT:000542F4]
        _formsToChange.Add('00055D13'); // TreeRoots05 [STAT:00055D13]
        _formsToChange.Add('0003A28B'); // TreeHero01 [STAT:0003A28B]
        _formsToChange.Add('0003E08D'); // TreeBlasted05 "Tree" [STAT:0003E08D]
        _formsToChange.Add('0003E08F'); // TreeMapleblasted07 "Maple Tree" [STAT:0003E08F]
        _formsToChange.Add('0003E0D1'); // TreeMapleForest7 "Maple Tree" [STAT:0003E0D1]
        _formsToChange.Add('000585A8'); // LeafPile01 [STAT:000585A8]
        _formsToChange.Add('000585AA'); // LeafPile02 [STAT:000585AA]
        _formsToChange.Add('000585AB'); // LeafPile03 [STAT:000585AB]
        _formsToChange.Add('00059AA1'); // VineTree01 [STAT:00059AA1]
        _formsToChange.Add('00059AAE'); // VineTree02 [STAT:00059AAE]
        _formsToChange.Add('0005A480'); // LeafPile04 [STAT:0005A480]
        _formsToChange.Add('0005C21E'); // VineGround03 [STAT:0005C21E]
        _formsToChange.Add('0005C221'); // VineHangingLarge03 [STAT:0005C221]
        _formsToChange.Add('0005C223'); // VineShrub01 [STAT:0005C223]
        _formsToChange.Add('0005C229'); // VineHanging09 [STAT:0005C229]
        _formsToChange.Add('0006C6D0'); // TreeMapleForestsmall1 "Maple Tree" [STAT:0006C6D0]
        _formsToChange.Add('0006C6D2'); // TreeMapleForestsmall2 "Maple Tree" [STAT:0006C6D2]
        _formsToChange.Add('0006C6D4'); // TreeMapleForestsmall3 "Maple Tree" [STAT:0006C6D4]
        _formsToChange.Add('0006FA34'); // TreeBlastedM01 "Stump" [STAT:0006FA34]
        _formsToChange.Add('000713E1'); // TreeBlastedM04 "Tree" [STAT:000713E1]
        _formsToChange.Add('000713E2'); // TreeBlastedM03 "Tree" [STAT:000713E2]
        _formsToChange.Add('000713E3'); // TreeBlastedM02 "Tree" [STAT:000713E3]
        _formsToChange.Add('00072DC6'); // TreeHero01_LOD [STAT:00072DC6]
        _formsToChange.Add('000787EF'); // TreeClustermMound02temp [STAT:000787EF]
        _formsToChange.Add('0007ED8B'); // DebrisPileLargeWood04 [STAT:0007ED8B]
        _formsToChange.Add('0007ED8C'); // DebrisPileLargeWood05 [STAT:0007ED8C]
        _formsToChange.Add('0007ED8D'); // DebrisPileLargeWood06 [STAT:0007ED8D]
        _formsToChange.Add('0007ED8E'); // DebrisPileLargeWood01 [STAT:0007ED8E]
        _formsToChange.Add('0007ED8F'); // DebrisPileLargeWood02 [STAT:0007ED8F]
        _formsToChange.Add('0007ED90'); // DebrisPileLargeWood03 [STAT:0007ED90]
        _formsToChange.Add('0008029B'); // DebrisPileSmallWood03 [STAT:0008029B]
        _formsToChange.Add('0008029C'); // DebrisPileSmallWood04 [STAT:0008029C]
        _formsToChange.Add('0008029D'); // DebrisPileSmallWood05 [STAT:0008029D]
        _formsToChange.Add('0008029E'); // DebrisPileSmallWood01 [STAT:0008029E]
        _formsToChange.Add('0008029F'); // DebrisPileSmallWood02 [STAT:0008029F]
        _formsToChange.Add('0008407B'); // TreeSwing_RopePile01 [STAT:0008407B]
        _formsToChange.Add('0008407F'); // TreeSwing03_NoSwing [STAT:0008407F]
        _formsToChange.Add('00084080'); // TreeSwing_Grounded01 [STAT:00084080]
        _formsToChange.Add('0008954A'); // TrashClump01 [STAT:0008954A]
        _formsToChange.Add('0008954E'); // TrashClump02 [STAT:0008954E]
        _formsToChange.Add('0008A5D7'); // TrashEdge01 [STAT:0008A5D7]
        _formsToChange.Add('0008A5E0'); // TrashEdge02 [STAT:0008A5E0]
        _formsToChange.Add('0008B5F5'); // TrashPileWall02 [STAT:0008B5F5]
        _formsToChange.Add('0008B5F6'); // TrashPileWall01 [STAT:0008B5F6]
        _formsToChange.Add('0008B5FD'); // TrashEdge03 [STAT:0008B5FD]
        _formsToChange.Add('0008B604'); // TrashPileCor01 [STAT:0008B604]
        _formsToChange.Add('0008B617'); // TrashPileWall03 [STAT:0008B617]
        _formsToChange.Add('0008B618'); // TrashEdge04 [STAT:0008B618]
        _formsToChange.Add('0008B648'); // TrashPileCorIn01 [STAT:0008B648]
        _formsToChange.Add('0008B671'); // TrashClump03 [STAT:0008B671]
        _formsToChange.Add('0008C803'); // DebrisPileSmallConc01 [STAT:0008C803]
        _formsToChange.Add('0008C804'); // DebrisPileSmallConc02 [STAT:0008C804]
        _formsToChange.Add('0008C805'); // DebrisPileSmallConc03 [STAT:0008C805]
        _formsToChange.Add('0008C806'); // DebrisPileSmallConc04 [STAT:0008C806]
        _formsToChange.Add('0008C807'); // DebrisPileSmallConc05 [STAT:0008C807]
        _formsToChange.Add('000A7206'); // TreeBlasted01Lichen [STAT:000A7206]
        _formsToChange.Add('000A7207'); // TreeBlasted01LichenFX [STAT:000A7207]
        _formsToChange.Add('000A7208'); // TreeBlasted02Lichen [STAT:000A7208]
        _formsToChange.Add('000A7209'); // TreeBlasted02LichenFX [STAT:000A7209]
        _formsToChange.Add('000A7403'); // TreeblastedM04Lichen [STAT:000A7403]
        _formsToChange.Add('000A7404'); // TreeblastedM04LichenFX [STAT:000A7404]
        _formsToChange.Add('000A7405'); // TreeMapleblasted02Lichen [STAT:000A7405]
        _formsToChange.Add('000A7406'); // TreeMapleblasted02LichenFX [STAT:000A7406]
        _formsToChange.Add('000ADEAF'); // TreeDriftwood01 "Driftwood" [STAT:000ADEAF]
        _formsToChange.Add('000ADEB6'); // TreeDriftwoodStump01 "Stump" [STAT:000ADEB6]
        _formsToChange.Add('000ADEB8'); // TreeDriftwoodStump02 "Stump" [STAT:000ADEB8]
        _formsToChange.Add('000ADEBA'); // TreeDriftwoodStump03 "Stump" [STAT:000ADEBA]
        _formsToChange.Add('000ADEBC'); // TreeDriftwoodStump04 "Stump" [STAT:000ADEBC]
        _formsToChange.Add('000ADEC3'); // TreeDriftwoodLog02 "Driftwood" [STAT:000ADEC3]
        _formsToChange.Add('000AF0D0'); // TreeDriftwoodLog01 "Driftwood" [STAT:000AF0D0]
        _formsToChange.Add('000AF0DB'); // TreeDriftwoodLog03 "Driftwood" [STAT:000AF0DB]
        _formsToChange.Add('000AF0DE'); // TreeDriftwood02 "Driftwood" [STAT:000AF0DE]
        _formsToChange.Add('000B9A09'); // PGarageClutterBollard01 [STAT:000B9A09]
        _formsToChange.Add('000BAD0D'); // SeaweedVine01 [STAT:000BAD0D]
        _formsToChange.Add('000BAD0F'); // SeaweedGround01 [STAT:000BAD0F]
        _formsToChange.Add('000BB7C9'); // SeaweedVine02 [STAT:000BB7C9]
        _formsToChange.Add('000BDAEE'); // Seaweed02 [STAT:000BDAEE]
        _formsToChange.Add('000BDAEF'); // Seaweed03 [STAT:000BDAEF]
        _formsToChange.Add('000BFA41'); // SeaweedVine03 [STAT:000BFA41]
        _formsToChange.Add('000D2757'); // MirelurkDebrisDecal01 [STAT:000D2757]
        _formsToChange.Add('000D51B4'); // MirelurkDebrisDecal02 [STAT:000D51B4]
        _formsToChange.Add('000D9CA7'); // TreeElmTree01Static "Elm Tree" [STAT:000D9CA7]
        _formsToChange.Add('000D9CA8'); // TreeElmForest01Static "Elm Tree" [STAT:000D9CA8]
        _formsToChange.Add('000D9CA9'); // TreeElmForest02Static "Elm Tree" [STAT:000D9CA9]
        _formsToChange.Add('000D9CAA'); // TreeElmUndergrowth01Static "Elm Sapling" [STAT:000D9CAA]
        _formsToChange.Add('000D9CAB'); // TreeElmUndergrowth02Static "Elm Sapling" [STAT:000D9CAB]
        _formsToChange.Add('000E72CA'); // ProtectronDebris1 [STAT:000E72CA]
        _formsToChange.Add('000E72CB'); // ProtectronDebris2 [STAT:000E72CB]
        _formsToChange.Add('000E72CC'); // ProtectronDebris3 [STAT:000E72CC]
        _formsToChange.Add('000E72CD'); // ProtectronDebris4 [STAT:000E72CD]
        _formsToChange.Add('000E72CE'); // ProtectronDebris5 [STAT:000E72CE]
        _formsToChange.Add('000E72CF'); // ProtectronDebris6 [STAT:000E72CF]
        _formsToChange.Add('000E8271'); // DebrisMoundGlowingSea01 [STAT:000E8271]
        _formsToChange.Add('000E8273'); // DebrisMoundGlowingSea02 [STAT:000E8273]
        _formsToChange.Add('000EAF3B'); // DebrisPileGlowingSea01 [STAT:000EAF3B]
        _formsToChange.Add('000F2541'); // TreeStumpGS01 "Stump" [STAT:000F2541]
        _formsToChange.Add('000F2543'); // TreeLogGS01 "Burnt Log" [STAT:000F2543]
        _formsToChange.Add('000F290C'); // TreeLogGS02 [STAT:000F290C]
        _formsToChange.Add('000F290F'); // TreeLogGS03 [STAT:000F290F]
        _formsToChange.Add('000F35C8'); // TreeLogGS04 [STAT:000F35C8]
        _formsToChange.Add('000F35CA'); // TreeLogGS05 [STAT:000F35CA]
        _formsToChange.Add('000F35CC'); // TreeGS01 [STAT:000F35CC]
        _formsToChange.Add('000F40EA'); // HedgeRowGS01 [STAT:000F40EA]
        _formsToChange.Add('000F40ED'); // HedgeRowGS02 [STAT:000F40ED]
        _formsToChange.Add('000F40EF'); // deadshrubGS01 [STAT:000F40EF]
        _formsToChange.Add('000F40F1'); // deadshrubGS02 [STAT:000F40F1]
        _formsToChange.Add('000F40F3'); // deadshrubGS03 [STAT:000F40F3]
        _formsToChange.Add('000F40F5'); // HedgeRowGS03 [STAT:000F40F5]
        _formsToChange.Add('000F478F'); // TreeLogGS06 [STAT:000F478F]
        _formsToChange.Add('000F4791'); // TreeGS02 [STAT:000F4791]
        _formsToChange.Add('000F393D'); // Rubble_Flat_Trash_Lg01a [STAT:000F393D]
        _formsToChange.Add('000F393F'); // Rubble_Pile_Trash_Lrg01 [STAT:000F393F]
        _formsToChange.Add('00106936'); // Rubble_Flat_Trash_Edge01 [STAT:00106936]
        _formsToChange.Add('00106937'); // Rubble_Flat_Trash_Edge02 [STAT:00106937]
        _formsToChange.Add('00106938'); // Rubble_Flat_Trash_Edge03 [STAT:00106938]
        _formsToChange.Add('00106939'); // Rubble_Flat_Trash_Lg01b [STAT:00106939]
        _formsToChange.Add('0010693A'); // Rubble_Flat_Trash_Lg01c [STAT:0010693A]
        _formsToChange.Add('0010693B'); // Rubble_Flat_Trash_Sm01 [STAT:0010693B]
        _formsToChange.Add('0010693C'); // Rubble_Flat_Trash_Sm02 [STAT:0010693C]
        _formsToChange.Add('0010693D'); // Rubble_Flat_Trash_Sm03 [STAT:0010693D]
        _formsToChange.Add('0010693E'); // Rubble_Flat_Trash_Sm04 [STAT:0010693E]
        _formsToChange.Add('0010693F'); // Rubble_Flat_Trash_Sm05 [STAT:0010693F]
        _formsToChange.Add('00106940'); // Rubble_Pile_Trash_Lrg02 [STAT:00106940]
        _formsToChange.Add('00106951'); // Rubble_Pile_Trash_Med01 [STAT:00106951]
        _formsToChange.Add('00106FBD'); // TreeStumpSMarsh01 "Stump" [STAT:00106FBD]
        _formsToChange.Add('00109180'); // TreeStumpSMarsh02 "Stump" [STAT:00109180]
        _formsToChange.Add('00109182'); // TreeSMarsh01 "Tree" [STAT:00109182]
        _formsToChange.Add('00109184'); // TreeStumpSMarsh03 "Stump" [STAT:00109184]
        _formsToChange.Add('0010918D'); // TreeSMarsh02 "Tree" [STAT:0010918D]
        _formsToChange.Add('0010A2C0'); // TreeSMarsh03 "Tree" [STAT:0010A2C0]
        _formsToChange.Add('0010BFDF'); // TreeFallenSMarsh04 "Log" [STAT:0010BFDF]
        _formsToChange.Add('0010C66C'); // TreeFallenSMarsh01 "Log" [STAT:0010C66C]
        _formsToChange.Add('0010CBE2'); // SMarshMoss01 [STAT:0010CBE2]
        _formsToChange.Add('0010CBE3'); // SMarshMoss02 [STAT:0010CBE3]
        _formsToChange.Add('0010CBE4'); // SMarshMoss03 [STAT:0010CBE4]
        _formsToChange.Add('0010FA77'); // SMarshMoss04 [STAT:0010FA77]
        _formsToChange.Add('0010FA79'); // TreeSMarsh04 "Tree" [STAT:0010FA79]
        _formsToChange.Add('001103D3'); // TreeSMarsh05 "Tree" [STAT:001103D3]
        _formsToChange.Add('001103D6'); // TreeSMarshRoots01 "Roots" [STAT:001103D6]
        _formsToChange.Add('001103D9'); // TreeSMarshRoots02 "Roots" [STAT:001103D9]
        _formsToChange.Add('00111F7D'); // SMarshMossWall01 [STAT:00111F7D]
        _formsToChange.Add('00111F80'); // SMarshMossWall02 [STAT:00111F80]
        _formsToChange.Add('00118911'); // DebrisPileLargeWood06_Marsh [STAT:00118911]
        _formsToChange.Add('0011A8E8'); // TrashPileWall01_Marsh [STAT:0011A8E8]
        _formsToChange.Add('0011A917'); // TrashPileCorIn01_Marsh [STAT:0011A917]
        _formsToChange.Add('0011A918'); // TrashPileWall02_Marsh [STAT:0011A918]
        _formsToChange.Add('0011A919'); // TrashPileWall03_Marsh [STAT:0011A919]
        _formsToChange.Add('0011A91A'); // TrashClump03_Marsh [STAT:0011A91A]
        _formsToChange.Add('0011A91B'); // TrashClump02_Marsh [STAT:0011A91B]
        _formsToChange.Add('0011A91C'); // TrashClump01_Marsh [STAT:0011A91C]
        _formsToChange.Add('0012154B'); // TreeBlastedForestBurntFallen02_Top "Fallen Tree" [STAT:0012154B]
        _formsToChange.Add('0012154C'); // TreeBlastedForestBurntFallen03 "Fallen Tree" [STAT:0012154C]
        _formsToChange.Add('0012154D'); // TreeBlastedForestBurntStump01 "Stump" [STAT:0012154D]
        _formsToChange.Add('0012154E'); // TreeBlastedForestBurntStump02 "Stump" [STAT:0012154E]
        _formsToChange.Add('0012154F'); // TreeBlastedForestBurntUpright03 "Tree" [STAT:0012154F]
        _formsToChange.Add('00121550'); // TreeBlastedForestBurntUpright02 "Tree" [STAT:00121550]
        _formsToChange.Add('00121551'); // TreeBlastedForestBurntUpright01 "Tree" [STAT:00121551]
        _formsToChange.Add('00121552'); // TreeBlastedForestBurntStump03 "Stump" [STAT:00121552]
        _formsToChange.Add('00121553'); // TreeBlastedForestBurntFallen01 "Fallen Tree" [STAT:00121553]
        _formsToChange.Add('00121554'); // TreeBlastedForestBurntFallen02_Bottom "Fallen Tree" [STAT:00121554]
        _formsToChange.Add('001236AE'); // TreeBlastedForestDestroyedFallen01 "Blasted Log" [STAT:001236AE]
        _formsToChange.Add('001236AF'); // TreeBlastedForestDestroyedFallen02 "Blasted Log" [STAT:001236AF]
        _formsToChange.Add('001236B0'); // TreeBlastedForestDestroyedFallen03 "Blasted Log" [STAT:001236B0]
        _formsToChange.Add('001236B1'); // TreeBlastedForestDestroyedStump01 "Blasted Stump" [STAT:001236B1]
        _formsToChange.Add('001236B2'); // TreeBlastedForestDestroyedStump02 "Blasted Stump" [STAT:001236B2]
        _formsToChange.Add('001236B3'); // TreeBlastedForestDestroyedStump03 "Blasted Stump" [STAT:001236B3]
        _formsToChange.Add('001236B4'); // TreeBlastedForestDestroyedUpright01 "Blasted Tree" [STAT:001236B4]
        _formsToChange.Add('001236B5'); // TreeBlastedForestDestroyedUpright02 "Blasted Tree" [STAT:001236B5]
        _formsToChange.Add('001236B6'); // TreeBlastedForestDestroyedUpright03 "Blasted Tree" [STAT:001236B6]
        _formsToChange.Add('00123A61'); // TrashPileWall01_Gravel [STAT:00123A61]
        _formsToChange.Add('00123A66'); // TrashPileWall02_Gravel [STAT:00123A66]
        _formsToChange.Add('00123A6A'); // TrashClump03_Gravel [STAT:00123A6A]
        _formsToChange.Add('00123A6B'); // TrashClump02_Gravel [STAT:00123A6B]
        _formsToChange.Add('00123A6C'); // TrashClump01_Gravel [STAT:00123A6C]
        _formsToChange.Add('00123AD0'); // TrashPileCor01_Gravel [STAT:00123AD0]
        _formsToChange.Add('00123DD1'); // BlastedForestVinesCluster01 [STAT:00123DD1]
        _formsToChange.Add('00123DD2'); // BlastedForestVinesHanging01 [STAT:00123DD2]
        _formsToChange.Add('00123DD3'); // BlastedForestVinesHanging02 [STAT:00123DD3]
        _formsToChange.Add('00125504'); // BlastedForestFungalGroundCluster02 [STAT:00125504]
        _formsToChange.Add('00125505'); // BlastedForestFungalGroundWedges01 [STAT:00125505]
        _formsToChange.Add('00125506'); // BlastedForestFungalGroundWedges02 [STAT:00125506]
        _formsToChange.Add('00125507'); // BlastedForestFungalTreeCluster01 [STAT:00125507]
        _formsToChange.Add('00125508'); // BlastedForestFungalTreeCluster02 [STAT:00125508]
        _formsToChange.Add('00125509'); // BlastedForestFungalTreeCluster06 [STAT:00125509]
        _formsToChange.Add('0012550A'); // BlastedForestFungalTreeCluster05 [STAT:0012550A]
        _formsToChange.Add('0012550B'); // BlastedForestFungalTreeCluster04 [STAT:0012550B]
        _formsToChange.Add('0012550C'); // BlastedForestFungalTreeCluster03 [STAT:0012550C]
        _formsToChange.Add('0012550D'); // BlastedForestFungalGroundCluster01 [STAT:0012550D]
        _formsToChange.Add('0012B6D6'); // DebrisPileLargeWood06_SandDry [STAT:0012B6D6]
        _formsToChange.Add('0012B6DA'); // TrashClump01_SandWet [STAT:0012B6DA]
        _formsToChange.Add('0012B6DE'); // TrashClump02_SandWet [STAT:0012B6DE]
        _formsToChange.Add('0012B6E2'); // TrashClump03_SandWet [STAT:0012B6E2]
        _formsToChange.Add('0013384D'); // Bramble01 [STAT:0013384D]
        _formsToChange.Add('0013384E'); // Bramble02 [STAT:0013384E]
        _formsToChange.Add('0013384F'); // Bramble03 [STAT:0013384F]
        _formsToChange.Add('00133850'); // Bramble04 [STAT:00133850]
        _formsToChange.Add('00133853'); // DeadShrub01 [STAT:00133853]
        _formsToChange.Add('00133854'); // DeadShrub02 [STAT:00133854]
        _formsToChange.Add('00133855'); // DeadShrub03 [STAT:00133855]
        _formsToChange.Add('00133856'); // DeadShrub04 [STAT:00133856]
        _formsToChange.Add('00133857'); // DeadShrub05 "Bush" [STAT:00133857]
        _formsToChange.Add('00133858'); // DeadShrub06 "Bush" [STAT:00133858]
        _formsToChange.Add('00133859'); // Forsythia01 [STAT:00133859]
        _formsToChange.Add('0013385A'); // Forsythia02 [STAT:0013385A]
        _formsToChange.Add('0013385B'); // Forsythia03 [STAT:0013385B]
        _formsToChange.Add('0013385C'); // HedgeRow01 [STAT:0013385C]
        _formsToChange.Add('0013385D'); // HedgeRow02 "Bush" [STAT:0013385D]
        _formsToChange.Add('0013385E'); // HedgeRow03 [STAT:0013385E]
        _formsToChange.Add('0013385F'); // HedgeRow04 [STAT:0013385F]
        _formsToChange.Add('00133861'); // HollyShrub01 "Shrub" [STAT:00133861]
        _formsToChange.Add('00133862'); // HollyShrub02 "Shrub" [STAT:00133862]
        _formsToChange.Add('00133863'); // HollyShrub03 "Shrub" [STAT:00133863]
        _formsToChange.Add('00133864'); // HollyShrub04 "Shrub" [STAT:00133864]
        _formsToChange.Add('00133865'); // ShrubGroupLarge04 [STAT:00133865]
        _formsToChange.Add('00133866'); // ShrubGroupLarge05 [STAT:00133866]
        _formsToChange.Add('00133867'); // ShrubGroupMedium02 [STAT:00133867]
        _formsToChange.Add('00133868'); // ShrubGroupMedium03 [STAT:00133868]
        _formsToChange.Add('00133869'); // ShrubGroupSmall01 [STAT:00133869]
        _formsToChange.Add('0013386A'); // Fern01 [STAT:0013386A]
        _formsToChange.Add('0013386B'); // Fern02 [STAT:0013386B]
        _formsToChange.Add('0013386F'); // Marshshrub01 [STAT:0013386F]
        _formsToChange.Add('00133870'); // Marshshrub02 [STAT:00133870]
        _formsToChange.Add('00133871'); // HollyShrubSmall01Trimmed "Shrub" [STAT:00133871]
        _formsToChange.Add('0013C377'); // TreeBlastedForestFungalLarge01 [STAT:0013C377]
        _formsToChange.Add('0013C378'); // TreeBlastedForestFungalMedium01 [STAT:0013C378]
        _formsToChange.Add('0013C379'); // TreeBlastedForestFungalSmall01 [STAT:0013C379]
        _formsToChange.Add('0013C37A'); // BlastedForestGroundRoots01 [STAT:0013C37A]
        _formsToChange.Add('0013C37B'); // BlastedForestGroundRoots02 [STAT:0013C37B]
        _formsToChange.Add('0013C37C'); // BlastedForestGroundRootsRadial01 [STAT:0013C37C]
        _formsToChange.Add('00140570'); // TreeMapleForest1BirdMarker [STAT:00140570]
        _formsToChange.Add('00140571'); // TreeMapleForestsmall1BirdMarker [STAT:00140571]
        _formsToChange.Add('00140572'); // TreeMapleblasted01BirdMarker [STAT:00140572]
        _formsToChange.Add('001453D7'); // TrashClump01_Silt [STAT:001453D7]
        _formsToChange.Add('001453D8'); // TrashClump02_Silt [STAT:001453D8]
        _formsToChange.Add('001453D9'); // TrashClump03_Silt [STAT:001453D9]
        _formsToChange.Add('00148EEF'); // RoseBush01 [STAT:00148EEF]
        _formsToChange.Add('00148EF3'); // RoseBush02 [STAT:00148EF3]
        _formsToChange.Add('0014EBB8'); // RoseBush01White [STAT:0014EBB8]
        _formsToChange.Add('0014EBB9'); // RoseBush02White [STAT:0014EBB9]
        _formsToChange.Add('00165012'); // OfficePaperDebris03 [STAT:00165012]
        _formsToChange.Add('00165014'); // OfficePaperDebris04 [STAT:00165014]
        _formsToChange.Add('00165015'); // OfficePaperDebris05 [STAT:00165015]
        _formsToChange.Add('0016501E'); // OfficePaperDebris06 [STAT:0016501E]
        _formsToChange.Add('00165022'); // OfficePaperDebris07 [STAT:00165022]
        _formsToChange.Add('00165023'); // OfficePaperDebrisSinglePg01 [STAT:00165023]
        _formsToChange.Add('00165024'); // OfficePaperDebris02 [STAT:00165024]
        _formsToChange.Add('00165025'); // OfficePaperDebrisSinglePg02 [STAT:00165025]
        _formsToChange.Add('00165026'); // OfficePaperDebrisSinglePg03 [STAT:00165026]
        _formsToChange.Add('00165027'); // OfficePaperDebrisSinglePg04 [STAT:00165027]
        _formsToChange.Add('0016ADBB'); // TreeNoose01_Branch [STAT:0016ADBB]
        _formsToChange.Add('0016BAF3'); // PaperDebris01 [STAT:0016BAF3]
        _formsToChange.Add('0016BAF5'); // PaperDebris02 [STAT:0016BAF5]
        _formsToChange.Add('001798F0'); // SWflat2x2CircleTree_01 [STAT:001798F0]
        _formsToChange.Add('00179B43'); // TrashPileCorIn01_CraterDebris [STAT:00179B43]
        _formsToChange.Add('00179B44'); // TrashPileWall01_DebrisCrater [STAT:00179B44]
        _formsToChange.Add('00179B45'); // TrashClump03_DebrisCrater [STAT:00179B45]
        _formsToChange.Add('00179B46'); // TrashClump01_CraterDebris [STAT:00179B46]
        _formsToChange.Add('00179B48'); // TrashClump02_DebrisCrater [STAT:00179B48]
        _formsToChange.Add('00182994'); // MarshScumL01_Debris [STAT:00182994]
        _formsToChange.Add('0018BA4F'); // NFCreosote01 [STAT:0018BA4F]
        _formsToChange.Add('0018BA50'); // NFCreosote02 [STAT:0018BA50]
        _formsToChange.Add('0018BA51'); // NFCreosote03 [STAT:0018BA51]
        _formsToChange.Add('00191498'); // Rubble_Pile_Debris_04 [STAT:00191498]
        _formsToChange.Add('0019149E'); // Rubble_Pile_Debris_05 [STAT:0019149E]
        _formsToChange.Add('0019149F'); // Rubble_Pile_Debris_07 [STAT:0019149F]
        _formsToChange.Add('001914A2'); // Rubble_Pile_Debris_06 [STAT:001914A2]
        _formsToChange.Add('001914A5'); // Rubble_Pile_Debris_03 [STAT:001914A5]
        _formsToChange.Add('001914C0'); // Rubble_Pile_Debris_01 [STAT:001914C0]
        _formsToChange.Add('001914C2'); // DecalDebris05 [STAT:001914C2]
        _formsToChange.Add('001914C9'); // DecalDebris04 [STAT:001914C9]
        _formsToChange.Add('001914DB'); // DecalDebris06 [STAT:001914DB]
        _formsToChange.Add('00191624'); // Rubble_Pile_Debris_02 [STAT:00191624]
        _formsToChange.Add('00195CC4'); // NFoothillsShrubLarge01 [STAT:00195CC4]
        _formsToChange.Add('00195CC5'); // NFoothillsShrubMedium01 [STAT:00195CC5]
        _formsToChange.Add('00195CC6'); // NFoothillsShrubSmall01 [STAT:00195CC6]
        _formsToChange.Add('00197516'); // FarmPlot01BlastedForest [STAT:00197516]
        _formsToChange.Add('0019A6AE'); // HighTechDebris01 [STAT:0019A6AE]
        _formsToChange.Add('0019A6AF'); // HighTechDebris02 [STAT:0019A6AF]
        _formsToChange.Add('0019A6B0'); // HighTechDebris03 [STAT:0019A6B0]
        _formsToChange.Add('0019A6B1'); // HighTechDebris04 [STAT:0019A6B1]
        _formsToChange.Add('0019A6B2'); // HighTechDebris05 [STAT:0019A6B2]
        _formsToChange.Add('0019A6B3'); // HighTechDebris06 [STAT:0019A6B3]
        _formsToChange.Add('0019A6B4'); // HighTechDebris07 [STAT:0019A6B4]
        _formsToChange.Add('0019A6B5'); // HighTechDebris08 [STAT:0019A6B5]
        _formsToChange.Add('0019A6B6'); // HighTechDebrisDecal01 [STAT:0019A6B6]
        _formsToChange.Add('0019A6B7'); // HighTechDebrisDecal02 [STAT:0019A6B7]
        _formsToChange.Add('0019A6B8'); // HighTechDebrisDecal03 [STAT:0019A6B8]
        _formsToChange.Add('0019FAA1'); // TrashPileCorIn01_Silt [STAT:0019FAA1]
        _formsToChange.Add('001A891E'); // HedgeRow03PW [STAT:001A891E]
        _formsToChange.Add('001A8921'); // HedgeRow02PW [STAT:001A8921]
        _formsToChange.Add('001A8924'); // HedgeRow01PW [STAT:001A8924]
        _formsToChange.Add('00020B8C'); // VineHanging01NF [STAT:00020B8C]
        _formsToChange.Add('00020B99'); // VineHanging02NF [STAT:00020B99]
        _formsToChange.Add('00020CD1'); // VineHanging03NF [STAT:00020CD1]
        _formsToChange.Add('00020D35'); // VineHanging04NF [STAT:00020D35]
        _formsToChange.Add('00020D3F'); // VineHanging05NF [STAT:00020D3F]
        _formsToChange.Add('00020D4A'); // VineHanging06NF [STAT:00020D4A]
        _formsToChange.Add('00020D4F'); // VineHanging07NF [STAT:00020D4F]
        _formsToChange.Add('00020D55'); // VineHanging08NF [STAT:00020D55]
        _formsToChange.Add('00020D63'); // VineHanging09NF [STAT:00020D63]
        _formsToChange.Add('00020DF6'); // VineHangingLarge01NF [STAT:00020DF6]
        _formsToChange.Add('00020E25'); // VineHangingLarge02NF [STAT:00020E25]
        _formsToChange.Add('00020E2C'); // VineHangingLarge03NF [STAT:00020E2C]
        _formsToChange.Add('00020E2F'); // VineShrub01NF [STAT:00020E2F]
        _formsToChange.Add('00020E32'); // VineTree01NF [STAT:00020E32]
        _formsToChange.Add('00020E35'); // VineTree02NF [STAT:00020E35]
        _formsToChange.Add('00020E38'); // VineGround01NF [STAT:00020E38]
        _formsToChange.Add('00020E3B'); // VineGround02NF [STAT:00020E3B]
        _formsToChange.Add('00020E3E'); // VineGround03NF [STAT:00020E3E]
        _formsToChange.Add('00020E41'); // VineDecalCorner01NF [STAT:00020E41]
        _formsToChange.Add('00020E44'); // VineDecalCorner02NF [STAT:00020E44]
        _formsToChange.Add('00020E47'); // VineDecalLarge01NF [STAT:00020E47]
        _formsToChange.Add('00020E4A'); // VineDecalLarge02NF [STAT:00020E4A]
        _formsToChange.Add('00020E4D'); // VineDecalLarge03NF [STAT:00020E4D]
        _formsToChange.Add('00020E50'); // VineDecalMed01NF [STAT:00020E50]
        _formsToChange.Add('00020E62'); // VineDecalMed02NF [STAT:00020E62]
        _formsToChange.Add('00020EAF'); // VineDecalMed03NF [STAT:00020EAF]
        _formsToChange.Add('00020EDC'); // VineDecalSmall01NF [STAT:00020EDC]
        _formsToChange.Add('00020EEB'); // VineDecalSmall02NF [STAT:00020EEB]
        _formsToChange.Add('00020EEE'); // VineDecalSmall03NF [STAT:00020EEE]
        _formsToChange.Add('00020EFA'); // VineDecalXSmall01NF [STAT:00020EFA]
        _formsToChange.Add('00020F09'); // VineDecalXSmall02NF [STAT:00020F09]
        _formsToChange.Add('0002B8F0'); // DecalConcrete01 [STAT:0002B8F0]
        _formsToChange.Add('0002B8F1'); // DecalConcrete02 [STAT:0002B8F1]
        _formsToChange.Add('0002B8F2'); // DecalConcrete03 [STAT:0002B8F2]
        _formsToChange.Add('0002B8F3'); // DecalConcrete04 [STAT:0002B8F3]
        _formsToChange.Add('0002B8F4'); // DecalMetal01 [STAT:0002B8F4]
        _formsToChange.Add('0002B8F5'); // DecalMetal02 [STAT:0002B8F5]
        _formsToChange.Add('0002B8F6'); // DecalMetal03 [STAT:0002B8F6]
        _formsToChange.Add('0002B8F7'); // DecalMetal04 [STAT:0002B8F7]
        _formsToChange.Add('0002B8F8'); // DecalWood01 [STAT:0002B8F8]
        _formsToChange.Add('0002B8F9'); // DecalWood02 [STAT:0002B8F9]
        _formsToChange.Add('0002B8FA'); // DecalWood03 [STAT:0002B8FA]
        _formsToChange.Add('0002B8FB'); // DecalWood04 [STAT:0002B8FB]
        _formsToChange.Add('0002D587'); // ExtRubble_HiTec_Debris01 "Debris" [STAT:0002D587]
        _formsToChange.Add('0004471B'); // ExtRubble_HiTec_Debris02 "Debris" [STAT:0004471B]
        _formsToChange.Add('000B3748'); // WaterDebrisA [STAT:000B3748]
        _formsToChange.Add('000C041C'); // WaterDebrisB [STAT:000C041C]
        _formsToChange.Add('00122E1F'); // TrashPileRectangle01 [STAT:00122E1F]
        _formsToChange.Add('0013578B'); // ExtRubble_HiTec_Debris04 "Debris" [STAT:0013578B]
        _formsToChange.Add('0013578C'); // ExtRubble_HiTec_Debris05 "Debris" [STAT:0013578C]
        _formsToChange.Add('0013578D'); // ExtRubble_HiTec_Debris06 "Debris" [STAT:0013578D]
        _formsToChange.Add('0013578E'); // ExtRubble_HiTec_Debris07 "Debris" [STAT:0013578E]
        _formsToChange.Add('0013578F'); // ExtRubble_HiTec_Debris08 "Debris" [STAT:0013578F]
        _formsToChange.Add('00135790'); // ExtRubble_HiTec_Debris03 "Debris" [STAT:00135790]
        _formsToChange.Add('00188845'); // DeadShrub01Obscurance [STAT:00188845]
        _formsToChange.Add('00194493'); // ClutterGenShelfC [STAT:00194493]
        _formsToChange.Add('00194497'); // ClutterGenDeskA [STAT:00194497]
        _formsToChange.Add('0019449D'); // ClutterGenTableA [STAT:0019449D]
        _formsToChange.Add('001944A0'); // ClutterGenDecalA [STAT:001944A0]
        _formsToChange.Add('001944AA'); // ClutterGenDeskB [STAT:001944AA]
        _formsToChange.Add('001944AF'); // ClutterGenSlimeA [STAT:001944AF]
        _formsToChange.Add('001944B0'); // ClutterGenDecalA1 [STAT:001944B0]
        _formsToChange.Add('001944B2'); // ClutterGenDeskC [STAT:001944B2]
        _formsToChange.Add('001944B5'); // ClutterGenDeskD [STAT:001944B5]
        _formsToChange.Add('001944BC'); // ClutterGenDustA [STAT:001944BC]
        _formsToChange.Add('001944D0'); // ClutterGenShelfA [STAT:001944D0]
        _formsToChange.Add('001944D3'); // ClutterGenShelfB [STAT:001944D3]
        _formsToChange.Add('001A97D8'); // TreeSapling01 [STAT:001A97D8]
        _formsToChange.Add('001A97D9'); // TreeSapling02 [STAT:001A97D9]
        _formsToChange.Add('001A97DA'); // TreeSapling03 [STAT:001A97DA]
        _formsToChange.Add('001A97DB'); // TreeSapling04 [STAT:001A97DB]
        _formsToChange.Add('001A97DC'); // TreeCedarShrub01 [STAT:001A97DC]
        _formsToChange.Add('001A97DD'); // TreeCedarShrub02 [STAT:001A97DD]
        _formsToChange.Add('001A97DE'); // TreeCedarShrub03 [STAT:001A97DE]
        _formsToChange.Add('001A97DF'); // TreeClusterMound01 [STAT:001A97DF]
        _formsToChange.Add('001A97E0'); // TreeClusterMound02 [STAT:001A97E0]
        _formsToChange.Add('001A97E1'); // TreeClusterMound01_Marsh "Trees" [STAT:001A97E1]
        _formsToChange.Add('001A97E3'); // TreeClusterMound02_Marsh "Trees" [STAT:001A97E3]
        _formsToChange.Add('001A97E5'); // TreeClusterMound02_Forest [STAT:001A97E5]
        _formsToChange.Add('001A97E6'); // TreeClusterMound02_NF [STAT:001A97E6]
        _formsToChange.Add('001ADB1D'); // TrashEdge03_Nochunks [STAT:001ADB1D]
        _formsToChange.Add('001ADB1E'); // TrashEdge04_nochunks [STAT:001ADB1E]
        _formsToChange.Add('001ADB1F'); // TrashClump03_nochunks [STAT:001ADB1F]
        _formsToChange.Add('001ADB20'); // TrashPileWall02_nochunks [STAT:001ADB20]
        _formsToChange.Add('001ADB21'); // TrashPileCorIn01_nochunks [STAT:001ADB21]
        _formsToChange.Add('001ADB22'); // TrashPileWall01_nochunks [STAT:001ADB22]
        _formsToChange.Add('001ADB23'); // TrashPileWall03_nochunks [STAT:001ADB23]
        _formsToChange.Add('001B9B93'); // MarshScumM01_Debris [STAT:001B9B93]
        _formsToChange.Add('001B9B96'); // MarshScumS01_Debris [STAT:001B9B96]
        _formsToChange.Add('001BB8CF'); // TrashClump01_SandDry [STAT:001BB8CF]
        _formsToChange.Add('001BB8D3'); // TrashClump02_SandDry [STAT:001BB8D3]
        _formsToChange.Add('001BB8D4'); // TrashClump03_SandDry [STAT:001BB8D4]
        _formsToChange.Add('001BCE55'); // BlastedForestLeafPile01 [STAT:001BCE55]
        _formsToChange.Add('001BCE57'); // BlastedForestLeafPile02 [STAT:001BCE57]
        _formsToChange.Add('001BE3C8'); // BlastedForestFungalGroundWedges03 [STAT:001BE3C8]
        _formsToChange.Add('001BE3C9'); // BlastedForestFungalGroundCluster03 [STAT:001BE3C9]
        _formsToChange.Add('001BE3CA'); // BlastedForestFungalGroundCluster04 [STAT:001BE3CA]
        _formsToChange.Add('001BE3CB'); // BlastedForestLeafPile03 [STAT:001BE3CB]
        _formsToChange.Add('001BE432'); // Seaweed03_Water [STAT:001BE432]
        _formsToChange.Add('001BE433'); // Seaweed02_Water [STAT:001BE433]
        _formsToChange.Add('001BE434'); // SeaweedGround01_Water [STAT:001BE434]
        _formsToChange.Add('001BF098'); // DebrisMoundCoastFloor01_WetSand [STAT:001BF098]
        _formsToChange.Add('001BF09D'); // DebrisMoundCoastFloor01_RiverSilt [STAT:001BF09D]
        _formsToChange.Add('001BF09F'); // DebrisMoundCoastFloor01_OceanFloor [STAT:001BF09F]
        _formsToChange.Add('001C2291'); // TreeClusterMound01_RiverbedRocks02Wet [STAT:001C2291]
        _formsToChange.Add('001C9AF1'); // TrashPileWall03_Gravel [STAT:001C9AF1]
        _formsToChange.Add('001CCDA0'); // BlastedForestBurntBranch01 [STAT:001CCDA0]
        _formsToChange.Add('001CCDA1'); // BlastedForestBurntBranchPile01 [STAT:001CCDA1]
        _formsToChange.Add('001CCDA2'); // BlastedForestBurntBranchPile02 [STAT:001CCDA2]
        _formsToChange.Add('001E491C'); // Rubble_Flat_Trash_Catwalks_01 [STAT:001E491C]
        _formsToChange.Add('001E491D'); // Rubble_Flat_Trash_Catwalks_02 [STAT:001E491D]
        _formsToChange.Add('001E491E'); // Rubble_Flat_Trash_Catwalks_04 [STAT:001E491E]
        _formsToChange.Add('001E491F'); // Rubble_Flat_Trash_Catwalks_03 [STAT:001E491F]
        _formsToChange.Add('001E4920'); // Rubble_Flat_Trash_Catwalks_05 [STAT:001E4920]
        _formsToChange.Add('001E4921'); // Rubble_Flat_Trash_Catwalks_06 [STAT:001E4921]
        _formsToChange.Add('0020A563'); // ClutterGenDecalB [STAT:0020A563]
        _formsToChange.Add('0020D6D7'); // TreeElmFree01BirdMarker [STAT:0020D6D7]
        _formsToChange.Add('00214B0C'); // DinerWallDebris01 [STAT:00214B0C]
        _formsToChange.Add('0023A66B'); // VineHangingLarge10NF [STAT:0023A66B]
        _formsToChange.Add('0023A66F'); // VineHangingLarge11NF [STAT:0023A66F]
        _formsToChange.Add('01003D04'); // TreeRedPineSCCluster01_DLC03 [SCOL:01003D04]
        _formsToChange.Add('01003D05'); // TreeRedPineSCCluster02_DLC03 [SCOL:01003D05]
        _formsToChange.Add('01003D08'); // TreeRedPineSCCluster03_DLC03 [SCOL:01003D08]
        _formsToChange.Add('01003D0A'); // TreeRedPineSCCluster04_DLC03 [SCOL:01003D0A]
        _formsToChange.Add('01004F56'); // TreeRedPineSCCluster05_DLC03 [SCOL:01004F56]
        _formsToChange.Add('01004F59'); // TreeBeachPineSCCluster01_DLC03 [SCOL:01004F59]
        _formsToChange.Add('01005CEF'); // TreeBeachPineSCCluster02_DLC03 [SCOL:01005CEF]
        _formsToChange.Add('01005CF0'); // TreeRedPineSCCluster06_DLC03 [SCOL:01005CF0]
        _formsToChange.Add('01005CF1'); // TreeRedPineSCCluster07_DLC03 [SCOL:01005CF1]
        _formsToChange.Add('01006C8F'); // TreeRedPineSCBroken [SCOL:01006C8F]
        _formsToChange.Add('01006D26'); // ShrubGroupDLC03Large01 [SCOL:01006D26]
        _formsToChange.Add('01006D28'); // ShrubGroupDLC03Large02 [SCOL:01006D28]
        _formsToChange.Add('01006D29'); // ShrubGroupDLC03Medium01 [SCOL:01006D29]
        _formsToChange.Add('01006D2A'); // ShrubGroupDLC03Small01 [SCOL:01006D2A]
        _formsToChange.Add('01006D74'); // FernSC_DLC03_Sm01 [SCOL:01006D74]
        _formsToChange.Add('01006D76'); // FernSC_DLC03_Sm02 [SCOL:01006D76]
        _formsToChange.Add('01006D78'); // FernSC_DLC03_Med01 [SCOL:01006D78]
        _formsToChange.Add('01006D7A'); // FernSC_DLC03_Med02 [SCOL:01006D7A]
        _formsToChange.Add('01006D7C'); // FernSC_DLC03_Lg01 "DLC03\Landscape\Plants\" [SCOL:01006D7C]
        _formsToChange.Add('0100C44A'); // TreeBeachPineSCCluster03_DLC03 [SCOL:0100C44A]
        _formsToChange.Add('01016745'); // BranchPileStumpRocks02_DLC03 [SCOL:01016745]
        _formsToChange.Add('01016747'); // BranchPileStump02_DLC03 [SCOL:01016747]
        _formsToChange.Add('01001B58'); // TreeRedPineFull01 "Red Pine Tree" [STAT:01001B58]
        _formsToChange.Add('01001B59'); // TreeRedPineHalf01 "Red Pine Tree" [STAT:01001B59]
        _formsToChange.Add('01001B5A'); // TreeRedPineDead01 "Red Pine Tree" [STAT:01001B5A]
        _formsToChange.Add('010024F9'); // TreeRedPineHalf02 "Red Pine Tree" [STAT:010024F9]
        _formsToChange.Add('010024FA'); // TreeRedPineDead02 "Red Pine Tree" [STAT:010024FA]
        _formsToChange.Add('010024FB'); // TreeRedPineHalf03 "Red Pine Tree" [STAT:010024FB]
        _formsToChange.Add('010024FC'); // TreeBeachPine01 "Red Pine Tree" [STAT:010024FC]
        _formsToChange.Add('01002519'); // TreeRedPineHero01 "Red Pine Tree" [STAT:01002519]
        _formsToChange.Add('010025A4'); // TreeBeachPine02 "Dead Pine Tree" [STAT:010025A4]
        _formsToChange.Add('010026FF'); // KelpPile08_TrashClump02 [STAT:010026FF]
        _formsToChange.Add('01002BFC'); // KelpPile08_TrashClump01 [STAT:01002BFC]
        _formsToChange.Add('01002C12'); // KelpPile08_TrashClump03 [STAT:01002C12]
        _formsToChange.Add('01003C42'); // Bramble01_DLC03_01 [STAT:01003C42]
        _formsToChange.Add('01003C43'); // Bramble02_DLC03_01 [STAT:01003C43]
        _formsToChange.Add('01003C44'); // Bramble04_DLC03_01 [STAT:01003C44]
        _formsToChange.Add('01003C45'); // Creosote01_DLC03_01 [STAT:01003C45]
        _formsToChange.Add('01003C46'); // Creosote02_DLC03_01 [STAT:01003C46]
        _formsToChange.Add('01003C47'); // Creosote03_DLC03_01 [STAT:01003C47]
        _formsToChange.Add('01003C48'); // Fern01_DLC03_01 [STAT:01003C48]
        _formsToChange.Add('01003C49'); // Fern02_DLC03_01 [STAT:01003C49]
        _formsToChange.Add('01003C4A'); // HollyShrub01_DLC03_01 [STAT:01003C4A]
        _formsToChange.Add('01003C4B'); // HollyShrub02_DLC03_01 [STAT:01003C4B]
        _formsToChange.Add('01003C4C'); // HollyShrub03_DLC03_01 [STAT:01003C4C]
        _formsToChange.Add('01003C4D'); // HollyShrub04_DLC03_01 [STAT:01003C4D]
        _formsToChange.Add('01003C4E'); // Bramble03_DLC03_01 [STAT:01003C4E]
        _formsToChange.Add('01003C4F'); // Bramble01_DLC03_02 [STAT:01003C4F]
        _formsToChange.Add('01003C50'); // Bramble02_DLC03_02 [STAT:01003C50]
        _formsToChange.Add('01003C51'); // Bramble03_DLC03_02 [STAT:01003C51]
        _formsToChange.Add('01003C52'); // Bramble04_DLC03_02 [STAT:01003C52]
        _formsToChange.Add('01003C53'); // Fern01_DLC03_02 [STAT:01003C53]
        _formsToChange.Add('01003C54'); // Fern02_DLC03_02 [STAT:01003C54]
        _formsToChange.Add('01003C55'); // HollyShrub01_DLC03_02 [STAT:01003C55]
        _formsToChange.Add('01003C56'); // HollyShrub02_DLC03_02 [STAT:01003C56]
        _formsToChange.Add('01003C57'); // HollyShrub03_DLC03_02 [STAT:01003C57]
        _formsToChange.Add('01003C58'); // HollyShrub04_DLC03_02 [STAT:01003C58]
        _formsToChange.Add('01003C59'); // Fern01_DLC03_03 [STAT:01003C59]
        _formsToChange.Add('01003C5A'); // Fern02_DLC03_03 [STAT:01003C5A]
        _formsToChange.Add('01003C5B'); // Fern01_DLC03_04 [STAT:01003C5B]
        _formsToChange.Add('01003C5D'); // Fern02_DLC03_04 [STAT:01003C5D]
        _formsToChange.Add('0100443D'); // TreeRedPineFallen01 "Red Pine Tree" [STAT:0100443D]
        _formsToChange.Add('01004F4C'); // TreePineSmall01 "Red Pine Tree" [STAT:01004F4C]
        _formsToChange.Add('01004F4D'); // TreePineSmall02 "Red Pine Tree" [STAT:01004F4D]
        _formsToChange.Add('01004F4E'); // TreePineSmall03 "Red Pine Tree" [STAT:01004F4E]
        _formsToChange.Add('01005434'); // TreeRedPineFull02 "Red Pine Tree" [STAT:01005434]
        _formsToChange.Add('01005436'); // TreePineSmall04 "Red Pine Tree" [STAT:01005436]
        _formsToChange.Add('01005477'); // CreosoteShrubLarge01_DLC03_01 [STAT:01005477]
        _formsToChange.Add('01005479'); // CreosoteShrubMedium01_DLC03_01 [STAT:01005479]
        _formsToChange.Add('0100547B'); // CreosoteShrubSmall01_DLC03_01 [STAT:0100547B]
        _formsToChange.Add('01006C88'); // TreeRedPineLog01 "Red Pine Tree" [STAT:01006C88]
        _formsToChange.Add('01006C8A'); // TreeRedPineStump01 "Red Pine Tree" [STAT:01006C8A]
        _formsToChange.Add('01006C8C'); // TreeRedPineStump02 "Red Pine Tree" [STAT:01006C8C]
        _formsToChange.Add('010072DF'); // TreeBeachPineStump01 "Red Pine Tree" [STAT:010072DF]
        _formsToChange.Add('010072E0'); // TreeBeachPineLog01 "Pine Tree" [STAT:010072E0]
        _formsToChange.Add('0100FA8B'); // DirtSlope01_MarshTrash_DLC03 [STAT:0100FA8B]
        _formsToChange.Add('0100FBF3'); // TrashClump03_DLC03 [STAT:0100FBF3]
        _formsToChange.Add('0100FBF4'); // TrashEdge02_DLC03 [STAT:0100FBF4]
        _formsToChange.Add('0100FBF6'); // TrashPileWall02_DLC03 [STAT:0100FBF6]
        _formsToChange.Add('0100FBF7'); // TrashPileCorIn01_DLC03 [STAT:0100FBF7]
        _formsToChange.Add('0100FBF8'); // TrashClump02_DLC03 [STAT:0100FBF8]
        _formsToChange.Add('0100FBF9'); // TrashClump01_DLC03 [STAT:0100FBF9]
        _formsToChange.Add('0100FBFA'); // TrashEdge01_DLC03 [STAT:0100FBFA]
        _formsToChange.Add('0100FBFB'); // TrashEdge03_DLC03 [STAT:0100FBFB]
        _formsToChange.Add('0100FBFC'); // TrashEdge04_DLC03 [STAT:0100FBFC]
        _formsToChange.Add('0100FBFD'); // TrashPileWall01_DLC03 [STAT:0100FBFD]
        _formsToChange.Add('0100FBFE'); // TrashPileWall03_DLC03 [STAT:0100FBFE]
        _formsToChange.Add('01024FE4'); // HotelGlassDebrisC [STAT:01024FE4]
        _formsToChange.Add('01024FE5'); // HotelGlassDebrisA [STAT:01024FE5]
        _formsToChange.Add('01024FE6'); // HotelGlassDebrisB [STAT:01024FE6]
        _formsToChange.Add('010281BB'); // TreePineRoots01 [STAT:010281BB]
        _formsToChange.Add('010281BC'); // TreePineRoots04 [STAT:010281BC]
        _formsToChange.Add('010281BD'); // TreePineRoots05 [STAT:010281BD]
        _formsToChange.Add('010281BE'); // TreePineRoots02 [STAT:010281BE]
        _formsToChange.Add('010281BF'); // TreePineRoots03 [STAT:010281BF]
        _formsToChange.Add('010281D2'); // TreeBeachRoots01 [STAT:010281D2]
        _formsToChange.Add('010281D4'); // TreeBeachRoots02 [STAT:010281D4]
        _formsToChange.Add('010281D5'); // TreeBeachRoots03 [STAT:010281D5]
        _formsToChange.Add('010281D6'); // TreeBeachRoots04 [STAT:010281D6]
        _formsToChange.Add('010281D7'); // TreeBeachRoots05 [STAT:010281D7]
        _formsToChange.Add('0103CDF8'); // DirtSlope02_MarshTrash_DLC03 [STAT:0103CDF8]
        _formsToChange.Add('0200D1E9'); // DLC04_ShrubGroupMD01 [SCOL:0200D1E9]
        _formsToChange.Add('0200D1EC'); // DLC04_ShrubGroupMD02 [SCOL:0200D1EC]
        _formsToChange.Add('0200D1EE'); // DLC04_ShrubGroupSM01 [SCOL:0200D1EE]
        _formsToChange.Add('0200D1F0'); // DLC04_ShrubGroupSM04 [SCOL:0200D1F0]
        _formsToChange.Add('0200D2CE'); // DLC04_ShrubGroupSM03 [SCOL:0200D2CE]
        _formsToChange.Add('0200D2D0'); // DLC04_ShrubGroupLG01 [SCOL:0200D2D0]
        _formsToChange.Add('0200D2D2'); // DLC04_ShrubGroupMD04 [SCOL:0200D2D2]
        _formsToChange.Add('0200D2D3'); // DLC04_ShrubGroupLG03 [SCOL:0200D2D3]
        _formsToChange.Add('0200D2D4'); // DLC04_ShrubGroupLG05 [SCOL:0200D2D4]
        _formsToChange.Add('0200D2D5'); // DLC04_ShrubGroupMD03 [SCOL:0200D2D5]
        _formsToChange.Add('0200D2D6'); // DLC04_ShrubGroupSM02 [SCOL:0200D2D6]
        _formsToChange.Add('0200D2D8'); // DLC04_ShrubGroupSM05 [SCOL:0200D2D8]
        _formsToChange.Add('0200D2DF'); // DLC04_ShrubGroupLG02 [SCOL:0200D2DF]
        _formsToChange.Add('0200D2F2'); // DLC04_ShrubGroupLG06 [SCOL:0200D2F2]
        _formsToChange.Add('0200D2F4'); // DLC04_ShrubGroupLG04 [SCOL:0200D2F4]
        _formsToChange.Add('020392E4'); // TreeBlastedForestCluster08_DLC05 [SCOL:020392E4]
        _formsToChange.Add('020392E6'); // TreeBlastedForestCluster07_DLC05 [SCOL:020392E6]
        _formsToChange.Add('020392E8'); // TreeBlastedForestCluster06_DLC05 [SCOL:020392E8]
        _formsToChange.Add('020392EB'); // TreeBlastedForestCluster09_DLC05 [SCOL:020392EB]
        _formsToChange.Add('020392ED'); // TreeBlastedForestCluster10_DLC05 [SCOL:020392ED]
        _formsToChange.Add('0205356F'); // DLC04_GauntletSCTrashClutter03 [SCOL:0205356F]
        _formsToChange.Add('02053594'); // DLC04_GauntletSCTrashClutter04 [SCOL:02053594]
        _formsToChange.Add('02053626'); // DLC04_GauntletSCTrashClutter08 [SCOL:02053626]
        _formsToChange.Add('02053628'); // DLC04_GauntletSCTrashClutter09 [SCOL:02053628]
        _formsToChange.Add('0205362A'); // DLC04_GauntletSCTrashClutter10 [SCOL:0205362A]
        _formsToChange.Add('02053630'); // DLC04_GauntletSCTrashClutter13 [SCOL:02053630]
        _formsToChange.Add('02053632'); // DLC04_GauntletSCTrashClutter14 [SCOL:02053632]
        _formsToChange.Add('02053634'); // DLC04_GauntletSCTrashClutter15 [SCOL:02053634]
        _formsToChange.Add('02053636'); // DLC04_GauntletSCTrashClutter16 [SCOL:02053636]
        _formsToChange.Add('02053638'); // DLC04_GauntletSCTrashClutter17 [SCOL:02053638]
        _formsToChange.Add('0205363A'); // DLC04_GauntletSCTrashClutter18 [SCOL:0205363A]
        _formsToChange.Add('0205363C'); // DLC04_GauntletSCTrashClutter19 [SCOL:0205363C]
        _formsToChange.Add('0205363E'); // DLC04_GauntletSCTrashClutter20 [SCOL:0205363E]
        _formsToChange.Add('02053640'); // DLC04_GauntletSCTrashClutter21 [SCOL:02053640]
        _formsToChange.Add('02053642'); // DLC04_GauntletSCTrashClutter22 [SCOL:02053642]
        _formsToChange.Add('02053644'); // DLC04_GauntletSCTrashClutter23 [SCOL:02053644]
        _formsToChange.Add('0200AEE6'); // Briar_TreeL01 [STAT:0200AEE6]
        _formsToChange.Add('0200AEE7'); // Briar_TreeM01 [STAT:0200AEE7]
        _formsToChange.Add('0200AEE8'); // Briar_TreeS01 [STAT:0200AEE8]
        _formsToChange.Add('0200B408'); // DLC04_DebrisPile01_WetMud "Debris" [STAT:0200B408]
        _formsToChange.Add('0200B40B'); // DLC04_DebrisMound01_WetMud "Debris" [STAT:0200B40B]
        _formsToChange.Add('0200CBA9'); // TrashClump01_DLC04_ValleyGrass "Trash" [STAT:0200CBA9]
        _formsToChange.Add('0200CBAD'); // TrashClump01_DLC04_ValleyDirt "Trash" [STAT:0200CBAD]
        _formsToChange.Add('0200CBB0'); // TrashClump02_DLC04_ValleyDirt "Trash" [STAT:0200CBB0]
        _formsToChange.Add('0200CBB2'); // TrashClump02_DLC04_ValleyGrass "Trash" [STAT:0200CBB2]
        _formsToChange.Add('0200CBB4'); // TrashClump03_DLC04_ValleyDirt "Trash" [STAT:0200CBB4]
        _formsToChange.Add('0200CBB5'); // TrashClump03_DLC04_ValleyGrass "Trash" [STAT:0200CBB5]
        _formsToChange.Add('0200CBBB'); // TrashPileCorIn01_DLC04_ValleyGrass "Trash" [STAT:0200CBBB]
        _formsToChange.Add('0200CBBD'); // TrashPileCorIn01_DLC04_ValleyDirt "Trash" [STAT:0200CBBD]
        _formsToChange.Add('0200CBBE'); // TrashPileWall01_DLC04_ValleyGrass "Trash" [STAT:0200CBBE]
        _formsToChange.Add('0200CBC0'); // TrashPileWall01_DLC04_ValleyDirt "Trash" [STAT:0200CBC0]
        _formsToChange.Add('0200CBC1'); // TrashPileWall02_DLC04_ValleyGrass "Trash" [STAT:0200CBC1]
        _formsToChange.Add('0200CBC3'); // TrashPileWall02_DLC04_ValleyDirt "Trash" [STAT:0200CBC3]
        _formsToChange.Add('0200CBC4'); // TrashPileWall03_DLC04_ValleyGrass "Trash" [STAT:0200CBC4]
        _formsToChange.Add('0200CBC6'); // TrashPileWall03_DLC04_ValleyDirt "Trash" [STAT:0200CBC6]
        _formsToChange.Add('0200CCCD'); // TrashEdge01_DLC04_ValleyDirt "Trash" [STAT:0200CCCD]
        _formsToChange.Add('0200CCDE'); // TrashClump02_DLC04_HillGrass "Trash" [STAT:0200CCDE]
        _formsToChange.Add('0200CCDF'); // TrashClump03_DLC04_HillGrass "Trash" [STAT:0200CCDF]
        _formsToChange.Add('0200CCE0'); // TrashClump01_DLC04_HillGrass "Trash" [STAT:0200CCE0]
        _formsToChange.Add('0200CCE1'); // TrashPileWall01_DLC04_HillGrass "Trash" [STAT:0200CCE1]
        _formsToChange.Add('0200CCE2'); // TrashPileWall02_DLC04_HillGrass "Trash" [STAT:0200CCE2]
        _formsToChange.Add('0200CCE3'); // TrashPileCorIn01_DLC04_HillGrass "Trash" [STAT:0200CCE3]
        _formsToChange.Add('0200CCE4'); // TrashPileWall03_DLC04_HillGrass "Trash" [STAT:0200CCE4]
        _formsToChange.Add('0200CCE5'); // TrashClump02_DLC04_HillDirt "Trash" [STAT:0200CCE5]
        _formsToChange.Add('0200CCE6'); // TrashClump03_DLC04_HillDirt "Trash" [STAT:0200CCE6]
        _formsToChange.Add('0200CCE7'); // TrashClump01_DLC04_HillDirt "Trash" [STAT:0200CCE7]
        _formsToChange.Add('0200CCE8'); // TrashPileWall01_DLC04_HillDirt "Trash" [STAT:0200CCE8]
        _formsToChange.Add('0200CCE9'); // TrashPileCorIn01_DLC04_HillDirt "Trash" [STAT:0200CCE9]
        _formsToChange.Add('0200CCEA'); // TrashPileWall02_DLC04_HillDirt "Trash" [STAT:0200CCEA]
        _formsToChange.Add('0200CCEB'); // TrashPileWall03_DLC04_HillDirt "Trash" [STAT:0200CCEB]
        _formsToChange.Add('0200CCED'); // TrashEdge02_DLC04_ValleyDirt "Trash" [STAT:0200CCED]
        _formsToChange.Add('0200CCEF'); // TrashEdge03_DLC04_ValleyDirt "Trash" [STAT:0200CCEF]
        _formsToChange.Add('0200CCF3'); // TrashEdge04_DLC04_ValleyDirt "Trash" [STAT:0200CCF3]
        _formsToChange.Add('0200CCF8'); // TrashPileCor01_DLC04_ValleyGrass "Trash" [STAT:0200CCF8]
        _formsToChange.Add('0200CCF9'); // TrashPileCor01_DLC04_ValleyDirt "Trash" [STAT:0200CCF9]
        _formsToChange.Add('0200CCFA'); // TrashPileCor01_DLC04_HillGrass "Trash" [STAT:0200CCFA]
        _formsToChange.Add('0200CCFB'); // TrashPileCor01_DLC04_HillDirt "Trash" [STAT:0200CCFB]
        _formsToChange.Add('0200D18C'); // DLC04_DebrisMound02_WetMud "Debris" [STAT:0200D18C]
        _formsToChange.Add('0201DBFF'); // Briar_VinesM01 [STAT:0201DBFF]
        _formsToChange.Add('0201E2D8'); // Briar_VinesS01 [STAT:0201E2D8]
        _formsToChange.Add('02027778'); // BlastedForestVinesCluster02 [STAT:02027778]
        _formsToChange.Add('02027779'); // BlastedForestVinesCorner01 [STAT:02027779]
        _formsToChange.Add('0202777A'); // BlastedForestVinesCorner02 [STAT:0202777A]
        _formsToChange.Add('0202777B'); // BlastedForestVinesHanging03 [STAT:0202777B]
        _formsToChange.Add('0202A18A'); // DLC04_TrashClump01 [STAT:0202A18A]
        _formsToChange.Add('0202B5FF'); // DLC04_TrashClump02 [STAT:0202B5FF]
        _formsToChange.Add('0202B615'); // DLC04_TrashEdge01 [STAT:0202B615]
        _formsToChange.Add('0203F65E'); // GlassDebrisB_DLC04 [STAT:0203F65E]
        _formsToChange.Add('0203F65F'); // GlassDebrisC_DLC04 [STAT:0203F65F]
        _formsToChange.Add('0203F660'); // GlassDebrisA_DLC04 [STAT:0203F660]
                            
        Result := 0;
    end; // end function Initialize

//====================================================================================================================================================
// Main process, goes through each record in the selected file one by one. Takes for fucking ever. Also, single threaded and locks up the UI. sOutput and _exceptionCountMax provided as relief for out of control scripts.
//====================================================================================================================================================
function Process(e: IInterface): Integer;
    var
        a, b, iCellID: Integer; // for iterator, for iterator, cell ID as integer
        parentCell: IInterface; // Parent cell record of e
        sCellID: String; // cell ID as HEX string
    begin
        try                      
            // -------------------------------------------------------------------------------
            // set up plugin and masters
            // -------------------------------------------------------------------------------
            // operate on the last override
            e := WinningOverride(e);

            // create new physical plugin file if it's not there
            if not Assigned(_plugin) then 
            begin
                _plugin := FileByIndex(Pred(FileCount));
                if not Assigned(_plugin) then 
                begin
                    Result := 1;
                    Exit;
                end; // end if
            end; // end if
            
            // add masters
            AddRequiredElementMasters(e, _plugin, False);
            // -------------------------------------------------------------------------------

            // -------------------------------------------------------------------------------
            // Entry Criteria ... Pass or Exit
            // -------------------------------------------------------------------------------
            // skip it if it's not a reference
            if Signature(e) <> 'REFR' then Exit;

            // get the full path, exit if blank.
            _fullPath := FullPath(e);
            if _fullPath = '' then Exit; 

            // get the name, exit if blank.
            _name := Name(e);
            if _name = '' then Exit;
            
            // exclude items located in interior cells
            sCellID := GetElementNativeValues(e, 'CELL');
            sCellID := '$' + sCellID;
            iCellID := StrToInt(sCellID);
            //sCellID := '$' + IntToHex(iCellID, 8);
            if(pos('Fallout4.esm', _fullPath) <> 0) then parentCell := RecordByFormID(FileByIndex(0), iCellID, True); // 0 only works for vanilla fallout ... maybe 1 and 2 are the other respective masters ... we'll find out
            if(pos('DLCCoast.esm', _fullPath) <> 0) then parentCell := RecordByFormID(FileByIndex(1), iCellID, True);
            if(pos('DLCNukaWorld.esm', _fullPath) <> 0) then parentCell := RecordByFormID(FileByIndex(2), iCellID, True);
            if GetElementEditValues(parentCell, 'DATA\Is Interior Cell') = '1' then Exit;

            // Go through the _thingsToIgnore list. If one matches anything in the full path then exit.            
            for a := 0 to _thingsToIgnore.Count - 1 do
            begin
                if pos(_thingsToIgnore.Strings[a], _fullPath) <> 0 then
                begin
                    Exit;
                end // end if
                else 
                begin
                    a := a + 1;
                end; // end else
            end; // end for
            // -------------------------------------------------------------------------------

            // -------------------------------------------------------------------------------
            // Go through the form list. If one matches then place a light there.            
            // -------------------------------------------------------------------------------
            for b := 0 to _formsToChange.Count - 1 do
            begin
                if pos(_formsToChange.Strings[b], _name) <> 0 then
                begin
                    PlaceLight(e);
                    break;
                end // end if
                else 
                begin
                    b := b + 1;
                end; // end else
            end; // end for
            // -------------------------------------------------------------------------------

            Result := 0;
        except
            on Ex: Exception do 
            begin
                sOutput('Exception Caught - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
                sOutput('NAME: ' + _name);
                sOutput('FULL PATH: ' + _fullPath);
                sOutput('REASON: ' + Ex.Message);                
                sOutput('Exception Caught - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
                
                // increment the global exception count
                _exceptionCount := _exceptionCount + 1;

                // cause an index out of bounds error to halt the script since 'halt' seems to be ignored. yes, it's hacky
                if _exceptionCount > _exceptionCountMax then AddMessage(_formsToChange.Strings[99999]); 

                Result := 1;
            end; // end on Ex
        end; // end try/except
    end; // end function Process

//====================================================================================================================================================
// Sort the masters then exit.
//====================================================================================================================================================
function Finalize: integer;
    begin
        if Assigned(_plugin) then SortMasters(_plugin);
        Result := 0;
    end; // end function Finalize

//====================================================================================================================================================
// An output function that limits the output to _outputMax lines then thows an index out of bounds error. Used during debugging since HALT doesn't seem to work. yes, it's hacky
//====================================================================================================================================================
function sOutput(sIn: string): integer;
    var
        sFormat: string;
        asTime : AnsiString;
    begin
        // standard US time format.
        sFormat := 'hh:nn:ss';
        DateTimeToString (asTime, sFormat, Time);
        
        // output with a timestamp
        AddMessage(asTime + ': ' + sIn);
        
        // increment the global record output count
        _recordCount := _recordCount + 1;

        // in ValueFromIndex[#####] make [#####] a hight enough number to cause an index out of bounds error. This will halt the program if the try/catch block doesn't grab it. "halt" by itself seems to be ignored. yes, it's hacky
        if _recordCount > _outputMax then AddMessage(_formsToChange.Strings[99999]); 
    end; // end function sOutput

//====================================================================================================================================================
// Get the position and rotation of each original object, then create a light referencing 'DefaultLightWaterGlowingSea01NSCaustics [LIGH:00204273]' at those coordinates with that rotation.
// We may need to mess with the light density once the placement works. We'll do that by removing the copied lights, then removing entries from _formsToChange and rerunning the script until we get good distribution.
//====================================================================================================================================================
function PlaceLight(e: IInterface): integer;
    var
        newRecord: IInterface; // the new record created in the plugin.
        newLight: IwbElement; // the construct
        sCell: String; // e's current CELL information
        pX, pY, pZ, rX, rY, rZ: Integer; // original position and rotation information of e
    begin        
        // get the X, Y, and Z coordinates of the item as well as the CELL info
        pX := GetElementEditValues(e, 'DATA\Position\X');
        pY := GetElementEditValues(e, 'DATA\Position\Y');
        pZ := GetElementEditValues(e, 'DATA\Position\Z');
        rX := GetElementEditValues(e, 'DATA\Rotation\X');
        rY := GetElementEditValues(e, 'DATA\Rotation\Y');
        rZ := GetElementEditValues(e, 'DATA\Rotation\Z');
        sCell := GetElementEditValues(e, 'CELL');
                        
        // place a green, shimmery light at those coordinates - NAME - Base = DefaultLightWaterGlowingSea01NSCaustics [LIGH:00204273]
        SetElementEditValues(newLight, 'CELL', sCell);                                                      // this needs to be the cell from the original object matching _formsToChange entries' cells (vital!)
        SetElementEditValues(newLight, 'NAME', 'DefaultLightWaterGlowingSea01NSCaustics [LIGH:00204273]');  // if that light doesn't work ... we can pretty much change this to anything. I was thinking the fake cactuses and shrub cutouts from nuka world. or mines ... or traffic cones. we could even make a list to rotate through.
        SetElementEditValues(newLight, 'XRDS', '512');                                                      // we'll start off with this radius and see how well it works.
        SetElementEditValues(newLight, 'XLIG\FOV 90+/-', '0.000000');                                       // not sure what this does. Left at default.
        SetElementEditValues(newLight, 'XLIG\Fade 1.0+/-', '0.000000');                                     // not sure what this does. Left at default.
        SetElementEditValues(newLight, 'XLIG\End Distance Cap', '0.000000');                                // not sure what this does. Left at default.
        SetElementEditValues(newLight, 'XLIG\Shadow Depth Bias', '1.000000');                               // leave this, shadows with this number of lights would kill the framerate or make the game unplayable most likely. (if that's what the param even does)
        SetElementEditValues(newLight, 'XLIG\Near Clip', '0.000000');                                       // not sure what this does. Left at default.
        SetElementEditValues(newLight, 'XLIG\Volumetric Intensity', '0.000000');                            // not sure what this does. Left at default.
        SetElementEditValues(newLight, 'DATA\Position\X', IntToStr(pX));                                    // Use original X position (vital!)
        SetElementEditValues(newLight, 'DATA\Position\Y', IntToStr(pY));                                    // Use original Y position (vital!)
        SetElementEditValues(newLight, 'DATA\Position\Z', IntToStr(pZ + 0.1));                              // move Z up a tad in case we're embedded in the floor, ground, or something.
        SetElementEditValues(newLight, 'DATA\Rotation\X', IntToStr(rX));                                    // use original X rotation. It's a light, but it's not going to hurt anything.
        SetElementEditValues(newLight, 'DATA\Rotation\Y', IntToStr(rY));                                    // use original Y rotation. It's a light, but it's not going to hurt anything.
        SetElementEditValues(newLight, 'DATA\Rotation\Z', IntToStr(rZ));                                    // use original Z rotation. It's a light, but it's not going to hurt anything.

        // copy record as new to plugin
        newRecord := wbCopyElementToFile(newLight, _plugin, True, False);
        
        // If there's anything left to do, we can do it to newRecord. Placement with the above data *should* be enough though.
    end; // end function PlaceLights
end. // end script
