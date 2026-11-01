import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import pool from './db.js';
dotenv.config();

const app = express();
app.use(helmet());
app.use(cors({ origin: process.env.CLIENT_ORIGIN || 'http://localhost:5173' }));
app.use(express.json({ limit: '100kb' }));

const asyncRoute = fn => (req,res,next) => Promise.resolve(fn(req,res,next)).catch(next);
const positiveId = value => Number.isInteger(Number(value)) && Number(value)>0;
const log = (action, table, key, details={}) => pool.execute(
  'INSERT INTO audit_log(actor,action_name,table_name,record_key,details) VALUES(?,?,?,?,?)',
  ['demo-admin',action,table,String(key ?? ''),JSON.stringify(details)]
);

app.get('/api/health', asyncRoute(async (_req,res) => {
  await pool.query('SELECT 1');
  res.json({status:'ok',database:'connected',project:'UniSphere ADBMS'});
}));

app.get('/api/dashboard', asyncRoute(async (_req,res) => {
  const [[students]] = await pool.query("SELECT COUNT(*) total, SUM(status='Active') active FROM students");
  const [[courses]] = await pool.query('SELECT COUNT(*) total FROM courses');
  const [[attendance]] = await pool.query("SELECT ROUND(100*SUM(attendance_status='Present')/NULLIF(COUNT(*),0),1) rate FROM attendance");
  const [[fees]] = await pool.query("SELECT COALESCE(SUM(amount),0) total FROM fee_invoices WHERE status IN ('Pending','Partially Paid','Overdue')");
  const [[results]] = await pool.query('SELECT ROUND(AVG(marks_obtained/max_marks*100),1) average FROM exam_results r JOIN exams e ON e.exam_id=r.exam_id');
  res.json({students,courses,attendance,fees,results});
}));

app.get('/api/students', asyncRoute(async (req,res) => {
  const q = String(req.query.q || '').trim();
  const [rows] = await pool.execute(
    `SELECT s.student_id,s.student_no,s.full_name,s.email,s.phone,s.year_level,s.status,d.department_name,d.department_id
     FROM students s JOIN departments d ON d.department_id=s.department_id
     WHERE (?='' OR s.full_name LIKE CONCAT('%',?,'%') OR s.student_no LIKE CONCAT('%',?,'%') OR s.email LIKE CONCAT('%',?,'%'))
     ORDER BY s.student_id DESC LIMIT 250`, [q,q,q,q]);
  res.json(rows);
}));
app.post('/api/students', asyncRoute(async (req,res) => {
  const {student_no,full_name,email,phone=null,department_id,year_level=1,status='Active'}=req.body;
  if(!student_no || !full_name || !email || !department_id || !year_level) return res.status(400).json({error:'student_no, full_name, email, department_id and year_level are required'});
  if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return res.status(400).json({error:'A valid email address is required'});
  const [result] = await pool.execute('INSERT INTO students(student_no,full_name,email,phone,department_id,year_level,status) VALUES(?,?,?,?,?,?,?)',[student_no,full_name,email,phone,Number(department_id),Number(year_level),status]);
  await log('STUDENT_CREATED','students',result.insertId,{student_no,email});
  res.status(201).json({student_id:result.insertId,message:'Student created'});
}));
app.put('/api/students/:id', asyncRoute(async (req,res) => {
  if(!positiveId(req.params.id)) return res.status(400).json({error:'Invalid student id'});
  const {full_name,email,phone=null,department_id,year_level,status}=req.body;
  if(!full_name || !email || !department_id || !year_level || !status) return res.status(400).json({error:'full_name, email, department_id, year_level and status are required'});
  const [r] = await pool.execute('UPDATE students SET full_name=?,email=?,phone=?,department_id=?,year_level=?,status=? WHERE student_id=?',[full_name,email,phone,Number(department_id),Number(year_level),status,Number(req.params.id)]);
  if(!r.affectedRows) return res.status(404).json({error:'Student not found'});
  await log('STUDENT_UPDATED','students',req.params.id,{email});
  res.json({message:'Student updated'});
}));
app.delete('/api/students/:id', asyncRoute(async (req,res) => {
  if(!positiveId(req.params.id)) return res.status(400).json({error:'Invalid student id'});
  const [r]=await pool.execute('DELETE FROM students WHERE student_id=?',[Number(req.params.id)]);
  if(!r.affectedRows) return res.status(404).json({error:'Student not found'});
  await log('STUDENT_DELETED','students',req.params.id);
  res.json({message:'Student deleted'});
}));

