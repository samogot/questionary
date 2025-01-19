#!/usr/bin/python3.9
import mysql.connector
import secrets


def get_db() -> mysql.connector.MySQLConnection:
    return mysql.connector.MySQLConnection(
        host=secrets.MYSQL_HOST,
        user=secrets.MYSQL_USER,
        password=secrets.MYSQL_PASSWORD,
        database=secrets.MYSQL_DATABASE,
    )


def _query_commit_and_check_rows(db: mysql.connector.MySQLConnection, query, limit=100, **kwargs):
    with db.cursor() as c:
        c.execute(query, {'limit': limit, **kwargs})
        db.commit()
        return c.rowcount < limit, c.rowcount


def _repeat_until_done(name, fn, *args, **kwargs):
    while True:
        done, rows = fn(*args, **kwargs)
        if rows > 0:
            print(name, rows)
        if done:
            break


def _delete_outdated_rows_from_frm_forms_ext(db: mysql.connector.MySQLConnection, limit=100):
    query = r'''
DELETE FROM frm_forms_ext
WHERE stop_time < frm_func_get_form_stop_time(id_form)
LIMIT %(limit)s
'''
    return _query_commit_and_check_rows(db, query, limit)


def _populate_new_rows_in_frm_forms_ext(db: mysql.connector.MySQLConnection, limit=100):
    query = r'''
INSERT INTO frm_forms_ext(id_form, start_time, stop_time, quest_count, quest_max, iat_max_err, iat_max_PCT_300, region, city, school, class, sex)
SELECT `id_form`,
       frm_func_get_form_start_time(id_form) AS                                                                                `start_time`,
       frm_func_get_form_stop_time(id_form)  AS                                                                                `stop_time`,
       (SELECT count(DISTINCT `key`) FROM frm_questions WHERE id_form = f.id_form AND `key` NOT LIKE '%\_%' AND `value` != '') `quest_count`,
       (SELECT max(replace(substring_index(`key`, '_', 1), 'quest', '') * 1) FROM frm_questions WHERE id_form = f.id_form)     `quest_max`,
       (SELECT max(err)
        FROM iat_subjects
                 INNER JOIN iat_data USING (id_subject)
        WHERE `id_form` = f.id_form)                                                                                           iat_max_err,
       (SELECT max(PCT_300)
        FROM iat_subjects
                 INNER JOIN iat_data USING (id_subject)
        WHERE `id_form` = f.id_form)                                                                                           iat_max_PCT_300,
       coalesce((SELECT VALUE FROM `frm_questions` WHERE `key` = 'quest0_region' AND f.id_form = id_form ORDER BY `time` DESC LIMIT 1),
                (SELECT `region` FROM `reg_all` WHERE code = f.id_worker LIMIT 1))                                             region,
       coalesce((SELECT VALUE FROM `frm_questions` WHERE `key` = 'quest0_city' AND f.id_form = id_form ORDER BY `time` DESC LIMIT 1),
                (SELECT `city` FROM `reg_all` WHERE code = f.id_worker LIMIT 1))                                               city,
       coalesce((SELECT VALUE FROM `frm_questions` WHERE `key` = 'quest0_school' AND f.id_form = id_form ORDER BY `time` DESC LIMIT 1),
                (SELECT `school` FROM `reg_all` WHERE code = f.id_worker LIMIT 1))                                             school,
       coalesce((SELECT VALUE FROM `frm_questions` WHERE `key` = 'quest0_class' AND f.id_form = id_form ORDER BY `time` DESC LIMIT 1),
                (SELECT `class` FROM `reg_all` WHERE code = f.id_worker LIMIT 1))                                              class,
       coalesce((SELECT VALUE FROM `frm_questions` WHERE `key` = 'quest0_sex' AND f.id_form = id_form ORDER BY `time` DESC LIMIT 1),
                (SELECT `sex` FROM `reg_all` WHERE code = f.id_worker LIMIT 1))                                                sex
FROM frm_forms f
WHERE NOT exists(SELECT 1 FROM frm_forms_ext WHERE id_form = f.id_form)
LIMIT %(limit)s
'''
    return _query_commit_and_check_rows(db, query, limit)


def _populate_status_auto_in_frm_forms_ext(db, limit=100):
    query = r'''UPDATE frm_forms_ext
    INNER JOIN (SELECT id_form
                FROM frm_forms_ext
                WHERE quest_count > 1
                  AND status_auto IS NULL
                ORDER BY id_form
                LIMIT %(limit)s) f USING (id_form)
    LEFT JOIN (SELECT id_form,
                      sum(dif <= 1) / count(dif) * 100.0 PCT_1,
                      sum(dif <= 2) / count(dif) * 100.0 PCT_2,
                      sum(dif <= 3) / count(dif) * 100.0 PCT_3
               FROM (SELECT id_form, min(q2.time - q1.time) AS dif
                     FROM (SELECT id_form
                           FROM frm_forms_ext
                           WHERE quest_count > 1
                             AND status_auto IS NULL
                           ORDER BY id_form
                           LIMIT %(limit)s) AS f
                              INNER JOIN frm_questions q1 USING (id_form)
                              INNER JOIN frm_questions q2 USING (id_form)
                     WHERE q1.key LIKE 'quest%'
                       AND q1.key NOT LIKE '%\_%'
                       AND q2.key = concat('quest', (replace(q1.key, 'quest', '') * 1 + 1))
                       AND q1.time <= q2.time
                     GROUP BY id_form, q1.key) tt
               GROUP BY id_form) t USING (id_form)
SET status_PCT_1 = PCT_1,
    status_PCT_2 = PCT_2,
    status_PCT_3 = PCT_3,
    status_num   = (PCT_1 > 30) + (PCT_2 > 50) + (PCT_3 > 80),
    status_auto  = coalesce(((PCT_1 > 30) + (PCT_2 > 50) + (PCT_3 > 80)) < 2, 0)
WHERE status_auto IS NULL'''
    return _query_commit_and_check_rows(db, query, limit)


def main():
    db = get_db()
    with db.cursor() as c:
        c.callproc('iat_proc_update_data')
    _repeat_until_done('delete frm_forms_ext', _delete_outdated_rows_from_frm_forms_ext, db, 500)
    _repeat_until_done('insert frm_forms_ext', _populate_new_rows_in_frm_forms_ext, db, 500)
    _repeat_until_done('update frm_forms_ext', _populate_status_auto_in_frm_forms_ext, db, 1000)
    print('ok')


if __name__ == '__main__':
    main()
