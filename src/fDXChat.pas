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
    DXChatMemo: TMemo;
    procedure btClearClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MemoChange(Sender: TObject);
    procedure FocusLastLine;
  private
    { private declarations }
  public
    procedure CleanDXChatMemo;
    procedure AddDXChatMemo(ChLine:String);
    { public declarations }
  end;

var
  frmDXChat: TfrmDXChat;
  MaxLines : integer ;

implementation

{ TfrmDXChat }

Uses dUtils,uMyini,dData ;

procedure TfrmDXChat.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   dmUtils.SaveWindowPos(frmDXChat);
end;

procedure TfrmDXChat.btClearClick(Sender: TObject);
begin
    CleanDXChatMemo;
end;

procedure TfrmDXChat.FormCreate(Sender: TObject);
begin
   dmUtils.LoadWindowPos(frmDXChat);
end;

procedure TfrmDXChat.FormHide(Sender: TObject);
begin
   dmUtils.SaveWindowPos(frmDXChat);
   frmDXChat.hide;
end;

procedure TfrmDXChat.FormShow(Sender: TObject);

begin
    MaxLines := 50;
    dmUtils.LoadWindowPos(frmDXChat);
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
  if not frmDXChat.Visible then frmDXChat.Show;
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

