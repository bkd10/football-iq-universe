// Textes légaux, en français (version de référence) et en anglais. Les
// autres langues affichent la version anglaise avec une note en tête.
// `{company}`, `{email}`... sont remplacés par `LegalInfo.placeholders`.
// Une ligne qui commence par « ## » est un titre.
//
// À faire relire par un avocat avant la mise en vente.

const termsFr = r'''
Version {version}. En créant un compte, tu acceptes ces conditions.

## 1. Qui édite l'appli
Football IQ Universe est éditée par {company}, {legal_form}, {registration}, dont le siège est {address}. Contact : {email}. Responsable de la publication : {director}. Le site est hébergé par Cloudflare, Inc. et les données par Supabase, Inc.

## 2. À quoi sert l'appli
Football IQ Universe permet de publier des vidéos de football, de relever des défis, de se mesurer à d'autres joueurs et de se faire remarquer. L'appli ne garantit à personne d'être recruté par un club. L'appli est gratuite, sans abonnement. Seuls les Ballons peuvent être achetés, au prix affiché avant le paiement.

## 3. Inscription et âge
Il faut avoir au moins 13 ans. Entre 13 et 17 ans, le joueur doit avoir l'autorisation de ses parents (ou de son tuteur légal) : il l'atteste à l'inscription et donne l'e-mail d'un parent. Un parent peut demander à tout moment la suppression du compte de son enfant en écrivant à {email}. Les comptes recruteur et marque sont réservés aux majeurs. Les informations données à l'inscription doivent être exactes.

## 4. Ton compte
Ton mot de passe est personnel. Nous te conseillons d'activer la double authentification dans Réglages. Préviens-nous à {email} si tu penses que quelqu'un utilise ton compte.

## 5. Tes vidéos et ce qui est interdit
Tu restes propriétaire de tes vidéos. Tu nous autorises à les afficher dans l'appli tant qu'elles y sont publiées. Il est interdit de publier : de la violence, de la haine, du harcèlement, de la nudité, des contenus dangereux, des vidéos d'autres personnes sans leur accord, ou tout contenu illégal. Chacun peut signaler un contenu avec le bouton « Signaler » ou en écrivant à {email}. Nous examinons chaque signalement, retirons les contenus interdits et pouvons suspendre un compte qui ne respecte pas ces règles. Nous t'expliquons toujours pourquoi un de tes contenus est retiré ou ton compte suspendu, et tu peux contester la décision en écrivant à {email}.

## 6. Ballons et Stars
Les Ballons sont une monnaie virtuelle du jeu et les Stars mesurent ta réputation. Ni les uns ni les autres n'ont de valeur en argent. Leur fonctionnement, les prix et les remboursements sont décrits dans les Règles des Ballons, qui font partie de ces conditions.

## 7. Défis, Challenges et Battles
Ce sont des concours de talent : le gagnant est désigné par les votes de la communauté ou par un jury, jamais par le hasard. On ne gagne jamais d'argent. Pour entrer dans une Battle ou un Challenge, on dépense des Ballons, quoi qu'il arrive, et le gagnant ne remporte jamais les Ballons des autres : il n'y a ni mise ni cagnotte. Les défis sponsorisés par une marque, avec un vrai lot, sont gratuits et sans obligation d'achat ; le lot est remis par la marque, selon le règlement affiché sur le défi.

## 8. Recruteurs
Un recruteur ne peut contacter un joueur mineur qu'après l'accord de son parent ou tuteur. Le compte recruteur est gratuit pendant l'essai de 14 jours ; aucun paiement n'est demandé et l'essai ne se transforme jamais en abonnement payant sans ton accord.

## 9. Disponibilité et responsabilité
Nous faisons notre possible pour que l'appli fonctionne en continu, sans pouvoir le garantir. Nous ne sommes pas responsables des contenus publiés par les joueurs, mais nous les retirons dès qu'un contenu illégal nous est signalé.

## 10. Supprimer ton compte
Tu peux supprimer ton compte à tout moment dans Réglages > Supprimer mon compte. Tes vidéos et tes données sont alors effacées. Les Ballons et Stars restants sont perdus. Si tu ne peux plus te connecter, écris à {email}.

## 11. Droit applicable et litiges
Ces conditions sont soumises au droit français. En cas de désaccord, écris-nous d'abord à {email}. Tu peux aussi recourir gratuitement au médiateur de la consommation : {mediator}. À défaut, les tribunaux français sont compétents.

## 12. Changements
Nous pouvons modifier ces conditions. Nous te prévenons dans l'appli avant tout changement important.
''';

