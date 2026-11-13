- [x] update les symlinks sur le nouveau skill graphify
- [x] supprimer tout ce qui concerne les squads (docs, skills, workflows, etc)
- [x] supprimer les mentions de squads dans les skills
- [ ] enlever les mocks du mobile qui servait à faire la refonte graphique (migration 100% Forui, suppression de shadcn et hux)
1. [ ] regarder les nouvelles IA pour faire d'une vidéo la meme "vidéo" 3D dans laquelle on peut se déplacer et avancer dans le temps
   1.  https://research.nvidia.com/labs/toronto-ai/lyra/
   2.  gaussian splatting ?
       1.  https://github.com/graphdeco-inria/gaussian-splatting
       2. En fait, il ne faut pas que l'objet soit en mouvement.
    3. SMPL-X (-X pour avoir les mains et le visage) (https://smpl-x.is.tue.mpg.de/)
       1. extraire le mesh 3D d'un humain à partir d'une vidéo
       2.
    3. Notre but étant de refaire la pipeline d'un modèle déjà tout fini, en utilisant une suite de modèles :
       1. Détection de la personne (YOLOv8)
       2. Suivi temporel de la personne
       3. Repères 2D du corps
       4. Reconstruction 3D




2. [ ] photo to 3D model (pour l'analyse de prises de la voie)
   1. [ ]
3. [x] rajouter dans les doc le forui + symlinks des skills
4. [ ] enlever le francais de la doc
5. [ ]
