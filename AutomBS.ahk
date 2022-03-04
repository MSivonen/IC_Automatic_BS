#SingleInstance Force
#include %A_ScriptDir%
#include JSON.ahk
#include idledict.ahk

;Special thanks to all the idle dragons who inspired and assisted me!
global VersionNumber := "2.00"
global CurrentDictionary := "2.00"

;Local File globals
global OutputLogFile := "idlecombolog.txt"
global SettingsFile := "idlecombosettings.json"
global UserDetailsFile := "userdetails.json"
global BlacksmithLogFile := "blacksmithlog.json"
global CurrentSettings := []
global GameInstallDir := "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\"
global WRLFile := GameInstallDir "IdleDragons_Data\StreamingAssets\downloaded_files\webRequestLog.txt"
global DictionaryFile := "https://raw.githubusercontent.com/dhusemann/idlecombos/master/idledict.ahk"
global LocalDictionary := "idledict.ahk"

global ICSettingsFile := A_AppData
StringTrimRight, ICSettingsFile, ICSettingsFile, 7
ICSettingsFile := ICSettingsFile "LocalLow\Codename Entertainment\Idle Champions\localSettings.json"
global GameClient := GameInstallDir "IdleDragons.exe"

;Settings globals
global ServerName := "ps7"
global GetDetailsonStart := 0
global FirstRun := 1
global AlwaysSaveContracts := 0
global NoSaveSetting := 0
global SettingsCheckValue := 11 ;used to check for outdated settings file
global NewSettings := JSON.stringify({"servername":"ps7","firstrun":0,"user_id":0,"hash":0,"instance_id":0,"getdetailsonstart":0,"launchgameonstart":0,"alwayssavechests":1,"alwayssavecontracts":1,"alwayssavecodes":1, "NoSaveSetting":0})

;Server globals
global DummyData := "&language_id=1&timestamp=0&request_id=0&network_id=11&mobile_client_version=999"
global CodestoEnter := ""

;User info globals
global UserID := 0
global UserHash := 0
global InstanceID := 0
global UserDetails := []
global ActiveInstance := 0
global ChampDetails := ""
global TotalChamps := 0
;Inventory globals
global CurrentTinyBS := ""
global CurrentSmBS := ""
global CurrentMdBS := ""
global CurrentLgBS := ""
global AvailableBSLvs := ""
global BrivSlot4 := 0
global BrivZone := 0
global RadioGroup1 = 0
global RadioGroup2 = 0
global RadioGroup3 = 0
global OtherID = 0
global AutomBSChamp = 75
global BSChampTXT = 999

;GUI globals
global oMyGUI := ""
global OutputText := "Test"
global OutputStatus := "Welcome to IdleCombos v" VersionNumber
global CurrentTime := ""
global LastUpdated := "No data loaded."
global TrayIcon := systemroot "\system32\imageres.dll"
global LastBSChamp := ""
global automTXT := "Automation not running"
global TimeLeft = 0
global timeleftTXT = TimeLeft

global counter := new SecondCounter


