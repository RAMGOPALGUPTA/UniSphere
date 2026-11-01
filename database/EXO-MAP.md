# UniSphere ADBMS Practical Map and Viva Notes

This map documents the practical concepts implemented in this repository. Use the exact experiment titles/numbers from your university manual if they differ; this project does not assume your course's official EXO numbering.

| Practical | Where to run | Database concept | Viva explanation |
|---|---|---|---|
| Relational modelling | database/schema.sql | Entities, relationships, keys | Each entity has its own table; foreign keys connect related entities. |
| DDL | database/schema.sql | CREATE TABLE, VIEW, PROCEDURE, TRIGGER, INDEX | DDL defines database objects and their structure. |
| DML | database/seed.sql, API CRUD | INSERT, SELECT, UPDATE, DELETE | DML reads and changes table rows. |
| Constraints | ADBMS Lab → DDL & constraints | PK, FK, UNIQUE, CHECK, NOT NULL | Constraints enforce data integrity at the database layer. |
| Normalization | Schema design | 1NF/2NF/3NF design principles | Department, course, faculty, student and enrollment facts are separated to reduce repeated data and update anomalies. |
| Joins | ADBMS Lab → Multi-table joins | INNER JOIN, LEFT JOIN | Joins reconstruct related information using keys without duplicating attributes across tables. |
| Aggregates | ADBMS Lab → Aggregate analytics | COUNT, SUM, AVG, GROUP BY | Aggregate functions summarize rows; GROUP BY creates one summary per group. |
| Subqueries / CTE | ADBMS Lab → CTE & subqueries | WITH, subquery, CROSS JOIN | CTEs name intermediate results and make multi-step SQL easier to read. |
| Views | ADBMS Lab → Database views | v_student_academic_summary, v_fee_dues | A view is a stored query definition, not a separate copy of the underlying data. |
| Indexes and optimization | ADBMS Lab → Indexes & EXPLAIN | B-tree indexes, EXPLAIN | Indexes can speed selective lookups at a storage/write cost; EXPLAIN shows the optimizer's plan. |
| Transactions | ADBMS Lab → ACID transaction | BEGIN, COMMIT, ROLLBACK, row lock | A payment and invoice-status update succeed together or roll back together. |
| Stored procedure | ADBMS Lab → Stored procedure | sp_student_transcript | A stored procedure encapsulates a parameterized operation in the database. |
| Trigger | ADBMS Lab → Trigger & audit log | AFTER INSERT | The database automatically writes an audit event when a fee payment is inserted. |
| Auditability | ADBMS Lab / GET /api/audit | Audit log, JSON details | Audit rows record important application changes and trigger-driven payment events. |
| Database access | server/src/index.js | Parameterized statements | SQL values are bound as parameters to reduce SQL-injection risk. |
| Reporting | API endpoints | Views and aggregates | Operational records are combined into academic, attendance and fee reports. |

## Relational model overview

- departments → parent entity for students, faculty and courses.
- students → one row per student; unique student number and email.
- faculty → faculty member and department association.
- courses → course definition with department and optional faculty.
- enrollments → associative table resolving the many-to-many student/course relationship.
- attendance → one student's status for a course on a date.
- exams and exam_results → assessment definition and each student's result.
- fee_invoices and fee_payments → invoice/payment separation, supporting multiple payments per invoice.
- audit_log → event history for application changes and payment trigger records.

## Transaction walkthrough

1. Client sends an invoice ID, positive payment amount, payment method and unique reference.
2. API opens a connection and starts a transaction.
3. SELECT ... FOR UPDATE locks the invoice row to avoid concurrent overpayment.
4. API calculates the remaining balance and validates the amount.
5. It inserts a payment and updates invoice status.
6. MySQL's AFTER INSERT trigger writes the audit event.
7. API commits; any exception causes a rollback.

## What this version does not implement

The repository does not currently include live MongoDB, Redis, Cassandra, Neo4j, distributed replication/sharding, cloud-managed database provisioning, or a data-lake/ETL pipeline. These require their own services and tests. If your official lab manual includes these experiments, they must be added separately; this document does not count them as implemented.
