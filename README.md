# 📘  System Access Policy (PL/SQL Triggers and Packages Exercises)

## 🔹 Overview

This exercise implements AUCA's system access policy using **PL/SQL
triggers**. The goal is to restrict database activity during non-working
hours and log any unauthorized access attempts automatically.

We created:\
- **1 Main table** → for normal user operations\
- **1 Logging table** → where unauthorized attempts are recorded\
- **2 Triggers** → one to restrict access, one to log violations

------------------------------------------------------------------------

## 🔹 Business Rules Implemented

1.  Users cannot access or record data on **Saturday or Sunday**.\
2.  Users can access the system only during **Monday--Friday, from 8:00
    AM to 5:00 PM**.\
3.  Any attempt outside these allowed times must be **blocked** and
    **logged**.

------------------------------------------------------------------------

## 🔹 Tables Used

### ✔ 1. Main Working Table

This table represents normal user activity. Trigger 1 will restrict
access to it.

``` sql
CREATE TABLE recording_table (
    id   NUMBER,
    data VARCHAR2(50)
);
```

### ✔ 2. Logging Table

Trigger 2 inserts records into this table whenever an unauthorized
access attempt is blocked.

``` sql
CREATE TABLE access_violations_log (
    log_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR2(50),
    action_type   VARCHAR2(50),
    attempted_on  DATE,
    description   VARCHAR2(200)
);
```

------------------------------------------------------------------------

## 🔹 Trigger 1 --- Access Restriction Trigger

This is a **BEFORE INSERT/UPDATE/DELETE** trigger on the main working
table.\
It checks the system day and time, and blocks operations if:

-   The current day is **Saturday or Sunday**\
-   The time is **before 8:00 AM or after 5:00 PM**

It raises custom errors:\
- `ORA-20001` --- Weekend access\
- `ORA-20002` --- Outside working hours

------------------------------------------------------------------------

## 🔹 Trigger 2 --- Logging Trigger

Trigger 2 fires **AFTER SERVERERROR**. When Trigger 1 blocks an
operation using ORA-20001 or ORA-20002, Trigger 2 logs the attempt by
recording:

-   Username\
-   Action attempted\
-   Timestamp\
-   Description

------------------------------------------------------------------------

## 🔹 Testing the Triggers

### ✔ 1. Testing Trigger 1 (Restriction)

``` sql
INSERT INTO recording_table (id, data)
VALUES (999, 'Test attempt');
```

Expected result: an ORA-20001 or ORA-20002 error.

------------------------------------------------------------------------

### ✔ 2. Testing Trigger 2 (Logging)

``` sql
SELECT * FROM access_violations_log;
```

Expected result: a new row showing the username, action, date, and
description.

------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE hr_salary_pkg IS

    -- Calculates RSSB tax (3% of salary)
    FUNCTION calculate_rssb_tax(p_salary NUMBER) RETURN NUMBER;

    -- Returns net salary after RSSB deduction
    FUNCTION get_net_salary(p_salary NUMBER) RETURN NUMBER;

    -- Updates employee salary using dynamic SQL
    PROCEDURE update_employee_salary_dyn(
        p_emp_id NUMBER,
        p_new_salary NUMBER
    );

    -- Demonstrates USER vs CURRENT_USER security context
    PROCEDURE show_security_context;

END hr_salary_pkg;
/
-----------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY hr_salary_pkg IS

    ----------------------------------------------------------
    -- FUNCTION: Calculate RSSB Tax (3%)
    ----------------------------------------------------------
    FUNCTION calculate_rssb_tax(p_salary NUMBER) RETURN NUMBER IS
        v_tax NUMBER;
    BEGIN
        v_tax := p_salary * 0.03;
        RETURN v_tax;
    END calculate_rssb_tax;


    ----------------------------------------------------------
    -- FUNCTION: Get Net Salary
    ----------------------------------------------------------
    FUNCTION get_net_salary(p_salary NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN p_salary - calculate_rssb_tax(p_salary);
    END get_net_salary;


    ----------------------------------------------------------
    -- PROCEDURE: Update Employee Salary (Dynamic SQL)
    ----------------------------------------------------------
    PROCEDURE update_employee_salary_dyn(
        p_emp_id NUMBER,
        p_new_salary NUMBER
    ) IS
        v_sql VARCHAR2(500);
    BEGIN
        v_sql := 'UPDATE employees SET salary = :1 WHERE employee_id = :2';

        EXECUTE IMMEDIATE v_sql USING p_new_salary, p_emp_id;

        DBMS_OUTPUT.PUT_LINE('Salary updated dynamically for employee ID: ' || p_emp_id);
    END update_employee_salary_dyn;


    ----------------------------------------------------------
    -- PROCEDURE: Security Context Demonstration
    ----------------------------------------------------------
    PROCEDURE show_security_context IS
    BEGIN
        /*
            USER:
                - The schema that owns the package.
                - Represents the definer of the package.

            CURRENT_USER:
                - The account executing the package at runtime.
                - Can differ from USER when invoker rights apply.
        */

        DBMS_OUTPUT.PUT_LINE('USER: ' || USER);
        DBMS_OUTPUT.PUT_LINE('CURRENT_USER: ' || SYS_CONTEXT('USERENV','CURRENT_USER'));
    END show_security_context;

END hr_salary_pkg;
/