;BEGIN:	default run commands
if FileExist(TrayIcon) {
	if (SubStr(A_OSVersion, 1, 2) == 10) {
		Menu, Tray, Icon, %TrayIcon%, 300
	}
	else if (A_OSVersion == "WIN_8") {
		Menu, Tray, Icon, %TrayIcon%, 284
	}
	else if (A_OSVersion == "WIN_7") {
		Menu, Tray, Icon, %TrayIcon%, 78
	}
	else if (A_OSVersion == "WIN_VISTA") {
		Menu, Tray, Icon, %TrayIcon%, 77
	} ; WIN_8.1, WIN_2003, WIN_XP, WIN_2000, WIN_NT4, WIN_95, WIN_98, WIN_ME
}
UpdateLogTime()
FileAppend, (%CurrentTime%) IdleCombos v%VersionNumber% started.`n, %OutputLogFile%
FileRead, OutputText, %OutputLogFile%
if (!oMyGUI) {
	oMyGUI := new MyGui()
}
;First run checks and setup
if !FileExist(SettingsFile) {
	FileAppend, %NewSettings%, %SettingsFile%
	UpdateLogTime()
	FileAppend, (%CurrentTime%) Settings file "idlecombosettings.json" created.`n, %OutputLogFile%
	FileRead, OutputText, %OutputLogFile%
	oMyGUI.Update()
}
FileRead, rawsettings, %SettingsFile%
CurrentSettings := JSON.parse(rawsettings)
if !(CurrentSettings.Count() == SettingsCheckValue) {
	FileDelete, %SettingsFile%
	FileAppend, %NewSettings%, %SettingsFile%
	UpdateLogTime()
	FileAppend, (%CurrentTime%) Settings file "idlecombosettings.json" created.`n, %OutputLogFile%
	FileRead, OutputText, %OutputLogFile%
	FileRead, rawsettings, %SettingsFile%
	CurrentSettings := JSON.parse(rawsettings)
	oMyGUI.Update()
	MsgBox, Your settings file has been deleted due to an update to IdleCombos. Please verify that your settings are set as preferred.
}
if FileExist(A_ScriptDir "\webRequestLog.txt") {
	MsgBox, 4, , % "WRL File detected. Use file?"
	IfMsgBox, Yes
	{
		WRLFile := A_ScriptDir "\webRequestLog.txt"
		FirstRun()
	}
}
if !(CurrentSettings.firstrun) {
	FirstRun()
}
if (CurrentSettings.user_id && CurrentSettings.hash) {
	UserID := CurrentSettings.user_id
	UserHash := CurrentSettings.hash
	InstanceID := CurrentSettings.instance_id
	SB_SetText("User ID & Hash ready.")
}
else {
	SB_SetText("User ID & Hash not found!")
}
;Loading current settings
ServerName := CurrentSettings.servername
GetDetailsonStart := CurrentSettings.getdetailsonstart
LaunchGameonStart := CurrentSettings.launchgameonstart
AlwaysSaveContracts := CurrentSettings.alwayssavecontracts
NoSaveSetting := CurrentSettings.NoSaveSetting
if (GetDetailsonStart == "1") {
	GetUserDetails()
}

oMyGUI.Update()
SendMessage, 0x115, 7, 0, Edit1, A
return
;END:	default run commands

;BEGIN: GUI Defs
class MyGui {
	Width := "550"
	Height := "275" ;"250"
	__New()
	{
		Gui, MyWindow:New
		Gui, MyWindow:+Resize -MaximizeBox 

		Menu, BlacksmithSubmenu, Add, Use Tiny Contracts, Tiny_Blacksmith
		Menu, BlacksmithSubmenu, Add, Use Small Contracts, Sm_Blacksmith
		Menu, BlacksmithSubmenu, Add, Use Medium Contracts, Med_Blacksmith
		Menu, BlacksmithSubmenu, Add, Use Large Contracts, Lg_Blacksmith
		Menu, BlacksmithSubmenu, Add, Item Level Report, GearReport
		Menu, ToolsSubmenu, Add, &Blacksmith, :BlacksmithSubmenu

		Menu, HelpSubmenu, Add, &Run Setup, FirstRun
		Menu, HelpSubmenu, Add, &List Champ IDs, List_ChampIDs
		Menu, IdleMenu, Add, &Help, :HelpSubmenu
		Gui, Menu, IdleMenu

		col1_x := 5
		col2_x := 420
		col3_x := 480
		row_y := 5

		Gui, Add, StatusBar,, %OutputStatus%

		Gui, MyWindow:Add, Button, x%col2_x% y%row_y% w60 gReload_Clicked, Reload
		Gui, MyWindow:Add, Button, x%col3_x% y%row_y% w60 gExit_Clicked, Exit

	;	Gui, MyWindow:Add, Tab3, x%col1_x% y%row_y% w400 h230, Inventory|Log|
	;	Gui, Tab

		row_y := row_y + 25
		;Gui, MyWindow:Add, Button, x%col3_x% y%row_y% w60 gUpdate_Clicked, Update
		row_y := row_y + 25

		Gui, MyWindow:Add, Text, x420 y40,	Champion to use`nBS contracts on:
		Gui, MyWindow:Add, Edit, vAutomBSChamp x420 y73 w40,
		Gui, MyWindow:Add, Button, x470 y73 w60 gSaveChamp_Clicked, Save
		Gui, MyWindow:Add, Text, x500 y95 w50 vBSChampTXT
		Gui, MyWindow:Add, Text, x420 y95 w80, Champ id saved: 

		Gui, MyWindow:Add, Text, x410 y120, Data Timestamp:
		Gui, MyWindow:Add, Text, x410 y140 vLastUpdated w220, % LastUpdated
		Gui, MyWindow:Add, Button, x410 y160 w60 gUpdate_Clicked, Update
		Gui, MyWindow:Add, Button, x410 y190 w60 gUseBriv_Clicked, Start
		Gui, MyWindow:Add, Button, x410 y+5 w60 gStopBriv_Clicked, Stop


	;	Gui, Tab, Inventory

		Gui, MyWindow:Add, Text, x15 y20+p w110, Tiny Blacksmiths:
		Gui, MyWindow:Add, Text, vCurrentTinyBS x+2 w35 right, % CurrentTinyBS
		Gui, MyWindow:Add, Text, x15 y+p w110, Small Blacksmiths:
		Gui, MyWindow:Add, Text, vCurrentSmBS x+2 w35 right, % CurrentSmBS
		Gui, MyWindow:Add, Text, x15 y+p w110, Medium Blacksmiths:
		Gui, MyWindow:Add, Text, vCurrentMdBS x+2 w35 right, % CurrentMdBS
		Gui, MyWindow:Add, Text, x15 y+p w110, Large Blacksmiths:
		Gui, MyWindow:Add, Text, vCurrentLgBS x+2 w35 right, % CurrentLgBS

		Gui, MyWindow:Add, Text, x15 y+20+p w110, 58 Briv
		Gui, MyWindow:Add, Text, x15 y+p w110, 75 Hew Maan
		Gui, MyWindow:Add, Text, x15 y+20+p vautomTXT w300, % automTXT
		Gui, MyWindow:Add, Text, x15 y+p vtimeleftTXT w150, % timeleftTXT


	;	Gui, Tab, Log
		this.Show()
	}

	

	Show() {
		;check if minimized if so leave it be
		WinGet, OutputVar , MinMax, AutomBS v%VersionNumber%
		if (OutputVar = -1) {
			return
		}
		nW := this.Width
		nH := this.Height
		Gui, MyWindow:Show, w%nW% h%nH%, AutomBS v%VersionNumber%
	}

	Hide() {
		Gui, MyWindow:Hide
	}

	Submit() {
		Gui, MyWindow:Submit, NoHide
	}

	Update() {
		GuiControl, MyWindow:, OutputText, % OutputText, w250 h210
		SendMessage, 0x115, 7, 0, Edit1
		GuiControl, MyWindow:, LastUpdated, % LastUpdated, w250 h210
		;inventory
		GuiControl, MyWindow:, CurrentTinyBS, % CurrentTinyBS, w250 h210
		GuiControl, MyWindow:, CurrentSmBS, % CurrentSmBS, w250 h210
		GuiControl, MyWindow:, CurrentMdBS, % CurrentMdBS, w250 h210
		GuiControl, MyWindow:, CurrentLgBS, % CurrentLgBS, w250 h210
		;this.Show() - removed
	}

}


