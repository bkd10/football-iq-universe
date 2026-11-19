// Textes légaux, en français et en anglais. Les autres langues affichent
// la version anglaise avec une note en tête. `{company}`, `{email}`... sont
// remplacés par `LegalInfo.placeholders`. Une ligne qui commence par « ## »
// est un titre.
//
// Société britannique (Bkd sport Ltd, Londres) : droit anglais, UK GDPR,
// Children's Code de l'ICO, Online Safety Act 2023, Consumer Rights Act 2015.
// PROJET À FAIRE VALIDER PAR UN AVOCAT BRITANNIQUE avant toute publication
// sur les stores et tout sponsor. Ce n'est pas un avis juridique.

const termsFr = r'''
Version {version}. En créant un compte, tu acceptes ces conditions. Elles sont écrites simplement : si quelque chose n'est pas clair, écris-nous à {email}.

## 1. Qui édite l'appli
Football IQ Universe est éditée par {company}, société de droit anglais (private limited company) immatriculée en {place_of_registration} sous le numéro {company_number}, dont le siège est {address}, {city}, Royaume-Uni. Contact : {email}.

## 2. À quoi sert l'appli
Football IQ Universe permet de publier des vidéos de football, de relever des défis, de se mesurer à d'autres joueurs et de se faire remarquer. L'appli ne garantit à personne d'être recruté par un club. L'appli est gratuite, sans abonnement. Seuls les Ballons peuvent être achetés, au prix affiché avant le paiement, et jamais par un joueur mineur sans l'accord de ses parents.

## 3. Âge et inscription
Il faut avoir l'âge minimum affiché à l'inscription (13 ans aujourd'hui ; il peut être plus élevé dans certains pays). La date de naissance est obligatoire : elle sert à protéger les mineurs. Avant 18 ans, le joueur doit avoir l'autorisation de ses parents (ou de son tuteur légal) : il l'atteste et donne l'e-mail d'un parent. Un parent peut demander à tout moment la suppression du compte de son enfant en écrivant à {email}. Les comptes recruteur et marque sont réservés aux majeurs. Mentir sur son âge peut entraîner la fermeture du compte.

## 4. Protection des moins de 18 ans
Un compte de moins de 18 ans démarre avec les réglages les plus protecteurs : profil limité, messages privés seulement entre abonnés mutuels, pas de Battle contre un inconnu sans accord, ville masquée, aucun achat sans l'accord d'un parent, rappel de pause. Une marque ne peut jamais écrire en privé à un mineur. Un recruteur ne peut contacter un mineur qu'avec l'accord de son parent. Le détail est sur la page Sécurité.

## 5. Ton compte
Ton mot de passe est personnel. Active la double authentification dans Réglages. Préviens-nous à {email} si tu penses que quelqu'un utilise ton compte.

## 6. Tes vidéos et le droit à l'image
Tu restes propriétaire de tes vidéos. En publiant, tu confirmes que tu as le droit de le faire : c'est toi qui l'as filmée ou tu as l'accord de l'auteur, et chaque personne qu'on reconnaît est d'accord ; pour une personne mineure filmée (toi compris), un de ses parents est d'accord. Tu nous donnes le droit, gratuit et non exclusif, d'afficher ta vidéo dans l'appli (feed, profil, défis, classements) tant qu'elle y est publiée ; ce droit s'arrête quand tu la supprimes. Nous ne vendons pas tes vidéos et nous ne les utilisons pas dans nos publicités sans ton accord écrit (et celui de ton parent si tu es mineur).

## 7. Sponsors et défis sponsorisés
Un défi proposé par une marque est toujours marqué « Sponsorisé ». Il est gratuit, sans obligation d'achat, et son règlement est affiché sur le défi. Une marque peut voir les vidéos publiées dans son défi, comme tout le monde dans l'appli, mais elle ne peut pas les réutiliser ailleurs (publicité, réseaux sociaux…) sans l'accord écrit de leur auteur, et de son parent s'il est mineur. Une marque n'a jamais accès à tes coordonnées et ne peut pas t'écrire en privé si tu es mineur.

## 8. Ce qui est interdit
Il est interdit de publier ou d'envoyer : de la violence, de la haine, du harcèlement, des menaces, de la nudité ou des contenus sexuels, des contenus dangereux, des vidéos d'autres personnes sans leur accord, des coordonnées personnelles (les tiennes ou celles des autres), des liens vers d'autres sites pour attirer un joueur ailleurs, ou tout contenu illégal. Il est interdit de demander à un mineur des photos, des vidéos privées ou un rendez-vous.

## 9. Signaler, bloquer, contester
Chaque profil, vidéo, commentaire et message a un bouton « Signaler », et tu peux « Bloquer » n'importe quel joueur : il ne voit plus tes vidéos, ne peut plus te commenter ni t'écrire. Nous examinons chaque signalement, les plus urgents (mineur en danger) en premier. Une vidéo signalée par plusieurs personnes est masquée en attendant notre décision. Nous retirons les contenus interdits et pouvons suspendre un compte. Nous t'expliquons pourquoi un contenu est retiré ou un compte suspendu, et tu peux contester la décision en écrivant à {email} : une autre personne réexamine ta demande.

## 10. Ballons et Stars
Les Ballons sont une monnaie virtuelle du jeu et les Stars mesurent ta réputation. Ni les uns ni les autres n'ont de valeur en argent. Leur fonctionnement, les prix et les remboursements sont dans les Règles des Ballons, qui font partie de ces conditions.

## 11. Défis, Challenges et Battles
Ce sont des concours de talent : le gagnant est désigné par les votes ou par un jury, jamais par le hasard. On ne gagne jamais d'argent. L'entrée d'une Battle ou d'un Challenge coûte des Ballons quoi qu'il arrive ; il n'y a ni mise ni cagnotte.

## 12. Disponibilité et responsabilité
Nous faisons notre possible pour que l'appli fonctionne en continu, sans pouvoir le garantir. Rien dans ces conditions ne limite les droits que la loi te donne comme consommateur.

## 13. Supprimer ton compte
Tu peux supprimer ton compte à tout moment dans Réglages > Supprimer mon compte. Ton profil, tes vidéos, tes messages et tes réglages sont effacés tout de suite. Les Ballons et Stars restants sont perdus. Si tu ne peux plus te connecter, écris à {email}.

## 14. Droit applicable et litiges
Ces conditions sont soumises au droit anglais. Si tu habites ailleurs au Royaume-Uni ou dans un autre pays, tu gardes la protection des lois de ton pays et tu peux saisir les tribunaux de chez toi. En cas de désaccord, écris-nous d'abord à {email}. Règlement amiable des litiges : {adr}.

## 15. Changements
Nous pouvons modifier ces conditions. Nous te prévenons dans l'appli avant tout changement important.
''';

