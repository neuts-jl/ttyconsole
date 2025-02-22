  {
    *****************************************************************************
     Unit        : uttykeyboard
     Author      : NEUTS JL
     License     : GPL (GNU General Public License)
     Date        : 01/02/2025

     Description : This unit handles keyboard management in console mode

     WARNING     : This program does not use the CRT unit, because it disrupts
                   the proper functioning of the console, especially for launched
                   shells.

     This program is free software: you can redistribute it and/or modify it
     under the terms of the GNU General Public License as published by the Free
     Software Foundation, either version 3 of the License, or (at your option)
     any later version.

     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
     Public License for more details.

     You should have received a copy of the GNU General Public License along with
     this program. If not, see <https://www.gnu.org/licenses/>.
    *****************************************************************************
  }
unit uttykeyboard;

{$mode ObjFPC}{$H+}

interface
uses
  Classes, sysutils, uttyansi;

type
  TKeysArray = array of integer;

const
  vkUp = $FF26;
  vkPageUp = $FF21;
  vkDown = $FF28;
  vkPageDown = $FF22;
  vkRight = $FF27;
  vkLeft = $FF25;
  vkDelete = $FF2E;
  vkIns = $FF2D;
  vkBack = $0008;
  vkTab = $0009;
  vkShiftTab = $FF09;
  vkReturn = $000D;
  vkEscape = $001B;
  vkHome = $FF24;
  vkEnd = $FF23;

  vkF1 = $FF70;
  vkF2 = $FF71;
  vkF3 = $FF72;
  vkF4 = $FF73;
  vkF5 = $FF74;
  vkF6 = $FF75;
  vkF7 = $FF76;
  vkF8 = $FF77;
  vkF9 = $FF78;
  vkF10 = $FF79;
  vkF11 = $FF7A;
  vkF12 = $FF7B;


function KeyPressed: boolean;
function ReadKeyboard: integer;
function IsKeyInSet(key: integer; const Keys: TKeysArray): boolean;

implementation

{$IFDEF WINDOWS}
uses
  Windows;

var
  stdin:THandle;

function KeyPressed: Boolean;
var
  InputRecArray: array of TInputRecord;
  NumRead: DWORD;
  NumEvents: DWORD;
  I: Integer;
  KeyCode: Word;
begin
  Result := False;
  if StdIn=0 then
  begin
    Reset(Input);
    StdIn := TTextRec(Input).Handle;
  end;
  GetNumberOfConsoleInputEvents(StdIn, NumEvents);
  if NumEvents = 0 then
    Exit;
  SetLength(InputRecArray, NumEvents);
  PeekConsoleInput(StdIn, InputRecArray[0], NumEvents, NumRead);
  for I := 0 to High(InputRecArray) do
  begin
    if (InputRecArray[I].EventType and Key_Event <> 0) and
       InputRecArray[I].Event.KeyEvent.bKeyDown then
    begin
      KeyCode := InputRecArray[I].Event.KeyEvent.wVirtualKeyCode;
      if not (KeyCode in [VK_SHIFT, VK_MENU, VK_CONTROL]) then
      begin
//        if ConvertKey(InputRecArray[I], FindKeyCode(KeyCode)) <> -1 then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
end;

function ReadKeyboard: Integer;
var
  Input: INPUT_RECORD;
  ReadCount: DWORD;
  ShiftPressed: Boolean;
  CapsLockState: Boolean;
  AltPressed: Boolean;
  KeyChar: Char;
  KeyCode: Word;
