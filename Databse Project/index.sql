USE CarWashDB;

CREATE INDEX idx_prenotazioni_data_impianto ON PRENOTAZIONI(DataOra, ID_Impianto);
CREATE INDEX idx_clienti_cognome ON CLIENTI(Cognome, Nome);
