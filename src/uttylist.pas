{
  *****************************************************************************
   Unit        : uttyliste
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 01/02/2025

   Description : This unit displays the list in text mode. It integrates
                 keyboard shortcut management and filter
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
unit uttylist;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, uttykeyboard, uttyeditfields, uttyansi;

type
  TListViewer=Class
  private
    FList:TStringList;
    FX1:integer;
    FY1:integer;
    FX2:integer;
    FY2:integer;
    FShowFilter:boolean;
    FExitKeys: TKeysArray;
    FSelectedIndex: integer;
  public
    Constructor Create;
    Destructor Destroy;
    function Show:integer;
    property List:TStringList read FList write FList;
    property x1:integer read FX1 write FX1;
    property y1:integer read FY1 write FY1;
    property x2:integer read FX2 write FX2;
    property y2:integer read FY2 write FY2;
    property ShowFilter:boolean read FShowFilter write FShowFilter;
    property ExitKeys: TKeysArray read FExitKeys write FExitKeys;
    property SelectedIndex: integer read FSelectedIndex write FSelectedIndex;
  end;

implementation

constructor TListViewer.Create;
begin
  inherited;
  FList:=TSTringList.Create;
end;

destructor TListViewer.Destroy;
begin
  FList.Free;
  inherited;
end;

function TListViewer.Show:integer;
var
  StartIndex, OldStartIndex: integer;
  VisibleCount, PrevSelectedIndex, MaxLen: integer;
  FilterEditor:TFieldsEditor;
  sList:TStringList;
  oFilter:string;
  FilterVisible:boolean;

  procedure DrawItem(index, posY: integer; selected: boolean);
  begin
    if (posY <= FY2) and (posY >= FY1) then
    begin
      if selected then
        InvVideo
      else
        NormVideo;
      GotoXY(FX1, posY);
      if (index >= 0) and (index < FList.Count) then
        Write(Copy(FList[index] + StringOfChar(' ', MaxLen), 1, MaxLen))
      else
        Write(StringOfChar(' ', MaxLen));

      NormVideo;
    end;
  end;

  procedure ClearLine(yPos: integer);
  begin
    GotoXY(FX1, yPos);
    Write(StringOfChar(' ', MaxLen));
  end;

  procedure DrawList;
  var
    i, posY: integer;
  begin
    for i := 0 to VisibleCount - 1 do
    begin
      posY := FY1 + i;
      if (StartIndex + i < FList.Count) then
        DrawItem(StartIndex + i, posY, StartIndex + i = FSelectedIndex)
      else
        ClearLine(posY);
    end;
  end;

  procedure QuickSelect(Key:integer);
    function SelectLine(Car:char;Start:integer):boolean;
    var
      i:integer;
    begin
      Car:=UpperCase(Car)[1];
      for i := Start to FList.Count - 1 do
      begin
        if (UpperCase(Copy(FList[i], 1, 1)) = Car) and (i<>FSelectedIndex) then
        begin
          if FSelectedIndex-Visiblecount>i then
            StartIndex:=0
          else if i>VisibleCount then
            StartIndex:=i;
          FSelectedIndex := i;
          Exit(True);
        end;
      end;
      Result:=False;
  end;

  var
    Car:Char;
  begin
    if (Key>$FF00) then
      exit;
    Car:=Char(Key);
    if Car in ['a'..'z','A'..'Z','0'..'9','_'] then
    begin
      if SelectLine(Car,FSelectedIndex) then
        exit
      else
        SelectLine(Car,0);
    end;
  end;

  procedure InitFilter;
  var
    i:integer;
    Field:TFieldEdit;
  begin
    FilterVisible:=FShowFilter and (FList.Count>FY2 - FY1);
    if FilterVisible then
    begin
      for i:=0 to FList.Count-1 do
        FList.Objects[i]:=TObject(Pointer(i));
      oFilter:='';
      sList:=TStringList.Create;
      sList.Text:=FList.Text;
      FilterEditor:=TFieldsEditor.Create;
      Field:=TFieldEdit.Create;
      FilterEditor.ExitKeys:=Concat([vkUp,vkDown,vkHome,vkEnd,vkPageDown,vkPageup,vkReturn],FExitKeys);
      Field.Col:=FX1;
      Field.Row:=FY1;
      Field.Size:=FX2-FX1+1;
      Field.FieldType:=ftString;
      FilterEditor.Fields.Add(Field);
      inc(FY1);
    end;
  end;

  function GetKey:integer;
  var
    Key,i:integer;
    Filter:string;
  begin
    if Not FilterVisible then
      Key:=ReadKeyboard
    else
    begin
      Key:=FilterEditor.Edit;
      if Key=vkReturn then
      begin
        Filter:=LowerCase(Trim(FilterEditor.Fields[0].Value));
        if Filter<>oFilter then
        begin
          oFilter:=Filter;
          Key:=0;
          if Filter='' then
            FList.Text:=sList.Text
          else
          begin
            FList.Clear;
            for i:=0 to sList.Count-1 do
            begin
              if Pos(Filter,LowerCase(sList[i]))>0 then
                FList.AddObject(sList[i],TObject(Pointer(i)));
            end;
          end;
          FSelectedIndex := 0;
          StartIndex := 0;
          DrawList;
        end;
      end;
    end;
    Result:=Key;
  end;

  procedure EndFilter;
  begin
    if FilterVisible then
    begin
      if FList.Count>0 then
        FSelectedIndex:=Integer(Pointer(FList.Objects[FSelectedIndex]))
      else
        FSelectedIndex:=-1;
      FList.Text:=sList.Text;
      sList.Free;
      FilterEditor.Free;
    end;
  end;
var
  Key:integer;

begin
  InitFilter;
  Try
    MaxLen := Fx2 - Fx1 + 1;
    VisibleCount := Fy2 - Fy1 + 1;
    if FSelectedIndex < 0 then
      FSelectedIndex := 0;
    if FSelectedIndex > FList.Count - 1 then
      FSelectedIndex := FList.Count - 1;
    StartIndex := 0;
    OldStartIndex := 0;
    PrevSelectedIndex := -1;

    if FSelectedIndex >= VisibleCount then
      StartIndex := FSelectedIndex - VisibleCount + 1;

    CursorOff;
    DrawList;
    repeat
      if FSelectedIndex <> PrevSelectedIndex then
      begin
        if PrevSelectedIndex >= StartIndex then
          DrawItem(PrevSelectedIndex, Fy1 + (PrevSelectedIndex - StartIndex), False);
        if FSelectedIndex >= StartIndex then
          DrawItem(FSelectedIndex, Fy1 + (FSelectedIndex - StartIndex), True);
        if OldStartIndex <> StartIndex then
        begin
          DrawList;
          OldStartIndex := StartIndex;
        end;
        PrevSelectedIndex := FSelectedIndex;
      end;
      Key := GetKey;
      if IsKeyInSet(Key, FExitKeys) then
      begin
        Result := Key;
        break;
      end
      else
      begin
        case key of
          vkHome:
          begin
            FSelectedIndex := 0;
            StartIndex := 0;
          end;

          vkend:
          begin
            FSelectedIndex := FList.Count - 1;
            StartIndex := FList.Count - VisibleCount;
          end;

          vkUp:
            if FSelectedIndex > 0 then
            begin
              if FSelectedIndex < StartIndex + VisibleCount then
                DrawItem(FSelectedIndex, Fy1 + (FSelectedIndex - StartIndex), False);
              Dec(FSelectedIndex);
              if FSelectedIndex < StartIndex then
                Dec(StartIndex);
            end;

          vkDown:
            if FSelectedIndex < FList.Count - 1 then
            begin
              if (FSelectedIndex >= StartIndex) and (FSelectedIndex <
                StartIndex + VisibleCount) then
                DrawItem(FSelectedIndex, Fy1 + (FSelectedIndex - StartIndex), False);
              Inc(FSelectedIndex);
              if FSelectedIndex >= StartIndex + VisibleCount then
                Inc(StartIndex);
            end;

          vkPageUp:
            if StartIndex > 0 then
            begin
              Dec(StartIndex, VisibleCount);
              if FSelectedIndex >= VisibleCount then
                Dec(FSelectedIndex, VisibleCount)
              else
                FSelectedIndex := 0;
              if StartIndex < 0 then
              begin
                StartIndex := 0;
                FSelectedIndex := 0;
              end;
            end;

          vkPageDown:
            if StartIndex + VisibleCount < FList.Count then
            begin
              Inc(StartIndex, VisibleCount);
              if FSelectedIndex + VisibleCount < FList.Count then
                Inc(FSelectedIndex, VisibleCount)
              else
                FSelectedIndex := FList.Count - 1;
            end;
          else
            QuickSelect(Key);
        end;
      end;
    until False;
  finally
    EndFilter;
    CursorOn;
  end;
end;


end.