SaveChamp_Clicked()
	{
		GuiControlGet, AutomBSChamp
		BSChampTXT = % AutomBSChamp
		msgbox % AutomBSChamp
		GuiControl,MyWindow:,BSChampTXT, % AutomBSChamp
	}

Update_Clicked()
	{
		GetUserDetails()
		return
	}

UseBriv_Clicked()
	{
	msgbox,4, Are you sure?, Use bs contracts automatically on %AutomBSChamp% ?
	IfMsgBox, No
		return
	counter.Start()
	}

StopBriv_Clicked()
	{
	counter.Stop()
	}

Reload_Clicked()
	{
		Reload
		return
	}

Exit_Clicked()
	{
		ExitApp
		return
	}


Save_Settings()
	{
		oMyGUI.Submit()
		CurrentSettings.servername := ServerName
		CurrentSettings.getdetailsonstart := GetDetailsonStart
		CurrentSettings.launchgameonstart := LaunchGameonStart
		CurrentSettings.alwayssavecontracts := AlwaysSaveContracts
		CurrentSettings.nosavesetting := NoSaveSetting
		newsettings := JSON.stringify(CurrentSettings)
		FileDelete, %SettingsFile%
		FileAppend, %newsettings%, %SettingsFile%
		SB_SetText("Settings have been saved.")
		return
	}


	