const termsEn = r'''
Version {version}. By creating an account, you accept these terms. They are written in plain language: if anything is unclear, write to us at {email}.

## 1. Who publishes the app
Football IQ Universe is published by {company}, a private limited company registered in {place_of_registration} under number {company_number}, registered office {address}, {city}, United Kingdom. Contact: {email}.

## 2. What the app is for
Football IQ Universe lets you post football videos, take on challenges, compete with other players and get noticed. The app does not guarantee anyone will be signed by a club. The app is free, with no subscription. Only Balls can be bought, at the price shown before payment, and never by an underage player without their parents' consent.

## 3. Age and sign-up
You must be at least the minimum age shown at sign-up (13 today; it may be higher in some countries). Your date of birth is required: it is used to protect minors. Under 18, players need permission from their parents (or legal guardian): they confirm it and give a parent's email. A parent can ask at any time for their child's account to be deleted by writing to {email}. Scout and brand accounts are for adults only. Lying about your age may lead to your account being closed.

## 4. Protection for under-18s
An under-18 account starts with the most protective settings: limited profile, private messages only between mutual followers, no Battles against strangers without consent, city hidden, no purchases without a parent's consent, break reminders. A brand can never send a private message to a minor. A scout can only contact a minor with their parent's consent. Details are on the Safety page.

## 5. Your account
Your password is personal. Turn on two-factor authentication in Settings. Tell us at {email} if you think someone else is using your account.

## 6. Your videos and image rights
You keep ownership of your videos. By posting, you confirm you have the right to do so: you filmed it or have the author's permission, and every recognisable person agrees; for anyone under 18 in the video (including you), one of their parents agrees. You give us a free, non-exclusive right to show your video in the app (feed, profile, challenges, rankings) while it is posted; this right ends when you delete it. We do not sell your videos and do not use them in our advertising without your written consent (and your parent's if you are under 18).

## 7. Sponsors and sponsored challenges
A challenge run by a brand is always labelled “Sponsored”. It is free, with no purchase required, and its rules are shown on the challenge. A brand can see the videos posted in its challenge, like anyone in the app, but cannot reuse them elsewhere (advertising, social media…) without the written consent of their author, and of their parent if they are under 18. A brand never has access to your contact details and cannot message you privately if you are under 18.

## 8. What is forbidden
You must not post or send: violence, hate, harassment, threats, nudity or sexual content, dangerous content, videos of other people without their consent, personal contact details (yours or anyone else's), links to other sites to lure a player elsewhere, or any illegal content. Asking a minor for photos, private videos or a meeting is forbidden.

## 9. Report, block, appeal
Every profile, video, comment and message has a “Report” button, and you can “Block” any player: they no longer see your videos and cannot comment on them or message you. We review every report, the most urgent ones (a minor at risk) first. A video reported by several people is hidden until we decide. We remove forbidden content and may suspend accounts. We tell you why content was removed or an account suspended, and you can appeal by writing to {email}: someone else reviews your request.

## 10. Balls and Stars
Balls are the game's virtual currency and Stars measure your reputation. Neither has any money value. How they work, prices and refunds are in the Balls rules, which are part of these terms.

## 11. Challenges and Battles
These are talent contests: the winner is chosen by votes or by a jury, never by chance. You never win money. Entering a Battle or Challenge costs Balls whatever happens; there is no stake and no prize pool.

## 12. Availability and liability
We do our best to keep the app running at all times but cannot guarantee it. Nothing in these terms limits your statutory rights as a consumer.

## 13. Deleting your account
You can delete your account at any time in Settings > Delete my account. Your profile, videos, messages and settings are erased right away. Any remaining Balls and Stars are lost. If you can no longer log in, write to {email}.

## 14. Governing law and disputes
These terms are governed by the law of England and Wales. If you live elsewhere in the UK or in another country, you keep the protection of your local laws and can go to your local courts. If you disagree with something, write to us first at {email}. Alternative dispute resolution: {adr}.

## 15. Changes
We may change these terms. We will let you know in the app before any important change.
''';

