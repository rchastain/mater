
(* MATER Mate searching program v1.1 (c) Valentin Albillo 1998 *)

uses
  SysUtils, MaterCore, CommandLine;

var
  LEpd: string;
  LDepth: integer;
  LSearchMode: TSearchMode;
  LNeedHelp: boolean;
  LResult: string;
  LResultDepth: integer;
  
begin
  LEpd := '';
  LDepth := 0;
  LSearchMode := smAllMoves;
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
    LSearchMode := smChecks;
  
  if LNeedHelp then
    WriteLn(Concat(
      'Usage', LineEnding,
      '  mater -position {<epd>} -moves <number> [-check]', LineEnding,
      '  mater -p {<epd>} -m <number> [-c]'
    ))
  else
  begin
    LResult := SolveMate(LEpd, LDepth, LSearchMode, LResultDepth);
    if LResult = '' then
      WriteLn('No mate found')
    else
      WriteLn(Format('Mate found in %d moves: %s', [LResultDepth, LResult]));
  end;
end.