Tiny_Blacksmith()
	{
		UseBlacksmith(31)
		return
	}

Sm_Blacksmith()
	{
		UseBlacksmith(32)
		return
	}

Med_Blacksmith()
	{
		UseBlacksmith(33)
		return
	}

Lg_Blacksmith()
	{
		UseBlacksmith(34)
		return
	}

UseBlacksmith(buffid) {

		if !UserID {
			MsgBox % "Need User ID & Hash."
			FirstRun()
		}
		switch buffid
		{
			case 31: currentcontracts := CurrentTinyBS
			case 32: currentcontracts := CurrentSmBS
			case 33: currentcontracts := CurrentMdBS
			case 34: currentcontracts := CurrentLgBS
		}	
		if !(currentcontracts) {
			return
		}

		count=%currentcontracts%
		heroid = % AutomBSChamp
		while !(heroid is number) {
			InputBox, heroid, Blacksmithing, % "Please enter a valid Champ ID number.", , 200, 180, , , , , %LastBSChamp%
			if ErrorLevel
				return
		}
		while !((heroid > 0) && (heroid < 100)) {
			InputBox, heroid, Blacksmithing, % "Please enter a valid Champ ID number.", , 200, 180, , , , , %LastBSChamp%
			if ErrorLevel
				return
		}

		LastBSChamp := heroid
		bscontractparams := "&user_id=" UserID "&hash=" UserHash "&instance_id=" InstanceID "&buff_id=" buffid "&hero_id=" heroid "&num_uses="
		tempsavesetting := 0
		slot1lvs := 0
		slot2lvs := 0
		slot3lvs := 0
		slot4lvs := 0
		slot5lvs := 0
		slot6lvs := 0
		while (count > 0) {
			SB_SetText("Contracts remaining to use: " count)
			if (count < 50) {
				rawresults := ServerCall("useserverbuff", bscontractparams count)
				count -= count
			}
			else {
				rawresults := ServerCall("useserverbuff", bscontractparams "50")
				count -= 50
			}
			if (CurrentSettings.alwayssavecontracts || tempsavesetting) {
				FileAppend, %rawresults%`n, %BlacksmithLogFile%
			}
			else {
				if !CurrentSettings.nosavesetting {
					InputBox, dummyvar, Contracts Results, Save to File?, , 250, 150, , , , , % rawresults
					dummyvar := ""
					if !ErrorLevel {
						FileAppend, %rawresults%`n, %ContractLogFile%
						tempsavesetting := 1
					}
				}
			}
			blacksmithresults := JSON.parse(rawresults)
			if ((blacksmithresults.success == "0") || (blacksmithresults.okay == "0")) {
				;MsgBox % ChampFromID(heroid) " levels gained:`nSlot 1: " slot1lvs "`nSlot 2: " slot2lvs "`nSlot 3: " slot3lvs "`nSlot 4: " slot4lvs "`nSlot 5: " slot5lvs "`nSlot 6: " slot6lvs
				;MsgBox % "Error: " rawresults
				switch buffid
				{
					case 31: contractsused := (CurrentTinyBS - blacksmithresults.buffs_remaining)
					case 32: contractsused := (CurrentSmBS - blacksmithresults.buffs_remaining)
					case 33: contractsused := (CurrentMdBS - blacksmithresults.buffs_remaining)
					case 34: contractsused := (CurrentLgBS - blacksmithresults.buffs_remaining)
				}
				UpdateLogTime()
				FileAppend, % "(" CurrentTime ") Contracts Used: " Floor(contractsused) "`n", %OutputLogFile%
				FileRead, OutputText, %OutputLogFile%
				oMyGUI.Update()
				GetUserDetails()
				SB_SetText("Contracts remaining: " count " (Error)")
				return
			}
			rawactions := JSON.stringify(blacksmithresults.actions)
			blacksmithactions := JSON.parse(rawactions)
			for k, v in blacksmithactions
			{
				switch v.slot_id
				{
					case 1: slot1lvs += v.amount
					case 2: slot2lvs += v.amount
					case 3: slot3lvs += v.amount
					case 4: slot4lvs += v.amount
					case 5: slot5lvs += v.amount
					case 6: slot6lvs += v.amount
				}
			}
		}
		;MsgBox % ChampFromID(heroid) " levels gained:`nSlot 1: " slot1lvs "`nSlot 2: " slot2lvs "`nSlot 3: " slot3lvs "`nSlot 4: " slot4lvs "`nSlot 5: " slot5lvs "`nSlot 6: " slot6lvs
		tempsavesetting := 0
		switch buffid {
			case 31: contractsused := (CurrentTinyBS - blacksmithresults.buffs_remaining)
			case 32: contractsused := (CurrentSmBS - blacksmithresults.buffs_remaining)
			case 33: contractsused := (CurrentMdBS - blacksmithresults.buffs_remaining)
			case 34: contractsused := (CurrentLgBS - blacksmithresults.buffs_remaining)
		}
		UpdateLogTime()
		FileAppend, % "(" CurrentTime ") Contracts used on " ChampFromID(heroid) ": " Floor(contractsused) "`n", %OutputLogFile%
		FileRead, OutputText, %OutputLogFile%
		oMyGUI.Update()
		GetUserDetails()
		SB_SetText("Blacksmith use completed.")
		return
	}

	FirstRun() {
		MsgBox, 4, , Get User ID and Hash from webrequestlog.txt?
		IfMsgBox, Yes
		{
			GetIdFromWRL()
			UpdateLogTime()
			FileAppend, (%CurrentTime%) User ID: %UserID% & Hash: %UserHash% detected in WRL.`n, %OutputLogFile%
		}
		else
		{
			MsgBox, 4, , Choose install directory manually?
			IfMsgBox Yes
			{
				FileSelectFile, WRLFile, 1, webRequestLog.txt, Select webRequestLog file, webRequestLog.txt
				if ErrorLevel
					return
				GetIdFromWRL()
				GameInstallDir := SubStr(WRLFile, 1, -67)
				GameClient := GameInstallDir "IdleDragons.exe"
			}	
			else {
				InputBox, UserID, user_id, Please enter your "user_id" value., , 250, 125
				if ErrorLevel
					return
				InputBox, UserHash, hash, Please enter your "hash" value., , 250, 125
				if ErrorLevel
					return
				UpdateLogTime()
				FileAppend, (%CurrentTime%) User ID: %UserID% & Hash: %UserHash% manually entered.`n, %OutputLogFile%
			}
		}
		FileRead, OutputText, %OutputLogFile%
		oMyGUI.Update()
		CurrentSettings.user_id := UserID
		CurrentSettings.hash := UserHash
		CurrentSettings.firstrun := 1
		newsettings := JSON.stringify(CurrentSettings)
		FileDelete, %SettingsFile%
		FileAppend, %newsettings%, %SettingsFile%
		UpdateLogTime()
		FileAppend, (%CurrentTime%) IdleCombos setup completed.`n, %OutputLogFile%
		FileRead, OutputText, %OutputLogFile%
		oMyGUI.Update()
		SB_SetText("User ID & Hash ready.")
	}

	UpdateLogTime() {
		FormatTime, CurrentTime, , yyyy-MM-dd HH:mm:ss
	}

	GetIDFromWRL() {
		FileRead, oData, %WRLFile%
		if ErrorLevel {
			MsgBox, 4, , Could not find webRequestLog.txt file.`nChoose install directory manually?
			IfMsgBox Yes
			{
				FileSelectFile, WRLFile, 1, webRequestLog.txt, Select webRequestLog file, webRequestLog.txt
				if ErrorLevel
					return
				FileRead, oData, %WRLFile%
			}
			else
				return
		}
		FoundPos := InStr(oData, "getuserdetails&language_id=1&user_id=")
		oData2 := SubStr(oData, (FoundPos + 37))
		FoundPos := InStr(oData2, "&hash=")
		StringLeft, UserID, oData2, (FoundPos - 1)
		oData := SubStr(oData2, (FoundPos + 6))
		FoundPos := InStr(oData, "&instance_key=")
		StringLeft, UserHash, oData, (FoundPos - 1)
		oData := ; Free the memory.
		oData2 := ; Free the memory.
		return
	}

	GetUserDetails() {
		Gui, MyWindow:Default
		SB_SetText("Please wait a moment...")
		getuserparams := DummyData "&include_free_play_objectives=true&instance_key=1&user_id=" UserID "&hash=" UserHash
		rawdetails := ServerCall("getuserdetails", getuserparams)
		FileDelete, %UserDetailsFile%
		FileAppend, %rawdetails%, %UserDetailsFile%
		UserDetails := JSON.parse(rawdetails)
		InstanceID := UserDetails.details.instance_id
		CurrentSettings.instance_id := InstanceID
		ActiveInstance := UserDetails.details.active_game_instance_id
		newsettings := JSON.stringify(CurrentSettings)
		FileDelete, %SettingsFile%
		FileAppend, %newsettings%, %SettingsFile%
		ParseTimestamps()
		ParseInventoryData()
		oMyGUI.Update()
		SB_SetText("User details available.")
		return
	}

	ParseTimestamps() {
		localdiff := (A_Now - A_NowUTC)
		if (localdiff < -28000000) {
			localdiff += 70000000
		}
		if (localdiff < -250000) {
			localdiff += 760000
		}
		StringTrimRight, localdiffh, localdiff, 4
		localdiffm := SubStr(localdiff, -3)
		StringTrimRight, localdiffm, localdiffm, 2
		if (localdiffm > 59) {
			localdiffm -= 40
		}
		timestampvalue := "19700101000000"
		timestampvalue += UserDetails.current_time, s
		EnvAdd, timestampvalue, localdiffh, h
		EnvAdd, timestampvalue, localdiffm, m
		FormatTime, LastUpdated, % timestampvalue, MMM d`, h:mm tt
		tgptimevalue := "19700101000000"
		tgptimevalue += UserDetails.details.stats.time_gate_key_next_time, s
		EnvAdd, tgptimevalue, localdiffh, h
		EnvAdd, tgptimevalue, localdiffm, m
		FormatTime, NextTGPDrop, % tgptimevalue, MMM d`, h:mm tt
		if (UserDetails.details.stats.time_gate_key_next_time < UserDetails.current_time) {
			Gui, Font, cGreen
			GuiControl, Font, NextTGPDrop
		}
		else {
			Gui, Font, cBlack
			GuiControl, Font, NextTGPDrop
		}
	}

	ParseInventoryData() {
		for k, v in UserDetails.details.buffs
			switch v.buff_id
		{
			case 31: CurrentTinyBS := v.inventory_amount
			case 32: CurrentSmBS := v.inventory_amount
			case 33: CurrentMdBS := v.inventory_amount
			case 34: CurrentLgBS := v.inventory_amount
		}
		AvailableBSLvs := "= " CurrentTinyBS+(CurrentSmBS*2)+(CurrentMdBS*6)+(CurrentLgBS*24) " Item Levels"
	}


	ServerCall(callname, parameters) {
		URLtoCall := "http://ps7.idlechampions.com/~idledragons/post.php?call=" callname parameters
		WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		WR.SetTimeouts("10000", "10000", "10000", "10000")
		Try {
			WR.Open("POST", URLtoCall, false)
			WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
			WR.Send()
			WR.WaitForResponse(-1)
			data := WR.ResponseText
		}
		UpdateLogTime()
		FileAppend, (%CurrentTime%) Server request: "%callname%"`n, %OutputLogFile%
		FileRead, OutputText, %OutputLogFile%
		oMyGUI.Update()
		return data
	}


	List_ChampIDs()
		{
			champnamelen := 0
			champname := ""
			id := 1
			champidlist := ""
			while (id < 101) {
				champname := ChampFromID(id)
				StringLen, champnamelen, champname
				while (champnamelen < 16)
				{
					champname := champname " "
					champnamelen += 1
				}
				if (!mod(id, 4))
					champidlist := champidlist id ": " champname "`n"
				else
					champidlist := champidlist id ": " champname "`t"
				id += 1
			}
			;MsgBox, , Champ ID List, % champidlist
			CustomMsgBox("Champion IDs and Names",champidlist,"Courier New","Blue")
			return	
		}
	
		CustomMsgBox(Title,Message,Font="",FontOptions="",WindowColor="")
		{
			Gui,66:Destroy
			Gui,66:Color,%WindowColor%

			Gui,66:Font,%FontOptions%,%Font%
			Gui,66:Add,Text,,%Message%
			Gui,66:Font

			GuiControlGet,Text,66:Pos,Static1

			Gui,66:Add,Button,% "Default y+10 w75 g66OK xp+" (TextW / 2) - 38 ,OK

			Gui,66:-MinimizeBox
			Gui,66:-MaximizeBox

			SoundPlay,*-1
			Gui,66:Show,,%Title%

			Gui,66:+LastFound
			WinWaitClose
			Gui,66:Destroy
			return

			66OK:
				Gui,66:Destroy
			return
		}


