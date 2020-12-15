
(*******************************************************************)
(*                                                                 *)
(*  MATER: Mate searching program - (c) Valentin Albillo 1998      *)
(*                                                                 *)
(*      This program or parts thereof can be used for any purpose  *)
(*  whatsoever as long as proper credit is given to the copyright  *)
(*  holder. Absolutely no guarantees given, no liabilities of any  *)
(*  kind accepted. Use at your own risk.  Your using this code in  *)
(*  all or in part does indicate your acceptance of these terms.   *)
(*                                                                 *)
(*******************************************************************)

program Mater;

uses
  SysUtils, MaterCore, CommandLine;

var
  LEpd: string;
  LDepth: integer;
  LMode: TSearchMode;
  LNeedHelp: boolean;
  LResult: string;
  LResultDepth: integer;
  
begin
  LEpd := '';
  LDepth := 0;
  LMode := smAllMoves;
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
    LMode := smChecks;
  
  if LNeedHelp then
    WriteLn(Concat(
      'Usage', LineEnding,
      '  mater -position "<epd>" -moves <number> [-check]', LineEnding,
      '  mater -p "<epd>" -m <number> [-c]'
    ))
  else
  begin
    LResult := SolveMate(LEpd, LDepth, LMode, LResultDepth);
    if LResult = '' then
      WriteLn('No mate found')
    else
      WriteLn(Format('Mate found in %d moves: %s', [LResultDepth, LResult]));
  end;
end.
