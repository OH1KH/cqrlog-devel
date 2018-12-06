unit fDXChat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TfrmDXChat }

  TfrmDXChat = class(TForm)
    btClear: TButton;
    btClose: TButton;
    chOnTop: TCheckBox;
    DXChatMemo: TMemo;
    procedure btClearClick(Sender: TObject);
    procedure btCloseClick(Sender: TObject);
    procedure chOnTopChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MemoChange(Sender: TObject);
    procedure FocusLastLine;
  private
    { private declarations }
  public
    chHide   : boolean;
    procedure CleanDXChatMemo;
    procedure AddDXChatMemo(ChLine:String);
    procedure SetFont(Sender: TObject);
     { public declarations }
  end;

var
  frmDXChat: TfrmDXChat;
  MaxLines : integer ;


implementation

{ TfrmDXChat }

Uses dUtils,uMyini,dData,fDXCluster;

procedure TfrmDXChat.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   dmUtils.SaveWindowPos(frmDXChat);
   //cqrini.WriteBool('DXChat', 'Top', frmDXChat.chOnTop.Checked);
   //cqrini.WriteBool('DXChat', 'Hide', chHide);
end;

procedure TfrmDXChat.btClearClick(Sender: TObject);
begin
    CleanDXChatMemo;
end;

procedure TfrmDXChat.btCloseClick(Sender: TObject);
begin
  frmDXChat.Hide;
end;


procedure TfrmDXChat.chOnTopChange(Sender: TObject);
begin
  if chOnTop.Checked then
    FormStyle:=fsSystemStayOnTop
  else
    FormStyle:=fsNormal;
  cqrini.WriteBool('DXChat', 'Top', frmDXChat.chOnTop.Checked);
end;

procedure TfrmDXChat.FormCreate(Sender: TObject);
begin
   MaxLines := 50;
   dmUtils.LoadWindowPos(frmDXChat);
   chOnTop.Checked := cqrini.ReadBool('DXChat', 'Top', false);
   chHide := cqrini.ReadBool('DXChat', 'Hide', false);
end;
procedure TfrmDXChat.SetFont(Sender: TObject);
var
  f : TFont;
begin
    f := TFont.Create;
    dmUtils.LoadWindowPos(frmDXChat);
    dmUtils.LoadFontSettings(frmDXChat);
  try
    f.Name := cqrini.ReadString('DXCluster','Font','DejaVu Sans Mono');
    f.Size := cqrini.ReadInteger('DXCluster','FontSize',12);
    DXChatMemo.Font :=f;
  finally
    f.Free
  end;

end;

procedure TfrmDXChat.FormShow(Sender: TObject);
Begin
  SetFont(nil);
  chOnTop.Checked := cqrini.ReadBool('DXChat', 'Top', false);
  chHide := cqrini.ReadBool('DXChat', 'Hide', false);
end;

procedure TfrmDXChat.CleanDXChatMemo;

Begin
     DXChatMemo.lines.Clear;
end;
procedure TfrmDXChat.FocusLastLine;
begin
   with DXChatMemo do
     begin
      SelStart := GetTextLen;
      SelLength := 0;
      ScrollBy(0, Lines.Count+1);
      Refresh;
     end;
end;

procedure TfrmDXChat.MemoChange(Sender: TObject);
var i: integer;
begin
  //scroll buffer
  if DXChatMemo.lines.count >= MaxLines then
         Begin
          repeat
            DXChatMemo.lines.delete(0);
          until DXChatMemo.lines.count <= Maxlines;
          FocusLastLine;
         end;
end;
procedure TfrmDXChat.AddDXChatMemo(ChLine:String);
var
  l : integer;
begin
 if ChLine[length(ChLine)] <> '>' then    //if not dxcluster prompt
  Begin
  if(( not frmDXChat.Visible ) and (chHide = false ))then frmDXChat.Show; //form closed, but not hided
  //remove "mycall de"
  l := length(cqrini.ReadString('Station', 'Call', ''))+4; //4 = ' DE '
  ChLine := FormatDateTime('hh:nn',Now)+'_'+copy(Chline,l+1,length(Chline)-l);
  if dmData.DebugLevel>=1 then Writeln('Chat :',ChLine);
  DXChatMemo.lines.Add(ChLine);
  FocusLastLine;
 end;
end;
initialization
  {$I fDXChat.lrs}

end.