GearReport() {
	totalgearlevels := -1
	totalgearitems := -1
	totalcorelevels := -1
	totalcoreitems := -1
	totaleventlevels := 0
	totaleventitems := 0
	totalshinycore := 0
	totalshinyevent := 0
	highestcorelevel := 0
	highesteventlevel := 0
	highestcoreid := 0
	highesteventid := 0
	lowestcorelevel := 10000000000
	lowesteventlevel := 10000000000
	lowestcoreid := 0
	lowesteventid := 0
	currentchamplevel := 0
	currentcount := 0
	lastchamp := 0
	lastshiny := 0
	currentloot := UserDetails.details.loot
	dummyitem := {}
	currentloot.push(dummyitem)

	for k, v in currentloot {
		totalgearlevels += (v.enchant + 1)
		totalgearitems += 1

		if (lastchamp < 13) {
			totalcorelevels += (v.enchant + 1)
			totalcoreitems += 1
			if (lastshiny) {
				totalshinycore += 1
			}
			if ((v.hero_id != lastchamp) and (lastchamp != 0)) {
				if (currentchamplevel > highestcorelevel) {
					highestcorelevel := currentchamplevel
					highestcoreid := lastchamp
				}
				if (currentchamplevel < lowestcorelevel) {
					lowestcorelevel := currentchamplevel
					lowestcoreid := lastchamp
				}
				currentchamplevel := 0
				currentcount := 0
				currentchamplevel := (v.enchant + 1)
				currentcount += 1
			}
			else {
				currentchamplevel += (v.enchant + 1)
				currentcount += 1
			}
		}
		else if ((lastchamp = 13) or (lastchamp = 18) or (lastchamp = 30) or (lastchamp = 67) or (lastchamp = 68) or (lastchamp = 86) or (lastchamp = 87) or (lastchamp = 88)){
			totalcorelevels += (v.enchant + 1)
			totalcoreitems += 1
			if (lastshiny) {
				totalshinycore += 1
			}
			if (v.hero_id != lastchamp) {
				if (currentchamplevel > highestcorelevel) {
					highestcorelevel := currentchamplevel
					highestcoreid := lastchamp
				}
				if (currentchamplevel < lowestcorelevel) {
					lowestcorelevel := currentchamplevel
					lowestcoreid := lastchamp
				}
				currentchamplevel := 0
				currentcount := 0
				currentchamplevel := (v.enchant + 1)
				currentcount += 1
			}
			else {
				currentchamplevel += (v.enchant + 1)
				currentcount += 1
			}
		}
		else {
			totaleventlevels += (v.enchant + 1)
			totaleventitems += 1
			if (lastshiny) {
				totalshinyevent += 1
			}
			if (v.hero_id != lastchamp) {
				if (currentchamplevel > highesteventlevel) {
					highesteventlevel := currentchamplevel
					highesteventid := lastchamp
				}
				if (currentchamplevel < lowesteventlevel) {
					lowesteventlevel := currentchamplevel
					lowesteventid := lastchamp
				}
				currentchamplevel := 0
				currentcount := 0
				currentchamplevel := (v.enchant + 1)
				currentcount += 1
			}
			else {
				currentchamplevel += (v.enchant + 1)
				currentcount += 1
			}
		}

		lastchamp := v.hero_id
		lastshiny := v.gild
	}
	dummyitem := currentloot.pop()
	shortreport := ""

	shortreport := shortreport "Avg item level:`t" Round(totalgearlevels/totalgearitems)

	shortreport := shortreport "`n`nAvg core level:`t" Round(totalcorelevels/totalcoreitems)
	shortreport := shortreport "`nHighest avg core:`t" Round(highestcorelevel/6) " (" ChampFromID(highestcoreid) ")"
	shortreport := shortreport "`nLowest avg core:`t" Round(lowestcorelevel/6) " (" ChampFromID(lowestcoreid) ")"
	shortreport := shortreport "`nCore Shinies:`t" totalshinycore "/" totalcoreitems

	shortreport := shortreport "`n`nAvg event level:`t" Round(totaleventlevels/totaleventitems)
	shortreport := shortreport "`nHighest avg event:`t" Round(highesteventlevel/6) " (" ChampFromID(highesteventid) ")"
	shortreport := shortreport "`nLowest avg event:`t" Round(lowesteventlevel/6) " (" ChampFromID(lowesteventid) ")"
	shortreport := shortreport "`nEvent Shinies:`t" totalshinyevent "/" totaleventitems

	MsgBox % shortreport
	return
}


class SecondCounter {
    __New() {
			global automTXT
        this.interval := 1000
        this.count := 0
        this.timer := ObjBindMethod(this, "Tick")

    }
    Start() {
		GuiControl,MyWindow:,automTXT, Automation using bs on champ %AutomBSChamp%
        timer := this.timer
        SetTimer % timer, % this.interval
    }
    Stop() {
        timer := this.timer
        SetTimer % timer, Off
		GuiControl,MyWindow:,automTXT, Automation not running

    }
    Tick() {
		TimeLeft -= 1000
		;msgbox % timeleft
		GuiControl,MyWindow:,TimeleftTXT, % floor(TimeLeft/1000)
		;if (!oMyGUI)

		if(!mod(TimeLeft,120000))
			Update_Clicked()

		if(TimeLeft<1000)
			{
			UseBlacksmith(31)
			UseBlacksmith(32)
			UseBlacksmith(33)
			UseBlacksmith(34)
			TimeLeft = 1800000
			}
    }
}