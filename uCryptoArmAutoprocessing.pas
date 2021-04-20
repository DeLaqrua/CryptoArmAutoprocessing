unit uCryptoArmAutoprocessing;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, MSScriptControl_TLB,
  Vcl.StdCtrls, ActiveX, frxClass, System.Zip, Vcl.FileCtrl, System.Masks, DateUtils,
  Vcl.Buttons, Vcl.Samples.Spin, Vcl.ExtCtrls;

type
  TFormMain = class(TForm)
    ScriptControlVB: TScriptControl;
    ButtonManualProcessing: TButton;
    MemoLog: TMemo;
    frxReportProtocolConfirmed: TfrxReport;
    frxReportProtocolNotConfirmed: TfrxReport;
    LabelPath: TLabel;
    EditPath: TEdit;
    ButtonPath: TButton;
    SpeedButtonPlay: TSpeedButton;
    SpeedButtonStop: TSpeedButton;
    LabelAutoProcessingInterval: TLabel;
    LabelMin: TLabel;
    LabelSec: TLabel;
    SpinEditMin: TSpinEdit;
    SpinEditSec: TSpinEdit;
    TimerAutoProcessingState: TTimer;
    LabelAutoProcessingState: TLabel;
    TimerAutoProcessing: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure ButtonManualProcessingClick(Sender: TObject);
    procedure ButtonPathClick(Sender: TObject);
    procedure SpeedButtonPlayMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButtonPlayMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButtonStopMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpeedButtonStopMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SpinEditMinKeyPress(Sender: TObject; var Key: Char);
    procedure SpinEditSecKeyPress(Sender: TObject; var Key: Char);
    procedure SpeedButtonPlayClick(Sender: TObject);
    procedure SpeedButtonStopClick(Sender: TObject);
    procedure TimerAutoProcessingStateTimer(Sender: TObject);
    procedure TimerAutoProcessingTimer(Sender: TObject);
    procedure SpinEditSecChange(Sender: TObject);
    procedure SpinEditMinChange(Sender: TObject);

  private
    { Private declarations }
  public
    function SignatureVerify(inputFileName, inputFileNameSignature: string): string;
    function CheckErrorsWithinArchive(inputArchiveFileName: string): boolean;
    function CorrectPath(inputDirectory: string): string;
    function CheckFileName(inputFileName: string): boolean;

    procedure UpdateDirectories(inputDirectoryRoot: string);
    procedure SortErrorFiles;
    procedure MoveFilesToErrors(inputFileName: string);

    procedure Processed(inputArchiveFileName: string);
    procedure MoveFilesToProcessed(inputArchiveFileName, inputNotSigFile: string; inputSigFilesArray: array of string);
  end;

var
  FormMain: TFormMain;
var
  DirectoryRoot, DirectoryErrors, DirectoryProcessed, DirectoryOutput, DescriptionErrorArchive: string;

implementation

