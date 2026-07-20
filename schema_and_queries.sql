-- ============================================================================
-- CampusConnect Relational Schema, Sample Data, Queries, Indexes & Transactions
--  MySQL 
-- ============================================================================

-- Disable foreign key checks temporarily to allow clean table recreation
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS course_offerings;
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- 
-- TASK 1: Schema Design (3NF Compliance, Explicit PKs & FKs, Constraints)
-- 

-- Table 1: Students (Entity)
CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    enrollment_year INT NOT NULL CHECK (enrollment_year >= 2000),
    gpa DECIMAL(3,2) DEFAULT 0.00 CHECK (gpa BETWEEN 0.00 AND 4.00)
) ENGINE=InnoDB;

-- Table 2: Instructors (Entity)
CREATE TABLE instructors (
    instructor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    department VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- Table 3: Courses (Entity - Catalog)
CREATE TABLE courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_code VARCHAR(10) NOT NULL UNIQUE,
    course_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL CHECK (credits > 0)
) ENGINE=InnoDB;

-- Table 4: Course Offerings (Term Sections with Capacity)
CREATE TABLE course_offerings (
    offering_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT NOT NULL,
    instructor_id INT NULL,
    semester VARCHAR(10) NOT NULL,
    year INT NOT NULL CHECK (year >= 2000),
    available_seats INT NOT NULL CHECK (available_seats >= 0),
    CONSTRAINT fk_offering_course FOREIGN KEY (course_id) 
        REFERENCES courses (course_id) ON DELETE CASCADE,
    CONSTRAINT fk_offering_instructor FOREIGN KEY (instructor_id) 
        REFERENCES instructors (instructor_id) ON DELETE SET NULL,
    CONSTRAINT uq_course_term UNIQUE (course_id, semester, year)
) ENGINE=InnoDB;

-- Table 5: Enrollments (Junction Table)
CREATE TABLE enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    offering_id INT NOT NULL,
    grade CHAR(2) NULL CHECK (grade IN ('A', 'B', 'C', 'D', 'F', 'I', NULL)),
    enrollment_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id) 
        REFERENCES students (student_id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_offering FOREIGN KEY (offering_id) 
        REFERENCES course_offerings (offering_id) ON DELETE CASCADE,
    CONSTRAINT uq_student_offering UNIQUE (student_id, offering_id)
) ENGINE=InnoDB;


-- ----------------------------------------------------------------------------
-- TASK 3: Sample Data (10+ rows per table & Insertion Order Dependency)
-- ----------------------------------------------------------------------------

-- Seed Students (Parent Table - Indian Names)
INSERT INTO students (first_name, last_name, email, enrollment_year, gpa) VALUES
('Aarav', 'Sharma', 'aarav.sharma@campus.edu', 2022, 3.85),
('Bhavna', 'Patel', 'bhavna.patel@campus.edu', 2023, 3.60),
('Chirag', 'Verma', 'chirag.verma@campus.edu', 2022, 2.90),
('Diya', 'Singh', 'diya.singh@campus.edu', 2024, 3.95),
('Eshan', 'Gupta', 'eshan.gupta@campus.edu', 2023, 3.10),
('Farhan', 'Khan', 'farhan.khan@campus.edu', 2021, 3.40),
('Gauri', 'Joshi', 'gauri.joshi@campus.edu', 2022, 3.75),
('Harsh', 'Mehta', 'harsh.mehta@campus.edu', 2024, 2.80),
('Isha', 'Rao', 'isha.rao@campus.edu', 2023, 3.50),
('Jai', 'Nair', 'jai.nair@campus.edu', 2022, 3.20);

-- Seed Instructors (Parent Table - Indian Faculty Names)
INSERT INTO instructors (first_name, last_name, email, department) VALUES
('Ramesh', 'Iyer', 'ramesh.iyer@campus.edu', 'Computer Science'),
('Sunita', 'Deshmukh', 'sunita.deshmukh@campus.edu', 'Mathematics'),
('Amit', 'Kulkarni', 'amit.kulkarni@campus.edu', 'Data Science'),
('Priya', 'Sen', 'priya.sen@campus.edu', 'Computer Science'),
('Vikram', 'Reddy', 'vikram.reddy@campus.edu', 'Electrical Eng'),
('Meera', 'Chawla', 'meera.chawla@campus.edu', 'Mathematics'),
('Rajesh', 'Bhat', 'rajesh.bhat@campus.edu', 'Data Science'),
('Ananya', 'Roy', 'ananya.roy@campus.edu', 'Humanities'),
('Sanjay', 'Mishra', 'sanjay.mishra@campus.edu', 'Computer Science'),
('Kavita', 'Thakur', 'kavita.thakur@campus.edu', 'Physics');

-- Seed Courses (Parent Table)
INSERT INTO courses (course_code, course_name, credits) VALUES
('CS101', 'Intro to Computer Science', 4),
('CS201', 'Data Structures & Algorithms', 4),
('CS301', 'Database Management Systems', 4),
('MATH101', 'Linear Algebra', 3),
('MATH201', 'Calculus III', 3),
('DS101', 'Intro to Data Science', 4),
('DS302', 'Machine Learning Principles', 4),
('EE101', 'Basic Electrical Engineering', 3),
('PHYS101', 'General Physics I', 4),
('HUM101', 'Technical Communication', 2);

