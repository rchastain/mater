
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

unit MaterCore;

interface

function SolveMate(
  const AFen: string;
  const AMovesNumber: integer;
  const ACheckOnly: boolean = FALSE
): string;

implementation

uses
  SysUtils, StrUtils;

const
  CMaxMoves = 200;
  CMaxPieces = 16;
  CBlank = 0;
  CPawn = 1;
  CKnight = 2;
  CBishop = 3;
  CRook = 4;
  CQueen = 5;
  CKing = 6;
  COut = 7;
  CWhite = 1;
  CBlack = -1;
  CNone = 0;
  CTop = 22;
  CBottom = 99;
  CCapture = -1;
  CAny = 1;
  CShortCastle = 6;
  CLongCastle = 7;
  CEnPassant = 8;
  CShortCastleValue = 50;
  CLongCastleValue = 30;

function PieceColor(const i: integer): integer;
begin
  if i = 0 then
    result := 0
  else if i < 0 then
    result := CBlack
  else
    result := CWhite;
end;

type
  TSquareSet = set of 1..120;
  TBooleanArray = array[CBlack..CWhite] of boolean;
  TSquareSetArray = array[CBlack..CWhite] of TSquareSet;

  TPosition = record
    FBoard: array[1..120] of integer;
    FActiveColor: boolean;
    FKingCastle: TBooleanArray;
    FQueenRookCastle: TBooleanArray;
    FKingRookCastle: TBooleanArray;
    FEnPassantSquare: integer;
  end;

  TMove = record
    FFrom,
    FTo,
    FClass,
    FValue: integer;
  end;

  TMoveArray = array[1..CMaxMoves] of TMove;
  TPieceArray = array[1..CMaxPieces] of integer;

  TAuxData = array[CBlack..CWhite] of record
    FKingSquare: integer;
    FPieceNumber: integer;
    FPieces: TPieceArray;
  end;

const
  CPawnValue = 100;
  CKnightValue = 300;
  CBishopValue = 300;
  CRookValue = 500;
  CQueenValue = 900;
  CKingValue = 9999;

  CPieceValue: array[CBlack * CKing..CWhite * CKing] of integer = (
    CKingValue, CQueenValue, CRookValue, CBishopValue, CKnightValue, CPawnValue, 0,
    CPawnValue, CKnightValue, CBishopValue, CRookValue, CQueenValue, CKingValue
  );

  CPawnVector:   array[1..3] of integer = (10, 9, 11);
  CKnightVector: array[1..8] of integer = (-21, -19, -12, -8, 8, 12, 19, 21);
  CBishopVector: array[1..4] of integer = (-11, -9, 9, 11);
  CRookVector:   array[1..4] of integer = (-10, -1, 1, 10);
  CQueenVector:  array[1..8] of integer = (-11, -10, -9, -1, 1, 9, 10, 11);
  CKingVector:   array[1..8] of integer = (-11, -10, -9, -1, 1, 9, 10, 11);

  CPromoSquares:     TSquareSetArray = ([CBottom - 7..CBottom], [], [CTop..CTop + 7]);
  CPawnSquares:      TSquareSetArray = ([32..39], [], [82..89]);
  CEnPassantSquares: TSquareSetArray = ([72..79], [], [42..49]);

  CQueenRookSquares: array[CBlack..CWhite] of integer = (CTop, CNone, CBottom - 7);
  CKingRookSquares:  array[CBlack..CWhite] of integer = (CTop + 7, CNone, CBottom);

function SquareToStr(const ASquare: integer): string;
begin
  result := Concat(
    Chr(ASquare mod 10 - 2 + Ord('a')),
    Chr(9 - ASquare div 10 + Ord('1'))
  );
end;

function StrToSquare(const AStr: string): integer;
begin
  result := 10 * (Ord(AStr[1]) - Ord('a') + 2) + Ord(AStr[2]) - Ord('1') + 2;
end;

