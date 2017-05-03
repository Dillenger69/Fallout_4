{
    list forms in selected worldspaces/cells. This is a companion script to 'Manipulate world forms.pas' Used to generate the _formsToChange list
    Author: dillenger69 (at) gmail.com
}
unit ListThings;

// All globals have an uncerscore at the beginning for easy identification.
var
    _useThese, _ignoreThese: TStringList;
    _recordCount, _recordLimit, _outputCount, _outputLimit, _exceptionCount, _exceptionLimit: Integer;
    _formTypes, _modelPath, _formFullPath, _formName, _editorId, _formType: String;

//====================================================================================================================================================
// runs once before "Process" kicks off for each record
//====================================================================================================================================================
function Initialize: Integer;
    begin
        // we can limit the number of output lines in case the script goes haywire the first time.
        Result := 0;
		_formTypes := 'STAT, SCOL'; // only static types and static collections
        _recordCount := 0;
        _recordLimit := 3000000; // there areroughly 2.2 million records between the three esm files so 3 million is a good overall limit ... just in case
        _outputCount := 0;
        _outputLimit := 10000; // hopefully not more than ten thousand output records.
        _exceptionCount := 0;
        _exceptionLimit := 1; // one exception is the limit for this script.

        // this is the list of keywords to ignore. Kick out forms before accepting them.
        _ignoreThese := TStringList.Create;
        _ignoreThese.NameValueSeparator := ',';
        _ignoreThese.Duplicates := dupIgnore;
        _ignoreThese.Sorted := False;
		_ignoreThese.Add('Bollard'); 		// Leave bollards alone
        _ignoreThese.Add('Privet'); 		// Leave privet hedges alone, realistically, they should be gone too, but keep them for some cover in sanctuary at the beginning
        _ignoreThese.Add('Street'); 		// anything with "Street" in it Upper case variant
        _ignoreThese.Add('Supermutant'); 	// anything related to supermutants
        _ignoreThese.Add('PreWar'); 		// anything related to prewar sanctuary
        _ignoreThese.Add('Institute'); 		// Leave the institiute alone
        _ignoreThese.Add('Sign'); 			// Leave signs alone
        _ignoreThese.Add('NoDecal'); 		// Leave this alone
        _ignoreThese.Add('Greeb'); 			// Leave Greebs alone
        _ignoreThese.Add('Brick'); 			// Leave Bricks alone
        _ignoreThese.Add('Totem'); 			// Leave Totems alone
        _ignoreThese.Add('Treehouse'); 		// Leave the treehouse be
        _ignoreThese.Add('Generator'); 		// Leave generators alone
        _ignoreThese.Add('MemoryBanks'); 	// Leave Dima's head alone
        _ignoreThese.Add('Greentech'); 		// Leave Greentech alone
        _ignoreThese.Add('Diamond'); 		// Leave diamond city's trash alone
        _ignoreThese.Add('Trashcan'); 		// Leave Trashcans alone
        _ignoreThese.Add('TrashBin'); 		// Leave trash bins alone
        _ignoreThese.Add('Airplane'); 		// Leave airplane debris alone
        _ignoreThese.Add('Artillery'); 		// Leave Artillery debris alone
        _ignoreThese.Add('Boards'); 		// Leave the boards be
        _ignoreThese.Add('LargeConc'); 		// Leave this alone
        _ignoreThese.Add('DinerInt'); 		// Stay out of here
        _ignoreThese.Add('Federalist'); 	// Stay out of here
        _ignoreThese.Add('MetalTable'); 	// Keep the metal tables
        _ignoreThese.Add('MetalShelf'); 	// Keep the metal shelves
        _ignoreThese.Add('PlayerHouse'); 	// Leave the playerhouse alone
        _ignoreThese.Add('Vault'); 			// Leave vaults alone
        _ignoreThese.Add('xmas'); 			// Leave the christmas tree alone
        _ignoreThese.Add('christmas'); 		// Leave the christmas tree alone
		_ignoreThese.Add('Cutout'); 		// leave the props alone
		_ignoreThese.Add('Raider');			// leave the raider props alone
		_ignoreThese.Add('MarketDecal'); 	// leave the market sign be in nuka world
		_ignoreThese.Add('NoRoots'); 		// leave it alone if it says noroots
		_ignoreThese.Add('MainWall'); 		// leave the walls in nuka world alone
		_ignoreThese.Add('DinerWall'); 		// leave the walls in the diner alone
		_ignoreThese.Add('BirdMarker'); 	// leave the bird markers even though the trees are gone
		_ignoreThese.Add('NFRoots'); 		// leave this thing
		_ignoreThese.Add('DirtCliffLarge'); // leave the cliffs
		_ignoreThese.Add('Dmg'); 			// leave the damage stuff
		_ignoreThese.Add('GrassMound'); 	// leave the crass mounds
		_ignoreThese.Add('GrassDirt'); 		// leave the grass and dirt
		_ignoreThese.Add('CGNuke'); 		// leave the prewar swaying trees
		_ignoreThese.Add('FarmPlot'); 		// leave this alone
		_ignoreThese.Add('Trimmed'); 		// leave Codsworth's hedges
		_ignoreThese.Add('RockBlasted'); 	// leave rocks alone
		_ignoreThese.Add('ManRoot'); 		// man root?
		_ignoreThese.Add('TreeCircle'); 	// leave this alone
		_ignoreThese.Add('DecoMain'); 		// leave this alone
		_ignoreThese.Add('Protectron'); 	// leave this alone
		_ignoreThese.Add('PathBlocker'); 	// leave this alone
		_ignoreThese.Add('SWCurb'); 		// leave this alone
		_ignoreThese.Add('HWDouble'); 		// leave this alone
		_ignoreThese.Add('HWSingle'); 		// leave this alone
		_ignoreThese.Add('BLDG_Corner'); 	// leave the walls alone
        

        // this is the list of Keywords to include
        _useThese := TStringList.Create;
        _useThese.NameValueSeparator := ',';
        _useThese.Duplicates := dupIgnore;
        _useThese.Sorted := False;
        _useThese.Add('Barnacle');			// fuck the barnacles
        _useThese.Add('Branch');			// no stray branch piles
        _useThese.Add('BlastedForest');		// nothing in the blasted forest
        _useThese.Add('Bramble');			// no brambles
        _useThese.Add('Cattails');			// cattails gone
        _useThese.Add('Cedar');				// no cedar trees
        _useThese.Add('Clutter');			// remove dat clutter
        _useThese.Add('Creosote');			// fucking creosote
        _useThese.Add('DeadFlower');		// dead flowers ... meh
        _useThese.Add('Debris');			// clean up some of the debris
        _useThese.Add('Decal');				// ged rid of teh 2d trash
        _useThese.Add('Driftwood');			// driftwood should be long salvaged
        _useThese.Add('Fern');				// ferns gone
        _useThese.Add('FishDead');			// dead fish ... bleh
        _useThese.Add('Forsythia');			// forsythia is as bad as creosote
        _useThese.Add('LeafPile');			// clean up dem leaf piles
        _useThese.Add('HedgeRow');			// more like tangled mess row
        _useThese.Add('Kelp');				// does it burn? probably
        _useThese.Add('MarshMoss');			// dats good burnin'
        _useThese.Add('MarshScum');			// because
        _useThese.Add('RoseBush');			// not really
        _useThese.Add('RubChunkiesSmall');	// them damn rub chunkies!
        _useThese.Add('Rubble_Flat');		// more 2d shit gone
        _useThese.Add('Root');				// no trees means no roots
        _useThese.Add('Stump');				// thinking of leaving the stumps, but not sure
        _useThese.Add('Sapling');			// saplings? no way
        _useThese.Add('Shrub');				// they do not look like shrubs I know of
        _useThese.Add('Seaweed');			// again, does it burn? probably
        _useThese.Add('Tree');				// the meat of things ... KILL THE TREES
        _useThese.Add('Trash');				// really, it's been 200 years and there are brooms and shovels everywhere ... use them!
        _useThese.Add('Vine');				// vines gotta go

    end; // end function Initialize

