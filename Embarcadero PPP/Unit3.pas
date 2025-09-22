unit Unit3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  Data.DB, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FMX.Layouts, System.UIConsts;

type
  TStanjeZalihaForm = class(TForm)
    Label1: TLabel;
    edtPretraga: TEdit;
    lblStatus: TEdit;
    Nazad: TButton;
    btnOsvezi: TButton;
    btnKorekcija: TButton;
    btnPreuzmi: TButton;
    lvDelovi: TListView;
    FDQueryDelovi: TFDQuery;
    FDQueryUpdate: TFDQuery;
    Label2: TLabel;
    Label3: TLabel;
    procedure FormShow(Sender: TObject);
    procedure NazadClick(Sender: TObject);
    procedure btnOsveziClick(Sender: TObject);
    procedure btnPreuzmiClick(Sender: TObject);
    procedure btnKorekcijaClick(Sender: TObject);
    procedure edtPretragaChange(Sender: TObject);
  private
    procedure UcitajDelove;
    procedure ProveriBrojNiskihZaliha;
    procedure EvidentirajPromenu(DeoID: Integer; TipPromene: string; StaraKol, NovaKol: Integer; Napomena: string);
  public
    FDConnection1: TFDConnection;
    UlogovaniKorisnikID: Integer;
  end;

var
  StanjeZalihaForm: TStanjeZalihaForm;

implementation

uses Unit1;

{$R *.fmx}

procedure TStanjeZalihaForm.FormShow(Sender: TObject);
begin
  FDQueryDelovi.Connection := FDConnection1;
  FDQueryUpdate.Connection := FDConnection1;
  UcitajDelove;
end;

procedure TStanjeZalihaForm.UcitajDelove;
var
  ListItem: TListViewItem;
  Kolicina, MinKolicina: Integer;
begin
  lvDelovi.BeginUpdate;
  try
    lvDelovi.Items.Clear;
    FDQueryDelovi.SQL.Text := 'SELECT DeoID, SifraDela, NazivDela, Kolicina, MinimalnaKolicina, JedinicaMere FROM Delovi ORDER BY NazivDela';
    if Trim(edtPretraga.Text) <> '' then
    begin
      FDQueryDelovi.SQL.Text := 'SELECT DeoID, SifraDela, NazivDela, Kolicina, MinimalnaKolicina, JedinicaMere FROM Delovi ' +
                               'WHERE UPPER(NazivDela) LIKE UPPER(:Pretraga) OR UPPER(SifraDela) LIKE UPPER(:Pretraga) ' +
                               'ORDER BY NazivDela';
      FDQueryDelovi.ParamByName('Pretraga').AsString := '%' + Trim(edtPretraga.Text) + '%';
    end;
    FDQueryDelovi.Open;
    while not FDQueryDelovi.Eof do
    begin
      ListItem := lvDelovi.Items.Add;
      ListItem.Tag := FDQueryDelovi.FieldByName('DeoID').AsInteger;
      ListItem.Text := FDQueryDelovi.FieldByName('NazivDela').AsString;
      Kolicina := FDQueryDelovi.FieldByName('Kolicina').AsInteger;
      MinKolicina := FDQueryDelovi.FieldByName('MinimalnaKolicina').AsInteger;
      ListItem.Detail := Format('Šifra: %s | Količina: %d %s | Min: %d',
        [FDQueryDelovi.FieldByName('SifraDela').AsString, Kolicina,
         FDQueryDelovi.FieldByName('JedinicaMere').AsString, MinKolicina]);
      if Kolicina < MinKolicina then
        if ListItem.Objects.FindObjectT<TListItemText>('text') <> nil then
           ListItem.Objects.FindObjectT<TListItemText>('text').TextColor := TAlphaColors.Red;
      FDQueryDelovi.Next;
    end;
  finally
    if FDQueryDelovi.Active then FDQueryDelovi.Close;
    lvDelovi.EndUpdate;
  end;
  ProveriBrojNiskihZaliha;
end;

