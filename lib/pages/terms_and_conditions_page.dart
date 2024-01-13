import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatefulWidget {
  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Terms and Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(overflow: TextOverflow.fade,"Informativa sulla privacy per l'app Venice Go\n\nEffettiva a partire dal data di effettiva implementazione\n\n Benvenuto nell'app Venice Go. La tua privacy è di primaria importanza per noi, e ci impegniamo a proteggere le tue informazioni personali nel rispetto del Regolamento Generale sulla Protezione dei Dati (GDPR).\n\n 1. Raccolta di informazioni personali\n\n 1.1 Dati personali forniti dall'utente:\n Raccogliamo le informazioni personali che ci fornisci volontariamente durante l'utilizzo dell'app, come il tuo nome, cognome, indirizzo email e, opzionalmente, la tua foto del profilo.\n\n 1.2 Dati di localizzazione:\n L'app Venice Go raccoglie la tua posizione per offrirti una mappa interattiva e personalizzata delle attrazioni di Venezia. Questi dati di localizzazione sono utilizzati esclusivamente per migliorare la tua esperienza e non sono condivisi con terze parti.\n\n 2. Uso delle informazioni\n\n 2.1 Miglioramento dell'esperienza utente:\n Le informazioni personali raccolte vengono utilizzate per personalizzare l'esperienza dell'utente all'interno dell'app, fornendo suggerimenti e indicazioni basate sulla tua posizione.\n\n 2.2 Comunicazioni:\n Potremmo utilizzare il tuo indirizzo email per inviarti comunicazioni relative alle tue attività all'interno dell'app, nuove funzionalità o aggiornamenti.\n\n 3. Condivisione di informazioni\n\n Le informazioni personali raccolte non saranno vendute, affittate o condivise con terze parti senza il tuo consenso esplicito, tranne nei casi descritti in questa informativa sulla privacy.\n\n 4. Conservazione e trattamento dei dati in Europa\n\n Tutte le informazioni personali raccolte dall'app Venice Go sono conservate e trattate all'interno dell'Unione Europea. Ciò garantisce il rispetto delle disposizioni del GDPR in materia di trasferimenti internazionali di dati personali.\n\n 5. Sicurezza delle informazioni\n\n Implementiamo misure di sicurezza per proteggere le informazioni personali raccolte dall'accesso non autorizzato o dalla divulgazione.\n\n 6. Accesso e modifica delle informazioni personali\n\n Puoi accedere e modificare le informazioni personali fornite in qualsiasi momento tramite le impostazioni dell'app.\n\n 7. Conservazione dei dati\n\n Conserviamo le informazioni personali solo per il tempo necessario per gli scopi indicati in questa informativa, a meno che non sia richiesto o consentito dalla legge una conservazione più lunga.\n\n 8. Consenso dell'utente\n\n Utilizzando l'app Venice Go, acconsenti alla raccolta e all'uso delle informazioni personali come descritto in questa informativa sulla privacy.\n\n9. Aggiornamenti della privacy\n\nQuesta informativa sulla privacy potrebbe subire modifiche per rispecchiare eventuali aggiornamenti dell'app o cambiamenti normativi. Verifica periodicamente questa pagina per rimanere informato.\n\nPer ulteriori informazioni o domande sulla nostra politica sulla privacy, contattaci all'indirizzo info@venicego.it\n\nGrazie per la fiducia.\n\nVenice Go\n     "),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        )
      ),
    );
  }
}