const termsEn = r'''
Version {version}. By creating an account, you accept these terms.

## 1. Who publishes the app
Football IQ Universe is published by {company}, {legal_form}, {registration}, registered office {address}. Contact: {email}. Publication director: {director}. The website is hosted by Cloudflare, Inc. and the data by Supabase, Inc.

## 2. What the app is for
Football IQ Universe lets you post football videos, take on challenges, compete with other players and get noticed. The app does not guarantee anyone will be signed by a club. The app is free, with no subscription. Only Balls can be bought, at the price shown before payment.

## 3. Sign-up and age
You must be at least 13. Between 13 and 17, players need permission from their parents (or legal guardian): they confirm it when signing up and give a parent's email. A parent can ask at any time for their child's account to be deleted by writing to {email}. Scout and brand accounts are for adults only. The information you give when signing up must be accurate.

## 4. Your account
Your password is personal. We recommend turning on two-factor authentication in Settings. Tell us at {email} if you think someone else is using your account.

## 5. Your videos and what is forbidden
You keep ownership of your videos. You allow us to show them in the app while they are posted. You must not post: violence, hate, harassment, nudity, dangerous content, videos of other people without their consent, or any illegal content. Anyone can report content with the “Report” button or by writing to {email}. We review every report, remove forbidden content and may suspend accounts that break these rules. We always tell you why your content was removed or your account suspended, and you can appeal by writing to {email}.

## 6. Balls and Stars
Balls are the game's virtual currency and Stars measure your reputation. Neither has any money value. How they work, prices and refunds are described in the Balls rules, which are part of these terms.

## 7. Challenges and Battles
These are talent contests: the winner is chosen by community votes or by a jury, never by chance. You never win money. Entering a Battle or Challenge costs Balls whatever happens, and the winner never takes the other players' Balls: there is no stake and no prize pool. Brand-sponsored challenges with a real prize are free with no purchase required; the prize is given by the brand under the rules shown on the challenge.

## 8. Scouts
A scout can only contact an underage player after their parent or guardian agrees. The scout account is free during the 14-day trial; no payment is asked and the trial never turns into a paid subscription without your consent.

## 9. Availability and liability
We do our best to keep the app running at all times but cannot guarantee it. We are not responsible for content posted by players, but we remove illegal content as soon as it is reported to us.

## 10. Deleting your account
You can delete your account at any time in Settings > Delete my account. Your videos and data are then erased. Any remaining Balls and Stars are lost. If you can no longer log in, write to {email}.

## 11. Governing law and disputes
These terms are governed by French law. If you disagree with something, write to us first at {email}. You can also use the consumer mediator free of charge: {mediator}. Otherwise, French courts have jurisdiction.

## 12. Changes
We may change these terms. We will let you know in the app before any important change.
''';

