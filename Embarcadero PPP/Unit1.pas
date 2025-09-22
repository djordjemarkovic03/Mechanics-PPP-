unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, System.IOUtils,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.FMXUI.Wait, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Phys.SQLiteWrapper.Stat;

type
  TLoginForm = class(TForm)
    edtKorisnickoIme: TEdit;
    edtLozinka: TEdit;
    btnLogin: TButton;
    lblPoruka: TLabel;
    FDConnection1: TFDConnection; // VRAĆENO
    FDQuery1: TFDQuery;           // VRAĆENO
    Label1: TLabel;
    Label2: TLabel;
    procedure btnLoginClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure InicijalizujBazu;
    procedure KreirajTabele;
    procedure UbaciTestPodatke;
  public
    { Public declarations }
  end;

var
  LoginForm: TLoginForm;

implementation

uses Unit2; // Glavna forma

{$R *.fmx}

procedure TLoginForm.FormCreate(Sender: TObject);
begin
  InicijalizujBazu;
end;

procedure TLoginForm.InicijalizujBazu;
var
  DBPath: string;
begin
  DBPath := TPath.Combine(TPath.GetDocumentsPath, 'autoservis_zalihe.db');
  if FDConnection1.Connected then
    FDConnection1.Connected := False;
  FDConnection1.Params.Clear;
  FDConnection1.DriverName := 'SQLite';
  FDConnection1.Params.Add('Database=' + DBPath);
  FDConnection1.Params.Add('LockingMode=Normal');

  if not TFile.Exists(DBPath) then
  begin
    try
      FDConnection1.Connected := True;
      KreirajTabele;
      UbaciTestPodatke;
      ShowMessage('Baza podataka je uspešno kreirana!');
    except
      on E: Exception do ShowMessage('Greška pri kreiranju baze: ' + E.Message);
    end;
  end
  else
  begin
    try
      FDConnection1.Connected := True;
    except
      on E: Exception do ShowMessage('Greška pri povezivanju na bazu: ' + E.Message);
    end;
  end;
end;

procedure TLoginForm.KreirajTabele;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FDConnection1;
    Q.SQL.Text := 'CREATE TABLE Korisnici (KorisnikID INTEGER PRIMARY KEY AUTOINCREMENT, KorisnickoIme TEXT NOT NULL UNIQUE, Lozinka TEXT NOT NULL, ImePrezime TEXT);';
    Q.ExecSQL;
    Q.SQL.Text := 'CREATE TABLE Delovi (DeoID INTEGER PRIMARY KEY AUTOINCREMENT, SifraDela TEXT UNIQUE, NazivDela TEXT NOT NULL, Kolicina INTEGER DEFAULT 0, MinimalnaKolicina INTEGER DEFAULT 5, JedinicaMere TEXT DEFAULT ''kom'');';
    Q.ExecSQL;
    Q.SQL.Text := 'CREATE TABLE EvidencijaPromena (PromenaID INTEGER PRIMARY KEY AUTOINCREMENT, DeoID INTEGER NOT NULL, KorisnikID INTEGER NOT NULL, TipPromene TEXT NOT NULL, StaraKolicina INTEGER, NovaKolicina INTEGER, Promena INTEGER, Napomena TEXT, DatumVreme DATETIME DEFAULT CURRENT_TIMESTAMP);';
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TLoginForm.UbaciTestPodatke;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FDConnection1;
    Q.SQL.Text := 'INSERT INTO Korisnici (KorisnickoIme, Lozinka, ImePrezime) VALUES (''admin'', ''admin'', ''Administrator''), (''serviser'', ''123'', ''Marko Marković'');';
    Q.ExecSQL;
    Q.SQL.Text := 'INSERT INTO Delovi (SifraDela, NazivDela, Kolicina, MinimalnaKolicina) VALUES (''ULJ001'', ''Motorno ulje 5W-30'', 25, 10), (''FLT001'', ''Filter ulja'', 15, 5);';
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TLoginForm.btnLoginClick(Sender: TObject);
var
  UlogovaniKorisnikID: Integer;
  UlogovanoKorisnickoIme: string;
begin
  if (edtKorisnickoIme.Text = '') or (edtLozinka.Text = '') then
  begin
    lblPoruka.Text := 'Morate uneti oba polja!';
    Exit;
  end;
  try
    if not FDConnection1.Connected then
      FDConnection1.Connected := True;
    FDQuery1.SQL.Text := 'SELECT KorisnikID, ImePrezime FROM Korisnici WHERE KorisnickoIme = :KI AND Lozinka = :LO';
    FDQuery1.ParamByName('KI').AsString := edtKorisnickoIme.Text;
    FDQuery1.ParamByName('LO').AsString := edtLozinka.Text;
    FDQuery1.Open;

    if not FDQuery1.IsEmpty then
    begin
      UlogovaniKorisnikID := FDQuery1.FieldByName('KorisnikID').AsInteger;
      UlogovanoKorisnickoIme := FDQuery1.FieldByName('ImePrezime').AsString;

      // VAŽNO: Prosleđujemo podatke i konekciju Glavnoj Formi
      GlavnaForma.UlogovaniKorisnikID := UlogovaniKorisnikID;
      GlavnaForma.UlogovanoKorisnickoIme := UlogovanoKorisnickoIme;
      GlavnaForma.FDConnection1 := Self.FDConnection1;

      Self.Hide;
      GlavnaForma.Show;
      lblPoruka.Text := '';
    end
    else
    begin
      lblPoruka.Text := 'Pogrešno korisničko ime ili lozinka!';
    end;
  finally
    if FDQuery1.Active then
      FDQuery1.Close;
  end;
end;

end.
