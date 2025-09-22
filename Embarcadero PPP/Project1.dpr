program Project1;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit1 in 'Unit1.pas' {LoginForm},
  Unit2 in 'Unit2.pas' {GlavnaForma},
  Unit4 in 'Unit4.pas' {AdministracijaForm},
  Unit3 in 'Unit3.pas' {StanjeZalihaForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TLoginForm, LoginForm);
  Application.CreateForm(TGlavnaForma, GlavnaForma);
  Application.CreateForm(TAdministracijaForm, AdministracijaForm);
  Application.CreateForm(TStanjeZalihaForm, StanjeZalihaForm);
  Application.Run;
end.
