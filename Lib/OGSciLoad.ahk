

SciLoad(_dll_path:="SciLexer.dll") {
    _sci_pointer := DllCall("LoadLibrary", "Str", _dll_path, "Ptr")
    Gui.Prototype.SciAdd := ((_gui, _opts:="")=>_SciBase(_gui, _opts))
    Return _sci_pointer
}

SciFree(_sci_pointer) {
    Try
        FileAppend("Freeing the Scintilla.dll Library...`n", "*")

    DllCall("FreeLibrary", "Ptr", _sci_pointer)
}

Class _SciBase {
    Static Default := {
        Options: {
            x: 5,
            y: 5,
            w: 450,
            h: 250,
            Style: 0x40000000 | 0x00010000,  ; WS_CHILD | WS_TABSTOP
            Visible: False,
            ExStyle: 0x00000200,  ; WS_EX_CLIENTEDGE
            GuiID: 311210
        }
    }
    Options := {
        x: 5,
        y: 5,
        w: 450,
        h: 250,
        Style: 0x40000000 | 0x00010000,  ; WS_CHILD | WS_TABSTOP
        Visible: False,
        ExStyle: 0x00000200,  ; WS_EX_CLIENTEDGE
        GuiID: 311210
    }
    
    /* @prop {Gui} gui */
    gui := {}
    
    __New(_gui, _opts:="") {
        Global sNul := ""
             , iNul := 0
        if (IsObject(_opts))
            for _prop, _def in _opts.OwnProps()
                if (this.Options.HasOwnProp(_prop))
                    this.Options.%_prop% := _def
        this.gui := _gui
        this.Init()
    }

    Init() {
        WStyle := ( (!!this.Options.Visible)          ;
                  ? (this.Options.Style | 0x10000000) ;  <Style> | WS_VISIBLE
                  : this.Options.Style              ) ;
        this.hwnd := DllCall("CreateWindowEx"                      ; -------------
                            ,"Uint", this.Options.ExStyle          ; Ex Style
                            ,"Str",  "Scintilla"                   ; Class Name
                            ,"Str",  sNul                          ; Window Name
                            ,"UInt", WStyle                        ; Window Styles
                            ,"Int",  this.Options.x                ; x
                            ,"Int",  this.Options.y                ; y
                            ,"Int",  this.Options.w                ; Width
                            ,"Int",  this.Options.h                ; Height
                            ,"UInt", this.gui.Hwnd                 ; Parent HWND
                            ,"UInt", this.Options.GuiID            ; (HMENU)GuiID
                            ,"UInt", iNul                          ; hInstance
                            ,"UInt", iNul, "UInt")                 ; lpParam
        this.Send(iNul, iNul, iNul, this.hwnd)
        Return this.hwnd
    }

    Send(_msg, _wparam:=0x00, _lparam:=0x00, _hwnd:=0x00) {
        static _SCI_GETDIRECTFUNCTION := 2184, _SCI_GETDIRECTPOINTER  := 2185
             , _DirectFunction := 0x0, _DirectPointer := 0x0
             , _init := False
    
        ; If properties aren't initialized, do so
        if (!_init and _hwnd) {
            _DirectFunction := SendMessage(_SCI_GETDIRECTFUNCTION, 0, 0,, "ahk_id " _hwnd)
            _DirectPointer := SendMessage(_SCI_GETDIRECTPOINTER , 0, 0,, "ahk_id " _hwnd)
            _init := True
            Return
        } else if (!_init and !_hwnd) {  ; properties do not exist and cannot be set
            Return
        }
    
        ; Send message to Scintilla control
        Return DllCall( _DirectFunction
                      , "UInt", _DirectPointer
                      , "Int", _msg
                      , "UInt", _wparam
                      , "UInt", _lparam )
    }
}
