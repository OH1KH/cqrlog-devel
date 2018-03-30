unit fMonWsjtx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, maskedit, ColorBox, Menus, ExtCtrls, RichMemo, strutils, process, Types;

type

  { TfrmMonWsjtx }

  TfrmMonWsjtx = class(TForm)
    btFTxtN: TButton;
    cbflw: TCheckBox;
    chkMap: TCheckBox;
    EditAlert: TEdit;
    edtFollow: TEdit;
    edtFollowCall: TEdit;
    pnlFollow: TPanel;
    pnlAlert: TPanel;
    tbAlert: TToggleBox;
    noTxt: TCheckBox;
    chkHistory: TCheckBox;
    cmCqDx: TMenuItem;
    cmFont: TMenuItem;
    popFontDlg: TFontDialog;
    popColorDlg: TColorDialog;
    lblBand: TLabel;
    lblMode: TLabel;
    cmHead: TMenuItem;
    cmNever: TMenuItem;
    cmBand: TMenuItem;
    cmAny: TMenuItem;
    cmHere: TMenuItem;
    popColors: TPopupMenu;
    tbLocAlert: TToggleBox;
    tbmyAll: TToggleBox;
    tbmyAlrt: TToggleBox;
    tbFollow: TToggleBox;
    tbTCAlert: TToggleBox;
    tmrFollow: TTimer;
    tmrCqPeriod: TTimer;
    WsjtxMemo: TRichMemo;
    procedure btFTxtNClick(Sender: TObject);
    procedure cbflwChange(Sender: TObject);
    procedure chkHistoryChange(Sender: TObject);
    procedure chkMapChange(Sender: TObject);
    procedure cmAnyClick(Sender: TObject);
    procedure cmBandClick(Sender: TObject);
    procedure cmCqDxClick(Sender: TObject);
    procedure cmFontClick(Sender: TObject);
    procedure cmHereClick(Sender: TObject);
    procedure cmNeverClick(Sender: TObject);
    procedure EditAlertEnter(Sender: TObject);
    procedure EditAlertExit(Sender: TObject);
    procedure edtFollowCallEnter(Sender: TObject);
    procedure edtFollowCallExit(Sender: TObject);
    procedure edtFollowCallKeyDown(Sender: TObject; var Key: word;
      Shift: TShiftState);
    procedure edtFollowDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure noTxtChange(Sender: TObject);
    procedure tbAlertChange(Sender: TObject);
    procedure tbFollowChange(Sender: TObject);
    procedure tbLocAlertChange(Sender: TObject);
    procedure tbmyAllChange(Sender: TObject);
    procedure tbmyAlrtChange(Sender: TObject);
    procedure tbTCAlertChange(Sender: TObject);
    procedure tmrCqPeriodTimer(Sender: TObject);
    procedure tmrFollowTimer(Sender: TObject);
    procedure WsjtxMemoDblClick(Sender: TObject);
  private
    procedure FocusLastLine;
    procedure AddColorStr(s: string; const col: TColor = clBlack);
    procedure RunVA(Afile: string);
    procedure WsjtxMemoScroll;
    procedure decodetest(i: boolean);
    procedure PrintCall(Pcall: string);  // prints colored call
    procedure PrintLoc(PLoc, tTa, mT: string);  // prints colored loc
    function OkCall(Call: string): boolean;
    procedure SendReply(reply: string);
    procedure TryCallAlert(S: string);
    procedure TryAlerts;
    procedure SaveFormPos(FormMode: string);
    procedure LoadFormPos(FormMode: string);
    procedure CqPeriodTimerStart;
    { private declarations }
  public
    procedure CleanWsjtxMemo;
    function NextElement(Message: string; var index: integer): string;
    procedure AddDecodedMessage(Message, Band, Reply: string; Dfreq: integer);
    procedure AddFollowedMessage(Message, Reply: string);
    procedure AddOtherMessage(Message, Reply: string);
    procedure NewBandMode(Band, Mode: string);
    procedure SendFreeText(MyText: string);

    { public declarations }
  end;

const
  MaxLines: integer = 41;        //Max monitor lines text will show MaxLines-1 lines
  CountryLen = 15;               //length of printed country name in monitor
  CallLen = 10;               //max len of callsign
  Sdelim = ',';              //separator of several text alerts

type
  TReplyArray = array of string [255];

var
  frmMonWsjtx: TfrmMonWsjtx;
  RepArr: TReplyArray;  //static array for reply strings: set max same as MaxLines
  LastWsjtLineTime: string;                  //time of last printed line
  myAlert: string;
  //alert name moved to script as 1st parameter
  //can be:'my'= ansver to my cq,
  //       'loc'=new main grid,
  //       'text'= text given is found from new monitor line
  timeToAlert: string;                  //only once per event per minute
  MonitorLine: string;                  // complete line as printed to monitor

  extCqCall: Tcolor = $000055FF;    // extended cq (cq dx, cq na etc.) color
  wkdhere: Tcolor;
  wkdband: Tcolor;
  wkdany: Tcolor;
  wkdnever: Tcolor;
  EditedText: string;
  //holds editAlert after finished (loose focus)
  Ssearch, Sfull: string;
  Spos: integer;
  RepFlw: string [255];
  //reply in case of follow line double click

  msgCall: string;
  msgLoc: string;
  msgTime: string;
  isMyCall: boolean;
  CurMode: string = '';
  CurBand: string = '';
  LockMap: boolean;
  LockFlw: boolean;


implementation

{$R *.lfm}

{ TfrmMonWsjtx }

uses fNewQSO, dData, dUtils, dDXCC, fWorkedGrids, uMyini;

procedure TfrmMonWsjtx.RunVA(Afile: string);
const
  cAlert = 'voice_keyer/voice_alert.sh';
var
  AProcess: TProcess;
begin
  if not FileExists(dmData.HomeDir + cAlert) then
    exit;

  AProcess := TProcess.Create(nil);
  try
    AProcess.CommandLine := 'bash ' + dmData.HomeDir + cAlert + ' ' + Afile;
    if dmData.DebugLevel >= 1 then
      Writeln('Command line: ', AProcess.CommandLine);
    AProcess.Execute
  finally
    AProcess.Free
  end;
