
unit CommandLine;

interface

function HasOption(const AShortName, ALongName: string): boolean;
function GetOptionValue(const AShortName, ALongName: string): string;

implementation

uses
  SysUtils, FLRE;

const
  CBefore = '.* ';
  CNameSymbol = '[-/]';
  CSeparator = ' |:|=';
  CAfter = ' .*';
  CQuotedValue = '"[^"]+"';
  CSimpleValue = '[^ ]+';

function GetCmdLine: string;
var
  i: integer;
  s: string;
begin
  result := ' ';
  for i:= 1 to ParamCount do
  begin
    s := ParamStr(i);
    if (Length(s) > 0) and (Pos(s[1], CNameSymbol) > 0) then
      result := Concat(result, s, ' ')
    else
      result := Concat(result, '"', s, '" ');
  end;
end; 

var
  LCmdLine: string;

function HasOption(const AShortName, ALongName: string): boolean;
var
  e: TFLRE;
  c: TFLRECaptures;
  s: TFLRERawByteString;
begin
  s := Concat(CBefore, CNameSymbol, '(', AShortName, '|', ALongName, ')((', CSeparator, ')', '(', CQuotedValue, '|', CSimpleValue, '))?', CAfter);
  e := TFLRE.Create(s, [rfIGNORECASE]);
  result := e.Match(LCmdLine, c);
  e.Free;
end;

function GetOptionValue(const AShortName, ALongName: string): string;
var
  e: TFLRE;
  c: TFLRECaptures;
  s: TFLRERawByteString;
begin
  s := Concat(CBefore, CNameSymbol, '(', AShortName, '|', ALongName, ')(', CSeparator, ')', '(', CQuotedValue, '|', CSimpleValue, ')', CAfter);
  e := TFLRE.Create(s, [rfIGNORECASE]);
  if e.Match(LCmdLine, c) then
  begin
    result := Copy(LCmdLine, c[3].Start, c[3].Length);
    if result[1] = '"' then
      result := Copy(result, 2, Length(result) - 2);
  end else
    result := '';
  e.Free;
end;

initialization
  LCmdLine := GetCmdLine;

finalization
  LCmdLine := '';

end.
