unit Unit4;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,
  Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FMX.Layouts, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, System.UIConsts,
  FMX.DialogService;

type
  TAdministracijaForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edtSifraDela: TEdit;
    edtNazivDela: TEdit;
    edtKolicina: TEdit;
    edtMinKolicina: TEdit;
    btnSacuvaj: TButton;
    btnNoviUnos: TButton;
    btnNazad: TButton;
    FDQueryAdmin: TFDQuery;
    lblNapomena: TLabel;
    lvDelovi: TListView;
    btnObrisi: TButton;
    Label5: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnNazadClick(Sender: TObject);
    procedure btnNoviUnosClick(Sender: TObject);
    procedure btnSacuvajClick(Sender: TObject);
    procedure lvDeloviItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure btnObrisiClick(Sender: TObject);
  private
    procedure PripremiZaNoviUnos;
    procedure UcitajDelove;
    procedure EvidentirajPromenu(DeoID: Integer; TipPromene: string;
      StaraKol, NovaKol: Integer; Napomena: string);
  public
    FDConnection1: TFDConnection;
    UlogovaniKorisnikID: Integer;
  end;

var
  AdministracijaForm: TAdministracijaForm;

implementation

uses Unit1;

{$R *.fmx}

procedure TAdministracijaForm.FormShow(Sender: TObject);
begin
  FDQueryAdmin.Connection := FDConnection1;
  UcitajDelove;
  PripremiZaNoviUnos;
end;

procedure TAdministracijaForm.UcitajDelove;
var
  ListItem: TListViewItem;
begin
  lvDelovi.BeginUpdate;
  try
    lvDelovi.Items.Clear;

    // IZMENA 1: Dodata je "Kolicina" u SELECT listu
    FDQueryAdmin.SQL.Text := 'SELECT DeoID, NazivDela, SifraDela, Kolicina FROM Delovi ORDER BY NazivDela';

    FDQueryAdmin.Open;
    while not FDQueryAdmin.Eof do
    begin
      ListItem := lvDelovi.Items.Add;
      ListItem.Text := FDQueryAdmin.FieldByName('NazivDela').AsString;

      // IZMENA 2: Prikazujemo i šifru i količinu u "Detail" delu
      ListItem.Detail := Format('Šifra: %s | Količina: %d', [
        FDQueryAdmin.FieldByName('SifraDela').AsString,
        FDQueryAdmin.FieldByName('Kolicina').AsInteger
      ]);

      ListItem.Tag := FDQueryAdmin.FieldByName('DeoID').AsInteger;
      FDQueryAdmin.Next;
    end;
  finally
    if FDQueryAdmin.Active then FDQueryAdmin.Close;
    lvDelovi.EndUpdate;
  end;
end;

procedure TAdministracijaForm.PripremiZaNoviUnos;
begin
  lvDelovi.Selected := nil;
  edtSifraDela.Text := 'DEO-' + FormatDateTime('yyyymmddhhnnss', Now);
  edtSifraDela.Enabled := False;
  edtNazivDela.Text := '';
  edtKolicina.Text := '0';
  edtMinKolicina.Text := '5';
  btnSacuvaj.Text := 'Dodaj Novi Deo';
  btnObrisi.Enabled := False;
  edtNazivDela.SetFocus;
end;

procedure TAdministracijaForm.btnNoviUnosClick(Sender: TObject);
begin
  PripremiZaNoviUnos;
end;

procedure TAdministracijaForm.lvDeloviItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  if AItem = nil then Exit;
  FDQueryAdmin.SQL.Text := 'SELECT SifraDela, NazivDela, Kolicina, MinimalnaKolicina FROM Delovi WHERE DeoID = :ID';
  FDQueryAdmin.ParamByName('ID').AsInteger := AItem.Tag;
  FDQueryAdmin.Open;
  try
    if not FDQueryAdmin.IsEmpty then
    begin
      edtSifraDela.Text := FDQueryAdmin.FieldByName('SifraDela').AsString;
      edtNazivDela.Text := FDQueryAdmin.FieldByName('NazivDela').AsString;
      edtKolicina.Text := FDQueryAdmin.FieldByName('Kolicina').AsString;
      edtMinKolicina.Text := FDQueryAdmin.FieldByName('MinimalnaKolicina').AsString;
      btnSacuvaj.Text := 'Sačuvaj Izmene';
      btnObrisi.Enabled := True;
    end;
  finally
    if FDQueryAdmin.Active then FDQueryAdmin.Close;
  end;
end;

procedure TAdministracijaForm.btnSacuvajClick(Sender: TObject);
var
  Kolicina, MinKolicina, DeoID, StaraKolicina: Integer;