end;

procedure TfrmMonWsjtx.AddColorStr(s: string; const col: TColor = clBlack);
var
  i: integer;
begin
  for i := 1 to length(s) do
  begin
    if ((Ord(s[i]) >= 32) and (Ord(s[i]) <= 122)) then   //from space to z accepted
      MonitorLine := MonitorLine + s[i];
  end;
  if not frmMonWsjtx.noTxt.Checked then
    with WsjtxMemo do
    begin
      if s <> '' then
      begin
        SelStart := Length(Text);
        SelText := s;
        SelLength := Length(s);
        if col = wkdnever then
          SetRangeParams(SelStart, SelLength, [tmm_Styles, tmm_Color],
            '', 0, col, [fsBold], [])
        else
          SetRangeColor(SelStart, SelLength, col);
        // deselect inserted string and position cursor at the end of the text
        SelStart := Length(Text);
        SelText := '';
      end;
      //FocusLastLine;
    end;

end;

procedure TfrmMonWsjtx.CleanWsjtxMemo;

var
  l: integer;
begin
  WsjtxMemo.Lines.Clear;
  for l := 0 to Maxlines - 1 do
    RepArr[l] := '';
end;

procedure TfrmMonWsjtx.FocusLastLine;
begin
  with WsjtxMemo do
  begin
    SelStart := GetTextLen;
    SelLength := 0;
    ScrollBy(0, Lines.Count);
    Refresh;
  end;
end;

procedure TfrmMonWsjtx.WsjtxMemoScroll;
var
  i: integer;
begin
  with WsjtxMemo do
  begin
    //scroll buffer if needed
    if Lines.Count >= MaxLines then
    begin
      repeat
        Lines.Delete(0);
        for i := 0 to MaxLines - 2 do
          RepArr[i] := RepArr[i + 1];
      until Lines.Count <= Maxlines;
      RepArr[MaxLines - 1] := '';
      FocusLastLine;
    end;
  end;
end;

procedure TfrmMonWsjtx.SendReply(reply: string);
var
  i: byte;
