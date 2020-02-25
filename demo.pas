
uses
  SysUtils, MaterCore;

procedure Test(const AExpectedResult, AEpd: string; const ADepth: integer; const ASearchMode: TSearchMode = smAllMoves);
var
  LResult: string;
begin
  LResult := SolveMate(AEpd, ADepth, ASearchMode);
  if LResult <> AExpectedResult then
    WriteLn('Unexpected result: "', LResult, '"');
end;

begin
  Test('b7a8n', 'b7/PP6/8/8/7K/6B1/6N1/4R1bk w KQkq -', 3);
  Test('h6c1', '8/8/1p5B/4p3/1p2k1P1/1P3n2/P4PB1/K2R4 w KQkq -', 3);
  Test('d6c7', '2N5/8/k2K4/8/p1PB4/P7/8/8 w KQkq -', 4);
  Test('f6d5', 'rnbK2R1/p6p/p1kNpN1r/P3B1Q1/3P1p1p/5p2/5p1b/8 w KQkq -', 4);
  Test('h7g7', '8/1n2P2K/3p2p1/2p3pk/6pr/4ppr1/6p1/1b6 w KQkq -', 3);
  Test('b7b8r', '4K1R1/PP2P3/2k5/3pP3/3B4/6P1/8/8 w KQkq -', 3);
  Test('e7e8b', '8/2P1P1P1/3PkP2/8/4K3/8/8/8 w Qkq -', 3);
  Test('h3g5', '3nn3/2p2p1k/1p1pp1p1/p2B3p/r2B2N1/7N/8/7K w KQkq -', 12, smChecks);
end.