begin
  if Trim(edtNazivDela.Text) = '' then
  begin
    ShowMessage('Naziv dela je obavezan!');
    Exit;
  end;
  try
    Kolicina := StrToInt(edtKolicina.Text);
    MinKolicina := StrToInt(edtMinKolicina.Text);
  except
    ShowMessage('Količine moraju biti brojevi.');
    Exit;
  end;

  try
    if lvDelovi.Selected <> nil then
    begin
      DeoID := lvDelovi.Selected.Tag;
      FDQueryAdmin.SQL.Text := 'SELECT Kolicina FROM Delovi WHERE DeoID = :ID';
      FDQueryAdmin.ParamByName('ID').AsInteger := DeoID;
      FDQueryAdmin.Open;
      StaraKolicina := FDQueryAdmin.FieldByName('Kolicina').AsInteger;
      FDQueryAdmin.Close;
      FDQueryAdmin.SQL.Text := 'UPDATE Delovi SET NazivDela = :Naziv, Kolicina = :Kol, MinimalnaKolicina = :MinKol WHERE DeoID = :ID';
      FDQueryAdmin.ParamByName('Naziv').AsString := edtNazivDela.Text;
      FDQueryAdmin.ParamByName('Kol').AsInteger := Kolicina;
      FDQueryAdmin.ParamByName('MinKol').AsInteger := MinKolicina;
      FDQueryAdmin.ParamByName('ID').AsInteger := DeoID;
      FDQueryAdmin.ExecSQL;
      EvidentirajPromenu(DeoID, 'IZMENA', StaraKolicina, Kolicina, 'Ručna izmena kroz administraciju');
    end
    else
    begin
      // ISPRAVLJENO: Uklonjena nepostojeća kolona 'Opis'
      FDQueryAdmin.SQL.Text := 'INSERT INTO Delovi (SifraDela, NazivDela, Kolicina, MinimalnaKolicina) VALUES (:Sifra, :Naziv, :Kol, :MinKol)';
      FDQueryAdmin.ParamByName('Sifra').AsString := edtSifraDela.Text;
      FDQueryAdmin.ParamByName('Naziv').AsString := edtNazivDela.Text;
      FDQueryAdmin.ParamByName('Kol').AsInteger := Kolicina;
      FDQueryAdmin.ParamByName('MinKol').AsInteger := MinKolicina;
      FDQueryAdmin.ExecSQL;
      FDQueryAdmin.SQL.Text := 'SELECT last_insert_rowid() as ID';
      FDQueryAdmin.Open;
      DeoID := FDQueryAdmin.FieldByName('ID').AsInteger;
      FDQueryAdmin.Close;
      EvidentirajPromenu(DeoID, 'DODAVANJE', 0, Kolicina, 'Novi deo');
    end;
  except
    on E: Exception do ShowMessage('Greška pri čuvanju podataka: ' + E.Message);
  end;
  UcitajDelove;
  PripremiZaNoviUnos;
end;

procedure TAdministracijaForm.btnObrisiClick(Sender: TObject);
begin
  if lvDelovi.Selected = nil then
  begin
    ShowMessage('Morate selektovati deo koji želite da obrišete.');
    Exit;
  end;
  try
    FDQueryAdmin.SQL.Text := 'DELETE FROM Delovi WHERE DeoID = :ID';
    FDQueryAdmin.ParamByName('ID').AsInteger := lvDelovi.Selected.Tag;
    FDQueryAdmin.ExecSQL;
    UcitajDelove;
    PripremiZaNoviUnos;
  except
    on E: Exception do ShowMessage('Greška pri brisanju: ' + E.Message);
  end;
end;

procedure TAdministracijaForm.EvidentirajPromenu(DeoID: Integer; TipPromene: string;
  StaraKol, NovaKol: Integer; Napomena: string);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FDConnection1;
    Q.SQL.Text := 'INSERT INTO EvidencijaPromena (DeoID, KorisnikID, TipPromene, StaraKolicina, NovaKolicina, Promena, Napomena) VALUES (:DeoID, :KorisnikID, :Tip, :Stara, :Nova, :Promena, :Napomena)';
    Q.ParamByName('DeoID').AsInteger := DeoID;
    Q.ParamByName('KorisnikID').AsInteger := UlogovaniKorisnikID;
    Q.ParamByName('Tip').AsString := TipPromene;
    Q.ParamByName('Stara').AsInteger := StaraKol;
    Q.ParamByName('Nova').AsInteger := NovaKol;
    Q.ParamByName('Promena').AsInteger := NovaKol - StaraKol;
    Q.ParamByName('Napomena').AsString := Napomena;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TAdministracijaForm.btnNazadClick(Sender: TObject);
begin
  Self.Close;
end;

end.
