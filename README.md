# BCV2
A clipboard manager written in AutoHotkey v2 using a Scintilla edit control

### Hotkey List
```
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
```