const privacyFr = r'''
Version {version}.

## En bref (pour les moins de 18 ans)
• On ne te demande que ce qui sert au jeu : un e-mail, un pseudo, un mot de passe et ta date de naissance.
• Ta date de naissance, ton e-mail et celui de ton parent ne sont jamais montrés à personne.
• Ton profil est limité : les inconnus ne voient que ton pseudo, ton niveau et ton poste. Ta ville est cachée.
• Seuls tes abonnés mutuels peuvent t'écrire en privé. Une marque ne peut jamais t'écrire.
• On ne connaît pas ta position GPS, on ne lit pas tes contacts, on ne fait pas de publicité ciblée, on ne vend jamais tes données.
• Tu peux bloquer ou signaler n'importe qui, et tout supprimer d'un coup dans Réglages.
• Une question, un souci ? Écris à {safety_email}, ou parle-en à un adulte de confiance.

## Qui est responsable de tes données
{company}, {address}, {city}, Royaume-Uni (enregistrée auprès de l'ICO sous le numéro {ico}). Pour toute question sur tes données : {email}. Représentant dans l'Union européenne : {eu_rep}.

## Les données que nous gardons
• Obligatoire : ton e-mail, ton pseudo, ton mot de passe (chiffré, nous ne le voyons jamais) et ta date de naissance (pour vérifier ton âge et appliquer la protection des mineurs).
• Facultatif, seulement si tu le donnes : nom affiché, photo, bio, pays, ville, poste, pied fort, taille, poids. Tu peux les effacer à tout moment dans « Modifier le profil ».
• Ce que tu fais dans l'appli : vidéos, réactions, commentaires, votes, abonnements, messages, défis, Ballons, Stars, joueurs bloqués, signalements.
• Pour un joueur mineur : l'e-mail d'un parent, la date de l'attestation d'accord parental et, s'il y a lieu, la date de l'accord pour les achats.
• Tes réglages de sécurité (profil limité, messages, Battles, rappel de pause).
• Pour un achat : le pack, le prix et la date. Le paiement est traité par Stripe : nous ne voyons jamais ta carte.
• Des données techniques (type d'appareil, erreurs) pour réparer les bugs.
Nous ne collectons ni ta position GPS, ni tes contacts, ni ton micro en dehors des vidéos que tu choisis de publier.

## Pourquoi (base légale)
• Faire fonctionner l'appli et ton compte (contrat).
• Protéger les mineurs, modérer les contenus, lutter contre la triche et répondre aux autorités (obligation légale et intérêt légitime).
• Garder les preuves d'achat (obligation légale).
Nous ne faisons pas de profilage publicitaire. Le classement et la « Pépite du jour » reposent sur les réactions aux vidéos, pas sur ta vie privée.

## Qui peut voir quoi
Pour un majeur, le profil public montre le pseudo, la photo, le poste, les vidéos et les statistiques. Pour un mineur, le profil est limité par défaut. Ta date de naissance, ton e-mail et l'e-mail de ton parent ne sont jamais publics. Les modérateurs peuvent lire un message privé seulement s'il a été signalé. Nous ne vendons jamais tes données.

## Nos prestataires
• Supabase, Inc. : base de données, comptes et vidéos.
• Cloudflare, Inc. : hébergement du site.
• Stripe : paiements (seulement pour un achat).
• Sentry : suivi des erreurs, sans publicité ni profilage.
Certains sont situés hors du Royaume-Uni (États-Unis notamment). Ces transferts sont encadrés par les garanties prévues par la loi britannique (UK Extension au Data Privacy Framework ou clauses contractuelles approuvées par l'ICO).

## Combien de temps
• Ton compte et tes contenus : tant que ton compte existe. Quand tu le supprimes, ton profil, tes vidéos, tes messages, tes réglages et tes consentements sont effacés tout de suite.
• Les signalements et décisions de modération : 1 an, pour répondre à une contestation.
• Les achats : 6 ans, comme la loi comptable britannique l'exige, sans lien avec ton profil une fois le compte supprimé.

## Tes droits
Tu peux accéder à tes données, les corriger, les effacer, les récupérer, t'opposer à leur utilisation ou la limiter.
• Tout supprimer : Réglages > Supprimer mon compte, sans te justifier.
• Pour le reste : Réglages > Mes données, ou écris à {email}. Nous répondons sous un mois.
Tu peux te plaindre auprès de l'ICO (ico.org.uk), l'autorité britannique de protection des données, ou de celle de ton pays (en France, la CNIL). Pour un mineur, ses parents peuvent exercer ces droits, y compris demander la suppression du compte.

## Cookies
Seulement ce qui est indispensable (ta connexion et tes préférences). Voir la page « Cookies ».

## Changements
Nous te prévenons dans l'appli avant tout changement important de cette politique.
''';