//====================================================================================================================================================
// for each record that matches the criteria, print out a line to the screen to be used in another script.
//====================================================================================================================================================
function Process(e: IInterface): Integer;
    var
        i: Integer;
    begin
        // initialize all the globals that change per form.
        Result := 0;
        _modelPath := '';
        _formFullPath := '';
        _formName := '';
        _editorId := '';
        _formType := '';
        _recordCount := _recordCount + 1;
        
        // stop the script if we go over the record limit
        if(_recordCount >= _recordLimit) then
        begin
            Result := 1;
            Exit;
        end; // end if

        try
            // operate on the last override
            e := WinningOverride(e);
            
            // the signature is the form type ... Static = STAT, Static Collection = SCOL, Non-Player Character = NPC_, etc.
            _formType := Signature(e);

            // only use defined form types
            if Pos(_formType, _formTypes) = 0 then Exit;

            // get the needed data
            _formFullPath := FullPath(e);
            _formName := Name(e);
            _editorId := GetElementEditValues(e, 'EDID');
            _modelPath := GetElementEditValues(e, 'Model\MODL');

            // Ignore record if any of these are blank.
            if _formFullPath = '' then Exit;
            if _formName = '' then Exit;
            if _editorId = '' then Exit;
            if _modelPath = '' then Exit;
            
            // loop through the ignore list of keywords. Exit if one matches
            for i := 0 to _ignoreThese.Count - 1 do
            begin
                if (pos(AnsiUpperCase(_ignoreThese.Strings[i]), AnsiUpperCase(_editorId)) <> 0) then
                begin
                    Exit;
                end // end if
                else
                begin
                    i := i + 1;  
                end; // end else
            end; // end for

            // loop through the include list of keywords. If one matches, print out the _formsToChange and the path to the NIF
            for i := 0 to _useThese.Count - 1 do
            begin
                if (pos(AnsiUpperCase(_useThese.Strings[i]), AnsiUpperCase(_editorId)) <> 0) then
                begin
                    Result := OutputLine();
                    Exit;
                end; // end if
                
                i := i + 1;
            end; // end for

        except
            on Ex: Exception do 
            begin               
                // Exit with a 1 to halt the script if we hit a snag.
                Result := LogException(Ex, 'Exception Caught in main loop.', formName, formFullPath);
                Exit;
            end;    // end on Ex
        end;    // end try/except
    end;    // end function Process

