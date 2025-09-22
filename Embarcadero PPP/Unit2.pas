unit Unit2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Comp.Client, FMX.Controls.Presentation;

type
  TGlavnaForma = class(TForm)
    btnStanjeZaliha: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure btnStanjeZalihaClick(Sender: TObject);
    procedure btnAdministracijaDelovaClick(Sender: TObject);
    procedure btnOdjavaClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    UlogovaniKorisnikID: Integer;
    UlogovanoKorisnickoIme: string;
    FDConnection1: TFDConnection;
  end;

var
  GlavnaForma: TGlavnaForma;

implementation

uses Unit3, Unit4, Unit1;

{$R *.fmx}

procedure TGlavnaForma.FormShow(Sender: TObject);
begin
  Label1.Text := 'Ulogovan korisnik: ' + UlogovanoKorisnickoIme;
end;

procedure TGlavnaForma.btnStanjeZalihaClick(Sender: TObject);
begin
  // ISPRAVLJENO: Siguran način otvaranja forme
  StanjeZalihaForm := TStanjeZalihaForm.Create(nil);
  try
    StanjeZalihaForm.UlogovaniKorisnikID := Self.UlogovaniKorisnikID;
    StanjeZalihaForm.FDConnection1 := Self.FDConnection1;
    StanjeZalihaForm.ShowModal;
  finally
    StanjeZalihaForm.Free;
  end;
end;

procedure TGlavnaForma.btnAdministracijaDelovaClick(Sender: TObject);
begin
  // ISPRAVLJENO: Siguran način otvaranja forme
  AdministracijaForm := TAdministracijaForm.Create(nil);
  try
    AdministracijaForm.UlogovaniKorisnikID := Self.UlogovaniKorisnikID;
    AdministracijaForm.FDConnection1 := Self.FDConnection1;
    AdministracijaForm.ShowModal;
  finally
    AdministracijaForm.Free;
  end;
end;

procedure TGlavnaForma.btnOdjavaClick(Sender: TObject);
begin
  Self.Hide;
  LoginForm.edtKorisnickoIme.Text := '';
  LoginForm.edtLozinka.Text := '';
  LoginForm.Show;
end;

end.