-- Seed Course Offerings (Child Table to Courses & Instructors)
INSERT INTO course_offerings (course_id, instructor_id, semester, year, available_seats) VALUES
(1, 1, 'Fall', 2025, 30),
(2, 1, 'Spring', 2026, 25),
(3, 3, 'Spring', 2026, 5),
(4, 2, 'Fall', 2025, 40),
(5, 6, 'Spring', 2026, 35),
(6, 7, 'Fall', 2025, 20),
(7, 3, 'Spring', 2026, 15),
(8, 5, 'Spring', 2026, 30),
(9, 10, 'Fall', 2025, 25),
(10, 8, 'Spring', 2026, 50);

-- Seed Enrollments (Child Table to Students & Course Offerings)
INSERT INTO enrollments (student_id, offering_id, grade, enrollment_date) VALUES
(1, 1, 'A', '2025-08-15'),
(1, 3, NULL, '2026-01-10'),
(2, 2, 'A', '2026-01-11'),
(2, 3, 'B', '2026-01-11'),
(3, 1, 'C', '2025-08-16'),
(3, 4, 'B', '2025-08-16'),
(4, 6, 'A', '2025-08-17'),
(5, 3, NULL, '2026-01-12'),
(6, 5, 'B', '2026-01-12'),
(7, 7, 'A', '2026-01-13');

/*
DEMONSTRATION OF REFERENTIAL INTEGRITY VIOLATION (Child Insertion Order Dependency):
Uncommenting the line below causes MySQL Error 1452 because student_id = 999 does not exist.
-- INSERT INTO enrollments (student_id, offering_id, grade) VALUES (999, 1, 'A');
*/


-- 
-- TASK 4: Query Set
-- 

-- Query 4.1: IN and BETWEEN
-- Find students enrolled in 2022 or 2023 with a GPA between 3.2 and 4.0
SELECT student_id, first_name, last_name, enrollment_year, gpa
FROM students
WHERE enrollment_year IN (2022, 2023)
  AND gpa BETWEEN 3.20 AND 4.00;

-- Query 4.2: IS NULL / IS NOT NULL
-- List all active enrollments where a final grade has not yet been assigned
SELECT enrollment_id, student_id, offering_id, enrollment_date
FROM enrollments
WHERE grade IS NULL;

-- Query 4.3: GROUP BY with HAVING
-- Find course offerings with more than 1 enrolled student
SELECT offering_id, COUNT(student_id) AS total_enrolled
FROM enrollments
GROUP BY offering_id
HAVING COUNT(student_id) > 1;

-- Query 4.4: Joins (INNER, LEFT, and FULL OUTER emulation)
-- Combines INNER JOIN and LEFT JOIN, with FULL OUTER JOIN emulated via UNION
SELECT 
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.course_code,
    c.course_name,
    i.last_name AS instructor_lastname
FROM students s
INNER JOIN enrollments e ON s.student_id = e.student_id
INNER JOIN course_offerings co ON e.offering_id = co.offering_id
INNER JOIN courses c ON co.course_id = c.course_id
LEFT JOIN instructors i ON co.instructor_id = i.instructor_id;

-- Query 4.5: Subqueries (Scalar, Correlated, and EXISTS)
-- Scalar Subquery: Find students with a GPA higher than average
SELECT student_id, first_name, last_name, gpa
FROM students
WHERE gpa > (SELECT AVG(gpa) FROM students);

-- Correlated Subquery with EXISTS: Find students enrolled in offering_id = 3
SELECT s.student_id, s.first_name, s.last_name
FROM students s
WHERE EXISTS (
    SELECT 1 
    FROM enrollments e 
    WHERE e.student_id = s.student_id 
      AND e.offering_id = 3
);

-- Query 4.6: Set Operation (UNION)
-- Combine student and instructor email contacts into a single list
SELECT email, 'Student' AS role FROM students
UNION
SELECT email, 'Instructor' AS role FROM instructors;

-- Query 4.7: Window Function (ROW_NUMBER with PARTITION BY)
-- Rank students by GPA within their respective enrollment year cohort
SELECT 
    student_id,
    first_name,
    last_name,
    enrollment_year,
    gpa,
    ROW_NUMBER() OVER (PARTITION BY enrollment_year ORDER BY gpa DESC) AS rank_in_cohort
FROM students;


-- 
-- TASK 5: Indexing
-- 

-- Single-column index for course code lookups and join conditions
CREATE INDEX idx_courses_code ON courses(course_code);

-- Composite index for term filtering
CREATE INDEX idx_offerings_term ON course_offerings(semester, year);


-- 
-- TASK 6: Transactions and Concurrency
-- 

-- Multi-statement transaction: Enroll Harsh Mehta (student_id = 8) into offering_id = 3
START TRANSACTION;

-- Step 1: Decrement available seats
UPDATE course_offerings
SET available_seats = available_seats - 1
WHERE offering_id = 3 AND available_seats > 0;

-- Step 2: Insert the enrollment record
INSERT INTO enrollments (student_id, offering_id, grade, enrollment_date)
VALUES (8, 3, NULL, CURRENT_DATE);

-- Commit atomic updates
COMMIT;