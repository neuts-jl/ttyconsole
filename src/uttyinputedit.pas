{
  *****************************************************************************
   Unit        : uttyinputedit
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 20/02/2025

   Description : Line input editor in console mode

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

unit uttyinputedit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uttyansi, uttykeyboard;

procedure InputEdit(var Input: string; History: TStringList;
  const x: integer = 1; const Size: integer = 80); overload;
procedure InputEdit(var Input: string; const x: integer = 1; const Size: integer = 80);

implementation

procedure InputEdit(var Input: string; History: TStringList;
  const x: integer = 1; const Size: integer = 80);
var
  Key: integer;
  CursorPos: integer;
  HistoryIndex: integer;
  InsertMode: boolean;

  procedure Locate(Col: integer);
  begin
    gotoX(Col + x - 1);
  end;

  procedure DisplayInput;
  begin
    CursorOff;
    Locate(1);
    Write(Input);
    Write(StringOfChar(' ', Size - Length(Input)));
    Locate(CursorPos);
    CursorOn;
  end;

begin
  CursorPos := Length(Input) + 1;
  HistoryIndex := History.Count;
  InsertMode := True;
  CursorNorm;
  DisplayInput;
  repeat
    Key := ReadKeyboard;
    case Key of
      vkLeft:
        if CursorPos > 1 then
        begin
          Dec(CursorPos);
          Locate(CursorPos);
        end;

      vkRight:
        if CursorPos <= Length(Input) then
        begin
          Inc(CursorPos);
          Locate(CursorPos);
        end;

      vkUp:
        if HistoryIndex > 0 then
        begin
          Dec(HistoryIndex);
          Input := History[HistoryIndex];
          CursorPos := Length(Input) + 1;
          DisplayInput;
        end;

      vkDown:
        if HistoryIndex < History.Count - 1 then
        begin
          Inc(HistoryIndex);
          Input := History[HistoryIndex];
          CursorPos := Length(Input) + 1;
          DisplayInput;
        end
        else if HistoryIndex = History.Count - 1 then
        begin
          HistoryIndex := History.Count;
          Input := '';
          CursorPos := 1;
          DisplayInput;
        end;

      vkDelete:
        if (CursorPos <= Length(Input)) and (Length(Input) > 0) then
        begin
          Delete(Input, CursorPos, 1);
          DisplayInput;
        end;

      vkBack:
        if CursorPos > 1 then
        begin
          Delete(Input, CursorPos - 1, 1);
          Dec(CursorPos);
          DisplayInput;
        end;

      vkIns:
      begin
        InsertMode := not InsertMode;
        DisplayInput;
        if InsertMode then
          CursorNorm
        else
          CursorBloc;
      end;

      vkReturn:
      begin
        if Input <> '' then
          History.Add(Input);
        Exit;
      end;

      else
        if (Key >= 32) and (Key <= 126) and (Length(Input) <= Size) then
        begin
          if InsertMode then
            Insert(Chr(Key), Input, CursorPos)
          else
          begin
            if CursorPos <= Length(Input) then
              Input[CursorPos] := Chr(Key)
            else
              Input := Input + Chr(Key);
          end;
          Inc(CursorPos);
          DisplayInput;
        end;
    end;
  until False;
end;

var
  History: TStringList;

procedure InputEdit(var Input: string; const x: integer = 1; const Size: integer = 80);
begin
  if History = nil then
    History := TStringList.Create;
  InputEdit(Input, History, x, Size);
end;

initialization
  History := nil;

finalization
  if History <> nil then
    History.Free;
end.
