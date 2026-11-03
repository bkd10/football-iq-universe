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
Football IQ Universe permet de publier des vidéos de football, de relever des défis, de se mesurer à d'autres joueurs et d'être repéré. L'appli est gratuite. Certains bonus peuvent être achetés.

## 3. Inscription et âge
Il faut avoir au moins 13 ans. Entre 13 et 17 ans, le joueur doit avoir l'autorisation de ses parents (ou de son tuteur légal) : il l'atteste à l'inscription et donne l'e-mail d'un parent. Un parent peut demander à tout moment la suppression du compte de son enfant en écrivant à {email}. Les comptes recruteur et marque sont réservés aux majeurs. Les informations données à l'inscription doivent être exactes.

## 4. Ton compte
Ton mot de passe est personnel. Nous te conseillons d'activer la double authentification dans Réglages. Préviens-nous à {email} si tu penses que quelqu'un utilise ton compte.

## 5. Tes vidéos et ce qui est interdit
Tu restes propriétaire de tes vidéos. Tu nous autorises à les afficher dans l'appli tant qu'elles y sont publiées. Il est interdit de publier : de la violence, de la haine, du harcèlement, de la nudité, des contenus dangereux, des vidéos d'autres personnes sans leur accord, ou tout contenu illégal. Chacun peut signaler un contenu. Nous retirons les contenus interdits et pouvons suspendre un compte qui ne respecte pas ces règles.

## 6. Ballons et Stars
Les Ballons sont une monnaie virtuelle du jeu et les Stars mesurent ta réputation. Ni les uns ni les autres n'ont de valeur en argent. Leur fonctionnement est décrit dans les Règles des Ballons, qui font partie de ces conditions.

## 7. Défis, Challenges et Battles
Ce sont des concours de talent : le gagnant est désigné par les votes de la communauté ou par un jury, jamais par le hasard. On ne gagne jamais d'argent. Pour entrer dans une Battle ou un Challenge, on dépense des Ballons, quoi qu'il arrive, et le gagnant ne remporte jamais les Ballons des autres : il n'y a ni mise ni cagnotte. Les défis sponsorisés par une marque, avec un vrai lot, sont gratuits et sans obligation d'achat ; le lot est remis par la marque, selon le règlement affiché sur le défi.

## 8. Recruteurs
Un recruteur ne peut contacter un joueur mineur qu'après l'accord de son parent ou tuteur.

## 9. Disponibilité et responsabilité
Nous faisons notre possible pour que l'appli fonctionne en continu, sans pouvoir le garantir. Nous ne sommes pas responsables des contenus publiés par les joueurs, mais nous les retirons dès qu'un contenu illégal nous est signalé.

## 10. Supprimer ton compte
Tu peux supprimer ton compte à tout moment dans Réglages. Tes vidéos et tes données sont alors effacées. Les Ballons et Stars restants sont perdus.

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
Football IQ Universe lets you post football videos, take on challenges, compete with other players and get scouted. The app is free. Some bonuses can be bought.

## 3. Sign-up and age
You must be at least 13. Between 13 and 17, players need permission from their parents (or legal guardian): they confirm it when signing up and give a parent's email. A parent can ask at any time for their child's account to be deleted by writing to {email}. Scout and brand accounts are for adults only. The information you give when signing up must be accurate.

## 4. Your account
Your password is personal. We recommend turning on two-factor authentication in Settings. Tell us at {email} if you think someone else is using your account.

## 5. Your videos and what is forbidden
You keep ownership of your videos. You allow us to show them in the app while they are posted. You must not post: violence, hate, harassment, nudity, dangerous content, videos of other people without their consent, or any illegal content. Anyone can report content. We remove forbidden content and may suspend accounts that break these rules.

## 6. Balls and Stars
Balls are the game's virtual currency and Stars measure your reputation. Neither has any money value. How they work is described in the Balls rules, which are part of these terms.

## 7. Challenges and Battles
These are talent contests: the winner is chosen by community votes or by a jury, never by chance. You never win money. Entering a Battle or Challenge costs Balls whatever happens, and the winner never takes the other players' Balls: there is no stake and no prize pool. Brand-sponsored challenges with a real prize are free with no purchase required; the prize is given by the brand under the rules shown on the challenge.

## 8. Scouts
A scout can only contact an underage player after their parent or guardian agrees.