const privacyEn = r'''
Version {version}.

## In short (for under-18s)
• We only ask for what the game needs: an email, a username, a password and your date of birth.
• Your date of birth, your email and your parent's email are never shown to anyone.
• Your profile is limited: strangers only see your username, level and position. Your city is hidden.
• Only your mutual followers can message you privately. A brand can never message you.
• We don't know your GPS location, we don't read your contacts, we do no targeted advertising and we never sell your data.
• You can block or report anyone, and delete everything at once in Settings.
• A question or a problem? Write to {safety_email}, or talk to an adult you trust.

## Who is responsible for your data
{company}, {address}, {city}, United Kingdom (registered with the ICO under number {ico}). For any question about your data: {email}. Representative in the European Union: {eu_rep}.

## The data we keep
• Required: your email, username, password (encrypted, we never see it) and date of birth (to check your age and apply child protection).
• Optional, only if you give it: display name, photo, bio, country, city, position, strong foot, height, weight. You can remove them at any time in “Edit profile”.
• What you do in the app: videos, reactions, comments, votes, follows, messages, challenges, Balls, Stars, blocked players, reports.
• For an underage player: a parent's email, the date of the parental consent confirmation and, if any, the date of consent for purchases.
• Your safety settings (limited profile, messages, Battles, break reminders).
• For a purchase: the pack, the price and the date. Payment is handled by Stripe: we never see your card.
• Technical data (device type, errors) to fix bugs.
We do not collect your GPS location, your contacts, or your microphone outside the videos you choose to post.

## Why (legal basis)
• To run the app and your account (contract).
• To protect minors, moderate content, fight cheating and answer the authorities (legal obligation and legitimate interest).
• To keep proof of purchase (legal obligation).
We do no advertising profiling. Rankings and the “Gem of the day” are based on reactions to videos, not on your private life.

## Who can see what
For adults, the public profile shows the username, photo, position, videos and stats. For minors, the profile is limited by default. Your date of birth, your email and your parent's email are never public. Moderators can read a private message only if it has been reported. We never sell your data.

## Our providers
• Supabase, Inc.: database, accounts and videos.
• Cloudflare, Inc.: website hosting.
• Stripe: payments (only for a purchase).
• Sentry: error tracking, with no advertising or profiling.
Some are located outside the UK (in particular the United States). These transfers are covered by the safeguards required by UK law (UK Extension to the Data Privacy Framework or ICO-approved contract clauses).

## How long
• Your account and content: as long as your account exists. When you delete it, your profile, videos, messages, settings and consents are erased right away.
• Reports and moderation decisions: 1 year, so we can answer an appeal.
• Purchases: 6 years, as UK accounting law requires, no longer linked to your profile once the account is deleted.

## Your rights
You can access, correct, delete or export your data, and object to or restrict its use.
• Delete everything: Settings > Delete my account, with no need to give a reason.
• For everything else: Settings > My data, or write to {email}. We answer within one month.
You can complain to the ICO (ico.org.uk), the UK data protection authority, or to the authority of your country. For a minor, their parents can exercise these rights, including asking for the account to be deleted.

## Cookies
Only what is essential (your login and preferences). See the “Cookies” page.

## Changes
We will let you know in the app before any important change to this policy.
''';

