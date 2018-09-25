unit fAbout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, lclintf, ComCtrls, Types;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    Bevel1 : TBevel;
    btnChangelog : TButton;
    btnClose : TButton;
    Image1 : TImage;
    Label1 : TLabel;
    Label2 : TLabel;
    Label3 : TLabel;
    Label5 : TLabel;
    lblLink : TLabel;
    lblVerze : TLabel;
    mContributors : TMemo;
    PageControl1 : TPageControl;
    tabAbout : TTabSheet;
    tabContributors : TTabSheet;
    procedure btnChangelogClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lblLinkClick(Sender: TObject);
    procedure lblLinkMouseEnter(Sender: TObject);
    procedure tabAboutContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  frmAbout: TfrmAbout;

implementation

{$R *.lfm}

{ TfrmAbout }
uses fChangelog, uVersion;

procedure TfrmAbout.lblLinkMouseEnter(Sender: TObject);
begin
  lblLink.Cursor := crHandPoint
end;

procedure TfrmAbout.tabAboutContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TfrmAbout.lblLinkClick(Sender: TObject);
begin
  openURl(lblLink.Caption)
end;

procedure TfrmAbout.btnChangelogClick(Sender: TObject);
begin
  with TfrmChangelog.Create(Application) do
  try
    ShowModal
  finally
    Free
  end
end;

procedure TfrmAbout.FormShow(Sender: TObject);
begin
  lblVerze.Caption := cVERSION + '  ' + cBUILD_DATE
end;

end.

