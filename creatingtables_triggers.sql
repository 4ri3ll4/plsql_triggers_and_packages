CREATE TABLE access_violations_log (
    log_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR2(50),
    action_type   VARCHAR2(50),
    attempted_on  DATE,
    description   VARCHAR2(200)
);

CREATE OR REPLACE TRIGGER trg_restrict_access
BEFORE INSERT OR UPDATE OR DELETE ON access_violations_log
DECLARE
    v_day VARCHAR2(10);
    v_time NUMBER;
BEGIN
    -- Get current day name
    v_day := TO_CHAR(SYSDATE, 'DAY', 'NLS_DATE_LANGUAGE=ENGLISH');

    -- Get current hour (24h format)
    v_time := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));

    -- Check if weekend
    IF TRIM(v_day) IN ('SATURDAY', 'SUNDAY') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Access not allowed during weekend.');
    END IF;

    -- Check if outside working hours
    IF v_time < 8 OR v_time >= 17 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Access allowed only 8:00 AM to 5:00 PM.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER trg_log_violations
AFTER SERVERERROR ON DATABASE
DECLARE
    v_user       VARCHAR2(50);
    v_error_code NUMBER;
    v_action     VARCHAR2(50);
BEGIN
    -- Get the error that just occurred
    v_error_code := ORA_SERVER_ERROR(1);

    -- We only log our custom errors (-20001 and -20002)
    IF v_error_code IN (-20001, -20002) THEN

        v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');

        INSERT INTO access_violations_log (username, action_type, attempted_on, description)
        VALUES (
            v_user,
            SYS_CONTEXT('USERENV','CURRENT_SCHEMA'),
            SYSDATE,
            'Unauthorized access attempt detected.'
        );
    END IF;
END;
/