procedure TStanjeZalihaForm.ProveriBrojNiskihZaliha;
var
  Q: TFDQuery;
  BrojNiskih: Integer; // ISPRAVLJENO: Deklaracija koja je nedostajala
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FDConnection1;
    Q.SQL.Text := 'SELECT COUNT(*) as Broj FROM Delovi WHERE Kolicina < MinimalnaKolicina';
    Q.Open;
    BrojNiskih := Q.FieldByName('Broj').AsInteger;
    Q.Close;
    if BrojNiskih > 0 then
      lblStatus.Text := Format('UPOZORENJE: %d delova ima niske zalihe!', [BrojNiskih])
    else
      lblStatus.Text := 'Sve zalihe su u optimalnom stanju';
  finally
    Q.Free;
  end;
end;

procedure TStanjeZalihaForm.EvidentirajPromenu(DeoID: Integer; TipPromene: string;
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

procedure TStanjeZalihaForm.btnKorekcijaClick(Sender: TObject);
var
  DeoID, StaraKolicina, NovaKolicina: Integer;
  InputStr: string;
begin
  if lvDelovi.Selected = nil then
  begin
    ShowMessage('Molimo vas, prvo izaberite deo sa liste.');
    Exit;
  end;
  DeoID := lvDelovi.Selected.Tag;
  FDQueryDelovi.SQL.Text := 'SELECT Kolicina FROM Delovi WHERE DeoID = :ID';
  FDQueryDelovi.ParamByName('ID').AsInteger := DeoID;
  FDQueryDelovi.Open;
  StaraKolicina := FDQueryDelovi.FieldByName('Kolicina').AsInteger;
  FDQueryDelovi.Close;

  if InputQuery('Korekcija stanja', 'Unesite novu količinu:', InputStr) then
  begin
    try
      NovaKolicina := StrToInt(InputStr);
      if NovaKolicina < 0 then Exit;
      FDQueryUpdate.SQL.Text := 'UPDATE Delovi SET Kolicina = :NovaKol WHERE DeoID = :ID';
      FDQueryUpdate.ParamByName('NovaKol').AsInteger := NovaKolicina;
      FDQueryUpdate.ParamByName('ID').AsInteger := DeoID;
      FDQueryUpdate.ExecSQL;
      EvidentirajPromenu(DeoID, 'KOREKCIJA', StaraKolicina, NovaKolicina, 'Ručna izmena');
      UcitajDelove;
    except
      on E: EConvertError do ShowMessage('Neispravan unos, molimo unesite broj.');
    end;
  end;
end;

procedure TStanjeZalihaForm.NazadClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TStanjeZalihaForm.btnOsveziClick(Sender: TObject);
begin
  UcitajDelove;
end;

procedure TStanjeZalihaForm.btnPreuzmiClick(Sender: TObject);
var
  DeoID, StaraKolicina: Integer;
begin
  if lvDelovi.Selected = nil then
  begin
    ShowMessage('Molimo vas, prvo izaberite deo sa liste.');
    Exit;
  end;
  DeoID := lvDelovi.Selected.Tag;
  FDQueryDelovi.SQL.Text := 'SELECT Kolicina FROM Delovi WHERE DeoID = :ID';
  FDQueryDelovi.ParamByName('ID').AsInteger := DeoID;
  FDQueryDelovi.Open;
  StaraKolicina := FDQueryDelovi.FieldByName('Kolicina').AsInteger;
  FDQueryDelovi.Close;

  if StaraKolicina <= 0 then
  begin
    ShowMessage('Deo nije na stanju!');
    Exit;
  end;

  // ISPRAVLJENO: Uklonjen MessageDlg koji je pravio grešku
  try
    FDQueryUpdate.SQL.Text := 'UPDATE Delovi SET Kolicina = Kolicina - 1 WHERE DeoID = :ID';
    FDQueryUpdate.ParamByName('ID').AsInteger := DeoID;
    FDQueryUpdate.ExecSQL;
    EvidentirajPromenu(DeoID, 'PREUZIMANJE', StaraKolicina, StaraKolicina - 1, 'Standardno preuzimanje');
    UcitajDelove;
  except
    on E: Exception do ShowMessage('Greška pri preuzimanju dela: ' + E.Message);
  end;
end;

procedure TStanjeZalihaForm.edtPretragaChange(Sender: TObject);
begin
  UcitajDelove;
end;

end.
