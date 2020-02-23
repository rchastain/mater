
uses
  SysUtils, MaterCore, CommandLine;

procedure Log(const ALine: string; const ARewrite: boolean = FALSE);
var
  LFilename: TFilename;
  LFile: TextFile;
begin
  LFilename := ChangeFileExt({$I %FILE%}, '.log');
  Assign(LFile, LFilename);
  if ARewrite or not FileExists(LFileName) then
    Rewrite(LFile)
  else
    Append(LFile);
  WriteLn(LFile, ALine);
  Close(LFile);
end;

var
  LEpd: string;
  LDepth: integer;
  LCheck: boolean;
  LNeedHelp: boolean;
  LResult: string;
  
begin
  WriteLn('MATER Mate searching program v1.1 (c) Valentin Albillo 1998');
  
  LEpd := '';
  LDepth := 0;
  LCheck := FALSE;
  LNeedHelp := FALSE;
  if HasOption('p', 'position') then
    LEpd := GetOptionValue('p', 'position')
  else
    LNeedHelp := TRUE;
  if HasOption('m', 'moves') then
    LDepth := StrToIntDef(GetOptionValue('m', 'moves'), 0)
  else
    LNeedHelp := TRUE;
  if HasOption('c', 'check') then
    LCheck := TRUE;
  
  if LNeedHelp then
    WriteLn(Concat(
      'Usage', LineEnding,
      '  mater -position {<epd>} -moves <number> [-check]', LineEnding,
      '  mater -p {<epd>} -m <number> [-c]'
    ))
  else
  begin
    LResult := SolveMate(LEpd, LDepth, LCheck);;
    WriteLn('Result: ', LResult);
  end;
end.
