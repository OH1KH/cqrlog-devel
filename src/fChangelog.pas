unit fChangelog;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, LazHelpHTML, IpHtml, Ipfilebroker;

type

  { TfrmChangelog }

  TfrmChangelog = class(TForm)
    Button1: TButton;
    IpFileDataProvider1: TIpFileDataProvider;
    IpHtmlPanel1: TIpHtmlPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmChangelog: TfrmChangelog;

implementation

{$R *.lfm}

{ TfrmChangelog }
uses dData;

procedure TfrmChangelog.FormShow(Sender: TObject);
var
  tmp : String;
begin
  tmp := expandLocalHtmlFileName(dmData.ShareDir+'changelog.html');
  IpHtmlPanel1.OpenURL(tmp)
end;

end.

