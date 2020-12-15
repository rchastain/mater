
uses
  SysUtils, Classes, MaterCore;

{$ASSERTIONS ON}

function Solve(const AIndex: integer; const AEpd: string; const ADepth: integer; const AMode: TSearchMode): string;
const
  CFmtStr = 'index=%0.3d time=%s depth=%d mode=%d solution=%s';
var
  LTime: cardinal;
  LTimeStr: string;
begin
  LTime := GetTickCount64;
  result := SolveMate(AEpd, ADepth, AMode);
  LTime := GetTickCount64 - LTime;
  LTimeStr := FormatDateTime('hh:nn:ss:zzz', LTime / (1000 * SECSPERDAY));
  WriteLn(Format(CFmtStr, [AIndex, LTimeStr, ADepth, Ord(AMode), result]));
end;

const
  CFileName = 'problems.csv';

var
  LFileName: string;
  LFile, LLine: TStringList;  
  LEpd: string;
  LDepth: integer;
  LMode: TSearchMode;
  LMove: string;
  i: integer;
  
begin
  if FileExists(ParamStr(1)) then
    LFileName := ParamStr(1)
  else
    LFileName := CFileName;
  LFile := TStringList.Create;
  LFile.LoadFromFile(LFileName);
  LLine := TStringList.Create;
  LLine.Delimiter := ',';
  LLine.StrictDelimiter := TRUE;
  for i:= 0 to Pred(LFile.Count) do
  begin
    LLine.DelimitedText := LFile.Strings[i];
    Assert(LLine.Count = 3);
    LEpd := LLine.Strings[2];
    LDepth := StrToInt(LLine.Strings[0]);
    LMode := TSearchMode(StrToInt(LLine.Strings[1]));
    LMove := Solve(Succ(i), LEpd, LDepth, LMode);
    LLine.Append(LMove);
    LFile.Strings[i] := LLine.DelimitedText;
  end;
  LFile.SaveToFile('solutions.csv');
  LFile.Free;
  LLine.Free;
end.
