NUM1            EQU     255 ; Primo operando (inserisci qua il primo numero)
NUM2            EQU     4 ; Secondo operando (inserisci qua il secondo numero)
OPERAZIONE      EQU     4 ; Operazione (+ = 1, - = 2, * = 3, / = 4)
RISULTATO       FILL    4
RESTO           FILL    4     

                ;       Carica i due operandi
                MOV     R2, #NUM1 ; primo operando

                MOV     R3, #NUM2 ; secondo operando

                ;       Carica l'operazione
                MOV     R4, #OPERAZIONE ; operazione


                CMP     R4, #1 ; Se è '+'
                BEQ     ADDIZIONE

                CMP     R4, #2 ; Se è '-'
                BEQ     SOTTRAZIONE

                CMP     R4, #3 ; Se è '*'
                BEQ     MOLTIPLICAZIONE

                CMP     R4, #4 ; Se è '/'
                BEQ     DIVISIONE

                ;       Se l'operazione non è valida, risultato = 0
                MOV     R0, #0
                B       FINE

ADDIZIONE       
                ADD     R0, R2, R3 ; R0 = NUM1 + NUM2
                B       FINE

SOTTRAZIONE     
                SUB     R0, R2, R3 ; R0 = NUM1 - NUM2
                B       FINE

MOLTIPLICAZIONE 
                MOV     R0, #0 ; Inizializza il risultato a 0
                CMP     R3, #0 ; Controlla se il moltiplicatore è 0
                BEQ     FINE ; Se è 0, risultato = 0

MOLT_CICLO      
                ADD     R0, R0, R2 ; Somma NUM1 al risultato
                SUB     R3, R3, #1 ; Decrementa il contatore
                CMP     R3, #0 ; Controlla se ha raggiunto 0
                BNE     MOLT_CICLO ; Se non è 0, continua il ciclo
                B       FINE

DIVISIONE       
                CMP     R3, #0 ; Controllo divisione per zero
                BEQ     DIV_ZERO
                MOV     R5, #0 ; Inizializza il quoziente a 0
                B       DIV_CICLO

DIV_CICLO       
                CMP     R2, R3 ; Controlla se numeratore < denominatore
                BLT     DIV_FINE ; Se sì, fine divisione
                SUB     R2, R2, R3 ; Sottrai il denominatore dal numeratore
                ADD     R5, R5, #1 ; Incrementa il quoziente
                B       DIV_CICLO ; Ripeti il ciclo

DIV_FINE        
                MOV     R0, R5 ; R0 = quoziente
                CMP     R2,#0  ; Se numeratore > 0 è presente resto
                BHI     DIV_RESTO ; Se si, salva resto
                B       FINE

DIV_ZERO        
                MOV     R0, #0 ; Se divisione per zero, risultato = 0
                B       FINE
DIV_RESTO       MOV     R3,#RESTO
                STR     R2,[R3]
                B       FINE

FINE            MOV     R1,#RISULTATO
                STR     R0,[R1]