const ballonsFr = r'''
Version {version}. Ces règles font de Football IQ un jeu de talent, pas un jeu d'argent.

## 1. Les Ballons n'ont pas de valeur en argent
Les Ballons sont une monnaie virtuelle, utilisable seulement dans le jeu. Ils ne s'échangent jamais contre de l'argent, des biens ou des cadeaux, ne se revendent pas et ne se transfèrent pas à un autre joueur.

## 2. Gagner ou acheter des Ballons
Tu gagnes des Ballons en jouant : bonus de bienvenue, vidéos, missions, défis officiels gratuits. Un majeur peut aussi en acheter. Acheter n'est jamais nécessaire pour jouer, progresser ou gagner.

## 3. À quoi servent les Ballons
Les Ballons servent à entrer dans les Battles et les Challenges, et aux bonus. Une fois dépensés, ils ne reviennent pas, sauf si le défi est annulé ou n'a pas de vainqueur : l'entrée est alors remboursée.

## 4. Pas de mise, pas de cagnotte
L'entrée d'un défi est dépensée quoi qu'il arrive. Le gagnant ne remporte jamais les Ballons des autres : il gagne des Stars, des points de forme et une victoire au compteur. Le gagnant est désigné par les votes ou un jury, jamais par le hasard.

## 5. Défis sponsorisés
Les défis d'une marque sont toujours marqués « Sponsorisé », gratuits et sans achat nécessaire.

## 6. Joueurs mineurs
Par défaut, un joueur de moins de 18 ans ne peut pas acheter de Ballons. Si nous ouvrons un jour les achats aux mineurs, ce sera seulement avec l'accord d'un parent donné depuis un lien personnel, avec un plafond mensuel, et l'appli ne montrera jamais de message poussant un mineur à acheter.

## 7. Prix, achats et remboursements
• Le prix affiché est le prix final, taxes comprises. Il n'y a ni abonnement, ni frais cachés, ni paiement récurrent : un achat = un paiement unique.
• Avant de payer, tu vois le nombre de Ballons et le prix réel. Le paiement se fait sur la page sécurisée de Stripe, qui t'envoie un reçu.
• Les Ballons sont ajoutés tout de suite. Comme ce sont des contenus numériques livrés immédiatement, tu demandes cette livraison immédiate et tu reconnais perdre ton droit d'annulation de 14 jours (Consumer Contracts Regulations 2013). Sans cet accord, le paiement ne peut pas se faire.
• Nous remboursons intégralement : un paiement débité sans Ballons ajoutés, un paiement en double, ou un achat fait par un mineur sans l'accord de ses parents. Écris à {email} avec la date de l'achat ; nous répondons sous 14 jours.
• Tes droits légaux (Consumer Rights Act 2015 : contenu numérique conforme à sa description) restent toujours valables.

## 8. Triche et fermeture du compte
Les Ballons obtenus en trichant sont retirés. Si tu supprimes ton compte, tes Ballons sont perdus.
''';

