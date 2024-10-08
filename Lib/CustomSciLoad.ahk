/**
 * SciLoad uses the **LoadLibrary** function from **libloaderapi.h**
 *      to load the Scintilla DLL library and bind a method named **`SciAdd`**
 *      to the prototype of the global Gui class. **SciAdd** takes one
 *      argument, the options parameter associated with **`Gui.Add`**. The
 *      control returned from **SciAdd** owns a **`Send`** method used for
 *      sending messages directly to the control via DLL calls, which takes
 *      a *message*, optional *wparam*, and optional *lparam* as arguments.
 *
 *
 * @param {`String`} _sci_dll If left blank, "Scintilla.dll" will be searched
 *                              for in the current working directory.
 * @param {`String`} _lex_dll If left blank, "CustomLexer.dll" will be searched
 *                              for in the current working directory.
 * @return {`Object`} Pointers to the Scintilla.dll and CustomLexer.dll libraries
 * 
 *      ReturnObj := {
 *          sci: 0x123456   ; scintilla.dll pointer
 *          lex: 0x654321   ; customlexer.dll pointer
 *      }
 */
SciLoad(_sci_dll:="", _lex_dll:="") {
    ; Load Scintilla library and obtain pointer
    _sci_pointer := DllCall( "LoadLibrary"                                    ;
                           , "Str", !!_sci_dll ? _sci_dll : "Scintilla.dll"   ;
                           , "Ptr"                                            )
    
    _lex_pointer := DllCall( "LoadLibrary"                                    ;
                           , "Str", !!_sci_dll ? _sci_dll : "CustomLexer.dll" ;
                           , "Ptr"                                            )
    /**
     * Function to be attached to *`Gui.Prototype`*, allowing for a custom
     *      Scintilla control to be added with a **`Send`** method for sending
     *      messages to the control directly with DLL calls
     */
    SciAdd(_gui, _opts:="") {
        ctrl := _gui.Add("Custom", "ClassScintilla " _opts)
        ctrl.Send := SciCtrlSend
        ctrl.Send(0, 0, 0, ctrl.Hwnd)
        Return ctrl
    }

    ; Set SciAdd method for global Gui class
    Gui.Prototype.SciAdd := SciAdd

    ; Return pointer to Scintilla library
    Return { sci: _sci_pointer, lex: _lex_pointer }
}

/**
 * SciFree uses the **FreeLibrary** function from **libloaderapi.h** in System Services
 * @param {`Object`} _pointers Pointers to the Scintilla.dll and CustomLexer.dll libraries
 */
SciFree(_pointers) {
    Try
        FileAppend("Freeing the Scintilla.dll Library...`n", "*")

    DllCall("FreeLibrary", "Ptr", _pointers.sci)

    Try
        FileAppend("Freeing the custom lexer dll library...`n", "*")

    DllCall("FreeLibrary", "Ptr", _pointers.lex)
}

/**
 * Retrieve direct references to a Scintilla function and pointer and store
 *      them in static variables so as to avoid the overhead associated with
 *      using SendMessage. The hwnd is stored in a static variable after first
 *      usage (and subsequents).
 * @param {Int} _msg
 * @param {UInt} _wparam
 * @param {UInt} _lparam
 * @param {hWnd} _hwnd
 */
SciSend(_msg, _wparam:=0, _lparam:=0, _hwnd:="") {
    static _init := False
         , _DirectFunction := ""
         , _DirectPointer  := ""
         , _SCI_GETDIRECTFUNCTION := 2184
         , _SCI_GETDIRECTPOINTER  := 2185
    if !_init and _hwnd {
        _init := True
        _DirectFunction := SendMessage(_SCI_GETDIRECTFUNCTION, 0, 0,, "ahk_id " _hwnd)
        _DirectPointer  := SendMessage(_SCI_GETDIRECTPOINTER , 0, 0,, "ahk_id " _hwnd)
        Return
    } else if !_init and !_hwnd
        Return
    Return DllCall(_DirectFunction
                 , "UInt", _DirectPointer
                 , "Int" , _msg
                 , "UInt", _wparam
                 , "UInt", _lparam)
}

/**
 * If **_hwnd** is present and the *`_DirectFunction`* or *`_DirectPointer`*
 *      property is not already set for **_ctrl**, a direct reference to a
 *      Scintilla function and pointer are retrieved and stored as said
 *      properties of **_ctrl**. Subsequent calls use the function and pointer
 *      to send messages via DLL calls to the Scintilla ctrl without the
 *      overhead associated with SendMessage.
 *
 *
 * This function is meant to be bound to a *`Gui.Custom`* Scintilla control,
 *      and as such would pass a hidden **this** variable
 *      into the first parameter (**_ctrl**), leaving only the remaining
 *      parameters to be passed when calling.
 *
 * @param {Gui.Custom} _ctrl
 * @param {Any} _msg
 * @param {Integer} _wparam
 * @param {Integer} _lparam
 * @param {Hwnd} _hwnd
 */
SciCtrlSend(_ctrl, _msg, _wparam:=0x00, _lparam:=0x00, _hwnd:=0x00) {
    static _SCI_GETDIRECTFUNCTION := 2184
         , _SCI_GETDIRECTPOINTER  := 2185

    ; Check for existence of function/pointer properties in _ctrl
    if !(_ctrl.HasOwnProp("_DirectFunction")) or !(_ctrl.HasOwnProp("_DirectPointer"))
        _init := false
    else _init := true

    ; If properties aren't initialized, do so
    if (!_init and _hwnd) {
        _ctrl.DefineProp("_DirectFunction", {
            Value: SendMessage(_SCI_GETDIRECTFUNCTION, 0, 0,, "ahk_id " _hwnd)
        })
        _ctrl.DefineProp("_DirectPointer", {
            Value: SendMessage(_SCI_GETDIRECTPOINTER , 0, 0,, "ahk_id " _hwnd)
        })
        Return
    } else if (!_init and !_hwnd) {  ; properties do not exist and cannot be set
        Return
    }

    ; Send message to Scintilla control
    Return DllCall( _ctrl._DirectFunction
                  , "UInt", _ctrl._DirectPointer
                  , "Int", _msg
                  , "UInt", _wparam
                  , "UInt", _lparam )
}