app.get('/api/departments', asyncRoute(async (_req,res) => {
  const [rows]=await pool.query('SELECT department_id,department_code,department_name FROM departments ORDER BY department_name');
  res.json(rows);
}));
app.get('/api/courses', asyncRoute(async (_req,res) => {
  const [rows]=await pool.query('SELECT c.course_id,c.course_code,c.course_name,c.credits,c.semester,d.department_name,f.full_name faculty_name FROM courses c JOIN departments d ON d.department_id=c.department_id LEFT JOIN faculty f ON f.faculty_id=c.faculty_id ORDER BY c.course_code');
  res.json(rows);
}));
app.get('/api/attendance/summary', asyncRoute(async (_req,res) => {
  const [rows]=await pool.query(`SELECT s.student_no,s.full_name,c.course_code,
    COUNT(a.attendance_id) classes,
    SUM(a.attendance_status='Present') present,
    ROUND(100*SUM(a.attendance_status='Present')/NULLIF(COUNT(a.attendance_id),0),1) attendance_percent
    FROM students s JOIN attendance a ON a.student_id=s.student_id JOIN courses c ON c.course_id=a.course_id
    GROUP BY s.student_id,c.course_id ORDER BY attendance_percent ASC`);
  res.json(rows);
}));
app.get('/api/reports/performance', asyncRoute(async (_req,res) => {
  const [rows]=await pool.query('SELECT * FROM v_student_academic_summary ORDER BY average_exam_percent DESC');
  res.json(rows);
}));
app.get('/api/reports/fee-dues', asyncRoute(async (_req,res) => {
  const [rows]=await pool.query('SELECT * FROM v_fee_dues ORDER BY due_date');
  res.json(rows);
}));
app.get('/api/audit', asyncRoute(async (_req,res) => {
  const [rows]=await pool.query('SELECT audit_id,actor,action_name,table_name,record_key,details,created_at FROM audit_log ORDER BY audit_id DESC LIMIT 100');
  res.json(rows);
}));