const ballonsEn = r'''
Version {version}. These rules make Football IQ a game of skill, not gambling.

## 1. Balls have no money value
Balls are a virtual currency, usable only in the game. They can never be exchanged for money, goods or gifts, cannot be resold and cannot be transferred to another player.

## 2. Earning or buying Balls
You earn Balls by playing: welcome bonus, videos, missions, free official challenges. Adults can also buy them. Buying is never needed to play, progress or win.

## 3. What Balls are for
Balls are used to enter Battles and Challenges, and for bonuses. Once spent, they don't come back, unless the challenge is cancelled or has no winner: the entry is then refunded.

## 4. No stake, no prize pool
A challenge entry is spent whatever happens. The winner never takes the other players' Balls: they win Stars, form points and a win on their record. The winner is chosen by votes or a jury, never by chance.

## 5. Sponsored challenges
Brand challenges are always labelled “Sponsored”, free, with no purchase required.

## 6. Underage players
By default, players under 18 cannot buy Balls. If we ever open purchases to minors, it will only be with a parent's consent given from a personal link, with a monthly cap, and the app will never show a message pushing a minor to buy.

## 7. Prices, purchases and refunds
• The price shown is the final price, taxes included. There is no subscription, no hidden fee and no recurring payment: one purchase = one single payment.
• Before paying, you see the number of Balls and the real price. Payment is made on Stripe's secure page, which emails you a receipt.
• Balls are added right away. As they are digital content delivered immediately, you ask for this immediate delivery and acknowledge that you lose your 14-day cancellation right (Consumer Contracts Regulations 2013). Without this consent, payment cannot go through.
• We give a full refund for: a payment charged without Balls added, a duplicate payment, or a purchase made by a minor without their parents' consent. Write to {email} with the purchase date; we answer within 14 days.
• Your statutory rights (Consumer Rights Act 2015: digital content as described) always remain valid.

## 8. Cheating and closing your account
Balls obtained by cheating are removed. If you delete your account, your Balls are lost.
''';