function PosToStr(const APos: TPosition): string;
const
  CShape: array[CBlack * CKing..COut] of char = ('k', 'q', 'r', 'b', 'n', 'p', ' ', 'P', 'N', 'B', 'R', 'Q', 'K', '#');
  CArrow: array[boolean] of string = ('', '<---');
  CColor: array[boolean] of string = ('White', 'Black');
  CBoard =
    '    A   B   C   D   E   F   G   H  ' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '8 | %s | %s | %s | %s | %s | %s | %s | %s | %s' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '7 | %s | %s | %s | %s | %s | %s | %s | %s |' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '6 | %s | %s | %s | %s | %s | %s | %s | %s |' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '5 | %s | %s | %s | %s | %s | %s | %s | %s |' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '4 | %s | %s | %s | %s | %s | %s | %s | %s |' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '3 | %s | %s | %s | %s | %s | %s | %s | %s |' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '2 | %s | %s | %s | %s | %s | %s | %s | %s |' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '1 | %s | %s | %s | %s | %s | %s | %s | %s | %s' + LineEnding +
    '  +---+---+---+---+---+---+---+---+' + LineEnding +
    '' + LineEnding +
    '  * Side to move: %s' + LineEnding +
    '  * Castling rights: %s' + LineEnding +
    '  * En passant square: %s' + LineEnding;
var
  LCastlingState: string;
  LEnPassantState: string;
begin
  with APos do
  begin
    LCastlingState := IfThen(
      FKingRookCastle[CWhite] or FQueenRookCastle[CWhite] or FKingRookCastle[CBlack] or FQueenRookCastle[CBlack], 
      Concat(
        IfThen(FKingRookCastle[CWhite], 'K', ''),
        IfThen(FQueenRookCastle[CWhite], 'Q', ''),
        IfThen(FKingRookCastle[CBlack], 'k', ''),
        IfThen(FQueenRookCastle[CBlack], 'q', '')
      ),
      '-'
    );
    LEnPassantState := IfThen(FEnPassantSquare = CNone, '-', SquareToStr(FEnPassantSquare));
    result := Format(
      CBoard,
      [
        CShape[FBoard[22]], CShape[FBoard[23]], CShape[FBoard[24]], CShape[FBoard[25]], CShape[FBoard[26]], CShape[FBoard[27]], CShape[FBoard[28]], CShape[FBoard[29]], CArrow[FActiveColor],
        CShape[FBoard[32]], CShape[FBoard[33]], CShape[FBoard[34]], CShape[FBoard[35]], CShape[FBoard[36]], CShape[FBoard[37]], CShape[FBoard[38]], CShape[FBoard[39]], 
        CShape[FBoard[42]], CShape[FBoard[43]], CShape[FBoard[44]], CShape[FBoard[45]], CShape[FBoard[46]], CShape[FBoard[47]], CShape[FBoard[48]], CShape[FBoard[49]], 
        CShape[FBoard[52]], CShape[FBoard[53]], CShape[FBoard[54]], CShape[FBoard[55]], CShape[FBoard[56]], CShape[FBoard[57]], CShape[FBoard[58]], CShape[FBoard[59]], 
        CShape[FBoard[62]], CShape[FBoard[63]], CShape[FBoard[64]], CShape[FBoard[65]], CShape[FBoard[66]], CShape[FBoard[67]], CShape[FBoard[68]], CShape[FBoard[69]], 
        CShape[FBoard[72]], CShape[FBoard[73]], CShape[FBoard[74]], CShape[FBoard[75]], CShape[FBoard[76]], CShape[FBoard[77]], CShape[FBoard[78]], CShape[FBoard[79]], 
        CShape[FBoard[82]], CShape[FBoard[83]], CShape[FBoard[84]], CShape[FBoard[85]], CShape[FBoard[86]], CShape[FBoard[87]], CShape[FBoard[88]], CShape[FBoard[89]], 
        CShape[FBoard[92]], CShape[FBoard[93]], CShape[FBoard[94]], CShape[FBoard[95]], CShape[FBoard[96]], CShape[FBoard[97]], CShape[FBoard[98]], CShape[FBoard[99]], CArrow[FActiveColor = FALSE],
        CColor[FActiveColor],
        LCastlingState,
        LEnPassantState
      ]
    );
  end;
end;

var
  LPosition: TPosition;
  LNodes: integer;

function LoadPosition(const AFen: string; var AActiveColor: integer): boolean;
var
  a: array[1..6] of string;
  x, y, i, j: integer;
