{
    Place a light at the coordinates of each item in each cell that matches anything in _formsToModify but excluding _thingsToIgnore which compares against the full path for exclusion purposes.
}
unit PlaceLights;

// I gave all globals an uncerscore at the beginning for easy identification.
const
    _outputCountMax = 9999999;      // maximum number of times function sOutput can be used before the script exits
    _recordCountMax = 9999999;      // maximum number of records to look through before exiting the script. There are a total of 2,174,970 records between fallout4, nuka world, and far harbor
    _exceptionCountMax = 9999999;   // number of exceptions allowed before we exit the script
    _itemsPlacedMax = 9999999;      // the maximum number of items we'll place before exiting the script.
    _timeFormat = 'hh:nn:ss';       // the format to use with CurrentTime(_timeFormat)
var
    _plugin: IInterface;                                                                // the new plugin
    _fullPath, _name, _signature: String;                                               // the FullPath and the NAME elements
    _thingsToIgnore, _formsToModify: TStringList;                                       // List of words to use to exit, list of base form IDs to be manipulated when they occur in the world.
    _outputCount, _exceptionCount, _recordCount, _recordsFound, _itemsPlaced: Integer;  // current count of sOutput uses and exceptions caught.

//====================================================================================================================================================
// Run once before starting main process.
//====================================================================================================================================================
function Initialize: Integer;
    begin
        // output the start time so we can guage actual script run time ... because fo4edit loses track going over an hour.
        AddMessage(CurrentTime(_timeFormat) + ': Script start');

        // set Result to 0, we can change it to 1 for failures later.
        Result := 0;
        
        // Tally of items actually placed
        _itemsPlaced := 0;

        // Tally of processed records. used in debug output
        _recordsFound := 0;

        // this is the tally of outputs we've done via the sOutput function, used for killing out of control scripts and debugging.
        _outputCount := 0;

        // the tally of exceptions caught in the main loop having used LogException. Used for killing out of control scripts and debugging.
        _exceptionCount := 0;

        // the tally of records we've looked at
        _recordCount := 0;
        
        // these strings will be compared to the full path, if they occur then the script will reject the record for processing.
        _thingsToIgnore := TStringList.Create;
        _thingsToIgnore.NameValueSeparator := ',';
        _thingsToIgnore.Duplicates := dupIgnore;
        _thingsToIgnore.Sorted := False;
        // _thingsToIgnore.Add(' Interior ');       // ignore Interior cells
        // _thingsToIgnore.Add(' interior ');       // ignore interior cells
        _thingsToIgnore.Add('SanctuaryHillsWorld'); // ignore prewar sanctuary
        _thingsToIgnore.Add('DiamondCityFX');       // skip whatever this place is
        _thingsToIgnore.Add('TestMadCoast');        // leave TestMadCoast alone
        _thingsToIgnore.Add('TestClaraCoast');      // leave TestClaraCoast alone
        _thingsToIgnore.Add('DLC03VRWorldspace');   // Dima's head is off limits
        _thingsToIgnore.Add('TestMadWorld');        // leave TestMadWorld alone
        
        // these form IDs are compared against the NAME of every reference in every cell. If there is a match (after exlusion) then the record is accepted for processing.
        // Everything caused too many lights and crashes, reducing to just trees and vines.
        _formsToModify := TStringList.Create;
        _formsToModify.NameValueSeparator := ',';
        _formsToModify.Duplicates := dupIgnore;
        _formsToModify.Sorted := False;
        _formsToModify.Add('00019570');	// BranchPileStumpRocks01 "Branch Pile" [SCOL:00019570],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00019570.NIF
		_formsToModify.Add('00019572');	// BranchPileStumpVines01 "Branch Pile" [SCOL:00019572],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00019572.NIF
		_formsToModify.Add('0002442F');	// DirtSlope01RootsStumps_ForestFloor [SCOL:0002442F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0002442F.NIF
		_formsToModify.Add('00026FEA');	// TreeScrubVines03 "Trees" [SCOL:00026FEA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00026FEA.NIF
		_formsToModify.Add('0002716E');	// TreeLeanScrub01 "Trees" [SCOL:0002716E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0002716E.NIF
		_formsToModify.Add('00027785');	// TreeLeanScrub03 "Trees" [SCOL:00027785],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00027785.NIF
		_formsToModify.Add('0002C7AC');	// TreeLeanCluster01 "Trees" [SCOL:0002C7AC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0002C7AC.NIF
		_formsToModify.Add('0002C7AF');	// TreeClusterVines01 "Tree Cluster" [SCOL:0002C7AF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0002C7AF.NIF
		_formsToModify.Add('0002C7B3');	// TreeLeanDead01 "Trees" [SCOL:0002C7B3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0002C7B3.NIF
		_formsToModify.Add('0002C808');	// TreeLeanScrub02 "Trees" [SCOL:0002C808],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0002C808.NIF
		_formsToModify.Add('00031A08');	// TreeLeanScrub04 "Trees" [SCOL:00031A08],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00031A08.NIF
		_formsToModify.Add('00031A0A');	// TreeLeanScrub05 "Trees" [SCOL:00031A0A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00031A0A.NIF
		_formsToModify.Add('00031A0D');	// TreeLeanScrub06 "Trees" [SCOL:00031A0D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00031A0D.NIF
		_formsToModify.Add('00031A0E');	// TreeLeanScrub07 "Trees" [SCOL:00031A0E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00031A0E.NIF
		_formsToModify.Add('00031A10');	// TreeScrubVines01 "Trees" [SCOL:00031A10],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00031A10.NIF
		_formsToModify.Add('00031A11');	// TreeScrubVines02 "Trees" [SCOL:00031A11],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00031A11.NIF
		_formsToModify.Add('00032028');	// TreeScrubVines04 "Trees" [SCOL:00032028],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00032028.NIF
		_formsToModify.Add('000321AE');	// TreeLeanScrub08 "Trees" [SCOL:000321AE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000321AE.NIF
		_formsToModify.Add('00034F55');	// BranchPileStump01 "Branch Pile" [SCOL:00034F55],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00034F55.NIF
		_formsToModify.Add('00035813');	// TreeCluster04 "Tree Cluster" [SCOL:00035813],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00035813.NIF
		_formsToModify.Add('0003581A');	// TreeCluster05 "Tree Cluster" [SCOL:0003581A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0003581A.NIF
		_formsToModify.Add('0003581C');	// TreeLeanCluster02 "Trees" [SCOL:0003581C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0003581C.NIF
		_formsToModify.Add('00035871');	// TreeCluster03 "Tree Cluster" [SCOL:00035871],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00035871.NIF
		_formsToModify.Add('00035887');	// TreeCluster01 "Tree Cluster" [SCOL:00035887],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00035887.NIF
		_formsToModify.Add('0003589F');	// TreeCluster07 "Tree Cluster" [SCOL:0003589F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0003589F.NIF
		_formsToModify.Add('000358D1');	// TreeCluster02 "Tree Cluster" [SCOL:000358D1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000358D1.NIF
		_formsToModify.Add('000358D6');	// TreeCluster06 "Tree Cluster" [SCOL:000358D6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000358D6.NIF
		_formsToModify.Add('000393E9');	// BranchPile02 "Maple Branches" [SCOL:000393E9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000393E9.NIF
		_formsToModify.Add('00039709');	// TreeClusterTall01 [SCOL:00039709],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00039709.NIF
		_formsToModify.Add('0003E000');	// TreeCluster08 "Tree Cluster" [SCOL:0003E000],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0003E000.NIF
		_formsToModify.Add('00046E61');	// TreeLeanDead02 "Trees" [SCOL:00046E61],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00046E61.NIF
		_formsToModify.Add('00046E62');	// TreeLeanDead03 "Trees" [SCOL:00046E62],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00046E62.NIF
		_formsToModify.Add('00046E63');	// TreeLeanDead04 "Trees" [SCOL:00046E63],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00046E63.NIF
		_formsToModify.Add('00046E64');	// TreeClusterDead01 "Tree Cluster" [SCOL:00046E64],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00046E64.NIF
		_formsToModify.Add('00046E65');	// TreeLeanDead05 "Trees" [SCOL:00046E65],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00046E65.NIF
		_formsToModify.Add('00046E66');	// TreeCluster09 "Tree Cluster" [SCOL:00046E66],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00046E66.NIF
		_formsToModify.Add('00046E6F');	// TreeLeanDead06 "Trees" [SCOL:00046E6F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00046E6F.NIF
		_formsToModify.Add('0004C1B5');	// DirtSlope01RootsStumps_RootsEroded01 [SCOL:0004C1B5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0004C1B5.NIF
		_formsToModify.Add('00056270');	// ElectricalTowerVines01 [SCOL:00056270],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00056270.NIF
		_formsToModify.Add('00056271');	// ElectricalTowerVines02 [SCOL:00056271],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00056271.NIF
		_formsToModify.Add('00056274');	// ElectricalTowerVines03 [SCOL:00056274],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00056274.NIF
		_formsToModify.Add('0005E20C');	// TreeClusterDead02 "Tree Cluster" [SCOL:0005E20C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0005E20C.NIF
		_formsToModify.Add('0005E20D');	// TreeClusterDead03 "Tree Cluster" [SCOL:0005E20D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0005E20D.NIF
		_formsToModify.Add('0005E20E');	// TreeClusterDead04 "Tree Cluster" [SCOL:0005E20E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0005E20E.NIF
		_formsToModify.Add('0006477D');	// BranchPile03 "Maple Branches" [SCOL:0006477D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0006477D.NIF
		_formsToModify.Add('0002F81A');	// REObjectDL01TrashPile [SCOL:0002F81A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0002F81A.NIF
		_formsToModify.Add('00077DDE');	// ConcordTrashPile01 [SCOL:00077DDE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DDE.NIF
		_formsToModify.Add('00077DE8');	// ConcordTrashPile02 [SCOL:00077DE8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DE8.NIF
		_formsToModify.Add('00077DEA');	// ConcordTrashPile03 [SCOL:00077DEA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DEA.NIF
		_formsToModify.Add('00077DEE');	// ConcordTrashPile05 [SCOL:00077DEE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DEE.NIF
		_formsToModify.Add('00077DF0');	// ConcordTrashPile06 [SCOL:00077DF0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DF0.NIF
		_formsToModify.Add('00077DF2');	// ConcordTrashPile07 [SCOL:00077DF2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DF2.NIF
		_formsToModify.Add('00077DF9');	// ConcordTrashPile08 [SCOL:00077DF9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DF9.NIF
		_formsToModify.Add('00077DFB');	// ConcordTrashPile09 [SCOL:00077DFB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DFB.NIF
		_formsToModify.Add('00077DFF');	// ConcordTrashPile10 [SCOL:00077DFF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077DFF.NIF
		_formsToModify.Add('00077E10');	// ConcordTrashPile11 [SCOL:00077E10],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00077E10.NIF
		_formsToModify.Add('000D245D');	// DirtSlope02_NF_Roots01_Roots [SCOL:000D245D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000D245D.NIF
		_formsToModify.Add('00134638');	// TreeBlastedForestClusterFallen01 "Fallen Trees" [SCOL:00134638],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00134638.NIF
		_formsToModify.Add('0013463A');	// TreeBlastedForestCluster01 "Trees" [SCOL:0013463A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0013463A.NIF
		_formsToModify.Add('0013463C');	// TreeBlastedForestCluster02 "Trees" [SCOL:0013463C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0013463C.NIF
		_formsToModify.Add('0013463E');	// TreeBlastedForestCluster03 "Trees" [SCOL:0013463E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0013463E.NIF
		_formsToModify.Add('00134641');	// TreeBlastedForestCluster04 "Trees" [SCOL:00134641],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00134641.NIF
		_formsToModify.Add('00135CF7');	// TreeBlastedForestCluster05 "Trees" [SCOL:00135CF7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM00135CF7.NIF
		_formsToModify.Add('0014825D');	// TreeForestCluster01 [SCOL:0014825D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014825D.NIF
		_formsToModify.Add('0014B7C1');	// TreeForestCluster02 [SCOL:0014B7C1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014B7C1.NIF
		_formsToModify.Add('0014B7C3');	// TreeForestCluster03 [SCOL:0014B7C3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014B7C3.NIF
		_formsToModify.Add('0014EC0A');	// TreeClusterDestroyedFallen01 [SCOL:0014EC0A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014EC0A.NIF
		_formsToModify.Add('0014EC0B');	// TreeClusterDestroyedFallen02 [SCOL:0014EC0B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014EC0B.NIF
		_formsToModify.Add('0014EC0C');	// TreeClusterDestroyedFallen03 [SCOL:0014EC0C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014EC0C.NIF
		_formsToModify.Add('0014F6C7');	// TreeClusterGSFallen01 [SCOL:0014F6C7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014F6C7.NIF
		_formsToModify.Add('0014F6C9');	// TreeClusterGSFallen02 [SCOL:0014F6C9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014F6C9.NIF
		_formsToModify.Add('0014F6CA');	// TreeClusterGSFallen03 [SCOL:0014F6CA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0014F6CA.NIF
		_formsToModify.Add('000BBD3F');	// Tree_NF_Cluster01 [SCOL:000BBD3F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD3F.NIF
		_formsToModify.Add('000BBD43');	// Tree_NF_Cluster02 [SCOL:000BBD43],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD43.NIF
		_formsToModify.Add('000BBD45');	// Tree_NF_Cluster03 [SCOL:000BBD45],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD45.NIF
		_formsToModify.Add('000BBD48');	// Tree_NF_FallenCluster01 [SCOL:000BBD48],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD48.NIF
		_formsToModify.Add('000BBD4B');	// Tree_NF_Cluster04 [SCOL:000BBD4B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD4B.NIF
		_formsToModify.Add('000BBD4E');	// Tree_NF_Cluster05 [SCOL:000BBD4E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD4E.NIF
		_formsToModify.Add('000BBD50');	// Tree_NF_FallenCluster02 [SCOL:000BBD50],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD50.NIF
		_formsToModify.Add('000BBD52');	// Tree_NF_FallenCluster03 [SCOL:000BBD52],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD52.NIF
		_formsToModify.Add('000BBD55');	// Tree_NF_FallenCluster04 [SCOL:000BBD55],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD55.NIF
		_formsToModify.Add('000BBD58');	// Tree_NF_Cluster06 [SCOL:000BBD58],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD58.NIF
		_formsToModify.Add('000BBD62');	// Tree_NF_Cluster07 [SCOL:000BBD62],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD62.NIF
		_formsToModify.Add('000BBD64');	// Tree_NF_FallenCluster05 [SCOL:000BBD64],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BBD64.NIF
		_formsToModify.Add('000BD5C0');	// Tree_NF_RockGroundCluster01 [SCOL:000BD5C0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BD5C0.NIF
		_formsToModify.Add('000BD5C2');	// Tree_NF_RockGroundCluster02 [SCOL:000BD5C2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000BD5C2.NIF
		_formsToModify.Add('000D09BA');	// CITTrashPile01 [SCOL:000D09BA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000D09BA.NIF
		_formsToModify.Add('000D09BC');	// CITTrashPile02 [SCOL:000D09BC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000D09BC.NIF
		_formsToModify.Add('000D09BE');	// CITTrashPile03 [SCOL:000D09BE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000D09BE.NIF
		_formsToModify.Add('000D7D7C');	// CITLeafPile01 [SCOL:000D7D7C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM000D7D7C.NIF
		_formsToModify.Add('0016B7DC');	// DN76Ship1TrashStaticCollection [SCOL:0016B7DC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0016B7DC.NIF
		_formsToModify.Add('0016B914');	// DN76Ship8TrashStaticCollection [SCOL:0016B914],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0016B914.NIF
		_formsToModify.Add('0019B595');	// CafeTable01Debris01 [SCOL:0019B595],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0019B595.NIF
		_formsToModify.Add('0019B597');	// CafeTable01Debris02 [SCOL:0019B597],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0019B597.NIF
		_formsToModify.Add('0019B599');	// CafeTable01Debris03 [SCOL:0019B599],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0019B599.NIF
		_formsToModify.Add('0019B59B');	// CafeTable02Debris01 [SCOL:0019B59B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0019B59B.NIF
		_formsToModify.Add('0019B59D');	// CafeTable02Debris02 [SCOL:0019B59D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0019B59D.NIF
		_formsToModify.Add('0019B59F');	// CafeTable03Debris01 [SCOL:0019B59F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM0019B59F.NIF
		_formsToModify.Add('001ED560');	// HWOnRampEndCapCurveR01SCVine01 [SCOL:001ED560],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM001ED560.NIF
		_formsToModify.Add('001ED561');	// HWOnRampEndCapCurveL01SCVine01 [SCOL:001ED561],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM001ED561.NIF
		_formsToModify.Add('001ED566');	// HWOnRampStrFree01SCVine01 [SCOL:001ED566],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\Fallout4.esm\CM001ED566.NIF
		_formsToModify.Add('000393CD');	// TreeBlasted02 "Tree" [STAT:000393CD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted02.nif
		_formsToModify.Add('000372D4');	// ForestRoots01 [STAT:000372D4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\ForestRoots01.nif
		_formsToModify.Add('000372D6');	// ForestRoots02 [STAT:000372D6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\ForestRoots02.nif
		_formsToModify.Add('00038599');	// TreeBlasted01 "Tree" [STAT:00038599],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted01.nif
		_formsToModify.Add('00032464');	// TreeStump01 "Stump" [STAT:00032464],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStump01.nif
		_formsToModify.Add('00032936');	// TreeStump02 "Stump" [STAT:00032936],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStump02.nif
		_formsToModify.Add('00033F54');	// TreeStump03 "Stump" [STAT:00033F54],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStump03.nif
		_formsToModify.Add('000299B3');	// TreeLog01 "Maple Log" [STAT:000299B3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLog01.nif
		_formsToModify.Add('0002A620');	// TreeLog02 "Maple Log" [STAT:0002A620],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLog02.nif
		_formsToModify.Add('0002B8DB');	// TreefallenBranch01 "Branch" [STAT:0002B8DB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreefallenBranch01.nif
		_formsToModify.Add('0001E95B');	// DebrisInteriorWoodPileBg04 [STAT:0001E95B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileBg04.nif
		_formsToModify.Add('0001E957');	// DebrisInteriorWoodPile03Trash [STAT:0001E957],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile03Trash.nif
		_formsToModify.Add('0001E953');	// DebrisInteriorWoodPile01Trash [STAT:0001E953],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile01Trash.nif
		_formsToModify.Add('0001E94F');	// DebrisInteriorWoodPileSm03 [STAT:0001E94F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileSm03.nif
		_formsToModify.Add('0001D907');	// DebrisWoodPileSm05 [STAT:0001D907],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPileSm05.nif
		_formsToModify.Add('0001D8FB');	// DebrisWoodPile03Trash [STAT:0001D8FB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile03Trash.nif
		_formsToModify.Add('0001D8F7');	// DebrisWoodPile01Trash [STAT:0001D8F7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile01Trash.nif
		_formsToModify.Add('0001D8F3');	// DebrisWoodPile04Trash [STAT:0001D8F3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile04Trash.nif
		_formsToModify.Add('0001D1C7');	// DebrisPile04 [STAT:0001D1C7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile04.nif
		_formsToModify.Add('0001D1AF');	// TrashDecal03 [STAT:0001D1AF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashDecal03.nif
		_formsToModify.Add('0001D191');	// DebrisPile03 [STAT:0001D191],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile03.nif
		_formsToModify.Add('0001D17F');	// DebrisPile01Dirt [STAT:0001D17F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile01Dirt.nif
		_formsToModify.Add('0001D166');	// DebrisPile01 [STAT:0001D166],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile01.nif
		_formsToModify.Add('0001D181');	// DebrisPile02 [STAT:0001D181],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile02.nif
		_formsToModify.Add('0001D184');	// TrashDecal01 [STAT:0001D184],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashDecal01.nif
		_formsToModify.Add('0001D18E');	// TrashDecal02 [STAT:0001D18E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashDecal02.nif
		_formsToModify.Add('0001D199');	// DebrisPile02Trash [STAT:0001D199],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile02Trash.nif
		_formsToModify.Add('0001D1A0');	// DebrisPile01Trash [STAT:0001D1A0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile01Trash.nif
		_formsToModify.Add('0001D1A6');	// DebrisPileRoad01Trash [STAT:0001D1A6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPileRoad01Trash.nif
		_formsToModify.Add('0001D1B5');	// TrashDecal04 [STAT:0001D1B5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashDecal04.nif
		_formsToModify.Add('0001D1BA');	// DebrisPile03Trash [STAT:0001D1BA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile03Trash.nif
		_formsToModify.Add('0001D1C3');	// TrashDecal05 [STAT:0001D1C3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashDecal05.nif
		_formsToModify.Add('0001D1CF');	// DebrisPile04Trash [STAT:0001D1CF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPile04Trash.nif
		_formsToModify.Add('0001D549');	// DebrisPileRoad02Trash [STAT:0001D549],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisPileRoad02Trash.nif
		_formsToModify.Add('0001D8F4');	// DebrisWoodPileRoad01Trash [STAT:0001D8F4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPileRoad01Trash.nif
		_formsToModify.Add('0001D8F5');	// DebrisWoodPileRoad02Trash [STAT:0001D8F5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPileRoad02Trash.nif
		_formsToModify.Add('0001D8F6');	// DebrisWoodPile01 [STAT:0001D8F6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile01.nif
		_formsToModify.Add('0001D8F8');	// DebrisWoodPile02 [STAT:0001D8F8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile02.nif
		_formsToModify.Add('0001D8F9');	// DebrisWoodPile02Trash [STAT:0001D8F9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile02Trash.nif
		_formsToModify.Add('0001D8FA');	// DebrisWoodPile03 [STAT:0001D8FA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile03.nif
		_formsToModify.Add('0001D8FC');	// DebrisWoodPile04 [STAT:0001D8FC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPile04.nif
		_formsToModify.Add('0001D905');	// DebrisWoodPileSm03 [STAT:0001D905],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPileSm03.nif
		_formsToModify.Add('0001D906');	// DebrisWoodPileSm04 [STAT:0001D906],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPileSm04.nif
		_formsToModify.Add('0001D908');	// DebrisWoodPileSm01 [STAT:0001D908],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPileSm01.nif
		_formsToModify.Add('0001D909');	// DebrisWoodPileSm02 [STAT:0001D909],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisWoodPileSm02.nif
		_formsToModify.Add('0001E94D');	// DebrisInteriorWoodPileSm01 [STAT:0001E94D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileSm01.nif
		_formsToModify.Add('0001E94E');	// DebrisInteriorWoodPileSm02 [STAT:0001E94E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileSm02.nif
		_formsToModify.Add('0001E950');	// DebrisInteriorWoodPileSm04 [STAT:0001E950],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileSm04.nif
		_formsToModify.Add('0001E951');	// DebrisInteriorWoodPileSm05 [STAT:0001E951],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileSm05.nif
		_formsToModify.Add('0001E952');	// DebrisInteriorWoodPile01 [STAT:0001E952],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile01.nif
		_formsToModify.Add('0001E954');	// DebrisInteriorWoodPile02 [STAT:0001E954],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile02.nif
		_formsToModify.Add('0001E955');	// DebrisInteriorWoodPile02Trash [STAT:0001E955],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile02Trash.nif
		_formsToModify.Add('0001E956');	// DebrisInteriorWoodPile03 [STAT:0001E956],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile03.nif
		_formsToModify.Add('0001E958');	// DebrisInteriorWoodPile04 [STAT:0001E958],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile04.nif
		_formsToModify.Add('0001E959');	// DebrisInteriorWoodPile04Trash [STAT:0001E959],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPile04Trash.nif
		_formsToModify.Add('0001E95A');	// DebrisInteriorWoodPileBg03 [STAT:0001E95A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileBg03.nif
		_formsToModify.Add('0001E95C');	// DebrisInteriorWoodPileBg01 [STAT:0001E95C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileBg01.nif
		_formsToModify.Add('0001E95D');	// DebrisInteriorWoodPileBg02 [STAT:0001E95D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileBg02.nif
		_formsToModify.Add('0001E95F');	// DebrisInteriorWoodPileBg05 [STAT:0001E95F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DebrisInteriorWoodPileBg05.nif
		_formsToModify.Add('00001B58');	// DecalDebris01 [STAT:00001B58],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DecalDebrise01.nif
		_formsToModify.Add('00001B56');	// DecalDebris03 [STAT:00001B56],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DecalDebrise03.nif
		_formsToModify.Add('00001B54');	// RubChunkiesSmall02 [STAT:00001B54],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\RubChunkiesSmall02.nif
		_formsToModify.Add('00000005');	// DivineMarker [STAT:00000005],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Marker_Divine.nif
		_formsToModify.Add('00001B55');	// RubChunkiesSmall01 [STAT:00001B55],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\RubChunkiesSmall01.nif
		_formsToModify.Add('00001B57');	// DecalDebris02 [STAT:00001B57],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DecalDebrise02.nif
		_formsToModify.Add('00039BF1');	// TreeBlasted03 "Tree" [STAT:00039BF1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted03.nif
		_formsToModify.Add('0003A053');	// ForestRoots03 [STAT:0003A053],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\ForestRoots03.nif
		_formsToModify.Add('0003A054');	// ForestRoots04 [STAT:0003A054],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\ForestRoots04.nif
		_formsToModify.Add('0003A055');	// ForestRoots05 [STAT:0003A055],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\ForestRoots05.nif
		_formsToModify.Add('0003A9F2');	// OfficePaperDebris01 [STAT:0003A9F2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Office\OfficePaperDebris01.nif
		_formsToModify.Add('00045618');	// TreeStump04 "Stump" [STAT:00045618],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStump04.nif
		_formsToModify.Add('000457C2');	// VineHanging01 [STAT:000457C2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging01.nif
		_formsToModify.Add('000457C3');	// VineHanging02 [STAT:000457C3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging02.nif
		_formsToModify.Add('000457C4');	// VineHanging03 [STAT:000457C4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging03.nif
		_formsToModify.Add('00047E39');	// VineDecalCorner01 [STAT:00047E39],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperCorner01.nif
		_formsToModify.Add('00047E3A');	// VineDecalCorner02 [STAT:00047E3A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperCorner02.nif
		_formsToModify.Add('00047E3B');	// VineDecalLarge01 [STAT:00047E3B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperLarge01.nif
		_formsToModify.Add('00047E3C');	// VineDecalLarge02 [STAT:00047E3C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperLarge02.nif
		_formsToModify.Add('00047E3D');	// VineDecalLarge03 [STAT:00047E3D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperLarge03.nif
		_formsToModify.Add('00047E3E');	// VineDecalMed01 [STAT:00047E3E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperMed01.nif
		_formsToModify.Add('00047E3F');	// VineDecalMed02 [STAT:00047E3F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperMed02.nif
		_formsToModify.Add('00048BAB');	// VineDecalMed03 [STAT:00048BAB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperMed03.nif
		_formsToModify.Add('00048BAC');	// VineDecalSmall01 [STAT:00048BAC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperSmall01.nif
		_formsToModify.Add('00048BAD');	// VineDecalSmall02 [STAT:00048BAD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperSmall02.nif
		_formsToModify.Add('00048BAE');	// VineDecalSmall03 [STAT:00048BAE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperSmall03.nif
		_formsToModify.Add('00048BAF');	// VineDecalXSmall01 [STAT:00048BAF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperXSmall01.nif
		_formsToModify.Add('00048BB0');	// VineDecalXSmall02 [STAT:00048BB0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperXSmall02.nif
		_formsToModify.Add('00048BB1');	// VineHanging04 [STAT:00048BB1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging04.nif
		_formsToModify.Add('00048BB2');	// VineHanging05 [STAT:00048BB2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging05.nif
		_formsToModify.Add('00048BB3');	// VineHanging06 [STAT:00048BB3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging06.nif
		_formsToModify.Add('00048BB4');	// VineHangingLarge01 [STAT:00048BB4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHangingLarge01.nif
		_formsToModify.Add('00048BB5');	// VineHangingLarge02 [STAT:00048BB5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHangingLarge02.nif
		_formsToModify.Add('00049532');	// TreeBlasted04 "Tree" [STAT:00049532],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted04.nif
		_formsToModify.Add('00049C5D');	// DirtSlope02_Roots01 [STAT:00049C5D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope02.nif
		_formsToModify.Add('0004A071');	// TreeMapleForest5 "Maple Tree" [STAT:0004A071],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForest5.nif
		_formsToModify.Add('0004A072');	// TreeMapleForest6 "Maple Tree" [STAT:0004A072],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForest6.nif
		_formsToModify.Add('0004A073');	// TreeMapleForest1 "Maple Tree" [STAT:0004A073],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForest1.nif
		_formsToModify.Add('0004A074');	// TreeMapleForest2 "Maple Tree" [STAT:0004A074],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForest2.nif
		_formsToModify.Add('0004A075');	// TreeMapleForest3 "Maple Tree" [STAT:0004A075],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForest3.nif
		_formsToModify.Add('0004A076');	// TreeMapleForest4 "Maple Tree" [STAT:0004A076],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForest4.nif
		_formsToModify.Add('0004C901');	// VineGround01 [STAT:0004C901],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineGround01.nif
		_formsToModify.Add('0004C902');	// VineGround02 [STAT:0004C902],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineGround02.nif
		_formsToModify.Add('0004D320');	// VineHanging07 [STAT:0004D320],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging07.nif
		_formsToModify.Add('0004D322');	// VineHanging08 [STAT:0004D322],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging08.nif
		_formsToModify.Add('0004D93B');	// TreeMapleblasted01 "Maple Tree" [STAT:0004D93B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted01.nif
		_formsToModify.Add('000503B6');	// TreeMapleblasted02 "Maple Tree" [STAT:000503B6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted02.nif
		_formsToModify.Add('000516A3');	// BranchPileBark01 "Maple Bark" [STAT:000516A3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBranchPile01.nif
		_formsToModify.Add('000521BB');	// TreeMapleblasted03 "Maple Trunk" [STAT:000521BB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted03.nif
		_formsToModify.Add('00052A19');	// TreeRoots01 [STAT:00052A19],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeRoots01.nif
		_formsToModify.Add('00052A1E');	// TreeRoots02 [STAT:00052A1E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeRoots02.nif
		_formsToModify.Add('00052A20');	// TreeRoots03 [STAT:00052A20],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeRoots03.nif
		_formsToModify.Add('000531AE');	// TreeMapleblasted04 "Maple Tree" [STAT:000531AE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted04.nif
		_formsToModify.Add('000531B3');	// TreeMapleblasted05 "Maple Tree" [STAT:000531B3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted05.nif
		_formsToModify.Add('000531BC');	// TreeMapleblasted06 "Maple Trunk" [STAT:000531BC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted06.nif
		_formsToModify.Add('0005325A');	// BranchPileBark02 "Tree" [STAT:0005325A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBranchPile02.nif
		_formsToModify.Add('0005325E');	// BranchPile01 "Maple Branches" [STAT:0005325E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBranchPile03.nif
		_formsToModify.Add('00053262');	// TreefallenBranch02 "Branch" [STAT:00053262],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreefallenBranch02.nif
		_formsToModify.Add('000542F4');	// TreeRoots04 [STAT:000542F4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeRoots04.nif
		_formsToModify.Add('00055D13');	// TreeRoots05 [STAT:00055D13],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeRoots05.nif
		_formsToModify.Add('0003A28B');	// TreeHero01 [STAT:0003A28B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeHero01.nif
		_formsToModify.Add('0003E08D');	// TreeBlasted05 "Tree" [STAT:0003E08D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted05.nif
		_formsToModify.Add('0003E08F');	// TreeMapleblasted07 "Maple Tree" [STAT:0003E08F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted07.nif
		_formsToModify.Add('0003E0D1');	// TreeMapleForest7 "Maple Tree" [STAT:0003E0D1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForest7.nif
		_formsToModify.Add('0004C1B2');	// DirtSlope01_Roots01 [STAT:0004C1B2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('00056BD6');	// DirtSlope01_Roots01Dirt [STAT:00056BD6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('000585A8');	// LeafPile01 [STAT:000585A8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\LeafPile01.nif
		_formsToModify.Add('000585AA');	// LeafPile02 [STAT:000585AA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\LeafPile02.nif
		_formsToModify.Add('000585AB');	// LeafPile03 [STAT:000585AB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\LeafPile03.nif
		_formsToModify.Add('00059AA1');	// VineTree01 [STAT:00059AA1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineTree01.nif
		_formsToModify.Add('00059AAE');	// VineTree02 [STAT:00059AAE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineTree02.nif
		_formsToModify.Add('0005A480');	// LeafPile04 [STAT:0005A480],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\LeafPile04.nif
		_formsToModify.Add('0005C21E');	// VineGround03 [STAT:0005C21E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineGround03.nif
		_formsToModify.Add('0005C221');	// VineHangingLarge03 [STAT:0005C221],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHangingLarge03.nif
		_formsToModify.Add('0005C223');	// VineShrub01 [STAT:0005C223],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineShrub01.nif
		_formsToModify.Add('0005C229');	// VineHanging09 [STAT:0005C229],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging09.nif
		_formsToModify.Add('0006C6D0');	// TreeMapleForestsmall1 "Maple Tree" [STAT:0006C6D0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForestsmall1.nif
		_formsToModify.Add('0006C6D2');	// TreeMapleForestsmall2 "Maple Tree" [STAT:0006C6D2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForestsmall2.nif
		_formsToModify.Add('0006C6D4');	// TreeMapleForestsmall3 "Maple Tree" [STAT:0006C6D4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleForestsmall3.nif
		_formsToModify.Add('0006FA34');	// TreeBlastedM01 "Stump" [STAT:0006FA34],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlastedM01.nif
		_formsToModify.Add('000713E1');	// TreeBlastedM04 "Tree" [STAT:000713E1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlastedM04.nif
		_formsToModify.Add('000713E2');	// TreeBlastedM03 "Tree" [STAT:000713E2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlastedM03.nif
		_formsToModify.Add('000713E3');	// TreeBlastedM02 "Tree" [STAT:000713E3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlastedM02.nif
		_formsToModify.Add('00072DC6');	// TreeHero01_LOD [STAT:00072DC6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\LOD\Landscape\Trees\TreeHero01_LOD.nif
		_formsToModify.Add('000787EF');	// TreeClustermMound02temp [STAT:000787EF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster02.nif
		_formsToModify.Add('0007ED8B');	// DebrisPileLargeWood04 [STAT:0007ED8B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood04.nif
		_formsToModify.Add('0007ED8C');	// DebrisPileLargeWood05 [STAT:0007ED8C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood05.nif
		_formsToModify.Add('0007ED8D');	// DebrisPileLargeWood06 [STAT:0007ED8D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood06.nif
		_formsToModify.Add('0007ED8E');	// DebrisPileLargeWood01 [STAT:0007ED8E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood01.nif
		_formsToModify.Add('0007ED8F');	// DebrisPileLargeWood02 [STAT:0007ED8F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood02.nif
		_formsToModify.Add('0007ED90');	// DebrisPileLargeWood03 [STAT:0007ED90],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood03.nif
		_formsToModify.Add('0008029B');	// DebrisPileSmallWood03 [STAT:0008029B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallWood03.nif
		_formsToModify.Add('0008029C');	// DebrisPileSmallWood04 [STAT:0008029C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallWood04.nif
		_formsToModify.Add('0008029D');	// DebrisPileSmallWood05 [STAT:0008029D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallWood05.nif
		_formsToModify.Add('0008029E');	// DebrisPileSmallWood01 [STAT:0008029E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallWood01.nif
		_formsToModify.Add('0008029F');	// DebrisPileSmallWood02 [STAT:0008029F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallWood02.nif
		_formsToModify.Add('0008407B');	// TreeSwing_RopePile01 [STAT:0008407B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\TreeSwing_RopePile01.nif
		_formsToModify.Add('0008407F');	// TreeSwing03_NoSwing [STAT:0008407F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\TreeSwing03_NoSwing.nif
		_formsToModify.Add('00084080');	// TreeSwing_Grounded01 [STAT:00084080],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\TreeSwing_Grounded01.nif
		_formsToModify.Add('00089338');	// HitSmHallDebrisPile01 [STAT:00089338],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitSmHallDebrisPile01.nif
		_formsToModify.Add('0008933B');	// HitDebrisPile01 [STAT:0008933B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPile01.nif
		_formsToModify.Add('0008933C');	// HitDebrisPileFlat01 [STAT:0008933C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileFlat01.nif
		_formsToModify.Add('0008933E');	// HitDebrisPileTiles01 [STAT:0008933E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileTiles01.nif
		_formsToModify.Add('00089350');	// HitSmHallDebrisPile02 [STAT:00089350],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitSmHallDebrisPile02.nif
		_formsToModify.Add('00089359');	// HitSmRoomDebrisPile01 [STAT:00089359],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitSmRoomDebrisPile01.nif
		_formsToModify.Add('0008935A');	// HitSmRoomDebrisPile02 [STAT:0008935A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitSmRoomDebrisPile02.nif
		_formsToModify.Add('00089365');	// HitLgRoomDebrisPile01 [STAT:00089365],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitLgRoomDebrisPile01.nif
		_formsToModify.Add('00089366');	// HitLgRoomDebrisPile02 [STAT:00089366],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitLgRoomDebrisPile02.nif
		_formsToModify.Add('0008954A');	// TrashClump01 [STAT:0008954A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0008954E');	// TrashClump02 [STAT:0008954E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0008A5D7');	// TrashEdge01 [STAT:0008A5D7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge01.nif
		_formsToModify.Add('0008A5E0');	// TrashEdge02 [STAT:0008A5E0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge02.nif
		_formsToModify.Add('0008B5F5');	// TrashPileWall02 [STAT:0008B5F5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02.nif
		_formsToModify.Add('0008B5F6');	// TrashPileWall01 [STAT:0008B5F6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('0008B5FD');	// TrashEdge03 [STAT:0008B5FD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge03.nif
		_formsToModify.Add('0008B604');	// TrashPileCor01 [STAT:0008B604],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCor01.nif
		_formsToModify.Add('0008B617');	// TrashPileWall03 [STAT:0008B617],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('0008B618');	// TrashEdge04 [STAT:0008B618],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge04.nif
		_formsToModify.Add('0008B648');	// TrashPileCorIn01 [STAT:0008B648],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('0008B671');	// TrashClump03 [STAT:0008B671],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('0008C803');	// DebrisPileSmallConc01 [STAT:0008C803],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallConc01.nif
		_formsToModify.Add('0008C804');	// DebrisPileSmallConc02 [STAT:0008C804],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallConc02.nif
		_formsToModify.Add('0008C805');	// DebrisPileSmallConc03 [STAT:0008C805],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallConc03.nif
		_formsToModify.Add('0008C806');	// DebrisPileSmallConc04 [STAT:0008C806],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallConc04.nif
		_formsToModify.Add('0008C807');	// DebrisPileSmallConc05 [STAT:0008C807],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileSmallConc05.nif
		_formsToModify.Add('00090E89');	// HitDebrisPile03 [STAT:00090E89],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPile03.nif
		_formsToModify.Add('00090E8A');	// HitDebrisPile04 [STAT:00090E8A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPile04.nif
		_formsToModify.Add('00090E8B');	// HitDebrisChunkSmRoom03 [STAT:00090E8B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkSmRoom03.nif
		_formsToModify.Add('00090E8C');	// HitDebrisPile02 [STAT:00090E8C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPile02.nif
		_formsToModify.Add('00090E8D');	// HitDebrisChunkSmRoom01 [STAT:00090E8D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkSmRoom01.nif
		_formsToModify.Add('00090E8E');	// HitDebrisChunkSmRoom02 [STAT:00090E8E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkSmRoom02.nif
		_formsToModify.Add('00090E8F');	// HitDebrisChunkSmHall03 [STAT:00090E8F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkSmHall03.nif
		_formsToModify.Add('00090E90');	// HitDebrisChunkSmHall01 [STAT:00090E90],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkSmHall01.nif
		_formsToModify.Add('00090E91');	// HitDebrisChunkSmHall02 [STAT:00090E91],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkSmHall02.nif
		_formsToModify.Add('00090E92');	// HitDebrisChunkPipe01 [STAT:00090E92],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkPipe01.nif
		_formsToModify.Add('00090E93');	// HitDebrisChunkPipe02 [STAT:00090E93],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkPipe02.nif
		_formsToModify.Add('00090E94');	// HitDebrisChunkLgRoom02 [STAT:00090E94],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkLgRoom02.nif
		_formsToModify.Add('00090E95');	// HitDebrisChunkLgRoom03 [STAT:00090E95],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkLgRoom03.nif
		_formsToModify.Add('00090E96');	// HitDebrisChunkLgRoom01 [STAT:00090E96],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisChunkLgRoom01.nif
		_formsToModify.Add('0009C831');	// RockPileL01Roots [STAT:0009C831],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Rocks\RockPileL01.nif
		_formsToModify.Add('000A0595');	// RockPileL01RootsRocks [STAT:000A0595],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Rocks\RockPileL01.nif
		_formsToModify.Add('000A7206');	// TreeBlasted01Lichen [STAT:000A7206],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted01Lichen.nif
		_formsToModify.Add('000A7207');	// TreeBlasted01LichenFX [STAT:000A7207],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted01LichenFX.nif
		_formsToModify.Add('000A7208');	// TreeBlasted02Lichen [STAT:000A7208],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted02Lichen.nif
		_formsToModify.Add('000A7209');	// TreeBlasted02LichenFX [STAT:000A7209],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBlasted02LichenFX.nif
		_formsToModify.Add('000A7403');	// TreeblastedM04Lichen [STAT:000A7403],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeblastedM04Lichen.nif
		_formsToModify.Add('000A7404');	// TreeblastedM04LichenFX [STAT:000A7404],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeblastedM04LichenFX.nif
		_formsToModify.Add('000A7405');	// TreeMapleblasted02Lichen [STAT:000A7405],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted02Lichen.nif
		_formsToModify.Add('000A7406');	// TreeMapleblasted02LichenFX [STAT:000A7406],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeMapleblasted02LichenFX.nif
		_formsToModify.Add('000ADEAF');	// TreeDriftwood01 "Driftwood" [STAT:000ADEAF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Driftwood01.nif
		_formsToModify.Add('000ADEB6');	// TreeDriftwoodStump01 "Stump" [STAT:000ADEB6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeDriftwoodStump01.nif
		_formsToModify.Add('000ADEB8');	// TreeDriftwoodStump02 "Stump" [STAT:000ADEB8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStump02.nif
		_formsToModify.Add('000ADEBA');	// TreeDriftwoodStump03 "Stump" [STAT:000ADEBA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStump03.nif
		_formsToModify.Add('000ADEBC');	// TreeDriftwoodStump04 "Stump" [STAT:000ADEBC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStump04.nif
		_formsToModify.Add('000ADEC3');	// TreeDriftwoodLog02 "Driftwood" [STAT:000ADEC3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLog02.nif
		_formsToModify.Add('000AF0D0');	// TreeDriftwoodLog01 "Driftwood" [STAT:000AF0D0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLog01.nif
		_formsToModify.Add('000AF0DB');	// TreeDriftwoodLog03 "Driftwood" [STAT:000AF0DB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeDriftwoodLog03.nif
		_formsToModify.Add('000AF0DE');	// TreeDriftwood02 "Driftwood" [STAT:000AF0DE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Driftwood02.nif
		_formsToModify.Add('000BAD0D');	// SeaweedVine01 [STAT:000BAD0D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SeaweedVine01.nif
		_formsToModify.Add('000BAD0F');	// SeaweedGround01 [STAT:000BAD0F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Seaweed01.nif
		_formsToModify.Add('000BB7C9');	// SeaweedVine02 [STAT:000BB7C9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SeaweedVine02.nif
		_formsToModify.Add('000BDAEE');	// Seaweed02 [STAT:000BDAEE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Seaweed02.nif
		_formsToModify.Add('000BDAEF');	// Seaweed03 [STAT:000BDAEF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Seaweed03.nif
		_formsToModify.Add('000BFA41');	// SeaweedVine03 [STAT:000BFA41],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SeaweedVine03.nif
		_formsToModify.Add('000C55E6');	// DirtSlope01_NF_Roots01Dirt [STAT:000C55E6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('000C55EA');	// DirtSlope02_NF_Roots01 [STAT:000C55EA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope02.nif
		_formsToModify.Add('000C865A');	// DirtCliffTopShelfSm01_NF_Roots [STAT:000C865A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtCliffTopShelfSm01.nif
		_formsToModify.Add('000C8DBC');	// RockPileL01_NF_Roots01 [STAT:000C8DBC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Rocks\RockPileL01.nif
		_formsToModify.Add('000CA9C5');	// FishDead01 [STAT:000CA9C5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Deadfish\FishDead01.nif
		_formsToModify.Add('000CF443');	// FishDead02 [STAT:000CF443],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Deadfish\FishDead02.nif
		_formsToModify.Add('000CF446');	// FishDead03 [STAT:000CF446],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Deadfish\FishDead03.nif
		_formsToModify.Add('000D2464');	// DirtSlope01_NF_Roots01Grass [STAT:000D2464],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('000D2757');	// MirelurkDebrisDecal01 [STAT:000D2757],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\MirelurkDebrisDecal01.nif
		_formsToModify.Add('000D51B4');	// MirelurkDebrisDecal02 [STAT:000D51B4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\MirelurkDebrisDecal02.nif
		_formsToModify.Add('000D9CA7');	// TreeElmTree01Static "Elm Tree" [STAT:000D9CA7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeElmFree01.nif
		_formsToModify.Add('000D9CA8');	// TreeElmForest01Static "Elm Tree" [STAT:000D9CA8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeElmForest01.nif
		_formsToModify.Add('000D9CA9');	// TreeElmForest02Static "Elm Tree" [STAT:000D9CA9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeElmForest02.nif
		_formsToModify.Add('000D9CAA');	// TreeElmUndergrowth01Static "Elm Sapling" [STAT:000D9CAA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeElmUndergrowth01.nif
		_formsToModify.Add('000D9CAB');	// TreeElmUndergrowth02Static "Elm Sapling" [STAT:000D9CAB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeElmUndergrowth02.nif
		_formsToModify.Add('000E8271');	// DebrisMoundGlowingSea01 [STAT:000E8271],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\GlowingSea\DebrisMoundGlowingSea01.nif
		_formsToModify.Add('000E8273');	// DebrisMoundGlowingSea02 [STAT:000E8273],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\GlowingSea\DebrisMoundGlowingSea02.nif
		_formsToModify.Add('000EAF3B');	// DebrisPileGlowingSea01 [STAT:000EAF3B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\GlowingSea\DebrisPileGlowingSea01.nif
		_formsToModify.Add('000F00A6');	// KelpAnim01 [STAT:000F00A6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\KelpAnim01.nif
		_formsToModify.Add('000F2541');	// TreeStumpGS01 "Stump" [STAT:000F2541],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStumpGS01.nif
		_formsToModify.Add('000F2543');	// TreeLogGS01 "Burnt Log" [STAT:000F2543],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLogGS01.nif
		_formsToModify.Add('000F2548');	// HitDebrisPileCeiling02 [STAT:000F2548],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileCeiling02.nif
		_formsToModify.Add('000F2549');	// HitDebrisPileCeiling01 [STAT:000F2549],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileCeiling01.nif
		_formsToModify.Add('000F2554');	// HitDebrisPileCeiling03 [STAT:000F2554],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileCeiling03.nif
		_formsToModify.Add('000F290C');	// TreeLogGS02 [STAT:000F290C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLogGS02.nif
		_formsToModify.Add('000F290F');	// TreeLogGS03 [STAT:000F290F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLogGS03.nif
		_formsToModify.Add('000F35C8');	// TreeLogGS04 [STAT:000F35C8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeBranchGS01.nif
		_formsToModify.Add('000F35CA');	// TreeLogGS05 [STAT:000F35CA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLogGS05.nif
		_formsToModify.Add('000F35CC');	// TreeGS01 [STAT:000F35CC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeGS01.nif
		_formsToModify.Add('000F40EA');	// HedgeRowGS01 [STAT:000F40EA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRowGS01.nif
		_formsToModify.Add('000F40ED');	// HedgeRowGS02 [STAT:000F40ED],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRowGS02.nif
		_formsToModify.Add('000F40EF');	// deadshrubGS01 [STAT:000F40EF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\deadshrubGS01.nif
		_formsToModify.Add('000F40F1');	// deadshrubGS02 [STAT:000F40F1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\deadshrubGS02.nif
		_formsToModify.Add('000F40F3');	// deadshrubGS03 [STAT:000F40F3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\deadshrubGS03.nif
		_formsToModify.Add('000F40F5');	// HedgeRowGS03 [STAT:000F40F5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRowGS03.nif
		_formsToModify.Add('000F478F');	// TreeLogGS06 [STAT:000F478F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeLogGS06.nif
		_formsToModify.Add('000F4791');	// TreeGS02 [STAT:000F4791],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeGS02.nif
		_formsToModify.Add('000F4B96');	// HitDebrisPileDirtSmall01 [STAT:000F4B96],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileDirtSmall01.nif
		_formsToModify.Add('000FA772');	// HitExtLobbyRailingUnderLong01Debris01 [STAT:000FA772],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Architecture\Buildings\Hightech\Lobby\HitExtLobbyRailingUnderLong01Debris01.nif
		_formsToModify.Add('000FA781');	// HitExtLobbyRailingUnderLong01Debris02 [STAT:000FA781],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Architecture\Buildings\Hightech\Lobby\HitExtLobbyRailingUnderLong01Debris02.nif
		_formsToModify.Add('000F393D');	// Rubble_Flat_Trash_Lg01a [STAT:000F393D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Lg01a.nif
		_formsToModify.Add('000F393F');	// Rubble_Pile_Trash_Lrg01 [STAT:000F393F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Trash_Lrg01.nif
		_formsToModify.Add('00101690');	// RockPileM01_NF_Roots [STAT:00101690],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Rocks\RockPileM01.nif
		_formsToModify.Add('00106936');	// Rubble_Flat_Trash_Edge01 [STAT:00106936],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Edge01.nif
		_formsToModify.Add('00106937');	// Rubble_Flat_Trash_Edge02 [STAT:00106937],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Edge02.nif
		_formsToModify.Add('00106938');	// Rubble_Flat_Trash_Edge03 [STAT:00106938],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Edge03.nif
		_formsToModify.Add('00106939');	// Rubble_Flat_Trash_Lg01b [STAT:00106939],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Lg01b.nif
		_formsToModify.Add('0010693A');	// Rubble_Flat_Trash_Lg01c [STAT:0010693A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Lg01c.nif
		_formsToModify.Add('0010693B');	// Rubble_Flat_Trash_Sm01 [STAT:0010693B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Sm01.nif
		_formsToModify.Add('0010693C');	// Rubble_Flat_Trash_Sm02 [STAT:0010693C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Sm02.nif
		_formsToModify.Add('0010693D');	// Rubble_Flat_Trash_Sm03 [STAT:0010693D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Sm03.nif
		_formsToModify.Add('0010693E');	// Rubble_Flat_Trash_Sm04 [STAT:0010693E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Sm04.nif
		_formsToModify.Add('0010693F');	// Rubble_Flat_Trash_Sm05 [STAT:0010693F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Sm05.nif
		_formsToModify.Add('00106940');	// Rubble_Pile_Trash_Lrg02 [STAT:00106940],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Trash_Lrg02.nif
		_formsToModify.Add('00106951');	// Rubble_Pile_Trash_Med01 [STAT:00106951],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Trash_Med01.nif
		_formsToModify.Add('00106FBD');	// TreeStumpSMarsh01 "Stump" [STAT:00106FBD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStumpSMarsh01.nif
		_formsToModify.Add('00109180');	// TreeStumpSMarsh02 "Stump" [STAT:00109180],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStumpSMarsh02.nif
		_formsToModify.Add('00109182');	// TreeSMarsh01 "Tree" [STAT:00109182],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeSMarsh01.nif
		_formsToModify.Add('00109184');	// TreeStumpSMarsh03 "Stump" [STAT:00109184],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeStumpSMarsh03.nif
		_formsToModify.Add('0010918D');	// TreeSMarsh02 "Tree" [STAT:0010918D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeSMarsh02.nif
		_formsToModify.Add('0010A2C0');	// TreeSMarsh03 "Tree" [STAT:0010A2C0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeSMarsh03.nif
		_formsToModify.Add('0010BFDF');	// TreeFallenSMarsh04 "Log" [STAT:0010BFDF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeFallenSMarsh04.nif
		_formsToModify.Add('0010C66C');	// TreeFallenSMarsh01 "Log" [STAT:0010C66C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeFallenSMarsh01.nif
		_formsToModify.Add('0010CBE2');	// SMarshMoss01 [STAT:0010CBE2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SMarshMoss01.nif
		_formsToModify.Add('0010CBE3');	// SMarshMoss02 [STAT:0010CBE3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SMarshMoss02.nif
		_formsToModify.Add('0010CBE4');	// SMarshMoss03 [STAT:0010CBE4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SMarshMoss03.nif
		_formsToModify.Add('0010FA77');	// SMarshMoss04 [STAT:0010FA77],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SMarshMoss04.nif
		_formsToModify.Add('0010FA79');	// TreeSMarsh04 "Tree" [STAT:0010FA79],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeSMarsh04.nif
		_formsToModify.Add('001103D3');	// TreeSMarsh05 "Tree" [STAT:001103D3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeSMarsh05.nif
		_formsToModify.Add('001103D6');	// TreeSMarshRoots01 "Roots" [STAT:001103D6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeSMarshRoots01.nif
		_formsToModify.Add('001103D9');	// TreeSMarshRoots02 "Roots" [STAT:001103D9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeSMarshRoots02.nif
		_formsToModify.Add('00111F7D');	// SMarshMossWall01 [STAT:00111F7D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SMarshMossWall01.nif
		_formsToModify.Add('00111F80');	// SMarshMossWall02 [STAT:00111F80],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\SMarshMossWall02.nif
		_formsToModify.Add('00112054');	// MarshScumL01 [STAT:00112054],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\MarshScumL01.nif
		_formsToModify.Add('00112875');	// MarshScumM01 [STAT:00112875],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\MarshScumM01.nif
		_formsToModify.Add('00112FE7');	// Barnacle01 [STAT:00112FE7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Barnacle01.nif
		_formsToModify.Add('00112FE9');	// Barnacle02 [STAT:00112FE9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Barnacle02.nif
		_formsToModify.Add('00113E15');	// MarshScumS01 [STAT:00113E15],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\MarshScumS01.nif
		_formsToModify.Add('00118911');	// DebrisPileLargeWood06_Marsh [STAT:00118911],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood06.nif
		_formsToModify.Add('0011A8E8');	// TrashPileWall01_Marsh [STAT:0011A8E8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('0011A917');	// TrashPileCorIn01_Marsh [STAT:0011A917],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('0011A918');	// TrashPileWall02_Marsh [STAT:0011A918],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02.nif
		_formsToModify.Add('0011A919');	// TrashPileWall03_Marsh [STAT:0011A919],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('0011A91A');	// TrashClump03_Marsh [STAT:0011A91A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('0011A91B');	// TrashClump02_Marsh [STAT:0011A91B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0011A91C');	// TrashClump01_Marsh [STAT:0011A91C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0012154B');	// TreeBlastedForestBurntFallen02_Top "Fallen Tree" [STAT:0012154B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeFallen02_Top.nif
		_formsToModify.Add('0012154C');	// TreeBlastedForestBurntFallen03 "Fallen Tree" [STAT:0012154C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeFallen03.nif
		_formsToModify.Add('0012154D');	// TreeBlastedForestBurntStump01 "Stump" [STAT:0012154D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeStump01.nif
		_formsToModify.Add('0012154E');	// TreeBlastedForestBurntStump02 "Stump" [STAT:0012154E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeStump02.nif
		_formsToModify.Add('0012154F');	// TreeBlastedForestBurntUpright03 "Tree" [STAT:0012154F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeUpright03.nif
		_formsToModify.Add('00121550');	// TreeBlastedForestBurntUpright02 "Tree" [STAT:00121550],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeUpright02.nif
		_formsToModify.Add('00121551');	// TreeBlastedForestBurntUpright01 "Tree" [STAT:00121551],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeUpright01.nif
		_formsToModify.Add('00121552');	// TreeBlastedForestBurntStump03 "Stump" [STAT:00121552],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeStump03.nif
		_formsToModify.Add('00121553');	// TreeBlastedForestBurntFallen01 "Fallen Tree" [STAT:00121553],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeFallen01.nif
		_formsToModify.Add('00121554');	// TreeBlastedForestBurntFallen02_Bottom "Fallen Tree" [STAT:00121554],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntTreeFallen02_Bottom.nif
		_formsToModify.Add('001236AE');	// TreeBlastedForestDestroyedFallen01 "Blasted Log" [STAT:001236AE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeFallen01.nif
		_formsToModify.Add('001236AF');	// TreeBlastedForestDestroyedFallen02 "Blasted Log" [STAT:001236AF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeFallen02.nif
		_formsToModify.Add('001236B0');	// TreeBlastedForestDestroyedFallen03 "Blasted Log" [STAT:001236B0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeFallen03.nif
		_formsToModify.Add('001236B1');	// TreeBlastedForestDestroyedStump01 "Blasted Stump" [STAT:001236B1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeStump01.nif
		_formsToModify.Add('001236B2');	// TreeBlastedForestDestroyedStump02 "Blasted Stump" [STAT:001236B2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeStump02.nif
		_formsToModify.Add('001236B3');	// TreeBlastedForestDestroyedStump03 "Blasted Stump" [STAT:001236B3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeStump03.nif
		_formsToModify.Add('001236B4');	// TreeBlastedForestDestroyedUpright01 "Blasted Tree" [STAT:001236B4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeUpright01.nif
		_formsToModify.Add('001236B5');	// TreeBlastedForestDestroyedUpright02 "Blasted Tree" [STAT:001236B5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeUpright02.nif
		_formsToModify.Add('001236B6');	// TreeBlastedForestDestroyedUpright03 "Blasted Tree" [STAT:001236B6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestDestroyedTreeUpright03.nif
		_formsToModify.Add('00123A61');	// TrashPileWall01_Gravel [STAT:00123A61],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('00123A66');	// TrashPileWall02_Gravel [STAT:00123A66],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02.nif
		_formsToModify.Add('00123A6A');	// TrashClump03_Gravel [STAT:00123A6A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('00123A6B');	// TrashClump02_Gravel [STAT:00123A6B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('00123A6C');	// TrashClump01_Gravel [STAT:00123A6C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('00123AD0');	// TrashPileCor01_Gravel [STAT:00123AD0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCor01.nif
		_formsToModify.Add('00123DD1');	// BlastedForestVinesCluster01 [STAT:00123DD1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestVinesCluster01.nif
		_formsToModify.Add('00123DD2');	// BlastedForestVinesHanging01 [STAT:00123DD2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestVinesHanging01.nif
		_formsToModify.Add('00123DD3');	// BlastedForestVinesHanging02 [STAT:00123DD3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestVinesHanging02.nif
		_formsToModify.Add('00125504');	// BlastedForestFungalGroundCluster02 [STAT:00125504],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalGroundCluster02.nif
		_formsToModify.Add('00125505');	// BlastedForestFungalGroundWedges01 [STAT:00125505],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalGroundWedges01.nif
		_formsToModify.Add('00125506');	// BlastedForestFungalGroundWedges02 [STAT:00125506],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalGroundWedges02.nif
		_formsToModify.Add('00125507');	// BlastedForestFungalTreeCluster01 [STAT:00125507],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalTreeCluster01.nif
		_formsToModify.Add('00125508');	// BlastedForestFungalTreeCluster02 [STAT:00125508],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalTreeCluster02.nif
		_formsToModify.Add('00125509');	// BlastedForestFungalTreeCluster06 [STAT:00125509],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalTreeCluster06.nif
		_formsToModify.Add('0012550A');	// BlastedForestFungalTreeCluster05 [STAT:0012550A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalTreeCluster05.nif
		_formsToModify.Add('0012550B');	// BlastedForestFungalTreeCluster04 [STAT:0012550B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalTreeCluster04.nif
		_formsToModify.Add('0012550C');	// BlastedForestFungalTreeCluster03 [STAT:0012550C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalTreeCluster03.nif
		_formsToModify.Add('0012550D');	// BlastedForestFungalGroundCluster01 [STAT:0012550D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalGroundCluster01.nif
		_formsToModify.Add('0012B6D6');	// DebrisPileLargeWood06_SandDry [STAT:0012B6D6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\Building\DebrisPiles\DebrisPileLargeWood06.nif
		_formsToModify.Add('0012B6DA');	// TrashClump01_SandWet [STAT:0012B6DA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0012B6DE');	// TrashClump02_SandWet [STAT:0012B6DE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0012B6E2');	// TrashClump03_SandWet [STAT:0012B6E2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('0013384D');	// Bramble01 [STAT:0013384D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Bramble01.nif
		_formsToModify.Add('0013384E');	// Bramble02 [STAT:0013384E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Bramble02.nif
		_formsToModify.Add('0013384F');	// Bramble03 [STAT:0013384F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Bramble03.nif
		_formsToModify.Add('00133850');	// Bramble04 [STAT:00133850],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Bramble04.nif
		_formsToModify.Add('00133851');	// Cattails01 [STAT:00133851],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Cattails01.nif
		_formsToModify.Add('00133852');	// Cattails02 [STAT:00133852],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Cattails02.nif
		_formsToModify.Add('00133853');	// DeadShrub01 [STAT:00133853],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\DeadShrub01.nif
		_formsToModify.Add('00133854');	// DeadShrub02 [STAT:00133854],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\DeadShrub02.nif
		_formsToModify.Add('00133855');	// DeadShrub03 [STAT:00133855],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\DeadShrub03.nif
		_formsToModify.Add('00133856');	// DeadShrub04 [STAT:00133856],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\DeadShrub04.nif
		_formsToModify.Add('00133857');	// DeadShrub05 "Bush" [STAT:00133857],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\DeadShrub05.nif
		_formsToModify.Add('00133858');	// DeadShrub06 "Bush" [STAT:00133858],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\DeadShrub06.nif
		_formsToModify.Add('00133859');	// Forsythia01 [STAT:00133859],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Forsythia01.nif
		_formsToModify.Add('0013385A');	// Forsythia02 [STAT:0013385A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Forsythia02.nif
		_formsToModify.Add('0013385B');	// Forsythia03 [STAT:0013385B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Forsythia03.nif
		_formsToModify.Add('0013385C');	// HedgeRow01 [STAT:0013385C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRow01.nif
		_formsToModify.Add('0013385D');	// HedgeRow02 "Bush" [STAT:0013385D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRow02.nif
		_formsToModify.Add('0013385E');	// HedgeRow03 [STAT:0013385E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRow03.nif
		_formsToModify.Add('0013385F');	// HedgeRow04 [STAT:0013385F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRow04.nif
		_formsToModify.Add('00133861');	// HollyShrub01 "Shrub" [STAT:00133861],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HollyShrub01.nif
		_formsToModify.Add('00133862');	// HollyShrub02 "Shrub" [STAT:00133862],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HollyShrub02.nif
		_formsToModify.Add('00133863');	// HollyShrub03 "Shrub" [STAT:00133863],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HollyShrub03.nif
		_formsToModify.Add('00133864');	// HollyShrub04 "Shrub" [STAT:00133864],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HollyShrub04.nif
		_formsToModify.Add('00133865');	// ShrubGroupLarge04 [STAT:00133865],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\ShrubGroupLarge04.nif
		_formsToModify.Add('00133866');	// ShrubGroupLarge05 [STAT:00133866],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\ShrubGroupLarge05.nif
		_formsToModify.Add('00133867');	// ShrubGroupMedium02 [STAT:00133867],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\ShrubGroupMedium02.nif
		_formsToModify.Add('00133868');	// ShrubGroupMedium03 [STAT:00133868],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\ShrubGroupMedium03.nif
		_formsToModify.Add('00133869');	// ShrubGroupSmall01 [STAT:00133869],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\ShrubGroupSmall01.nif
		_formsToModify.Add('0013386A');	// Fern01 [STAT:0013386A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\TreeFern01.nif
		_formsToModify.Add('0013386B');	// Fern02 [STAT:0013386B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\TreeFern02.nif
		_formsToModify.Add('0013386F');	// Marshshrub01 [STAT:0013386F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\MarshShrub01.nif
		_formsToModify.Add('00133870');	// Marshshrub02 [STAT:00133870],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\MarshShrub02.nif
		_formsToModify.Add('001346AE');	// RWResStr01BlastedForest_Grass [STAT:001346AE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\RetainingWall\Residential\RWResStr01Grass.nif
		_formsToModify.Add('001346B0');	// RWResStrShort01BlastedForestGrass01 [STAT:001346B0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\RetainingWall\Residential\RWResStrShort01Grass.nif
		_formsToModify.Add('001346B2');	// RWResCor01BlastedForest_Grass [STAT:001346B2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\RetainingWall\Residential\RWResCor01Grass.nif
		_formsToModify.Add('001346B4');	// RWResCorIn01BlastedForest_Grass [STAT:001346B4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\RetainingWall\Residential\RWResCorIn01Grass.nif
		_formsToModify.Add('0013C377');	// TreeBlastedForestFungalLarge01 [STAT:0013C377],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestFungalTreeLarge01.nif
		_formsToModify.Add('0013C378');	// TreeBlastedForestFungalMedium01 [STAT:0013C378],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestFungalTreeMedium01.nif
		_formsToModify.Add('0013C379');	// TreeBlastedForestFungalSmall01 [STAT:0013C379],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestFungalTreeSmall01.nif
		_formsToModify.Add('0013C37A');	// BlastedForestGroundRoots01 [STAT:0013C37A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestGroundRoots01.nif
		_formsToModify.Add('0013C37B');	// BlastedForestGroundRoots02 [STAT:0013C37B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestGroundRoots02.nif
		_formsToModify.Add('0013C37C');	// BlastedForestGroundRootsRadial01 [STAT:0013C37C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestGroundRootsRadial01.nif
		_formsToModify.Add('00140D3E');	// DirtSlope01_BlastedForestGrass01 [STAT:00140D3E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('00140D40');	// DirtSlope01_BlastedForestForestFloor01 [STAT:00140D40],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('00140D42');	// DirtSlope02_BlastedForestGrass01 [STAT:00140D42],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope02.nif
		_formsToModify.Add('00140D44');	// DirtSlope02_BlastedForestForestFloor01 [STAT:00140D44],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope02.nif
		_formsToModify.Add('0014265C');	// DirtSlope01_BlastedForestGravel01 [STAT:0014265C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('0014265E');	// DirtSlope02_BlastedForestGravel01 [STAT:0014265E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope02.nif
		_formsToModify.Add('00145030');	// RockPileL01_BlastedForest_GravelDirt01 [STAT:00145030],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Rocks\RockPileL01.nif
		_formsToModify.Add('00145032');	// RockPileL01_BlastedForest_ForestFloor01Dirt01 [STAT:00145032],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Rocks\RockPileL01.nif
		_formsToModify.Add('001453D7');	// TrashClump01_Silt [STAT:001453D7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('001453D8');	// TrashClump02_Silt [STAT:001453D8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('001453D9');	// TrashClump03_Silt [STAT:001453D9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('00148EEF');	// RoseBush01 [STAT:00148EEF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\RoseBush01.nif
		_formsToModify.Add('00148EF3');	// RoseBush02 [STAT:00148EF3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\RoseBush02.nif
		_formsToModify.Add('0014EBB8');	// RoseBush01White [STAT:0014EBB8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\RoseBush01White.nif
		_formsToModify.Add('0014EBB9');	// RoseBush02White [STAT:0014EBB9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\RoseBush02White.nif
		_formsToModify.Add('0015CEEF');	// KelpAnim02 [STAT:0015CEEF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\KelpAnim02.nif
		_formsToModify.Add('00165012');	// OfficePaperDebris03 [STAT:00165012],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebris03.nif
		_formsToModify.Add('00165014');	// OfficePaperDebris04 [STAT:00165014],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebris04.nif
		_formsToModify.Add('00165015');	// OfficePaperDebris05 [STAT:00165015],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebris05.nif
		_formsToModify.Add('0016501E');	// OfficePaperDebris06 [STAT:0016501E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebris06.nif
		_formsToModify.Add('00165022');	// OfficePaperDebris07 [STAT:00165022],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebris07.nif
		_formsToModify.Add('00165023');	// OfficePaperDebrisSinglePg01 [STAT:00165023],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebrisSinglePg01.nif
		_formsToModify.Add('00165024');	// OfficePaperDebris02 [STAT:00165024],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebris02.nif
		_formsToModify.Add('00165025');	// OfficePaperDebrisSinglePg02 [STAT:00165025],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebrisSinglePg02.nif
		_formsToModify.Add('00165026');	// OfficePaperDebrisSinglePg03 [STAT:00165026],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebrisSinglePg03.nif
		_formsToModify.Add('00165027');	// OfficePaperDebrisSinglePg04 [STAT:00165027],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\OfficePaperDebrisSinglePg04.nif
		_formsToModify.Add('0016ADBB');	// TreeNoose01_Branch [STAT:0016ADBB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\TreeNoose01_Branch.nif
		_formsToModify.Add('0016BAF3');	// PaperDebris01 [STAT:0016BAF3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\PaperDebris01.nif
		_formsToModify.Add('0016BAF5');	// PaperDebris02 [STAT:0016BAF5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\PaperDebris\PaperDebris02.nif
		_formsToModify.Add('001798F0');	// SWflat2x2CircleTree_01 [STAT:001798F0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Sidewalks\SWflat2x2CircleTree_01.nif
		_formsToModify.Add('00179B43');	// TrashPileCorIn01_CraterDebris [STAT:00179B43],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('00179B44');	// TrashPileWall01_DebrisCrater [STAT:00179B44],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('00179B45');	// TrashClump03_DebrisCrater [STAT:00179B45],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('00179B46');	// TrashClump01_CraterDebris [STAT:00179B46],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('00179B48');	// TrashClump02_DebrisCrater [STAT:00179B48],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('00182994');	// MarshScumL01_Debris [STAT:00182994],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\MarshScumL01.nif
		_formsToModify.Add('0018BA4F');	// NFCreosote01 [STAT:0018BA4F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Creosote01.nif
		_formsToModify.Add('0018BA50');	// NFCreosote02 [STAT:0018BA50],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Creosote02.nif
		_formsToModify.Add('0018BA51');	// NFCreosote03 [STAT:0018BA51],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Creosote03.nif
		_formsToModify.Add('00191498');	// Rubble_Pile_Debris_04 [STAT:00191498],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Debris_01.nif
		_formsToModify.Add('0019149E');	// Rubble_Pile_Debris_05 [STAT:0019149E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Debris_02.nif
		_formsToModify.Add('0019149F');	// Rubble_Pile_Debris_07 [STAT:0019149F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Debris_03.nif
		_formsToModify.Add('001914A2');	// Rubble_Pile_Debris_06 [STAT:001914A2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Debris_04.nif
		_formsToModify.Add('001914A5');	// Rubble_Pile_Debris_03 [STAT:001914A5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Debris_05.nif
		_formsToModify.Add('001914C0');	// Rubble_Pile_Debris_01 [STAT:001914C0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Debris_06.nif
		_formsToModify.Add('001914C2');	// DecalDebris05 [STAT:001914C2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DecalDebris04.nif
		_formsToModify.Add('001914C9');	// DecalDebris04 [STAT:001914C9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DecalDebris05.nif
		_formsToModify.Add('001914DB');	// DecalDebris06 [STAT:001914DB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\DecalDebris06.nif
		_formsToModify.Add('00191624');	// Rubble_Pile_Debris_02 [STAT:00191624],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Pile_Debris_07.nif
		_formsToModify.Add('00195CC4');	// NFoothillsShrubLarge01 [STAT:00195CC4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\FoothillsShrubLarge01.nif
		_formsToModify.Add('00195CC5');	// NFoothillsShrubMedium01 [STAT:00195CC5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\FoothillsShrubMedium01.nif
		_formsToModify.Add('00195CC6');	// NFoothillsShrubSmall01 [STAT:00195CC6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\FoothillsShrubSmall01.nif
		_formsToModify.Add('0019A6AE');	// HighTechDebris01 [STAT:0019A6AE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris01.nif
		_formsToModify.Add('0019A6AF');	// HighTechDebris02 [STAT:0019A6AF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris02.nif
		_formsToModify.Add('0019A6B0');	// HighTechDebris03 [STAT:0019A6B0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris03.nif
		_formsToModify.Add('0019A6B1');	// HighTechDebris04 [STAT:0019A6B1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris04.nif
		_formsToModify.Add('0019A6B2');	// HighTechDebris05 [STAT:0019A6B2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris05.nif
		_formsToModify.Add('0019A6B3');	// HighTechDebris06 [STAT:0019A6B3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris06.nif
		_formsToModify.Add('0019A6B4');	// HighTechDebris07 [STAT:0019A6B4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris07.nif
		_formsToModify.Add('0019A6B5');	// HighTechDebris08 [STAT:0019A6B5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebris08.nif
		_formsToModify.Add('0019A6B6');	// HighTechDebrisDecal01 [STAT:0019A6B6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebrisDecal01.nif
		_formsToModify.Add('0019A6B7');	// HighTechDebrisDecal02 [STAT:0019A6B7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebrisDecal02.nif
		_formsToModify.Add('0019A6B8');	// HighTechDebrisDecal03 [STAT:0019A6B8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\HighTechDebrisDecal03.nif
		_formsToModify.Add('0019FAA1');	// TrashPileCorIn01_Silt [STAT:0019FAA1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('001A890E');	// DirtSlope01_Roots01PW [STAT:001A890E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('001A891E');	// HedgeRow03PW [STAT:001A891E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRow03.nif
		_formsToModify.Add('001A8921');	// HedgeRow02PW [STAT:001A8921],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRow02.nif
		_formsToModify.Add('001A8924');	// HedgeRow01PW [STAT:001A8924],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\HedgeRow01.nif
		_formsToModify.Add('00020B8C');	// VineHanging01NF [STAT:00020B8C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging01.nif
		_formsToModify.Add('00020B99');	// VineHanging02NF [STAT:00020B99],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging02.nif
		_formsToModify.Add('00020CD1');	// VineHanging03NF [STAT:00020CD1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging03.nif
		_formsToModify.Add('00020D35');	// VineHanging04NF [STAT:00020D35],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging04.nif
		_formsToModify.Add('00020D3F');	// VineHanging05NF [STAT:00020D3F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging05.nif
		_formsToModify.Add('00020D4A');	// VineHanging06NF [STAT:00020D4A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging06.nif
		_formsToModify.Add('00020D4F');	// VineHanging07NF [STAT:00020D4F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging07.nif
		_formsToModify.Add('00020D55');	// VineHanging08NF [STAT:00020D55],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging08.nif
		_formsToModify.Add('00020D63');	// VineHanging09NF [STAT:00020D63],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging09.nif
		_formsToModify.Add('00020DF6');	// VineHangingLarge01NF [STAT:00020DF6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging01.nif
		_formsToModify.Add('00020E25');	// VineHangingLarge02NF [STAT:00020E25],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHangingLarge02.nif
		_formsToModify.Add('00020E2C');	// VineHangingLarge03NF [STAT:00020E2C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHangingLarge03.nif
		_formsToModify.Add('00020E2F');	// VineShrub01NF [STAT:00020E2F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineShrub01.nif
		_formsToModify.Add('00020E32');	// VineTree01NF [STAT:00020E32],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineTree01.nif
		_formsToModify.Add('00020E35');	// VineTree02NF [STAT:00020E35],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineTree02.nif
		_formsToModify.Add('00020E38');	// VineGround01NF [STAT:00020E38],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineGround01.nif
		_formsToModify.Add('00020E3B');	// VineGround02NF [STAT:00020E3B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineGround02.nif
		_formsToModify.Add('00020E3E');	// VineGround03NF [STAT:00020E3E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineGround03.nif
		_formsToModify.Add('00020E41');	// VineDecalCorner01NF [STAT:00020E41],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperCorner01.nif
		_formsToModify.Add('00020E44');	// VineDecalCorner02NF [STAT:00020E44],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperCorner02.nif
		_formsToModify.Add('00020E47');	// VineDecalLarge01NF [STAT:00020E47],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperLarge01.nif
		_formsToModify.Add('00020E4A');	// VineDecalLarge02NF [STAT:00020E4A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperLarge02.nif
		_formsToModify.Add('00020E4D');	// VineDecalLarge03NF [STAT:00020E4D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperLarge03.nif
		_formsToModify.Add('00020E50');	// VineDecalMed01NF [STAT:00020E50],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperMed01.nif
		_formsToModify.Add('00020E62');	// VineDecalMed02NF [STAT:00020E62],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperMed02.nif
		_formsToModify.Add('00020EAF');	// VineDecalMed03NF [STAT:00020EAF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperMed03.nif
		_formsToModify.Add('00020EDC');	// VineDecalSmall01NF [STAT:00020EDC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperSmall01.nif
		_formsToModify.Add('00020EEB');	// VineDecalSmall02NF [STAT:00020EEB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperSmall02.nif
		_formsToModify.Add('00020EEE');	// VineDecalSmall03NF [STAT:00020EEE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperSmall03.nif
		_formsToModify.Add('00020EFA');	// VineDecalXSmall01NF [STAT:00020EFA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperXSmall01.nif
		_formsToModify.Add('00020F09');	// VineDecalXSmall02NF [STAT:00020F09],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineCreeperXSmall02.nif
		_formsToModify.Add('0002B8F0');	// DecalConcrete01 [STAT:0002B8F0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalConcrete01.nif
		_formsToModify.Add('0002B8F1');	// DecalConcrete02 [STAT:0002B8F1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalConcrete02.nif
		_formsToModify.Add('0002B8F2');	// DecalConcrete03 [STAT:0002B8F2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalConcrete03.nif
		_formsToModify.Add('0002B8F3');	// DecalConcrete04 [STAT:0002B8F3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalConcrete04.nif
		_formsToModify.Add('0002B8F4');	// DecalMetal01 [STAT:0002B8F4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalMetal01.nif
		_formsToModify.Add('0002B8F5');	// DecalMetal02 [STAT:0002B8F5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalMetal02.nif
		_formsToModify.Add('0002B8F6');	// DecalMetal03 [STAT:0002B8F6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalMetal03.nif
		_formsToModify.Add('0002B8F7');	// DecalMetal04 [STAT:0002B8F7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalMetal04.nif
		_formsToModify.Add('0002B8F8');	// DecalWood01 [STAT:0002B8F8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalWood01.nif
		_formsToModify.Add('0002B8F9');	// DecalWood02 [STAT:0002B8F9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalWood02.nif
		_formsToModify.Add('0002B8FA');	// DecalWood03 [STAT:0002B8FA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalWood03.nif
		_formsToModify.Add('0002B8FB');	// DecalWood04 [STAT:0002B8FB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Effects\DecalsPlaced\DecalWood04.nif
		_formsToModify.Add('0002D587');	// ExtRubble_HiTec_Debris01 "Debris" [STAT:0002D587],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris01.nif
		_formsToModify.Add('0004471B');	// ExtRubble_HiTec_Debris02 "Debris" [STAT:0004471B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris02.nif
		_formsToModify.Add('000B3748');	// WaterDebrisA [STAT:000B3748],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\WaterDebrisA.nif
		_formsToModify.Add('000C041C');	// WaterDebrisB [STAT:000C041C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\WaterDebrisB.nif
		_formsToModify.Add('00122E1F');	// TrashPileRectangle01 [STAT:00122E1F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileRectangle01.nif
		_formsToModify.Add('0013578B');	// ExtRubble_HiTec_Debris04 "Debris" [STAT:0013578B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris04.nif
		_formsToModify.Add('0013578C');	// ExtRubble_HiTec_Debris05 "Debris" [STAT:0013578C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris05.nif
		_formsToModify.Add('0013578D');	// ExtRubble_HiTec_Debris06 "Debris" [STAT:0013578D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris06.nif
		_formsToModify.Add('0013578E');	// ExtRubble_HiTec_Debris07 "Debris" [STAT:0013578E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris07.nif
		_formsToModify.Add('0013578F');	// ExtRubble_HiTec_Debris08 "Debris" [STAT:0013578F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris08.nif
		_formsToModify.Add('00135790');	// ExtRubble_HiTec_Debris03 "Debris" [STAT:00135790],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Debris03.nif
		_formsToModify.Add('00188845');	// DeadShrub01Obscurance [STAT:00188845],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\DeadShrub01Obscurance.nif
		_formsToModify.Add('00194493');	// ClutterGenShelfC [STAT:00194493],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenShelfC.nif
		_formsToModify.Add('00194497');	// ClutterGenDeskA [STAT:00194497],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDeskA.nif
		_formsToModify.Add('0019449D');	// ClutterGenTableA [STAT:0019449D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenTableA.nif
		_formsToModify.Add('001944A0');	// ClutterGenDecalA [STAT:001944A0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDecalA.nif
		_formsToModify.Add('001944AA');	// ClutterGenDeskB [STAT:001944AA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDeskB.nif
		_formsToModify.Add('001944AF');	// ClutterGenSlimeA [STAT:001944AF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenSlimeA.nif
		_formsToModify.Add('001944B0');	// ClutterGenDecalA1 [STAT:001944B0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDecalB.nif
		_formsToModify.Add('001944B2');	// ClutterGenDeskC [STAT:001944B2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDeskC.nif
		_formsToModify.Add('001944B5');	// ClutterGenDeskD [STAT:001944B5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDeskD.nif
		_formsToModify.Add('001944BC');	// ClutterGenDustA [STAT:001944BC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDustA.nif
		_formsToModify.Add('001944D0');	// ClutterGenShelfA [STAT:001944D0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenShelfA.nif
		_formsToModify.Add('001944D3');	// ClutterGenShelfB [STAT:001944D3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenShelfB.nif
		_formsToModify.Add('001A9752');	// ECliffGrassCurved01_BlastedForest [STAT:001A9752],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\ErodedCliffs\ECliffGrassCurved01.nif
		_formsToModify.Add('001A976B');	// ECliffGrassCurved01_RootsEroded [STAT:001A976B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\ErodedCliffs\ECliffGrassCurved01.nif
		_formsToModify.Add('001A97A2');	// ECliffGrassStr01_RootsEroded [STAT:001A97A2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\ErodedCliffs\ECliffGrassStr01.nif
		_formsToModify.Add('001A97D8');	// TreeSapling01 [STAT:001A97D8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Sapling01.nif
		_formsToModify.Add('001A97D9');	// TreeSapling02 [STAT:001A97D9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Sapling02.nif
		_formsToModify.Add('001A97DA');	// TreeSapling03 [STAT:001A97DA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Sapling03.nif
		_formsToModify.Add('001A97DB');	// TreeSapling04 [STAT:001A97DB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Sapling04.nif
		_formsToModify.Add('001A97DC');	// TreeCedarShrub01 [STAT:001A97DC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Cedar01.nif
		_formsToModify.Add('001A97DD');	// TreeCedarShrub02 [STAT:001A97DD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Cedar02.nif
		_formsToModify.Add('001A97DE');	// TreeCedarShrub03 [STAT:001A97DE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\Cedar03.nif
		_formsToModify.Add('001A97DF');	// TreeClusterMound01 [STAT:001A97DF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster01.nif
		_formsToModify.Add('001A97E0');	// TreeClusterMound02 [STAT:001A97E0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster02.nif
		_formsToModify.Add('001A97E1');	// TreeClusterMound01_Marsh "Trees" [STAT:001A97E1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster01.nif
		_formsToModify.Add('001A97E3');	// TreeClusterMound02_Marsh "Trees" [STAT:001A97E3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster02.nif
		_formsToModify.Add('001A97E5');	// TreeClusterMound02_Forest [STAT:001A97E5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster02.nif
		_formsToModify.Add('001A97E6');	// TreeClusterMound02_NF [STAT:001A97E6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster02.nif
		_formsToModify.Add('001ADB1D');	// TrashEdge03_Nochunks [STAT:001ADB1D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge03_Nochunks.nif
		_formsToModify.Add('001ADB1E');	// TrashEdge04_nochunks [STAT:001ADB1E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge04_nochunks.nif
		_formsToModify.Add('001ADB1F');	// TrashClump03_nochunks [STAT:001ADB1F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03_nochunks.nif
		_formsToModify.Add('001ADB20');	// TrashPileWall02_nochunks [STAT:001ADB20],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02_nochunks.nif
		_formsToModify.Add('001ADB21');	// TrashPileCorIn01_nochunks [STAT:001ADB21],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01_nochunks.nif
		_formsToModify.Add('001ADB22');	// TrashPileWall01_nochunks [STAT:001ADB22],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01_nochunks.nif
		_formsToModify.Add('001ADB23');	// TrashPileWall03_nochunks [STAT:001ADB23],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03_nochunks.nif
		_formsToModify.Add('001B9B93');	// MarshScumM01_Debris [STAT:001B9B93],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\MarshScumM01.nif
		_formsToModify.Add('001B9B96');	// MarshScumS01_Debris [STAT:001B9B96],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Water\MarshScumS01.nif
		_formsToModify.Add('001BB8CF');	// TrashClump01_SandDry [STAT:001BB8CF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('001BB8D3');	// TrashClump02_SandDry [STAT:001BB8D3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('001BB8D4');	// TrashClump03_SandDry [STAT:001BB8D4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('001BCE55');	// BlastedForestLeafPile01 [STAT:001BCE55],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\BlastedForestLeafPile01.nif
		_formsToModify.Add('001BCE57');	// BlastedForestLeafPile02 [STAT:001BCE57],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\BlastedForestLeafPile02.nif
		_formsToModify.Add('001BE3C8');	// BlastedForestFungalGroundWedges03 [STAT:001BE3C8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalGroundWedges03.nif
		_formsToModify.Add('001BE3C9');	// BlastedForestFungalGroundCluster03 [STAT:001BE3C9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalGroundCluster03.nif
		_formsToModify.Add('001BE3CA');	// BlastedForestFungalGroundCluster04 [STAT:001BE3CA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\BlastedForestFungalGroundCluster04.nif
		_formsToModify.Add('001BE3CB');	// BlastedForestLeafPile03 [STAT:001BE3CB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Forest\BlastedForestLeafPile03.nif
		_formsToModify.Add('001BE432');	// Seaweed03_Water [STAT:001BE432],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Seaweed03_Tree.nif
		_formsToModify.Add('001BE433');	// Seaweed02_Water [STAT:001BE433],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Seaweed02_Tree.nif
		_formsToModify.Add('001BE434');	// SeaweedGround01_Water [STAT:001BE434],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\Seaweed01_Tree.nif
		_formsToModify.Add('001BF098');	// DebrisMoundCoastFloor01_WetSand [STAT:001BF098],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\GlowingSea\DebrisMoundGlowingSea01.nif
		_formsToModify.Add('001BF09D');	// DebrisMoundCoastFloor01_RiverSilt [STAT:001BF09D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\GlowingSea\DebrisMoundGlowingSea01.nif
		_formsToModify.Add('001BF09F');	// DebrisMoundCoastFloor01_OceanFloor [STAT:001BF09F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\GlowingSea\DebrisMoundGlowingSea01.nif
		_formsToModify.Add('001C2291');	// TreeClusterMound01_RiverbedRocks02Wet [STAT:001C2291],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\TreeCluster01.nif
		_formsToModify.Add('001C5ACD');	// HitDebrisPileTilesSingle01 [STAT:001C5ACD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileTilesSingle01.nif
		_formsToModify.Add('001C5ACE');	// HitDebrisPileTilesSingle02 [STAT:001C5ACE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Interiors\HighTech\DebrisPiles\HitDebrisPileTilesSingle02.nif
		_formsToModify.Add('001C9AF1');	// TrashPileWall03_Gravel [STAT:001C9AF1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('001CCDA0');	// BlastedForestBurntBranch01 [STAT:001CCDA0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntBranch01.nif
		_formsToModify.Add('001CCDA1');	// BlastedForestBurntBranchPile01 [STAT:001CCDA1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntBranchPile01.nif
		_formsToModify.Add('001CCDA2');	// BlastedForestBurntBranchPile02 [STAT:001CCDA2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Trees\BlastedForestBurntBranchPile02.nif
		_formsToModify.Add('001E491C');	// Rubble_Flat_Trash_Catwalks_01 [STAT:001E491C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Catwalks_01.nif
		_formsToModify.Add('001E491D');	// Rubble_Flat_Trash_Catwalks_02 [STAT:001E491D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Catwalks_02.nif
		_formsToModify.Add('001E491E');	// Rubble_Flat_Trash_Catwalks_04 [STAT:001E491E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Catwalks_04.nif
		_formsToModify.Add('001E491F');	// Rubble_Flat_Trash_Catwalks_03 [STAT:001E491F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Catwalks_03.nif
		_formsToModify.Add('001E4920');	// Rubble_Flat_Trash_Catwalks_05 [STAT:001E4920],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Catwalks_05.nif
		_formsToModify.Add('001E4921');	// Rubble_Flat_Trash_Catwalks_06 [STAT:001E4921],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\Rubble_Flat_Trash_Catwalks_06.nif
		_formsToModify.Add('0020A563');	// ClutterGenDecalB [STAT:0020A563],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\ClutterGeneric\ClutterGenDecalB.nif
		_formsToModify.Add('0023A66B');	// VineHangingLarge10NF [STAT:0023A66B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging10.nif
		_formsToModify.Add('0023A66F');	// VineHangingLarge11NF [STAT:0023A66F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\VineHanging11.nif
		_formsToModify.Add('01002CAE');	// KelpGroup_Med01 [SCOL:01002CAE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00002CAE.NIF
		_formsToModify.Add('01002CD3');	// KelpGroup_Med02 [SCOL:01002CD3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00002CD3.NIF
		_formsToModify.Add('01002D0E');	// KelpGroup_Sm01 [SCOL:01002D0E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00002D0E.NIF
		_formsToModify.Add('01002D0F');	// KelpGroup_Sm02 [SCOL:01002D0F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00002D0F.NIF
		_formsToModify.Add('01002D15');	// KelpGroup_Lg01 [SCOL:01002D15],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00002D15.NIF
		_formsToModify.Add('01002D1B');	// KelpGroup_Lg02 [SCOL:01002D1B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00002D1B.NIF
		_formsToModify.Add('01002D1C');	// KelpGroup_Lg03 [SCOL:01002D1C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00002D1C.NIF
		_formsToModify.Add('010035CD');	// KelpGroup_Med05 [SCOL:010035CD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035CD.NIF
		_formsToModify.Add('010035CE');	// KelpGroup_Sm03 [SCOL:010035CE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035CE.NIF
		_formsToModify.Add('010035CF');	// KelpGroup_Sm04 [SCOL:010035CF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035CF.NIF
		_formsToModify.Add('010035D0');	// KelpGroup_Med03 [SCOL:010035D0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035D0.NIF
		_formsToModify.Add('010035D1');	// KelpGroup_Med04 [SCOL:010035D1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035D1.NIF
		_formsToModify.Add('010035D3');	// KelpGroup_Sm05 [SCOL:010035D3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035D3.NIF
		_formsToModify.Add('010035D5');	// KelpGroup_Lg04 [SCOL:010035D5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035D5.NIF
		_formsToModify.Add('010035D6');	// KelpGroup_Shore01 [SCOL:010035D6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035D6.NIF
		_formsToModify.Add('010035D9');	// KelpGroup_Lg05 [SCOL:010035D9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035D9.NIF
		_formsToModify.Add('010035DA');	// KelpGroup_Shore02 [SCOL:010035DA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM000035DA.NIF
		_formsToModify.Add('01003D04');	// TreeRedPineSCCluster01_DLC03 [SCOL:01003D04],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00003D04.NIF
		_formsToModify.Add('01003D05');	// TreeRedPineSCCluster02_DLC03 [SCOL:01003D05],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00003D05.NIF
		_formsToModify.Add('01003D08');	// TreeRedPineSCCluster03_DLC03 [SCOL:01003D08],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00003D08.NIF
		_formsToModify.Add('01003D0A');	// TreeRedPineSCCluster04_DLC03 [SCOL:01003D0A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00003D0A.NIF
		_formsToModify.Add('01004F56');	// TreeRedPineSCCluster05_DLC03 [SCOL:01004F56],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00004F56.NIF
		_formsToModify.Add('01004F59');	// TreeBeachPineSCCluster01_DLC03 [SCOL:01004F59],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00004F59.NIF
		_formsToModify.Add('01005CEF');	// TreeBeachPineSCCluster02_DLC03 [SCOL:01005CEF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00005CEF.NIF
		_formsToModify.Add('01005CF0');	// TreeRedPineSCCluster06_DLC03 [SCOL:01005CF0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00005CF0.NIF
		_formsToModify.Add('01005CF1');	// TreeRedPineSCCluster07_DLC03 [SCOL:01005CF1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00005CF1.NIF
		_formsToModify.Add('01006C8F');	// TreeRedPineSCBroken [SCOL:01006C8F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006C8F.NIF
		_formsToModify.Add('01006D26');	// ShrubGroupDLC03Large01 [SCOL:01006D26],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D26.NIF
		_formsToModify.Add('01006D28');	// ShrubGroupDLC03Large02 [SCOL:01006D28],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D28.NIF
		_formsToModify.Add('01006D29');	// ShrubGroupDLC03Medium01 [SCOL:01006D29],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D29.NIF
		_formsToModify.Add('01006D2A');	// ShrubGroupDLC03Small01 [SCOL:01006D2A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D2A.NIF
		_formsToModify.Add('01006D74');	// FernSC_DLC03_Sm01 [SCOL:01006D74],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D74.NIF
		_formsToModify.Add('01006D76');	// FernSC_DLC03_Sm02 [SCOL:01006D76],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D76.NIF
		_formsToModify.Add('01006D78');	// FernSC_DLC03_Med01 [SCOL:01006D78],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D78.NIF
		_formsToModify.Add('01006D7A');	// FernSC_DLC03_Med02 [SCOL:01006D7A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D7A.NIF
		_formsToModify.Add('01006D7C');	// FernSC_DLC03_Lg01 "DLC03\Landscape\Plants\" [SCOL:01006D7C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00006D7C.NIF
		_formsToModify.Add('0100C44A');	// TreeBeachPineSCCluster03_DLC03 [SCOL:0100C44A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM0000C44A.NIF
		_formsToModify.Add('01016745');	// BranchPileStumpRocks02_DLC03 [SCOL:01016745],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00016745.NIF
		_formsToModify.Add('01016747');	// BranchPileStump02_DLC03 [SCOL:01016747],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM00016747.NIF
		_formsToModify.Add('0104657F');	// clutter_SCkelp01 [SCOL:0104657F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCCoast.esm\CM0004657F.NIF
		_formsToModify.Add('01001B58');	// TreeRedPineFull01 "Red Pine Tree" [STAT:01001B58],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineFull01.nif
		_formsToModify.Add('01001B59');	// TreeRedPineHalf01 "Red Pine Tree" [STAT:01001B59],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineHalf01.nif
		_formsToModify.Add('01001B5A');	// TreeRedPineDead01 "Red Pine Tree" [STAT:01001B5A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineDead01.nif
		_formsToModify.Add('010024E4');	// FishDeadHaddock01 [STAT:010024E4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDeadHaddock01.nif
		_formsToModify.Add('010024F6');	// FishDeadMirelurkSpawn01 [STAT:010024F6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDeadMirelurkSpawn01.nif
		_formsToModify.Add('010024F9');	// TreeRedPineHalf02 "Red Pine Tree" [STAT:010024F9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineHalf02.nif
		_formsToModify.Add('010024FA');	// TreeRedPineDead02 "Red Pine Tree" [STAT:010024FA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineDead02.nif
		_formsToModify.Add('010024FB');	// TreeRedPineHalf03 "Red Pine Tree" [STAT:010024FB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineHalf03.nif
		_formsToModify.Add('010024FC');	// TreeBeachPine01 "Red Pine Tree" [STAT:010024FC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeBeachPine01.nif
		_formsToModify.Add('01002519');	// TreeRedPineHero01 "Red Pine Tree" [STAT:01002519],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineHero01.nif
		_formsToModify.Add('010025A4');	// TreeBeachPine02 "Dead Pine Tree" [STAT:010025A4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeBeachPine02.nif
		_formsToModify.Add('01002601');	// FishDeadMackerel01 [STAT:01002601],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDeadMackerel01.nif
		_formsToModify.Add('010026F7');	// KelpPile01 [STAT:010026F7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile01.nif
		_formsToModify.Add('010026F8');	// KelpPile02 [STAT:010026F8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile02.nif
		_formsToModify.Add('010026F9');	// KelpPile03 [STAT:010026F9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile03.nif
		_formsToModify.Add('010026FA');	// KelpPile04_Rowboat [STAT:010026FA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile04_Rowboat.nif
		_formsToModify.Add('010026FB');	// KelpPile05_Corner [STAT:010026FB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile05_Corner.nif
		_formsToModify.Add('010026FC');	// KelpPile06_Dock01 [STAT:010026FC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile06_Dock01.nif
		_formsToModify.Add('010026FD');	// KelpPile06_Railing [STAT:010026FD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile06_Railing.nif
		_formsToModify.Add('010026FE');	// KelpPile07 [STAT:010026FE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile07.nif
		_formsToModify.Add('010026FF');	// KelpPile08_TrashClump02 [STAT:010026FF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile08_TrashClump02.nif
		_formsToModify.Add('01002700');	// KelpPile06_Dock02 [STAT:01002700],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile06_Dock02.nif
		_formsToModify.Add('01002B73');	// FishDeadHaddock02 [STAT:01002B73],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDeadHaddock02.nif
		_formsToModify.Add('01002B74');	// FishDeadHaddock03 [STAT:01002B74],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDeadHaddock03.nif
		_formsToModify.Add('01002B75');	// FishDeadMackerel02 [STAT:01002B75],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDeadMackerel02.nif
		_formsToModify.Add('01002B76');	// FishDeadMackerel03 [STAT:01002B76],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDeadMackerel03.nif
		_formsToModify.Add('01002BB5');	// KelpPile09_Lg [STAT:01002BB5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile09_Lg.nif
		_formsToModify.Add('01002BFC');	// KelpPile08_TrashClump01 [STAT:01002BFC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile08_TrashClump01.nif
		_formsToModify.Add('01002C12');	// KelpPile08_TrashClump03 [STAT:01002C12],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile08_TrashClump03.nif
		_formsToModify.Add('01002C43');	// KelpPile10_Sm01 [STAT:01002C43],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile10_Sm01.nif
		_formsToModify.Add('01002C44');	// KelpPile10_Sm02 [STAT:01002C44],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\KelpPile10_Sm02.nif
		_formsToModify.Add('01003C42');	// Bramble01_DLC03_01 [STAT:01003C42],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble01.nif
		_formsToModify.Add('01003C43');	// Bramble02_DLC03_01 [STAT:01003C43],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble02.nif
		_formsToModify.Add('01003C44');	// Bramble04_DLC03_01 [STAT:01003C44],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble04.nif
		_formsToModify.Add('01003C45');	// Creosote01_DLC03_01 [STAT:01003C45],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Creosote01.nif
		_formsToModify.Add('01003C46');	// Creosote02_DLC03_01 [STAT:01003C46],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Creosote02.nif
		_formsToModify.Add('01003C47');	// Creosote03_DLC03_01 [STAT:01003C47],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Creosote03.nif
		_formsToModify.Add('01003C48');	// Fern01_DLC03_01 [STAT:01003C48],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern01_DLC03.nif
		_formsToModify.Add('01003C49');	// Fern02_DLC03_01 [STAT:01003C49],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern02_DLC03.nif
		_formsToModify.Add('01003C4A');	// HollyShrub01_DLC03_01 [STAT:01003C4A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub01.nif
		_formsToModify.Add('01003C4B');	// HollyShrub02_DLC03_01 [STAT:01003C4B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub02.nif
		_formsToModify.Add('01003C4C');	// HollyShrub03_DLC03_01 [STAT:01003C4C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub03.nif
		_formsToModify.Add('01003C4D');	// HollyShrub04_DLC03_01 [STAT:01003C4D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub04.nif
		_formsToModify.Add('01003C4E');	// Bramble03_DLC03_01 [STAT:01003C4E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble03.nif
		_formsToModify.Add('01003C4F');	// Bramble01_DLC03_02 [STAT:01003C4F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble01.nif
		_formsToModify.Add('01003C50');	// Bramble02_DLC03_02 [STAT:01003C50],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble02.nif
		_formsToModify.Add('01003C51');	// Bramble03_DLC03_02 [STAT:01003C51],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble03.nif
		_formsToModify.Add('01003C52');	// Bramble04_DLC03_02 [STAT:01003C52],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\Bramble04.nif
		_formsToModify.Add('01003C53');	// Fern01_DLC03_02 [STAT:01003C53],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern01_DLC03.nif
		_formsToModify.Add('01003C54');	// Fern02_DLC03_02 [STAT:01003C54],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern02_DLC03.nif
		_formsToModify.Add('01003C55');	// HollyShrub01_DLC03_02 [STAT:01003C55],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub01.nif
		_formsToModify.Add('01003C56');	// HollyShrub02_DLC03_02 [STAT:01003C56],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub02.nif
		_formsToModify.Add('01003C57');	// HollyShrub03_DLC03_02 [STAT:01003C57],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub03.nif
		_formsToModify.Add('01003C58');	// HollyShrub04_DLC03_02 [STAT:01003C58],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\HollyShrub04.nif
		_formsToModify.Add('01003C59');	// Fern01_DLC03_03 [STAT:01003C59],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern01_DLC03.nif
		_formsToModify.Add('01003C5A');	// Fern02_DLC03_03 [STAT:01003C5A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern02_DLC03.nif
		_formsToModify.Add('01003C5B');	// Fern01_DLC03_04 [STAT:01003C5B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern01_DLC03.nif
		_formsToModify.Add('01003C5D');	// Fern02_DLC03_04 [STAT:01003C5D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Plants\TreeFern02_DLC03.nif
		_formsToModify.Add('0100443D');	// TreeRedPineFallen01 "Red Pine Tree" [STAT:0100443D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineFallen01.nif
		_formsToModify.Add('01004F4C');	// TreePineSmall01 "Red Pine Tree" [STAT:01004F4C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineSmall01.nif
		_formsToModify.Add('01004F4D');	// TreePineSmall02 "Red Pine Tree" [STAT:01004F4D],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineSmall02.nif
		_formsToModify.Add('01004F4E');	// TreePineSmall03 "Red Pine Tree" [STAT:01004F4E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineSmall03.nif
		_formsToModify.Add('01005434');	// TreeRedPineFull02 "Red Pine Tree" [STAT:01005434],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineFull01.nif
		_formsToModify.Add('01005436');	// TreePineSmall04 "Red Pine Tree" [STAT:01005436],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineSmall01.nif
		_formsToModify.Add('01005477');	// CreosoteShrubLarge01_DLC03_01 [STAT:01005477],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\FoothillsShrubLarge01.nif
		_formsToModify.Add('01005479');	// CreosoteShrubMedium01_DLC03_01 [STAT:01005479],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\FoothillsShrubMedium01.nif
		_formsToModify.Add('0100547B');	// CreosoteShrubSmall01_DLC03_01 [STAT:0100547B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\Plants\FoothillsShrubSmall01.nif
		_formsToModify.Add('010061E3');	// KelpPile12_Giant [STAT:010061E3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_Plain_Tiny_Mid02.nif
		_formsToModify.Add('010061EA');	// KelpPile11_LG [STAT:010061EA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_Plain_Tiny_Short01.nif
		_formsToModify.Add('010061EC');	// KelpPile13_Giant [STAT:010061EC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\ExtRubble_HiTec_Sm_Mid06.nif
		_formsToModify.Add('01006C88');	// TreeRedPineLog01 "Red Pine Tree" [STAT:01006C88],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineLog01.nif
		_formsToModify.Add('01006C8A');	// TreeRedPineStump01 "Red Pine Tree" [STAT:01006C8A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineStump01.nif
		_formsToModify.Add('01006C8C');	// TreeRedPineStump02 "Red Pine Tree" [STAT:01006C8C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeRedPineStump02.nif
		_formsToModify.Add('010072DF');	// TreeBeachPineStump01 "Red Pine Tree" [STAT:010072DF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeBeachPineStump02.nif
		_formsToModify.Add('010072E0');	// TreeBeachPineLog01 "Pine Tree" [STAT:010072E0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreeBeachPineLog01.nif
		_formsToModify.Add('0100FA8B');	// DirtSlope01_MarshTrash_DLC03 [STAT:0100FA8B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope01.nif
		_formsToModify.Add('0100FBF3');	// TrashClump03_DLC03 [STAT:0100FBF3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\Rubble\TrashClump03_DLC03.nif
		_formsToModify.Add('0100FBF4');	// TrashEdge02_DLC03 [STAT:0100FBF4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\Rubble\TrashEdge02_DLC03.nif
		_formsToModify.Add('0100FBF6');	// TrashPileWall02_DLC03 [STAT:0100FBF6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\Rubble\TrashPileWall02_DLC03.nif
		_formsToModify.Add('0100FBF7');	// TrashPileCorIn01_DLC03 [STAT:0100FBF7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\Rubble\TrashPileCorIn01_DLC03.nif
		_formsToModify.Add('0100FBF8');	// TrashClump02_DLC03 [STAT:0100FBF8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0100FBF9');	// TrashClump01_DLC03 [STAT:0100FBF9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0100FBFA');	// TrashEdge01_DLC03 [STAT:0100FBFA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge01.nif
		_formsToModify.Add('0100FBFB');	// TrashEdge03_DLC03 [STAT:0100FBFB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge03.nif
		_formsToModify.Add('0100FBFC');	// TrashEdge04_DLC03 [STAT:0100FBFC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge04.nif
		_formsToModify.Add('0100FBFD');	// TrashPileWall01_DLC03 [STAT:0100FBFD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('0100FBFE');	// TrashPileWall03_DLC03 [STAT:0100FBFE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('01024FE4');	// HotelGlassDebrisC [STAT:01024FE4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Architecture\Hotel\HotelGlassDebrisC.nif
		_formsToModify.Add('01024FE5');	// HotelGlassDebrisA [STAT:01024FE5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Architecture\Hotel\HotelGlassDebrisA.nif
		_formsToModify.Add('01024FE6');	// HotelGlassDebrisB [STAT:01024FE6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Architecture\Hotel\HotelGlassDebrisB.nif
		_formsToModify.Add('010281BB');	// TreePineRoots01 [STAT:010281BB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots01.nif
		_formsToModify.Add('010281BC');	// TreePineRoots04 [STAT:010281BC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots04.nif
		_formsToModify.Add('010281BD');	// TreePineRoots05 [STAT:010281BD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots05.nif
		_formsToModify.Add('010281BE');	// TreePineRoots02 [STAT:010281BE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots02.nif
		_formsToModify.Add('010281BF');	// TreePineRoots03 [STAT:010281BF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots03.nif
		_formsToModify.Add('010281D2');	// TreeBeachRoots01 [STAT:010281D2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots01.nif
		_formsToModify.Add('010281D4');	// TreeBeachRoots02 [STAT:010281D4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots02.nif
		_formsToModify.Add('010281D5');	// TreeBeachRoots03 [STAT:010281D5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots03.nif
		_formsToModify.Add('010281D6');	// TreeBeachRoots04 [STAT:010281D6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots04.nif
		_formsToModify.Add('010281D7');	// TreeBeachRoots05 [STAT:010281D7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\Landscape\Trees\TreePineRoots05.nif
		_formsToModify.Add('01033DC7');	// FishDead01_DLC03 [STAT:01033DC7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\FishDead01_DLC03.nif
		_formsToModify.Add('01033DC8');	// FishDead02_DLC03 [STAT:01033DC8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\fishdead02_DLC03.nif
		_formsToModify.Add('01033DC9');	// FishDead03_DLC03 [STAT:01033DC9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC03\SetDressing\FishRacks\fishdead03_DLC03.nif
		_formsToModify.Add('0103CDF8');	// DirtSlope02_MarshTrash_DLC03 [STAT:0103CDF8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\Landscape\DirtCliffs\DirtSlope02.nif
		_formsToModify.Add('0200D1E9');	// DLC04_ShrubGroupMD01 [SCOL:0200D1E9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D1E9.NIF
		_formsToModify.Add('0200D1EC');	// DLC04_ShrubGroupMD02 [SCOL:0200D1EC],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D1EC.NIF
		_formsToModify.Add('0200D1EE');	// DLC04_ShrubGroupSM01 [SCOL:0200D1EE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D1EE.NIF
		_formsToModify.Add('0200D1F0');	// DLC04_ShrubGroupSM04 [SCOL:0200D1F0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D1F0.NIF
		_formsToModify.Add('0200D2CE');	// DLC04_ShrubGroupSM03 [SCOL:0200D2CE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2CE.NIF
		_formsToModify.Add('0200D2D0');	// DLC04_ShrubGroupLG01 [SCOL:0200D2D0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2D0.NIF
		_formsToModify.Add('0200D2D2');	// DLC04_ShrubGroupMD04 [SCOL:0200D2D2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2D2.NIF
		_formsToModify.Add('0200D2D3');	// DLC04_ShrubGroupLG03 [SCOL:0200D2D3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2D3.NIF
		_formsToModify.Add('0200D2D4');	// DLC04_ShrubGroupLG05 [SCOL:0200D2D4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2D4.NIF
		_formsToModify.Add('0200D2D5');	// DLC04_ShrubGroupMD03 [SCOL:0200D2D5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2D5.NIF
		_formsToModify.Add('0200D2D6');	// DLC04_ShrubGroupSM02 [SCOL:0200D2D6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2D6.NIF
		_formsToModify.Add('0200D2D8');	// DLC04_ShrubGroupSM05 [SCOL:0200D2D8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2D8.NIF
		_formsToModify.Add('0200D2DF');	// DLC04_ShrubGroupLG02 [SCOL:0200D2DF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2DF.NIF
		_formsToModify.Add('0200D2F2');	// DLC04_ShrubGroupLG06 [SCOL:0200D2F2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2F2.NIF
		_formsToModify.Add('0200D2F4');	// DLC04_ShrubGroupLG04 [SCOL:0200D2F4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2F4.NIF
		_formsToModify.Add('0200D2F6');	// Hedgerow04_Briars_DLC04 [SCOL:0200D2F6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2F6.NIF
		_formsToModify.Add('0200D2F7');	// Hedgerow01_Briars_DLC04 [SCOL:0200D2F7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2F7.NIF
		_formsToModify.Add('0200D2F9');	// Hedgerow02_Briars_DLC04 [SCOL:0200D2F9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000D2F9.NIF
		_formsToModify.Add('0200EF7F');	// Hedgerow03_Briars_DLC04 [SCOL:0200EF7F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0000EF7F.NIF
		_formsToModify.Add('020392E4');	// TreeBlastedForestCluster08_DLC05 [SCOL:020392E4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM000392E4.NIF
		_formsToModify.Add('020392E6');	// TreeBlastedForestCluster07_DLC05 [SCOL:020392E6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM000392E6.NIF
		_formsToModify.Add('020392E8');	// TreeBlastedForestCluster06_DLC05 [SCOL:020392E8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM000392E8.NIF
		_formsToModify.Add('020392EB');	// TreeBlastedForestCluster09_DLC05 [SCOL:020392EB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM000392EB.NIF
		_formsToModify.Add('020392ED');	// TreeBlastedForestCluster10_DLC05 [SCOL:020392ED],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM000392ED.NIF
		_formsToModify.Add('02053566');	// DLC04_GauntletSCTrashClutter01 [SCOL:02053566],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053566.NIF
		_formsToModify.Add('0205356F');	// DLC04_GauntletSCTrashClutter03 [SCOL:0205356F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0005356F.NIF
		_formsToModify.Add('02053594');	// DLC04_GauntletSCTrashClutter04 [SCOL:02053594],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053594.NIF
		_formsToModify.Add('02053626');	// DLC04_GauntletSCTrashClutter08 [SCOL:02053626],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053626.NIF
		_formsToModify.Add('02053628');	// DLC04_GauntletSCTrashClutter09 [SCOL:02053628],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053628.NIF
		_formsToModify.Add('0205362A');	// DLC04_GauntletSCTrashClutter10 [SCOL:0205362A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0005362A.NIF
		_formsToModify.Add('02053630');	// DLC04_GauntletSCTrashClutter13 [SCOL:02053630],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053630.NIF
		_formsToModify.Add('02053632');	// DLC04_GauntletSCTrashClutter14 [SCOL:02053632],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053632.NIF
		_formsToModify.Add('02053634');	// DLC04_GauntletSCTrashClutter15 [SCOL:02053634],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053634.NIF
		_formsToModify.Add('02053636');	// DLC04_GauntletSCTrashClutter16 [SCOL:02053636],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053636.NIF
		_formsToModify.Add('02053638');	// DLC04_GauntletSCTrashClutter17 [SCOL:02053638],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053638.NIF
		_formsToModify.Add('0205363A');	// DLC04_GauntletSCTrashClutter18 [SCOL:0205363A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0005363A.NIF
		_formsToModify.Add('0205363C');	// DLC04_GauntletSCTrashClutter19 [SCOL:0205363C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0005363C.NIF
		_formsToModify.Add('0205363E');	// DLC04_GauntletSCTrashClutter20 [SCOL:0205363E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM0005363E.NIF
		_formsToModify.Add('02053640');	// DLC04_GauntletSCTrashClutter21 [SCOL:02053640],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053640.NIF
		_formsToModify.Add('02053642');	// DLC04_GauntletSCTrashClutter22 [SCOL:02053642],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053642.NIF
		_formsToModify.Add('02053644');	// DLC04_GauntletSCTrashClutter23 [SCOL:02053644],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SCOL\DLCNukaWorld.esm\CM00053644.NIF
		_formsToModify.Add('0200AEE6');	// Briar_TreeL01 [STAT:0200AEE6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\Briar_TreeL01.nif
		_formsToModify.Add('0200AEE7');	// Briar_TreeM01 [STAT:0200AEE7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\Briar_TreeM01.nif
		_formsToModify.Add('0200AEE8');	// Briar_TreeS01 [STAT:0200AEE8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\Briar_TreeS01.nif
		_formsToModify.Add('0200B408');	// DLC04_DebrisPile01_WetMud "Debris" [STAT:0200B408],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\MudTrash\DLC04_DebrisPile01_WetMud.nif
		_formsToModify.Add('0200B40B');	// DLC04_DebrisMound01_WetMud "Debris" [STAT:0200B40B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\MudTrash\DLC04_DebrisMound01_WetMud.nif
		_formsToModify.Add('0200CBA9');	// TrashClump01_DLC04_ValleyGrass "Trash" [STAT:0200CBA9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0200CBAD');	// TrashClump01_DLC04_ValleyDirt "Trash" [STAT:0200CBAD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0200CBB0');	// TrashClump02_DLC04_ValleyDirt "Trash" [STAT:0200CBB0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0200CBB2');	// TrashClump02_DLC04_ValleyGrass "Trash" [STAT:0200CBB2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0200CBB4');	// TrashClump03_DLC04_ValleyDirt "Trash" [STAT:0200CBB4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('0200CBB5');	// TrashClump03_DLC04_ValleyGrass "Trash" [STAT:0200CBB5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('0200CBBB');	// TrashPileCorIn01_DLC04_ValleyGrass "Trash" [STAT:0200CBBB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('0200CBBD');	// TrashPileCorIn01_DLC04_ValleyDirt "Trash" [STAT:0200CBBD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('0200CBBE');	// TrashPileWall01_DLC04_ValleyGrass "Trash" [STAT:0200CBBE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('0200CBC0');	// TrashPileWall01_DLC04_ValleyDirt "Trash" [STAT:0200CBC0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('0200CBC1');	// TrashPileWall02_DLC04_ValleyGrass "Trash" [STAT:0200CBC1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02.nif
		_formsToModify.Add('0200CBC3');	// TrashPileWall02_DLC04_ValleyDirt "Trash" [STAT:0200CBC3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02.nif
		_formsToModify.Add('0200CBC4');	// TrashPileWall03_DLC04_ValleyGrass "Trash" [STAT:0200CBC4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('0200CBC6');	// TrashPileWall03_DLC04_ValleyDirt "Trash" [STAT:0200CBC6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('0200CCCD');	// TrashEdge01_DLC04_ValleyDirt "Trash" [STAT:0200CCCD],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge01.nif
		_formsToModify.Add('0200CCDE');	// TrashClump02_DLC04_HillGrass "Trash" [STAT:0200CCDE],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0200CCDF');	// TrashClump03_DLC04_HillGrass "Trash" [STAT:0200CCDF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('0200CCE0');	// TrashClump01_DLC04_HillGrass "Trash" [STAT:0200CCE0],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0200CCE1');	// TrashPileWall01_DLC04_HillGrass "Trash" [STAT:0200CCE1],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('0200CCE2');	// TrashPileWall02_DLC04_HillGrass "Trash" [STAT:0200CCE2],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02.nif
		_formsToModify.Add('0200CCE3');	// TrashPileCorIn01_DLC04_HillGrass "Trash" [STAT:0200CCE3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('0200CCE4');	// TrashPileWall03_DLC04_HillGrass "Trash" [STAT:0200CCE4],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('0200CCE5');	// TrashClump02_DLC04_HillDirt "Trash" [STAT:0200CCE5],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump02.nif
		_formsToModify.Add('0200CCE6');	// TrashClump03_DLC04_HillDirt "Trash" [STAT:0200CCE6],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump03.nif
		_formsToModify.Add('0200CCE7');	// TrashClump01_DLC04_HillDirt "Trash" [STAT:0200CCE7],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashClump01.nif
		_formsToModify.Add('0200CCE8');	// TrashPileWall01_DLC04_HillDirt "Trash" [STAT:0200CCE8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall01.nif
		_formsToModify.Add('0200CCE9');	// TrashPileCorIn01_DLC04_HillDirt "Trash" [STAT:0200CCE9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCorIn01.nif
		_formsToModify.Add('0200CCEA');	// TrashPileWall02_DLC04_HillDirt "Trash" [STAT:0200CCEA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall02.nif
		_formsToModify.Add('0200CCEB');	// TrashPileWall03_DLC04_HillDirt "Trash" [STAT:0200CCEB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileWall03.nif
		_formsToModify.Add('0200CCED');	// TrashEdge02_DLC04_ValleyDirt "Trash" [STAT:0200CCED],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge02.nif
		_formsToModify.Add('0200CCEF');	// TrashEdge03_DLC04_ValleyDirt "Trash" [STAT:0200CCEF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge03.nif
		_formsToModify.Add('0200CCF3');	// TrashEdge04_DLC04_ValleyDirt "Trash" [STAT:0200CCF3],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashEdge04.nif
		_formsToModify.Add('0200CCF8');	// TrashPileCor01_DLC04_ValleyGrass "Trash" [STAT:0200CCF8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCor01.nif
		_formsToModify.Add('0200CCF9');	// TrashPileCor01_DLC04_ValleyDirt "Trash" [STAT:0200CCF9],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCor01.nif
		_formsToModify.Add('0200CCFA');	// TrashPileCor01_DLC04_HillGrass "Trash" [STAT:0200CCFA],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCor01.nif
		_formsToModify.Add('0200CCFB');	// TrashPileCor01_DLC04_HillDirt "Trash" [STAT:0200CCFB],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\SetDressing\Rubble\TrashPileCor01.nif
		_formsToModify.Add('0200D18C');	// DLC04_DebrisMound02_WetMud "Debris" [STAT:0200D18C],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\MudTrash\DLC04_DebrisMound02_WetMud.nif
		_formsToModify.Add('0201DBFF');	// Briar_VinesM01 [STAT:0201DBFF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\Briar_VinesM01.nif
		_formsToModify.Add('0201E2D8');	// Briar_VinesS01 [STAT:0201E2D8],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\Briar_VinesS01.nif
		_formsToModify.Add('02027778');	// BlastedForestVinesCluster02 [STAT:02027778],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\BlastedForestVinesCluster02.nif
		_formsToModify.Add('02027779');	// BlastedForestVinesCorner01 [STAT:02027779],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\BlastedForestVinesCorner01.nif
		_formsToModify.Add('0202777A');	// BlastedForestVinesCorner02 [STAT:0202777A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\BlastedForestVinesCorner02.nif
		_formsToModify.Add('0202777B');	// BlastedForestVinesHanging03 [STAT:0202777B],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Landscape\Plants\BlastedForestVinesHanging03.nif
		_formsToModify.Add('0202A18A');	// DLC04_TrashClump01 [STAT:0202A18A],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\SetDressing\TrashObjects\DLC04_TrashClump01.nif
		_formsToModify.Add('0202B5FF');	// DLC04_TrashClump02 [STAT:0202B5FF],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\SetDressing\TrashObjects\DLC04_TrashClump02.nif
		_formsToModify.Add('0202B615');	// DLC04_TrashEdge01 [STAT:0202B615],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\SetDressing\TrashObjects\DLC04_TrashEdge01.nif
		_formsToModify.Add('0203F65E');	// GlassDebrisB_DLC04 [STAT:0203F65E],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Architecture\Overlook\GlassDebrisB_DLC04.nif
		_formsToModify.Add('0203F65F');	// GlassDebrisC_DLC04 [STAT:0203F65F],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Architecture\Overlook\GlassDebrisC_DLC04.nif
		_formsToModify.Add('0203F660');	// GlassDebrisA_DLC04 [STAT:0203F660],				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\DLC04\Architecture\Overlook\GlassDebrisA_DLC04.nif
        
    end; // end function Initialize

