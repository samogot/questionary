# From To files
SET @from_file = (SELECT id_file
                  FROM rsrch_files
                  WHERE name = '2025_ltpmppp');
SET @to_file = (SELECT id_file
                FROM rsrch_files
                WHERE name = '2025_ltpmpz');

# Duplicate forms with a new file
# Save old id_form in id_worker_old temporarily
INSERT INTO frm_forms(id_worker, id_worker_old, id_device, internal_id, id_file, `real`, inputter, address, phone, photo, status, priority)
SELECT id_worker,
       id_form  AS id_worker_old,
       id_device,
       internal_id,
       @to_file AS id_file,
       `real`,
       inputter,
       address,
       phone,
       photo,
       status,
       priority
FROM frm_forms
WHERE id_file = @from_file;

# Duplicate answers with new forms
INSERT INTO frm_questions (id_form, `key`, value, time)
SELECT f.id_form, `key`, value, time
FROM frm_questions q
         INNER JOIN frm_forms f ON (f.id_worker_old = q.id_form)
WHERE id_file = @to_file;

# Save the mapping
INSERT INTO frm_form_moves(orig_id_form, copy_id_form)
SELECT id_worker_old, id_form
FROM frm_forms
WHERE id_file = @to_file
  AND id_worker_old IS NOT NULL;



# Fix the data format

# All keys ordered
SELECT DISTINCT `key`
FROM frm_questions
WHERE id_form IN (SELECT id_form
                  FROM frm_forms
                  WHERE id_file = @to_file
                    AND id_worker_old IS NOT NULL)
ORDER BY cast(replace(substring_index(`key`, '_', 1), 'quest', '') AS DECIMAL), `key`;

# Delete admin records
DELETE
FROM frm_questions
WHERE id_form IN (SELECT id_form
                  FROM frm_forms
                  WHERE id_file = @to_file
                    AND id_worker = 585858
                    AND id_worker_old IS NOT NULL);

# Add 28 questions at numbers starting from 8 and shift all other questions down
SELECT *,
# UPDATE frm_questions
# SET `key`=
       concat('quest', (cast(replace(substring_index(`key`, '_', 1), 'quest', '') AS DECIMAL) + 28), replace(`key`, substring_index(`key`, '_', 1), ''))
FROM frm_questions
WHERE id_form IN (SELECT id_form
                  FROM frm_forms
                  WHERE id_file = @to_file
                    AND id_worker_old IS NOT NULL)
  AND cast(replace(substring_index(`key`, '_', 1), 'quest', '') AS DECIMAL) >= 8;

# # SELECT * FROM frm_questions
# UPDATE frm_questions
# SET value=value * 1 + 1
# WHERE id_form IN (SELECT id_form
#                   FROM frm_forms
#                   WHERE id_file = @to_file
#                     AND id_worker_old IS NOT NULL)
#   AND `key` IN (
#                 'quest10',
#                 'quest11',
#                 'quest12',
#                 'quest13',
#                 'quest14',
#                 'quest15',
#                 'quest16',
#                 'quest17',
#                 'quest18',
#                 'quest19',
#                 'quest21',
#                 'quest22'
#     );


# Cleanup temporary id_worker_old
UPDATE frm_forms
SET id_worker_old = NULL
WHERE id_file = @to_file
  AND id_worker_old IS NOT NULL;