begin
  result := FALSE;
  
  for i := 1 to 6 do
    a[i] := ExtractWord(i, AFen, [' ']);

  x := 1;
  y := 8;
  i := 1;

  with LPosition do
  begin
    while i <= Length(a[1]) do
    begin
      case UpCase(a[1][i]) of
        'P', 'N', 'B', 'R', 'Q', 'K':
          begin
            case a[1][i] of
              'p': j := CBlack * CPawn;
              'n': j := CBlack * CKnight;
              'b': j := CBlack * CBishop;
              'r': j := CBlack * CRook;
              'q': j := CBlack * CQueen;
              'k': j := CBlack * CKing;
              'P': j := CWhite * CPawn;
              'N': j := CWhite * CKnight;
              'B': j := CWhite * CBishop;
              'R': j := CWhite * CRook;
              'Q': j := CWhite * CQueen;
              'K': j := CWhite * CKing;
            end;
            FBoard[10 * (10 - y) + x + 1] := j;
            Inc(x);
          end;
        '1'..'8':
          begin
            j := Ord(a[1][i]) - Ord('0');
            while j > 0 do
            begin
              FBoard[10 * (10 - y) + x + 1] := cBlank;
              Inc(x);
              Dec(j);
            end;
          end;
        '/':
          begin
            x := 1;
            Dec(y);
          end;
      else
        Exit;
      end;
      Inc(i);
    end;
    
    FActiveColor := a[2] = 'b';
     
    FQueenRookCastle[CBlack] := (Pos('q', a[3]) > 0);
    FKingRookCastle[CBlack] := (Pos('k', a[3]) > 0);
    FKingCastle[CBlack] := FQueenRookCastle[CBlack] or FKingRookCastle[CBlack];

    FQueenRookCastle[CWhite] := (Pos('Q', a[3]) > 0);
    FKingRookCastle[CWhite] := (Pos('K', a[3]) > 0);
    FKingCastle[CWhite] := FQueenRookCastle[CWhite] or FKingRookCastle[CWhite];

    if a[4] = '-' then
      FEnPassantSquare := CNone
    else
      FEnPassantSquare := StrToSquare(a[4]);
  end;

  if a[2] = 'w' then
    AActiveColor := CWhite
  else if a[2] = 'b' then
    AActiveColor := CBlack
  else
    Exit;

  result := TRUE;
end;

procedure SetAuxData(var AData: TAuxData);
var
  LSquare: integer;
