{
  *****************************************************************************
   Unit        : uttyeditfields
   Author      : NEUTS JL
   License     : GPL (GNU General Public License)
   Date        : 01/02/2025

   Description : This unit handles editing of form fields
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
unit uttyeditfields;

{$mode objfpc}{$H+}
{$notes off}

interface

uses
  Classes, SysUtils, fgl, uttykeyboard, uttyconsole, uttyansi;

type
  TFieldType=(ftString,ftBoolean,ftInteger,ftFloat,ftDate,ftCurrency);

  TFieldEdit=Class
  public
    Col,Row:integer;
    Name:string;
    FieldType:TFieldType;
    Value:string;
    Size:integer;
    Precision:integer;
    Modified:boolean;
    ReadOnly:boolean;
    Constructor Create;
    procedure Assign(AValue:TFieldEdit);
  end;
  TFieldsEdit=specialize TFPGList<TFieldEdit>;

  TFieldsEditor=class
    private
      FFields:TFieldsEdit;
      FFieldIndex:integer;
      FInverseVideo:boolean;
      FInsertionMode:boolean;
      FExitKeys:TKeysArray;
      function ValueStr(AValue:string;ALen:integer):string;
    public
      Constructor Create;
      Destructor Destroy;override;
      procedure PrintField(FieldEdit:TFieldEdit;InverseVideo:boolean);
      procedure PrintFields;
      function Edit:integer;
      property Fields:TFieldsEdit read FFields write FFields;
      property FieldIndex:integer read FFieldIndex write FFieldIndex;
      property InverseVideo:boolean read FInverseVideo write FInverseVideo;
      property InsertionMode:boolean read FInsertionMode write FInsertionMode;
      property ExitKeys:TKeysArray read FExitKeys write FExitKeys;
    end;


implementation
uses
  math;

Constructor TFieldEdit.Create;
begin
  inherited;
  Col:=1;
  Row:=1;
  Name:='';
  FieldType:=ftString;
  Value:='';
  Size:=2;
  Precision:=0;
  Modified:=False;
  ReadOnly:=False;
end;

procedure TFieldEdit.Assign(AValue:TFieldEdit);
begin
  Col:=AValue.Col;
  Row:=AValue.Row;
  Name:=AValue.Name;
  FieldType:=AValue.FieldType;
  Value:=AValue.Value;
  Size:=AValue.Size;
  Precision:=AValue.Precision;
  Modified:=AValue.Modified;
  ReadOnly:=AValue.ReadOnly;
end;

Constructor TFieldsEditor.Create;
begin
  inherited;
  FFields:=TFieldsEdit.Create;
  FFieldIndex:=0;
  FInverseVideo:=False;
  FInsertionMode:=True;
  FExitKeys:=[];
end;

Destructor TFieldsEditor.Destroy;
begin
  FFields.Free;
  inherited;
end;

function TFieldsEditor.ValueStr(AValue:string;ALen:integer):string;
begin
  Result:=AValue;
  while length(Result)<Alen do
    Result:=Result+' ';
  Result:=Copy(Result,1,ALen);
end;

procedure TFieldsEditor.PrintField(FieldEdit:TFieldEdit;InverseVideo:boolean);
var
  F1,F2:string;
begin
  with FieldEdit do
  begin
    if InverseVideo then
      InvVideo;
    gotoXY(Col,Row);
    if Size<1 then
      Size:=1;
    case FieldType of
      ftInteger:
        Value:=Format('%'+IntToStr(Size)+'d',[StrToIntDef(Trim(Value),0)]);
      ftFloat:
      begin
        F1:='';
        while length(F1)<Size-Precision do
          F1:=F1+'#';
        F2:='';
        while length(F2)<Precision do
          F2:=F2+'0';
        Value:=FormatFloat(F1+'0.'+F2,StrToFloatDef(Trim(Value),0));
        while length(Value)<Size do
          Value:=' '+Value;
      end
      else
        Value:=ValueStr(Value,Size);
    end;
    write(Value);
    if InverseVideo then
      NormVideo;
  end;
end;

procedure TFieldsEditor.PrintFields;
var
  i:integer;
begin
  CursorOff;
  for i:=0 to FFields.Count-1 do
  begin
    PrintField(FFields[i],FInverseVideo);
    FFields[i].Modified:=False;
  end;
  CursorOn;
end;

function TFieldsEditor.Edit:integer;
var
  Done, Init, OldInsertionMode:boolean;
  CarIndex:integer;
  OValue:string;

  procedure DoKeys;
  var
    Key:integer;
  begin
    Key:=ReadKeyboard;
    if IsKeyInSet(Key, FExitKeys) then
    begin
      Result:=Key;
      Done:=True;
      Exit;
    end;
    with FFields[FFieldIndex] do
    begin
      case Key of
        vkHome:
          CarIndex:=0;
        vkEnd:
          CarIndex:=Length(Trim(Value));
        vkDown:
          if FFieldIndex<FFields.Count-1 then
          begin
            Inc(FFieldIndex);
            CarIndex:=0;
          end;
        vkUp:
          if FFieldIndex>0 then
          begin
            Dec(FFieldIndex);
            CarIndex:=0;
          end;
        vkRight:
          begin
            if CarIndex<Size-1 then
              inc(CarIndex)
          end;
        vkLeft:
          if CarIndex>0 then
            Dec(CarIndex);
        vkDelete:
        if Not ReadOnly then
        begin
          Delete(Value,CarIndex+1,1);
          Modified:=True;
        end;
        vkIns:
          InsertionMode:=not InsertionMode;
        vkTab:
          begin
            if FFieldIndex<FFields.Count-1 then
              Inc(FFieldIndex)
            else
              FFieldIndex:=0;
            CarIndex:=0;
          end;
        vkShiftTab:
          begin
            if FFieldIndex>0 then
              Dec(FFieldIndex)
            else
              FFieldIndex:=FFields.Count-1;
            CarIndex:=0;
          end;
        vkBack:
        begin
          if Not ReadOnly and (CarIndex>0) then
          begin
            Delete(Value,CarIndex,1);
            Dec(CarIndex);
            Modified:=True;
          end;
        end;
        else
        begin
          if  (CarIndex<Size)
          and (Key<$FF00)
          and not ReadOnly
          and
          (
              ((chr(Key) in ['0'..'9'])     and (FieldType in [ftInteger]))
            or
              ((chr(Key) in ['0'..'9','.']) and (FieldType in [ftFloat,ftCurrency] ))
            or
              ((chr(Key) in ['0'..'9','/']) and (FieldType in [ftDate]))
            or
              ((chr(Key) in [' '..'z'])     and (FieldType in [ftString]))
          ) then
          begin
            inc(CarIndex);
            if InsertionMode then
              Insert(chr(Key),Value,CarIndex)
            else
              Value[CarIndex]:=chr(Key);
            Modified:=True;
          end;
        end;
      end;
    end;
  end;

begin
  Init:=True;
  Done:=False;
  CarIndex:=0;
  OValue:='';
  PrintFields;
  if (FFieldIndex<0) or (FFieldIndex>FFields.Count) then
    FFieldIndex:=0;
  if FInverseVideo then
    InvVideo;
  if FInsertionMode then
    CursorNorm
  else
    CursorBloc;
  OldInsertionMode:=FInsertionMode;

  while not Done do
  begin
    with FFields[FFieldIndex] do
    begin
      if Init then
      begin
        CarIndex:=Length(TrimRight(Value));
        Init:=False;
      end;
      if CarIndex>Size-1 then
        CarIndex:=Size-1;
      if OValue<>Value then
      begin
        Value:=ValueStr(Value,Size);
        OValue:=Value;
        CursorOff;
        GotoXY(Col,Row);
        write(Value);
        CursorOn;
      end;
      GotoXY(Col+CarIndex,Row);
      if FInsertionMode<>OldInsertionMode then
      begin
        OldInsertionMode:=InsertionMode;
        if FInsertionMode then
          CursorNorm
        else
          CursorBloc;
      end;
      DoKeys;
    end;
  end;
  if FInverseVideo then
    NormVideo;
end;

end.


