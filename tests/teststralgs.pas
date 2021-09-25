program teststralgs;

uses
   adtstralgs, testutils, adtdarray, SysUtils;

{$R-}

procedure RunTest;
const
   abba1Ind = 28;
   abba2Ind = 33;
var
   str, str2, str3 : String;
   tab : array of Cardinal;
   ind, i : IndexType;
begin
   str := 'abcdefghijklmnopqrstuvwxyz abba abba Abba Pater Abba Pater';
   
   StartTest('String Algorithms (adtstralgs.pas)');
   
   { -------------------------- Reverse ----------------------- }
   Test(Reverse(str, 1, Length(str) + 1) =
           'retaP abbA retaP abbA abba abba zyxwvutsrqponmlkjihgfedcba',
        'Reverse');
   
   { -------------------------- KmpFindSubstr -------------------- }
   str2 := 'Abba Pater';
   ind := KmpFindSubstr(str, str2, 1, KmpComputeTable(str2));
   Test(ind = Length(str) - 2 * Length(str2), 'KmpFindSubstr',
        'wrong position: ' + IntToStr(ind) + ' instead of ' +
           IntToStr(Length(str) - 2 * Length(str2)));
   
   str2 := 'fghi';
   ind := KmpFindSubstr(str, str2, 3, KmpComputeTable(str2));
   Test(ind = 6, 'KmpFindSubstr', 'wrong position: ' +
                                     IntToStr(ind) + ' instead of 6');
   
   str2 := 'ii';
   ind := KmpFindSubstr(str, str2, 1, KmpComputeTable(str2));
   Test(ind = -1, 'KmpFindSubstr', 'wrong position: ' +
                                      IntToStr(ind) + ' instead of -1');
   
   str2 := 'abba';
   ind := KmpFindSubstr(str, str2, 1, KmpComputeTable(str2));
   Test(ind = abba1Ind, 'KmpFindSubstr', 'wrong position: ' + IntToStr(ind) +
                                            ' instead of ' +  IntToStr(abba1Ind));
   
   { ----------------------- KmpReverseFindSubstr ------------------- }
   str2 := 'Abba Pater';
   ind := KmpReverseFindSubstr(str, str2, Length(str) + 1,
                               KmpReverseComputeTable(str2));
   Test(ind = Length(str) - Length(str2) + 1, 'KmpReverseFindSubstr',
        'wrong position: ' + IntToStr(ind) + ' instead of ' +
           IntToStr(Length(str) - Length(str2) + 1));
   
   str2 := 'fghi';
   ind := KmpReverseFindSubstr(str, str2, Length(str) + 1,
                               KmpReverseComputeTable(str2));
   Test(ind = 6, 'KmpReverseFindSubstr', 'wrong position: ' +
                                     IntToStr(ind) + ' instead of 6');
   
   str2 := 'ii';
   ind := KmpReverseFindSubstr(str, str2, Length(str) + 1,
                               KmpReverseComputeTable(str2));
   Test(ind = -1, 'KmpReverseFindSubstr', 'wrong position: ' +
                                      IntToStr(ind) + ' instead of -1');
   
   str2 := 'abba';
   ind := KmpReverseFindSubstr(str, str2, Length(str) + 1,
                               KmpReverseComputeTable(str2));
   Test(ind = abba2Ind, 'KmpReverseFindSubstr', 'wrong position: ' +
                                                   IntToStr(ind) +
                                            ' instead of ' +  IntToStr(abba2Ind));
   
   { -------------------------- BmFindSubstr -------------------- }
   str2 := 'Abba Pater';
   ind := BmFindSubstr(str, str2, 1, BmComputeTable(str2));
   Test(ind = Length(str) - 2 * Length(str2), 'BmFindSubstr',
        'wrong position: ' + IntToStr(ind) + ' instead of ' +
           IntToStr(Length(str) - 2 * Length(str2)));
   
   str2 := 'fghi';
   ind := BmFindSubstr(str, str2, 3, BmComputeTable(str2));
   Test(ind = 6, 'BmFindSubstr', 'wrong position: ' +
                                     IntToStr(ind) + ' instead of 6');
   
   str2 := 'ii';
   ind := BmFindSubstr(str, str2, 1, BmComputeTable(str2));
   Test(ind = -1, 'BmFindSubstr', 'wrong position: ' +
                                      IntToStr(ind) + ' instead of -1');
   
   str2 := 'abba';
   ind := BmFindSubstr(str, str2, 1, BmComputeTable(str2));
   Test(ind = abba1Ind, 'BmFindSubstr', 'wrong position: ' + IntToStr(ind) +
                                           ' instead of ' +  IntToStr(abba1Ind));
   
   { ------------------------- KmrFindSubstrings ----------------- }
   str2 := 'Abba Pater';
   str3 := str + str2;
   tab := KmrFindSubstrings(str3, 1, Length(str3) + 1, Length(str2));
   Test(tab[Length(str) - 2 * Length(str2)] = tab[Length(str) + 1],
        'KmrFindSubstrings', str2 + ' not found at index: ' +
                                IntToStr(Length(str) - 2 * Length(str2)));
   Test(tab[Length(str) - Length(str2) + 1] = tab[Length(str) + 1],
        'KmrFindSubstrings', str2 + ' not found at index: ' +
                                IntToStr(Length(str) - Length(str2) + 1));
   
   str2 := 'fghi';
   str3 := str + str2;
   tab := KmrFindSubstrings(str3, 1, Length(str3) + 1, Length(str2));
   Test(tab[6] = tab[Length(str) + 1],
        'KmrFindSubstrings', str2 + ' not found at index: 6');
   
   str2 := 'ii';
   str3 := str + str2;
   tab := KmrFindSubstrings(str3, 1, Length(str3) + 1, Length(str2));
   StartSilentMode;
   for i := 1 to Length(str) do
   begin
      Test(tab[i] <> tab[Length(str) + 1], 'KmrFindSubstrings',
           'ii found at ' + IntToStr(i));
   end;
   StopSilentMode;
   
   FinishTest;
end;

begin
   RunTest;
end.