begin
  FillChar(AData, SizeOf(AData), #0);
  with LPosition do
    for LSquare := CTop to CBottom do
      if Abs(FBoard[LSquare]) in [CPawn..CKing] then
        with AData[PieceColor(FBoard[LSquare])] do
        begin
          Inc(FPieceNumber);
          FPieces[FPieceNumber] := LSquare;
          if FBoard[LSquare] = PieceColor(FBoard[LSquare]) * CKing then
            FKingSquare := LSquare;
        end;
end;

function InCheck(const AColor, AKingSquare, AOpponentKingSquare: integer): boolean;
var
  i, s, b, v: integer;
begin
  result := TRUE;

  if Abs(AKingSquare - AOpponentKingSquare) in [1, 9..11] then
    Exit;

  with LPosition do
  begin
    for i := 1 to 4 do
    begin
      v := CBishopVector[i];
      s := AKingSquare;
      repeat
        Inc(s, v);
        b := FBoard[s];
      until b <> cBlank;
      if (b = -1 * AColor * CBishop) or (b = -1 * AColor * CQueen) then
        Exit;

      v := CRookVector[i];
      s := AKingSquare;
      repeat
        Inc(s, v);
        b := FBoard[s];
      until b <> cBlank;
      if (b = -1 * AColor * CRook) or (b = -1 * AColor * CQueen) then
        Exit;
    end;

    for i := 1 to 8 do
      if FBoard[AKingSquare + CKnightVector[i]] = -1 * AColor * CKnight then
        Exit;

    for i := 2 to 3 do
      if FBoard[AKingSquare + -1 * AColor * CPawnVector[i]] = -1 * AColor * CPawn then
        Exit;
  end;
  result := FALSE;
end;

procedure GenerateMoves(
  const AColor: integer;
  const ASquare: integer;
  var AMoves: TMoveArray;
  var AMovesCount: integer;
  AKingSquare, AOpponentKingSquare: integer;
  const ALegal: boolean;
  const ASingle: boolean;
  var AFound: boolean
);
var
  s, b, i, d: integer;
  r: TPosition;
  v, c: integer;

  procedure TestRecordMove(const ABoard, AClass, AValue: integer);
  begin
    if ALegal then
    begin
      r := LPosition;
      with LPosition do
      begin
        FBoard[s] := ABoard;
        FBoard[ASquare] := cBlank;
        if AClass = -1 * CEnPassant then
          FBoard[s + CPawnVector[1] * AColor] := cBlank;
        if InCheck(AColor, AKingSquare, AOpponentKingSquare) then
        begin
          LPosition := r;
          Exit;
        end;
        if ASingle then
        begin
          AFound := TRUE;
          LPosition := r;
          Exit;
        end;
      end;
      LPosition := r;
    end;
    Inc(AMovesCount);
    with AMoves[AMovesCount] do
    begin
      FFrom := ASquare;
      FTo := s;
      FClass := AClass;
      FValue := AValue;
    end;
  end;

  procedure TestRecordPawn;
  begin
    v := CPieceValue[Abs(b)];

    if v = 0 then
      c := CAny
    else
      c := CCapture;

    if s in CPromoSquares[AColor] then
    begin
      TestRecordMove(AColor * CQueen,  CQueen  * c, v + CQueenValue); if AFound then Exit;
      TestRecordMove(AColor * CRook,   CRook   * c, v + CRookValue); if AFound then Exit;
      TestRecordMove(AColor * CBishop, CBishop * c, v + CBishopValue); if AFound then Exit;
      TestRecordMove(AColor * CKnight, CKnight * c, v + CKnightValue); if AFound then Exit;
    end else
    begin
      TestRecordMove(CPawn, c, v);
      if AFound then
        Exit;
    end;
  end;

  procedure TestCastling;
  var
    i: integer;
  label
    sig;
  begin
    with LPosition do
    begin
      if not FKingCastle[AColor] then
        Exit;
      AKingSquare := ASquare;
      if FKingRookCastle[AColor] then
      begin
        for i := Succ(AKingSquare) to AKingSquare + 2 do
          if FBoard[i] <> cBlank then
            goto sig;
        if InCheck(AColor, AKingSquare, AOpponentKingSquare) then
          Exit;
        for i := Succ(AKingSquare) to AKingSquare + 2 do
          if InCheck(AColor, i, AOpponentKingSquare) then
            goto sig;
        if ASingle then
        begin
          AFound := TRUE;
          Exit;
        end;
        Inc(AMovesCount);
        with AMoves[AMovesCount] do
        begin
          FFrom := ASquare;
          FTo := AKingSquare + 2;
          FClass := CShortCastle;
          FValue := CShortCastleValue;
        end;
      end;
      sig:
      if FQueenRookCastle[AColor] then
      begin
        for i := AKingSquare - 3 to Pred(AKingSquare) do
          if FBoard[i] <> cBlank then
            Exit;
        if InCheck(AColor, AKingSquare, AOpponentKingSquare) then
          Exit;
        for i := AKingSquare - 2 to Pred(AKingSquare) do
          if InCheck(AColor, i, AOpponentKingSquare) then
            Exit;
        if ASingle then
        begin
          AFound := TRUE;
          Exit;
        end;
        Inc(AMovesCount);
        with AMoves[AMovesCount] do
        begin
          FFrom := ASquare;
          FTo := AKingSquare - 2;
          FClass := CLongCastle;
          FValue := CLongCastleValue;
        end;
      end;
    end;
  end;

begin
  AFound := FALSE;
  Inc(LNodes);
  with LPosition do
  begin
    AMovesCount := 0;
    case Abs(FBoard[ASquare]) of
      CPawn:
        begin
          d := -1 * AColor * CPawnVector[1];
          s := ASquare + d;
          b := FBoard[s];
          if b = cBlank then
          begin
            TestRecordPawn;
            if AFound then
              Exit;
            if ASquare in CPawnSquares[AColor] then
            begin
              Inc(s, d);
              b := FBoard[s];
              if b = cBlank then
              begin
                TestRecordPawn;
                if AFound then
                  Exit;
              end;
            end;
          end;
          for i := 2 to 3 do
          begin
            s := ASquare - 1 * AColor * CPawnVector[i];
            if s = FEnPassantSquare then
            begin
              if s in CEnPassantSquares[AColor] then
              begin
                TestRecordMove(CPawn, -1 * CEnPassant, CPawnValue);
                if AFound then
                  Exit;
              end;
            end else
            begin
              b := FBoard[s];
              if Abs(b) in [CPawn..CKing] then
                if b * -1 * AColor > 0 then
                begin
                  TestRecordPawn;
                  if AFound then
                    Exit;
                end;
            end;
          end;
        end;
      CKnight:
        for i := 1 to 8 do
        begin
          s := ASquare + CKnightVector[i];
          b := FBoard[s];
          if b <> 7 then
            if b * AColor <= 0 then
            begin
              v := CPieceValue[Abs(b)];
              if v = 0 then
                c := CAny
              else
                c := CCapture;
              TestRecordMove(FBoard[ASquare], c, v);
              if AFound then
                Exit;
            end;
        end;
      CBishop:
        for i := 1 to 4 do
        begin
          s := ASquare;
          repeat
            Inc(s, CBishopVector[i]);
            b := FBoard[s];
            if b <> 7 then
              if b * AColor <= 0 then
              begin
                v := CPieceValue[Abs(b)];
                if v = 0 then
                  c := CAny
                else
                  c := CCapture;
                TestRecordMove(FBoard[ASquare], c, v);
                if AFound then
                  Exit;
              end;
          until b <> cBlank;
        end;
      CRook:
        for i := 1 to 4 do
        begin
          s := ASquare;
          repeat
            Inc(s, CRookVector[i]);
            b := FBoard[s];
            if b <> 7 then
              if b * AColor <= 0 then
              begin
                v := CPieceValue[Abs(b)];
                if v = 0 then
                  c := CAny
                else
                  c := CCapture;
                TestRecordMove(FBoard[ASquare], c, v);
                if AFound then
                  Exit;
              end;
          until b <> cBlank;
        end;
      CQueen:
        for i := 1 to 8 do
        begin
          s := ASquare;
          repeat
            Inc(s, CQueenVector[i]);
            b := FBoard[s];
            if b <> 7 then
              if b * AColor <= 0 then
              begin
                v := CPieceValue[Abs(b)];
                if v = 0 then
                  c := CAny
                else
                  c := CCapture;
                TestRecordMove(FBoard[ASquare], c, v);
                if AFound then
                  Exit;
              end;
          until b <> cBlank;
        end;
      CKing:
        begin
          for i := 1 to 8 do
          begin
            s := ASquare + CKingVector[i];
            b := FBoard[s];
            AKingSquare := s;
            if b <> 7 then
              if b * AColor <= 0 then
              begin
                v := CPieceValue[Abs(b)];
                if v = 0 then
                  c := CAny
                else
                  c := CCapture;
                TestRecordMove(FBoard[ASquare], c, v);
                if AFound then
                  Exit;
              end;
          end;
          TestCastling;
          if AFound then
            Exit;
        end;
    end;
  end;
end;

function AnyMoveSide(const AColor: integer; var AData: TAuxData; const AKingSquare, AOpponentKingSquare: integer): boolean;
var
  i, LCount: integer;
  LMoves: TMoveArray;
  LFound: boolean;
begin
  with AData[AColor] do
  begin
    GenerateMoves(
      AColor,
      AKingSquare,
      LMoves,
      LCount,
      AKingSquare,
      AOpponentKingSquare,
      TRUE,
      TRUE,
      LFound
    );
    if LFound then
    begin
      result := TRUE;
      Exit;
    end;
    for i := 1 to FPieceNumber do
      if FPieces[i] <> AKingSquare then
      begin
        GenerateMoves(
          AColor,
          FPieces[i],
          LMoves,
          LCount,
          AKingSquare,
          AOpponentKingSquare,
          TRUE,
          TRUE,
          LFound
        );
        if LFound then
        begin
          result := TRUE;
          Exit;
        end;
      end;
  end;
  result := FALSE;
end;

procedure PerformMove(var AMove: TMove; const AColor: integer; var AKingSquare: integer);
var
  b: integer;
begin
  with AMove, LPosition do
  begin
    b := FBoard[FFrom];
    FBoard[FFrom] := cBlank;
    FBoard[FTo] := b;
    FEnPassantSquare := CNone;
    case Abs(b) of
      CPawn:
        begin
          if Abs(FFrom - FTo) = 20 then
            FEnPassantSquare := (FFrom + FTo) div 2;
          case Abs(FClass) of
            CKnight, CBishop, CRook, CQueen:
              FBoard[FTo] := AColor * Abs(FClass);
            CEnPassant:
              FBoard[FTo + CPawnVector[1] * AColor] := cBlank;
          end;
        end;
      CKing:
        begin
          AKingSquare := FTo;
          if FKingCastle[AColor] then
          begin
            FKingCastle[AColor] := FALSE;
            FQueenRookCastle[AColor] := FALSE;
            FKingRookCastle[AColor] := FALSE;
          end;
          case FClass of
            CShortCastle:
              begin
                FBoard[Pred(FTo)] := AColor * CRook;
                FBoard[FFrom + 3] := cBlank;
              end;
            CLongCastle:
              begin
                FBoard[Succ(FTo)] := AColor * CRook;
                FBoard[FFrom - 4] := cBlank;
              end;
          end;
        end;
      CRook:
        if FFrom = CQueenRookSquares[AColor] then
          FQueenRookCastle[AColor] := FALSE
        else if FFrom = CKingRookSquares[AColor] then
          FKingRookCastle[AColor] := FALSE;
    end;
    if FTo = CQueenRookSquares[-1 * AColor] then
      FQueenRookCastle[-1 * AColor] := FALSE
    else if FTo = CKingRookSquares[-1 * AColor] then
      FKingRookCastle[-1 * AColor] := FALSE;
  end;
end;

function FindMate(const AColor: integer; const ADepth: integer; const AMaxDepth: integer; var AMove: TMove; const ACheckOnly: boolean): boolean;
label
  __NEXT__,
  __MATE__;
var
  LKingSquare, LOtherKingSquare, i, j, k, k2, LNotUsed: integer;
  LData1, LData2: TAuxData;
  LMove: TMove;
  LArray1, LArray2: TMoveArray;
  LCount1, LCount2: integer;
  LPos1, LPos2: TPosition;
  LFound, LStalemate: boolean;
begin
  SetAuxData(LData1);
  LKingSquare := LData1[AColor].FKingSquare;
  LOtherKingSquare := LData1[-1 * AColor].FKingSquare;
  LPos1 := LPosition;
  with LData1[AColor] do
    for k := 1 to FPieceNumber do
    begin
      GenerateMoves(AColor, FPieces[k], LArray1, LCount1, LKingSquare, LOtherKingSquare, ADepth <> AMaxDepth, FALSE, LFound);
      for i := 1 to LCount1 do
      begin
        LMove := LArray1[i];
        PerformMove(LMove, AColor, LKingSquare);
        if ADepth = AMaxDepth then
          if InCheck(-1 * AColor, LOtherKingSquare, LKingSquare) then
          begin
            if InCheck(AColor, LKingSquare, LOtherKingSquare) then goto __NEXT__;
            if LMove.FClass < 0 then SetAuxData(LData2) else LData2 := LData1;
            if AnyMoveSide(-1 * AColor, LData2, LOtherKingSquare, LKingSquare) then goto __NEXT__;
            goto __MATE__;
          end else
            goto __NEXT__;
        if ACheckOnly then
          if not InCheck(-1 * AColor, LOtherKingSquare, LKingSquare) then goto __NEXT__;
        LStalemate := TRUE;
        if LMove.FClass < 0 then SetAuxData(LData2) else LData2 := LData1;
        with LData2[-1 * AColor] do
          for k2 := 1 to FPieceNumber do
          begin
            GenerateMoves(-1 * AColor, FPieces[k2], LArray2, LCount2, LOtherKingSquare, LKingSquare, TRUE, FALSE, LFound);
            if LCount2 <> 0 then
            begin
              LStalemate := FALSE;
              LPos2 := LPosition;
              for j := 1 to LCount2 do
              begin
                PerformMove(LArray2[j], -1 * AColor, LNotUsed);
                if not FindMate(AColor, Succ(ADepth), AMaxDepth, AMove, ACheckOnly) then goto __NEXT__;
                LPosition := LPos2;
              end;
            end;
          end;
        if ACheckOnly then goto __MATE__;
        if LStalemate then
          if InCheck(-1 * AColor, LOtherKingSquare, LKingSquare) then goto __MATE__ else goto __NEXT__;
        
        __MATE__:
        if ADepth = 1 then
          AMove := LMove;
        result := TRUE;
        LPosition := LPos1;
        Exit;
        
        __NEXT__:
        LPosition := LPos1;
        LKingSquare := FKingSquare;
      end;
    end;
  result := FALSE;
end;

function SearchMate(const AColor: integer; const ADepth: integer; const AMaxDepth: integer; var AMoveDepth: integer; var AMove: TMove; const ACheckOnly: boolean): boolean;
var
  i: integer;
begin
  result := FALSE;
  i := ADepth;
  while (i <= AMaxDepth) and not result do
  begin
    if FindMate(AColor, 1, i, AMove, ACheckOnly) then
    begin
      result := TRUE;
      AMoveDepth := i;
    end;
    Inc(i);
  end;
end;

function ClassToStr(const AClass: integer): string;
begin
  case Abs(AClass) of
    CAny:         result := '';
    CKnight:      result := 'n';
    CBishop:      result := 'b';
    CRook:        result := 'r';
    CQueen:       result := 'q';
    CShortCastle: result := '';
    CLongCastle:  result := '';
    CEnPassant:   result := '';
    else
      result := '???';
  end;
end;

function FormatMove(const AMove: TMove): string;
(*
const
  CPieceName: array[CPawn..CKing] of string = ('', 'N', 'B', 'R', 'Q', 'K');
*)
begin
  with AMove, LPosition do
    if (FFrom = 0) and (FTo = 0) then
      result := '(no move)'
    else
    (*
      if FClass < 0 then { Capture }
        result := Concat(CPieceName[FBoard[FFrom]], SquareToStr(FFrom), 'x', SquareToStr(FTo), ClassToStr(FClass))
      else
        result := Concat(CPieceName[FBoard[FFrom]], SquareToStr(FFrom), SquareToStr(FTo), ClassToStr(FClass));
    *)
      result := Concat(SquareToStr(FFrom), SquareToStr(FTo), ClassToStr(FClass));
end;

function SolveMate(const AFen: string; const AMovesNumber: integer; const ACheckOnly: boolean): string;
const
  COption: array[boolean] of string = ('all moves', 'check sequence');
var
  LMoveDepth: integer;
  LActiveColor: integer;
  LMove: TMove;
begin
  result := '';
  if LoadPosition(AFen, LActiveColor) then
  begin
    WriteLn(LineEnding, PosToStr(LPosition));
    WriteLn('Search mode: ', COption[ACheckOnly]);
    WriteLn('Maximum moves number: ', AMovesNumber);
    LNodes := 0;
    if SearchMate(
      LActiveColor,
      1,
      AMovesNumber,
      LMoveDepth,
      LMove,
      ACheckOnly
    ) then
    begin
      result := FormatMove(LMove);
      WriteLn('Result: ', result);
    end;
  end;
end;

const
  CZero: TPosition = (
    FBoard: (
      cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut,
      cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cBlank, cOut,
      cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut,
      cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut, cOut
    );
    FActiveColor: FALSE;
    FKingCastle: (FALSE, FALSE, FALSE);
    FQueenRookCastle: (FALSE, FALSE, FALSE);
    FKingRookCastle: (FALSE, FALSE, FALSE);
    FEnPassantSquare: CNone
  );

begin
  LPosition := CZero;
end.
