rem
rem NAME
rem   cikgu_queries.sql - The 10 ad hoc queries for the ICT502 report
rem
rem DESCRIPTION
rem   Ten standalone queries of visibly different kinds, run against the
rem   CIKGU schema. Each query is preceded by a comment stating the
rem   question it answers. Run while connected as CIKGU:
rem
rem      sqlplus cikgu/Cikgu_123@//localhost:1521/FREEPDB1 @cikgu_queries.sql
rem
rem   Queries 8-10 are DML; they are wrapped between a savepoint-style
rem   demonstration and a ROLLBACK so running this script leaves the seed
rem   data unchanged.
rem
rem --------------------------------------------------------------------------

SET LINESIZE 140
SET PAGESIZE 60

rem ==========================================================================
rem Query 1 - Simple filter
rem Question: Which tutors have more than 5 years of teaching experience?
rem ==========================================================================

SELECT au.full_name, t.expertise, t.years_experience
  FROM tutor t
  JOIN app_user au ON au.user_id = t.user_id
 WHERE t.years_experience > 5
 ORDER BY t.years_experience DESC;

rem ==========================================================================
rem Query 2 - Multi-table join
rem Question: For every enrollment, who is the learner, which module are
rem they taking, and what is their progress score?
rem ==========================================================================

SELECT au.full_name    AS learner_name,
       m.module_title,
       e.progress_score,
       e.status
  FROM enrollment e
  JOIN learner  l  ON l.user_id   = e.user_id
  JOIN app_user au ON au.user_id  = l.user_id
  JOIN module   m  ON m.module_id = e.module_id
 ORDER BY au.full_name, m.module_title;

rem ==========================================================================
rem Query 3 - Aggregate + GROUP BY / ORDER BY
rem Question: What is the average progress score per module, ranked from
rem best-performing to worst?
rem ==========================================================================

SELECT m.module_title,
       COUNT(e.user_id)               AS enrolled_learners,
       ROUND(AVG(e.progress_score),1) AS avg_progress
  FROM module m
  JOIN enrollment e ON e.module_id = m.module_id
 GROUP BY m.module_title
 ORDER BY avg_progress DESC;

rem ==========================================================================
rem Query 4 - Subquery with NOT EXISTS
rem Question: Which learners have registered but never enrolled in any
rem module?
rem ==========================================================================

SELECT au.full_name, au.email, au.date_joined
  FROM learner l
  JOIN app_user au ON au.user_id = l.user_id
 WHERE NOT EXISTS (
          SELECT 1
            FROM enrollment e
           WHERE e.user_id = l.user_id
       );

rem ==========================================================================
rem Query 5 - CONNECT BY PRIOR (recursive)
rem Question: What does the full tutor mentorship hierarchy look like,
rem from the most senior mentors down to every mentee?
rem ==========================================================================

SELECT LPAD(' ', 3 * (LEVEL - 1)) || au.full_name AS mentorship_chain,
       LEVEL AS chain_level,
       t.years_experience
  FROM tutor t
  JOIN app_user au ON au.user_id = t.user_id
 START WITH t.mentor_id IS NULL
CONNECT BY PRIOR t.user_id = t.mentor_id
 ORDER SIBLINGS BY au.full_name;

rem ==========================================================================
rem Query 6 - GROUP BY + HAVING
rem Question: Which modules have more than 2 enrolled learners?
rem ==========================================================================

SELECT m.module_title,
       COUNT(*) AS enrollment_count
  FROM module m
  JOIN enrollment e ON e.module_id = m.module_id
 GROUP BY m.module_title
HAVING COUNT(*) > 2
 ORDER BY enrollment_count DESC;

rem ==========================================================================
rem Query 7 - Analytic / window function
rem Question: Within each module, how do the enrolled learners rank by
rem progress score?
rem ==========================================================================

SELECT m.module_title,
       au.full_name AS learner_name,
       e.progress_score,
       RANK() OVER (PARTITION BY e.module_id
                    ORDER BY e.progress_score DESC) AS rank_in_module
  FROM enrollment e
  JOIN module   m  ON m.module_id = e.module_id
  JOIN app_user au ON au.user_id  = e.user_id
 ORDER BY m.module_title, rank_in_module;

rem ==========================================================================
rem The remaining three queries are DML. They are demonstrated and then
rem rolled back so the seed data stays intact.
rem ==========================================================================

rem ==========================================================================
rem Query 8 - INSERT
rem Question: How is a new goal added for a learner? (Adds a goal for
rem learner 27, Wong Kai Xin; goal_id comes from the sequence trigger.)
rem ==========================================================================

INSERT INTO goal (user_id, goal_title, target_outcome, target_date)
VALUES (27, 'Prepare for a data science degree',
        'Complete the beginner data modules before applying',
        DATE '2027-06-30');

SELECT goal_id, user_id, goal_title, target_date
  FROM goal
 WHERE user_id = 27;

rem ==========================================================================
rem Query 9 - UPDATE
rem Question: How are enrollments with a full progress score marked as
rem COMPLETED in one statement?
rem ==========================================================================

UPDATE enrollment
   SET status = 'COMPLETED'
 WHERE progress_score >= 100
   AND status <> 'COMPLETED';

SELECT user_id, module_id, progress_score, status, last_updated_at
  FROM enrollment
 WHERE progress_score >= 100;

rem ==========================================================================
rem Query 10 - DELETE
rem Question: How are stale DROPPED enrollments (dropped before
rem 1 March 2026) purged from the system?
rem ==========================================================================

DELETE FROM enrollment
 WHERE status = 'DROPPED'
   AND enroll_date < DATE '2026-03-01';

SELECT user_id, module_id, status, enroll_date
  FROM enrollment
 WHERE status = 'DROPPED';

rem Undo the DML demonstrations (queries 8-10)
ROLLBACK;