//====================================================================================================================================================
// Main process, goes through each record in the selected file one by one. Takes for fucking ever. Also, single threaded and locks up the UI. sOutput and _exceptionCountMax provided as relief for out of control scripts.
//====================================================================================================================================================
function Process(e: IInterface): Integer;
    begin
        Result := 0;
        
        // -------------------------------------------------------------------------------
        // incrememnt the record count and exit the script if we go over the limit. Used for debugging.
        _recordCount := _recordCount + 1;
        if(_recordCount > _recordCountMax) then 
        begin
            Result := 1;
            Exit;
        end;
        // -------------------------------------------------------------------------------

        // -------------------------------------------------------------------------------
        // set up plugin, masters, and globals
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
        
        // Set the _fullPath, _name, and _signature globals
        _fullPath := FullPath(e);
        _name := Name(e);
        _signature := Signature(e);
        // -------------------------------------------------------------------------------

        // -------------------------------------------------------------------------------
        // Entry Criteria ... Exit if SkipThis returns true.
        if(SkipThis(e) = True) then Exit;
        // -------------------------------------------------------------------------------

        // -------------------------------------------------------------------------------
        // Go through the form list. If one matches a base form in the _name then place a light there. A TDictionary lookup of the base form ID would be 1000 times faster but we don't have access to TDictionary >:(    
        // spit out _formsToModify as a comma sparated list and check that list for the presence of the form ID stripped out of the NAME
        try
            if(pos(_name, _formsToModify.CommaText) <> 0) then Result := PlaceLight(e); // Do the actual work within PlaceLight
        except
            on Ex: Exception do 
            begin
                Result := LogException(Ex,'Caught placing the light.'); 
            end; // end on Ex
        end; // end try/except
        // -------------------------------------------------------------------------------

    end; // end function Process