const legalNoticeFr = r'''
## Éditeur de l'appli
{company}, private limited company de droit anglais.
Immatriculée en {place_of_registration} (Companies House) sous le numéro {company_number}.
Siège (registered office) : {address}, {city}, Royaume-Uni.
E-mail : {email}.
Numéro de TVA : {vat}.
Enregistrement auprès de l'ICO : {ico}.
Représentant dans l'Union européenne : {eu_rep}.

## Hébergement
• Site : Cloudflare, Inc., 101 Townsend Street, San Francisco, CA 94107, États-Unis (cloudflare.com).
• Données, comptes et vidéos : Supabase, Inc. (supabase.com).
• Paiements : Stripe Payments UK, Ltd. (stripe.com).

## Signaler un contenu illégal ou un danger
Chaque profil, vidéo, commentaire et message a un bouton « Signaler ». Tu peux aussi écrire à {safety_email}. En cas de danger immédiat, appelle le 999 au Royaume-Uni ou le 112 en Europe.

## Propriété intellectuelle
Le nom Football IQ Universe, l'appli et son design appartiennent à {company}. Les vidéos appartiennent à leurs auteurs. Les polices sont utilisées sous licence SIL Open Font License 1.1 et les icônes Material sous licence Apache 2.0 ; la liste complète est dans Réglages > Licences.

## Litiges
Droit anglais. En cas de désaccord, écris-nous d'abord à {email}. Règlement amiable : {adr}.
''';

const legalNoticeEn = r'''
## Publisher of the app
{company}, a private limited company under English law.
Registered in {place_of_registration} (Companies House) under number {company_number}.
Registered office: {address}, {city}, United Kingdom.
Email: {email}.
VAT number: {vat}.
ICO registration: {ico}.
Representative in the European Union: {eu_rep}.

## Hosting
• Website: Cloudflare, Inc., 101 Townsend Street, San Francisco, CA 94107, United States (cloudflare.com).
• Data, accounts and videos: Supabase, Inc. (supabase.com).
• Payments: Stripe Payments UK, Ltd. (stripe.com).

## Reporting illegal content or danger
Every profile, video, comment and message has a “Report” button. You can also write to {safety_email}. In immediate danger, call 999 in the UK or 112 in Europe.

## Intellectual property
The Football IQ Universe name, the app and its design belong to {company}. Videos belong to their authors. Fonts are used under the SIL Open Font License 1.1 and Material icons under the Apache 2.0 license; the full list is in Settings > Licenses.

## Disputes
Law of England and Wales. If you disagree with something, write to us first at {email}. Alternative dispute resolution: {adr}.
''';

const cookiesFr = r'''
Version {version}.

## Ce que l'appli garde sur ton appareil
Seulement ce qui est indispensable, stocké dans ton navigateur ou ton téléphone, jamais envoyé à des tiers :
• Ta session de connexion, pour que tu restes connecté. Supprimée quand tu te déconnectes.
• Tes préférences : écran d'accueil déjà vu, réglages du jeu.
• Pendant un paiement, Stripe peut déposer ses propres cookies sur sa page, pour la sécurité et la lutte contre la fraude.

## Ce que l'appli ne fait pas
Aucun cookie publicitaire, aucun pistage d'un site à l'autre, aucune mesure d'audience, aucun bouton de réseau social qui te suit.

## Pourquoi il n'y a pas de bandeau cookies
La loi britannique (PECR) et les règles européennes n'exigent un accord que pour les traceurs non indispensables. L'appli n'en utilise aucun. Si cela change, un bandeau te demandera ton accord avant, avec un bouton « Refuser » aussi visible que « Accepter », et rien ne sera activé par défaut pour un mineur.

## Effacer ces données
Te déconnecter efface ta session. Tu peux aussi effacer les données du site dans les réglages de ton navigateur.
''';

const cookiesEn = r'''
Version {version}.

## What the app keeps on your device
Only what is essential, stored in your browser or phone, never sent to third parties:
• Your login session, so you stay logged in. Removed when you log out.
• Your preferences: welcome screen already seen, game settings.
• During a payment, Stripe may set its own cookies on its page, for security and fraud prevention.

## What the app does not do
No advertising cookies, no cross-site tracking, no audience measurement, no social media buttons that follow you.

## Why there is no cookie banner
UK law (PECR) and EU rules only require consent for non-essential trackers. The app uses none. If that changes, a banner will ask for your consent first, with a “Reject” button as visible as “Accept”, and nothing will be switched on by default for a minor.

## Clearing this data
Logging out clears your session. You can also clear the site's data in your browser settings.
''';

