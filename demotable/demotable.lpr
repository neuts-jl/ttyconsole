program demotable;
uses
  crt,classes;

var
  Table:TCsvCrtTable;
  Size:TPoint;
begin
  Size:=GetConsoleSize;
  Table:=TCsvCrtTable.Create;
  Table.LoadFromString(
  'Nom,Prénom,Age,Adresse'+#10+
  'Dupond,André,12,4 rue de l''espoir'+#10+
  'Durant,Jules,34,14 rue de la liberté'+#10+
  'Macaon,Robert,21,14 rue watteau'+#10+
  'Lecomte,Julie,28,45 rue poussin');
  Table.WidthMin:=Size.x-1;
  Table.DisplayMode:=dmNone;
  Table.DisplayTable;
  Table.DisplayMode:=dmPartialTable;
  Table.DisplayTable;
  Table.DisplayMode:=dmTable;
  Table.DisplayTable;
  readln;
{
  clrscr;
  Table.DisplayMode:=dmPartialTable;
  Table.WidthMin:=Size.x-1;
  Table.DisplayTable;
  Table.LoadFromFile('process.csv');
  Table.DisplayTable;
  readln;
 }
  Table.Free;
end.