const privacyFr = r'''
Version {version}.

## Qui est responsable de tes données
{company}, {address}. Pour toute question sur tes données : {email}.

## Les données que nous gardons
Nous ne demandons que ce qui sert au jeu.
• Obligatoire : ton e-mail, ton pseudo, ton mot de passe (chiffré, nous ne le voyons jamais) et ta date de naissance (pour vérifier ton âge et protéger les mineurs).
• Facultatif, seulement si tu le donnes : nom affiché, photo, bio, pays, ville, poste, pied fort, taille, poids. Tu peux les effacer à tout moment dans « Modifier le profil ».
• Ce que tu fais dans l'appli : vidéos, réactions, commentaires, votes, abonnements, messages, défis, Ballons et Stars.
• Pour un joueur mineur : l'e-mail d'un parent et la date de son attestation d'accord parental.
• Pour un achat : le pack acheté, le prix et la date. Le paiement est traité par Stripe : nous ne voyons jamais ta carte bancaire.
• Si la double authentification est activée : la clé de ton appli de codes, gardée par Supabase.
• Des données techniques (type de navigateur, erreurs) pour réparer les bugs.
Nous ne collectons ni ta position GPS, ni tes contacts, et nous ne faisons aucune publicité ciblée.

## Pourquoi
• Faire fonctionner l'appli et ton compte (exécution du contrat).
• Protéger les comptes, modérer les contenus et lutter contre la triche (intérêt légitime).
• Protéger les mineurs, répondre aux autorités et garder les factures (obligation légale).

## Qui peut voir quoi
Ton profil public montre ton pseudo, ta photo, ta bio, ton poste, tes vidéos et tes statistiques. Ta date de naissance, ton e-mail et l'e-mail de ton parent ne sont jamais publics. Un recruteur ne peut contacter un mineur qu'après l'accord du parent. Nous ne vendons jamais tes données.

## Nos prestataires
• Supabase, Inc. : base de données, comptes et vidéos.
• Cloudflare, Inc. : hébergement du site.
• Stripe : paiements (seulement si tu achètes des Ballons).
• Sentry : suivi des erreurs, sans publicité ni profilage.
Les polices et le moteur d'affichage de l'appli sont hébergés chez nous : ton navigateur ne contacte ni Google ni aucun autre service pour afficher l'appli.
Certains sont situés hors de l'Union européenne (États-Unis notamment). Ces transferts sont encadrés par le cadre de protection des données UE–États-Unis ou par les clauses contractuelles types de la Commission européenne.

## Combien de temps
• Ton compte et tes contenus : tant que ton compte existe. Quand tu le supprimes, ton profil, tes vidéos, tes messages et tes données sont effacés tout de suite.
• Les données de connexion techniques : 1 an maximum.
• Les signalements et décisions de modération : 1 an, pour pouvoir répondre à une contestation.
• Les achats : 10 ans, comme la loi comptable l'exige, sans lien avec ton profil une fois le compte supprimé.

## Tes droits
Tu peux accéder à tes données, les corriger, les effacer, les récupérer dans un fichier, t'opposer à leur utilisation ou la limiter.
• Supprimer ton compte et toutes tes données : Réglages > Supprimer mon compte, sans avoir à te justifier.
• Pour tout le reste, ou si tu ne peux plus te connecter : Réglages > Mes données, ou écris à {email}. Nous répondons sous un mois.
Tu peux aussi te plaindre auprès de la CNIL (cnil.fr). Pour un mineur, ses parents peuvent exercer ces droits, y compris demander la suppression du compte.

## Cookies et stockage sur ton appareil
Voir la page « Cookies ». En résumé : seulement ce qui est indispensable (ta connexion et tes préférences), aucun cookie publicitaire ni de mesure d'audience.

## Changements
Nous te prévenons dans l'appli avant tout changement important de cette politique.
''';

