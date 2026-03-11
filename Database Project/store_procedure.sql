DELIMITER //
CREATE PROCEDURE sp_manutenzione_straordinaria (
    IN p_id_impianto INT,
    IN p_data DATE,
    IN p_descrizione TEXT,
    IN p_costo DECIMAL(10,2)
)
BEGIN
    -- Dichiarazione gestore errori per la transazione
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        -- In caso di errore, annulla tutte le modifiche
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore durante la transazione. Operazione annullata.';
    END;

    -- Inizio della transazione sicura
    START TRANSACTION;

    -- 1. Inserisce il record della spesa di manutenzione
    INSERT INTO MANUTENZIONI (DataIntervento, Descrizione, Costo, ID_Impianto)
    VALUES (p_data, p_descrizione, p_costo, p_id_impianto);

    -- 2. Cambia lo stato dell'impianto mettendolo fuori uso
    UPDATE IMPIANTI 
    SET Stato = 'MANUTENZIONE' 
    WHERE ID_Impianto = p_id_impianto;

    -- 3. Cancella in automatico tutte le prenotazioni future per quell'impianto
    -- per evitare che i clienti si presentino e trovino il guasto
    UPDATE PRENOTAZIONI
    SET Stato = 'CANCELLATA'
    WHERE ID_Impianto = p_id_impianto 
      AND Stato = 'CONFERMATA'
      AND DataOra >= NOW();

    -- Se tutto è andato a buon fine, salva definitivamente le modifiche
    COMMIT;
END; //

CREATE PROCEDURE sp_completa_lavaggio (
    IN p_id_prenotazione INT
)
BEGIN
    DECLARE v_id_programma INT;
    DECLARE v_stato_attuale VARCHAR(20);

    -- Gestione errori e rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Errore nello scarico magazzino. Annullato.';
    END;

    -- Recupera lo stato e il programma della prenotazione
    SELECT Stato, ID_Programma INTO v_stato_attuale, v_id_programma
    FROM PRENOTAZIONI
    WHERE ID_Prenotazione = p_id_prenotazione;

    -- Controlla che la prenotazione sia valida per essere completata
    IF v_stato_attuale != 'CONFERMATA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo le prenotazioni CONFERMATE possono essere completate.';
    ELSE
        START TRANSACTION;

        -- 1. Aggiorna lo stato della prenotazione
        UPDATE PRENOTAZIONI
        SET Stato = 'COMPLETATA'
        WHERE ID_Prenotazione = p_id_prenotazione;

        -- 2. Scarica le giacenze dal magazzino incrociando i prodotti usati in quel programma
        -- Usa una logica avanzata di UPDATE con INNER JOIN
        UPDATE PRODOTTI p
        INNER JOIN COMPOSIZIONE_PROG cp ON p.ID_Prodotto = cp.ID_Prodotto
        SET p.Stock = p.Stock - cp.QtaUtilizzata
        WHERE cp.ID_Programma = v_id_programma;

        COMMIT;
    END IF;
END; //

DELIMITER ;