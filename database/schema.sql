-- UniSphere ADBMS schema (MySQL 8.0+)
CREATE DATABASE IF NOT EXISTS unisphere CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE unisphere;

CREATE TABLE IF NOT EXISTS departments (
  department_id INT AUTO_INCREMENT PRIMARY KEY,
  department_code VARCHAR(12) NOT NULL UNIQUE,
  department_name VARCHAR(120) NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS students (
  student_id INT AUTO_INCREMENT PRIMARY KEY,
  student_no VARCHAR(20) NOT NULL UNIQUE,
  full_name VARCHAR(140) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  phone VARCHAR(25),
  department_id INT NOT NULL,
  year_level TINYINT NOT NULL,
  status ENUM('Active','On Leave','Graduated','Suspended') NOT NULL DEFAULT 'Active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_student_year CHECK (year_level BETWEEN 1 AND 6),
  CONSTRAINT fk_student_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_students_department_year (department_id, year_level),
  INDEX idx_students_name (full_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS faculty (
  faculty_id INT AUTO_INCREMENT PRIMARY KEY,
  faculty_no VARCHAR(20) NOT NULL UNIQUE,
  full_name VARCHAR(140) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  department_id INT NOT NULL,
  CONSTRAINT fk_faculty_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS courses (
  course_id INT AUTO_INCREMENT PRIMARY KEY,
  course_code VARCHAR(20) NOT NULL UNIQUE,
  course_name VARCHAR(160) NOT NULL,
  credits TINYINT NOT NULL,
  department_id INT NOT NULL,
  faculty_id INT NULL,
  semester TINYINT NOT NULL,
  CONSTRAINT chk_course_credits CHECK (credits BETWEEN 1 AND 10),
  CONSTRAINT chk_course_semester CHECK (semester BETWEEN 1 AND 12),
  CONSTRAINT fk_course_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_course_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  INDEX idx_courses_department (department_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS enrollments (
  enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  course_id INT NOT NULL,
  academic_year VARCHAR(9) NOT NULL,
  enrolled_on DATE NOT NULL DEFAULT (CURRENT_DATE),
  status ENUM('Enrolled','Completed','Withdrawn') NOT NULL DEFAULT 'Enrolled',
  UNIQUE KEY uq_student_course_year (student_id, course_id, academic_year),
  CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_enrollment_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_enrollment_course_status (course_id, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS attendance (
  attendance_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  course_id INT NOT NULL,
  class_date DATE NOT NULL,
  attendance_status ENUM('Present','Absent','Late','Excused') NOT NULL,
  marked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_attendance_student_course_date (student_id, course_id, class_date),
  CONSTRAINT fk_attendance_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_attendance_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_attendance_date_status (class_date, attendance_status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exams (
  exam_id INT AUTO_INCREMENT PRIMARY KEY,
  course_id INT NOT NULL,
  exam_name VARCHAR(120) NOT NULL,
  exam_date DATE NOT NULL,
  max_marks DECIMAL(6,2) NOT NULL DEFAULT 100,
  CONSTRAINT fk_exam_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exam_results (
  result_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  exam_id INT NOT NULL,
  student_id INT NOT NULL,
  marks_obtained DECIMAL(6,2) NOT NULL,
  graded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_exam_student (exam_id, student_id),
  CONSTRAINT chk_marks_nonnegative CHECK (marks_obtained >= 0),
  CONSTRAINT fk_result_exam FOREIGN KEY (exam_id) REFERENCES exams(exam_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_result_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fee_invoices (
  invoice_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id INT NOT NULL,
  invoice_no VARCHAR(30) NOT NULL UNIQUE,
  fee_type ENUM('Tuition','Hostel','Transport','Library','Other') NOT NULL DEFAULT 'Tuition',
  amount DECIMAL(12,2) NOT NULL,
  due_date DATE NOT NULL,
  status ENUM('Pending','Partially Paid','Paid','Overdue') NOT NULL DEFAULT 'Pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_fee_amount CHECK (amount > 0),
  CONSTRAINT fk_invoice_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  INDEX idx_invoice_status_due (status, due_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fee_payments (
  payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  invoice_id BIGINT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method ENUM('Cash','Card','UPI','Bank Transfer') NOT NULL DEFAULT 'UPI',
  reference_no VARCHAR(60) NOT NULL UNIQUE,
  paid_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_payment_amount CHECK (amount > 0),
  CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES fee_invoices(invoice_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_log (
  audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  actor VARCHAR(120) NOT NULL DEFAULT 'system',
  action_name VARCHAR(100) NOT NULL,
  table_name VARCHAR(80) NOT NULL,
  record_key VARCHAR(80),
  details JSON,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_created (created_at),
  INDEX idx_audit_table_action (table_name, action_name)
) ENGINE=InnoDB;

CREATE OR REPLACE VIEW v_student_academic_summary AS
SELECT s.student_id, s.student_no, s.full_name, s.email, d.department_name,
       COUNT(DISTINCT e.course_id) AS enrolled_courses,
       ROUND(AVG(er.marks_obtained / ex.max_marks * 100), 2) AS average_exam_percent
FROM students s
JOIN departments d ON d.department_id=s.department_id
LEFT JOIN enrollments e ON e.student_id=s.student_id AND e.status='Enrolled'
LEFT JOIN exam_results er ON er.student_id=s.student_id
LEFT JOIN exams ex ON ex.exam_id=er.exam_id
GROUP BY s.student_id,s.student_no,s.full_name,s.email,d.department_name;

CREATE OR REPLACE VIEW v_fee_dues AS
SELECT s.student_no,s.full_name,fi.invoice_no,fi.fee_type,fi.amount,fi.due_date,fi.status
FROM fee_invoices fi JOIN students s ON s.student_id=fi.student_id
WHERE fi.status IN ('Pending','Partially Paid','Overdue');

DELIMITER //
CREATE PROCEDURE sp_student_transcript(IN p_student_id INT)
BEGIN
  SELECT s.student_no,s.full_name,c.course_code,c.course_name,ex.exam_name,
         er.marks_obtained,ex.max_marks,
         ROUND(er.marks_obtained/ex.max_marks*100,2) AS percentage
  FROM students s
  JOIN exam_results er ON er.student_id=s.student_id
  JOIN exams ex ON ex.exam_id=er.exam_id
  JOIN courses c ON c.course_id=ex.course_id
  WHERE s.student_id=p_student_id
  ORDER BY ex.exam_date DESC;
END//

CREATE TRIGGER trg_fee_payment_audit AFTER INSERT ON fee_payments
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(actor,action_name,table_name,record_key,details)
  VALUES ('system','PAYMENT_RECORDED','fee_payments',CAST(NEW.payment_id AS CHAR),
          JSON_OBJECT('invoice_id',NEW.invoice_id,'amount',NEW.amount,'reference_no',NEW.reference_no));
END//
DELIMITER ;
