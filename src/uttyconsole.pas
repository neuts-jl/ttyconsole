{
  *****************************************************************************
   Unit        : uttyconsole
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 01/02/2025

   Description : Tools for tty console


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

unit uttyconsole;

{$mode ObjFPC}{$H+}

interface

uses
  classes, SysUtils;


procedure ClearConsole;
function  GetConsoleSize:TPoint;
procedure ValidBox(x1, y1, x2, y2: integer);

implementation
uses
  {$IFDEF LINUX}
    BaseUnix, Termio,
  {$ENDIF}
  {$IFDEF WINDOWS}
    Windows,
  {$ENDIF}
  process;


{$IFDEF WINDOWS}
  function GetConsoleSize:Tpoint;
  var
    ConsoleHandle: THandle;
    ConsoleScreenBufferInfo: TConsoleScreenBufferInfo;
  begin
    Result.X:=80;
    Result.Y:=25;
    ConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);
    if ConsoleHandle = INVALID_HANDLE_VALUE then
      exit;

    if not GetConsoleScreenBufferInfo(ConsoleHandle, ConsoleScreenBufferInfo) then
      exit;
    Result.X:=ConsoleScreenBufferInfo.dwSize.X;
    Result.Y:=ConsoleScreenBufferInfo.dwSize.Y;
  end;
{$ENDIF}

{$IFDEF LINUX}
  function GetConsoleSize: TPoint;
  var
    ws: TWinSize;
  begin
    if FpIoCtl(StdOutputHandle, TIOCGWINSZ, @ws) <> -1 then
    begin
      Result.X := ws.ws_col;
      Result.Y := ws.ws_row;
    end
    else
    begin
      Result.X:=80;
      Result.Y:=25;
    end;
  end;
{$ENDIF}

procedure ValidBox(x1, y1, x2, y2: integer);
var
  Size: Tpoint;
begin
  Size := GetConsoleSize;
  if (x1 < 0) or (y1 < 0) or (x2 > Size.X) or (y2 > Size.y) or
    (x1 >= x2) or (y1 >= y2) then
    raise(Exception.Create('Invalid coordinates'));
end;

procedure ClearConsole;
begin
  with TProcess.Create(nil) do
  begin
    try
      {%H-}
      {$IFDEF LINUX}
        CommandLine:='clear';
      {$ENDIF}
      {$IFDEF WINDOWS}
        CommandLine:='cmd.exe /c cls';
      {$ENDIF}
      {%H+}
      Options := [poWaitOnExit];
      Execute;
      Free;
    Except
    end;
  end;
end;

end.