## 9. Availability and liability
We do our best to keep the app running at all times but cannot guarantee it. We are not responsible for content posted by players, but we remove illegal content as soon as it is reported to us.

## 10. Deleting your account
You can delete your account at any time in Settings. Your videos and data are then erased. Any remaining Balls and Stars are lost.

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
• Ton e-mail, ton pseudo, ta date de naissance, et si tu les donnes : pays, ville, poste, pied fort, taille, poids, photo, bio.
• Tes vidéos, tes réactions, commentaires, votes, abonnements et messages.
• Pour un joueur mineur : l'e-mail d'un parent et la date de son attestation d'accord parental.
• Pour un achat : le pack acheté et la date. Le paiement est traité par Stripe : nous ne voyons jamais ta carte bancaire.
• Des données techniques (type d'appareil, erreurs) pour réparer les bugs.

## Pourquoi
Faire fonctionner l'appli (contrat), protéger les comptes et lutter contre la triche (intérêt légitime), protéger les mineurs et respecter la loi (obligation légale, accord parental), et tenir les comptes des achats (obligation comptable).

## Qui peut voir quoi
Ton profil public montre ton pseudo, tes vidéos et tes statistiques. Ta date de naissance, ton e-mail et l'e-mail de ton parent ne sont jamais publics. Un recruteur ne peut contacter un mineur qu'après l'accord du parent.

## Nos prestataires
Supabase (base de données et comptes), Cloudflare (site), Stripe (paiements), Sentry (suivi des erreurs). Certains sont situés hors de l'Union européenne ; les transferts sont encadrés par les clauses contractuelles types de la Commission européenne.

## Combien de temps
Tant que ton compte existe. Quand tu supprimes ton compte, tes données et tes vidéos sont effacées. Les factures sont gardées 10 ans, comme la loi l'exige.

## Tes droits
Tu peux accéder à tes données, les corriger, les effacer, les récupérer, t'opposer à leur utilisation ou la limiter, en écrivant à {email}. Tu peux aussi te plaindre auprès de la CNIL (cnil.fr). Pour un mineur, ses parents peuvent exercer ces droits.

## Cookies
L'appli garde seulement ta session de connexion et tes préférences sur ton appareil. Pas de publicité, pas de pistage publicitaire.
''';

const privacyEn = r'''
Version {version}.

## Who is responsible for your data
{company}, {address}. For any question about your data: {email}.

## The data we keep
• Your email, username, date of birth, and if you give them: country, city, position, strong foot, height, weight, photo, bio.
• Your videos, reactions, comments, votes, follows and messages.
• For an underage player: a parent's email and the date of the parental consent confirmation.
• For a purchase: the pack bought and the date. Payment is handled by Stripe: we never see your bank card.
• Technical data (device type, errors) to fix bugs.

## Why
To run the app (contract), protect accounts and fight cheating (legitimate interest), protect minors and comply with the law (legal obligation, parental consent), and keep purchase records (accounting obligation).

## Who can see what
Your public profile shows your username, videos and stats. Your date of birth, your email and your parent's email are never public. A scout can only contact a minor after the parent agrees.

## Our providers
Supabase (database and accounts), Cloudflare (website), Stripe (payments), Sentry (error tracking). Some are located outside the European Union; transfers are covered by the European Commission's standard contractual clauses.

## How long
As long as your account exists. When you delete your account, your data and videos are erased. Invoices are kept for 10 years, as required by law.

## Your rights
You can access, correct, delete or export your data, and object to or restrict its use, by writing to {email}. You can also complain to the CNIL (cnil.fr). For a minor, their parents can exercise these rights.

## Cookies
The app only stores your login session and preferences on your device. No ads, no ad tracking.
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

## 7. Achats
Le prix est affiché avant de payer. Les Ballons sont ajoutés tout de suite après le paiement : en achetant, tu demandes cette livraison immédiate et tu renonces au délai de rétractation de 14 jours (article L221-28 du Code de la consommation). Un achat n'est pas remboursé, sauf si la loi l'impose ou en cas d'erreur de notre part.

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

## 7. Purchases
The price is shown before you pay. Balls are added right after payment: by buying, you ask for this immediate delivery and give up the 14-day withdrawal period (article L221-28 of the French Consumer Code). Purchases are not refunded unless required by law or in case of our mistake.

## 8. Cheating and closing your account
Balls obtained by cheating are removed. If you delete your account, your Balls are lost.
''';
