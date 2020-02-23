
unit CommandLine;

interface

function HasOption(const AShortName, ALongName: string): boolean;
function GetOptionValue(const AShortName, ALongName: string): string;

implementation

uses
  SysUtils, FLRE;

function GetCmdLine: string;
var
  i: integer;
begin
  result := ' ';
  for i:= 1 to ParamCount do
    result := Concat(result, ParamStr(i), ' ');
end;

const
  CBefore = '.* ';
  CNameSymbol = '[-/]';
  CSeparator = ' |:|=';
  CAfter = ' .*';
  CQuotedValue = '\{[^}]+\}';
  CSimpleValue = '[^ ]+'; 
  
function HasOption(const AShortName, ALongName: string): boolean;
var
  LCmdLine: string;
  e: TFLRE;
  c: TFLRECaptures;
  s: TFLRERawByteString;
begin
  LCmdLine := GetCmdLine;
  s := Concat(CBefore, CNameSymbol, '(', AShortName, '|', ALongName, ')((', CSeparator, ')', '(', CQuotedValue, '|', CSimpleValue, '))?', CAfter);
  e := TFLRE.Create(s, [rfIGNORECASE]);
  result := e.Match(LCmdLine, c);
  e.Free;
end;

function GetOptionValue(const AShortName, ALongName: string): string;
var
  LCmdLine: string;
  e: TFLRE;
  c: TFLRECaptures;
  s: TFLRERawByteString;
begin
  LCmdLine := GetCmdLine;
  s := Concat(CBefore, CNameSymbol, '(', AShortName, '|', ALongName, ')(', CSeparator, ')', '(', CQuotedValue, '|', CSimpleValue, ')', CAfter);
  e := TFLRE.Create(s, [rfIGNORECASE]);
  if e.Match(LCmdLine, c) then
  begin
    result := Copy(LCmdLine, c[3].Start, c[3].Length);
    if result[1] = '{' then
      result := Copy(result, 2, Length(result) - 2);
  end else
    result := '';
  e.Free;
end;
  
end.
