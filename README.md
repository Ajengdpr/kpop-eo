# K-Pop Event Organizer (MySQL)

**Tujuan:** simulasi alur data ticketing event K-Pop → OLTP → ETL (JS) → Data Warehouse (star).

## Isi repository
- `oltp/oltp_mysql.sql` – skema OLTP
- `oltp/seed_mysql_compat.sql` – seed contoh (kompatibel MariaDB/XAMPP)
- `dw/dw_mysql.sql` – schema DW (dim_* + fact_ticket_sales, fact_attendance)
- `etl/` – ETL Node.js (mysql2) untuk load dimensi & fakta
- `.env` – koneksi
- `gambar/` – ERD & Star Schema

## Cara menjalankan bisa melalui XAMPP/Windows
```powershell
# Pertama membuat Database
"C:\xampp\mysql\bin\mysql.exe" -u root -e "CREATE DATABASE IF NOT EXISTS oltp_kpopeo; CREATE DATABASE IF NOT EXISTS dw_kpopeo;"
# Lalu import schema + seed
"C:\xampp\mysql\bin\mysql.exe" -u root oltp_kpopeo < .\oltp\oltp_mysql.sql
"C:\xampp\mysql\bin\mysql.exe" -u root oltp_kpopeo < .\oltp\seed_mysql_compat.sql
"C:\xampp\mysql\bin\mysql.exe" -u root dw_kpopeo   < .\dw\dw_mysql.sql