begin
  if (length(reply) > 11) and (reply[12] = #$02) then //we should have proper reply
  begin
    reply[12] := #$04;    //quick hack: change message type from 2 to 4
    if dmData.DebugLevel >= 1 then
      Writeln('Changed message type from 2 to 4. Sending...');
    frmNewQSO.Wsjtxsock.SendString(reply);
    {if dmData.DebugLevel >= 1 then
    begin
      Write('Send data buffer contains:');
      for i := 1 to length(reply) do
       Begin
        Write('x', HexStr(Ord(reply[i]), 2));
        if ((reply[i] > #32) and (reply[i]< #127)) then
           write('/',reply[i]) else write('/_');
       end;
      writeln();
    end;}
  end;
end;

procedure TfrmMonWsjtx.WsjtxMemoDblClick(Sender: TObject);
var
  i: byte;
begin
  if dmData.DebugLevel >= 1 then
  begin
    Write('Clicked line no:', WsjtxMemo.Caretpos.Y, ' Array gives:');
    for i := 1 to length(RepArr[WsjtxMemo.Caretpos.Y]) do
      Write('x', HexStr(Ord(RepArr[WsjtxMemo.Caretpos.Y][i]), 2));
    writeln();
  end;
  SendReply(RepArr[WsjtxMemo.Caretpos.Y]);
end;

procedure TfrmMonWsjtx.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  LockMap := True;
  if chkMap.Checked then
    SaveFormPos('Map')
  else
    SaveFormPos('Cq');  //to be same as intial save
  dmUtils.SaveWindowPos(frmMonWsjtx);
end;

procedure TfrmMonWsjtx.cmNeverClick(Sender: TObject);
begin
  popColorDlg.Color := wkdNever;
  popColorDlg.Title := 'Qso never before - color';
  if popColorDlg.Execute then
  begin
    wkdNever := (popColorDlg.Color);
    cqrini.WriteString('MonWsjtx', 'wkdnever', ColorToString(wkdnever));
  end;
end;

procedure TfrmMonWsjtx.EditAlertEnter(Sender: TObject);
begin
  tbAlert.Checked := False;
end;

procedure TfrmMonWsjtx.EditAlertExit(Sender: TObject);
begin
  cqrini.WriteString('MonWsjtx', 'TextAlert', EditAlert.Text);
  cqrini.WriteBool('MonWsjtx', 'Follow', tbFollow.Checked);
  EditAlert.Text := trim(EditAlert.Text);
  EditedText := EditAlert.Text;
end;


procedure TfrmMonWsjtx.edtFollowCallEnter(Sender: TObject);
begin
  tbFollow.Checked := False;
  edtFollowCall.Clear;
end;

procedure TfrmMonWsjtx.edtFollowCallExit(Sender: TObject);
begin
  edtFollowCall.Text := trim(UpperCase(edtFollowCall.Text));   //sure upcase-trimmed
  cqrini.WriteString('MonWsjtx', 'FollowCall', edtFollowCall.Text);
end;

procedure TfrmMonWsjtx.edtFollowCallKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
begin
  if key = 13 then
  begin
    key := 0;
    tbFollow.SetFocus;
    tbFollow.Checked := True;
  end;
end;

procedure TfrmMonWsjtx.SendFreeText(MyText: string);
var
  Sbuf: string;
  i: byte;
begin
  if (length(MyText) > 13) then
    MyText := copy(MyText, 1, 13); //free text max len 13
  if frmNewQSO.RepHead <> '' then
  begin
    Sbuf := frmNewQSO.RepHead;
    Sbuf[12] := #9; //Free Text command
    Sbuf := Sbuf + #0 + #0 +#0 + chr(length(MyText)) + MyText + #0;
   { if dmData.DebugLevel >= 1 then
    begin
      Write('Free text buffer contains:');
      for i := 1 to length(SBuf) do
       Begin
        Write('x', HexStr(Ord(SBuf[i]), 2));
        if ((SBuf[i] > #32) and (Sbuf[i]< #127)) then
           write('/',SBuf[i]) else write('/_');
       end;
      writeln();
    end;}
    frmNewQSO.Wsjtxsock.SendString(Sbuf);
  end;
end;

procedure TfrmMonWsjtx.edtFollowDblClick(Sender: TObject);
begin
  if dmData.DebugLevel >= 1 then
    Writeln('Clicked follow line gives: ', RepFlw);
  SendReply(RepFlw);
end;

procedure TfrmMonWsjtx.cmBandClick(Sender: TObject);
begin
  popColorDlg.Color := wkdBand;
  popColorDlg.Title := 'Qso on this band, but not this mode - color';
  if popColorDlg.Execute then
  begin
    wkdBand := (popColorDlg.Color);
    cqrini.WriteString('MonWsjtx', 'wkdband', ColorToString(wkdband));
  end;

end;

procedure TfrmMonWsjtx.cmAnyClick(Sender: TObject);
begin
  popColorDlg.Color := wkdAny;
  popColorDlg.Title := 'Qso on some other band/mode - color';
  if popColorDlg.Execute then
  begin
    wkdAny := (popColorDlg.Color);
    cqrini.WriteString('MonWsjtx', 'wkdany', ColorToString(wkdany));
  end;

end;

procedure TfrmMonWsjtx.cmHereClick(Sender: TObject);
begin
  popColorDlg.Color := wkdHere;
  popColorDlg.Title := 'Qso on this band and mode - color';
  if popColorDlg.Execute then
  begin
    wkdHere := (popColorDlg.Color);
    cqrini.WriteString('MonWsjtx', 'wkdhere', ColorToString(wkdhere));
  end;

end;

procedure TfrmMonWsjtx.chkHistoryChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx', 'NoHistory', chkHistory.Checked);
end;

procedure TfrmMonWsjtx.SaveFormPos(FormMode: string);

begin
  if dmData.DebugLevel >= 1 then
    Writeln('---------------------------------------SaveFormPos:', FormMode);
  if frmMonWsjtx.WindowState = wsMaximized then
    cqrini.WriteBool('MonWsjtx', FormMode + 'Max', True)
  else
  begin
    cqrini.WriteInteger('MonWsjtx', FormMode + 'Height', frmMonWsjtx.Height);
    cqrini.WriteInteger('MonWsjtx', FormMode + 'Width', frmMonWsjtx.Width);
    cqrini.WriteInteger('MonWsjtx', FormMode + 'Top', frmMonWsjtx.Top);
    cqrini.WriteInteger('MonWsjtx', FormMode + 'Left', frmMonWsjtx.Left);
    cqrini.WriteBool('MonWsjtx', FormMode + 'Max', False);
  end;
end;

procedure TfrmMonWsjtx.LoadFormPos(FormMode: string);
begin
  if dmData.DebugLevel >= 1 then
    Writeln('---------------------------------------LoadFormPos:', FormMode);
  if cqrini.ReadBool('MonWsjtx', FormMode + 'Max', False) then
    frmMonWsjtx.WindowState := wsMaximized
  else
  begin
    frmMonWsjtx.Height := cqrini.ReadInteger('MonWsjtx', FormMode + 'Height', 100);
    frmMonWsjtx.Width := cqrini.ReadInteger('MonWsjtx', FormMode + 'Width', 100);
    frmMonWsjtx.Top := cqrini.ReadInteger('MonWsjtx', FormMode + 'Top', 20);
    frmMonWsjtx.Left := cqrini.ReadInteger('MonWsjtx', FormMode + 'Left', 20);
  end;
end;

procedure TfrmMonWsjtx.chkMapChange(Sender: TObject);
var
  i: integer;
begin
  if not LockMap then    //do not run autaomaticly on init or leave form
  begin
    cqrini.WriteBool('MonWsjtx', 'MapMode', chkMap.Checked);
    if chkMap.Checked then
    begin   //Map
      //write width/height CQ read width Map
      if Sender <> frmMonWsjtx then
        SaveFormPos('Cq');  //no save from init
      LoadFormPos('Map');
      LockFlw := True;
      cbflw.Checked := False;
      //drops panel size reservation. Map drops "follow" it does not return ON  when back to monitor mode
      LockFlw := False;
      frmMonWsjtx.Caption := 'Wsjt-x map';
      pnlFollow.Visible := False;
      pnlAlert.Visible := False;
      cbflw.Visible := False;
      noTxt.Visible := False;
      noTxt.Checked := False;
      //map mode allows text, no mind without printing. Printing stays on return to monitor mode.
      chkHistory.Visible := False;
    end
    else
    begin   //Cq
      //write width/height Map read width CQ
      if Sender <> frmMonWsjtx then
        SaveFormPos('Map');   //no save from init
      LoadFormPos('Cq');
      cbflw.Checked := cqrini.ReadBool('MonWsjtx', 'FollowShow', False);
      tbFollow.Checked := cqrini.ReadBool('MonWsjtx', 'Follow', False);
      frmMonWsjtx.Caption := 'Wsjt-x CQ-monitor';
      pnlAlert.Visible := True;
      cbflw.Visible := True;
      noTxt.Visible := True;
      chkHistory.Visible := True;
    end;
    CleanWsjtxMemo;
  end;
end;


procedure TfrmMonWsjtx.cbflwChange(Sender: TObject);
begin
  if not LockFlw then
    cqrini.WriteBool('MonWsjtx', 'FollowShow', cbflw.Checked);
  if cbflw.Checked then
  begin
    WsjtxMemo.BorderSpacing.Bottom := 96;
    pnlFollow.Visible := True;
    edtFollow.Text := '';
    ;
  end
  else
  begin
    tbFollow.Checked := False;
    WsjtxMemo.BorderSpacing.Bottom := 51;
    pnlFollow.Visible := False;
  end;
end;

procedure TfrmMonWsjtx.btFTxtNClick(Sender: TObject);
var
  My: string;
begin
  if frmNewQSO.edtName.Text <> '' then
  begin
    My := Upcase('Tu ' + frmNewQSO.edtName.Text + ' 73');
    if length(My) < 14 then
    begin
      SendFreeText(My);
      if dmData.DebugLevel >= 1 then
        Writeln('Sent Free text>', My, '<');
    end
    else
    btFTxtN.Visible:=false;
  end;
end;

procedure TfrmMonWsjtx.noTxtChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx', 'NoTxt', noTxt.Checked);
end;

procedure TfrmMonWsjtx.tbAlertChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx', 'TextAlertSet', tbAlert.Checked);
  if tbAlert.Checked then
  begin
    tbAlert.Font.Color := clGreen;
    tbAlert.Font.Style := [fsBold];
    if tbTCAlert.Checked then
    begin
      EditAlert.Text := trim(UpperCase(EditAlert.Text));
      EditedText := EditAlert.Text;
    end;
  end
  else
  begin
    tbAlert.Font.Color := clRed;
    tbAlert.Font.Style := [];
  end;
end;

procedure TfrmMonWsjtx.tbFollowChange(Sender: TObject);
begin
  if not LockFlw then
    cqrini.WriteBool('MonWsjtx', 'Follow', tbFollow.Checked);
  if tbFollow.Checked then
  begin
    tbFollow.Font.Color := clGreen;
    tbFollow.Font.Style := [fsBold];
  end
  else
  begin
    tbFollow.Font.Color := clRed;
    tbFollow.Font.Style := [];
    edtFollow.Text := '';
  end;
end;

procedure TfrmMonWsjtx.tbLocAlertChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx', 'LocAlert', tbLocAlert.Checked);
  if tbLocAlert.Checked then
  begin
    tbLocAlert.Font.Color := clGreen;
    tbLocAlert.Font.Style := [fsBold];
  end
  else
  begin
    tbLocAlert.Font.Color := clRed;
    tbLocAlert.Font.Style := [];
  end;
end;

procedure TfrmMonWsjtx.tbmyAllChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx', 'MyAll', tbmyAll.Checked);
  if tbmyAll.Checked then
  begin
    tbmyAll.Font.Color := clGreen;
    tbmyAll.Font.Style := [fsBold];
  end
  else
  begin
    tbmyAll.Font.Color := clRed;
    tbmyAll.Font.Style := [];
  end;
end;

procedure TfrmMonWsjtx.tbmyAlrtChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx', 'MyAlert', tbmyAlrt.Checked);
  if tbmyAlrt.Checked then
  begin
    tbmyAlrt.Font.Color := clGreen;
    tbmyAlrt.Font.Style := [fsBold];
  end
  else
  begin
    tbmyAlrt.Font.Color := clRed;
    tbmyAlrt.Font.Style := [];
  end;
end;

procedure TfrmMonWsjtx.tbTCAlertChange(Sender: TObject);
begin
  cqrini.WriteBool('MonWsjtx', 'TextAlertCall', tbTCAlert.Checked);
  tbAlert.Checked := False;   //drop alert off if text/call change
  if tbTCAlert.Checked then
  begin
    tbTCAlert.SetTextBuf('Call');
    EditAlert.Text := trim(UpperCase(EditAlert.Text));   //sure upcase-trimmed
    EditedText := EditAlert.Text;
  end
  else
  begin
    tbTCAlert.SetTextBuf('Text');
  end;
end;

procedure TfrmMonWsjtx.tmrCqPeriodTimer(Sender: TObject);
begin
  tmrCqPeriod.Enabled := False;
  if (chkHistory.Checked) then
    WsjtxMemo.SetRangeColor(0, length(WsjtxMemo.Text), clSilver);

end;

procedure TfrmMonWsjtx.tmrFollowTimer(Sender: TObject);
begin
  tmrFollow.Enabled := False;
  if tbFollow.Checked then
    edtFollow.Font.Color := clSilver;
end;

procedure TfrmMonWsjtx.CqPeriodTimerStart;
begin
  tmrCqPeriod.Enabled := False;
  if CurMode = 'FT8' then
    tmrCqPeriod.Interval := 16000
  else
    tmrCqPeriod.Interval := 61000;
  tmrCqPeriod.Enabled := True;
end;

procedure TfrmMonWsjtx.cmCqDxClick(Sender: TObject);
begin
  popColorDlg.Color := extCqCall;
  popColorDlg.Title := 'Extended CQ (DX, NA, SA ...) - color';
  if popColorDlg.Execute then
    extCqCall := (popColorDlg.Color);
  cqrini.WriteString('MonWsjtx', 'extCqCall', ColorToString(extCqCall));
end;

procedure TfrmMonWsjtx.cmFontClick(Sender: TObject);
begin
  popFontDlg.Font.Name := cqrini.ReadString('MonWsjtx', 'Font', 'Monospace');
  popFontDlg.Font.Size := cqrini.ReadInteger('MonWsjtx', 'FontSize', 10);
  popFontDlg.Title := 'Use monospace fonts, style is ignored';
  if popFontDlg.Execute then
  begin
    cqrini.WriteString('MonWsjtx', 'Font', popFontDlg.Font.Name);
    cqrini.WriteInteger('MonWsjtx', 'FontSize', popFontDlg.Font.Size);
    WsjtxMemo.Font.Name := popFontDlg.Font.Name;
    WsjtxMemo.Font.Size := popFontDlg.Font.Size;
    edtFollow.Font.Name := popFontDlg.Font.Name;
    edtFollow.Font.Size := popFontDlg.Font.Size;
    CleanWsjtxMemo;
    edtFollow.Text := '';
  end;
end;

procedure TfrmMonWsjtx.FormCreate(Sender: TObject);
begin
  LockMap := True;
  SetLength(RepArr, MaxLines); //set reply buffer to maxlines
  EditAlert.Text := '';
  EditedText := '';
  LastWsjtLineTime := '';
end;

procedure TfrmMonWsjtx.FormHide(Sender: TObject);
begin
  //decodetest(true);  //release these for decode tests
  //decodetest(false);
  LockMap := True;
  if chkMap.Checked then
    SaveFormPos('Map')
  else
    SaveFormPos('Cq');  //to be same as intial save
  dmUtils.SaveWindowPos(frmMonWsjtx);
  frmMonWsjtx.hide;
end;

procedure TfrmMonWsjtx.FormShow(Sender: TObject);
begin
  WsjtxMemo.Font.Name := cqrini.ReadString('MonWsjtx', 'Font', 'Monospace');
  WsjtxMemo.Font.Size := cqrini.ReadInteger('MonWsjtx', 'FontSize', 10);
  dmUtils.LoadWindowPos(frmMonWsjtx);
  dmUtils.LoadFontSettings(frmMonWsjtx);
  chkHistory.Checked := cqrini.ReadBool('MonWsjtx', 'NoHistory', False);
  noTxt.Checked := cqrini.ReadBool('MonWsjtx', 'NoTxt', False);
  tbmyAlrt.Checked := cqrini.ReadBool('MonWsjtx', 'MyAlert', False);
  tbmyAll.Checked := cqrini.ReadBool('MonWsjtx', 'MyAll', False);
  tbLocAlert.Checked := cqrini.ReadBool('MonWsjtx', 'LocAlert', False);
  EditAlert.Text := cqrini.ReadString('MonWsjtx', 'TextAlert', '');
  EditedText := EditAlert.Text;
  tbAlert.Checked := cqrini.ReadBool('MonWsjtx', 'TextAlertSet', False);
  tbTCAlert.Checked := cqrini.ReadBool('MonWsjtx', 'TextAlertCall', False);
  wkdhere := StringToColor(cqrini.ReadString('MonWsjtx', 'wkdhere', 'clRed'));
  wkdband := StringToColor(cqrini.ReadString('MonWsjtx', 'wkdband', 'clFuchsia'));
  wkdany := StringToColor(cqrini.ReadString('MonWsjtx', 'wkdany', 'clMaroon'));
  wkdnever := StringToColor(cqrini.ReadString('MonWsjtx', 'wkdnever', 'clGreen'));
  extCqCall := StringToColor(cqrini.ReadString('MonWsjtx', 'extCqCall', '$000055FF'));
  edtFollow.Font.Name := WsjtxMemo.Font.Name;
  edtFollow.Font.Size := WsjtxMemo.Font.Size;
  cbflw.Checked := cqrini.ReadBool('MonWsjtx', 'FollowShow', False);
  tbFollow.Checked := cqrini.ReadBool('MonWsjtx', 'Follow', False);
  edtFollowCall.Text := uppercase(cqrini.ReadString('MonWsjtx', 'FollowCall', ''));
  chkMap.Checked := cqrini.ReadBool('MonWsjtx', 'MapMode', False);
  if ((trim(edtFollowCall.Text) = '') and tbFollow.Checked) then
    tbFollow.Checked := False; //should not happen, chk it here
  LockFlw := False;
  LockMap := False; //last thing to do
  chkMapChange(frmMonWsjtx);
  btFTxtN.Visible := False;
end;

procedure TfrmMonWsjtx.NewBandMode(Band, Mode: string);

begin
  lblBand.Caption := Band;
  lblMode.Caption := Mode;
  CurBand := Band;
  CurMode := Mode;
  CleanWsjtxMemo;
  edtFollow.Text := '';
end;

function TfrmMonWsjtx.NextElement(Message: string; var index: integer): string;
  //detach next element from Message. Move index pointer, do not touch message string itself

begin
  Result := '';
  if Message <> '' then
  begin
    while (Message[index] = ' ') and (index <= length(Message)) do
      Inc(index);
    while (Message[index] <> ' ') and (index <= length(Message)) do
    begin
      Result := Result + Message[index];
      Inc(index);
    end;
    UpperCase(trim(Result));  //to be surely fixed
  end;

  if dmData.DebugLevel >= 1 then
    Writeln('Result:', Result, ' index of msg:', index);
end;
//-----------------------------------------------------------------------------------------
procedure TfrmMonWsjtx.decodetest(i: boolean);           // run execptions for debug
begin
  //split message it can be: (note: when testing remember continent compare set calls to be non dx]
  if (i) then
  begin
    AddDecodedMessage('175200 # CQ OH1LL KP11', '20M', 'reply', 0);      //normal cq
    AddDecodedMessage('175200 @ CQ DX OH1DX KP11', '20M', 'reply', 0);   //directed cq
    AddDecodedMessage('175200 @ CQ NA RV3NA', '20M', 'reply', 0);
    //call and continents/prefixes  no loc
    AddDecodedMessage('175200 @ CQ USA RV3USA', '20M', 'reply', 0);
    //call and continents/prefixes
    AddDecodedMessage('175200 @ CQ USA RV3USL KO30', '20M', 'reply', 0);
    //call and continents/prefixes
    AddDecodedMessage('175200 @ CQ OH1LL DX', '20M', 'reply', 0);
    //old official cq dx
    AddDecodedMessage('175200 # OF1KH CA1LL AA11', '20M', 'reply', 0);
    //set first you log call
    AddDecodedMessage('175200 # CQ 000 PA7ZZ JO22', '20M', 'reply', 0);
    //!where?" decodes now ok.
    AddDecodedMessage('175200 ~ CQ NO EU RZ3DX', '20M', 'reply', 0);  // for dbg
    AddDecodedMessage('201045 ~ CQ KAZAKHSTAN', '20M', 'reply', 0);
    // yet another bright cq idea of users
    AddDecodedMessage('201045 ~ CQ WHO EVER', '20M', 'reply', 0);
    // a guess for next idea
  end
  else
  begin
    ShowMessage('Test with CQ extensions:' + sLineBreak +
      '175200 # CQ OH1LL KP11' + sLineBreak + '175200 @ CQ DX OH1DX KP11' + sLineBreak +
      '175200 @ CQ NA RV3NA' + sLineBreak + '175200 @ CQ USA RV3USA' + sLineBreak +
      '175200 @ CQ USA RV3USL KO30' + sLineBreak + '175200 @ CQ OH1LL DX' + sLineBreak +
      '175200 # OF1KH CA1LL AA11' + sLineBreak +
      '175200 # CQ 000 PA7ZZ JO22' + sLineBreak +
      '175200 ~ CQ NO EU RZ3DX' + sLineBreak + '201045 ~ CQ KAZAKHSTAN' + sLineBreak +
      '201045 ~ CQ WHO EVER');  // for dbg
  end;
end;

procedure TfrmMonWsjtx.AddOtherMessage(Message, Reply: string);
var
  List1: TStringList;
begin
  btFTxtN.Visible := ((frmNewQSO.RepHead <> '') and (frmNewQSO.edtName.Text <> ''));
  if (frmMonWsjtx.tbFollow.Checked and (pos(edtFollowCall.Text, Message) > 0)) then
    //first check
    AddFollowedMessage(Message, Reply)
  else
  if chkMap.Checked then
  begin
    CqPeriodTimerStart;
    if dmData.DebugLevel >= 1 then
      Writeln('Other line:', Message);
    msgCall := '';
    msgLoc := '';
    isMyCall := False;
    List1 := TStringList.Create;
    try
      List1.Delimiter := ' ';
      List1.DelimitedText := Message;
      //without IFs you get easily out of bounds when unexpected decode results happen
      if (List1.Count > 0) then
        msgTime := List1[0];
      // if (List1.Count > 1) then deltafreq:=List1[1]
      if (List1.Count > 2) then
        isMyCall := pos(List1[2], UpperCase(cqrini.ReadString('Station', 'Call', ''))) > 0;
      if (List1.Count > 3) then
        msgCall := List1[3];
      if dmData.DebugLevel >= 1 then
        Writeln('List index:', List1.Count);
      if (List1.Count > 4) then
        msgLoc := List1[4] //avoid out of index in certain compound call lines
    finally
      List1.Free;
    end;
    if dmData.DebugLevel >= 1 then
      Writeln('Other call:', msgCall, '    loc:', msgLoc);
    if (not frmWorkedGrids.GridOK(msgLoc)) or (msgLoc = 'RR73') then
      //disble false used "RR73" being a loc
      msgLoc := '';

    if OkCall(msgCall) then
    begin
      myAlert := '';
      MonitorLine := '';

      if (msgTime <> LastWsjtLineTime) then
        CleanWsjtxMemo;
      LastWsjtLineTime := msgTime;
      if dmData.DebugLevel >= 1 then
        Writeln('Add reply array:', WsjtxMemo.Lines.Count);
      RepArr[WsjtxMemo.Lines.Count] := Reply;  //corresponding reply string to array
      //start printing
      AddColorStr(#40, clDefault);  //make not-CQ indicator start
      if dmData.DebugLevel >= 1 then
        Writeln('Start Other printing');
      PrintCall(msgCall);
      if msgLoc = '' then
      begin
        AddColorStr(#32#32#32#32#41#13#10, clDefault);
        //make not-CQ indicator stop + new line
      end
      else
      begin
        PrintLoc(msgLoc, '', '');
        AddColorStr(#41#13#10, clDefault);  //make not-CQ indicator stop + new line
      end;
      if dmData.DebugLevel >= 1 then
        Writeln('NL written and scroll if needed+alerts');
      WsjtxMemoScroll; // if neeeded
      TryAlerts;
    end;
  end;

end;

procedure TfrmMonWsjtx.AddFollowedMessage(Message, Reply: string);
var
  a: TExplodeArray;
  i, b: integer;
  ok: boolean;
begin
  if dmData.DebugLevel >= 1 then
    writeln('Follow stage#1 passed:', Message);
  b := 0;
  SetLength(a, 0);
  a := dmUtils.Explode(' ', Message);
  for i := 0 to (Length(a) - 1) do
    if (edtFollowCall.Text = a[i]) then
      b := i;
  writeln('Follow stage#2 result. Found at:', b + 1, '  LastItem:', i + 1);
  if ((i = 2) and (b = 2)   //message is just time[0] dfreq[1] and followcall[2]
    or (i > 2) and (b > 2))
  //message is time[0] dfreq[1] and call[2] followcall[3]..[or up]
  then
  begin
    tmrFollow.Enabled := False;
    if CurMode = 'FT8' then
      tmrFollow.Interval := 16000
    else
      tmrFollow.Interval := 61000;
    tmrFollow.Enabled := True;
    edtFollow.Font.Color := clDefault;
    edtFollow.Text := Message;
    RepFlw := Reply;
  end;
end;

procedure TfrmMonWsjtx.PrintCall(Pcall: string);
begin
  case frmWorkedGrids.WkdCall(msgCall, CurBand, CurMode) of
    0: AddColorStr(PadRight(UpperCase(msgCall), CallLen) + ' ', wkdnever);
    1: AddColorStr(PadRight(LowerCase(msgCall), CallLen) + ' ', wkdhere);
    2: AddColorStr(PadRight(UpperCase(msgCall), CallLen) + ' ', wkdband);
    3: AddColorStr(PadRight(UpperCase(msgCall), CallLen) + ' ', wkdany);
    else
      AddColorStr(PadRight(LowerCase(msgCall), CallLen) + ' ', clDefault);
      //should not happen
  end;

end;

procedure TfrmMonWsjtx.PrintLoc(PLoc, tTa, mT: string);
begin
  case frmWorkedGrids.WkdGrid(msgLoc, CurBand, CurMode) of
    //returns 0=not wkd
    //        1=full grid this band and mode
    //        2=full grid this band but NOT this mode
    //        3=full grid any other band/mode
    //        4=main grid this band and mode
    //        5=main grid this band but NOT this mode
    //        6=main grid any other band/mode
    0:
    begin
      AddColorStr(UpperCase(msgLoc), wkdnever); //not wkd
      if tbLocAlert.Checked and (tTa <> mT) then
        myAlert := 'loc';    //locator alert
    end;
    1: AddColorStr(lowerCase(msgLoc), wkdhere); //grid wkd
    2: AddColorStr(UpperCase(msgLoc), wkdband); //grid wkd band
    3: AddColorStr(UpperCase(msgLoc), wkdany); //grid wkd any
    4:
    begin
      AddColorStr(lowerCase(copy(msgLoc, 1, 2)), wkdhere); //maingrid wkd
      AddColorStr(copy(msgLoc, 3, 2), wkdnever);
    end;
    5:
    begin
      AddColorStr(UpperCase(copy(msgLoc, 1, 2)), wkdband); //maingrid wkd band
      AddColorStr(copy(msgLoc, 3, 2), wkdnever);
    end;
    6:
    begin
      AddColorStr(UpperCase(copy(msgLoc, 1, 2)), wkdany); //maingrid wkd any
      AddColorStr(copy(msgLoc, 3, 2), wkdnever);
    end;
    else
      AddColorStr(lowerCase(msgLoc), clDefault); //should not happen
  end;
end;

function TfrmMonWsjtx.OkCall(Call: string): boolean;
var
  HasNum, HasChr: boolean;
  i: integer;
begin
  i := 0;
  HasNum := False;
  HasChr := False;
  if (Call <> '') then
  begin
    repeat
      begin
        Inc(i);
        if ((Call[i] >= '0') and (Call[i] <= '9')) then
          HasNum := True;
        if ((Call[i] >= 'A') and (Call[i] <= 'Z')) then
          HasChr := True;
        if dmData.DebugLevel >= 1 then
          Writeln('CHR Count now:', i, ' len,num,chr:', length(Call), ',', HasNum, ',', HasChr);
      end;
    until (i >= length(Call));
  end;
  OkCall := HasNum and HasChr and (i > 2);
  if dmData.DebugLevel >= 1 then
    Writeln('Call ', call, ' valid: ', OkCall);
end;

procedure TfrmMonWsjtx.TryCallAlert(S: string);

begin
  //if no asterisk, compare as is
  if ((pos('*', S) = 0) and (pos(S, msgCALL) > 0)) then
  begin
    if dmData.DebugLevel >= 1 then
      Write('Text-', S, '-');
    myAlert := 'call'; // overrides locator
  end
  else
  begin     //has asterisk
    //if starts with asterisk remove it and compare right side
    if (LeftStr(S, 1) = '*') then
    begin
      if dmData.DebugLevel >= 1 then
        Write('Right-', S, '-');
      S := copy(S, 2, length(S) - 1);         //asterisk removed, then compare
      if (S = RightStr(msgCall, (length(S)))) then
        myAlert := 'call'; // overrides locator
    end
    else
    begin
      //if ends with asterisk remove it and compare left side
      if (RightStr(S, 1) = '*') then
        S := copy(S, 1, length(S) - 1);  //asterisk removed, then compare
      if (S = LeftStr(msgCall, length(S))) then
        myAlert := 'call'; // overrides locator
      if dmData.DebugLevel >= 1 then
        Write('Left-', S, '-');
    end;
  end;
  if dmData.DebugLevel >= 1 then
    Writeln('compare with:', S, ':results:', myAlert);
end;

procedure TfrmMonWsjtx.TryAlerts;
var
  a: TExplodeArray;
  i: integer;
begin
  if tbAlert.Checked then
  begin
    if tbTCAlert.Checked then
    begin
      if (EditedText <> '') then
      begin
        if dmData.DebugLevel >= 1 then
          Writeln('Alert text search');
        if (pos(Sdelim, EditedText) > 0) then //many variants
        begin
          SetLength(a, 0);
          a := dmUtils.Explode(',', EditedText);
          for i := 0 to Length(a) - 1 do
          begin
            a[i] := trim(a[i]);
            if dmData.DebugLevel >= 1 then
              Writeln('Split text search >', Sfull, '[', i, ']=', a[i]);
            TryCallAlert(a[i]);
          end;
        end
        else
          TryCallAlert(EditedText);
      end;
    end
    else if ((EditedText <> '') and (pos(EditedText, MonitorLine) > 0)) then
      myAlert := 'text'; // overrides locator
  end; // tbAlert
  if (tbmyAlrt.Checked and isMyCall) then
    myAlert := 'my'; //overrides anything else

  if (myAlert <> '') and (timeToAlert <> msgTime) then
  begin
    timeToAlert := msgTime;
    RunVA(myAlert); //play bash script
  end;
end;

procedure TfrmMonWsjtx.AddDecodedMessage(Message, band, Reply: string; Dfreq: integer);

var
  msgMode, msgCQ1, msgCQ2, msgRes, freq, CqDir: string;

  mycont, cont, country, waz, posun, itu, pfx, lat, long: string;

  i, index: integer;
  adif: word;

  CallCqDir,            //CQ caller calling directed call
  HasNum, HasChr: boolean;
  //-----------------------------------------------------------------------------------------
  procedure extcqprint;  //this is used 3 times below
  begin
    AddColorStr(' ' + copy(PadRight(msgRes, CountryLen), 1, CountryLen - 6), extCqCall);
    AddColorStr(' CQ:', clBlack);
    AddColorStr(CqDir + ' ', extCqCall);
  end;

  //-----------------------------------------------------------------------------------------
begin   //TfrmMonWsjtx.AddDecodedMessage

  btFTxtN.Visible := ((frmNewQSO.RepHead <> '') and (frmNewQSO.edtName.Text <> ''));
  CqPeriodTimerStart;

  mycont := '';
  cont := '';
  country := '';
  waz := '';
  posun := '';
  itu := '';
  lat := '';
  long := '';

  myAlert := '';
  MonitorLine := '';
  CallCqDir := False;
  CqDir := '';



  adif := dmDXCC.id_country(
    UpperCase(cqrini.ReadString('Station', 'Call', '')), '', Now(), pfx,
    mycont, country, WAZ, posun, ITU, lat, long);
  if dmData.DebugLevel >= 1 then
    Writeln('Memo Lines count is now:', WsjtxMemo.Lines.Count);
  index := 1;

  if dmData.DebugLevel >= 1 then
    Write('Time-');
  msgTime := NextElement(Message, index);

  if dmData.DebugLevel >= 1 then
    Write('Mode-');
  msgMode := NextElement(Message, index);

  case msgMode of
    chr(36): CurMode := 'JT4';
    '#': CurMode := 'JT65';
    '@': CurMode := 'JT9';
    '&': CurMode := 'MSK144';
    ':': CurMode := 'QRA64';
    '+': CurMode := 'T10';
    chr(126): CurMode := 'FT8';

    else
      CurMode := '';
  end;

  if CurMode <> '' then //mode is known; we can continue
  begin
    if dmData.DebugLevel >= 1 then
      Write('Cq1-'); //this is checked by newQSO to be MYCall or CQ
    msgCQ1 := NextElement(Message, index);
    isMyCall := pos(msgCQ1, UpperCase(cqrini.ReadString('Station',
      'Call', ''))) > 0;
    if dmData.DebugLevel >= 1 then
      Write('Cq2-');
    msgCQ2 := NextElement(Message, index);
    if length(msgCQ2) > 2 then
      // if longer than 2 may be call, otherwise is addition DX AS EU etc.
    begin
      if (OkCall(msgCQ2)) then
      begin // it may be real call
        msgCall := msgCQ2;
        if dmData.DebugLevel >= 1 then
          Writeln('msgCQ2>2(lrs+num) is Call-', 'Result:', msgCall, ' index of msg:', index);
      end
      else
      begin //was shortie, so next must be call
        CallCqDir := True;
        CqDir := msgCQ2;
        if dmData.DebugLevel >= 1 then
        begin
          Writeln('CQ2 had no number+char.');
          Write('Call-');
        end;
        msgCall := NextElement(Message, index);
        //!! if sill no call
        if not (OkCall(msgCall)) then
          msgCall := NextElement(Message, index);
      end;
    end
    else   //length(msgCQ2)<2
    begin
      CallCqDir := True;
      CqDir := msgCQ2;
      if dmData.DebugLevel >= 1 then
      begin
        Writeln('CQ2 length=<2.');
        Write('Call-');
      end;
      msgCall := NextElement(Message, index); //was shortie, so next must be call
      //!! if sill no call
      if not (OkCall(msgCall)) then
        msgCall := NextElement(Message, index);
    end;

    //how ever if we do not have callsign because some crazy cq calling way
    if (msgCall = '') then
      msgCall := 'NOCALL';

    if dmData.DebugLevel >= 1 then
      Writeln('DIR-CQ-call after CQ2:', CallCqDir);
    //so we should have time, mode and call by now. That reamains locator, if exists
    if dmData.DebugLevel >= 1 then
      Write('Loc-');
    msgLoc := NextElement(Message, index);


    if msgLoc = 'DX' then
    begin
      CallCqDir := True; //old std. way to call DX
      CqDir := msgLoc;
    end;
    if dmData.DebugLevel >= 1 then
      Writeln('DIR-CQ-call after old std DX:', CallCqDir);

    if ((length(msgLoc) < 4) or (length(msgLoc) > 4)) then
      //no locator; different than 4,  may be "DX" or something
      msgLoc := '----';
    if length(msgLoc) = 4 then
      if (not frmWorkedGrids.GridOK(msgLoc)) or (msgLoc = 'RR73') then
        //disble false used "RR73" being a loc
        msgLoc := '----';

    if dmData.DebugLevel >= 1 then
      Writeln('LOCATOR IS:', msgLoc);
    if (isMyCall and tbmyAlrt.Checked and tbmyAll.Checked and
      (msgLoc = '----')) then
      msgLoc := '<!!>';//locator for "ALL-MY"

    if not ((msgLoc = '----') and isMyCall) then
      //if mycall: line must have locator to print(I.E. Answer to my CQ)
    begin                                        //and other combinations (CQs) will print, too

      if (chkHistory.Checked or chkMap.Checked) and
        (msgTime <> LastWsjtLineTime) then
        CleanWsjtxMemo;
      LastWsjtLineTime := msgTime;
      RepArr[WsjtxMemo.Lines.Count] := Reply;  //corresponding reply string to array

      //start printing
      if dmData.DebugLevel >= 1 then
        Writeln('Start adding richmemo lines');

      if (not chkMap.Checked) then
      begin
        if (chkHistory.Checked) then
          AddColorStr(PadLeft(IntToStr(Dfreq), 6))
        else
          AddColorStr(msgTime, clDefault); //time
        AddColorStr('  ' + msgMode + ' ', clDefault); //mode
      end;

      if isMyCall then
        AddColorStr('=', wkdnever)
      else
        AddColorStr(' ', wkdnever);  //answer to me
      PrintCall(msgCall);

      if msgLoc = '----' then
        AddColorStr(msgLoc, clDefault) //no loc
      else
        PrintLoc(msgLoc, timeToAlert, msgTime);

      if (not chkMap.Checked) then
      begin
        adif := dmDXCC.id_country(msgCall, '', Now(), pfx, cont,
          msgRes, WAZ, posun, ITU, lat, long);
        if (pos(',', msgRes)) > 0 then
          msgRes := copy(msgRes, 1, pos(',', msgRes) - 1);

        if dmData.DebugLevel >= 1 then
          Writeln('My continent is:', mycont, '  His continent is:', cont);
        if CallCqDir then
          if ((mycont <> '') and (cont <> '')) then
            //we can do some comparisons of continents
          begin
            if ((CqDir = 'DX') and (mycont = cont)) then
            begin
              //I'm not DX for caller: color to warn directed call
              extcqprint;
            end
            else  //calling specified continent
            if ((CqDir <> 'DX') and (CqDir <> mycont)) then
            begin
              //CQ NOT directed to my continent: color to warn directed call
              extcqprint;
            end
            else  // should be ok to answer this directed cq
              AddColorStr(
                ' ' + copy(PadRight(msgRes, CountryLen), 1, CountryLen) + ' ', clBlack);
          end
          else
          begin
            // we can not compare continents, but it is directed cq. Best to warn with color anyway
            extcqprint;
          end
        else
          // should be ok to answer this is not directed cq
          AddColorStr(' ' + copy(PadRight(msgRes, CountryLen), 1, CountryLen) +
            ' ', clBlack);

        freq := dmUtils.FreqFromBand(CurBand, CurMode);
        msgRes := dmDXCC.DXCCInfo(adif, freq, CurMode, i);    //wkd info

        if dmData.DebugLevel >= 1 then
          Writeln('Looking this>', msgRes[1], '< from:', msgRes);
        case msgRes[1] of
          'U': AddColorStr(cont + ':' + msgRes, wkdhere);       //Unknown
          'C': AddColorStr(cont + ':' + msgRes, wkdAny);        //Confirmed
          'Q': AddColorStr(cont + ':' + msgRes, clTeal);        //Qsl needed
          'N': AddColorStr(cont + ':' + msgRes, wkdnever);      //New something

          else
            AddColorStr(msgRes, clDefault);     //something else...can't be
        end;
      end; //Map mode

      AddColorStr(#13#10, clDefault);  //make new line
      WsjtxMemoScroll; // if neeeded

      TryAlerts;

    end;//printing out  line
  end;  //continued
end;



initialization

end.
