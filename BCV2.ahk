
;@Ahk2Exe-Base C:\Program Files\AutoHotkey\v2\AutoHotkey.exe
;@Ahk2Exe-SetMainIcon %A_ScriptDir%\BCB.ico
;@Ahk2Exe-AddResource *14 %A_ScriptDir%\BCB.ico, BCBICON
#Requires Autohotkey v2.0
#Warn All, StdOut
#SingleInstance Force
SetWorkingDir A_ScriptDir

;@Ahk2Exe-IgnoreBegin
/**
 * @var {String} BCBIcon Path to `BCB.ico` icon
 */
BCBIcon := "BCB.ico"
;@Ahk2Exe-IgnoreEnd

/*@Ahk2Exe-Keep
; Handle to `BCB.ico` icon
BCBIcon := "HICON:" LoadPicture(A_ScriptDir "\BCV2.exe", "Icon6", &isIcon:=1)
*/

A_IconTip := "BCV2"
TraySetIcon(BCBIcon)


; @prop {String} Path to BetterClipboard configuration file
BCB_CONF_PATH := A_AppData "\BetterClipboard\BCB.ini"

; @prop {String} Path to directory storing clipboard entries
BCB_CLIPS_DIR := A_AppData "\BetterClipboard\clips"



/**
 * Immediately exit script if run with the command argument **Off**; in combination with
 * **`#SingleInstance Force`**, this allows for safely exiting the compiled script -- still
 * catching `OnExit` registered functions -- by just running ".\BCV2.exe Off"
*
* Intended to be used with my main default-running script.
*/
(BCBConf)
ParseArgs(*) {
    prev_state := !!Integer(BCBConf.Settings['State'])
    arg1 := (args_len:=A_Args.Length) ? A_Args[1] : 'unset'

    new_state := true
    switch arg1 {
        case 'On':
            new_state := true
        case 'Off':
            new_state := false
        default:
            new_state := !prev_state
    }
    ; msgbox 'prev: ' prev_state '`n' .
    ;        'arg: ' arg1 '`n' .
    ;        'new: ' new_state
    if new_state != prev_state
        BCBConf.Settings['State'] := new_state
    if !new_state
        ExitApp
}
; ParseArgs()
; BCBConf.HandleStartupArgs()

; #Include ..\Lib\SciLib\SciConstants.ahk
; #Include ..\Lib\SciLib\SciLoad.ahk

#Include <SciConstants>
#Include <SciLoad>

/**
 *  @var {String} SCI_DLL_PATH Path to Scintilla.dll
 */
SCI_DLL_PATH := "Lib\Scintilla.dll"
if !FileExist(SCI_DLL_PATH)
    FileInstall ".\Lib\Scintilla.dll", SCI_DLL_PATH

__PC_PATH := "Lib\DetectComputer.ahk"
if !FileExist(__PC_PATH)
    FileInstall ".\Lib\DetectComputer.ahk", __PC_PATH


#Include *i Lib\DetectComputer.ahk



/**
 * @param {Pointer} SciPtr A pointer to the Scintilla DLL library. Upon variable
 *      initialization, the method *`SciAdd`* is added to the global Gui class for the
 *      creation of a Scintilla control with a custom **`Send`** method for sending
 *      direct messages via DLL calls.
 */
SciPtr := SciLoad(SCI_DLL_PATH)

; Free Scintilla.dll library
OnExit (*) => SciFree(SciPtr)

/**
 * @var {BCBApp} App
 *
 * Initialize BetterClipboard application
 */
App := BCBApp()


/**
 * Helper class for setting/getting keys in configuration file as defined by
 *      **`BCB_CONF_PATH`** global variable.
 *
 *  The class makes use of static **`__Get`** and **`__Set`** to retrieve and store
 *      existing and non-existing values.
 */
Class BCBConf {
    static ini_presets := Map(
        'Index', Map(
            'Current', 1,
            'Max', 9999,
        ),
        'Settings', Map(
            'State', false,
            'ToastDuration', 3333
        )
    )

    static __New() {
        ValidateKeys(*){
            for _sect_name, _sect_keys in this.ini_presets
                for _key_name, _key_value in _sect_keys
                    if this.%_sect_name%[_key_name] = 'unset'
                        msgbox('new:`n' _key_name '`n' (this.%_sect_name%[_key_name] := _key_value))
                    else msgbox('existing:`n' _key_name '`n' _key_value)
        }
        ValidateConf(*) {
            if !!FileExist(BCB_CONF_PATH)
                return 'exists'

            SplitPath BCB_CONF_PATH,, &conf_dir
            if !!DirExist(conf_dir)
                return (ValidateKeys(), 'newfile')

            SplitPath conf_dir,, &conf_dir_parent
            if !!DirExist(conf_dir_parent)
                return (DirCreate(conf_dir), ValidateKeys(), 'newdir')

            throw ValueError("Neither file or directory of given path to "
                           . "configuration file could be found."          )
            return False
        }
        if not ValidateConf()
            ExitApp
        this.HandleStartupArgs()
    }

    static HandleStartupArgs(*) {
        prev_state := BCBConf.Settings['State']
        prev_state := (prev_state = 'unset') ? 0 : prev_state
        arg1 := (args_len:=A_Args.Length) ? A_Args[1] : 'unset'
        new_state := !!(arg1 = 'On')  ? true  :
                     !!(arg1 = 'Off') ? false : !prev_state
        toast_msg := false
        toast_title := false
        if new_state != prev_state {
            toast_msg := 'arg1: ' arg1 ', states: ' prev_state ' -> ' new_state
            toast_title := !new_state ? 'Closing {BCV2.exe} process' :
                                        'Starting {BCV2.exe} process'
            for _sect_nm, _sect_keys in this.ini_presets
                for _key_nm, _key_val in _sect_keys
                    toast_msg .= ( '`n' _sect_nm '.' _key_nm ': ' .
                                   this.%_sect_nm%[_key_nm]       )
            JKQuickToast(toast_msg, toast_title)
            BCBConf.Settings['State'] := new_state
        }
        if !new_state
            ExitApp
    }

    /**
     * @prop {Any} Index Get and set keys of the Index section in the configuration
     *                   file by passing the key name as the property parameter
     */
    static Index[_key] {
        Get => IniRead(BCB_CONF_PATH, "Index", _key, 'unset')
        Set => IniWrite(Value, BCB_CONF_PATH, "Index", _key)
    }

    static Settings[_key] {
        Get => IniRead(BCB_CONF_PATH, "Settings", _key, 'unset')
        Set => IniWrite(Value, BCB_CONF_PATH, "Settings", _key)
    }
}

JKQuickToast(_msg, _title, _timeout_ms?) {
    _timeout_ms := Abs(_timeout_ms ?? Round( 4 * 1000 )) * (-1)
    Try {
        _msg_str := String(_msg)
        _title_str := String(_title)
        TrayTip _msg_str, _title_str
        SetTimer (*)=> TrayTip(), _timeout_ms
    } Catch Error as type_err {
        TrayTip "The passed parameters did not have the correct types",
                "Could not display specified toast message"
        SetTimer (*)=>TrayTip(), _timeout_ms
    }
}
; JKQuickToast(_msg, _title, _timeout_ms) {
;     HideTrayTip(*) {
;         TrayTip
;         if SubStr(A_OSVersion, 1, 3) = "10." {
;             A_IconHidden := True
;             SetTimer( (*) => (A_IconHidden := False), (-200) )
;         }
;     }
;     Try {
;         _msg_str         := String(_msg)
;         _title_str       := String(_title)
;         _timeout_ms_int  := Integer(_timeout_ms) * -1
;         _types_are_valid := True
;     } Catch Error as type_err {
;         _types_are_valid := False
;     }
;     if _types_are_valid {
;         TrayTip( _msg_str, _title_str )
;         SetTimer( (*) => HideTrayTip(), _timeout_ms_int )
;     } else {
;         TrayTip( "The passed parameters did not have the correct types",
;                  "Could not display specified toast message" )
;         SetTimer( (*) => HideTrayTip(), (-4000) )
;     }
; }