//====================================================================================================================================================
//
//====================================================================================================================================================
function Finalize: integer;
    begin
    end; // end function Finalize

//====================================================================================================================================================
// An output function that limits the output to _outputLimit lines then returns 1 after that without printing to the screen.
//====================================================================================================================================================
function OutputLine: Integer;
    var
        formId, typeDelimiter: String;
    begin
        if(_outputCount < _outputLimit) then
        begin
            typeDelimiter := '[' + _formType + ':';
            formId := copy(_formName, (pos(typeDelimiter, _formName) + 6), 8);
            AddMessage('_formsToChange.Add(''' + formId + ''');	// ' + _formName + ',				model: C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\Data\Meshes\' + _modelPath);
            _outputCount := _outputCount + 1; // increment the global record output count
            Result := 0;
            Exit;
        end // end if
        else
        begin
            Result := 1; // Exit with result := 1 to pass on to the main loop so the program can be halted if desired.
            Exit;
        end; // end else
    end; // end function OutputLine

//====================================================================================================================================================
// Logs an Exception and increments the exception count. Limited by _exceptionLimit
//====================================================================================================================================================
function LogException(Ex: Exception; context, formName, formFullPath: String): Integer;
    begin
        if(_exceptionCount < _exceptionLimit) then
        begin
            AddMessage(CurrentTime() + ': Exception Caught - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
            AddMessage(CurrentTime() + ': CONTEXT: ' + context);
            AddMessage(CurrentTime() + ': NAME: ' + formName);
            AddMessage(CurrentTime() + ': FULL PATH: ' + formFullPath);
            AddMessage(CurrentTime() + ': REASON: ' + Ex.Message);                
            AddMessage(CurrentTime() + ': Exception Caught - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ');
            
            // increment the global exception count and check to see what we return.
            _exceptionCount := _exceptionCount + 1;
            if(_exceptionCount >= _exceptionLimit) then
            begin
                Result := 1;
                Exit;
            end
            else
            begin
                Result := 0;
                Exit;
            end;
        end
        else
        begin
            Result := 1; // This will cause the script to halt when passed out to the main loop
            Exit;
        end;
    end; // end function LogException

//====================================================================================================================================================
// returns the current time in 24 hour format
//====================================================================================================================================================
function CurrentTime: AnsiString;
    var
        asTime: AnsiString;
        sTimeFormat: String;
    begin
        sTimeFormat := 'hh:nn:ss';
        DateTimeToString(asTime, sTimeFormat, Time);
        Result := asTime;
        Exit;
    end; // end function CurrentTime

end.