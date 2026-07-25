rem
rem NAME
rem   cikgu_populate.sql - Populate the CIKGU schema with seed data
rem
rem DESCRIPTION
rem   Seed data for the Cikgu Personalized Learning Platform.
rem   Every seeded account logs in with the password 'password123'
rem   (stored as a BCrypt hash).
rem
rem   Seed ids are explicit (tutors 1-15, learners 16-33, goals 1-20,
rem   modules 1-15); the sequences start at 1000 so application inserts
rem   never collide with seed rows.
rem
rem   Deliberate data shapes for the graded reports/queries:
rem     - multi-level mentorship chains: 1 -> 2 -> 4 -> 6 and 1 -> 3 -> 7 -> 10
rem     - module 1 has one LEAD and two CO_TEACHERs
rem     - learners 27 and 29 have goals but zero enrollments (NOT EXISTS demo)
rem     - several enrollments whose goal target_date has passed while the
rem       status is not COMPLETED (behind-schedule report)
rem
rem --------------------------------------------------------------------------

SET FEEDBACK OFF

Prompt ******  Populating APP_USER table (tutors) ....

rem All password hashes = BCrypt('password123')

INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (1, 'Halim Abdullah', 'halim.abdullah@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400001', DATE '2025-01-15', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (2, 'Salmah Yusof', 'salmah.yusof@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400002', DATE '2025-02-01', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (3, 'Ravi Chandran', 'ravi.chandran@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400003', DATE '2025-02-10', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (4, 'Lim Wei Jian', 'lim.weijian@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400004', DATE '2025-03-05', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (5, 'Nur Aisyah Rahman', 'nur.aisyah@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400005', DATE '2025-03-12', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (6, 'Farid Kamal', 'farid.kamal@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400006', DATE '2025-04-01', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (7, 'Chong Mei Ling', 'chong.meiling@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400007', DATE '2025-04-20', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (8, 'Arjun Nair', 'arjun.nair@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400008', DATE '2025-05-02', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (9, 'Zainab Ismail', 'zainab.ismail@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400009', DATE '2025-05-18', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (10, 'Daniel Wong', 'daniel.wong@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400010', DATE '2025-06-01', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (11, 'Siti Hajar Mohd', 'siti.hajar@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400011', DATE '2025-06-15', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (12, 'Kavitha Pillai', 'kavitha.pillai@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400012', DATE '2025-07-01', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (13, 'Gopal Krishnan', 'gopal.krishnan@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400013', DATE '2025-07-20', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (14, 'Aminah Long', 'aminah.long@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400014', DATE '2025-08-05', 'TUTOR');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (15, 'Jason Chin', 'jason.chin@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '012-3400015', DATE '2025-08-22', 'TUTOR');

Prompt ******  Populating APP_USER table (learners) ....

INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (16, 'Aina Sofea Zulkifli', 'aina.sofea@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500016', DATE '2025-09-01', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (17, 'Muhammad Haziq Roslan', 'haziq.roslan@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500017', DATE '2025-09-10', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (18, 'Priya Darshini', 'priya.darshini@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500018', DATE '2025-09-18', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (19, 'Tan Jun Hao', 'tan.junhao@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500019', DATE '2025-10-02', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (20, 'Nurul Izzah Hamid', 'nurul.izzah@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500020', DATE '2025-10-11', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (21, 'Amirul Hakim Bakri', 'amirul.hakim@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500021', DATE '2025-10-25', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (22, 'Chloe Lim', 'chloe.lim@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500022', DATE '2025-11-03', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (23, 'Devendran Muthu', 'devendran.muthu@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500023', DATE '2025-11-15', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (24, 'Syafiqah Aziz', 'syafiqah.aziz@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500024', DATE '2025-11-28', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (25, 'Marcus Teo', 'marcus.teo@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500025', DATE '2025-12-05', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (26, 'Farah Nabila Osman', 'farah.nabila@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500026', DATE '2025-12-12', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (27, 'Wong Kai Xin', 'wong.kaixin@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500027', DATE '2026-01-04', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (28, 'Hafiz Shamsudin', 'hafiz.shamsudin@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500028', DATE '2026-01-09', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (29, 'Anushka Rai', 'anushka.rai@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500029', DATE '2026-01-16', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (30, 'Irfan Danial', 'irfan.danial@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500030', DATE '2026-01-22', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (31, 'Lee Su Yin', 'lee.suyin@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500031', DATE '2026-02-01', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (32, 'Khairul Anuar', 'khairul.anuar@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500032', DATE '2026-02-08', 'LEARNER');
INSERT INTO app_user (user_id, full_name, email, password_hash, phone, date_joined, user_type) VALUES
 (33, 'Sofia Binti Karim', 'sofia.karim@cikgu.my', '$2y$10$WWnac//SFbPxV8dcems5PeA69.dg7mrys/faY.J7BhsPx/o72dCKq', '013-5500033', DATE '2026-02-14', 'LEARNER');

Prompt ******  Populating TUTOR table ....

rem Mentorship chains: 1 -> 2 -> 4 -> 6 and 1 -> 3 -> 7 -> 10 (3+ levels).
rem Rows are ordered so every mentor is inserted before their mentees.

INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (1, NULL, 'Database Systems, Data Engineering', 20);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (2, 1, 'Oracle SQL, PL/SQL', 14);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (3, 1, 'Data Modeling, Systems Analysis', 12);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (4, 2, 'Java, Spring Framework', 8);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (5, 2, 'Web Development, Spring Boot', 7);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (6, 4, 'Backend Development', 3);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (7, 3, 'Statistics, Data Visualization', 6);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (8, 3, 'Python, Data Analysis', 5);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (9, 5, 'SQL Foundations', 2);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (10, 7, 'Data Visualization, Dashboards', 1);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (11, 1, 'Business Intelligence, Reporting', 9);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (12, NULL, 'Machine Learning, Statistics', 15);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (13, 12, 'Machine Learning Engineering', 4);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (14, 11, 'Power BI, Excel Analytics', 3);
INSERT INTO tutor (user_id, mentor_id, expertise, years_experience) VALUES
 (15, 2, 'Cloud Databases, OCI', 5);

Prompt ******  Populating LEARNER table ....

INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (16, 'Diploma in Accountancy, UiTM', 'Excel, Bookkeeping');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (17, 'SPM, self-taught programming', 'HTML, basic JavaScript');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (18, 'Bachelor of Business Administration', 'Excel, PowerPoint, reporting');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (19, 'Diploma in Multimedia Design', 'Photoshop, HTML, CSS');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (20, 'Bachelor of Science in Mathematics', 'Statistics, R basics');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (21, 'Diploma in Computer Science, UiTM', 'C++, Java basics');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (22, 'Bachelor of Mass Communication', 'Writing, social media analytics');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (23, 'Certificate in Electrical Engineering', 'AutoCAD, troubleshooting');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (24, 'Bachelor of Finance', 'Excel modeling, VBA');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (25, 'Diploma in Logistics Management', 'ERP systems, Excel');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (26, 'Bachelor of Human Resource Management', 'HRIS, reporting');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (27, 'STPM, science stream', 'Mathematics, physics');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (28, 'Diploma in Information Management, UiTM', 'Records management, SQL basics');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (29, 'Bachelor of Economics', 'Stata, Excel');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (30, 'SPM, retail work experience', 'Point-of-sale systems');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (31, 'Bachelor of Marketing', 'Google Analytics, Canva');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (32, 'Diploma in Mechanical Engineering', 'SolidWorks, mathematics');
INSERT INTO learner (user_id, education_background, parsed_skills) VALUES
 (33, 'Bachelor of Education (TESL)', 'Teaching, content writing');

Prompt ******  Populating GOAL table ....

INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (1, 16, 'Become a data analyst', 'Move into a junior data analyst role', DATE '2026-03-31');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (2, 16, 'Learn cloud databases', 'Run a database on Oracle Cloud', DATE '2026-12-31');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (3, 17, 'Career switch to software development', 'Land a junior developer job', DATE '2026-05-15');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (4, 18, 'Master SQL for reporting', 'Replace manual Excel reports with SQL', DATE '2026-04-30');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (5, 19, 'Build a portfolio web app', 'Publish a personal web application', DATE '2026-11-30');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (6, 20, 'Pass Oracle SQL certification', 'Obtain the Oracle SQL Associate cert', DATE '2026-06-15');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (7, 21, 'Automate reports with Python', 'Automate weekly branch reports', DATE '2026-10-31');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (8, 22, 'Understand machine learning basics', 'Complete an intro ML course', DATE '2027-01-31');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (9, 23, 'Move from Excel to SQL', 'Query the company database directly', DATE '2026-02-28');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (10, 24, 'Data engineering fundamentals', 'Understand pipelines and warehousing', DATE '2026-12-15');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (11, 25, 'Learn frontend basics', 'Build responsive pages with HTML/CSS', DATE '2026-08-31');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (12, 26, 'BI dashboards for work', 'Build a Power BI dashboard for HR', DATE '2026-05-31');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (13, 27, 'Learn Java programming', 'Write a small console application', DATE '2026-09-30');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (14, 28, 'Statistics refresher', 'Refresh statistics for data work', DATE '2026-04-15');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (15, 29, 'Explore NoSQL databases', 'Compare document and key-value stores', DATE '2027-02-28');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (16, 30, 'Version control mastery', 'Use Git confidently at work', DATE '2026-06-30');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (17, 31, 'Data visualization storytelling', 'Present campaign data visually', DATE '2026-10-15');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (18, 32, 'Database design skills', 'Design a normalized schema', DATE '2026-03-15');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (19, 33, 'Spring Boot proficiency', 'Build a CRUD web app with Spring Boot', DATE '2026-12-31');
INSERT INTO goal (goal_id, user_id, goal_title, target_outcome, target_date) VALUES
 (20, 18, 'Learn Python basics', 'Write data-cleaning scripts in Python', DATE '2026-09-15');

Prompt ******  Populating MODULE table ....

INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (1, 'SQL Fundamentals', 'SELECT, joins, grouping and subqueries on Oracle Database.', 20, 'BEGINNER');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (2, 'Advanced PL/SQL', 'Stored procedures, triggers, packages and bulk operations.', 35, 'ADVANCED');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (3, 'Data Modeling and ERD Design', 'Entity-relationship modeling, normalization and physical design.', 25, 'INTERMEDIATE');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (4, 'Python for Data Analysis', 'pandas, data cleaning and exploratory analysis.', 30, 'BEGINNER');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (5, 'Java Programming Basics', 'Syntax, OOP concepts and collections in Java.', 40, 'BEGINNER');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (6, 'Spring Boot Web Development', 'REST controllers, Thymeleaf views and JDBC data access.', 45, 'INTERMEDIATE');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (7, 'Statistics Foundations', 'Descriptive statistics, probability and inference basics.', 25, 'BEGINNER');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (8, 'Machine Learning Introduction', 'Supervised learning, model evaluation and scikit-learn.', 50, 'ADVANCED');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (9, 'From Excel to SQL', 'Translate spreadsheet workflows into SQL queries.', 15, 'BEGINNER');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (10, 'Data Visualization Essentials', 'Chart selection, dashboards and visual storytelling.', 20, 'INTERMEDIATE');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (11, 'NoSQL Databases Overview', 'Document, key-value and graph stores compared with SQL.', 22, 'INTERMEDIATE');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (12, 'Cloud Databases on OCI', 'Provisioning and managing Oracle databases in the cloud.', 30, 'ADVANCED');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (13, 'Business Intelligence with Power BI', 'Data models, DAX basics and report publishing.', 28, 'INTERMEDIATE');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (14, 'Web Fundamentals: HTML and CSS', 'Semantic markup, layout and responsive design.', 18, 'BEGINNER');
INSERT INTO module (module_id, module_title, description, duration_hours, difficulty) VALUES
 (15, 'Git and DevOps Basics', 'Version control workflows and CI fundamentals.', 12, 'BEGINNER');

Prompt ******  Populating MODULE_TUTOR table ....

rem Module 1 demonstrates co-teaching: one LEAD plus two CO_TEACHERs.

INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (1, 1, 'LEAD', DATE '2025-09-01');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (1, 4, 'CO_TEACHER', DATE '2025-09-15');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (1, 9, 'CO_TEACHER', DATE '2025-10-01');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (2, 2, 'LEAD', DATE '2025-09-01');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (2, 5, 'CO_TEACHER', DATE '2025-09-20');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (3, 1, 'LEAD', DATE '2025-09-05');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (4, 3, 'LEAD', DATE '2025-09-05');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (4, 8, 'CO_TEACHER', DATE '2025-09-25');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (5, 4, 'LEAD', DATE '2025-09-10');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (6, 5, 'LEAD', DATE '2025-09-10');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (6, 6, 'CO_TEACHER', DATE '2025-10-05');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (7, 12, 'LEAD', DATE '2025-09-12');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (8, 12, 'LEAD', DATE '2025-09-12');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (8, 7, 'CO_TEACHER', DATE '2025-10-10');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (9, 11, 'LEAD', DATE '2025-09-15');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (10, 7, 'LEAD', DATE '2025-09-15');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (11, 3, 'LEAD', DATE '2025-09-18');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (12, 15, 'LEAD', DATE '2025-09-18');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (13, 11, 'LEAD', DATE '2025-09-20');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (13, 14, 'CO_TEACHER', DATE '2025-10-12');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (14, 8, 'LEAD', DATE '2025-09-22');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (15, 10, 'LEAD', DATE '2025-09-22');
INSERT INTO module_tutor (module_id, user_id, teaching_role, assigned_date) VALUES
 (15, 6, 'CO_TEACHER', DATE '2025-10-15');

Prompt ******  Populating ENROLLMENT table ....

rem Learners 27 and 29 deliberately have no enrollments.
rem Goals 1, 3, 4, 6, 9, 12, 18 have past target dates, so their linked
rem non-COMPLETED enrollments appear in the behind-schedule report.

INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (16, 1, 1, DATE '2026-01-10', 85, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (16, 4, 1, DATE '2026-01-12', 100, 'COMPLETED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (16, 12, 2, DATE '2026-02-01', 40, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (17, 5, 3, DATE '2026-01-15', 55, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (17, 6, 3, DATE '2026-02-20', 10, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (18, 1, 4, DATE '2026-01-08', 100, 'COMPLETED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (18, 4, 20, DATE '2026-03-01', 62, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (19, 14, 5, DATE '2026-02-10', 75, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (19, 6, 5, DATE '2026-03-05', 20, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (20, 1, 6, DATE '2026-01-20', 90, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (20, 2, 6, DATE '2026-02-15', 35, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (21, 4, 7, DATE '2026-02-01', 88, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (21, 10, NULL, DATE '2026-03-10', 15, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (22, 8, 8, DATE '2026-02-25', 0, 'NOT_STARTED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (22, 7, 8, DATE '2026-02-25', 30, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (23, 9, 9, DATE '2026-01-05', 100, 'COMPLETED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (23, 1, 9, DATE '2026-02-12', 45, 'DROPPED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (24, 11, 10, DATE '2026-03-01', 25, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (24, 12, 10, DATE '2026-03-15', 10, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (25, 14, 11, DATE '2026-02-05', 95, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (25, 10, NULL, DATE '2026-04-02', 0, 'NOT_STARTED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (26, 13, 12, DATE '2026-01-25', 70, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (26, 1, NULL, DATE '2026-02-03', 100, 'COMPLETED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (28, 7, 14, DATE '2026-01-30', 100, 'COMPLETED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (28, 8, NULL, DATE '2026-03-18', 20, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (30, 15, 16, DATE '2026-02-18', 100, 'COMPLETED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (30, 6, NULL, DATE '2026-01-28', 0, 'DROPPED');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (31, 10, 17, DATE '2026-03-08', 60, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (32, 3, 18, DATE '2026-01-14', 80, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (32, 2, 18, DATE '2026-02-22', 55, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (33, 6, 19, DATE '2026-03-12', 65, 'IN_PROGRESS');
INSERT INTO enrollment (user_id, module_id, goal_id, enroll_date, progress_score, status) VALUES
 (33, 5, NULL, DATE '2026-04-05', 100, 'COMPLETED');

COMMIT;

SET FEEDBACK ON
