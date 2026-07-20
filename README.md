# CampusConnect Data Layer

**Engine:** MySQL 8.0 (InnoDB)

---

## 1. Schema Design & Normalization

### What happens if we don't normalize?
If we dumped all student, course, and enrollment data into one big spreadsheet or single table (`flat_enrollments`), it would quickly turn into a mess:

`flat_enrollments(student_id, student_name, student_email, enrollment_year, gpa, course_code, course_name, credits, semester, year, instructor_name, instructor_email, grade)`

This lazy approach creates three major issues:
* **Massive Redundancy:** Every time a student signs up for a class, we repeat the course name, credit count, and instructor details.
* **Messy Updates:** If a professor changes their email, we have to find and update every single historical enrollment row for their classes.
* **Accidental Data Loss:** If all students drop a newly added class, deleting those enrollment rows completely erases the course from our catalog history.

---

### Step-by-Step Path to 3NF

#### Step 1: First Normal Form (1NF)
We made sure every field holds a single, non-divisible value—no sticking lists of courses inside one column—and picked `(student_id, course_code, semester, year)` as a composite primary key.

* **What this fixes:** Gets rid of comma-separated lists, nested arrays, and repeated column groups.

#### Step 2: Second Normal Form (2NF)
Next, we checked for partial key dependencies. In our 1NF setup, fields like `student_name` only depended on `student_id`, while `course_name` only depended on `course_code`. Neither cared about the semester or year.

We broke the monolithic table apart into distinct core entities: `students`, `courses`, and `enrollments`.

* **What this fixes:** Cuts out partial dependencies so basic student and course details are stored in exactly one spot.

#### Step 3: Third Normal Form (3NF)
Finally, we looked for non-key fields depending on other non-key fields (transitive dependencies). 

For instance, if `course_offerings` stored `instructor_email` and `instructor_department`, the department actually belongs to the instructor, not the course section. We moved `instructors` into its own table and linked it back using `instructor_id` as a foreign key.

* **What this fixes:** Removes transitive dependencies ($A \rightarrow B \rightarrow C$), giving us a clean, modular 3NF schema.

---

## 2. Indexing Strategy

### The Indexes We Built
1. `CREATE INDEX idx_courses_code ON courses(course_code);`
   * **Why:** We look up and join courses by code (like `CS101`) all the time. A B-Tree index lets the database skip right to the exact match in logarithmic time ($O(\log N)$) instead of doing a full table scan ($O(N)$).

2. `CREATE INDEX idx_offerings_term ON course_offerings(semester, year);`
   * **Why:** Backend reports frequently filter classes by term (e.g., "Get all Spring 2026 offerings"). A composite index lets MySQL check both columns together instead of scanning through unrelated academic years.

### What We Left Unindexed On Purpose
* **Column:** `enrollments.grade`
* **Why:** We skipped `grade` because:
  1. **Low Variety (Low Cardinality):** Grades only have a few possible values (`A`, `B`, `C`, `D`, `F`, `I`). Because so many rows share the same value, MySQL's query optimizer usually ignores the index anyway and runs a table scan because it's faster.
  2. **Write Bottlenecks:** Grades change often during finals week. Maintaining an index on `grade` forces MySQL to rebuild the index tree on every update, slowing down write operations for no real gain.

---

## 3. Concurrency & Transactions

### The "Last Seat" Race Condition
Picture two students, **Aarav** and **Bhavna**, hitting the "Enroll" button for the final open seat (`available_seats = 1`) in a popular DBMS class at the exact same millisecond:

1. **Aarav's request starts:** Reads `available_seats` and gets `1`.
2. **Bhavna's request starts:** Right before Aarav finishes saving, Bhavna's query reads `available_seats` and also gets `1`.
3. **Aarav finishes:** Decrements the count to `0`, saves the enrollment, and commits.
4. **Bhavna finishes:** Operating on that old read value of `1`, Bhavna's query also decrements the count and commits.

Now both students are enrolled, but `available_seats` drops to `-1` (or stays at `0` with two new students). This is a classic **Lost Update / Overbooking bug**.

---

### How We Lock It Down
To prevent overbooking, we use **Pessimistic Locking (`SELECT ... FOR UPDATE`)** inside our enrollment transaction:

```sql
SELECT available_seats FROM course_offerings WHERE offering_id = 3 FOR UPDATE;