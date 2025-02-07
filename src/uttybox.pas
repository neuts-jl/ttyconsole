{
  *****************************************************************************
   Unit        : uttybox
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 01/02/2025

   Description : This unit handles text mode box and line drawing,
                 based on the ttyconsole unit in ANSI sequences.

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
unit uttybox;

{$mode ObjFPC}{$H+}

interface
uses
  {$IFDEF WINDOWS}
    Windows,
  {$ENDIF}
  uttyansi, uttyconsole;

type
  TBorderStyle = (bsAscii, bsSimple, bsDouble);

procedure DrawHLine(x1, x2, y: Integer; style: TBorderStyle; connect: Boolean = False);
procedure DrawVLine(x, y1, y2: Integer; style: TBorderStyle; connect: Boolean = False);
procedure DrawIntersection(x, y: Integer; style: TBorderStyle);
procedure DrawBox(x1, y1, x2, y2: Integer; style: TBorderStyle);

procedure DrawHLine(x1, x2, y: Integer; connect: Boolean = False);overload;
procedure DrawVLine(x, y1, y2: Integer; connect: Boolean = False);overload;
procedure DrawIntersection(x, y: Integer);overload;
procedure DrawBox(x1, y1, x2, y2: Integer);overload;

var
  CurrentBorderStyle:TBorderStyle;

implementation
const
  BorderChars: array[TBorderStyle] of record
    HLine, VLine, TopLeft, TopRight, BottomLeft, BottomRight,
      MidTop, MidBottom, midLeft, midRight, Intersection: PChar;
  end =
  (
    (HLine: '-'; VLine: '|'; TopLeft: '+'; TopRight: '+'; BottomLeft: '+'; BottomRight: '+';
      MidTop:'+'; MidBottom:'+'; midLeft:'+'; midRight:'+'; Intersection:'+'),
    (HLine: '─'; VLine: '│'; TopLeft: '┌'; TopRight: '┐'; BottomLeft: '└'; BottomRight: '┘';
      MidTop:'┬'; MidBottom:'┴'; midLeft:'├'; midRight:'┤'; Intersection:'┼'),
    (HLine: '═'; VLine: '║'; TopLeft: '╔'; TopRight: '╗'; BottomLeft: '╚'; BottomRight: '╝';
      MidTop:'╦'; MidBottom:'╩'; midLeft:'╠'; midRight:'╣'; Intersection:'╬')
  );

procedure DrawHLine(x1, x2, y: Integer; style: TBorderStyle; connect: Boolean = False);
var
  i: Integer;
begin
  GotoXY(x1, y);
  for i := x1 to x2 do
  begin
    if connect and (i = x1) then
      Write(BorderChars[style].MidLeft)
    else if connect and (i = x2) then
      Write(BorderChars[style].MidRight)
    else
      Write(BorderChars[style].HLine);
  end;
end;

procedure DrawVLine(x, y1, y2: Integer; style: TBorderStyle; connect: Boolean = False);
var
  i: Integer;
begin
  for i := y1 to y2 do
  begin
    GotoXY(x, i);
    if connect and (i = y1) then
      Write(BorderChars[style].MidTop)
    else if connect and (i = y2) then
      Write(BorderChars[style].MidBottom)
    else
      Write(BorderChars[style].VLine);
  end;
end;

procedure DrawIntersection(x, y: Integer; style: TBorderStyle);
begin
  GotoXY(x,y);
  write(BorderChars[style].Intersection);
end;

procedure DrawBox(x1, y1, x2, y2: Integer; style: TBorderStyle);
begin
  GotoXY(x1, y1);
  Write(BorderChars[style].TopLeft);
  DrawHLine(x1 + 1, x2 - 1, y1, style);
  Write(BorderChars[style].TopRight);

  DrawVLine(x1, y1 + 1, y2 - 1, style);
  DrawVLine(x2, y1 + 1, y2 - 1, style);

  GotoXY(x1, y2);
  Write(BorderChars[style].BottomLeft);
  DrawHLine(x1 + 1, x2 - 1, y2, style);
  Write(BorderChars[style].BottomRight);
end;

procedure DrawHLine(x1, x2, y: Integer; connect: Boolean = False);
begin
  DrawHLine(x1, x2, y, CurrentBorderStyle, connect);
end;

procedure DrawVLine(x, y1, y2: Integer; connect: Boolean = False);
begin
  DrawVLine(x, y1, y2, CurrentBorderStyle, connect);
end;

procedure DrawIntersection(x, y: Integer);
begin
  DrawIntersection(x, y, CurrentBorderStyle);
end;

procedure DrawBox(x1, y1, x2, y2: Integer);
begin
  DrawBox(x1, y1, x2, y2, CurrentBorderStyle);
end;

begin
 {$IFDEF WINDOWS}
    SetConsoleOutputCP(65001);
 {$ENDIF}
 CurrentBorderStyle:=bsAscii;
end.

