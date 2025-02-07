Program demolist;
uses
  SysUtils, Classes, uttyansi, uttykeyboard, uttylist;

var
  Viewer:TListViewer;
  Key, i: Integer;
begin
  ClrScr;

  Viewer:=TListViewer.Create;
  try
    for i := 0 to 100 do
      Viewer.List.Add('Option ' + IntToStr(i));

    Viewer.x1:=5;
    Viewer.y1:=5;
    Viewer.x2:=50;
    Viewer.y2:=20;
    Viewer.SelectedIndex:=50;
    Viewer.ExitKeys:=[vkEscape, vkReturn];
    Key:=Viewer.Show;

    gotoxy(1,25);
    if Viewer.SelectedIndex >= 0 then
      WriteLn('You have selected: ', Viewer.List[Viewer.SelectedIndex])
    else
      WriteLn('No selection');
    gotoxy(40,25);
    writeln('Key = '+IntToHex(Key,4));
  finally
    Viewer.Free;
  end;

  ReadLn;
end.