const privacyEn = r'''
Version {version}.

## Who is responsible for your data
{company}, {address}. For any question about your data: {email}.

## The data we keep
We only ask for what the game needs.
• Required: your email, username, password (encrypted, we never see it) and date of birth (to check your age and protect minors).
• Optional, only if you give it: display name, photo, bio, country, city, position, strong foot, height, weight. You can remove them at any time in “Edit profile”.
• What you do in the app: videos, reactions, comments, votes, follows, messages, challenges, Balls and Stars.
• For an underage player: a parent's email and the date of the parental consent confirmation.
• For a purchase: the pack bought, the price and the date. Payment is handled by Stripe: we never see your bank card.
• If two-factor authentication is on: the key of your code app, kept by Supabase.
• Technical data (browser type, errors) to fix bugs.
We do not collect your GPS location or your contacts, and we do no targeted advertising.

## Why
• To run the app and your account (performance of the contract).
• To protect accounts, moderate content and fight cheating (legitimate interest).
• To protect minors, answer the authorities and keep invoices (legal obligation).

## Who can see what
Your public profile shows your username, photo, bio, position, videos and stats. Your date of birth, your email and your parent's email are never public. A scout can only contact a minor after the parent agrees. We never sell your data.

## Our providers
• Supabase, Inc.: database, accounts and videos.
• Cloudflare, Inc.: website hosting.
• Stripe: payments (only if you buy Balls).
• Sentry: error tracking, with no advertising or profiling.
The app's fonts and display engine are hosted by us: your browser does not contact Google or any other service to display the app.
Some are located outside the European Union (in particular the United States). These transfers are covered by the EU–US Data Privacy Framework or the European Commission's standard contractual clauses.

## How long
• Your account and content: as long as your account exists. When you delete it, your profile, videos, messages and data are erased right away.
• Technical connection data: 1 year at most.
• Reports and moderation decisions: 1 year, so we can answer an appeal.
• Purchases: 10 years, as accounting law requires, no longer linked to your profile once the account is deleted.

## Your rights
You can access, correct, delete or export your data, and object to or restrict its use.
• Delete your account and all your data: Settings > Delete my account, with no need to give a reason.
• For everything else, or if you can no longer log in: Settings > My data, or write to {email}. We answer within one month.
You can also complain to the CNIL (cnil.fr) or your local data protection authority. For a minor, their parents can exercise these rights, including asking for the account to be deleted.

## Cookies and storage on your device
See the “Cookies” page. In short: only what is essential (your login and preferences), no advertising or audience measurement cookies.

## Changes
We will let you know in the app before any important change to this policy.
''';

const ballonsFr = r'''
Version {version}. Ces règles font de Football IQ un jeu de talent, pas un jeu d'argent.

## 1. Les Ballons n'ont pas de valeur en argent
Les Ballons sont une monnaie virtuelle, utilisable seulement dans le jeu. Ils ne s'échangent jamais contre de l'argent, des biens ou des cadeaux, ne se revendent pas et ne se transfèrent pas à un autre joueur.

## 2. Gagner ou acheter des Ballons
Tu gagnes des Ballons en jouant : bonus de bienvenue, vidéos, missions, défis officiels gratuits. Tu peux aussi en acheter.

## 3. À quoi servent les Ballons
Les Ballons servent à entrer dans les Battles et les Challenges, et aux bonus (par exemple mettre une vidéo en avant). Une fois dépensés, ils ne reviennent pas, sauf si le défi est annulé ou n'a pas de vainqueur : l'entrée est alors remboursée.

## 4. Battles et Challenges : pas de mise, pas de cagnotte
L'entrée d'un défi est dépensée quoi qu'il arrive, comme une vie dans un jeu. Le gagnant ne remporte jamais les Ballons des autres joueurs : il gagne des Stars, des points de forme sur sa carte et une victoire au compteur. Le gagnant est désigné par les votes ou par un jury, selon le talent montré dans la vidéo, jamais par le hasard. Seuls les défis officiels gratuits peuvent offrir une récompense en Ballons, payée par l'appli.

## 5. Défis sponsorisés
Les défis d'une marque avec un vrai lot sont toujours gratuits, sans aucun achat nécessaire.

## 6. Joueurs mineurs
Un joueur de moins de 18 ans ne peut acheter des Ballons qu'avec l'accord de ses parents.

## 7. Prix, achats et remboursements
• Le prix affiché est le prix final, toutes taxes comprises (TTC). Il n'y a ni abonnement, ni frais de service, ni paiement récurrent : un achat = un paiement unique.
• Avant de payer, tu vois le nombre de Ballons et le prix. Le paiement se fait sur la page sécurisée de Stripe, qui t'envoie un reçu par e-mail.
• Les Ballons sont ajoutés tout de suite après le paiement. Comme ce sont des contenus numériques livrés immédiatement, tu dois, avant de payer, demander cette livraison immédiate et reconnaître que tu perds ton droit de rétractation de 14 jours (article L221-28, 13° du Code de la consommation). Sans cet accord, le paiement ne peut pas se faire.
• Nous remboursons intégralement : un paiement débité sans que les Ballons soient ajoutés, un paiement en double, ou un achat fait par un mineur sans l'accord de ses parents si les Ballons n'ont pas été dépensés. Pour cela, écris à {email} dans les 30 jours avec la date de l'achat ; nous répondons sous 14 jours et remboursons sur le moyen de paiement utilisé.
• Tes droits légaux de consommateur (garantie de conformité des contenus numériques) restent toujours valables.

## 8. Triche et fermeture du compte
Les Ballons obtenus en trichant sont retirés. Si tu supprimes ton compte, tes Ballons sont perdus.
''';