{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
var ScriptFile: TextFile;
    Script, LineScript: String;
begin

  Script := '';

  if FileExists(ExtractFilePath(ParamStr(0))+'VerifyScript.vbs') then
    begin
      AssignFile(ScriptFile, ExtractFilePath(ParamStr(0))+'VerifyScript.vbs');
      Reset(ScriptFile);

      while not EOF(ScriptFile) do
        begin
          readln(ScriptFile, LineScript);
          Script := Script + LineScript + #13#10;
        end;

      CloseFile(ScriptFile);

      ScriptControlVB.Language := 'VBScript';
      ScriptControlVB.AddCode(Script);
    end
  else
    begin
      ShowMessage('���� "VerifyScript.vbs" ����������� � ����� � ����������. ��� ���� ��������� �� ����������.');
      Application.Terminate;
      Exit;
    end;

end;

procedure TFormMain.ButtonManualProcessingClick(Sender: TObject);
var SearchResult: TSearchRec;
    responceTextFile: TextFile;
    responceTextFileName: string;
    i: integer;

    FileDateTime: TDateTime;
    NotSigFileName, NotSigFileDateCreate, NotSigFileSize: string;
    frxNotSigFileName, frxNotSigFileDateCreate, frxNotSigFileSize: TfrxMemoView;
begin
  NotSigFileName := 'E:\Proba\AutoProcessingFiles\SH_830009_83008.xls';
  NotSigFileDateCreate := DateTimeToStr( FileDateToDateTime(FileAge(NotSigFileName)) );
  NotSigFileSize := IntToStr(FileSize(NotSigFileName));

  frxNotSigFileName := TfrxMemoView(frxReportProtocolNotConfirmed.FindObject('MemoNotSigFileName'));
  frxNotSigFileName.Memo.Text := ExtractFileName(NotSigFileName);

  frxNotSigFileDateCreate := TfrxMemoView(frxReportProtocolNotConfirmed.FindObject('MemoNotSigFileDateCreate'));
  frxNotSigFileDateCreate.Memo.Text := NotSigFileDateCreate;


  frxNotSigFileSize := TfrxMemoView(frxReportProtocolNotConfirmed.FindObject('MemoNotSigFileSize'));
  frxNotSigFileSize.Memo.Text := NotSigFileSize;

  frxReportProtocolNotConfirmed.ShowReport(true);

{
  DirectoryRoot := CorrectPath(EditPath.Text);
  if System.SysUtils.DirectoryExists(DirectoryRoot) = False then
    ShowMessage('��������� ���� � ����������. ����� �� ����������.')
  else
    begin

      UpdateDirectories(DirectoryRoot);

      SortErrorFiles;

      if FindFirst(DirectoryRoot + '*.*', faNormal, SearchResult) = 0 then
        begin
          repeat
            if CheckFileName(SearchResult.Name) and CheckErrorsWithinArchive(SearchResult.Name) then
              begin
                MoveFilesToErrors(SearchResult.Name);

                if System.SysUtils.DirectoryExists(DirectoryOutput) = False then
                  System.SysUtils.ForceDirectories(DirectoryOutput);
                responceTextFileName := DirectoryOutput + 'response_' + StringReplace(SearchResult.Name, ExtractFileExt(SearchResult.Name), '', [rfIgnoreCase]) + '.txt';
                i := 0;
                while FileExists(responceTextFileName) do
                  begin
                    i := i+1;
                    if i = 1 then
                      Insert(' (' + IntToStr(i) + ')', responceTextFileName, Length(responceTextFileName)-3)
                    else
                      responceTextFileName := StringReplace(responceTextFileName, ' (' + IntToStr(i-1) + ')', ' (' + IntToStr(i) + ')', []);
                  end;
                AssignFile(responceTextFile, responceTextFileName);
                ReWrite(responceTextFile);
                WriteLn(responceTextFile, DescriptionErrorArchive);
                CloseFile(responceTextFile);
              end
            else Processed(SearchResult.Name);
          until FindNext(SearchResult) <> 0;
          FindClose(SearchResult);
        end;

    end;
}
end;

procedure TFormMain.Processed(inputArchiveFileName: string);
var i, arrayIndex: integer;
    Archive: TZipFile;
    SigFilesArray: array of string;
    NotSigFile: string;
begin
  Archive := TZipFile.Create;
  try
    Archive.Open(DirectoryRoot + inputArchiveFileName, zmRead);
    Archive.ExtractAll(DirectoryRoot);

    arrayIndex := 0;
    for i := 0 to Archive.FileCount-1 do
      begin
        if LowerCase(ExtractFileExt(Archive.FileName[i])) = '.sig' then
          begin
            SetLength(SigFilesArray, arrayIndex + 1);
            SigFilesArray[arrayIndex] := Archive.FileName[i];
            arrayIndex := arrayIndex + 1;
          end
        else
          begin
            NotSigFile := Archive.FileName[i];
          end;
      end;

    Archive.Close;
  finally
    Archive.Free;
  end;

  {for i := 0 to High(SigFilesArray) do
    begin
      MemoLog.Lines.Add( SignatureVerify(DirectoryRoot + NotSigFile, DirectoryRoot + SigFilesArray[i]) );
    end;}

  MoveFilesToProcessed(inputArchiveFileName, NotSigFile, SigFilesArray);

end;

function TFormMain.SignatureVerify (inputFileName, inputFileNameSignature: string): string;
var VArr, ResultFromVB: Variant;
    ResultDescription: string;
    FunctionParameters: PSafeArray;
begin
  try
    VArr:=VarArrayCreate([0, 1], varVariant);
    VArr[0] := inputFileName;
    VArr[1] := inputFileNameSignature;

    FunctionParameters := PSafeArray(TVarData(VArr).VArray);

    ResultFromVB := ScriptControlVB.Run('SignatureVerify', FunctionParameters);
    case ResultFromVB of
      1 : ResultDescription := '�����';
      3 : ResultDescription := '������� ����������� ��� � ��� ��� �������';
    else ResultDescription := '������ �� ��������';
    end;

  except
    on E: Exception do
    MessageDlg(PWideChar(E.Message), mtError, [mbOk], 0);
  end;

  Result := ResultDescription;
end;

procedure TFormMain.SortErrorFiles;
var SearchResult: TSearchRec;
begin
  if System.SysUtils.DirectoryExists(DirectoryErrors) = False then
    System.SysUtils.ForceDirectories(DirectoryErrors);

  if FindFirst(DirectoryRoot + '*.*', faNormal, SearchResult) = 0 then
    begin
      repeat
        if (LowerCase(ExtractFileExt(SearchResult.Name)) <> '.zip') or
           (CheckFileName(SearchResult.Name) = false) then
          begin
            MoveFilesToErrors(SearchResult.Name);
            MemoLog.Lines.Add( DateToStr(Now) + ' ' + TimeToStr(Now) + '  �������� ��� ����� "' + SearchResult.Name + '"' + #13#10);
          end;
      until FindNext(SearchResult) <> 0;
      FindClose(SearchResult);
    end;
end;

function TFormMain.CheckFileName(inputFileName: string): boolean;
begin
  Result := False;

  if MatchesMask(inputFileName, 'SH_*_*_*.zip') or
     MatchesMask(inputFileName, 'SHO_*_*_*.zip') or
     MatchesMask(inputFileName, 'MSHO_*_*_*.zip') or
     MatchesMask(inputFileName, 'MSH_*_*_*.zip') or
     MatchesMask(inputFileName, 'MSMP_*_*_*.zip') or
     MatchesMask(inputFileName, 'SMP_*_*_*.zip') then
    begin
      Result := True;
    end;

end;

function TFormMain.CheckErrorsWithinArchive(inputArchiveFileName: string): boolean;
var i, Counter: integer;
    Archive: TZipFile;
begin
  DescriptionErrorArchive := '';

  Result := False;

  Archive := TZipFile.Create;
  try
    Archive.Open(DirectoryRoot + inputArchiveFileName, zmRead);

    Counter := 0;
    //�������� �� ���������� ������, ����������� � zip-������ ��� ����������. �� ���������� � ������ ������ ���� 1 ���� ��� ����������.
    for i := 0 to Archive.FileCount-1 do
      begin
        if LowerCase(ExtractFileExt(Archive.FileName[i])) <> '.sig' then
          Counter := Counter + 1;
      end;
    if Counter <> 1 then
      begin
        Result := True;
        DescriptionErrorArchive := '� zip-������ "' + inputArchiveFileName + '" ����� ������ ����� ��� ����������.';
        MemoLog.Lines.Add( DateToStr(Now) + ' ' + TimeToStr(Now) + '  ' + DescriptionErrorArchive + #13#10);
      end;

    //�������� �� ���������� ��������. ���� � zip-������ ������� �����������, �� � �����.
    Counter := 0;
    for i := 0 to Archive.FileCount-1 do
      begin
        if LowerCase(ExtractFileExt(Archive.FileName[i])) = '.sig' then
          counter := Counter + 1;
      end;
    if Counter = 0 then
      begin
        Result := True;
        DescriptionErrorArchive := '� zip-������ "' + inputArchiveFileName + '" ����������� �����-������� � ����������� ".sig"';
        MemoLog.Lines.Add( DateToStr(Now) + ' ' + TimeToStr(Now) + '  ' + DescriptionErrorArchive + #13#10);
      end;

    Archive.Close;
  finally
    Archive.Free;
  end;

end;

procedure TFormMain.MoveFilesToProcessed(inputArchiveFileName: string; inputNotSigFile: string; inputSigFilesArray: array of string);
var DirectoryFrom, DirectoryTo, fileDirectoryFrom, fileDirectoryTo: string;
    MO: string;
    pointerFileDirectoryFrom, pointerFileDirectoryTo: PWideChar;
    Year, Month: integer;
    i, indexArray: integer;
begin
  Year := YearOf(Date);
  Month := MonthOf(Date);
  MO := Copy(inputArchiveFileName, AnsiPos('_', inputArchiveFileName) + 1, 6);

  DirectoryFrom := DirectoryRoot;

  DirectoryTo := DirectoryProcessed + IntToStr(Year) + '\' + IntToStr(Month) + '\' + MO + '\' +
                 StringReplace(inputArchiveFileName, ExtractFileExt(inputArchiveFileName), '', [rfIgnoreCase]) + '\';
  if System.SysUtils.DirectoryExists(DirectoryTo) then
    begin
      i := 0;
      while System.SysUtils.DirectoryExists(DirectoryTo) do
        begin
          i := i+1;
          if i = 1 then
            begin
              Insert(' (' + IntToStr(i) + ')', DirectoryTo, Length(DirectoryTo));
            end
          else
            begin
              DirectoryTo := StringReplace(DirectoryTo, ' (' + IntToStr(i-1) +')', ' (' + IntToStr(i) + ')', []);
            end;
        end;
      System.SysUtils.ForceDirectories(DirectoryTo);
    end
  else
    System.SysUtils.ForceDirectories(DirectoryTo);

  fileDirectoryFrom := DirectoryFrom + inputArchiveFileName;
  pointerFileDirectoryFrom := Addr(fileDirectoryFrom[1]);
  fileDirectoryTo := DirectoryTo + inputArchiveFileName;
  pointerFileDirectoryTo := Addr(fileDirectoryTo[1]);
  MoveFile(pointerFileDirectoryFrom, pointerFileDirectoryTo);

  fileDirectoryFrom := DirectoryFrom + inputNotSigFile;
  pointerFileDirectoryFrom := Addr(fileDirectoryFrom[1]);
  fileDirectoryTo := DirectoryTo + inputNotSigFile;
  pointerFileDirectoryTo := Addr(fileDirectoryTo[1]);
  MoveFile(pointerFileDirectoryFrom, pointerFileDirectoryTo);

  For indexArray := 0 to High(inputSigFilesArray) do
    begin
      fileDirectoryFrom := DirectoryFrom + inputSigFilesArray[indexArray];
      pointerFileDirectoryFrom := Addr(fileDirectoryFrom[1]);
      fileDirectoryTo := DirectoryTo + inputSigFilesArray[indexArray];
      pointerFileDirectoryTo := Addr(fileDirectoryTo[1]);
      MoveFile(pointerFileDirectoryFrom, pointerFileDirectoryTo);
    end;

end;

procedure TFormMain.MoveFilesToErrors(inputFileName: string);
var fileDirectoryFrom, fileDirectoryTo: string;
    pointerFileDirectoryFrom, pointerFileDirectoryTo: PWideChar;
    i: integer;
begin
  if System.SysUtils.DirectoryExists(DirectoryErrors) = False then
    System.SysUtils.ForceDirectories(DirectoryErrors);

  fileDirectoryFrom := DirectoryRoot + inputFileName;
  fileDirectoryTo := DirectoryErrors + inputFileName;
  pointerFileDirectoryFrom := Addr(fileDirectoryFrom[1]);
  pointerFileDirectoryTo := Addr(fileDirectoryTo[1]);

  i := 0;
  while FileExists(fileDirectoryTo) do
    begin
      i := i+1;
      if i = 1 then
        begin
          Insert(' (' + IntToStr(i) + ')', fileDirectoryTo, Length(fileDirectoryTo)-3);
          pointerFileDirectoryTo := Addr(fileDirectoryTo[1]);
        end
      else
        begin
          fileDirectoryTo := StringReplace(fileDirectoryTo, ' (' + IntToStr(i-1) + ')', ' (' + IntToStr(i) + ')', []);
          pointerFileDirectoryTo := Addr(fileDirectoryTo[1]);
        end;
    end;

  MoveFile(pointerFileDirectoryFrom, pointerFileDirectoryTo);
end;

function TFormMain.CorrectPath(inputDirectory: string): string;
begin
  if Pos('/', inputDirectory) <> 0 then
    begin
      inputDirectory := StringReplace(inputDirectory, '/', '\', [rfReplaceAll]);
    end;

  if inputDirectory[length(inputDirectory)] <> '\' then
    Result := inputDirectory + '\'
  else
    Result := inputDirectory;
end;

procedure TFormMain.UpdateDirectories(inputDirectoryRoot: string);
begin
  DirectoryErrors := DirectoryRoot + 'Errors';
  DirectoryErrors := CorrectPath(DirectoryErrors);

  DirectoryProcessed := DirectoryRoot + 'Processed';
  DirectoryProcessed := CorrectPath(DirectoryProcessed);

  DirectoryOutput := DirectoryRoot + 'Output';
  DirectoryOutput := CorrectPath(DirectoryOutput);
end;

procedure TFormMain.ButtonPathClick(Sender: TObject);
begin
  if SelectDirectory('�������� ����� ��� ������ ���������������:', '', DirectoryRoot, [sdNewFolder, sdShowShares, sdNewUI, sdValidateDir]) then
    EditPath.Text := DirectoryRoot;
end;

procedure TFormMain.SpeedButtonPlayClick(Sender: TObject);
begin
  SpeedButtonPlay.Visible := False;
  SpeedButtonStop.Visible := True;

  if (SpinEditSec.Value > 59) or
     (SpinEditSec.Value < 0) or
     (SpinEditMin.Value < 0) or
     ( (SpinEditSec.Value = 0) and (SpinEditMin.Value = 0) ) then
    ShowMessage('������� ������� ������/�������')
  else
    begin
      TimerAutoProcessing.Interval := SpinEditMin.Value * 60000 + SpinEditSec.Value * 1000;
      TimerAutoProcessing.Enabled := True;

      TimerAutoProcessingState.Enabled := True;
      LabelAutoProcessingState.Caption := '�������������� �������';
    end;
end;

procedure TFormMain.SpeedButtonStopClick(Sender: TObject);
begin
  SpeedButtonStop.Visible := False;
  SpeedButtonPlay.Visible := True;

  TimerAutoProcessingState.Enabled := False;
  LabelAutoProcessingState.Caption := '�������������� �� �������';

  TimerAutoProcessing.Enabled := False;
end;

procedure TFormMain.TimerAutoProcessingStateTimer(Sender: TObject);
begin
  LabelAutoProcessingState.Caption := LabelAutoProcessingState.Caption + '.';
  if LabelAutoProcessingState.Caption = '�������������� �������....' then
    LabelAutoProcessingState.Caption := '�������������� �������';
end;

procedure TFormMain.TimerAutoProcessingTimer(Sender: TObject);
begin
  ButtonManualProcessingClick(Self);
end;

procedure TFormMain.SpeedButtonPlayMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SpeedButtonPlay.Glyph.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Icons\PlayPush.bmp');
end;

procedure TFormMain.SpeedButtonPlayMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SpeedButtonPlay.Glyph.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Icons\Play.bmp');
end;

procedure TFormMain.SpeedButtonStopMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SpeedButtonStop.Glyph.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Icons\StopPush.bmp');
end;

procedure TFormMain.SpeedButtonStopMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SpeedButtonStop.Glyph.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Icons\Stop.bmp');
end;

procedure TFormMain.SpinEditMinKeyPress(Sender: TObject; var Key: Char);
begin
  SpinEditMin.SelLength := 1;
end;

procedure TFormMain.SpinEditSecKeyPress(Sender: TObject; var Key: Char);
begin
  SpinEditSec.SelLength := 1;
end;

procedure TFormMain.SpinEditSecChange(Sender: TObject);
begin
  if SpinEditSec.Text = '' then
    SpinEditSec.Text := '0';
end;

procedure TFormMain.SpinEditMinChange(Sender: TObject);
begin
  if SpinEditMin.Text = '' then
    SpinEditMin.Text := '0';
end;

end.