const safetyFr = r'''
Version {version}. Football IQ est fait pour des joueurs de 15 à 22 ans, dont beaucoup ont moins de 18 ans. Voici comment nous te protégeons et comment obtenir de l'aide.

## Si tu es en danger
En cas de danger immédiat, appelle le 999 (Royaume-Uni) ou le 112 (Europe). Si quelque chose te met mal à l'aise, parles-en à un adulte de confiance. Au Royaume-Uni, Childline écoute gratuitement les jeunes au 0800 1111 (childline.org.uk). En France : 119 (enfance en danger) et 3018 (harcèlement en ligne).

## Ce qui est activé d'office avant 18 ans
• Profil limité : les inconnus voient seulement ton pseudo, ton niveau et ton poste.
• Messages privés seulement avec tes abonnés mutuels (vous vous suivez tous les deux). Une marque ne peut jamais t'écrire. Un recruteur doit en plus avoir l'accord de ton parent.
• Pas de Battle contre un adversaire tiré au hasard, sauf si tu l'acceptes.
• Ta ville est cachée et nous ne collectons jamais ta position GPS.
• Aucun achat de Ballons sans l'accord d'un parent, et aucune incitation à acheter.
• Des séries de jours sans perte et un rappel de pause.
Tu peux changer ces réglages dans Réglages > Sécurité et confidentialité, de préférence avec tes parents.

## Bloquer et signaler
Sur chaque profil, vidéo, commentaire et message, touche « … » ou le drapeau : « Signaler » ou « Bloquer ». Un joueur bloqué ne voit plus tes vidéos ni ton profil, ne peut plus te commenter, te suivre ni t'écrire, et il n'est pas prévenu. Les signalements qui concernent un mineur sont traités en premier, et une vidéo signalée par plusieurs personnes est masquée tout de suite en attendant la décision.

## Règles pour tous
Ne donne jamais ton adresse, ton école, ton numéro ou tes réseaux sociaux. Personne n'a le droit de te demander des photos, des vidéos privées ou un rendez-vous : signale-le. Un vrai recruteur passe toujours par l'appli et par tes parents.

## Pour les parents
Vous pouvez nous écrire à {safety_email} pour toute question, pour demander la suppression du compte de votre enfant ou pour signaler un problème. Le contact d'un recruteur avec un mineur demande toujours votre accord. Les achats sont désactivés pour les mineurs.

## Nous contacter
Sécurité des jeunes : {safety_email}. Tout le reste : {email}. {company}, {address}, {city}, Royaume-Uni.
''';

const safetyEn = r'''
Version {version}. Football IQ is made for players aged 15 to 22, many of them under 18. Here is how we protect you and how to get help.

## If you are in danger
In immediate danger, call 999 (UK) or 112 (Europe). If something makes you feel uncomfortable, talk to an adult you trust. In the UK, Childline listens to young people for free on 0800 1111 (childline.org.uk).

## What is switched on by default under 18
• Limited profile: strangers only see your username, level and position.
• Private messages only with your mutual followers (you follow each other). A brand can never message you. A scout also needs your parent's consent.
• No Battles against a randomly picked opponent unless you accept them.
• Your city is hidden and we never collect your GPS location.
• No Balls purchases without a parent's consent, and no pressure to buy.
• Day streaks with no loss, and break reminders.
You can change these in Settings > Safety and privacy, ideally with your parents.

## Block and report
On every profile, video, comment and message, tap “…” or the flag: “Report” or “Block”. A blocked player no longer sees your videos or profile, cannot comment, follow or message you, and is not told. Reports involving a minor are handled first, and a video reported by several people is hidden straight away until we decide.

## Rules for everyone
Never share your address, school, phone number or social media. Nobody may ask you for photos, private videos or a meeting: report it. A real scout always goes through the app and your parents.

## For parents
You can write to us at {safety_email} with any question, to ask for your child's account to be deleted or to report a problem. A scout contacting a minor always needs your consent. Purchases are switched off for minors.

## Contact us
Youth safety: {safety_email}. Everything else: {email}. {company}, {address}, {city}, United Kingdom.
''';
