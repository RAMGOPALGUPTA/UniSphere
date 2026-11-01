-- UniSphere ADBMS lab snippets: run after schema.sql and seed.sql.
USE unisphere;

-- EXO: SELECT / WHERE / ORDER BY
SELECT student_no,full_name,status FROM students WHERE status='Active' ORDER BY full_name;

-- EXO: INNER JOIN and LEFT JOIN
SELECT s.student_no,s.full_name,d.department_name,c.course_name
FROM students s JOIN departments d ON d.department_id=s.department_id
LEFT JOIN enrollments e ON e.student_id=s.student_id
LEFT JOIN courses c ON c.course_id=e.course_id;

-- EXO: GROUP BY and HAVING
SELECT d.department_name,COUNT(s.student_id) student_count
FROM departments d LEFT JOIN students s ON s.department_id=d.department_id
GROUP BY d.department_id,d.department_name HAVING COUNT(s.student_id)>=1;

-- EXO: subquery / CTE
WITH department_counts AS (SELECT department_id,COUNT(*) n FROM students GROUP BY department_id)
SELECT d.department_name,dc.n FROM department_counts dc JOIN departments d USING(department_id)
WHERE dc.n>(SELECT AVG(n) FROM department_counts);

-- EXO: views
SELECT * FROM v_student_academic_summary;
SELECT * FROM v_fee_dues;

-- EXO: indexes and query plan
EXPLAIN SELECT * FROM students WHERE student_no='US24081';

-- EXO: transaction rollback demonstration (safe; does not persist)
START TRANSACTION;
UPDATE fee_invoices SET status='Paid' WHERE invoice_id=1;
ROLLBACK;
SELECT invoice_no,status FROM fee_invoices WHERE invoice_id=1;

-- EXO: stored procedure
CALL sp_student_transcript(1);

-- EXO: trigger proof (existing payment seed row generated an audit row)
SELECT * FROM audit_log WHERE action_name='PAYMENT_RECORDED';
