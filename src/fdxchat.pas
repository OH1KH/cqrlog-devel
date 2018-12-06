unit fDXChat;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls,jakozememo;

type

  { TfrmDXChat }

  TfrmDXChat = class(TForm)
    DXChatMemo: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    procedure CleanDXChatMemo;
    procedure AddDXChatMemo(ChLine:String);
    { public declarations }
  end;

var
  frmDXChat: TfrmDXChat;
  MaxLines : integer = 100;
  TelChat: Tjakomemo;

implementation

{ TfrmDXChat }

Uses dUtils,uMyini ;

procedure TfrmDXChat.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   dmUtils.SaveWindowPos(frmDXChat);
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
    dmUtils.LoadWindowPos(frmDXChat);
end;

procedure TfrmDXChat.CleanDXChatMemo;

Begin
     DXChatMemo.lines.Clear;
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
  ChLine := copy(Chline,l+1,length(Chline)-l);
  //scroll buffer if needed
  if DXChatMemo.lines.count >= MaxLines then
         Begin
          repeat
            DXChatMemo.lines.delete(0);
          until DXChatMemo.lines.count <= Maxlines;
         end;
  DXChatMemo.lines.Add(ChLine);
 end;
end;
initialization
  {$I fDXChat.lrs}

end.