; A class to help manage the indicator gui for the currently shown index
Class BCBIndexGui {
    ; @prop {Boolean} active
    active := False

    ; @prop {Gui} gui
    gui := {}
    ; @prop {Gui.Text} text
    text := {}
    ; @prop {Gui} parentgui
    parentgui := {}

    ; @prop {Integer} width
    width := 100
    ; @prop {Integer} height
    height := 48

    ; @prop {Integer} fadeSteps Number of transparency steps in fade animation
    fadeSteps := 10
    ; @prop {Integer} fadeRest Ticks between transparency steps in fade animation
    fadeRest := 1
    ; @prop {Integer} opacity 0-255
    opacity := 125
    ; @prop {Integer} currentOp Current gui opacity [1-255]
    currentOp := 0

    ; @prop {String} fontOpts
    fontOpts := "s28"
    ; @prop {String} fontName
    fontName := "CaskaydiaCove Nerd Font Mono"

    ; @prop {Integer} timeout
    timeout := 1000
    ; @prop {Func} hideGuiBF
    hideGuiBF := {}

    /**
     * @param {Gui} _parentgui A reference to the main window Gui object
     * @param {Object} _colors A reference to an object containing color info containing
     *                         one or more of the following properties:
     *
     *      _colors := {
     *          indexbg: "0A1BEF"   ; 6-digit hex color as string
     *          indexfg: "320FBA"   ; 6-digit hex color as string
     *      }
     */
    __New(_parentgui, _colors:="") {
        this.parentgui := _parentgui
        this.gui := Gui("-Caption +ToolWindow +AlwaysOnTop")
        this.gui.MarginX := this.gui.MarginY := 0
        if IsObject(_colors) {
            if _colors.HasProp("indexbg")
                this.gui.BackColor := _colors.indexbg
            if _colors.HasProp("indexfg")
                this.fontOpts .= " c" _colors.indexfg
        }
        this.gui.SetFont(this.fontOpts, this.fontName)
        textOpts := "w" this.width " h" this.height " Center"
        this.text := this.gui.Add("Text", textOpts, 9999)
        this.gui.Show("NA x" A_ScreenWidth)
        WinSetTransColor(this.gui.BackColor " " 0, this.gui)
        this.MatchParentGuiPos()
        this.gui.Show("Hide")
        this.hideGuiBF := ObjBindMethod(this, "HideGui")
    }

    ; Show and fade in the index gui
    ShowGui(*) {
        static fadeAmt := this.opacity / this.fadeSteps
        this.active := True
        this.gui.Show("NA")
        this.MatchParentGuiPos()
        ; Fade in the index gui
        FadeIn(*) {
            if !(this.active) {
                SetTimer(, 0)
            } else {
                newTrans := Round(this.currentOp + fadeAmt)
                if (newTrans >= (this.opacity-1)) {
                    SetTimer(, 0)
                    WinSetTransColor(this.gui.BackColor " " this.opacity, this.gui)
                    this.currentOp := this.opacity
                } else {
                    WinSetTransColor(this.gui.BackColor " " newTrans, this.gui)
                    this.currentOp := newTrans
                }
            }
        }
        SetTimer(FadeIn, this.fadeRest)
    }

    ; Fade out and hide the index gui
    HideGui(*) {
        static fadeAmt := this.opacity / this.fadeSteps
        this.active := False
        ; Fade out the index gui
        FadeOut(*) {
            if (this.active) {
                SetTimer(, 0)
            } else {
                newTrans := Round(this.currentOp - fadeAmt)
                if (newTrans <= 1) {
                    SetTimer(, 0)
                    WinSetTransColor(this.gui.BackColor " " 0, this.gui)
                    this.currentOp := 0
                    this.gui.Hide()
                } else {
                    WinSetTransColor(this.gui.BackColor " " newTrans, this.gui)
                    this.currentOp := newTrans
                }
            }
        }
        SetTimer(FadeOut, this.fadeRest)
    }

    ; Start a timer to hide the index gui after a delay of so many milliseconds as
    ; defined by `BCBIndexGui.timeout`
    StartTimeout(*) {
        hideGuiBF := this.hideGuiBF
        SetTimer(hideGuiBF, -this.timeout)
    }

    ; Cancel a timer previously set using `BCBIndexGui.StartTimeout`
    StopTimeout(*) {
        hideGuiBF := this.hideGuiBF
        SetTimer(hideGuiBF, 0)
    }

    ; Immediately hide the index gui with no fade effect, interrupting any fade effect
    ; currently in progress
    HideGuiImmediately(*) {
        this.active := False
        WinSetTransColor(this.gui.BackColor " " 0, this.gui)
        this.currentOp := 0
        this.gui.Hide()
    }

    ; Set the position of the index gui to rest against the lower right corner of the
    ; parent gui using a `SetWindowPos` DLL call
    MatchParentGuiPos() {
        static uFlags := (SWP_NOACTIVATE:=0x0010)|(SWP_NOSIZE:=0x0001)
        this.parentGui.GetPos(&px, &py, &pw, &ph)
        newPosX := px+pw-this.width
        newPosY := py+ph-this.height
        DllCall("SetWindowPos", "Ptr", this.gui.Hwnd
                              , "Ptr", -1
                              , "Int", newPosX, "Int", newPosY
                              , "Int", 0, "Int", 0
                              , "UInt", uFlags)
    }
}