const ballonsEn = r'''
Version {version}. These rules make Football IQ a game of skill, not gambling.

## 1. Balls have no money value
Balls are a virtual currency, usable only in the game. They can never be exchanged for money, goods or gifts, cannot be resold and cannot be transferred to another player.

## 2. Earning or buying Balls
You earn Balls by playing: welcome bonus, videos, missions, free official challenges. You can also buy them.

## 3. What Balls are for
Balls are used to enter Battles and Challenges, and for bonuses (for example boosting a video). Once spent, they don't come back, unless the challenge is cancelled or has no winner: the entry is then refunded.

## 4. Battles and Challenges: no stake, no prize pool
A challenge entry is spent whatever happens, like a life in a game. The winner never takes the other players' Balls: they win Stars, form points on their card and a win on their record. The winner is chosen by votes or by a jury, based on the skill shown in the video, never by chance. Only free official challenges can offer a reward in Balls, paid by the app.

## 5. Sponsored challenges
Brand challenges with a real prize are always free, with no purchase required.

## 6. Underage players
A player under 18 can only buy Balls with their parents' consent.

## 7. Prices, purchases and refunds
• The price shown is the final price, all taxes included. There is no subscription, no service fee and no recurring payment: one purchase = one single payment.
• Before paying, you see the number of Balls and the price. Payment is made on Stripe's secure page, which emails you a receipt.
• Balls are added right after payment. As they are digital content delivered immediately, you must, before paying, ask for this immediate delivery and acknowledge that you lose your 14-day right of withdrawal (article L221-28, 13° of the French Consumer Code). Without this consent, payment cannot go through.
• We give a full refund for: a payment charged without the Balls being added, a duplicate payment, or a purchase made by a minor without their parents' consent if the Balls have not been spent. To ask, write to {email} within 30 days with the purchase date; we answer within 14 days and refund to the payment method used.
• Your legal consumer rights (conformity guarantee for digital content) always remain valid.

## 8. Cheating and closing your account
Balls obtained by cheating are removed. If you delete your account, your Balls are lost.
''';

const legalNoticeFr = r'''
## Éditeur de l'appli
{company}, {legal_form}, {registration}.
Siège : {address}.
Téléphone : {phone}. E-mail : {email}.
Numéro de TVA : {vat}.
Directeur de la publication : {director}.

## Hébergement
• Site : Cloudflare, Inc., 101 Townsend Street, San Francisco, CA 94107, États-Unis (cloudflare.com).
• Données, comptes et vidéos : Supabase, Inc., 970 Toa Payoh North #07-04, Singapour 318992 (supabase.com).
• Paiements : Stripe Payments Europe, Ltd., 1 Grand Canal Street Lower, Dublin 2, Irlande (stripe.com).

## Signaler un contenu illégal
Chaque vidéo et chaque profil a un bouton « Signaler ». Tu peux aussi écrire à {email}, qui est notre point de contact unique pour les utilisateurs et les autorités (règlement européen sur les services numériques), en français ou en anglais.

## Propriété intellectuelle
Le nom Football IQ Universe, l'appli et son design appartiennent à {company}. Les vidéos appartiennent à leurs auteurs. Les polices Montserrat, Inter, Barlow Condensed et Space Mono sont utilisées sous licence SIL Open Font License 1.1 et les icônes Material sous licence Apache 2.0 ; la liste complète des licences est dans Réglages > Licences.

## Litiges
En cas de désaccord, écris-nous d'abord à {email}. Tu peux ensuite recourir gratuitement au médiateur de la consommation : {mediator}.
''';

