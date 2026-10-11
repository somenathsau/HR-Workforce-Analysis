USE HR_Analytics;



/* ==================================
      Part A - Data Exproration
   ================================== */

-- 1. Total Number of Employees
SELECT count(emp_id) AS Total_Employees
FROM   emp_info;

-- 2. Total Active vs Inactive employees
SELECT   IIF (is_active = 1, 'Active', 'Inactive') AS Status,
         count(emp_id) AS Total_employees
FROM     emp_info
GROUP BY is_active;

-- 3. How many employees in each department
SELECT   department.dept_name,
         COUNT(emp_salary.emp_id) AS headcount
FROM     department
         LEFT OUTER JOIN
         emp_salary
         ON department.dept_id = emp_salary.dept_id
GROUP BY department.dept_name
ORDER BY headcount DESC;

-- 4. Department Having Highest Number of Employees
SELECT   TOP 1 department.dept_name,
               COUNT(emp_salary.emp_id) AS headcount
FROM     department
         LEFT OUTER JOIN
         emp_salary
         ON department.dept_id = emp_salary.dept_id
GROUP BY department.dept_name
ORDER BY headcount DESC;

-- 5a. Avaerage Basic Salary of Employees
SELECT STR(AVG(basic_salary), 10, 2) AS Avg_Basic_Pay
FROM   emp_salary;

-- 5b. Average Gross Salary of Employees
SELECT STR(AVG(gross_salary), 10, 2) AS AVG_Gross_Salary
FROM   emp_salary;

-- 6. Minimum and Maximun salaries of employees
SELECT MAX(gross_salary) AS Max_Salary,
       MIN(gross_salary) AS Min_Salary
FROM   emp_salary;

-- 7. Average age of employees
SELECT AVG(datediff(year, dob, getdate())) AS Average_age
FROM   emp_info;

-- 8. Employees distribution by gender
SELECT   gender,
         count(emp_id) AS Employee_Count
FROM     emp_info
GROUP BY gender;

-- 9. Employees belong to each qualification category
SELECT   qualification,
         count(emp_id) AS Total_Employees
FROM     emp_info
GROUP BY qualification;

-- 10. Total Employees distribution by country
SELECT   country,
         count(emp_id) AS Total_Employees
FROM     emp_info
GROUP BY country;

-- 11. Total Employees distribution by city
SELECT   city,
         COUNT(emp_id) AS Total_Employees
FROM     emp_info
GROUP BY city;


/* =======================================
      Part B - Workforce & Compensation
   ======================================= */


-- 12. Average Salary by Department
SELECT   department.dept_name,
         STR(AVG(emp_salary.gross_salary), 10, 0) AS "Average Salary"
FROM     department
         LEFT OUTER JOIN
         emp_salary
         ON department.dept_id = emp_salary.dept_id
GROUP BY dept_name
ORDER BY "Average Salary" DESC;

-- 13. Average Salary of each Job Role
SELECT   job_roles.position,
         STR(AVG(emp_salary.gross_salary), 10, 0) AS "Average Salary"
FROM     job_roles
         LEFT OUTER JOIN
         emp_salary
         ON job_roles.role_id = emp_salary.role_id
GROUP BY position
ORDER BY "Average Salary" DESC;

-- 14. Which Department have an highest average performance score?
SELECT   TOP 1 department.dept_name,
               STR(AVG(emp_salary.performance_rating), 10, 2) AS "Average Rating"
FROM     department
         LEFT OUTER JOIN
         emp_salary
         ON department.dept_id = emp_salary.dept_id
GROUP BY dept_name
ORDER BY "Average Rating" DESC;

-- 15. Which job roles have the highest average salary?
SELECT   TOP 1 job_roles.position,
               STR(AVG(emp_salary.gross_salary), 10, 0) AS "Average Salary"
FROM     job_roles
         LEFT OUTER JOIN
         emp_salary
         ON job_roles.role_id = emp_salary.role_id
GROUP BY position
ORDER BY "Average Salary" DESC;

-- 16. Compare the role's base_salary with the employees' actual basic_salary
SELECT   emp_info.emp_id,
         CONCAT(emp_info.first_name, ' ', emp_info.last_name) AS "Employee Name",
         job_roles.position,
         job_roles.base_salary AS Role_Base_Salary,
         emp_salary.basic_salary AS Actual_Basic_Salary,
         (emp_salary.basic_salary - job_roles.base_salary) AS Salary_Varience