; A class to help manage a custom Scintilla edit control
Class BCBEdit {
    ; @prop {Map} _TECHMODES Dictionary of Scintilla technology modes
    _TECHMODES := Map( "default"  , SC_TECHNOLOGY_DEFAULT             ; 0
                     , "dw"       , SC_TECHNOLOGY_DIRECTWRITE         ; 1
                     , "dw_retain", SC_TECHNOLOGY_DIRECTWRITERETAIN   ; 2
                     , "dw_dc"    , SC_TECHNOLOGY_DIRECTWRITEDC     ) ; 3
    ; @prop {Map} _VIRTSPACEOPTS Dictionary of Scintilla virtual space bit flags
    _VIRTSPACEOPTS := Map( "none"  , SCVS_NONE                   ; 0
                         , "rect"  , SCVS_RECTANGULARSELECTION   ; 1
                         , "user"  , SCVS_USERACCESSIBLE         ; 2
                         , "nowrap", SCVS_NOWRAPLINESTART      ) ; 4

    ; @prop {Boolean} _MultiSelect
    _MultiSelect := False

    /**
     * @prop {Method} Send
     * @param {Integer} _msg Message to send to the Scintilla control
     * @param {Integer} _wp wParam
     * @param {Integer} _lp lParam
     */
    Send := {}
    ; @prop {Method} Redo Sends a SCI_REDO command to the control
    Redo := {}
    ; @prop {Method} Duplicate Sends a SCI_SELECTIONDUPLICATE command to the control
    Duplicate := {}
    ; @prop {Method} SelectNext Adds the next occurrence to the main selection
    SelectNext := {}
    ; @prop {Method} SelectEach Adds each occurrence to the main selection
    SelectEach := {}
    ; @prop {Method} CopyAllowLine Copies selection or current line
    CopyAllowLine := {}
    ; @prop {Method} MoveLineUp Move selected lines up
    MoveLineUp := {}
    ; @prop {Method} MoveLineDown Move selected lines down
    MoveLineDown := {}

    ; @prop {BCBEdit.Wrap()} Wrap
    Wrap := {}
    ; @prop {BCBEdit.Selection} Selection
    Selection := {}
    ; @prop {BCBEdit.WhiteSpace} WhiteSpace
    WhiteSpace := {}
    ; @prop {BCBEdit.Caret} Caret
    Caret := {}
    ; @prop {BCBEdit.Chars} Chars
    Chars := {}
    ; @prop {BCBEdit.Font} Font
    Font := {}

    ; @prop {Integer} multiSelectColumn
    multiSelectColumn := -1

    /**
     * @param {Gui} _gui A reference to the parent Gui object
     * @param {String} _options A string containing options for the edit control
     */
    __New(_gui, _options:="") {
        this.ctrl := _gui.SciAdd(_options)
        this.gui := _gui
        this.Send := (_this, _msg, _wp:=0, _lp:=0) =>
                                            this.ctrl.Send(_msg, _wp, _lp)
        this.Redo := (*)=> (this.Send(SCI_REDO), this.Send(SCI_SCROLLCARET))
        this.Duplicate := (*)=> this.Send(SCI_SELECTIONDUPLICATE)
        this.SelectNext := (*)=> (this.Send(SCI_TARGETWHOLEDOCUMENT), this.Send(SCI_MULTIPLESELECTADDNEXT))
        this.SelectEach := (*)=> (this.Send(SCI_TARGETWHOLEDOCUMENT), this.Send(SCI_MULTIPLESELECTADDEACH))
        this.CopyAllowLine := (*)=> this.Send(SCI_COPYALLOWLINE)
        this.MoveLineDown := (*)=> this.Send(SCI_MOVESELECTEDLINESDOWN)
        this.MoveLineUp := (*)=> this.Send(SCI_MOVESELECTEDLINESUP)
        this.ZoomIn := (*)=> this.Send(SCI_ZOOMIN)
        this.ZoomOut := (*)=> this.Send(SCI_ZOOMOUT)
        ; this.RotateSelection := (*)=> (this.Send(SCI_ROTATESELECTION), this.Send(SCI_SCROLLCARET))
        this.Wrap := BCBEdit.Wrap(this)
        this.Selection := BCBEdit.Selection(this)
        this.WhiteSpace := BCBEdit.WhiteSpace(this)
        this.Caret := BCBEdit.Caret(this)
        this.Chars := BCBEdit.Chars(this)
        this.Font := BCBEdit.Font(this)
        this.SetShortcuts()
        ; this.Send(SCI_TARGETWHOLEDOCUMENT)
    }

    ; Enable keyboard shortcuts for the Scintilla control, handled by Scintilla
    SetShortcuts(*) {
        ; keyDefinition := keyCode + (keyMod << 16)
        ctrlPgDn := SCK_NEXT  + (SCMOD_CTRL << 16)
        ctrlPgUp := SCK_PRIOR + (SCMOD_CTRL << 16)
        altDn := SCK_DOWN + (SCMOD_ALT << 16)
        altUp := SCK_UP + (SCMOD_ALT << 16)
        altRight := SCK_RIGHT + (SCMOD_ALT << 16)
        altHome := SCK_HOME + (SCMOD_ALT << 16)
        altEnd := SCK_END + (SCMOD_ALT << 16)
        this.Send(SCI_ASSIGNCMDKEY, ctrlPgDn, SCI_PAGEDOWN) ; Ctrl+PgDn => PageDown
        this.Send(SCI_ASSIGNCMDKEY, ctrlPgUp, SCI_PAGEUP)   ; Ctrl+PgUp => PageUp
        ; ;
        ; ; Alt+Down => Move selected lines down
        ; ; this.Send(SCI_ASSIGNCMDKEY, altDn, SCI_MOVESELECTEDLINESDOWN)
        ; ; Alt+Up => Move selected lines up
        ; ; this.Send(SCI_ASSIGNCMDKEY, altUp, SCI_MOVESELECTEDLINESUP)
        ; ;
        ; ; Alt+Right => Rotate main selection in multiple selection
        ; ; this.Send(SCI_ASSIGNCMDKEY, altRight, SCI_ROTATESELECTION)
        ; ;
        ; Alt+Home => Uppercase
        this.Send(SCI_ASSIGNCMDKEY, altHome, SCI_UPPERCASE)
        ; Alt+End => Lowercase
        this.Send(SCI_ASSIGNCMDKEY, altEnd, SCI_LOWERCASE)
    }

    RotateSelection(*) {
        selectionCount := this.Send(SCI_GETSELECTIONS)
        mainSelection := this.Send(SCI_GETMAINSELECTION)
        if ((mainSelection+1) < selectionCount) {
            this.Send(SCI_SETMAINSELECTION, mainSelection+1)
        } else {
            this.Send(SCI_SETMAINSELECTION, 0)
        }
        this.Send(SCI_SCROLLCARET)
    }

    RotateSelectionReverse(*) {
        selectionCount := this.Send(SCI_GETSELECTIONS)
        mainSelection := this.Send(SCI_GETMAINSELECTION)
        if ((mainSelection-1) >= 0) {
            this.Send(SCI_SETMAINSELECTION, mainSelection-1)
        } else {
            this.Send(SCI_SETMAINSELECTION, selectionCount-1)
        }
        this.Send(SCI_SCROLLCARET)
    }

    AddCaretAbove(*) {
        selectionCount := this.Send(SCI_GETSELECTIONS)
        anchorPos := this.Send(SCI_GETANCHOR)
        lineNumber := this.Send(SCI_LINEFROMPOSITION, anchorPos)
        lineBeginPos := this.Send(SCI_POSITIONFROMLINE, lineNumber)
        if (selectionCount=1) {
            anchorColumn := anchorPos - lineBeginPos
            this.multiSelectColumn := anchorColumn
        } else anchorColumn := this.multiSelectColumn
        newLineBeginPos := this.Send(SCI_POSITIONFROMLINE, lineNumber-1)
        newLineEndPos := this.Send(SCI_GETLINEENDPOSITION, lineNumber-1)
        newLineLength := newLineEndPos - newLineBeginPos
        if (newLineLength >= anchorColumn) {
            newAnchorPos := newLineBeginPos + anchorColumn
        } else {
            newAnchorPos := newLineEndPos
        }
        this.Send(SCI_ADDSELECTION, newAnchorPos, newAnchorPos)
        this.Send(SCI_SCROLLCARET)
    }

    AddCaretBelow(*) {
        selectionCount := this.Send(SCI_GETSELECTIONS)
        anchorPos := this.Send(SCI_GETANCHOR)
        lineNumber := this.Send(SCI_LINEFROMPOSITION, anchorPos)
        lineBeginPos := this.Send(SCI_POSITIONFROMLINE, lineNumber)
        if (selectionCount=1) {
            anchorColumn := anchorPos - lineBeginPos
            this.multiSelectColumn := anchorColumn
        } else anchorColumn := this.multiSelectColumn
        newLineBeginPos := this.Send(SCI_POSITIONFROMLINE, lineNumber+1)
        newLineEndPos := this.Send(SCI_GETLINEENDPOSITION, lineNumber+1)
        newLineLength := newLineEndPos - newLineBeginPos
        if (newLineLength >= anchorColumn) {
            newAnchorPos := newLineBeginPos + anchorColumn
        } else {
            newAnchorPos := newLineEndPos
        }
        this.Send(SCI_ADDSELECTION, newAnchorPos, newAnchorPos)
        this.Send(SCI_SCROLLCARET)
    }

    /**
     * @prop {String} Text
     *
     * Get and set the contents of the Scintilla control
     */
    Text {
        Get {
            nLen := this.Send(SCI_GETLENGTH)
            buf := Buffer(nLen+1)
            this.Send(SCI_GETTEXT, nLen, buf.Ptr)
            Return StrGet(buf,,"UTF-8")
        }
        Set {
            str_size := StrPut(Value, "UTF-8")
            buf := Buffer(str_size, 0)
            StrPut(Value, buf, "UTF-8")
            this.Send(SCI_SETTEXT,, buf.Ptr)
        }
    }

    /**
     * @prop {Integer} MarginWidth
     *
     * Get and set width in pixels of margin 1
     */
    MarginWidth {
        Get => this.Send(SCI_GETMARGINWIDTHN, 1)
        Set => this.Send(SCI_SETMARGINWIDTHN, 1, Value)
    }

    /**
     * @prop {Boolean} ScrollBar
     *
     * Get and set vertical scrollbar visibility
     */
    ScrollBar {
        Get => this.Send(SCI_GETVSCROLLBAR)
        Set => this.Send(SCI_SETVSCROLLBAR)
    }

    /** @prop {Boolean} ScrollPastEnd
     *
     * Get and set ability to scroll past the last line
     */
    ScrollPastEnd {
        Get => this.Send(SCI_GETENDATLASTLINE)
        Set => this.Send(SCI_SETENDATLASTLINE, !!Value)
    }

    ; @prop {Boolean} MultipleSelection
    MultipleSelection {
        Get => this.Send(SCI_GETMULTIPLESELECTION)
        Set => this.Send(SCI_SETMULTIPLESELECTION, !!(Value))
    }

    ; @prop {Boolean} AdditionalSelectionTyping
    AdditionalSelectionTyping {
        Get => this.Send(SCI_GETADDITIONALSELECTIONTYPING)
        Set => this.Send(SCI_SETADDITIONALSELECTIONTYPING, !!(Value))
    }

    ; @prop {Boolean} MultiPaste
    MultiPaste {
        Get => this.Send(SCI_GETMULTIPASTE)
        Set => this.Send(SCI_SETMULTIPASTE, !!(Value))
    }

    /**
     * @prop {Hex Color} Background
     *
     * A **6-8** digit **(A)RGB** hex color as a string or integer defining the color of
     * the control's background
     */
    Background {
        Get => this.Send(SCI_STYLEGETBACK, STYLE_DEFAULT)
        Set {
            _col := (Type(Value) = "String") ? Integer("0x" Value) : Value
            this.Send(SCI_STYLESETBACK, STYLE_DEFAULT, _col)
            this.Send(SCI_STYLECLEARALL)
        }
    }

    /**
     * @prop {Hex Color} Foreground
     *
     * A **6-8** digit **(A)RGB** hex color as a string or integer defining the color of
     * the control's foreground text
     */
    Foreground {
        Get => this.Send(SCI_STYLEGETFORE, STYLE_DEFAULT)
        Set {
            _col := (Type(Value) = "String") ? Integer("0x" Value) : Value
            this.Send(SCI_STYLESETFORE, STYLE_DEFAULT, _col)
            this.Send(SCI_STYLECLEARALL)
        }
    }

    /**
     * @prop {String} Technology
     *
     * This value can be any key in `BCBEdit()._TECHMODES`
     *
     *      BCBEdit()._TECHMODES := Map(
     *           "default"  , SC_TECHNOLOGY_DEFAULT           := 0,
     *           "dw"       , SC_TECHNOLOGY_DIRECTWRITE       := 1,
     *           "dw_retain", SC_TECHNOLOGY_DIRECTWRITERETAIN := 2,
     *           "dw_dc"    , SC_TECHNOLOGY_DIRECTWRITEDC     := 3
     *      )
     */
    Technology {
        Get {
            _tech := this.Send(SCI_GETTECHNOLOGY)
            for techname, techval in this._TECHMODES
                if (_tech = techval)
                    Return techname
        }
        Set {
            for techname, techval in this._TECHMODES
                if (techname = StrLower(Value))
                    this.Send(SCI_SETTECHNOLOGY, techval)
        }
    }

    Class Font {
        ; @prop {BCBEdit} p The parent `BCBEdit` instance to interact with
        p := {}

        ; @param {BCBEdit} _BCBEdit The instance of `BCBEdit` to interact with
        __New(_BCBEdit) {
            this.p := _BCBEdit
        }

        /**
         * @prop {String} Font
         *
         * Get and set the name of the font to be displayed
         */
        Name {
            Get {
                nLen := this.p.Send(SCI_STYLEGETFONT, STYLE_DEFAULT)
                buf := Buffer(nLen+1, 0)
                this.p.Send(SCI_STYLEGETFONT, STYLE_DEFAULT, buf.Ptr)
                Return StrGet(buf,,"UTF-8")
            }
            Set {
                strSize := StrPut(Value, "UTF-8")
                buf := Buffer(strSize, 0)
                StrPut(Value, buf, "UTF-8")
                this.p.Send(SCI_STYLESETFONT, STYLE_DEFAULT, buf.Ptr)
                this.p.Send(SCI_STYLECLEARALL)
            }
        }

        /**
         * @prop {Number} Font
         *
         * Get and set the size of the font to be displayed
         */
        Size {
            Get => this.p.Send(SCI_STYLEGETSIZEFRACTIONAL, STYLE_DEFAULT)/100
            Set => (
                (IsNumber(Value)) ?
                this.p.Send(SCI_STYLESETSIZEFRACTIONAL, STYLE_DEFAULT, Integer(Value*100)) :
                False
            )
        }
    }

    Class Chars {
        ; @prop {BCBEdit} p The parent `BCBEdit` instance to interact with
        p := {}

        ; @param {BCBEdit} _BCBEdit The instance of `BCBEdit` to interact with
        __New(_BCBEdit) {
            this.p := _BCBEdit
        }

        Punctuation {
            Get {
                nLen := this.p.Send(SCI_GETPUNCTUATIONCHARS)
                buf := Buffer(nLen+1, 0)
                this.p.Send(SCI_GETPUNCTUATIONCHARS, 0, buf.Ptr)
                Return StrGet(buf,,"UTF-8")
            }
            Set {
                strSize := StrPut(Value, "UTF-8")
                buf := Buffer(strSize, 0)
                StrPut(Value, buf, "UTF-8")
                this.p.Send(SCI_SETPUNCTUATIONCHARS, 0, buf.Ptr)
            }
        }
    }

    Class Wrap {
        ; @prop {BCBEdit} p The parent `BCBEdit` instance to interact with
        p := {}

        ; @prop {Map} _WRAPMODES Dictionary of Scintilla wrap modes
        _WRAPMODES := Map( "none"  , SC_WRAP_NONE         ; 0
                         , "word"  , SC_WRAP_WORD         ; 1
                         , "char"  , SC_WRAP_CHAR         ; 2
                         , "white" , SC_WRAP_WHITESPACE ) ; 3
        ; @prop {Map} _VISUALFLAGSFLAGS Dictionary of Scintilla flags for wrap visual flags
        _VISUALFLAGSFLAGS := Map( "none",   SC_WRAPVISUALFLAG_NONE     ; 0
                                , "end",    SC_WRAPVISUALFLAG_END      ; 1
                                , "start",  SC_WRAPVISUALFLAG_START    ; 2
                                , "margin", SC_WRAPVISUALFLAG_MARGIN ) ; 4

        ; @param {BCBEdit} _BCBEdit The instance of `BCBEdit` to interact with
        __New(_BCBEdit) {
            this.p := _BCBEdit
        }

        /**
         * @prop {String} Mode
         *
         * This value can be any key in `BCBEdit.Wrap()._WRAPMODES`
         *
         *      BCBEdit.Wrap()._WRAPMODES := Map(
         *          "none",  SC_WRAP_NONE       := 0,
         *          "word",  SC_WRAP_WORD       := 1,
         *          "char",  SC_WRAP_CHAR       := 2,
         *          "white", SC_WRAP_WHITESPACE := 3
         *      )
         */
        Mode {
            Get {
                _wrap := this.p.Send(SCI_GETWRAPMODE)
                for wpname, wpval in this._WRAPMODES
                    if (_wrap = wpval)
                        Return wpname
            }
            Set {
                for wpname, wpval in this._WRAPMODES
                    if (wpname = Value)
                        this.p.Send(SCI_SETWRAPMODE, wpval)
            }
        }

        /**
         * @prop {Array} VisualFlags
         *
         * This value can be any combination of keys in `BCBEdit.Wrap._VISUALFLAGSFLAGS`,
         * stored inside an array
         *
         *      BCBEdit.Wrap._VISUALFLAGSFLAGS := Map(
         *          "none",   SC_WRAPVISUALFLAG_NONE   := 0x0000,
         *          "end",    SC_WRAPVISUALFLAG_END    := 0x0001,
         *          "start",  SC_WRAPVISUALFLAG_START  := 0x0002,
         *          "margin", SC_WRAPVISUALFLAG_MARGIN := 0x0004
         *      )
         */
        VisualFlags {
            Get {
                _flagBits := this.p.Send(SCI_GETWRAPVISUALFLAGS)
                _flags := !!(_flagBits) ? [] : ["none"]
                if _flagBits >= (_mgn:=this._VISUALFLAGSFLAGS["margin"]) {
                    _flagBits -= _mgn
                    _flags.Push("margin")
                }
                if _flagBits >= (_st:=this._VISUALFLAGSFLAGS["start"]) {
                    _flagBits -= _st
                    _flags.Push("start")
                }
                if _flagBits >= (_end:=this._VISUALFLAGSFLAGS["end"]) {
                    _flagBits -= _end
                    _flags.Push("end")
                }
                Return _flags
            }
            Set {
                _bitflag := 0x0000
                for flagName in Value
                    for flagNameRef, flagBitRef in this._VISUALFLAGSFLAGS
                        if (flagName=flagNameRef)
                            _bitflag += flagBitRef
                this.p.Send(SCI_SETWRAPVISUALFLAGS, _bitflag)
            }
        }

        /**
         * @prop {Integer} Indent
         *
         * Get and set the size of the indentation for sublines of wrapped text
         */
        Indent {
            Get => this.p.Send(SCI_GETWRAPSTARTINDENT)
            Set => this.p.Send(SCI_SETWRAPSTARTINDENT, Value)
        }
    }

    Class Caret {
        ; @prop {BCBEdit} p The parent `BCBEdit` instance to interact with
        p := {}

        ; @prop {Map} _STICKYMODES
        _STICKYMODES := Map( "off"       , SC_CARETSTICKY_OFF           ; 0
                           , "on"        , SC_CARETSTICKY_ON            ; 1
                           , "whitespace", SC_CARETSTICKY_WHITESPACE  ) ; 2

        /**
          * @param {BCBEdit} _BCBEdit
          *
          * The instance of `BCBEdit` to interact with
          */
        __New(_BCBEdit) {
            this.p := _BCBEdit
        }

        /**
         * @prop {Hex Color} Foreground
         *
         * An **8** digit **ARGB** hex color as a string or integer defining the color of
         * the caret foreground
         */
        Foreground {
            Get => this.p.Send(SCI_GETELEMENTCOLOUR, SC_ELEMENT_CARET)
            Set {
                _col := (Type(Value)="String") ? Integer("0x" Value) : Value
                this.p.Send(SCI_SETELEMENTCOLOUR, SC_ELEMENT_CARET, _col)
            }
        }

        /**
         * @prop {Hex Color} LineBackground
         *
         * An **8** digit **ARGB** hex color as a string or integer defining the color of
         * the background of the line the caret is on
         */
        LineBackground {
            Get => this.p.Send(SCI_GETELEMENTCOLOUR, SC_ELEMENT_CARET_LINE_BACK)
            Set {
                _col := (Type(Value)="String") ? Integer("0x" Value) : Value
                this.p.Send(SCI_SETELEMENTCOLOUR, SC_ELEMENT_CARET_LINE_BACK, _col)
            }
        }

        /**
         * @prop {String} Sticky
         *
         * This value can be any of the keys in `BCBEdit.Caret()._STICKYMODES`
         *
         *      BCBEdit.Caret()._STICKYMODES := Map(
         *          "off"       , SC_CARETSTICKY_OFF        := 0,
         *          "on"        , SC_CARETSTICKY_ON         := 1,
         *          "whitespace", SC_CARETSTICKY_WHITESPACE := 2
         *      )
         */
        Sticky {
            Get {
                _stickymode := this.p.Send(SCI_GETCARETSTICKY)
                for mdName, mdVal in this._STICKYMODES
                    if (mdVal=_stickymode)
                        Return mdName
            }
            Set {
                for mdName, mdVal in this._STICKYMODES
                    if (mdName=Value)
                        this.p.Send(SCI_SETCARETSTICKY, mdVal)
            }
        }

        /**
         * @prop {Integer} Width
         *
         * Get and set the width in pixels of the caret
         */
        Width {
            Get => this.p.Send(SCI_GETCARETWIDTH)
            Set => this.p.Send(SCI_SETCARETWIDTH, Value)
        }

        /**
         * @prop {Boolean} FrameDraw
         *
         * Toggle the appearance of a frame around the caret line (not filling it in)
         */
        FrameDraw {
            Get => this.p.Send(SCI_GETCARETLINEFRAME)
            Set => this.p.Send(SCI_SETCARETLINEFRAME, !!(Value))
        }
    }

    Class WhiteSpace {
        ; @prop {BCBEdit} p The parent `BCBEdit` instance to interact with
        p := {}

        ; @prop {Boolean} _UseIndents
        _UseIndents := False

        ; @prop {Map} _VISMODES
        _VISMODES := Map( "always_off"  , SCWS_INVISIBLE             ; 0
                        , "always_on"   , SCWS_VISIBLEALWAYS         ; 1
                        , "after_indent", SCWS_VISIBLEAFTERINDENT    ; 2
                        , "only_indent" , SCWS_VISIBLEONLYININDENT ) ; 3
        ; @prop {Map} _TABMODES
        _TABMODES := Map( "arrow" , SCTD_LONGARROW   ; 0
                        , "strike", SCTD_STRIKEOUT ) ; 1
        ; @prop {Map} _INDENTGUIDES
        _INDENTGUIDES := Map( "none"       , SC_IV_NONE          ; 0
                            , "real"       , SC_IV_REAL          ; 1
                            , "lookforward", SC_IV_LOOKFORWARD   ; 2
                            , "lookboth"   , SC_IV_LOOKBOTH    ) ; 3

        /**
         * @param {BCBEdit} _BCBEdit
         *
         * The instance of `BCBEdit` to interact with
         */
        __New(_BCBEdit) {
            this.p := _BCBEdit
        }

        /**
         * @prop {Hex Color} Foreground
         *
         * An **8** digit **ARGB** hex color as a string or integer defining the color of
         * the control's whitespace foreground
         */
        Foreground {
            Get => this.p.Send(SCI_GETELEMENTCOLOUR, SC_ELEMENT_WHITE_SPACE)
            Set {
                _col := (Type(Value)="String") ? Integer("0x" Value) : Value
                this.p.Send(SCI_SETELEMENTCOLOUR, SC_ELEMENT_WHITE_SPACE, _col)
            }
        }

        /**
         * @prop {String} Visibility
         *
         * This value can be any key in `BCBEdit.WhiteSpace()._VISMODES`
         *
         *      BCBEdit.WhiteSpace()._VISMODES := Map(
         *          "always_off"  , SCWS_INVISIBLE           := 0,
         *          "always_on"   , SCWS_VISIBLEALWAYS       := 1,
         *          "after_indent", SCWS_VISIBLEAFTERINDENT  := 2,
         *          "only_indent" , SCWS_VISIBLEONLYININDENT := 3
         *      )
         */
        Visibility {
            Get {
                _vis := this.p.Send(SCI_GETVIEWWS)
                for visName, visVal in this._VISMODES
                    if (_vis=visVal)
                        Return visName
            }
            Set {
                for visName, visVal in this._VISMODES
                    if (visName=Value)
                        this.p.Send(SCI_SETVIEWWS, visVal)
            }
        }

        /**
         * @prop {String} TabStyle
         *
         * This value can be either of the keys in `BCBEdit.WhiteSpace()._TABMODES`
         *
         *      BCBEdit.WhiteSpace()._TABMODES := Map(
         *          "arrow" , SCTD_LONGARROW := 0,  ; Default
         *          "strike", SCTD_STRIKEOUT := 1
         *      )
         */
        TabStyle{
            Get {
                _tabmode := this.p.Send(SCI_GETTABDRAWMODE)
                for mdName, mdVal in this._TABMODES
                    if (mdVal=_tabmode)
                        Return mdName
            }
            Set {
                for mdName, mdVal in this._TABMODES
                    if (mdName=Value)
                        this.p.Send(SCI_SETTABDRAWMODE, mdVal)
            }
        }

        /**
         * @prop {Integer} TabWidth
         *
         * Get and set the size of the tabs used in the control
         */
        TabWidth {
            Get => this.p.Send(SCI_GETTABWIDTH)
            Set => this.p.Send(SCI_SETTABWIDTH, Value)
        }

        /**
         * @prop {Boolean} UseTabs
         *
         * Toggle whether the control uses tabs or spaces
         */
        UseTabs {
            Get => this.p.Send(SCI_GETUSETABS)
            Set => this.p.Send(SCI_SETUSETABS, !!(Value))
        }

        /**
         * @prop {Boolean} UseIndents
         *
         * Toggle whether the tab and backspace keys insert/delete characters or
         * indent/unindent the current line
         */
        UseIndents {
            Get => this._UseIndents
            Set {
                this._UseIndents := !!(Value)
                this.p.Send(SCI_SETTABINDENTS, this._UseIndents)
                this.p.Send(SCI_SETBACKSPACEUNINDENTS, this._UseIndents)
            }
        }

        /**
         * @prop {String} IndentGuides
         *
         * Get/Set the indentation guide mode. This value can be any of the keys in
         *      `BCBEdit.WhiteSpace()._INDENTGUIDES`
         *
         *      BCBEdit.WhiteSpace()._INDENTGUIDES := Map(
         *            "none"       , SC_IV_NONE        := 0 ; Default
         *          , "real"       , SC_IV_REAL        := 1
         *          , "lookforward", SC_IV_LOOKFORWARD := 2
         *          , "lookboth"   , SC_IV_LOOKBOTH    := 3
         *      )
         */
        IndentGuides {
            Get {
                _igIDCurrent := this.p.Send(SCI_GETINDENTATIONGUIDES)
                for igName, igID in this._INDENTGUIDES
                    if (_igIDCurrent=igID)
                        Return igName
            }
            Set {
                for igName, igID in this._INDENTGUIDES
                    if (Value=igName)
                        this.p.Send(SCI_SETINDENTATIONGUIDES, igID)
            }
        }

        /**
         * @prop {String|Integer} IndentGuideColor
         *
         * Get/Set the indent guide color. This value can be a string of alphanumeric
         *      characters describing the hex color code (omitting `#`) or alternatively
         *      can be the integer value of the hex color code.
         */
        IndentGuideColor {
            Get => this.p.Send(SCI_STYLEGETFORE, STYLE_INDENTGUIDE)
            Set {
                _col := (Type(Value) = "String") ? Integer("0x" Value) : Value
                this.p.Send(SCI_STYLESETFORE, STYLE_INDENTGUIDE, _col)
            }
        }

        /**
         * @prop {Integer} Size
         *
         * Get and set the size of the whitespace markers in the control
         */
        Size {
            Get => this.p.Send(SCI_GETWHITESPACESIZE)
            Set => this.p.Send(SCI_SETWHITESPACESIZE, Value)
        }
    }

    Class Selection {
        ; @prop {BCBEdit} p The parent `BCBEdit` instance to interact with
        p := {}

        /**
         * @param {BCBEdit} _BCBEdit The instance of `BCBEdit` to interact with
         */
        __New(_BCBEdit) {
            this.p := _BCBEdit
            this.Additional := BCBEdit.Selection.Additional(_BCBEdit)
        }

        /**
         * @prop {Hex Color} Background
         *
         * An **6-8** digit **(A)RGB** hex color as a string or integer defining the color
         * of the selection background
         */
        Background {
            Get => this.p.Send(SCI_GETELEMENTCOLOUR, SC_ELEMENT_SELECTION_BACK)
            Set {
                _col := (Type(Value) = "String") ? Integer("0x" Value) : Value
                this.p.Send(SCI_SETELEMENTCOLOUR, SC_ELEMENT_SELECTION_BACK, _col)
            }
        }

        /**
         * @prop {Hex Color} Foreground
         *
         * An **6-8** digit **(A)RGB** hex color as a string or integer defining the color
         * of the selection foreground
         */
        Foreground {
            Get => this.p.Send(SCI_GETELEMENTCOLOUR, SC_ELEMENT_SELECTION_TEXT)
            Set {
                _col := (Type(Value) = "String") ? Integer("0x" Value) : Value
                this.p.Send(SCI_SETELEMENTCOLOUR, SC_ELEMENT_SELECTION_TEXT, _col)
            }
        }

        Class Additional {
            ; @prop {BCBEdit} p The parent `BCBEdit` instance to interact with
            p := {}

            /**
             * @param {BCBEdit} _BCBEdit The instance of `BCBEdit` to interact with
             */
            __New(_BCBEdit) {
                this.p := _BCBEdit
            }

            /**
             * @prop {Hex Color} Foreground
             *
             * An **6-8** digit **(A)RGB** hex color as a string or integer defining the color
             * of the additional selection foreground
             */
            Foreground {
                Get => this.p.Send(SCI_GETELEMENTCOLOUR, SC_ELEMENT_SELECTION_ADDITIONAL_TEXT)
                Set {
                    _col := (Type(Value) = "String") ? Integer("0x" Value) : Value
                    this.p.Send(SCI_SETELEMENTCOLOUR, SC_ELEMENT_SELECTION_ADDITIONAL_TEXT, _col)
                }
            }
        }

    }
}