app.get('/api/lab/experiments', (_req,res) => res.json([
 {id:'ddl',title:'DDL & constraints',concept:'CREATE TABLE, PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK',description:'Inspect the relational schema and integrity constraints.'},
 {id:'joins',title:'Multi-table joins',concept:'INNER JOIN, LEFT JOIN, GROUP BY',description:'Combine student, department, enrollment and course data.'},
 {id:'aggregate',title:'Aggregate analytics',concept:'COUNT, AVG, SUM, GROUP BY, HAVING',description:'Summarise attendance, marks and outstanding fees.'},
 {id:'subquery',title:'Subqueries & CTEs',concept:'Scalar subquery, CTE, correlated query',description:'Find students above the campus average score.'},
 {id:'views',title:'Views',concept:'CREATE VIEW and SELECT',description:'Read reusable student summary and fee-dues views.'},
 {id:'indexes',title:'Indexes & EXPLAIN',concept:'INDEX, EXPLAIN',description:'Inspect the query plan for indexed student search.'},
 {id:'transactions',title:'Transactions',concept:'START TRANSACTION, COMMIT, ROLLBACK',description:'Record a fee payment atomically and update invoice status.'},
 {id:'procedure',title:'Stored procedure',concept:'CALL sp_student_transcript(?)',description:'Generate a student transcript using a stored procedure.'},
 {id:'trigger',title:'Trigger & audit',concept:'AFTER INSERT trigger, JSON audit record',description:'A fee payment automatically creates an audit-log entry.'}
]));
app.get('/api/lab/run/:experiment', asyncRoute(async (req,res) => {
 let rows=[], sql='', explanation='';
 switch(req.params.experiment){
 case 'ddl':
   sql='SHOW CREATE TABLE students; SHOW CREATE TABLE enrollments';
   [rows]=await pool.query('SELECT TABLE_NAME,CONSTRAINT_NAME,CONSTRAINT_TYPE FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,CONSTRAINT_TYPE');
   explanation='Primary keys identify rows, foreign keys preserve relationships, and unique/check constraints reject invalid records.';
   break;
 case 'joins':
   sql='SELECT students + departments + enrollments + courses with INNER JOIN';
   [rows]=await pool.query(`SELECT s.student_no,s.full_name,d.department_name,c.course_code,c.course_name,e.status enrollment_status
     FROM students s JOIN departments d ON d.department_id=s.department_id
     LEFT JOIN enrollments e ON e.student_id=s.student_id
     LEFT JOIN courses c ON c.course_id=e.course_id ORDER BY s.student_no LIMIT 100`);
   explanation='JOIN combines related tables through key relationships instead of duplicating department and course data in the student row.';
   break;
 case 'aggregate':
   sql='GROUP BY department; COUNT students; AVG exam percent; SUM unpaid fees';
   [rows]=await pool.query(`SELECT d.department_name,COUNT(DISTINCT s.student_id) student_count,
      ROUND(AVG(er.marks_obtained/NULLIF(ex.max_marks,0)*100),1) average_exam_percent,
      COALESCE(SUM(DISTINCT CASE WHEN fi.status IN ('Pending','Partially Paid','Overdue') THEN fi.amount END),0) unpaid_fee_total
      FROM departments d LEFT JOIN students s ON s.department_id=d.department_id
      LEFT JOIN exam_results er ON er.student_id=s.student_id LEFT JOIN exams ex ON ex.exam_id=er.exam_id
      LEFT JOIN fee_invoices fi ON fi.student_id=s.student_id GROUP BY d.department_id,d.department_name ORDER BY student_count DESC`);
   explanation='Aggregate functions calculate summaries across groups; GROUP BY returns one row per department.';
   break;
 case 'subquery':
   sql='WITH campus_average AS (...) SELECT students above average';
   [rows]=await pool.query(`WITH scores AS (SELECT s.student_id,s.student_no,s.full_name,AVG(er.marks_obtained/NULLIF(ex.max_marks,0)*100) pct FROM students s JOIN exam_results er ON er.student_id=s.student_id JOIN exams ex ON ex.exam_id=er.exam_id GROUP BY s.student_id,s.student_no,s.full_name), campus AS (SELECT AVG(pct) avg_pct FROM scores) SELECT scores.student_no,scores.full_name,ROUND(scores.pct,2) student_percent,ROUND(campus.avg_pct,2) campus_average FROM scores CROSS JOIN campus WHERE scores.pct>campus.avg_pct ORDER BY scores.pct DESC`);
   explanation='The CTE names an intermediate result, then compares each student score to the campus-wide average.';
   break;
 case 'views':
   sql='SELECT * FROM v_student_academic_summary; SELECT * FROM v_fee_dues';
   [rows]=await pool.query('SELECT * FROM v_student_academic_summary ORDER BY full_name');
   explanation='A view stores a reusable query definition, not a duplicate copy of the underlying rows. Fee dues is available at GET /api/reports/fee-dues.';
   break;
 case 'indexes':
   sql='EXPLAIN SELECT ... FROM students WHERE student_no = ?';
   [rows]=await pool.execute('EXPLAIN SELECT student_id,student_no,full_name FROM students WHERE student_no=?',['US24081']);
   explanation='The unique index on student_no allows MySQL to locate a student without scanning the full table.';
   break;
 case 'transactions':
   sql='START TRANSACTION; INSERT fee_payments; UPDATE fee_invoices; COMMIT';
   explanation='Use POST /api/lab/transaction to execute a transaction. A failure rolls back both the payment and invoice status.';
   [rows]=await pool.query(`SELECT invoice_no,amount,status FROM fee_invoices ORDER BY invoice_id`);
   break;
 case 'procedure':
   sql='CALL sp_student_transcript(1)';
   [rows]=await pool.query('CALL sp_student_transcript(?)',[1]);
   explanation='A stored procedure encapsulates a parameterized transcript query inside the database.';
   break;
 case 'trigger':
   sql='AFTER INSERT ON fee_payments -> audit_log';
   [rows]=await pool.query('SELECT audit_id,action_name,table_name,record_key,details,created_at FROM audit_log ORDER BY audit_id DESC LIMIT 20');
   explanation='The trigger records an audit event automatically when a payment is inserted; application code does not create that trigger event.';
   break;
 default: return res.status(404).json({error:'Unknown experiment'});
 }
 res.json({experiment:req.params.experiment,sql,explanation,rows});
}));
app.post('/api/lab/transaction', asyncRoute(async (req,res) => {
 const {invoice_id,amount,payment_method='UPI',reference_no}=req.body;
 if(!positiveId(invoice_id)||!Number.isFinite(Number(amount))||Number(amount)<=0||!reference_no) return res.status(400).json({error:'invoice_id, positive amount and unique reference_no are required'});
 const conn=await pool.getConnection();
 try{
  await conn.beginTransaction();
  const [[invoice]]=await conn.execute('SELECT invoice_id,amount,status FROM fee_invoices WHERE invoice_id=? FOR UPDATE',[Number(invoice_id)]);
  if(!invoice) throw Object.assign(new Error('Invoice not found'),{statusCode:404});
  if(invoice.status==='Paid') throw Object.assign(new Error('Invoice is already paid'),{statusCode:409});
  const [[paid]]=await conn.execute('SELECT COALESCE(SUM(amount),0) total FROM fee_payments WHERE invoice_id=?',[Number(invoice_id)]);
  const due=Number(invoice.amount)-Number(paid.total);
  if(Number(amount)>due) throw Object.assign(new Error('Payment exceeds remaining balance'),{statusCode:400});
  await conn.execute('INSERT INTO fee_payments(invoice_id,amount,payment_method,reference_no) VALUES(?,?,?,?)',[Number(invoice_id),Number(amount),payment_method,reference_no]);
  const remaining=due-Number(amount);
  await conn.execute('UPDATE fee_invoices SET status=? WHERE invoice_id=?',[remaining===0?'Paid':'Partially Paid',Number(invoice_id)]);
  await conn.commit();
  res.status(201).json({message:'Payment committed successfully',invoice_id:Number(invoice_id),paid:Number(amount),remaining});
 }catch(e){await conn.rollback();throw e}finally{conn.release()}
}));

app.use((err,_req,res,_next)=>{
 console.error('[UniSphere API]',err.code||'',err.message);
 const status=err.statusCode || (err.code==='ER_DUP_ENTRY'?409:err.code==='ER_NO_REFERENCED_ROW_2'||err.code==='ER_ROW_IS_REFERENCED_2'?400:500);
 res.status(status).json({error:status===500?'Internal server error. Check API logs.':err.message});
});
const port=Number(process.env.PORT||4000);
if(process.env.NODE_ENV!=='test') app.listen(port,()=>console.log(`UniSphere ADBMS API listening at http://localhost:${port}`));
export default app;
