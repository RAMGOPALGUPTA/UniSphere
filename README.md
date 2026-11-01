# UniSphere — University Management & ADBMS Lab

UniSphere is an academic university-management project with a modern React interface and a real MySQL 8 database/API lab. The ADBMS Lab page executes live SQL against MySQL and returns query output so students can demonstrate database concepts during practicals and viva.

## Technology
- Frontend: React 18, Vite, Recharts, Lucide React
- API: Node.js, Express, mysql2, Helmet, CORS
- Database: MySQL 8 / InnoDB
- CI: GitHub Actions builds the frontend, initializes MySQL, and smoke-tests database-backed endpoints

## Quick start (Windows PowerShell)

### 1. Requirements
Install Node.js 20+ and MySQL Server 8. Ensure the MySQL service is running.

### 2. Create the database
From the repository root:
```powershell
Get-Content .\database\schema.sql -Raw | mysql -u root -p
Get-Content .\database\seed.sql -Raw | mysql -u root -p unisphere
```
The schema script creates the `unisphere` database and all tables, views, procedure, indexes and trigger. The seed script inserts demonstration records. Run the seed script again only if you want to restore/refresh missing sample records; it uses `INSERT IGNORE` for seeded IDs.

### 3. Configure and start the API
```powershell
Copy-Item .\server\.env.example .\server\.env
notepad .\server\.env
```
Set `DB_PASSWORD` to your local MySQL password. Do not commit `.env` or share its contents. Then:
```powershell
npm install --prefix server
npm run dev --prefix server
```
The API runs at `http://localhost:4000`. Verify with:
```powershell
Invoke-RestMethod http://localhost:4000/api/health
```

### 4. Start the frontend
Open a second PowerShell terminal in the repository root:
```powershell
npm install
npm run dev
```
Open the Vite URL, normally `http://localhost:5173`. Sign in using the demo screen, then choose **ADBMS Lab** in the sidebar. The lab needs the API and MySQL service running to execute queries.

### 5. Production build
```powershell
npm run build
```

## Implemented ADBMS practicals

1. **Relational schema and integrity constraints** — primary keys, foreign keys, UNIQUE, CHECK and referential actions.
2. **Joins** — student, department, enrollment and course data across related tables.
3. **Aggregate queries** — COUNT, SUM, AVG, GROUP BY and analytical summaries.
4. **CTEs and subqueries** — compare student exam performance against the campus average.
5. **Views** — `v_student_academic_summary` and `v_fee_dues`.
6. **Indexes and EXPLAIN** — inspect the query plan for a student-number lookup.
7. **Transactions / ACID** — fee payment uses a database transaction, row locking, validation, COMMIT and ROLLBACK on failure.
8. **Stored procedure** — `sp_student_transcript(student_id)`.
9. **Trigger and audit log** — a fee-payment insert automatically creates an audit event.
10. **Parameterized CRUD API** — create, read, update and delete student records with input validation and duplicate-key handling.
11. **Database reporting** — dashboard metrics, attendance summary, academic performance, fee dues and audit records.
12. **CSV export** — export the live result set from the ADBMS Lab.

SQL examples for direct execution are in `database/adbms-experiments.sql`. Schema and sample data are in `database/schema.sql` and `database/seed.sql`.

## API routes

- `GET /api/health`
- `GET /api/dashboard`
- `GET/POST /api/students`
- `PUT/DELETE /api/students/:id`
- `GET /api/departments`, `GET /api/courses`
- `GET /api/attendance/summary`
- `GET /api/reports/performance`, `GET /api/reports/fee-dues`
- `GET /api/audit`
- `GET /api/lab/experiments`, `GET /api/lab/run/:experiment`
- `POST /api/lab/transaction`

## Important scope and security notes

- The sign-in page is a **frontend demo gate**, not production authentication. It stores a demo session in browser local storage. No real password verification, password hashing, user table, RBAC, or secure session system is implemented.
- The original dashboard's sample widgets and student directory still contain local demo data. The **ADBMS Lab and listed API routes** use MySQL. Do not assume every existing dashboard widget is live database-connected.
- MySQL 8 is required for the CTEs, CHECK constraints and SQL syntax used here.
- The core relational ADBMS practicals above are implemented. MongoDB, Redis, Cassandra, Neo4j, cloud-provider integration, sharding/replication clusters and a data-lake/ETL pipeline are **not implemented** in this version. Only add these if they are explicitly part of the official course experiments and can be run/tested.
- Use only local sample data. This is an academic demonstration, not a production student-information system.
