# HEARTBEAT.md - Surveillance du Fork OpenClaw

## Tâches en cours
- [ ] Monitorer l'activité de `ResearcherSkill` dans `/home/ubuntu/.openclaw-dev/workspace/`
- [ ] Analyser les logs et les résultats des agents de contexte/vérificateurs.
- [ ] Intervenir si `ResearcherSkill` demande des permissions ou est bloqué.
- [ ] Assurer la continuité entre les itérations `n`.

## Instructions de Surveillance
1. **Veille active :** Vérifier les logs dans le répertoire du projet toutes les 30 min.
2. **Action proactive :** Si `ResearcherSkill` crée une branche ou un fichier de log (ex: `log.md`, `results.tsv`), lire les derniers résultats.
3. **Alerte Roger :** Signaler toute erreur critique ou blocage immédiat via Discord.
4. **Maintenance :** Maintenir le processus en vie.

## État des checks
- [ ] Surveillance Fork OpenClaw (Intervalle: 30 min)