; `BCBApp` starts the **BetterClipboard** application upon the initialization
; of a new instance
Class BCBApp {
    ; @prop {Boolean} active
    active := False
    ; @prop {Boolean} updatingClip
    updatingClip := False

    ; @prop {Gui} gui
    gui := {}
    ; @prop {BCBEdit()} edit
    edit := {}
    ; @prop {BCBIndexGui} idxGui
    idxGui := {}

    ; @prop {Object} colors
    colors := {
             bg:   "080e09",    ;  BGR
             fg:   "b6ffb1",    ;  BGR
         border:   "53864f",    ;  BGR
        indexbg:   "2a392b",    ;  BGR
        indexfg:   "5a8b5e",    ;  BGR
          caret: "c0fafffa",    ; ABGR
        caretln: "0a1a2a1a",    ; ABGR
          selbg: "aa579261",    ; ABGR
          selfg: "ff001000",    ; ABGR
        adselfg: "ff080e09",    ; ABGR
        whitefg: "5595d58a",    ; ABGR
        guidefg: "ff3c4e22"     ; ABGR
    }
    ; @prop {String} fontName
    fontName := "CaskaydiaCove Nerd Font Mono"

    ; @prop {Number} fontSizeMin
    fontSizeMin := 3
    ; @prop {Number} fontSizeMax
    fontSizeMax := 50

    ; @prop {Integer} fadeSteps Number of transparency steps in fade animation
    fadeSteps := 6
    ; @prop {Integer} fadeRest Ticks between transparency steps in fade animation
    fadeRest := 1
    ; @prop {Integer} opacity 0-255
    opacity := 225
    ; @prop {Integer} currentOp Current gui opacity [1-255]
    currentOp := 0

    ; @prop {Integer} indexDuration
    indexDuration := 500
    ; @prop {Integer} shownIndex Index of currently shown clip
    shownIndex := 0
    ; @prop {Integer} maxIndex
    maxIndex := 0
    ; @prop {Integer} curIndex Index of most recently created clip
    curIndex := 0

    ; @prop {Object} starting_dims
    starting_dims := {x: "Center", y: "Center", w: 700, h: 400}

    __New() {
        this.shownIndex := this.curIndex := BCBConf.Index["Current"]
        this.maxIndex := BCBConf.Index["Max"]
        this.InitClipsDir()

        this.gui := Gui("-Caption +ToolWindow +AlwaysOnTop","BetterClipboard", this)
        this.gui.OnEvent("Close", "Gui_OnClose")
        this.gui.MarginX := this.gui.MarginY := 3
        this.gui.BackColor := this.colors.border

        if (A_ScreenWidth < A_ScreenHeight)
            this.starting_dims.w := 888,
            this.starting_dims.h := 888,
            this.starting_dims.y := (A_ScreenHeight -
                                    this.starting_dims.h -
                                    (A_ScreenWidth - this.starting_dims.w) / 2)

        dimstr := ""
        dimstr .= "w" this.starting_dims.w " "
                . "h" this.starting_dims.h " "
        this.edit := BCBEdit(this.gui, dimstr)
        this.edit.Font.Name := this.fontName
        this.edit.Wrap.Mode := "word"
        this.edit.Wrap.VisualFlags := ["start", "end"]
        this.edit.Wrap.Indent := 2
        this.edit.Technology := "dw"
        this.edit.MarginWidth := 0
        this.edit.MultipleSelection := True
        this.edit.AdditionalSelectionTyping := True
        this.edit.MultiPaste := True
        this.edit.ScrollBar := False
        this.edit.ScrollPastEnd := False
        this.edit.Background := this.colors.bg
        this.edit.Foreground := this.colors.fg
        this.edit.Selection.Background := this.colors.selbg
        this.edit.Selection.Foreground := this.colors.selfg
        this.edit.Selection.Additional.Foreground := this.colors.adselfg
        this.edit.WhiteSpace.Visibility := "always_on"
        this.edit.WhiteSpace.Foreground := this.colors.whitefg
        this.edit.WhiteSpace.TabWidth := 4
        this.edit.WhiteSpace.UseTabs := False
        this.edit.WhiteSpace.UseIndents := True
        this.edit.WhiteSpace.Size := 2
        this.edit.WhiteSpace.IndentGuides := "lookboth"
        this.edit.WhiteSpace.IndentGuideColor := this.colors.guidefg
        ; this.edit.WhiteSpace.TabStyle := "strike"
        this.edit.Caret.Foreground := this.colors.caret
        this.edit.Caret.LineBackground := this.colors.caretln
        this.edit.Caret.Sticky := "on"
        this.edit.Caret.Width := 2
        ; this.edit.Caret.FrameDraw := True

        if (A_ScreenWidth < 1900)
            Loop 3
                this.edit.ZoomIn()

        this.gui.Show("NA x" (A_ScreenWidth*(-1000) - 5))
        WinSetTransparent(0, this.gui)
        this.gui.Show("Hide x" this.starting_dims.x " y" this.starting_dims.y)

        this.idxGui := BCBIndexGui(this.gui, this.colors)

        this.SetClip(this.shownIndex)
        this.InitHotkeys()
        OnMessage(0x1666, ObjBindMethod(this, "OnSizingStartEnd"))
        OnMessage(0x1667, (*)=>ExitApp())
        OnClipboardChange(ObjBindMethod(this, "ClipChange"))
    }



    /**
     * Upon receiving a message from my default-running script that is sent
     * when using Alt+Shift+RButton to resize the window, stop redrawing the
     * window and make the window black -- and change it back to the default
     * upon receiving the message sent when Alt+Shift+RButton is released.
     * This prevents some pretty intense flickering.
     * @param {Integer} wparam **Zero** or **Non-zero**
     * @param {Integer} lparam *unused*
     * @param {Integer} msg The code for the received message
     * @param {Integer} hwnd The handle of the receiving window
     */
    OnSizingStartEnd(_wparam, _lparam, _msg, _hwnd) {
        ; on sizing start -->
        if (!!_wparam) {
            ;; may need to set [20] back to [25]
            SetTimer SizingLoop, 20
            this.gui.BackColor := this.colors.bg
            this.edit.ctrl.Opt("-Redraw")
        ; on sizing end ---->
        } else {
            SetTimer SizingLoop, 0
            this.gui.BackColor := this.colors.border
            this.edit.ctrl.Opt("+Redraw")
        }
        SizingLoop(*) {
            this.gui.GetPos(,,&_w, &_h)
            w_new := _w-(this.gui.MarginX*2)
            h_new := _h-(this.gui.MarginY*2)
            this.edit.ctrl.Move(,,w_new, h_new)
        }
    }

    /**
     * Use the specified clipboard entry to set the currently shown text
     *       of the Scintilla control and update the index indicator respectively
     *
     * @param {Integer} _index
     */
    SetClip(_index) {
        this.edit.Text := FileRead(BCB_CLIPS_DIR "\" _index ".clip")
        this.idxGui.text.Value := _index
        this.shownIndex := _index
    }

    /**
     * Update the currently shown clip with the previous; Upon hitting the
     *      very first clip and executing this function, the current clip will
     *      be updated to be the last clip that was captured.
     *
     * ***May change this functionality***
     * ***to roll over to the clip with***
     * ***the highest index that exists***
     */
    PrevClip(*) {
        newIndex := this.shownIndex - 1
        if (newIndex <= 0)
            newIndex := this.curIndex
        if (FileExist(BCB_CLIPS_DIR "\" newIndex ".clip") ~= "A|N")
            this.SetClip(newIndex)
        this.idxGui.ShowGui()
        this.idxGui.StartTimeout()
    }

    /**
     * Update the currently shown clip with the next; Rolls over to index 1 after
     *      hitting the clip with the highest index. (Not the current clip)
     */
    NextClip(*) {
        newIndex := this.shownIndex + 1
        if (FileExist(BCB_CLIPS_DIR "\" newIndex ".clip") ~= "A|N")
            this.SetClip(newIndex)
        else
            this.SetClip(1)
        this.idxGui.ShowGui()
        this.idxGui.StartTimeout()
    }

    /**
     * Create new clip using the current clipboard contents
     */
    NewClip() {
        newIndex := this.curIndex + 1
        if (newIndex > this.maxIndex)
            newIndex := 1
        if (FileExist(clipPath:=(BCB_CLIPS_DIR "\" newIndex ".clip")) ~= "A|N")
            FileDelete(clipPath)
        FileAppend(A_Clipboard, clipPath, "UTF-8")
        BCBConf.Index["Current"] := this.curIndex := newIndex
    }

    /**
     * Function called on `OnClipboardChange`
     * @param {0|1|2} type The type of the clipboard contents
     */
    ClipChange(type) {
        static CB_EMPTY := 0, CB_TEXT := 1, CB_NON_TEXT := 2
        if (type=CB_TEXT) {
            this.NewClip()
            if this.updatingClip
                this.SetClip(this.curIndex), this.updatingClip := False
        }
    }

    /**
     * Update the clipboard contents with the currently shown text in the control
     */
    UpdateClipboardFromEdit(_hide:=False, *) {
        this.updatingClip := True
        A_Clipboard := this.edit.Text
        if _hide
            this.HideGui()
        else this.idxGui.ShowGui(), this.idxGui.StartTimeout()
    }

    /**
     * Update the current clip's file with the currently shown text
     */
    SaveShownClip(*) {
        current_text := this.edit.Text
        shownClip:=(BCB_CLIPS_DIR "\" this.shownIndex ".clip")
        if (FileExist(shownClip) ~= "A|N") {
            FileDelete(shownClip)
            FileAppend(current_text, shownClip, "UTF-8")
            JKQuickToast(shownClip, "Updated " this.shownIndex ".clip ...", 1500)
        }
    }

    /**
     * Broken method to delete the currently shown clip.
     * ***FIX LATER***
     */
    DeleteShownClip(*) {
        ; if (FileExist(shownClip:=(BCB_CLIPS_DIR "\" this.shownIndex ".clip")) ~= "A|N") {
        ;     fileList := Map()
        ;     Loop Files, BCB_CLIPS_DIR "\*.clip" {
        ;         filePrefix := StrReplace(A_LoopFileName, ".clip")
        ;         if ( (filePrefix ~= "^\d+$") and (Integer(filePrefix) > this.shownIndex) ) {
        ;             fileList[filePrefix] := { old: A_LoopFileName, new: filePrefix-1 ".clip"}
        ;         }
        ;     }
        ;     for filePF, fileInfo in fileList {
        ;         FileMove BCB_CLIPS_DIR "\"
        ;     }
        ;     FileDelete(shownClip)
        ; }
    }

    /**
     * Insert new blank line above the current and jump to it (doesn't split line)
     */
    NewLineAbove(*) {
        this.edit.Send(SCI_HOME)
        this.edit.Send(SCI_NEWLINE)
        this.edit.Send(SCI_LINEUP)
    }

    /**
     * Insert new blank line below the current and jump to it (doesn't split line)
     */
    NewLineBelow(*) {
        this.edit.Send(SCI_LINEEND)
        this.edit.Send(SCI_NEWLINE)
    }

    /**
     * Setup hotkeys for the control
     */
    InitHotkeys() {
        HotIf (*) => this.active
        Hotkey("!Enter"  , ObjBindMethod(this     , "UpdateClipboardFromEdit", True ))
        Hotkey("^!Enter" , ObjBindMethod(this     , "UpdateClipboardFromEdit", False))
        Hotkey("!+Enter" , ObjBindMethod(this     , "SaveShownClip"                 ))
        Hotkey("^Enter"  , ObjBindMethod(this     , "NewLineBelow"                  ))
        Hotkey("^+Enter" , ObjBindMethod(this     , "NewLineAbove"                  ))
        Hotkey("<#c"     , ObjBindMethod(this     , "HideGui"                       ))
        Hotkey("PgDn"    , ObjBindMethod(this     , "PrevClip"                      ))
        Hotkey("PgUp"    , ObjBindMethod(this     , "NextClip"                      ))
        Hotkey("!+Delete", ObjBindMethod(this     , "DeleteShownClip"               ))
        Hotkey("^-"      , ObjBindMethod(this.edit, "ZoomOut"                       ))
        Hotkey("^="      , ObjBindMethod(this.edit, "ZoomIn"                        ))
        Hotkey("^+z"     , ObjBindMethod(this.edit, "Redo"                          ))
        Hotkey("^+d"     , ObjBindMethod(this.edit, "Duplicate"                     ))
        Hotkey("^d"      , ObjBindMethod(this.edit, "SelectNext"                    ))
        Hotkey("^+a"     , ObjBindMethod(this.edit, "SelectEach"                    ))
        Hotkey("^c"      , ObjBindMethod(this.edit, "CopyAllowLine"                 ))
        Hotkey("^+Up"    , ObjBindMethod(this.edit, "MoveLineUp"                    ))
        Hotkey("^+Down"  , ObjBindMethod(this.edit, "MoveLineDown"                  ))
        Hotkey("!Up"     , ObjBindMethod(this.edit, "AddCaretAbove"                 ))
        Hotkey("!Down"   , ObjBindMethod(this.edit, "AddCaretBelow"                 ))
        Hotkey("!Right"  , ObjBindMethod(this.edit, "RotateSelection"               ))
        Hotkey("!Left"   , ObjBindMethod(this.edit, "RotateSelectionReverse"        ))
        ; Hotkey("!+p"     , (*)=>(A_Clipboard:=this.edit.Chars.Punctuation))
        HotIf (*) => !(this.active)
        Hotkey("<#c", ObjBindMethod(this, "ShowGui"))
        HotIf()
    }

    /**
     * Validate the existence of the directory to store clips (creating it if necessary).
     *      Will fail and exit the app if parent dir does not exist.
     *
     * If no clips exist in the directory, create one with the current clipboard contents.
     *
     * Fixes an out of bounds value in the .ini for the current index by
     *      forcing the current index to *1*, (over)writing `1.clip` with the
     *      current clipboard. A value can be out of bounds if it's less than 1,
     *      greater than the maxindex, or if the corresponding clip file doesn't exist.
     */
    InitClipsDir() {
        if !(DirExist(BCB_CLIPS_DIR)) {
            SplitPath(BCB_CLIPS_DIR,, &parentDir)
            if !(DirExist(parentDir)) {
                MsgBox("The path as determined by 'BCB_CLIPS_DIR' is not "
                     . "a valid directory and could not be created.")
                ExitApp()
            } else {
                DirCreate(BCB_CLIPS_DIR)
            }
        }
        fileCount := 0
        Loop Files, BCB_CLIPS_DIR "\*.clip"
            fileCount++
        if !(fileCount) {
            FileAppend(A_Clipboard, BCB_CLIPS_DIR "\1.clip", "UTF-8")
            BCBConf.Index["Current"] := this.curIndex := 1
        } else if ((this.curIndex <= 0) or (this.curIndex > this.maxIndex)) {
            if (FileExist(clip1:=(BCB_CLIPS_DIR "\1.clip")))
                FileDelete(clip1)
            FileAppend(A_Clipboard, clip1, "UTF-8")
            BCBConf.Index["Current"] := this.curIndex := 1
        } else if !(FileExist(clipC:=(BCB_CLIPS_DIR "\" this.curIndex ".clip")) ~= "A|N") {
            FileAppend(A_Clipboard, clipC, "UTF-8")
        }
    }

    /**
     * Fade in the gui and set the current clip
     */
    ShowGui(*) {
        static fadeAmt := this.opacity / this.fadeSteps
        this.active := True
        this.gui.Show()
        this.SetClip(this.curIndex)
        FadeIn(*) {
            if !(this.active) {
                SetTimer(, 0)
            } else {
                newTrans := Round(this.currentOp + fadeAmt)
                if (newTrans >= (this.opacity-1)) {
                    SetTimer(, 0)
                    WinSetTransparent(this.opacity, this.gui)
                    this.currentOp := this.opacity
                    this.idxGui.ShowGui()
                    this.idxGui.StartTimeout()
                    if !WinActive(this.gui)
                        WinActivate(this.gui)
                } else {
                    WinSetTransparent(newTrans, this.gui)
                    this.currentOp := newTrans
                }
            }
        }
        SetTimer(FadeIn, this.fadeRest)
    }

    /**
     * Fade out the gui
     */
    HideGui(*) {
        static fadeAmt := this.opacity / this.fadeSteps
        this.active := False
        FadeOut(*) {
            if (this.active) {
                SetTimer(, 0)
            } else {
                newTrans := Round(this.currentOp - fadeAmt)
                if (newTrans <= 1) {
                    SetTimer(, 0)
                    WinSetTransparent(0, this.gui)
                    this.currentOp := 0
                    this.gui.Hide()
                } else {
                    WinSetTransparent(newTrans, this.gui)
                    this.currentOp := newTrans
                }
            }
        }
        this.idxGui.StopTimeout()
        this.idxGui.HideGuiImmediately()
        SetTimer(FadeOut, this.fadeRest)
    }

    Gui_OnClose(guiObj, *) {
        ExitApp
    }
}
