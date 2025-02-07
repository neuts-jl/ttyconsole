{
  *****************************************************************************
   Unit        : uttyansi
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 01/02/2025

   Description : This unit replaces the use of CRT, it uses ANSI sequences
                 compatible  on most consoles. CRT disrupts the display of
                 external shells. CRT should not be included and should be
                 favored or/and enriched with features


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

unit uttyansi;

{$mode ObjFPC}{$H+}

interface

uses
  classes, SysUtils;

const
  Black        = 0;
  Red          = 1;
  Green        = 2;
  Yellow       = 3;
  Blue         = 4;
  Magenta      = 5;
  Cyan         = 6;
  White        = 7;
  Gray         = 8;
  LightRed     = 9;
  LightGreen   = 10;
  LightYellow  = 11;
  LightBlue    = 12;
  LightMagenta = 13;
  LightCyan    = 14;
  LightWhite   = 15;

procedure ClrScr;
procedure ClrScr(x1, y1, x2, y2:integer);overload;
procedure ClrEol;
procedure ClrBol;
procedure ClrLine;
procedure ClrLine(y,x1,x2:integer);overload;
procedure ClrEos;
procedure ClrBos;
procedure GotoHome;
procedure GotoXY(x, y:integer);
procedure CursorOff;
procedure CursorOn;
procedure CursorBlocFix;
procedure CursorBloc;
procedure CursorNorm;
procedure TextBackground(Color: Integer);
procedure TextColor(Color: Integer);
procedure InvVideo;
procedure NormVideo;
procedure HighVideo;
procedure LowVideo;


implementation
uses
  {$IFDEF LINUX}
    BaseUnix, Termio;
  {$ENDIF}
  {$IFDEF WINDOWS}
    Windows;
  {$ENDIF}

procedure ClrScr;
begin
  Write(#27'[2J' + #27'[H');
end;

procedure ClrScr(x1, y1, x2, y2:integer);
var
  y:integer;
begin
  for y:=y1 to y2 do
    ClrLine(y,x1,x2);
end;

procedure ClrEol;
begin
  Write(#27'[0K');
end;

procedure ClrBol;
begin
  Write(#27'[1K');
end;

procedure ClrLine;
begin
  Write(#27'[2K');
end;

procedure ClrLine(y,x1,x2:integer);
begin
  Write(#27'[', y, ';', x1, 'H', #27'[', x2 - x1, 'X');
end;


procedure ClrEos;
begin
  Write(#27'[0J');
end;

procedure ClrBos;
begin
  Write(#27'[1J');
end;

procedure GotoHome;
begin
  Write(#27'[H');
end;

procedure GotoXY(x, y:integer);
begin
  Write(#27'[', y, ';', x, 'H');
end;

procedure CursorOff;
begin
  Write(#27'[?25l')
end;

procedure CursorOn;
begin
  Write(#27'[?25h')
end;

procedure CursorBlocFix;
begin
  CursorOn;
  Write(#27'[2 q');
end;

procedure CursorBloc;
begin
  CursorOn;
  Write(#27'[1 q');
end;

procedure CursorNorm;
begin
  CursorOn;
  Write(#27'[3 q');
end;

procedure TextColor(Color: Integer);
begin
  Write(#27'[38;5;' + IntToStr(Color) + 'm');
end;

procedure TextBackground(Color: Integer);
begin
  Write(#27'[48;5;' + IntToStr(Color) + 'm');
end;

procedure InvVideo;
begin
  Write(#27'[7m');
end;

procedure NormVideo;
begin
  Write(#27'[0m');
end;

procedure HighVideo;
begin
  Write(#27'[1m');
end;

procedure LowVideo;
begin
  Write(#27'[22m');
end;

{$IFDEF WINDOWS}
  procedure EnableANSI;
  var
    ConsoleHandle: THandle;
    Mode: DWORD;
  begin
    ConsoleHandle := GetStdHandle(STD_OUTPUT_HANDLE);
    if ConsoleHandle = INVALID_HANDLE_VALUE then
      Exit;
    if not GetConsoleMode(ConsoleHandle, Mode) then
      Exit;
    Mode := Mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    SetConsoleMode(ConsoleHandle, Mode);
  end;
{$ENDIF}

begin
  {$IFDEF WINDOWS}
    EnableANSI;
  {$ENDIF}
end.


