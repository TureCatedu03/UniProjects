USE CarWashDB;


-- Elenco dei clienti ordinato alfabeticamente
SELECT Nome, Cognome, Email, Telefono 
FROM CLIENTI 
ORDER BY Cognome ASC, Nome ASC;

-- Ricerca di prodotti in vendita con prezzo superiore a 5 euro
SELECT Nome, PrezzoVendita, Stock 
FROM PRODOTTI 
WHERE IsVendita = TRUE AND PrezzoVendita > 5.00
ORDER BY PrezzoVendita DESC;


-- Impianti attualmente fuori uso (in manutenzione o prenotato)
SELECT ID_Impianto, Nome, Tipo 
FROM IMPIANTI 
WHERE Stato = 'MANUTENZIONE';

-- Elenco dei veicoli con il rispettivo proprietario
SELECT v.Targa, v.Modello, v.Tipo, c.Nome, c.Cognome 
FROM VEICOLI v
INNER JOIN CLIENTI c ON v.ID_Cliente = c.ID_Cliente;

-- Dettaglio delle prenotazioni confermate del giorno successivo al corrente
SELECT p.DataOra, c.Cognome, i.Nome AS Macchinario, prog.Nome AS Lavaggio
FROM PRENOTAZIONI p
INNER JOIN CLIENTI c ON p.ID_Cliente = c.ID_Cliente
INNER JOIN IMPIANTI i ON p.ID_Impianto = i.ID_Impianto
INNER JOIN PROGRAMMI prog ON p.ID_Programma = prog.ID_Programma
WHERE p.Stato = 'CONFERMATA' 
  AND DATE(p.DataOra) = CURDATE() + INTERVAL 1 DAY;

-- Numero di impianti per ogni sede
SELECT s.Citta, s.Indirizzo, COUNT(i.ID_Impianto) AS Numero_Impianti
FROM SEDI s
LEFT JOIN IMPIANTI i ON s.ID_Sede = i.ID_Sede
GROUP BY s.ID_Sede, s.Citta, s.Indirizzo;

-- Calcolo dell'incasso totale per ogni sede (per lavaggi)
SELECT s.Citta, SUM(prog.Prezzo) AS Incasso_Totale
FROM PRENOTAZIONI p
INNER JOIN IMPIANTI i ON p.ID_Impianto = i.ID_Impianto
INNER JOIN SEDI s ON i.ID_Sede = s.ID_Sede
INNER JOIN PROGRAMMI prog ON p.ID_Programma = prog.ID_Programma
WHERE p.Stato = 'COMPLETATA'
GROUP BY s.ID_Sede, s.Citta
ORDER BY Incasso_Totale DESC;

-- Classifica dei clienti più fedeli (Almeno 5 lavaggi completati)
SELECT c.Nome, c.Cognome, COUNT(p.ID_Prenotazione) AS Lavaggi_Effettuati
FROM CLIENTI c
INNER JOIN PRENOTAZIONI p ON c.ID_Cliente = p.ID_Cliente
WHERE p.Stato = 'COMPLETATA'
GROUP BY c.ID_Cliente, c.Nome, c.Cognome
HAVING COUNT(p.ID_Prenotazione) >= 5
ORDER BY Lavaggi_Effettuati DESC;

-- Consumo idrico medio (sopra 130)
SELECT s.Citta, ROUND(AVG(cs.Acqua_Mc), 2) AS Media_Acqua_Giornaliera
FROM CONSUMI_SEDE cs
INNER JOIN SEDI s ON cs.ID_Sede = s.ID_Sede
GROUP BY s.ID_Sede, s.Citta
HAVING AVG(cs.Acqua_Mc) > 130.00
ORDER BY Media_Acqua_Giornaliera DESC;

-- Consumo totale teorico di ogni prodotto per i lavaggi effettuati
SELECT prod.Nome, SUM(comp.QtaUtilizzata) AS Consumo_Totale_Litri
FROM PRENOTAZIONI p
INNER JOIN PROGRAMMI prog ON p.ID_Programma = prog.ID_Programma
INNER JOIN COMPOSIZIONE_PROG comp ON prog.ID_Programma = comp.ID_Programma
INNER JOIN PRODOTTI prod ON comp.ID_Prodotto = prod.ID_Prodotto
WHERE p.Stato = 'COMPLETATA'
GROUP BY prod.ID_Prodotto, prod.Nome
ORDER BY Consumo_Totale_Litri DESC;