const legalNoticeEn = r'''
## Publisher of the app
{company}, {legal_form}, {registration}.
Registered office: {address}.
Phone: {phone}. Email: {email}.
VAT number: {vat}.
Publication director: {director}.

## Hosting
• Website: Cloudflare, Inc., 101 Townsend Street, San Francisco, CA 94107, United States (cloudflare.com).
• Data, accounts and videos: Supabase, Inc., 970 Toa Payoh North #07-04, Singapore 318992 (supabase.com).
• Payments: Stripe Payments Europe, Ltd., 1 Grand Canal Street Lower, Dublin 2, Ireland (stripe.com).

## Reporting illegal content
Every video and profile has a “Report” button. You can also write to {email}, our single point of contact for users and authorities (EU Digital Services Act), in French or English.

## Intellectual property
The Football IQ Universe name, the app and its design belong to {company}. Videos belong to their authors. The Montserrat, Inter, Barlow Condensed and Space Mono fonts are used under the SIL Open Font License 1.1 and Material icons under the Apache 2.0 license; the full list of licenses is in Settings > Licenses.

## Disputes
If you disagree with something, write to us first at {email}. You can then use the consumer mediator free of charge: {mediator}.
''';

const cookiesFr = r'''
Version {version}.

## Ce que l'appli garde sur ton appareil
L'appli n'utilise que des traceurs indispensables à son fonctionnement. Ils sont stockés dans ton navigateur (stockage local), pas envoyés à des tiers :
• Ta session de connexion (Supabase), pour que tu restes connecté. Supprimée quand tu te déconnectes.
• Tes préférences : écran d'accueil déjà vu, réglages du jeu.
• Pendant un paiement, Stripe peut déposer ses propres cookies sur sa page de paiement, uniquement pour la sécurité et la lutte contre la fraude.

## Ce que l'appli ne fait pas
Aucun cookie publicitaire, aucun pistage d'un site à l'autre, aucune mesure d'audience, aucun bouton de réseau social qui te suit.

## Pourquoi il n'y a pas de bandeau cookies
La loi (article 82 de la loi Informatique et Libertés, lignes directrices de la CNIL) n'exige un accord que pour les traceurs qui ne sont pas indispensables. Comme l'appli n'en utilise aucun, elle ne te demande rien. Si cela change un jour, un bandeau te demandera ton accord avant tout dépôt, avec un bouton « Refuser » aussi visible que « Accepter ».

## Effacer ces données
Te déconnecter efface ta session. Tu peux aussi effacer les données du site dans les réglages de ton navigateur.
''';

const cookiesEn = r'''
Version {version}.

## What the app keeps on your device
The app only uses trackers that are essential for it to work. They are stored in your browser (local storage), not sent to third parties:
• Your login session (Supabase), so you stay logged in. Removed when you log out.
• Your preferences: welcome screen already seen, game settings.
• During a payment, Stripe may set its own cookies on its payment page, only for security and fraud prevention.

## What the app does not do
No advertising cookies, no cross-site tracking, no audience measurement, no social media buttons that follow you.

## Why there is no cookie banner
The law (ePrivacy rules, French CNIL guidelines) only requires consent for trackers that are not essential. As the app uses none, it doesn't ask you anything. If that ever changes, a banner will ask for your consent before anything is stored, with a “Reject” button as visible as “Accept”.

## Clearing this data
Logging out clears your session. You can also clear the site's data in your browser settings.
''';