//====================================================================================================================================================
// Sort the masters then exit.
//====================================================================================================================================================
function Finalize: Integer;
    begin
        if Assigned(_plugin) then SortMasters(_plugin);
        
        // output the completion time so we can guage actual script run time ... because fo4edit loses track going over an hour.
        AddMessage(CurrentTime(_timeFormat) + ': Script complete');

        Result := 0;
    end; // end function Finalize

//====================================================================================================================================================
// Entry Criteria, returns true if we skip this item due to not REFR type, empty full path, empty name, or a match in the _thingsToIgnore list against the full path.
// Also sets Globals _fullPath and _name for later use.
//====================================================================================================================================================
function SkipThis(e: IInterface): boolean;
    var
        a: Integer; // Iterator
    begin
        // -------------------------------------------------------------------------------
        // skip if not a reference type
        if _signature <> 'REFR' then 
        begin
            Result := true;
            Exit;
        end; // end if
        
        // -------------------------------------------------------------------------------
        // Skip if the full path is blank for some reason        
        if _fullPath = '' then 
        begin
            Result := true;
            Exit;
        end; // end if

        // -------------------------------------------------------------------------------
        // Skip if the name is blank for some reason
        if _name = '' then
        begin
            Result := true;
            Exit;
        end; // end if
        
        // -------------------------------------------------------------------------------
        // Go through the _thingsToIgnore list. If one matches anything in the full path then skip. Gets slower as the list gets longer.            
        for a := 0 to _thingsToIgnore.Count - 1 do
        begin
            if(pos(_thingsToIgnore.Strings[a], _fullPath) <> 0) then
            begin
                Result := true;
                Exit;
            end // end if
            else
            begin
                a := a + 1;
            end; // end else
        end; // end for

        // -------------------------------------------------------------------------------
        // strip the name down to the base form ID only for static objects or static collections ... everything else we toss. I thought the filter would handle this, it seems it does not.
        // do NOT skip references with static base types
        if(pos('[STAT:', _name) <> 0) then 
        begin
            _name := copy(_name, (pos('[STAT:', _name) + 6), 8);
            Result := false;
            Exit;
        end;
        
        // -------------------------------------------------------------------------------
        // do NOT skip references with static collection base types
        if(pos('[SCOL:', _name) <> 0) then 
        begin
            _name := copy(_name, (pos('[SCOL:', _name) + 6), 8);
            Result := false;
            Exit;
        end;

        // -------------------------------------------------------------------------------
        // If we've made it this far, this is a reference type but it's base form isn't STAT or SCOL, so we're not sure what's in the name ... toss it
        Result := true;
        Exit;
    
    end; // end function SkipThis


