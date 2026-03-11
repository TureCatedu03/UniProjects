USE CarWashDB;

DELIMITER //
CREATE TRIGGER trg_pagamento_prenotazione
BEFORE INSERT ON PRENOTAZIONI
FOR EACH ROW
BEGIN
    DECLARE v_prezzo DECIMAL(10,2);
    DECLARE v_saldo DECIMAL(10,2);
    DECLARE v_scadenza DATE;
    
    -- 1. Recupera il prezzo del lavaggio scelto
    SELECT Prezzo INTO v_prezzo 
    FROM PROGRAMMI 
    WHERE ID_Programma = NEW.ID_Programma;
    
    -- 2. Recupera i dati della tessera del cliente (saldo e scadenza abbonamento)
    SELECT Saldo, ScadenzaAbbonamento INTO v_saldo, v_scadenza
    FROM TESSERE
    WHERE ID_Cliente = NEW.ID_Cliente
    LIMIT 1;
    
    -- 3. Controllo logico: ha l'abbonamento valido per la data della prenotazione?
    IF (v_scadenza IS NOT NULL AND v_scadenza >= DATE(NEW.DataOra)) THEN
        SET @esito = 'Coperto da abbonamento';
        
    -- 4. Non ha abbonamento: ha credito sufficiente sulla prepagata?
    ELSEIF (v_saldo >= v_prezzo) THEN
        UPDATE TESSERE 
        SET Saldo = Saldo - v_prezzo 
        WHERE ID_Cliente = NEW.ID_Cliente;
        
    -- 5. Se non ha né abbonamento né soldi: blocca.
    ELSE
        SIGNAL SQLSTATE '45000'  -- segnale di eccezione personalizzata + blocco della query
        SET MESSAGE_TEXT = 'Errore Inserimento: Credito insufficiente e nessun abbonamento valido.';
    END IF;
END; //

CREATE TRIGGER trg_blocco_manutenzione
BEFORE INSERT ON PRENOTAZIONI
FOR EACH ROW
BEGIN
    DECLARE v_stato VARCHAR(20);
    
    -- Recupera lo stato attuale del macchinario richiesto
    SELECT Stato INTO v_stato
    FROM IMPIANTI
    WHERE ID_Impianto = NEW.ID_Impianto;
    
    -- Se il macchinario è in manutenzione o prenotato, blocca la prenotazione
    IF (v_stato = 'MANUTENZIONE') THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Errore Operativo: Impianto attualmente in manutenzione. Selezionare un altro impianto.';
    END IF;
END; //

CREATE TRIGGER trg_evita_sovrapposizioni
BEFORE INSERT ON PRENOTAZIONI
FOR EACH ROW
BEGIN
    DECLARE v_conflitti INT;
    -- Conta se ci sono già prenotazioni confermate per lo stesso impianto 
    -- in un intervallo di 30 minuti rispetto all'orario richiesto.
    SELECT COUNT(*) INTO v_conflitti
    FROM PRENOTAZIONI
    WHERE ID_Impianto = NEW.ID_Impianto
      AND Stato = 'CONFERMATA'
      AND DataOra >= NEW.DataOra - INTERVAL 15 MINUTE
      AND DataOra <= NEW.DataOra + INTERVAL 15 MINUTE;
      
    -- Se trova almeno una prenotazione in quell'arco temporale, blocca tutto
    IF (v_conflitti > 0) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Errore: Macchinario già occupato in questa fascia oraria. Scegliere un altro orario o un altro impianto.';
    END IF;
END; //
DELIMITER ;