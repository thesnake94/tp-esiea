Mini-CTF (local) - 3 challenges
- SQLi : http://localhost:8080/challenges/sqli/web/index.php
- Upload : http://localhost:8080/challenges/upload/web/upload.php
- RCE  : http://localhost:8080/challenges/rce/web/ping.php

Démarrage :
  docker-compose up -d

Réinitialiser la DB :
  docker exec -i ctf_mysql mysql -uroot -prootpass < challenges/sqli/db_init.sql

Attention : n'exposez PAS ces services en production / sur Internet.