//====================================================================================================================================================
// Logs an Exception and increments the exception count. Limited by _exceptionCountMax and _outputCountMax
//====================================================================================================================================================
function LogException(Ex: Exception; context: String): Integer;
    begin
        if(_exceptionCount < _exceptionCountMax) then
        begin
            AddMessage(CurrentTime(_timeFormat) + ': Exception Caught - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
            AddMessage(CurrentTime(_timeFormat) + ': CONTEXT: ' + context);
            AddMessage(CurrentTime(_timeFormat) + ': NAME: ' + _name);
            AddMessage(CurrentTime(_timeFormat) + ': FULL PATH: ' + _fullPath);
            AddMessage(CurrentTime(_timeFormat) + ': REASON: ' + Ex.Message);                
            AddMessage(CurrentTime(_timeFormat) + ': Exception Caught - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
            
            // increment the global exception count
            _exceptionCount := _exceptionCount + 1;
            Result := 0;
            Exit;
        end
        else
        begin
            // This will cause the script to halt when passed out to the main loop
            Result := 1;
            Exit;
        end;
    end; // end function LogException

//====================================================================================================================================================
// returns the current time
//====================================================================================================================================================
function CurrentTime(sTimeFormat: String): AnsiString;
    var
        asTime: AnsiString;
    begin
        try
            DateTimeToString(asTime, sTimeFormat, Time);
            Result := asTime;
            Exit;
        except
            on Ex: Exception do 
            begin
                LogException(Ex,'Caught getting the current time.');
                Result := 'Sad Trombone';
                Exit;
            end; // end on Ex
        end; // end try/except 
    end; // end function CurrentTime

//====================================================================================================================================================
// An output function that limits the output to _outputCountMax lines then returns 1 after that without logging.
//====================================================================================================================================================
function sOutput(sIn: String): Integer;
    begin
        if(_outputCount < _outputCountMax) then
        begin
            AddMessage(CurrentTime(_timeFormat) + ': ' + sIn); // output with a timestamp
            _outputCount := _outputCount + 1; // increment the global record output count
            Result := 0;
            Exit;
        end
        else
        begin
            Result := 1; // Exit wit result := 1 to pass on to the main loop so the program can be halted if desired.
            Exit;
        end;
    end; // end function sOutput

//====================================================================================================================================================
// place a green, shimmery light at the coordinates of e - Original: NAME - Base = DefaultLightWaterGlowingSea01NSCaustics [LIGH:00204273] - copied one [REFR:00215EB1] to newLight right above
// We may need to mess with the light density once the placement works. We'll do that by removing the copied lights, then removing entries from _formsToModify and rerunning the script until we get good distribution.
//====================================================================================================================================================
function PlaceLight(e: IInterface): integer;
    var
        oldLight, newLight: IInterface;  // the old light ripped from fallout4.esm, the new light copied into the plugin
        sCell: String;                   // e's current CELL information
        pX, pY, pZ, rX, rY, rZ: Integer; // original position and rotation information of e
    begin
        if(_itemsPlaced < _itemsPlacedMax) then
        begin
            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // set result to 0, we can change it to 1 if need be before exiting.
            Result := 0;
            
            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // get the X, Y, and Z coordinates of the item as well as the CELL info. Modify Z to be up 3 from original position and hopefully keep the lights from underground.
            try      
                pX := GetElementNativeValues(e, 'DATA\Position\X');
                pY := GetElementNativeValues(e, 'DATA\Position\Y');
                pZ := GetElementNativeValues(e, 'DATA\Position\Z');
                pZ := pZ + 3;
                rX := GetElementNativeValues(e, 'DATA\Rotation\X');
                rY := GetElementNativeValues(e, 'DATA\Rotation\Y');
                rZ := GetElementNativeValues(e, 'DATA\Rotation\Z');
                sCell := GetElementEditValues(e, 'CELL');
            except
                on Ex: Exception do 
                begin
                    Result := LogException(Ex,'Caught getting CELL, poition, and rotation values from e.');
                    Exit;
                end; // end on Ex
            end; // end try/except
            
            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // copy one glowing sea light for distribution about the commonwealth, Far Harbor, and Nuka World
            try
                oldLight := RecordByFormID(FileByIndex(0), $00215EB1, False);
                AddRequiredElementMasters(oldLight, _plugin, False);
            except
                on Ex: Exception do 
                begin
                    Result := LogException(Ex,'Caught Copying the original light.'); 
                    Exit;
                end; // end on Ex
            end; // end try/except
            
            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // Copy the new light to the plugin
            try
                newLight := wbCopyElementToFile(oldLight, _plugin, True, True); // copy new light reference record to plugin
                AddRequiredElementMasters(newLight, _plugin, False);            // add masters to new element. We need this when adding the light to lost coast and nuka world ... I'm pretty sure.
            except
                on Ex: Exception do 
                begin
                    Result := LogException(Ex,'Caught copying the new light to the plugin.'); 
                    Exit;
                end; // end on Ex
            end; // end try/except
            
            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // modify the radius, and XLIG parameters
            try                
                SetElementNativeValues(newLight, 'XRDS', 5); //Random(1024)+1);                  // Random light radius between 0 and 1024
                SetElementNativeValues(newLight, 'XLIG\FOV 90+/-', 0.000000);              // not sure what this does. Left at default.
                SetElementNativeValues(newLight, 'XLIG\Fade 1.0+/-', 0.000000);            // not sure what this does. Left at default.
                SetElementNativeValues(newLight, 'XLIG\End Distance Cap', 0.000000);       // not sure what this does. Left at default.
                SetElementNativeValues(newLight, 'XLIG\Shadow Depth Bias', 1.000000);      // leave this, shadows with this number of lights would kill the framerate or make the game unplayable most likely. (if that's what the param even does)
                SetElementNativeValues(newLight, 'XLIG\Near Clip', 0.000000);              // not sure what this does. Left at default.
                SetElementNativeValues(newLight, 'XLIG\Volumetric Intensity', 0.000000);   // not sure what this does. Left at default.
            except
                on Ex: Exception do 
                begin
                    Result := LogException(Ex,'Caught modifying the new light XRDS or XLIG parameters.');
                    Exit;
                end; // end on Ex
            end; // end try/except

            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // modify position of the new light
            try
                SetElementNativeValues(newLight, 'DATA\Position\X', pX);   // Use original X position (vital!)
                SetElementNativeValues(newLight, 'DATA\Position\Y', pY);   // Use original Y position (vital!)
                SetElementNativeValues(newLight, 'DATA\Position\Z', pZ);   // Use modified Z position (vital!)
            except
                on Ex: Exception do 
                begin
                    Result := LogException(Ex,'Caught modifying the new light position.');
                    Exit;
                end; // end on Ex
            end; // end try/except

            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // modify rotation of the new light
            try    
                SetElementNativeValues(newLight, 'DATA\Rotation\X', rX);   // use original X rotation. It's a light, but it's not going to hurt anything.
                SetElementNativeValues(newLight, 'DATA\Rotation\Y', rY);   // use original Y rotation. It's a light, but it's not going to hurt anything.
                SetElementNativeValues(newLight, 'DATA\Rotation\Z', rZ);   // use original Z rotation. It's a light, but it's not going to hurt anything.
            except
                on Ex: Exception do 
                begin
                    Result := LogException(Ex,'Caught modifying the new light rotation.');
                    Exit;
                end; // end on Ex
            end; // end try/except

            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // Modify the CELL information to put the light in the correct vicinity
            try
                SetElementEditValues(newLight, 'CELL', sCell); // this needs to be the cell from the original object matching _formsToModify entries' cells (vital!)
            except
                on Ex: Exception do
                begin
                    Result := LogException(Ex,'Caught modifying the new light CELL.');
                    Exit;
                end; // end on Ex
            end; // end try/except
            
            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // tally up another item placed
            _itemsPlaced := _itemsPlaced + 1;
        end // end if
        else
        begin
            //---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            // exit with 1 if we've placed maximum items.
            Result := 1;
            Exit; 
        end; // end else
    end; // end function PlaceLights
end. // end script
