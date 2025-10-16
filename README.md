# tp-esiea
# TP ESIEA – Mini app Flask (étape environnement)

Petite application Flask pour valider:
- Création du dépôt
- Mise en place GitHub Actions (tests auto au push)

## Lancer en local
```bash
python -m venv .venv
source .venv/bin/activate  # (Windows: .venv\Scripts\activate)
pip install -r requirements.txt
python app.py
# http://127.0.0.1:5000/ et /health
