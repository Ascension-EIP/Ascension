@EIP 
**Pour résumé suite à notre conversion**

Les objectifs seraient :
- Avoir un début fonctionnel qui utilise toute nos technologie

Au niveau des scopes, on aimerait :
- Une IA qui analyse les forces / affiche l'exos squelette 
- Un linkage entre back et IA avec rabbit mq
- Une front qui marche, qui permet d'upload une vidéo et de lancer une analyse
- La vidéo doit être stocker sur MinIO
- La DB doit être setup avec les bon schèma

Voici comment on s'organise :
- @livo3192 s'occupe de faire une première IA utilisant MediaPipe
- @jundo va s'occuper du link entre l'IA et le Back-end grâce à RabbitMQ
- @itskarmaoff va s'occuper du front, faire qu'on puisse upload la vidéo etc
- @dimitri_lapoudre va s'occuper d'init le back et de travailler sur les premières routes
- @nicolas_toro va s'occuper de tous les trucs pro, GitHub projects etc, et ensuite je rejoindrais Lou et on s'organisera.

Petit brouillons d'informations du flow :
- Le back renvoie une URL ou tu peux upload une vidéo
- Comme sa le mbile envoie la vidéo sur l'url
- Un bouton analyse
- Sa envoie la requête au back, le serveur avec rabbit envoie le truc à l'ia, elle envoie la réponse en JSON au serveur, il la stocke dans la db et envoie la réponse au front
- Si on a finis on met l'auth
- Une IA est sortie pour obtenir la profondeur à partir d'une IA -> SAM3



## Les étapes clés et rendus

### Étape 1 : Définition

Cette phase se concentre sur la délimitation du projet.

-   **Objectifs :** Définir le périmètre (scope), les objectifs et le scénario de démonstration.
    
-   **Livrables (Mardi) :** Un projet GitHub à jour, une milestone avec tâches assignées, la répartition documentée des tâches, la définition de l'environnement technique et la demande de matériel si nécessaire.
    

### Étape 2 : Parcours utilisateur et Prototypage

L'accent est mis sur l'essentiel et l'organisation agile.

-   **Contrainte majeure :** Le projet doit être développé "en un seul tenant" ; il est interdit de présenter le projet en plusieurs parties distinctes.
    
-   **Suivi (Jeudi et Lundi) :** Début puis démonstration du parcours utilisateur principal.
    
-   **Finalisation (Mercredi) :** Le projet doit être finalisé, les jours suivants étant réservés aux ajustements.
    

### Étape 3 : Préparation et Présentation

La phase finale concerne la communication autour du prototype.

-   **Format :** Un pitch de 15 minutes.
    
-   **Démonstration :** Une présentation publique incluant une démonstration réelle avec micros.