FROM     emp_info
         INNER JOIN
         emp_salary
         ON emp_info.emp_id = emp_salary.emp_id
         INNER JOIN
         job_roles
         ON emp_salary.role_id = job_roles.role_id
ORDER BY Salary_Varience DESC;

-- 17. Which job roles have more than 650 employees?
SELECT   job_roles.position,
         COUNT(emp_salary.emp_id) AS Total_Employees
FROM     job_roles
         LEFT OUTER JOIN
         emp_salary
         ON job_roles.role_id = emp_salary.role_id
GROUP BY position
HAVING   COUNT(emp_salary.emp_id) > 650
ORDER BY Total_Employees DESC;

/* =========================================
         Part C - HR Business Analysis
   ========================================= */

-- 18. Does Higher work experience correspond to higher salary?
-- This uses CTE (Common Table Expression)
WITH ExpGroups
AS (SELECT gross_salary,
      CASE 
         WHEN year_of_exp <= 3 THEN '0-3 yrs' WHEN year_of_exp > 3
          AND year_of_exp <= 5 THEN '3-5 yrs' WHEN year_of_exp > 5
          AND year_of_exp <= 10 THEN '5-10 yrs' ELSE '10+ yrs' 
      END AS Experience_Group
          FROM   emp_salary)
SELECT Experience_Group,
      COUNT(*) AS headcount,
      STR(AVG(gross_salary), 10, 0) AS avg_salary
FROM ExpGroups
GROUP BY Experience_Group;


-- 19. Which departments have high salary but below-average performance?
WITH DeptAverages AS (
    SELECT 
        CAST(AVG(gross_salary) AS DECIMAL(18, 0)) AS overall_avg_salary,
        CAST(AVG(performance_rating) AS DECIMAL(18, 2)) AS overall_avg_rating
    FROM emp_salary
),
DeptMetrics AS (
    SELECT 
        d.dept_name,
        CAST(AVG(s.gross_salary) AS DECIMAL(18, 2)) AS dept_avg_salary,
        CAST(AVG(s.performance_rating) AS DECIMAL(18, 2)) AS dept_avg_rating
    FROM department d
    JOIN emp_salary s ON d.dept_id = s.dept_id
    GROUP BY d.dept_name
)
SELECT 
    m.dept_name,
    m.dept_avg_salary,
    m.dept_avg_rating
FROM DeptMetrics m
CROSS JOIN DeptAverages a
WHERE m.dept_avg_salary > a.overall_avg_salary
  AND m.dept_avg_rating < a.overall_avg_rating
ORDER BY m.dept_avg_salary DESC;

-- 20. Which employees have a salary higher than their department's average?
SELECT   emp_info.emp_id,
         CONCAT(emp_info.first_name, ' ', emp_info.last_name) AS "Employee Name",
         department.dept_name,
         emp_salary.gross_salary AS "Emp Gross Salary"
FROM     emp_salary
         INNER JOIN
         emp_info
         ON emp_salary.emp_id = emp_info.emp_id
         INNER JOIN
         department
         ON emp_salary.dept_id = department.dept_id
WHERE    emp_salary.gross_salary > (SELECT AVG(emp_salary.gross_salary)
                                    FROM   emp_salary
                                    WHERE  emp_salary.dept_id = emp_salary.dept_id)
ORDER BY "Emp Gross Salary" DESC;

-- 21. Find the top 3 highest-paid employees in each department.
SELECT   d.dept_name,
         CONCAT(ei.first_name, ' ', ei.last_name) AS "Employee Name",
         es.gross_salary
FROM     emp_salary AS es
         INNER JOIN
         emp_info AS ei
         ON es.emp_id = ei.emp_id
         INNER JOIN
         department AS d
         ON es.dept_id = d.dept_id
WHERE    (SELECT count(*)
          FROM   emp_salary AS es2
          WHERE  es2.dept_id = es.dept_id
                 AND es2.gross_salary > es.gross_salary) < 3
ORDER BY d.dept_name, es.gross_salary DESC;


-- 22. Rank all employees by salary within their department.
SELECT   d.dept_name,
         CONCAT(ei.first_name, ' ', ei.last_name) AS "Employee Name",
         es.gross_salary,
         ROW_NUMBER() OVER (PARTITION BY es.dept_id ORDER BY es.gross_salary DESC) AS "Salary Rank"
FROM     emp_salary AS es
         INNER JOIN
         emp_info AS ei
         ON es.emp_id = ei.emp_id
         INNER JOIN
         department AS d
         ON es.dept_id = d.dept_id
ORDER BY d.dept_name, "Salary Rank" ASC;