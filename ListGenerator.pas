{
    list forms in selected worldspaces/cells. This is a companion script to 'Manipulate world forms.pas' Used to generate the _formsToChange list
    Author: dillenger69 (at) gmail.com
}
unit ListThings;

// I gave all global variables an uncerscore at the beginning for easy identification.
var
    _plugin: IInterface;
    _recordTypes, _fullPath, _formId, _name, _path: String;
    _useThese, _ignoreThese, _killScript: TStringList;
    _recordCount, _recordLimit: Integer;

//====================================================================================================================================================
// runs once before "Process" kicks off for each record
//====================================================================================================================================================
function Initialize: Integer;
    begin
        // we limit the number of output lines in case the script goes haywire.
        _recordCount := 0;
        _recordLimit := 2000;
        _recordTypes := 'STAT, SCOL';

        // used to kill rogue scripts when necessary since HALT doesn't seem to work.'
        _killScript := TStringList.Create;
        
        // this is the list of keywords to ignore. Kick out forms before accepting them.
        _ignoreThese := TStringList.Create;
        _ignoreThese.NameValueSeparator := ',';
        _ignoreThese.Duplicates := dupIgnore;
        _ignoreThese.Sorted := False;
        _ignoreThese.Add('Privet'); // Leave privet hedges alone
        _ignoreThese.Add('street'); // anything with "street" in it like streetlamps or streetcorners
        _ignoreThese.Add('Street'); // anything with "Street" in it Upper case variant
        _ignoreThese.Add('Supermutant'); // anything related to supermutants
        _ignoreThese.Add('prewar'); // anything related to prewar sanctuary
        _ignoreThese.Add('PreWar'); // anything related to prewar sanctuary
        _ignoreThese.Add('Prewar'); // anything related to prewar sanctuary
        _ignoreThese.Add('Institute'); // Leave the institiute alone
        _ignoreThese.Add('institute'); // Leave the institiute alone
        _ignoreThese.Add('Sign'); // Leave signs alone
        _ignoreThese.Add('sign'); // Leave signs alone
        _ignoreThese.Add('NoDecal'); // Leave this alone
        _ignoreThese.Add('greeb'); // Leave greebs alone
        _ignoreThese.Add('Greeb'); // Leave Greebs alone
        _ignoreThese.Add('brick'); // Leave bricks alone
        _ignoreThese.Add('Brick'); // Leave Bricks alone
        _ignoreThese.Add('totem'); // Leave totems alone
        _ignoreThese.Add('Totem'); // Leave Totems alone
        _ignoreThese.Add('Treehouse'); // Leave the treehouse be
        _ignoreThese.Add('TreeHouse'); // Leave the treehouse be
        _ignoreThese.Add('treehouse'); // Leave the treehouse be
        _ignoreThese.Add('generator'); // Leave generators alone
        _ignoreThese.Add('Generator'); // Leave Generators alone
        _ignoreThese.Add('MemoryBanks'); // Leave Dima's head alone
        _ignoreThese.Add('Greentech'); // Leave Greentech alone
        _ignoreThese.Add('Diamond'); // Leave diamond city's trash alone
        _ignoreThese.Add('Trashcan'); // Leave Trashcans alone
        _ignoreThese.Add('TrashBin'); // Leave trash bins alone
        _ignoreThese.Add('Airplane'); // Leave airplane debris alone
        _ignoreThese.Add('Artillery'); // Leave Artillery debris alone
        _ignoreThese.Add('Boards'); // Leave the boards be
        _ignoreThese.Add('LargeConc'); // Leave this alone
        _ignoreThese.Add('DinerInt'); // Stay out of here
        _ignoreThese.Add('Federalist'); // Stay out of here
        _ignoreThese.Add('MetalTable'); // Keep the metal tables
        _ignoreThese.Add('MetalShelf'); // Keep the metal shelves
        _ignoreThese.Add('PlayerHouse'); // Leave the playerhouse alone
        _ignoreThese.Add('Vault'); // Leave vaults alone
        

        // this is the list of Keywords to include
        _useThese := TStringList.Create;
        _useThese.NameValueSeparator := ',';
        _useThese.Duplicates := dupIgnore;
        _useThese.Sorted := False;
        _useThese.Add('Tree'); // Kill the trees
        _useThese.Add('Branch'); // There are branch piles, etc
        _useThese.Add('Vine'); // Get rid of those vines
        _useThese.Add('LeafPile'); // without trees we don't need leaf piles
        _useThese.Add('BlastedForest'); // Kill those blasted forest things
        _useThese.Add('Bramble'); // No Brambles
        _useThese.Add('Shrub'); // No Shrubs
        _useThese.Add('shrub'); // No shrubs
        _useThese.Add('Fern'); // No Ferns
        _useThese.Add('Forsythia'); // No Forsythia
        _useThese.Add('HedgeRow'); // It's not a hedge, it's a mess
        _useThese.Add('Creosote'); // No Creosote
        _useThese.Add('RoseBush'); // it's not a rose bush, it's a mess
        _useThese.Add('Seaweed'); // No Seaweed
        _useThese.Add('MarshMoss'); // nothing for moss to hang from
        _useThese.Add('Decal'); // Get rid of as many decals as possible
        _useThese.Add('Trash'); // Clean up that trash
        _useThese.Add('Clutter'); // Clean up that clutter
        _useThese.Add('Debris'); // Clean up that debris

    end;

//====================================================================================================================================================
// Runs for each record
//====================================================================================================================================================
function Process(e: IInterface): Integer;

    var
        i, a: Integer;
        hFixedFormId: String;

    begin
        try
            // operate on the last override
            e := WinningOverride(e);
            
            // only use defined record types
            if Pos(Signature(e), _recordTypes) = 0 then
                Exit;

            // get the needed data
            _path := Path(e);
            _fullPath := FullPath(e);
            _name := Name(e);
            _formId := GetElementEditValues(e, 'Record Header\FormId');

            // Exclude forms without a full path
            if _fullPath = '' then
                Exit;            
            
            // Exclude forms without a form ID
            if _formId = '' then
                Exit;

            // Exclude forms without a name
            if _name = '' then
                Exit;

            // loop through the ignore list of keywords
            for i := 0 to _ignoreThese.Count - 1 do
            begin
                if pos(_ignoreThese.Strings[i], _name) <> 0 then
                begin
                    Exit;
                end;
                i := i + 1;
            end;

            // loop through the include list of keywords.
            for a := 0 to _useThese.Count - 1 do
            begin
                
                // Print out the line if we have a match then exit for the next record
                if pos(_useThese.Strings[a], _name) <> 0 then
                begin
                    hFixedFormId := IntToHex(FixedFormID(e), 8);
                    AddMessage('_formsToChange.Add(''' + hFixedFormId + '''); // ' + _name);
                    _recordCount := _recordCount + 1;
                    
                    // if we have more than _recordLimit then exit the script
                    if _recordCount > _recordLimit then
                    begin
                        AddMessage(_killScript.ValueFromIndex[9999]); 
                    end;
                    Exit;
                end;
                a := a + 1;
            end;
        except
            on Ex: Exception do 
            begin
                Result := 1;
                AddMessage('Exception Caught - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
                AddMessage('NAME: ' + _name);
                AddMessage('FULL PATH: ' + _fullPath);
                AddMessage('REASON: ' + Ex.Message);
                
                // give this a high enough index to halt the program since 'Halt' doesn't seem to work.
                AddMessage(_formsToChange.ValueFromIndex[9999]);
            end;
        end;
    end;

//====================================================================================================================================================
//
//====================================================================================================================================================
function Finalize: integer;
    begin
    end;
end.