begin
  Result := 0;
  while Result=0 do
  begin
    if ReadConsoleInput(GetStdHandle(STD_INPUT_HANDLE), Input, 1, ReadCount) then
    begin
      if (Input.EventType = KEY_EVENT) and (Input.Event.KeyEvent.bKeyDown) then
      begin
        KeyCode := Input.Event.KeyEvent.wVirtualKeyCode;
        KeyChar := Input.Event.KeyEvent.AsciiChar;
        ShiftPressed := (Input.Event.KeyEvent.dwControlKeyState and SHIFT_PRESSED) <> 0;
        AltPressed := (Input.Event.KeyEvent.dwControlKeyState and (LEFT_ALT_PRESSED or RIGHT_ALT_PRESSED)) <> 0;
        CapsLockState := (Input.Event.KeyEvent.dwControlKeyState and CAPSLOCK_ON) <> 0;

        if KeyChar <> #0 then
        begin
          if (KeyChar=#9) and ShiftPressed then
            Result:=vkShiftTab
          else
            begin
            if (KeyChar >= 'a') and (KeyChar <= 'z') then
            begin
              if ShiftPressed xor CapsLockState then
                KeyChar := UpCase(KeyChar);
            end
            else if (KeyChar >= 'A') and (KeyChar <= 'Z') then
            begin
              if not (ShiftPressed xor CapsLockState) then
                KeyChar := Chr(Ord(KeyChar) + 32);
            end;
            Result := Ord(KeyChar);
          end;
        end
        else
        begin
          if AltPressed then
            Result := $FE00 or KeyCode
          else
            Result := $FF00 or KeyCode;
        end;
      end;
    end;
  end;
end;
{$ENDIF}

{$IFDEF LINUX}
uses
  BaseUnix, Unix, termio;

function KeyPressed: Boolean;
var
  OldTermios, NewTermios: termios;
  Fds: TFDSet;
  Timeout: TTimeVal;
begin
  Result := False;

  fpIOCtl(TextRec(Input).Handle, TCGETS, @OldTermios);
  NewTermios := OldTermios;

  cfmakeraw(NewTermios);
  fpIOCtl(TextRec(Input).Handle, TCSETS, @NewTermios);

  try
    fpFD_ZERO(Fds);
    fpFD_SET(TextRec(Input).Handle, Fds);

    Timeout.tv_sec := 0;
    Timeout.tv_usec := 100000;

    if fpSelect(TextRec(Input).Handle + 1, @Fds, nil, nil, @Timeout) > 0 then
      Result := True;
  finally
    fpIOCtl(TextRec(Input).Handle, TCSETS, @OldTermios);
  end;
end;

function ReadKeyboard: Integer;
var
  OldTermios, NewTermios: termios;
  Buffer: array[0..6] of Byte;
  BytesRead: LongInt;
  i:integer;
begin
  Result := 0;

  fpIOCtl(TextRec(Input).Handle, TCGETS, @OldTermios);
  NewTermios := OldTermios;

  cfmakeraw(NewTermios);
  fpIOCtl(TextRec(Input).Handle, TCSETS, @NewTermios);

  try
    FillChar(Buffer, SizeOf(Buffer), 0);
    BytesRead := fpRead(TextRec(Input).Handle, Buffer, SizeOf(Buffer));
    if BytesRead > 0 then
    begin
      if BytesRead=1 then
      begin
        if Buffer[0]=$7F then
          Result:=vkBack
        else
          Result := Ord(Buffer[0]);
      end
      else
      begin
        if Buffer[0]=$1B then
        begin
          Case Buffer[1] of
            $4F:
            begin
              case Buffer[2] of
                $50:Result:=vkF1;
                $51:Result:=vkF2;
                $52:Result:=vkF3;
                $53:Result:=vkF4;
              end;
            end;
            $5B:
            begin
              Case Buffer[2] of
                $41:Result:=vkUp;
                $42:Result:=vkDown;
                $43:Result:=vkRight;
                $44:Result:=vkLeft;
                $35:Result:=vkPageUp;
                $36:Result:=vkPageDown;
                $48:Result:=vkHome;
                $46:Result:=vkEnd;
                $32:Result:=vkIns;
                $33:Result:=vkDelete;
                $31:
                begin
                  Case Buffer[3] of
                    $35:Result:=vkF5;
                    $37:Result:=vkF6;
                    $38:Result:=vkF7;
                    $39:Result:=vkF8;
                  end;
                end;
                $39:
                begin
                  Case Buffer[3] of
                    $30:Result:=vkF9;
                    $31:Result:=vkF10;
//??                    $32:Result:=vkF11;
                    $34:Result:=vkF12;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    fpIOCtl(TextRec(Input).Handle, TCSETS, @OldTermios);
  end;
end;

{$ENDIF}

function IsKeyInSet(key: integer; const Keys: TKeysArray): boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to High(Keys) do
  begin
    if key = Keys[i] then
      Exit(True);
  end;
end;


initialization
  {$IFDEF WINDOWS}
    StdIn:=0;
  {$ENDIF}
end.
