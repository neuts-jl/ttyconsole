{
  *****************************************************************************
   Unit        : uttytable
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 01/02/2025

   Description : This unit converts and displays csv tables into text tables
                 based on the uttyansi unit in ANSI sequences.

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

unit ucsvttytable;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, Math;

type
  TDisplayMode=(dmNone,dmTable,dmPartialTable);
  TDisplayOption=(doHeader,doTopLine,doBotLine,doHeadLine,doVertLine,doVertLineExt);
  TDisplayOptions=set of TDisplayOption;
  TCsvTTYTable = class
  private
    FHeaders: TStringList;
    FData: TStringList;
    FOutputList: TStringList;
    procedure BuildHeaders;
    procedure BuildTable;
    procedure SetHeaderWidth(Index,Len:integer);
    function GetHeaderWidth(Index:integer):integer;
  public
    WidthMin:integer;
    DisplayMode:TDisplayMode;
    DisplayOptions:TDisplayOptions;
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromStringList(const DataList: TStringList);
    procedure LoadFromString(const Data: string);
    procedure LoadFromFile(const FileName: string);
    procedure DisplayTable;
    procedure GetOutputList(var OutputList: TStringList);
    function GetOutputString: string;
  end;


implementation

constructor TCsvTTYTable.Create;
begin
  inherited Create;
  FHeaders := TStringList.Create;
  FData := TStringList.Create;
  FOutputList := TStringList.Create;
  DisplayMode:=dmTable;
  WidthMin:=0;
end;

destructor TCsvTTYTable.Destroy;
begin
  FHeaders.Free;
  FData.Free;
  FOutputList.Free;
  inherited Destroy;
end;

procedure TCsvTTYTable.SetHeaderWidth(Index,Len:integer);
begin
  {$H-}
    FHeaders.Objects[Index] := TObject(Pointer(Len));
  {$H+}
end;

function TCsvTTYTable.GetHeaderWidth(Index:integer):integer;
begin
  {$H-}
    Result:=Integer(Pointer(FHeaders.Objects[Index]));
  {$H+}
end;

procedure TCsvTTYTable.BuildHeaders;
var
  i:integer;
begin
  FHeaders.Delimiter := ',';
  FHeaders.StrictDelimiter := True;
  FHeaders.DelimitedText := FData[0];
  FData.Delete(0);
end;

procedure TCsvTTYTable.LoadFromStringList(const DataList: TStringList);
begin
  FData.Assign(DataList);
  BuildHeaders;
end;

procedure TCsvTTYTable.LoadFromString(const Data: string);
begin
  FData.Text := Data;
  BuildHeaders;
end;

procedure TCsvTTYTable.LoadFromFile(const FileName: string);
begin
  FData.LoadFromFile(FileName);
  BuildHeaders;
end;


procedure TCsvTTYTable.BuildTable;
  procedure CalculateColumnWidths;
  var
    i, j: Integer;
    Parts: TStringList;
  begin
    For i:=0 to FHeaders.Count-1 do
      SetHeaderWidth(i,Length(FHeaders[i]));
    for i := 0 to FData.Count - 1 do
    begin
      Parts := TStringList.Create;
      try
        Parts.Delimiter := ',';
        Parts.StrictDelimiter := True;
        Parts.DelimitedText := FData[i];
        for j := 0 to Parts.Count - 1 do
          if j<FHeaders.Count then
            SetHeaderWidth(j, Max(GetHeaderWidth(j), Length(Parts[j])));
      finally
        Parts.Free;
      end;
    end;
  end;

  procedure CalulateLastColumnWidth;
  var
    w,i,Offset:integer;
  begin
    w:=0;
    for i := 0 to FHeaders.Count - 1 do
      inc(w,GetHeaderWidth(i)+1);
    if WidthMin>w then
    begin
      i:=FHeaders.Count-1;
      if DisplayMode=dmTable then
        Offset:=-1
      else
        Offset:=1;
      w:=GetHeaderWidth(i)+(WidthMin-w)+Offset;
      SetHeaderWidth(i,w);
    end;
  end;

  procedure BuildHLine;
  var
    i: integer;
    Line: string;
  begin
    if DisplayMode = dmTable then
      Line := '+'
    else
      Line := '';
    for i := 0 to FHeaders.Count - 1 do
    begin
      Line := Line + StringOfChar('-', GetHeaderWidth(i));
      if (i < FHeaders.Count - 1) or (DisplayMode = dmTable) then
        Line := Line + '+';
    end;
    FOutputList.Add(Line);
  end;

var
  i, j: Integer;
  Line, Sep: string;
  Parts: TStringList;
begin
  FOutputList.Clear;

  CalculateColumnWidths;
  CalulateLastColumnWidth;

  if DisplayMode in [dmTable, dmPartialTable] then
    Sep := '|'
  else
    Sep := ' ';

  if DisplayMode = dmTable then
    BuildHLine;

  if DisplayMode=dmTable then
    Line := Sep
  else
    Line := '';
  for i := 0 to FHeaders.Count - 1 do
  begin
    Line := Line + Format('%-*s', [GetHeaderWidth(i), FHeaders[i]]);
    if (i < FHeaders.Count - 1) or (DisplayMode = dmTable) then
      Line := Line + Sep;
  end;
  FOutputList.Add(Line);
  if DisplayMode <> dmNone then
    BuildHLine;

  for i := 0 to FData.Count - 1 do
  begin
    Parts := TStringList.Create;
    try
      Parts.Delimiter := ',';
      Parts.StrictDelimiter := True;
      Parts.DelimitedText := FData[i];
      Line := '';
      if DisplayMode = dmTable then
        Line := '|';
      for j := 0 to Parts.Count - 1 do
      begin
        if j < FHeaders.Count then
        begin
          Line := Line + Format('%-*s', [GetHeaderWidth(j), Parts[j]]);
          if (j < FHeaders.Count - 1) or (DisplayMode = dmTable) then
            Line := Line + Sep;
        end;
      end;
      FOutputList.Add(Line);
    finally
      Parts.Free;
    end;
  end;

  if DisplayMode in [dmTable, dmPartialTable] then
    BuildHLine;
end;


procedure TCsvTTYTable.DisplayTable;
begin
  BuildTable;
  WriteLn(FOutputList.Text);
end;

procedure TCsvTTYTable.GetOutputList(var OutputList: TStringList);
begin
  BuildTable;
  OutputList.Assign(FOutputList);
end;

function TCsvTTYTable.GetOutputString: string;
begin
  BuildTable;
  Result := FOutputList.Text;
end;


end.

