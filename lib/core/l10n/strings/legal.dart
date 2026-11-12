// Traductions : conformité (mentions légales, cookies, données, achats,
// promesses corrigées, accessibilité), toutes les langues.
const legalTranslations = <String, Map<String, String>>{
  'en': {
    'Retour':
        'Back',
    'Activer le son':
        'Turn sound on',
    'Couper le son':
        'Mute',
    'Envoyer':
        'Send',
    'Vidéo, {n} vues':
        'Video, {n} views',
    'Voir la vidéo':
        'Watch the video',
    'Mentions légales':
        'Legal notice',
    'Cookies':
        'Cookies',
    'Règles des Ballons et remboursements':
        'Balls rules and refunds',
    'Mes données':
        'My data',
    'Demander une copie, une correction ou la suppression.':
        'Ask for a copy, a correction or deletion.',
    'Licences':
        'Licenses',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'To delete your account and all your data, use “Delete my account” at the bottom of this page. To get a copy of your data, correct it or object to its use, write to us from your account\'s email address: we answer within one month.',
    'Fermer':
        'Close',
    'Écrire un e-mail':
        'Write an email',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'I accept the terms of use and the Balls rules, and I have read the privacy policy.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Prices include all taxes, one single payment: no subscription, no hidden fees. Balls arrive right after payment: on the payment page, you ask for this immediate delivery and give up the 14-day withdrawal period. Duplicate payment or Balls not received: refunded.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Talent speaks, not followers. Post your skills and let the community discover you, wherever you are.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Create a skill move, give it your name, and watch the community copy it. Every copy carries your name.',
    'Progresse, prouve, fais-toi remarquer':
        'Improve, prove it, get noticed',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Your rating is earned on the pitch, through community votes. Your Football Passport shows your progress to registered scouts.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Name this move: every copy will carry your name.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Scout accounts only · contact is mediated for minors.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'A scout can only contact you after a guardian approves — add their contact so you can be approached.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'No precise location is ever public. Contact from a scout is always mediated for under-18s.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'A scout wants to contact an underage player.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'A scout wants to contact {username} on Football IQ Universe. To approve or decline this contact, open the app, go to Settings > "I have a guardian code" and enter this code: {token}',
  },
  'es': {
    'Retour':
        'Volver',
    'Activer le son':
        'Activar sonido',
    'Couper le son':
        'Silenciar',
    'Envoyer':
        'Enviar',
    'Vidéo, {n} vues':
        'Vídeo, {n} visualizaciones',
    'Voir la vidéo':
        'Ver el vídeo',
    'Mentions légales':
        'Aviso legal',
    'Cookies':
        'Cookies',
    'Règles des Ballons et remboursements':
        'Reglas de los Balones y reembolsos',
    'Mes données':
        'Mis datos',
    'Demander une copie, une correction ou la suppression.':
        'Pide una copia, una corrección o la eliminación.',
    'Licences':
        'Licencias',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'Para eliminar tu cuenta y todos tus datos, usa «Eliminar mi cuenta» al final de esta página. Para recibir una copia de tus datos, corregirlos u oponerte a su uso, escríbenos desde el correo de tu cuenta: respondemos en un plazo de un mes.',
    'Fermer':
        'Cerrar',
    'Écrire un e-mail':
        'Escribir un correo',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'Acepto las condiciones de uso y las reglas de los Balones, y he leído la política de privacidad.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Precio con impuestos incluidos, pago único: sin suscripción ni costes ocultos. Los Balones llegan justo después del pago: en la página de pago pides esta entrega inmediata y renuncias al plazo de desistimiento de 14 días. Pago duplicado o Balones no recibidos: reembolsados.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Habla el talento, no los seguidores. Publica tus jugadas técnicas y deja que la comunidad te descubra, estés donde estés.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Crea una jugada, ponle tu nombre y mira cómo la comunidad la reproduce. Cada reproducción lleva tu nombre.',
    'Progresse, prouve, fais-toi remarquer':
        'Mejora, demuéstralo, hazte notar',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Tu nota se gana en el campo, con los votos de la comunidad. Tu Football Passport muestra tu progreso a los ojeadores registrados.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Ponle nombre a esta jugada: cada reproducción llevará tu nombre.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Solo cuentas de ojeador · el contacto con menores es supervisado.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'Un ojeador solo puede contactarte después de que un tutor lo apruebe: añade su contacto para que puedan contactarte.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'Nunca se muestra una ubicación precisa. El contacto de un ojeador con menores de 18 siempre es supervisado.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'Un ojeador quiere contactar con un jugador menor de edad.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'Un ojeador quiere contactar con {username} en Football IQ Universe. Para aprobar o rechazar este contacto, abre la app, ve a Ajustes > "Tengo un código de tutor" e introduce este código: {token}',
  },
  'pt': {
    'Retour':
        'Voltar',
    'Activer le son':
        'Ativar som',
    'Couper le son':
        'Silenciar',
    'Envoyer':
        'Enviar',
    'Vidéo, {n} vues':
        'Vídeo, {n} visualizações',
    'Voir la vidéo':
        'Ver o vídeo',
    'Mentions légales':
        'Aviso legal',
    'Cookies':
        'Cookies',
    'Règles des Ballons et remboursements':
        'Regras das Bolas e reembolsos',
    'Mes données':
        'Meus dados',
    'Demander une copie, une correction ou la suppression.':
        'Peça uma cópia, uma correção ou a exclusão.',
    'Licences':
        'Licenças',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'Para excluir sua conta e todos os seus dados, use “Excluir minha conta” no fim desta página. Para receber uma cópia dos seus dados, corrigi-los ou se opor ao uso deles, escreva para nós pelo e-mail da sua conta: respondemos em até um mês.',
    'Fermer':
        'Fechar',
    'Écrire un e-mail':
        'Escrever um e-mail',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'Aceito os termos de uso e as regras das Bolas, e li a política de privacidade.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Preço com impostos incluídos, pagamento único: sem assinatura, sem taxas escondidas. As Bolas chegam logo após o pagamento: na página de pagamento, você pede essa entrega imediata e renuncia ao prazo de arrependimento de 14 dias. Pagamento em dobro ou Bolas não recebidas: reembolsados.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Quem fala é o talento, não os seguidores. Poste seus lances técnicos e deixe a comunidade descobrir você, onde quer que esteja.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Crie um lance, dê seu nome a ele e veja a comunidade reproduzi-lo. Cada reprodução leva o seu nome.',
    'Progresse, prouve, fais-toi remarquer':
        'Evolua, prove, seja notado',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Sua nota é conquistada em campo, com os votos da comunidade. Seu Football Passport mostra sua evolução para os olheiros cadastrados.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Dê um nome a este lance: cada reprodução levará o seu nome.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Apenas contas de olheiro · contato mediado para menores.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'Um olheiro só pode falar com você depois que um responsável aprovar — adicione o contato dele para poder ser abordado.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'Nenhuma localização exata é pública. O contato de um olheiro com menores de 18 anos é sempre mediado.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'Um olheiro quer entrar em contato com um jogador menor de idade.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'Um olheiro quer entrar em contato com {username} no Football IQ Universe. Para aprovar ou recusar esse contato, abra o app, vá em Configurações > "Tenho um código de responsável" e digite este código: {token}',
  },
  'de': {
    'Retour':
        'Zurück',
    'Activer le son':
        'Ton einschalten',
    'Couper le son':
        'Stummschalten',
    'Envoyer':
        'Senden',
    'Vidéo, {n} vues':
        'Video, {n} Aufrufe',
    'Voir la vidéo':
        'Video ansehen',
    'Mentions légales':
        'Impressum',
    'Cookies':
        'Cookies',
    'Règles des Ballons et remboursements':
        'Ball-Regeln und Erstattungen',
    'Mes données':
        'Meine Daten',
    'Demander une copie, une correction ou la suppression.':
        'Kopie, Berichtigung oder Löschung anfordern.',
    'Licences':
        'Lizenzen',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'Um dein Konto und alle deine Daten zu löschen, nutze „Mein Konto löschen“ unten auf dieser Seite. Für eine Kopie deiner Daten, eine Berichtigung oder einen Widerspruch schreib uns von der E-Mail-Adresse deines Kontos: Wir antworten innerhalb eines Monats.',
    'Fermer':
        'Schließen',
    'Écrire un e-mail':
        'E-Mail schreiben',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'Ich akzeptiere die Nutzungsbedingungen und die Ball-Regeln und habe die Datenschutzerklärung gelesen.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Preise inkl. Steuern, Einmalzahlung: kein Abo, keine versteckten Kosten. Die Bälle kommen direkt nach der Zahlung: Auf der Zahlungsseite verlangst du diese sofortige Lieferung und verzichtest auf die 14-tägige Widerrufsfrist. Doppelte Zahlung oder keine Bälle erhalten: erstattet.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Talent zählt, nicht Follower. Poste deine Tricks und lass dich von der Community entdecken, egal wo du bist.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Erfinde einen Trick, gib ihm deinen Namen und sieh zu, wie die Community ihn nachmacht. Jede Nachahmung trägt deinen Namen.',
    'Progresse, prouve, fais-toi remarquer':
        'Werde besser, beweise es, fall auf',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Deine Bewertung verdienst du auf dem Platz, durch die Stimmen der Community. Dein Football Passport zeigt registrierten Scouts deinen Fortschritt.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Gib diesem Trick einen Namen: Jede Nachahmung trägt deinen Namen.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Nur Scout-Konten · Kontakt mit Minderjährigen wird vermittelt.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'Ein Scout kann dich erst kontaktieren, wenn ein Erziehungsberechtigter zustimmt – füge seinen Kontakt hinzu, damit man dich ansprechen kann.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'Ein genauer Standort ist nie öffentlich. Kontakt von Scouts läuft bei unter 18-Jährigen immer über eine Vermittlung.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'Ein Scout möchte einen minderjährigen Spieler kontaktieren.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'Ein Scout möchte {username} auf Football IQ Universe kontaktieren. Um diesen Kontakt freizugeben oder abzulehnen, öffne die App, geh zu Einstellungen > „Ich habe einen Elterncode“ und gib diesen Code ein: {token}',
  },
  'it': {
    'Retour':
        'Indietro',
    'Activer le son':
        'Attiva audio',
    'Couper le son':
        'Disattiva audio',
    'Envoyer':
        'Invia',
    'Vidéo, {n} vues':
        'Video, {n} visualizzazioni',
    'Voir la vidéo':
        'Guarda il video',
    'Mentions légales':
        'Note legali',
    'Cookies':
        'Cookie',
    'Règles des Ballons et remboursements':
        'Regole dei Palloni e rimborsi',
    'Mes données':
        'I miei dati',
    'Demander une copie, une correction ou la suppression.':
        'Chiedi una copia, una correzione o la cancellazione.',
    'Licences':
        'Licenze',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'Per eliminare il tuo account e tutti i tuoi dati, usa «Elimina il mio account» in fondo a questa pagina. Per ricevere una copia dei tuoi dati, correggerli od opporti al loro uso, scrivici dall\'indirizzo e-mail del tuo account: rispondiamo entro un mese.',
    'Fermer':
        'Chiudi',
    'Écrire un e-mail':
        'Scrivi un\'e-mail',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'Accetto le condizioni d\'uso e le regole dei Palloni, e ho letto l\'informativa sulla privacy.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Prezzo IVA inclusa, pagamento unico: nessun abbonamento, nessun costo nascosto. I Palloni arrivano subito dopo il pagamento: nella pagina di pagamento chiedi questa consegna immediata e rinunci al recesso di 14 giorni. Pagamento doppio o Palloni non ricevuti: rimborsati.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Parla il talento, non i follower. Pubblica i tuoi gesti tecnici e lascia che la community ti scopra, ovunque tu sia.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Crea un gesto, dagli il tuo nome e guarda la community riprodurlo. Ogni riproduzione porta il tuo nome.',
    'Progresse, prouve, fais-toi remarquer':
        'Migliora, dimostralo, fatti notare',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Il tuo voto si conquista in campo, grazie ai voti della community. Il tuo Football Passport mostra i tuoi progressi agli osservatori iscritti.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Dai un nome a questo gesto: ogni riproduzione porterà il tuo nome.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Solo account osservatore · contatto mediato per i minori.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'Un osservatore può contattarti solo dopo l\'approvazione di un tutore — aggiungi il suo contatto per poter essere contattato.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'Nessuna posizione precisa è mai pubblica. Il contatto da parte di un osservatore è sempre mediato per gli under 18.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'Un osservatore vuole contattare un giocatore minorenne.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'Un osservatore vuole contattare {username} su Football IQ Universe. Per approvare o rifiutare questo contatto, apri l\'app, vai su Impostazioni > "Ho un codice tutore" e inserisci questo codice: {token}',
  },
  'ar': {
    'Retour':
        'رجوع',
    'Activer le son':
        'تشغيل الصوت',
    'Couper le son':
        'كتم الصوت',
    'Envoyer':
        'إرسال',
    'Vidéo, {n} vues':
        'فيديو، {n} مشاهدة',
    'Voir la vidéo':
        'مشاهدة الفيديو',
    'Mentions légales':
        'الإشعار القانوني',
    'Cookies':
        'ملفات تعريف الارتباط',
    'Règles des Ballons et remboursements':
        'قواعد الكرات والاسترداد',
    'Mes données':
        'بياناتي',
    'Demander une copie, une correction ou la suppression.':
        'اطلب نسخة أو تصحيحًا أو حذفًا.',
    'Licences':
        'التراخيص',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'لحذف حسابك وكل بياناتك، استخدم «حذف حسابي» أسفل هذه الصفحة. للحصول على نسخة من بياناتك أو تصحيحها أو الاعتراض على استخدامها، راسلنا من البريد الإلكتروني لحسابك: نرد خلال شهر.',
    'Fermer':
        'إغلاق',
    'Écrire un e-mail':
        'كتابة بريد إلكتروني',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'أوافق على شروط الاستخدام وقواعد الكرات، وقد قرأت سياسة الخصوصية.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'السعر شامل الضرائب، دفعة واحدة: لا اشتراك ولا رسوم خفية. تصل الكرات فور الدفع: في صفحة الدفع تطلب هذا التسليم الفوري وتتنازل عن مهلة التراجع البالغة 14 يومًا. الدفع المكرر أو عدم وصول الكرات: يُسترد المبلغ.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'الموهبة هي التي تتكلم، لا المتابعون. انشر مهاراتك ودع المجتمع يكتشفك أينما كنت.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'ابتكر حركة، وأعطها اسمك، وشاهد المجتمع يعيد تنفيذها. كل إعادة تحمل اسمك.',
    'Progresse, prouve, fais-toi remarquer':
        'تطوّر، أثبت نفسك، ولفت الأنظار',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'تقييمك يُكسب في الملعب، بفضل أصوات المجتمع. يعرض Football Passport تقدّمك للكشافين المسجّلين.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'سمِّ هذه الحركة: كل إعادة ستحمل اسمك.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'لحسابات الكشافين فقط · التواصل مع القاصرين يتم عبر وسيط.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'لا يمكن لأي كشّاف التواصل معك إلا بعد موافقة وليّ أمرك — أضف جهة اتصاله ليتمكنوا من التواصل معك.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'لا يُعرض أي موقع دقيق للعامة أبدًا. التواصل من أي كشّاف يتم دائمًا عبر وسيط لمن هم دون 18 عامًا.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'كشّاف يريد التواصل مع لاعب قاصر.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'كشّاف يريد التواصل مع {username} على Football IQ Universe. للموافقة على هذا التواصل أو رفضه، افتح التطبيق، واذهب إلى الإعدادات > "لدي رمز وليّ أمر" وأدخل هذا الرمز: {token}',
  },
  'ru': {
    'Retour':
        'Назад',
    'Activer le son':
        'Включить звук',
    'Couper le son':
        'Выключить звук',
    'Envoyer':
        'Отправить',
    'Vidéo, {n} vues':
        'Видео, {n} просмотров',
    'Voir la vidéo':
        'Смотреть видео',
    'Mentions légales':
        'Правовая информация',
    'Cookies':
        'Файлы cookie',
    'Règles des Ballons et remboursements':
        'Правила Мячей и возвраты',
    'Mes données':
        'Мои данные',
    'Demander une copie, une correction ou la suppression.':
        'Запросить копию, исправление или удаление.',
    'Licences':
        'Лицензии',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'Чтобы удалить аккаунт и все свои данные, нажми «Удалить мой аккаунт» внизу этой страницы. Чтобы получить копию данных, исправить их или возразить против их использования, напиши нам с почты своего аккаунта: мы ответим в течение месяца.',
    'Fermer':
        'Закрыть',
    'Écrire un e-mail':
        'Написать письмо',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'Я принимаю условия использования и правила Мячей и прочитал(а) политику конфиденциальности.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Цена с учётом налогов, разовый платёж: без подписки и скрытых комиссий. Мячи приходят сразу после оплаты: на странице оплаты ты просишь о немедленной доставке и отказываешься от 14-дневного срока на отказ от покупки. Двойной платёж или Мячи не пришли: возврат денег.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Говорит талант, а не подписчики. Публикуй свои финты и дай сообществу открыть тебя, где бы ты ни был.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Придумай финт, дай ему своё имя и смотри, как сообщество его повторяет. Каждый повтор носит твоё имя.',
    'Progresse, prouve, fais-toi remarquer':
        'Расти, докажи, заяви о себе',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Рейтинг зарабатывается на поле, голосами сообщества. Твой Football Passport показывает твой прогресс зарегистрированным скаутам.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Назови этот финт: каждый повтор будет носить твоё имя.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Только аккаунты скаутов · контакт с несовершеннолетними через посредника.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'Скаут может связаться с тобой только после одобрения опекуна — добавь его контакт, чтобы с тобой могли связаться.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'Точное местоположение никогда не публикуется. Контакт скаута с игроками младше 18 всегда идёт через посредника.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'Скаут хочет связаться с несовершеннолетним игроком.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'Скаут хочет связаться с {username} в Football IQ Universe. Чтобы одобрить или отклонить контакт, открой приложение, зайди в Настройки > «У меня есть код опекуна» и введи этот код: {token}',
  },
  'sv': {
    'Retour':
        'Tillbaka',
    'Activer le son':
        'Slå på ljud',
    'Couper le son':
        'Stäng av ljud',
    'Envoyer':
        'Skicka',
    'Vidéo, {n} vues':
        'Video, {n} visningar',
    'Voir la vidéo':
        'Se videon',
    'Mentions légales':
        'Juridisk information',
    'Cookies':
        'Cookies',
    'Règles des Ballons et remboursements':
        'Regler för Bollar och återbetalningar',
    'Mes données':
        'Mina uppgifter',
    'Demander une copie, une correction ou la suppression.':
        'Begär en kopia, rättelse eller radering.',
    'Licences':
        'Licenser',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'För att radera ditt konto och alla dina uppgifter, använd ”Radera mitt konto” längst ner på sidan. För att få en kopia av dina uppgifter, rätta dem eller invända mot hur de används, skriv till oss från ditt kontos e-postadress: vi svarar inom en månad.',
    'Fermer':
        'Stäng',
    'Écrire un e-mail':
        'Skriv ett mejl',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'Jag godkänner användarvillkoren och reglerna för Bollar, och jag har läst integritetspolicyn.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Pris inkl. moms, engångsbetalning: ingen prenumeration, inga dolda avgifter. Bollarna kommer direkt efter betalningen: på betalsidan begär du denna omedelbara leverans och avstår från ångerrätten på 14 dagar. Dubbel betalning eller uteblivna Bollar: återbetalas.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Talangen talar, inte följarna. Lägg upp dina tekniska finter och låt communityt upptäcka dig, var du än är.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Skapa en fint, ge den ditt namn och se communityt göra efter den. Varje kopia bär ditt namn.',
    'Progresse, prouve, fais-toi remarquer':
        'Utvecklas, bevisa det, bli sedd',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Ditt betyg förtjänas på planen, genom communityts röster. Ditt Football Passport visar din utveckling för registrerade scouter.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Namnge finten: varje kopia kommer att bära ditt namn.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Endast scoutkonton · kontakt förmedlas för minderåriga.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'En scout kan bara kontakta dig efter att en vårdnadshavare godkänt — lägg till hens kontaktuppgifter så att du kan bli kontaktad.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'Ingen exakt plats visas någonsin offentligt. Kontakt från en scout förmedlas alltid för under 18 år.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'En scout vill kontakta en minderårig spelare.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'En scout vill kontakta {username} på Football IQ Universe. För att godkänna eller neka kontakten, öppna appen, gå till Inställningar > "Jag har en vårdnadshavarkod" och ange den här koden: {token}',
  },
  'tr': {
    'Retour':
        'Geri',
    'Activer le son':
        'Sesi aç',
    'Couper le son':
        'Sesi kapat',
    'Envoyer':
        'Gönder',
    'Vidéo, {n} vues':
        'Video, {n} görüntülenme',
    'Voir la vidéo':
        'Videoyu izle',
    'Mentions légales':
        'Yasal bilgiler',
    'Cookies':
        'Çerezler',
    'Règles des Ballons et remboursements':
        'Top kuralları ve iadeler',
    'Mes données':
        'Verilerim',
    'Demander une copie, une correction ou la suppression.':
        'Kopya, düzeltme veya silme iste.',
    'Licences':
        'Lisanslar',
    'Pour supprimer ton compte et toutes tes données, utilise « Supprimer mon compte » en bas de cette page. Pour recevoir une copie de tes données, en corriger ou t\'opposer à leur utilisation, écris-nous depuis l\'adresse de ton compte : nous répondons sous un mois.':
        'Hesabını ve tüm verilerini silmek için bu sayfanın altındaki “Hesabımı sil” seçeneğini kullan. Verilerinin bir kopyasını almak, düzeltmek veya kullanımına itiraz etmek için hesabının e-posta adresinden bize yaz: bir ay içinde yanıt veririz.',
    'Fermer':
        'Kapat',
    'Écrire un e-mail':
        'E-posta yaz',
    'J\'accepte les conditions d\'utilisation et les règles des Ballons, et j\'ai lu la politique de confidentialité.':
        'Kullanım koşullarını ve Top kurallarını kabul ediyorum, gizlilik politikasını okudum.',
    'Prix TTC, paiement unique : pas d\'abonnement, pas de frais cachés. Les Ballons arrivent tout de suite après le paiement : sur la page de paiement, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours. Paiement en double ou Ballons non reçus : remboursés.':
        'Fiyatlara vergiler dahil, tek seferlik ödeme: abonelik yok, gizli ücret yok. Toplar ödemeden hemen sonra gelir: ödeme sayfasında bu anında teslimatı istersin ve 14 günlük cayma hakkından vazgeçersin. Çift ödeme veya ulaşmayan Toplar: iade edilir.',
    'Le talent parle, pas les followers. Poste tes gestes techniques et laisse la communauté te découvrir, où que tu sois.':
        'Konuşan yetenektir, takipçiler değil. Tekniklerini paylaş, nerede olursan ol topluluk seni keşfetsin.',
    'Crée un geste, donne-lui ton nom, et regarde la communauté le reproduire. Chaque reproduction porte ton nom.':
        'Bir hareket yarat, ona adını ver ve topluluğun onu tekrarlamasını izle. Her tekrar senin adını taşır.',
    'Progresse, prouve, fais-toi remarquer':
        'Geliş, kanıtla, dikkat çek',
    'Ta note se gagne sur le terrain, grâce aux votes de la communauté. Ton Football Passport montre ta progression aux recruteurs inscrits.':
        'Puanın sahada, topluluğun oylarıyla kazanılır. Football Passport\'un gelişimini kayıtlı scout\'lara gösterir.',
    'Nomme ce geste : chaque reproduction portera ton nom.':
        'Bu harekete isim ver: her tekrar senin adını taşıyacak.',
    'Réservé aux comptes recruteurs · contact médié pour les mineurs.':
        'Sadece scout hesapları · reşit olmayanlar için iletişim aracılıdır.',
    'Un recruteur ne peut te contacter qu\'après approbation d\'un tuteur — renseigne son contact pour pouvoir être approché.':
        'Bir scout seninle ancak velin onayladıktan sonra iletişime geçebilir — sana ulaşılabilmesi için velinin iletişim bilgisini ekle.',
    'Aucune géolocalisation précise publique. Le contact par un recruteur est toujours médié pour les moins de 18 ans.':
        'Hiçbir kesin konum asla herkese açık olmaz. 18 yaş altı için bir scout\'un iletişimi her zaman aracılı yapılır.',
    'Un recruteur souhaite contacter un joueur mineur.':
        'Bir scout, reşit olmayan bir oyuncuyla iletişime geçmek istiyor.',
    'Un recruteur souhaite contacter {username} sur Football IQ Universe. Pour approuver ou refuser ce contact, ouvre l\'app, va dans Réglages > "J\'ai un code tuteur" et saisis ce code : {token}':
        'Bir scout, Football IQ Universe\'te {username} ile iletişime geçmek istiyor. Bu iletişimi onaylamak ya da reddetmek için uygulamayı aç, Ayarlar > "Veli kodum var" bölümüne git ve şu kodu gir: {token}',
  },
};
