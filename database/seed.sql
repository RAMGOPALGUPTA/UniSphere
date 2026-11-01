USE unisphere;
INSERT IGNORE INTO departments(department_id,department_code,department_name) VALUES
(1,'CSE','Computer Science & Engineering'),(2,'BBA','Business Administration'),(3,'DS','Data Science'),(4,'ECE','Electronics & Communication');

INSERT IGNORE INTO faculty(faculty_id,faculty_no,full_name,email,department_id) VALUES
(1,'FAC001','Dr. Meera Sharma','meera.sharma@unisphere.edu',1),
(2,'FAC002','Prof. Arjun Rao','arjun.rao@unisphere.edu',2),
(3,'FAC003','Dr. Kavita Singh','kavita.singh@unisphere.edu',3);

INSERT IGNORE INTO students(student_id,student_no,full_name,email,phone,department_id,year_level,status) VALUES
(1,'US24081','Sophia Taylor','sophia.taylor@unisphere.edu','9876500001',1,3,'Active'),
(2,'US24082','Liam Bennett','liam.bennett@unisphere.edu','9876500002',2,2,'Active'),
(3,'US24083','Ava Martinez','ava.martinez@unisphere.edu','9876500003',3,3,'Active'),
(4,'US24084','Noah Williams','noah.williams@unisphere.edu','9876500004',1,4,'Active'),
(5,'US24085','Mia Chen','mia.chen@unisphere.edu','9876500005',4,1,'On Leave'),
(6,'US24086','Ethan Patel','ethan.patel@unisphere.edu','9876500006',1,2,'Active');

INSERT IGNORE INTO courses(course_id,course_code,course_name,credits,department_id,faculty_id,semester) VALUES
(1,'CSE301','Advanced Database Management Systems',4,1,1,5),
(2,'CSE205','Data Structures & Algorithms',4,1,1,3),
(3,'BBA210','Business Analytics',3,2,2,4),
(4,'DS305','Applied Machine Learning',4,3,3,5),
(5,'ECE202','Digital Systems',3,4,NULL,3);

INSERT IGNORE INTO enrollments(enrollment_id,student_id,course_id,academic_year,status) VALUES
(1,1,1,'2026-27','Enrolled'),(2,1,2,'2026-27','Enrolled'),(3,2,3,'2026-27','Enrolled'),
(4,3,4,'2026-27','Enrolled'),(5,4,1,'2026-27','Enrolled'),(6,6,1,'2026-27','Enrolled'),
(7,4,2,'2026-27','Enrolled');

INSERT IGNORE INTO attendance(attendance_id,student_id,course_id,class_date,attendance_status) VALUES
(1,1,1,'2026-10-27','Present'),(2,2,3,'2026-10-27','Present'),(3,3,4,'2026-10-27','Late'),
(4,4,1,'2026-10-27','Absent'),(5,6,1,'2026-10-27','Present'),(6,1,2,'2026-10-28','Present'),
(7,4,2,'2026-10-28','Late');

INSERT IGNORE INTO exams(exam_id,course_id,exam_name,exam_date,max_marks) VALUES
(1,1,'ADBMS MST-1','2026-10-25',30),(2,2,'DSA MST-1','2026-10-24',30),(3,3,'Analytics Quiz','2026-10-22',20),(4,4,'ML Assessment','2026-10-23',50);
INSERT IGNORE INTO exam_results(result_id,exam_id,student_id,marks_obtained) VALUES
(1,1,1,27),(2,1,4,21),(3,1,6,25),(4,2,1,25),(5,2,4,23),(6,3,2,18),(7,4,3,44);

INSERT IGNORE INTO fee_invoices(invoice_id,student_id,invoice_no,fee_type,amount,due_date,status) VALUES
(1,1,'INV-2026-001','Tuition',65000,'2026-11-15','Pending'),
(2,2,'INV-2026-002','Tuition',58000,'2026-10-15','Overdue'),
(3,3,'INV-2026-003','Tuition',62000,'2026-11-30','Partially Paid'),
(4,4,'INV-2026-004','Hostel',28000,'2026-10-20','Pending'),
(5,6,'INV-2026-005','Tuition',65000,'2026-09-30','Paid');
INSERT IGNORE INTO fee_payments(payment_id,invoice_id,amount,payment_method,reference_no) VALUES
(1,5,65000,'UPI','DEMO-PAY-001');
